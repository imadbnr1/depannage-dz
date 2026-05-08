import re
import os
from collections import defaultdict

# This script will scan the Flutter project for hardcoded strings
# and generate localization entries

def extract_hardcoded_strings():
    # This is a simplified version - in practice, you would implement
    # a more comprehensive extraction
    
    # Sample hardcoded strings found in the codebase (based on our grep results)
    hardcoded_strings = [
        # From various Text() widgets
        'Titre et message obligatoires',
        'La date de fin doit etre apres la date de debut',
        'Notification envoyee',
        'Impossible de lire cette image.',
        'Image selectionnee. Elle sera envoyee avec la notification.',
        'Echec de l upload de l image',
        'Tarification mise a jour',
        'Journal indisponible',
        'Impossible de charger l audit admin.',
        'Admin Activity Log',
        'Rechercher action, admin, cible ou resume...',
        'Tout', 'Blocages', 'Approvals', 'Notifications', 'Annulations',
        'Aucune activite', 'Les actions admin apparaitront ici.',
        'Aujourd hui', 'Hier', '7 derniers jours', '30 derniers jours',
        'Toutes les donnees', 'Periode personnalisee',
        'Demandes filtrees', 'Actives', 'Terminees', 'Annulees', 'Chiffre filtre',
        'Commission plateforme', 'Basee sur $commissionPercent %',
        'Panier moyen', 'Moyenne par mission terminee',
        'Provider', 'Destination',
        'Montant', 'Debut', 'Fin',
        'Periode', 'En recherche', 'Taux completion', 'Commission',
        'Tout le monde', 'Customers', 'Providers',
        'Une fois par session', 'Toujours a l ouverture',
        'Offre', 'Reduction', 'Annonce',
        'Effacer la planification',
        'Envoi...', 'Envoyer',
        'Sauvegarde...', 'Sauvegarder',
        'Plus recentes', 'Plus anciennes', 'Prix le plus eleve',
        'Forcer annulation',
        'Compris',
        'Validation en attente',
        'Choisir destination',
        'Choisir sur la carte',
        'Ouvrir le suivi', 'Annuler la demande',
        'Annuler la mission', 'Fermer',
        'Mission introuvable',
        'Ouvrir Maps',
        'Evaluer le provider',
        'Demande introuvable',
        'Ajouter un commentaire...',
        'Nouveau message de $senderName',
        'Choisissez un point de depart valide.',
        'Choisissez une destination valide.',
        'Position: ${currentPos.latitude.toStringAsFixed(5)}, ${currentPos.longitude.toStringAsFixed(5)}',
        'Erreur chargement profil: $e',
        'Profil provider mis a jour',
        'Erreur sauvegarde: $e',
        'Telephone', 'Type de vehicule', 'Plaque',
        'Vous', 'Nom complet', 'Telephone',
        'Vehicule', 'Depart', 'Destination', 'Provider', 'Repere',
        'Aucun historique', 'Aucune demande active', 'Aucune activite',
        'Distance', 'ETA', 'Prix', 'Vehicule', 'Depart', 'Destination',
        'Pick up', 'Client', 'Dest',
        'Chat provider', 'Accueil', 'Demandes', 'Historique', 'Profil', 'Support',
        'Telephone', 'WhatsApp', 'Email', 'Adresse', 'Horaires', 'Confidentialite', 'Conditions',
        'Nouveau message',
        'Tout', 'Clients', 'Providers',
        'Retirer', 'Tout le monde', 'Customers', 'Providers',
        'Une fois par session', 'Toujours a l ouverture',
        'Offre', 'Reduction', 'Annonce',
        'Effacer la planification',
        'Envoi...', 'Envoyer',
        'Sauvegarde...', 'Sauvegarder',
        'Plus recentes', 'Plus anciennes', 'Prix le plus eleve',
        'Forcer annulation',
        'Compris',
        'Validation en attente',
        'Choisir destination',
        'Choisir sur la carte',
        'Ouvrir le suivi', 'Annuler la demande',
        'Annuler la mission', 'Fermer',
        'Mission introuvable',
        'Ouvrir Maps',
        'Evaluer le provider',
        'Demande introuvable',
        'Ajouter un commentaire...',
        'Nouveau message de $senderName',
        'Choisissez un point de depart valide.',
        'Choisissez une destination valide.',
        'Position: ${currentPos.latitude.toStringAsFixed(5)}, ${currentPos.longitude.toStringAsFixed(5)}',
        'Erreur chargement profil: $e',
        'Profil provider mis a jour',
        'Erreur sauvegarde: $e',
        'Telephone', 'Type de vehicule', 'Plaque',
        'Vous', 'Nom complet', 'Telephone',
        'Vehicule', 'Depart', 'Destination', 'Provider', 'Repere',
        'Aucun historique', 'Aucune demande active', 'Aucune activite',
        'Distance', 'ETA', 'Prix', 'Vehicule', 'Depart', 'Destination',
        'Pick up', 'Client', 'Dest',
        'Chat provider', 'Accueil', 'Demandes', 'Historique', 'Profil', 'Support',
        'Telephone', 'WhatsApp', 'Email', 'Adresse', 'Horaires', 'Confidentialite', 'Conditions',
        'Nouveau message',
        'Tout', 'Clients', 'Providers',
    ]
    
    # Remove duplicates while preserving order
    seen = set()
    unique_strings = []
    for s in hardcoded_strings:
        if s not in seen:
            seen.add(s)
            unique_strings.append(s)
    
    return unique_strings

def create_localization_keys(strings):
    # Create localization keys from strings
    localization_entries = {}
    
    for string in strings:
        # Create a key based on the string content
        # Convert to lowercase and replace spaces with underscores
        key = string.lower().replace(' ', '_').replace('-', '_').replace('.', '_').replace(',', '_')
        # Remove special characters
        key = re.sub(r'[^a-zA-Z0-9_]', '', key)
        # Remove multiple underscores
        key = re.sub(r'_+', '_', key)
        # Remove leading/trailing underscores
        key = key.strip('_')
        
        # If the key is empty or too short, create a generic one
        if not key or len(key) < 2:
            key = f"string_{len(localization_entries)}"
        
        localization_entries[key] = {
            'french': string,
            'english': string,  # Will need to be translated
            'arabic': string    # Will need to be translated
        }
    
    return localization_entries

def main():
    strings = extract_hardcoded_strings()
    localization_keys = create_localization_keys(strings)
    
    print(f"Found {len(strings)} unique hardcoded strings")
    print(f"Generated {len(localization_keys)} localization keys")
    
    # Print sample of the localization keys
    print("\nSample localization keys:")
    for i, (key, translations) in enumerate(list(localization_keys.items())[:10]):
        print(f"  '{key}': '{translations['french']}'")
        
    # Generate the Dart code for the localization file
    print("\nGenerated Dart code for app_localizations.dart:")
    print("\n// New entries to add to _translations map:")
    
    # Print French entries
    print("\n// French entries:")
    for key, translations in list(localization_keys.items())[:5]:
        print(f"      '{key}': '{translations['french']}',")
        
    # Print English entries
    print("\n// English entries:")
    for key, translations in list(localization_keys.items())[:5]:
        print(f"      '{key}': '{translations['english']}',")
        
    # Print Arabic entries
    print("\n// Arabic entries:")
    for key, translations in list(localization_keys.items())[:5]:
        print(f"      '{key}': '{translations['arabic']}',")

if __name__ == "__main__":
    main()