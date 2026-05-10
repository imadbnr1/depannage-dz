# Feature Specification: Restore Draggable Bottom Panels

**Feature Branch**: `001-restore-draggable-panels`  
**Created**: 2026-05-10  
**Status**: Draft  
**Input**: User description: "Restore draggable bottom panels after regression across customer and provider map/tracking pages. Panels currently snap back, cannot fully collapse or expand, feel blocked, fight map interactions, rebuild during drag, have unstable snapping, may move floating controls incorrectly, and must be restored without redesigning pages or touching unrelated security, authentication, dispatch, or business logic."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Smooth Panel Control (Priority: P1)

As a customer or provider using a map-based workflow, I need the bottom panel to drag smoothly between its available positions so I can inspect map context and mission details without the interface fighting my gesture.

**Why this priority**: Broken panel movement blocks core customer and provider workflows and makes tracking/dispatch screens feel unreliable.

**Independent Test**: Can be fully tested by opening each affected map or tracking screen, dragging the bottom panel from its default position to collapsed, intermediate, and expanded states, and confirming the panel follows the gesture without snapping back unexpectedly.

**Acceptance Scenarios**:

1. **Given** an affected map screen is visible, **When** the user drags the panel upward, **Then** the panel expands smoothly to the intended upper extent and remains there after release.
2. **Given** an affected map screen is visible, **When** the user drags the panel downward, **Then** the panel collapses smoothly to the intended lower extent and remains there after release.
3. **Given** the panel is midway through a drag, **When** the drag continues, **Then** the panel does not reset to its initial position because of unrelated screen updates.

---

### User Story 2 - Map Interaction Remains Reliable (Priority: P2)

As a user viewing a mission or service map, I need map gestures and panel gestures to stay distinct so I can pan, zoom, and drag the panel without accidental blocking or gesture conflict.

**Why this priority**: The map and panel share the primary screen area; interaction conflict makes live assistance workflows harder to complete.

**Independent Test**: Can be fully tested by panning and zooming the map, then dragging the panel repeatedly on each affected screen, confirming map gestures remain responsive and panel gestures only control the panel.

**Acceptance Scenarios**:

1. **Given** the user starts a gesture on the map area, **When** they pan or zoom, **Then** the map responds normally and the panel does not jump.
2. **Given** the user starts a gesture on the panel area or its handle, **When** they drag vertically, **Then** the panel responds normally and the map does not steal the gesture.

---

### User Story 3 - Stable Floating Controls and Layout (Priority: P3)

As a user navigating a map screen, I need floating controls and panel content to remain visible, correctly positioned, and free of bottom overflow while the panel changes height.

**Why this priority**: Floating controls help users recenter, access location actions, or inspect map details; misplaced controls and overflow reduce trust in the app quality.

**Independent Test**: Can be fully tested by dragging panels across all allowed extents on phone-sized, tablet-sized, and web-sized viewports and checking that floating controls track the visible panel height without overlapping key content.

**Acceptance Scenarios**:

1. **Given** a panel is collapsed, **When** floating map controls are visible, **Then** the controls sit above the visible panel edge and remain tappable.
2. **Given** a panel is expanded, **When** the screen is checked for layout issues, **Then** panel content remains usable without bottom overflow.
3. **Given** the app receives live map or mission updates while the panel is open, **When** the update is reflected, **Then** the visible panel state and floating control placement remain stable.

### Edge Cases

- Rapid repeated drags between collapsed and expanded positions must not leave the panel stuck between states.
- Live mission, route, or location updates during a drag must not reset the panel position.
- Very small mobile heights and wide web layouts must preserve panel usability without bottom overflow.
- Snap behavior must only occur at predictable resting points and must not prevent users from reaching the allowed collapsed or expanded states.
- Floating controls must not follow transient drag values in a way that causes jitter, overlap, or layout jumps.
- The affected screens are limited to: customer home, customer tracking, provider dashboard, provider tracking, and provider mission details.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST restore smooth draggable bottom panel behavior on all affected customer and provider map screens.
- **FR-002**: The system MUST allow each affected panel to reach its intended collapsed and expanded states without snapping back to the default state after the user releases the drag.
- **FR-003**: The system MUST preserve each panel's visible state during ordinary screen updates, including map, mission, route, and location refreshes.
- **FR-004**: The system MUST keep panel drag gestures and map gestures from interfering with each other in normal use.
- **FR-005**: The system MUST keep floating map controls aligned with the visible panel height so controls remain accessible and do not overlap important panel content.
- **FR-006**: The system MUST prevent bottom overflow and layout jumps across mobile and web-sized layouts.
- **FR-007**: The system MUST preserve current visual design, content, navigation, localization behavior, and customer/provider flows.
- **FR-008**: The system MUST avoid changes to authentication, security configuration, dispatch, provider presence, tracking data storage, or other business logic outside the panel regression scope.
- **FR-009**: The diagnosis MUST cover each affected panel separately and identify the user-visible cause of any reset, blocked drag, unstable snap, rebuild, or floating-control positioning problem found.
- **FR-010**: The fix MUST be verified with project-standard formatting and static analysis checks before being considered ready.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On each affected screen, users can move the panel from default to collapsed and default to expanded in at least 9 out of 10 manual attempts without unintended snap-back.
- **SC-002**: During continuous dragging for 5 seconds, no affected panel visibly resets to its initial state because of unrelated map or mission updates.
- **SC-003**: Map pan and zoom gestures remain responsive on all affected screens, with no observed panel jump when the gesture starts outside the panel area.
- **SC-004**: Floating controls remain visible, tappable, and above the panel edge at collapsed, default, and expanded states on representative mobile and web viewport sizes.
- **SC-005**: No bottom overflow or clipped primary action is visible on the affected screens during collapsed, default, or expanded panel states.
- **SC-006**: Existing customer and provider task flows remain unchanged, and no security, dispatch, authentication, or provider presence behavior is modified by this feature.

## Assumptions

- The intended design is to restore the previous smooth panel experience, not introduce a new visual design or navigation model.
- Existing panel content, labels, localization behavior, and screen-specific actions remain in scope only for preservation, not redesign.
- Snap points may be adjusted or removed only when that improves the user experience and still allows users to reach the intended collapsed and expanded states.
- Project context from AGENTS.md and repomix-flutter.txt is authoritative for security, architecture, map behavior, and quality constraints.
- Verification during implementation will include the affected pages named in the request and the standard project checks required by AGENTS.md.
