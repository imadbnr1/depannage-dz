"use strict";

const functions = require("firebase-functions/v1");
const logger = require("firebase-functions/logger");

const REGION = "us-central1";
const USER_AGENT = "DepaninyMapProxy/1.0 (graduation project)";
const JSON_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Cache-Control": "public, max-age=60",
};

function sendJson(res, status, body) {
  res.set(JSON_HEADERS);
  res.status(status).json(body);
}

function handleCors(req, res) {
  if (req.method === "OPTIONS") {
    res.set(JSON_HEADERS);
    res.status(204).send("");
    return true;
  }
  if (req.method !== "POST") {
    sendJson(res, 405, {error: "method_not_allowed"});
    return true;
  }
  return false;
}

function body(req) {
  return req.body && typeof req.body === "object" ? req.body : {};
}

function cleanText(value, maxLength) {
  if (typeof value !== "string") return "";
  return value.trim().slice(0, maxLength);
}

function cleanLimit(value, fallback, max) {
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed) || parsed <= 0) return fallback;
  return Math.min(parsed, max);
}

function cleanCoordinate(value, min, max) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed < min || parsed > max) return null;
  return parsed;
}

function cleanLatLng(input) {
  const lat = cleanCoordinate(input && input.lat, -90, 90);
  const lng = cleanCoordinate(input && (input.lng ?? input.lon), -180, 180);
  if (lat === null || lng === null) return null;
  return {lat, lng};
}

async function fetchJson(url, options = {}) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), options.timeoutMs || 7000);
  try {
    const response = await fetch(url, {
      method: options.method || "GET",
      headers: {
        "Accept": "application/json",
        "User-Agent": USER_AGENT,
        ...(options.headers || {}),
      },
      body: options.body,
      signal: controller.signal,
    });
    if (!response.ok) return null;
    const contentType = response.headers.get("content-type") || "";
    if (!contentType.includes("json")) return null;
    return await response.json();
  } catch (error) {
    logger.debug("Map proxy upstream failed", {
      endpoint: options.endpoint || "unknown",
      message: error && error.message ? error.message : "unknown",
    });
    return null;
  } finally {
    clearTimeout(timeout);
  }
}

function normalizeNominatimItems(data, limit) {
  if (!Array.isArray(data)) return [];
  return data.slice(0, limit).map((item) => {
    const lat = Number.parseFloat(String(item.lat || ""));
    const lng = Number.parseFloat(String(item.lon || ""));
    const displayName = cleanText(String(item.display_name || ""), 240);
    if (!Number.isFinite(lat) || !Number.isFinite(lng) || !displayName) {
      return null;
    }
    return {displayName, lat, lng};
  }).filter(Boolean);
}

function normalizeOverpassElements(data, limit) {
  if (!data || !Array.isArray(data.elements)) return [];
  const results = [];
  for (const element of data.elements) {
    if (results.length >= limit) break;
    const tags = element.tags || {};
    const lat = Number(element.lat || (element.center && element.center.lat));
    const lng = Number(element.lon || (element.center && element.center.lon));
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) continue;
    const name = cleanText(
      tags.name || tags.brand || tags.operator || tags["name:fr"] || "Service Auto",
      160,
    );
    const type = cleanText(
      tags.shop || tags.amenity || tags.craft || "automotive",
      60,
    );
    results.push({displayName: `${name} - ${type}`, lat, lng});
  }
  return results;
}

function fallbackRoute(origin, destination) {
  const distanceKm = haversineKm(origin, destination);
  return {
    points: [origin, destination],
    distanceKm,
    durationMinutes: Math.max(1, Math.min(999, Math.round((distanceKm / 35) * 60))),
    isFallback: true,
  };
}

function haversineKm(a, b) {
  const r = 6371;
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);
  const x = Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 2 * r * Math.asin(Math.sqrt(x));
}

function toRad(value) {
  return value * Math.PI / 180;
}

function runtimeConfig() {
  try {
    return functions.config() || {};
  } catch (error) {
    logger.debug("Firebase runtime config unavailable", {
      message: error && error.message ? error.message : "unknown",
    });
    return {};
  }
}

function configuredKey(envName, configPath) {
  const envValue = cleanText(process.env[envName] || "", 512);
  if (envValue) return envValue;

  const config = runtimeConfig();
  let value = config;
  for (const part of configPath) {
    value = value && value[part];
  }
  return cleanText(value || "", 512);
}

function routeFromGeoJson(coordinates, distanceMeters, durationSeconds) {
  if (!Array.isArray(coordinates) || coordinates.length < 2) return null;
  const points = coordinates.map((coord) => {
    if (!Array.isArray(coord) || coord.length < 2) return null;
    const lng = Number(coord[0]);
    const lat = Number(coord[1]);
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
    return {lat, lng};
  }).filter(Boolean);
  if (points.length < 2) return null;
  const distanceKm = Number.isFinite(distanceMeters) ? distanceMeters / 1000 : 0;
  return {
    points,
    distanceKm,
    durationMinutes: Number.isFinite(durationSeconds)
      ? Math.max(1, Math.min(999, Math.round(durationSeconds / 60)))
      : Math.max(1, Math.min(999, Math.round((distanceKm / 35) * 60))),
    isFallback: false,
  };
}

async function tryOpenRouteService(origin, destination) {
  const key = configuredKey("OPENROUTESERVICE_API_KEY", [
    "maps",
    "openrouteservice",
  ]);
  if (!key) return null;
  const url = new URL("https://api.openrouteservice.org/v2/directions/driving-car");
  url.searchParams.set("start", `${origin.lng},${origin.lat}`);
  url.searchParams.set("end", `${destination.lng},${destination.lat}`);
  url.searchParams.set("api_key", key);
  url.searchParams.set("format", "geojson");
  url.searchParams.set("geometry", "true");
  url.searchParams.set("instructions", "false");
  const data = await fetchJson(url, {endpoint: "openrouteservice"});
  const feature = data && Array.isArray(data.features) ? data.features[0] : null;
  const coords = feature && feature.geometry && feature.geometry.coordinates;
  const segment = feature && feature.properties &&
    Array.isArray(feature.properties.segments) ? feature.properties.segments[0] : null;
  return routeFromGeoJson(
    coords,
    Number(segment && segment.distance),
    Number(segment && segment.duration),
  );
}

async function tryOsrm(origin, destination) {
  const servers = [
    "https://router.project-osrm.org",
    "https://router.openstreetmap.de",
    "https://osrm-router.prod.aws.openstreetmap.de",
  ];
  for (const server of servers) {
    const url = new URL(`${server}/route/v1/driving/${origin.lng},${origin.lat};${destination.lng},${destination.lat}`);
    url.searchParams.set("overview", "full");
    url.searchParams.set("geometries", "geojson");
    url.searchParams.set("steps", "false");
    const data = await fetchJson(url, {endpoint: "osrm"});
    const route = data && Array.isArray(data.routes) ? data.routes[0] : null;
    const coords = route && route.geometry && route.geometry.coordinates;
    const result = routeFromGeoJson(coords, Number(route && route.distance), Number(route && route.duration));
    if (result) return result;
  }
  return null;
}

async function tryGraphHopper(origin, destination) {
  const key = configuredKey("GRAPHHOPPER_API_KEY", ["maps", "graphhopper"]);
  if (!key) return null;
  const url = new URL("https://graphhopper.com/api/1/route");
  url.searchParams.append("point", `${origin.lat},${origin.lng}`);
  url.searchParams.append("point", `${destination.lat},${destination.lng}`);
  url.searchParams.set("vehicle", "car");
  url.searchParams.set("key", key);
  url.searchParams.set("points_encoded", "false");
  url.searchParams.set("calc_points", "true");
  url.searchParams.set("instructions", "false");
  const data = await fetchJson(url, {endpoint: "graphhopper"});
  const path = data && Array.isArray(data.paths) ? data.paths[0] : null;
  const coords = path && path.points && path.points.coordinates;
  return routeFromGeoJson(coords, Number(path && path.distance), Number(path && path.time) / 1000);
}

async function tryMapbox(origin, destination) {
  const token = configuredKey("MAPBOX_ACCESS_TOKEN", ["maps", "mapbox"]);
  if (!token) return null;
  const url = new URL(`https://api.mapbox.com/directions/v5/mapbox/driving/${origin.lng},${origin.lat};${destination.lng},${destination.lat}`);
  url.searchParams.set("access_token", token);
  url.searchParams.set("geometries", "geojson");
  url.searchParams.set("overview", "full");
  url.searchParams.set("steps", "false");
  url.searchParams.set("alternatives", "false");
  const data = await fetchJson(url, {endpoint: "mapbox"});
  const route = data && Array.isArray(data.routes) ? data.routes[0] : null;
  const coords = route && route.geometry && route.geometry.coordinates;
  return routeFromGeoJson(coords, Number(route && route.distance), Number(route && route.duration));
}

exports.mapSearch = functions.region(REGION).https.onRequest(async (req, res) => {
  if (handleCors(req, res)) return;
  const query = cleanText(body(req).query, 120);
  const limit = cleanLimit(body(req).limit, 6, 10);
  if (query.length < 2) return sendJson(res, 200, {results: []});

  const url = new URL("https://nominatim.openstreetmap.org/search");
  url.searchParams.set("q", query);
  url.searchParams.set("format", "jsonv2");
  url.searchParams.set("addressdetails", "1");
  url.searchParams.set("countrycodes", "dz");
  url.searchParams.set("limit", String(limit));

  const data = await fetchJson(url, {endpoint: "nominatim-search"});
  return sendJson(res, 200, {results: normalizeNominatimItems(data, limit)});
});

exports.reverseGeocode = functions.region(REGION).https.onRequest(async (req, res) => {
  if (handleCors(req, res)) return;
  const position = cleanLatLng(body(req));
  if (!position) return sendJson(res, 200, {displayName: null});

  const url = new URL("https://nominatim.openstreetmap.org/reverse");
  url.searchParams.set("lat", String(position.lat));
  url.searchParams.set("lon", String(position.lng));
  url.searchParams.set("format", "jsonv2");
  url.searchParams.set("addressdetails", "1");
  url.searchParams.set("zoom", "18");

  const data = await fetchJson(url, {endpoint: "nominatim-reverse"});
  const displayName = data ? cleanText(data.display_name || "", 240) : "";
  return sendJson(res, 200, {displayName: displayName || null});
});

exports.nearbyPlaces = functions.region(REGION).https.onRequest(async (req, res) => {
  if (handleCors(req, res)) return;
  const position = cleanLatLng(body(req));
  const limit = cleanLimit(body(req).limit, 8, 20);
  if (!position) return sendJson(res, 200, {results: []});

  const query = `
    [out:json][timeout:5];
    (
      node["shop"~"car|car_repair|car_parts|tire|vulcanizer|motorcycle|motorcycle_repair"](around:5000,${position.lat},${position.lng});
      node["amenity"="fuel"](around:5000,${position.lat},${position.lng});
      node["amenity"="car_wash"](around:5000,${position.lat},${position.lng});
      node["craft"="car_repair"](around:5000,${position.lat},${position.lng});
      way["shop"~"car|car_repair|car_parts|tire"](around:5000,${position.lat},${position.lng});
      way["amenity"="fuel"](around:5000,${position.lat},${position.lng});
    );
    out center body ${limit};
  `;
  const url = new URL("https://overpass-api.de/api/interpreter");
  url.searchParams.set("data", query);
  const data = await fetchJson(url, {endpoint: "overpass", timeoutMs: 8000});
  return sendJson(res, 200, {results: normalizeOverpassElements(data, limit)});
});

exports.routeDirections = functions.region(REGION).https.onRequest(async (req, res) => {
  if (handleCors(req, res)) return;
  const origin = cleanLatLng(body(req).origin);
  const destination = cleanLatLng(body(req).destination);
  if (!origin || !destination) {
    return sendJson(res, 200, {route: null});
  }

  const route =
    await tryOpenRouteService(origin, destination) ||
    await tryOsrm(origin, destination) ||
    await tryGraphHopper(origin, destination) ||
    await tryMapbox(origin, destination) ||
    fallbackRoute(origin, destination);

  return sendJson(res, 200, {route});
});
