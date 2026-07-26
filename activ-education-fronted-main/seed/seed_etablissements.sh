#!/bin/bash
# seed_etablissements.sh — Généré automatiquement par generate_seed_etablissements.py
# Source : https://docs.google.com/spreadsheets/d/1iL39mVkJTQ0rEB-jhlfXzaiOAHzOxdJZay_3LUljq_U
# Usage: bash seed_etablissements.sh [email] [password]
set -e
API="${API_URL:-http://localhost:8080/api/v1}"
EMAIL="${1:-admin@activeducation.tg}"
PASS="${2:-abalakata}"

echo "=== Authentification ==="
TOKEN=$(curl -s -X POST "$API/auth/login" -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL\", \"motDePasse\": \"$PASS\"}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['accessToken'])")
AUTH="Authorization: Bearer $TOKEN"
echo "Token obtenu"

post() { curl -s -o /dev/null -X POST "$API/$1" -H "$AUTH" -H "Content-Type: application/json" -d "$2"; }

echo "╔═══════════════════════════════════════════════╗"
echo "║  SEED ÉTABLISSEMENTS (feuille officielle)    ║"
echo "╚═══════════════════════════════════════════════╝"

echo "  TG-UL-001 - Université de Lomé"
post "bibliotheque/etablissements" \
  '{"titre": "Université de Lomé", "resume": "Première université publique du Togo, fondée en 1970. Compte plusieurs facultés : Sciences, Lettres, Droit, Économie, Médecine, et écoles doctorales.", "contenu": "Première université publique du Togo, fondée en 1970. Compte plusieurs facultés : Sciences, Lettres, Droit, Économie, Médecine, et écoles doctorales.", "estPublie": true, "adresse": "BP 1515, Boulevard Eyadema", "ville": "Lomé", "typeEtablissement": "UNIVERSITE", "niveau": "Licence, Master, Doctorat", "contacts": "+228 22 22 29 61 / contact@univ-lome.tg", "siteWeb": "https://www.univ-lome.tg", "offreFormation": "Facultés: Sciences, Lettres et Sciences Humaines, Droit, Sciences Économiques et de Gestion, Médecine, Sciences de la Santé. Écoles: École Supérieure d'\''Agronomie, Institut National des Sciences de l'\''Éducation. Programmes de Licence (3 ans), Master (2 ans), Doctorat (3 ans). Domaines: Sciences Exactes, Sciences Humaines, Droit, Économie, Santé, Agronomie.", "estPublic": true}'

echo "  TG-UK-002 - Université de Kara"
post "bibliotheque/etablissements" \
  '{"titre": "Université de Kara", "resume": "Deuxième université publique du Togo, située dans la région de la Kara depuis 2004. Elle dessert tout le nord du pays.", "contenu": "Deuxième université publique du Togo, située dans la région de la Kara depuis 2004. Elle dessert tout le nord du pays.", "estPublie": true, "adresse": "BP 43, Kara", "ville": "Kara", "typeEtablissement": "UNIVERSITE", "niveau": "Licence, Master, Doctorat", "contacts": "+228 26 60 16 00 / contact@univ-kara.tg", "siteWeb": "https://www.univ-kara.tg", "offreFormation": "Facultés: Sciences et Techniques, Lettres et Sciences Humaines, Droit et Sciences Politiques, Sciences Économiques et de Gestion. Licence (3 ans), Master (2 ans), Doctorat (3 ans). Filières: Informatique, Mathématiques, Physique-Chimie, Biologie, Lettres Modernes, Anglais, Sociologie, Géographie, Droit, Économie, Gestion.", "estPublic": true}'

echo "  TG-ENS-003 - École Normale Supérieure d'Atakpamé"
post "bibliotheque/etablissements" \
  '{"titre": "École Normale Supérieure d'\''Atakpamé", "resume": "École Normale Supérieure d'\''Atakpamé — Établissement d'\''enseignement supérieur au Togo.", "contenu": "École Normale Supérieure d'\''Atakpamé — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-EPL-004 - École Polytechnique de Lomé"
post "bibliotheque/etablissements" \
  '{"titre": "École Polytechnique de Lomé", "resume": "École Polytechnique de Lomé — Établissement d'\''enseignement supérieur au Togo.", "contenu": "École Polytechnique de Lomé — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-ISICA-005 - Institut des Sciences de l'Information, de la Communication et des Arts"
post "bibliotheque/etablissements" \
  '{"titre": "Institut des Sciences de l'\''Information, de la Communication et des Arts", "resume": "Institut des Sciences de l'\''Information, de la Communication et des Arts — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Institut des Sciences de l'\''Information, de la Communication et des Arts — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-CIREL-006 - Centre International de Recherche et d'Étude de Langues – Village du Bénin"
post "bibliotheque/etablissements" \
  '{"titre": "Centre International de Recherche et d'\''Étude de Langues – Village du Bénin", "resume": "Centre public spécialisé dans l'\''enseignement et la recherche en langues, situé à Village du Bénin. Rattaché à l'\''Université de Lomé.", "contenu": "Centre public spécialisé dans l'\''enseignement et la recherche en langues, situé à Village du Bénin. Rattaché à l'\''Université de Lomé.", "estPublie": true, "adresse": "Village du Bénin", "ville": "Lomé", "typeEtablissement": "GRANDE_ECOLE", "niveau": "Licence, Master", "contacts": "+228 22 21 56 74", "siteWeb": "", "offreFormation": "Formation en langues et linguistique. Programmes de Licence et Master en Anglais, Allemand, Espagnol, Français Langue Étrangère, Linguistique Appliquée. Recherche en didactique des langues et linguistique africaine.", "estPublic": true}'

echo "  TG-UCAO-007 - Université Catholique de l'Afrique de l'Ouest – Unité Universitaire du Togo"
post "bibliotheque/etablissements" \
  '{"titre": "Université Catholique de l'\''Afrique de l'\''Ouest – Unité Universitaire du Togo", "resume": "Université privée catholique membre du réseau UCAO. Formations en sciences sociales, juridiques et économiques.", "contenu": "Université privée catholique membre du réseau UCAO. Formations en sciences sociales, juridiques et économiques.", "estPublie": true, "adresse": "BP 20258, Lomé", "ville": "Lomé", "typeEtablissement": "UNIVERSITE", "niveau": "Licence, Master", "contacts": "+228 22 21 46 65 / info@ucao-uut.tg", "siteWeb": "https://www.ucao-uut.tg", "offreFormation": "Facultés: Droit, Sciences Économiques et de Gestion, Sciences Sociales, Lettres et Sciences Humaines. Licence (3 ans), Master (2 ans). Filières: Droit des Affaires, Économie, Gestion des Entreprises, Sociologie, Psychologie, Communication, Sciences Politiques.", "estPublic": false}'

echo "  TG-ESGIS-008 - École Supérieure de Gestion, d'Informatique et des Sciences"
post "bibliotheque/etablissements" \
  '{"titre": "École Supérieure de Gestion, d'\''Informatique et des Sciences", "resume": "Grande école privée spécialisée en gestion, informatique et technologies. L'\''un des plus grands établissements privés du Togo.", "contenu": "Grande école privée spécialisée en gestion, informatique et technologies. L'\''un des plus grands établissements privés du Togo.", "estPublie": true, "adresse": "BP 80665, Lomé", "ville": "Lomé", "typeEtablissement": "GRANDE_ECOLE", "niveau": "Licence, Master", "contacts": "+228 22 21 60 60 / info@esgis.tg", "siteWeb": "https://www.esgis.tg", "offreFormation": "Écoles: ESGIS Management, ESGIS Informatique, ESGIS Communication. Programmes: Licence (3 ans), Master (2 ans), MBA. Filières: Informatique de Gestion, Génie Logiciel, Réseaux et Télécommunications, Marketing, Finance, Comptabilité, Audiovisuel, Design Graphique.", "estPublic": false}'

echo "  TG-IAI-009 - Institut Africain d'Informatique – Représentation du Togo"
post "bibliotheque/etablissements" \
  '{"titre": "Institut Africain d'\''Informatique – Représentation du Togo", "resume": "Institut privé spécialisé en administration des affaires et études commerciales.", "contenu": "Institut privé spécialisé en administration des affaires et études commerciales.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "GRANDE_ECOLE", "niveau": "Licence, Master", "contacts": "+228 22 21 00 00", "siteWeb": "", "offreFormation": "Formations en Administration des Affaires, Commerce International, Marketing, Gestion des Ressources Humaines, Finance, Comptabilité. Licence (3 ans), Master (2 ans).", "estPublic": false}'

echo "  TG-EAMAU-010 - École Africaine des Métiers de l'Architecture et de l'Urbanisme"
post "bibliotheque/etablissements" \
  '{"titre": "École Africaine des Métiers de l'\''Architecture et de l'\''Urbanisme", "resume": "École Africaine des Métiers de l'\''Architecture et de l'\''Urbanisme — Établissement d'\''enseignement supérieur au Togo.", "contenu": "École Africaine des Métiers de l'\''Architecture et de l'\''Urbanisme — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "https://www.eamau.org", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-IHERIS-011 - Institut des Hautes Études des Relations Internationales et Stratégiques"
post "bibliotheque/etablissements" \
  '{"titre": "Institut des Hautes Études des Relations Internationales et Stratégiques", "resume": "Institut des Hautes Études des Relations Internationales et Stratégiques — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Institut des Hautes Études des Relations Internationales et Stratégiques — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-GUST-012 - Global University of Science & Technology – Togo"
post "bibliotheque/etablissements" \
  '{"titre": "Global University of Science & Technology – Togo", "resume": "Université privée spécialisée en sciences, technologies et innovation.", "contenu": "Université privée spécialisée en sciences, technologies et innovation.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "UNIVERSITE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations en Sciences et Technologies: Informatique, Intelligence Artificielle, Data Science, Biotechnologies, Sciences de l'\''Ingénieur.", "estPublic": false}'

echo "  TG-ESTECA-013 - École Supérieure de Technologie du Cinéma et de l'Audiovisuel"
post "bibliotheque/etablissements" \
  '{"titre": "École Supérieure de Technologie du Cinéma et de l'\''Audiovisuel", "resume": "École privée spécialisée dans les métiers de la mode, du design et des arts plastiques.", "contenu": "École privée spécialisée dans les métiers de la mode, du design et des arts plastiques.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence", "contacts": "", "siteWeb": "", "offreFormation": "Formations en Stylisme, Création de Mode, Design Textile, Arts Plastiques, Design Graphique.", "estPublic": false}'

echo "  TG-ISTB-014 - International School of Technology and Business"
post "bibliotheque/etablissements" \
  '{"titre": "International School of Technology and Business", "resume": "École internationale privée alliant technologie et commerce. Programmes bilingues français/anglais.", "contenu": "École internationale privée alliant technologie et commerce. Programmes bilingues français/anglais.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Programmes bilingues en Technologies de l'\''Information, Business Management, Finance Internationale, Marketing Digital.", "estPublic": false}'

echo "  TG-ESAG-015 - École Supérieure d'Administration et de Gestion Notre Dame de l'Église"
post "bibliotheque/etablissements" \
  '{"titre": "École Supérieure d'\''Administration et de Gestion Notre Dame de l'\''Église", "resume": "École privée spécialisée dans les métiers de la mode, du design et des arts plastiques.", "contenu": "École privée spécialisée dans les métiers de la mode, du design et des arts plastiques.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence", "contacts": "", "siteWeb": "https://esagnde.org", "offreFormation": "Formations en Stylisme, Création de Mode, Design Textile, Arts Plastiques, Design Graphique.", "estPublic": false}'

echo "  TG-CERFER-016 - Centre Régional de Formation pour Entretien Routier"
post "bibliotheque/etablissements" \
  '{"titre": "Centre Régional de Formation pour Entretien Routier", "resume": "Centre Régional de Formation pour Entretien Routier — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Centre Régional de Formation pour Entretien Routier — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "CENTRE_FORMATION_PROFESSIONNELLE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-USTTG-017 - Université des Sciences et Technologies du Togo"
post "bibliotheque/etablissements" \
  '{"titre": "Université des Sciences et Technologies du Togo", "resume": "Université des Sciences et Technologies du Togo — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Université des Sciences et Technologies du Togo — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "UNIVERSITE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "https://rusta-usttg.org", "offreFormation": "Formations supérieures à Lomé.", "estPublic": true}'

echo "  TG-ESMA-018 - École Supérieure de Management des Affaires"
post "bibliotheque/etablissements" \
  '{"titre": "École Supérieure de Management des Affaires", "resume": "Grande école privée de commerce et de gestion. Propose des programmes en management, finance et entrepreneuriat.", "contenu": "Grande école privée de commerce et de gestion. Propose des programmes en management, finance et entrepreneuriat.", "estPublie": true, "adresse": "BP 81170, Lomé", "ville": "Lomé", "typeEtablissement": "GRANDE_ECOLE", "niveau": "Licence, Master", "contacts": "+228 22 21 35 00 / contact@esa.tg", "siteWeb": "https://www.esa.tg", "offreFormation": "Programmes: Licence en Commerce et Gestion (3 ans), Master en Management des Entreprises (2 ans), MBA. Filières: Marketing, Finance d'\''Entreprise, Ressources Humaines, Logistique, Commerce International, Entrepreneuriat.", "estPublic": false}'

echo "  TG-ISMA-019 - Institut Supérieur de Management Adonaï"
post "bibliotheque/etablissements" \
  '{"titre": "Institut Supérieur de Management Adonaï", "resume": "Institut privé de formation en management et entrepreneuriat.", "contenu": "Institut privé de formation en management et entrepreneuriat.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "+228 90 01 11 11", "siteWeb": "", "offreFormation": "Formations en Management, Entrepreneuriat, Marketing, Finance.", "estPublic": false}'

echo "  TG-HECM-020 - Haute École de Commerce et de Management"
post "bibliotheque/etablissements" \
  '{"titre": "Haute École de Commerce et de Management", "resume": "Haute École de Commerce et de Management — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Haute École de Commerce et de Management — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-ESA-021 - École Supérieure d'Agronomie"
post "bibliotheque/etablissements" \
  '{"titre": "École Supérieure d'\''Agronomie", "resume": "Grande école privée de commerce et de gestion. Propose des programmes en management, finance et entrepreneuriat.", "contenu": "Grande école privée de commerce et de gestion. Propose des programmes en management, finance et entrepreneuriat.", "estPublie": true, "adresse": "BP 81170, Lomé", "ville": "Lomé", "typeEtablissement": "GRANDE_ECOLE", "niveau": "Licence, Master", "contacts": "+228 22 21 35 00 / contact@esa.tg", "siteWeb": "https://www.esa.tg", "offreFormation": "Programmes: Licence en Commerce et Gestion (3 ans), Master en Management des Entreprises (2 ans), MBA. Filières: Marketing, Finance d'\''Entreprise, Ressources Humaines, Logistique, Commerce International, Entrepreneuriat.", "estPublic": false}'

echo "  TG-ESTBA-022 - École Supérieure des Techniques Biologiques et Alimentaires"
post "bibliotheque/etablissements" \
  '{"titre": "École Supérieure des Techniques Biologiques et Alimentaires", "resume": "Grande école privée de commerce et de gestion. Propose des programmes en management, finance et entrepreneuriat.", "contenu": "Grande école privée de commerce et de gestion. Propose des programmes en management, finance et entrepreneuriat.", "estPublie": true, "adresse": "BP 81170, Lomé", "ville": "Lomé", "typeEtablissement": "GRANDE_ECOLE", "niveau": "Licence, Master", "contacts": "+228 22 21 35 00 / contact@esa.tg", "siteWeb": "https://www.esa.tg", "offreFormation": "Programmes: Licence en Commerce et Gestion (3 ans), Master en Management des Entreprises (2 ans), MBA. Filières: Marketing, Finance d'\''Entreprise, Ressources Humaines, Logistique, Commerce International, Entrepreneuriat.", "estPublic": false}'

echo "  TG-IUTG-023 - Institut Universitaire de Technologie de Gestion"
post "bibliotheque/etablissements" \
  '{"titre": "Institut Universitaire de Technologie de Gestion", "resume": "Institut Universitaire de Technologie de Gestion — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Institut Universitaire de Technologie de Gestion — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-INSE-024 - Institut National des Sciences de l'Éducation"
post "bibliotheque/etablissements" \
  '{"titre": "Institut National des Sciences de l'\''Éducation", "resume": "Institut National des Sciences de l'\''Éducation — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Institut National des Sciences de l'\''Éducation — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-INJS-025 - Institut National de la Jeunesse et des Sports"
post "bibliotheque/etablissements" \
  '{"titre": "Institut National de la Jeunesse et des Sports", "resume": "Institut National de la Jeunesse et des Sports — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Institut National de la Jeunesse et des Sports — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-FSS-026 - Faculté des Sciences de la Santé – Université de Lomé"
post "bibliotheque/etablissements" \
  '{"titre": "Faculté des Sciences de la Santé – Université de Lomé", "resume": "Faculté des Sciences de la Santé – Université de Lomé — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Faculté des Sciences de la Santé – Université de Lomé — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "UNIVERSITE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": true}'

echo "  TG-FDS-027 - Faculté des Sciences – Université de Lomé"
post "bibliotheque/etablissements" \
  '{"titre": "Faculté des Sciences – Université de Lomé", "resume": "Faculté des Sciences – Université de Lomé — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Faculté des Sciences – Université de Lomé — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "UNIVERSITE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": true}'

echo "  TG-FDD-028 - Faculté de Droit – Université de Lomé"
post "bibliotheque/etablissements" \
  '{"titre": "Faculté de Droit – Université de Lomé", "resume": "Faculté de Droit – Université de Lomé — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Faculté de Droit – Université de Lomé — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "UNIVERSITE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": true}'

echo "  TG-FASEG-029 - Faculté des Sciences Économiques et de Gestion – Université de Lomé"
post "bibliotheque/etablissements" \
  '{"titre": "Faculté des Sciences Économiques et de Gestion – Université de Lomé", "resume": "Faculté des Sciences Économiques et de Gestion – Université de Lomé — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Faculté des Sciences Économiques et de Gestion – Université de Lomé — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "UNIVERSITE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": true}'

echo "  TG-FLLA-030 - Faculté des Lettres, Langues et Arts – Université de Lomé"
post "bibliotheque/etablissements" \
  '{"titre": "Faculté des Lettres, Langues et Arts – Université de Lomé", "resume": "Faculté des Lettres, Langues et Arts – Université de Lomé — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Faculté des Lettres, Langues et Arts – Université de Lomé — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "UNIVERSITE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": true}'

echo "  TG-FSHS-031 - Faculté des Sciences de l'Homme et de la Société – Université de Lomé"
post "bibliotheque/etablissements" \
  '{"titre": "Faculté des Sciences de l'\''Homme et de la Société – Université de Lomé", "resume": "Faculté des Sciences de l'\''Homme et de la Société – Université de Lomé — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Faculté des Sciences de l'\''Homme et de la Société – Université de Lomé — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "UNIVERSITE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": true}'

echo "  TG-IAEC-032 - Institut Africain d'Administration et d'Études Commerciales"
post "bibliotheque/etablissements" \
  '{"titre": "Institut Africain d'\''Administration et d'\''Études Commerciales", "resume": "Institut privé spécialisé en administration des affaires et études commerciales.", "contenu": "Institut privé spécialisé en administration des affaires et études commerciales.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "GRANDE_ECOLE", "niveau": "Licence, Master", "contacts": "+228 22 21 00 00", "siteWeb": "https://iaectogo.com/", "offreFormation": "Formations en Administration des Affaires, Commerce International, Marketing, Gestion des Ressources Humaines, Finance, Comptabilité. Licence (3 ans), Master (2 ans).", "estPublic": false}'

echo "  TG-ESAM-033 - École Supérieure d'Audit et de Management"
post "bibliotheque/etablissements" \
  '{"titre": "École Supérieure d'\''Audit et de Management", "resume": "Grande école privée de commerce et de gestion. Propose des programmes en management, finance et entrepreneuriat.", "contenu": "Grande école privée de commerce et de gestion. Propose des programmes en management, finance et entrepreneuriat.", "estPublie": true, "adresse": "BP 81170, Lomé", "ville": "Lomé", "typeEtablissement": "GRANDE_ECOLE", "niveau": "Licence, Master", "contacts": "+228 22 21 35 00 / contact@esa.tg", "siteWeb": "https://www.esa.tg", "offreFormation": "Programmes: Licence en Commerce et Gestion (3 ans), Master en Management des Entreprises (2 ans), MBA. Filières: Marketing, Finance d'\''Entreprise, Ressources Humaines, Logistique, Commerce International, Entrepreneuriat.", "estPublic": false}'

echo "  TG-LBS-034 - Lomé Business School"
post "bibliotheque/etablissements" \
  '{"titre": "Lomé Business School", "resume": "Lomé Business School — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Lomé Business School — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "https://lome-bs.com", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-FATAD-035 - Faculté de Théologie des Assemblées de Dieu (West Africa Advanced School of Theology)"
post "bibliotheque/etablissements" \
  '{"titre": "Faculté de Théologie des Assemblées de Dieu (West Africa Advanced School of Theology)", "resume": "Faculté de Théologie des Assemblées de Dieu (West Africa Advanced School of Theology) — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Faculté de Théologie des Assemblées de Dieu (West Africa Advanced School of Theology) — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-CIFOP-036 - Centre Informatique de Formation et d'Orientation Professionnelles"
post "bibliotheque/etablissements" \
  '{"titre": "Centre Informatique de Formation et d'\''Orientation Professionnelles", "resume": "Centre Informatique de Formation et d'\''Orientation Professionnelles — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Centre Informatique de Formation et d'\''Orientation Professionnelles — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "CENTRE_FORMATION_PROFESSIONNELLE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-ISDI-037 - Institut Supérieur de Droit et d'Interprétariat"
post "bibliotheque/etablissements" \
  '{"titre": "Institut Supérieur de Droit et d'\''Interprétariat", "resume": "Institut privé de formation en management et entrepreneuriat.", "contenu": "Institut privé de formation en management et entrepreneuriat.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "+228 90 01 11 11", "siteWeb": "", "offreFormation": "Formations en Management, Entrepreneuriat, Marketing, Finance.", "estPublic": false}'

echo "  TG-ISMAD-038 - Institut Supérieur de Management et de Développement"
post "bibliotheque/etablissements" \
  '{"titre": "Institut Supérieur de Management et de Développement", "resume": "Institut privé de formation en management et entrepreneuriat.", "contenu": "Institut privé de formation en management et entrepreneuriat.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "+228 90 01 11 11", "siteWeb": "", "offreFormation": "Formations en Management, Entrepreneuriat, Marketing, Finance.", "estPublic": false}'

echo "  TG-ESIG-039 - École Supérieure d'Informatique et de Gestion – Global Success"
post "bibliotheque/etablissements" \
  '{"titre": "École Supérieure d'\''Informatique et de Gestion – Global Success", "resume": "École privée spécialisée dans les métiers de la mode, du design et des arts plastiques.", "contenu": "École privée spécialisée dans les métiers de la mode, du design et des arts plastiques.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence", "contacts": "", "siteWeb": "https://esig.tg", "offreFormation": "Formations en Stylisme, Création de Mode, Design Textile, Arts Plastiques, Design Graphique.", "estPublic": false}'

echo "  TG-ESBTAO-040 - École Supérieure Baptiste de Théologie de l'Afrique de l'Ouest"
post "bibliotheque/etablissements" \
  '{"titre": "École Supérieure Baptiste de Théologie de l'\''Afrique de l'\''Ouest", "resume": "Grande école privée spécialisée en gestion, informatique et technologies. L'\''un des plus grands établissements privés du Togo.", "contenu": "Grande école privée spécialisée en gestion, informatique et technologies. L'\''un des plus grands établissements privés du Togo.", "estPublie": true, "adresse": "BP 80665, Lomé", "ville": "Lomé", "typeEtablissement": "GRANDE_ECOLE", "niveau": "Licence, Master", "contacts": "+228 22 21 60 60 / info@esgis.tg", "siteWeb": "https://www.esgis.tg", "offreFormation": "Écoles: ESGIS Management, ESGIS Informatique, ESGIS Communication. Programmes: Licence (3 ans), Master (2 ans), MBA. Filières: Informatique de Gestion, Génie Logiciel, Réseaux et Télécommunications, Marketing, Finance, Comptabilité, Audiovisuel, Design Graphique.", "estPublic": false}'

echo "  TG-ENA-041 - École Nationale d'Administration"
post "bibliotheque/etablissements" \
  '{"titre": "École Nationale d'\''Administration", "resume": "École publique de formation des enseignants du secondaire, située à Atakpamé. Forme des professeurs certifiés pour les lycées et collèges.", "contenu": "École publique de formation des enseignants du secondaire, située à Atakpamé. Forme des professeurs certifiés pour les lycées et collèges.", "estPublie": true, "adresse": "BP 10, Atakpamé", "ville": "Atakpamé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "+228 27 70 01 32", "siteWeb": "https://ena.tg", "offreFormation": "Formation des enseignants du secondaire. Filières: Mathématiques, Physique-Chimie, SVT, Lettres Modernes, Anglais, Histoire-Géographie. Licence d'\''Enseignement (3 ans), Master Enseignement (2 ans).", "estPublic": true}'

echo "  TG-ISDB-042 - Institut Supérieur de Philosophie et des Sciences Humaines Don Bosco"
post "bibliotheque/etablissements" \
  '{"titre": "Institut Supérieur de Philosophie et des Sciences Humaines Don Bosco", "resume": "Institut privé de formation en management et entrepreneuriat.", "contenu": "Institut privé de formation en management et entrepreneuriat.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "+228 90 01 11 11", "siteWeb": "", "offreFormation": "Formations en Management, Entrepreneuriat, Marketing, Finance.", "estPublic": false}'

echo "  TG-INFA-043 - Institut National de Formation Agricole de Tové"
post "bibliotheque/etablissements" \
  '{"titre": "Institut National de Formation Agricole de Tové", "resume": "Institut National de Formation Agricole de Tové — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Institut National de Formation Agricole de Tové — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-ENAM-044 - École Nationale des Auxiliaires Médicaux de Lomé"
post "bibliotheque/etablissements" \
  '{"titre": "École Nationale des Auxiliaires Médicaux de Lomé", "resume": "École publique de formation des auxiliaires médicaux (infirmiers, sages-femmes, techniciens de santé).", "contenu": "École publique de formation des auxiliaires médicaux (infirmiers, sages-femmes, techniciens de santé).", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence", "contacts": "", "siteWeb": "", "offreFormation": "Formation des professionnels de santé: Infirmier Diplômé d'\''État, Sage-Femme, Technicien de Laboratoire, Technicien de Radiologie.", "estPublic": true}'

echo "  TG-ISAGES-045 - Institut Supérieur d'Administration des Sciences Économiques et de Gestion (de Santé)"
post "bibliotheque/etablissements" \
  '{"titre": "Institut Supérieur d'\''Administration des Sciences Économiques et de Gestion (de Santé)", "resume": "Institut privé de formation en management et entrepreneuriat.", "contenu": "Institut privé de formation en management et entrepreneuriat.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "+228 90 01 11 11", "siteWeb": "", "offreFormation": "Formations en Management, Entrepreneuriat, Marketing, Finance.", "estPublic": false}'

echo "  TG-IPM-046 - Institut Supérieur Privé de Management du Togo"
post "bibliotheque/etablissements" \
  '{"titre": "Institut Supérieur Privé de Management du Togo", "resume": "Institut privé de formation en management et entrepreneuriat.", "contenu": "Institut privé de formation en management et entrepreneuriat.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "+228 90 01 11 11", "siteWeb": "", "offreFormation": "Formations en Management, Entrepreneuriat, Marketing, Finance.", "estPublic": false}'

echo "  TG-ESAF-047 - École Supérieure des Affaires"
post "bibliotheque/etablissements" \
  '{"titre": "École Supérieure des Affaires", "resume": "Grande école privée de commerce et de gestion. Propose des programmes en management, finance et entrepreneuriat.", "contenu": "Grande école privée de commerce et de gestion. Propose des programmes en management, finance et entrepreneuriat.", "estPublie": true, "adresse": "BP 81170, Lomé", "ville": "Lomé", "typeEtablissement": "GRANDE_ECOLE", "niveau": "Licence, Master", "contacts": "+228 22 21 35 00 / contact@esa.tg", "siteWeb": "https://www.esa.tg", "offreFormation": "Programmes: Licence en Commerce et Gestion (3 ans), Master en Management des Entreprises (2 ans), MBA. Filières: Marketing, Finance d'\''Entreprise, Ressources Humaines, Logistique, Commerce International, Entrepreneuriat.", "estPublic": false}'

echo "  TG-IFTS-048 - Institut de Formation Technique et Supérieure"
post "bibliotheque/etablissements" \
  '{"titre": "Institut de Formation Technique et Supérieure", "resume": "Institut de Formation Technique et Supérieure — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Institut de Formation Technique et Supérieure — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-IMAST-049 - Institut de Mathématiques, des Sciences et Technologies"
post "bibliotheque/etablissements" \
  '{"titre": "Institut de Mathématiques, des Sciences et Technologies", "resume": "Institut de Mathématiques, des Sciences et Technologies — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Institut de Mathématiques, des Sciences et Technologies — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-ESAT-050 - École Supérieure de l'Aéronautique et des Technologies – Togo"
post "bibliotheque/etablissements" \
  '{"titre": "École Supérieure de l'\''Aéronautique et des Technologies – Togo", "resume": "École privée spécialisée dans les métiers de la mode, du design et des arts plastiques.", "contenu": "École privée spécialisée dans les métiers de la mode, du design et des arts plastiques.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence", "contacts": "", "siteWeb": "", "offreFormation": "Formations en Stylisme, Création de Mode, Design Textile, Arts Plastiques, Design Graphique.", "estPublic": false}'

echo "  TG-ENSF-051 - École Nationale de Sages-Femmes de Lomé"
post "bibliotheque/etablissements" \
  '{"titre": "École Nationale de Sages-Femmes de Lomé", "resume": "École publique de formation des enseignants du secondaire, située à Atakpamé. Forme des professeurs certifiés pour les lycées et collèges.", "contenu": "École publique de formation des enseignants du secondaire, située à Atakpamé. Forme des professeurs certifiés pour les lycées et collèges.", "estPublie": true, "adresse": "BP 10, Atakpamé", "ville": "Atakpamé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "+228 27 70 01 32", "siteWeb": "", "offreFormation": "Formation des enseignants du secondaire. Filières: Mathématiques, Physique-Chimie, SVT, Lettres Modernes, Anglais, Histoire-Géographie. Licence d'\''Enseignement (3 ans), Master Enseignement (2 ans).", "estPublic": true}'

echo "  TG-ENAS-052 - École Nationale des Aides Sanitaires de Sokodé"
post "bibliotheque/etablissements" \
  '{"titre": "École Nationale des Aides Sanitaires de Sokodé", "resume": "École publique de formation des auxiliaires médicaux (infirmiers, sages-femmes, techniciens de santé).", "contenu": "École publique de formation des auxiliaires médicaux (infirmiers, sages-femmes, techniciens de santé).", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence", "contacts": "", "siteWeb": "https://ena.tg", "offreFormation": "Formation des professionnels de santé: Infirmier Diplômé d'\''État, Sage-Femme, Technicien de Laboratoire, Technicien de Radiologie.", "estPublic": true}'

echo "  TG-IASTM-053 - Institut Africain des Sciences, des Technologies et des Métiers"
post "bibliotheque/etablissements" \
  '{"titre": "Institut Africain des Sciences, des Technologies et des Métiers", "resume": "Institut privé spécialisé en administration des affaires et études commerciales.", "contenu": "Institut privé spécialisé en administration des affaires et études commerciales.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "GRANDE_ECOLE", "niveau": "Licence, Master", "contacts": "+228 22 21 00 00", "siteWeb": "", "offreFormation": "Formations en Administration des Affaires, Commerce International, Marketing, Gestion des Ressources Humaines, Finance, Comptabilité. Licence (3 ans), Master (2 ans).", "estPublic": false}'

echo "  TG-ESSEG-054 - École Supérieure des Sciences Économiques, de Gestion et de la Statistique (Dr Djoka)"
post "bibliotheque/etablissements" \
  '{"titre": "École Supérieure des Sciences Économiques, de Gestion et de la Statistique (Dr Djoka)", "resume": "École Supérieure des Sciences Économiques, de Gestion et de la Statistique (Dr Djoka) — Établissement d'\''enseignement supérieur au Togo.", "contenu": "École Supérieure des Sciences Économiques, de Gestion et de la Statistique (Dr Djoka) — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-ISTAK-055 - Institut des Sciences, Technologies et Arts – Kara"
post "bibliotheque/etablissements" \
  '{"titre": "Institut des Sciences, Technologies et Arts – Kara", "resume": "Institut des Sciences, Technologies et Arts – Kara — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Institut des Sciences, Technologies et Arts – Kara — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-CFBT-056 - Centre de Formation Bancaire du Togo"
post "bibliotheque/etablissements" \
  '{"titre": "Centre de Formation Bancaire du Togo", "resume": "Centre privé spécialisé dans la formation aux métiers de la banque et de la finance.", "contenu": "Centre privé spécialisé dans la formation aux métiers de la banque et de la finance.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "CENTRE_FORMATION_PROFESSIONNELLE", "niveau": "Formation professionnelle", "contacts": "", "siteWeb": "", "offreFormation": "Formations professionnelles en Banque, Finance, Assurance, Microfinance. Programmes certifiants.", "estPublic": false}'

echo "  TG-ENFS-057 - École Nationale de Formation Sociale"
post "bibliotheque/etablissements" \
  '{"titre": "École Nationale de Formation Sociale", "resume": "École publique de formation des enseignants du secondaire, située à Atakpamé. Forme des professeurs certifiés pour les lycées et collèges.", "contenu": "École publique de formation des enseignants du secondaire, située à Atakpamé. Forme des professeurs certifiés pour les lycées et collèges.", "estPublie": true, "adresse": "BP 10, Atakpamé", "ville": "Atakpamé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "+228 27 70 01 32", "siteWeb": "https://ena.tg", "offreFormation": "Formation des enseignants du secondaire. Filières: Mathématiques, Physique-Chimie, SVT, Lettres Modernes, Anglais, Histoire-Géographie. Licence d'\''Enseignement (3 ans), Master Enseignement (2 ans).", "estPublic": true}'

echo "  TG-ESIBA-058 - ESIBA Business School (École Supérieure d'Informatique, de Business et d'Administration)"
post "bibliotheque/etablissements" \
  '{"titre": "ESIBA Business School (École Supérieure d'\''Informatique, de Business et d'\''Administration)", "resume": "ESIBA Business School (École Supérieure d'\''Informatique, de Business et d'\''Administration) — Établissement d'\''enseignement supérieur au Togo.", "contenu": "ESIBA Business School (École Supérieure d'\''Informatique, de Business et d'\''Administration) — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-ESPC-059 - École Supérieure des Ponts et Chaussées"
post "bibliotheque/etablissements" \
  '{"titre": "École Supérieure des Ponts et Chaussées", "resume": "École privée d'\''ingénieurs située à Aného, spécialisée dans les formations techniques et scientifiques.", "contenu": "École privée d'\''ingénieurs située à Aného, spécialisée dans les formations techniques et scientifiques.", "estPublie": true, "adresse": "Aného", "ville": "Aného", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence", "contacts": "", "siteWeb": "", "offreFormation": "Formations d'\''ingénieurs et techniciens supérieurs. Filières: Génie Civil, Génie Électrique, Génie Informatique, Énergies Renouvelables.", "estPublic": false}'

echo "  TG-ESRID-060 - École Supérieure de Relations Internationales et de Diplomatie"
post "bibliotheque/etablissements" \
  '{"titre": "École Supérieure de Relations Internationales et de Diplomatie", "resume": "Grande école privée spécialisée en gestion, informatique et technologies. L'\''un des plus grands établissements privés du Togo.", "contenu": "Grande école privée spécialisée en gestion, informatique et technologies. L'\''un des plus grands établissements privés du Togo.", "estPublie": true, "adresse": "BP 80665, Lomé", "ville": "Lomé", "typeEtablissement": "GRANDE_ECOLE", "niveau": "Licence, Master", "contacts": "+228 22 21 60 60 / info@esgis.tg", "siteWeb": "https://www.esgis.tg", "offreFormation": "Écoles: ESGIS Management, ESGIS Informatique, ESGIS Communication. Programmes: Licence (3 ans), Master (2 ans), MBA. Filières: Informatique de Gestion, Génie Logiciel, Réseaux et Télécommunications, Marketing, Finance, Comptabilité, Audiovisuel, Design Graphique.", "estPublic": false}'

echo "  TG-CPTEC-061 - Centre de Perfectionnement aux Techniques Économiques et Commerciales"
post "bibliotheque/etablissements" \
  '{"titre": "Centre de Perfectionnement aux Techniques Économiques et Commerciales", "resume": "Centre de Perfectionnement aux Techniques Économiques et Commerciales — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Centre de Perfectionnement aux Techniques Économiques et Commerciales — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "CENTRE_FORMATION_PROFESSIONNELLE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-EMARITO-062 - École Maritime du Togo"
post "bibliotheque/etablissements" \
  '{"titre": "École Maritime du Togo", "resume": "École Maritime du Togo — Établissement d'\''enseignement supérieur au Togo.", "contenu": "École Maritime du Togo — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "https://emarito.org", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-ESTABAT-063 - École Supérieure d'Architecture et de Topographie"
post "bibliotheque/etablissements" \
  '{"titre": "École Supérieure d'\''Architecture et de Topographie", "resume": "École privée d'\''ingénieurs située à Aného, spécialisée dans les formations techniques et scientifiques.", "contenu": "École privée d'\''ingénieurs située à Aného, spécialisée dans les formations techniques et scientifiques.", "estPublie": true, "adresse": "Aného", "ville": "Aného", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence", "contacts": "", "siteWeb": "", "offreFormation": "Formations d'\''ingénieurs et techniciens supérieurs. Filières: Génie Civil, Génie Électrique, Génie Informatique, Énergies Renouvelables.", "estPublic": false}'

echo "  TG-IGEB-064 - Institut du Génie Biomédical de Lomé"
post "bibliotheque/etablissements" \
  '{"titre": "Institut du Génie Biomédical de Lomé", "resume": "Institut du Génie Biomédical de Lomé — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Institut du Génie Biomédical de Lomé — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-ESEC-065 - École Supérieure des Études Cinématographiques et de l'Audiovisuel"
post "bibliotheque/etablissements" \
  '{"titre": "École Supérieure des Études Cinématographiques et de l'\''Audiovisuel", "resume": "École privée spécialisée dans les métiers de la mode, du design et des arts plastiques.", "contenu": "École privée spécialisée dans les métiers de la mode, du design et des arts plastiques.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence", "contacts": "", "siteWeb": "", "offreFormation": "Formations en Stylisme, Création de Mode, Design Textile, Arts Plastiques, Design Graphique.", "estPublic": false}'

echo "  TG-ESTHSM-066 - École Supérieure du Tourisme et d'Hôtellerie Stella Matutina"
post "bibliotheque/etablissements" \
  '{"titre": "École Supérieure du Tourisme et d'\''Hôtellerie Stella Matutina", "resume": "Grande école privée spécialisée en gestion, informatique et technologies. L'\''un des plus grands établissements privés du Togo.", "contenu": "Grande école privée spécialisée en gestion, informatique et technologies. L'\''un des plus grands établissements privés du Togo.", "estPublie": true, "adresse": "BP 80665, Lomé", "ville": "Lomé", "typeEtablissement": "GRANDE_ECOLE", "niveau": "Licence, Master", "contacts": "+228 22 21 60 60 / info@esgis.tg", "siteWeb": "https://www.esgis.tg", "offreFormation": "Écoles: ESGIS Management, ESGIS Informatique, ESGIS Communication. Programmes: Licence (3 ans), Master (2 ans), MBA. Filières: Informatique de Gestion, Génie Logiciel, Réseaux et Télécommunications, Marketing, Finance, Comptabilité, Audiovisuel, Design Graphique.", "estPublic": false}'

echo "  TG-ESCEN-067 - École Supérieure de Commerce et d'Économie Numérique"
post "bibliotheque/etablissements" \
  '{"titre": "École Supérieure de Commerce et d'\''Économie Numérique", "resume": "Grande école privée spécialisée en gestion, informatique et technologies. L'\''un des plus grands établissements privés du Togo.", "contenu": "Grande école privée spécialisée en gestion, informatique et technologies. L'\''un des plus grands établissements privés du Togo.", "estPublie": true, "adresse": "BP 80665, Lomé", "ville": "Lomé", "typeEtablissement": "GRANDE_ECOLE", "niveau": "Licence, Master", "contacts": "+228 22 21 60 60 / info@esgis.tg", "siteWeb": "https://www.esgis.tg", "offreFormation": "Écoles: ESGIS Management, ESGIS Informatique, ESGIS Communication. Programmes: Licence (3 ans), Master (2 ans), MBA. Filières: Informatique de Gestion, Génie Logiciel, Réseaux et Télécommunications, Marketing, Finance, Comptabilité, Audiovisuel, Design Graphique.", "estPublic": false}'

echo "  TG-IADSS-068 - Institut Africain de Développement Sanitaire et Social"
post "bibliotheque/etablissements" \
  '{"titre": "Institut Africain de Développement Sanitaire et Social", "resume": "Institut privé spécialisé en administration des affaires et études commerciales.", "contenu": "Institut privé spécialisé en administration des affaires et études commerciales.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "GRANDE_ECOLE", "niveau": "Licence, Master", "contacts": "+228 22 21 00 00", "siteWeb": "", "offreFormation": "Formations en Administration des Affaires, Commerce International, Marketing, Gestion des Ressources Humaines, Finance, Comptabilité. Licence (3 ans), Master (2 ans).", "estPublic": false}'

echo "  TG-ESTAC-069 - École Supérieure des Techniques et Arts de la Communication"
post "bibliotheque/etablissements" \
  '{"titre": "École Supérieure des Techniques et Arts de la Communication", "resume": "Grande école privée de commerce et de gestion. Propose des programmes en management, finance et entrepreneuriat.", "contenu": "Grande école privée de commerce et de gestion. Propose des programmes en management, finance et entrepreneuriat.", "estPublie": true, "adresse": "BP 81170, Lomé", "ville": "Lomé", "typeEtablissement": "GRANDE_ECOLE", "niveau": "Licence, Master", "contacts": "+228 22 21 35 00 / contact@esa.tg", "siteWeb": "https://www.esa.tg", "offreFormation": "Programmes: Licence en Commerce et Gestion (3 ans), Master en Management des Entreprises (2 ans), MBA. Filières: Marketing, Finance d'\''Entreprise, Ressources Humaines, Logistique, Commerce International, Entrepreneuriat.", "estPublic": false}'

echo "  TG-IPBTP-070 - Institut Polytechnique des Bâtiments et des Travaux Publics"
post "bibliotheque/etablissements" \
  '{"titre": "Institut Polytechnique des Bâtiments et des Travaux Publics", "resume": "Institut Polytechnique des Bâtiments et des Travaux Publics — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Institut Polytechnique des Bâtiments et des Travaux Publics — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-DEFITECH-071 - Institut Polytechnique DEFITECH"
post "bibliotheque/etablissements" \
  '{"titre": "Institut Polytechnique DEFITECH", "resume": "Institut privé dédié au leadership, à la stratégie et au management. Fondé par le Groupe DWDG.", "contenu": "Institut privé dédié au leadership, à la stratégie et au management. Fondé par le Groupe DWDG.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Master", "contacts": "", "siteWeb": "https://isl.education", "offreFormation": "Masters en Stratégie d'\''Entreprise, Intelligence Artificielle, Management, Leadership. Formation hybride (en ligne et présentiel). Stages et projets consulting.", "estPublic": false}'

echo "  TG-FORMATEC-072 - Institut des Sciences Technologiques, Économiques et Administratives (FORMATEC)"
post "bibliotheque/etablissements" \
  '{"titre": "Institut des Sciences Technologiques, Économiques et Administratives (FORMATEC)", "resume": "Institut des Sciences Technologiques, Économiques et Administratives (FORMATEC) — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Institut des Sciences Technologiques, Économiques et Administratives (FORMATEC) — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-ESAS-073 - École Supérieure des Arts du Spectacle"
post "bibliotheque/etablissements" \
  '{"titre": "École Supérieure des Arts du Spectacle", "resume": "Grande école privée de commerce et de gestion. Propose des programmes en management, finance et entrepreneuriat.", "contenu": "Grande école privée de commerce et de gestion. Propose des programmes en management, finance et entrepreneuriat.", "estPublie": true, "adresse": "BP 81170, Lomé", "ville": "Lomé", "typeEtablissement": "GRANDE_ECOLE", "niveau": "Licence, Master", "contacts": "+228 22 21 35 00 / contact@esa.tg", "siteWeb": "https://www.esa.tg", "offreFormation": "Programmes: Licence en Commerce et Gestion (3 ans), Master en Management des Entreprises (2 ans), MBA. Filières: Marketing, Finance d'\''Entreprise, Ressources Humaines, Logistique, Commerce International, Entrepreneuriat.", "estPublic": false}'

echo "  TG-IFNTI-074 - Institut de Formation aux Normes et Technologies de l'Informatique"
post "bibliotheque/etablissements" \
  '{"titre": "Institut de Formation aux Normes et Technologies de l'\''Informatique", "resume": "Institut de Formation aux Normes et Technologies de l'\''Informatique — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Institut de Formation aux Normes et Technologies de l'\''Informatique — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-IFOMESS-075 - Institut de Formation aux Métiers de la Sécurité Sociale"
post "bibliotheque/etablissements" \
  '{"titre": "Institut de Formation aux Métiers de la Sécurité Sociale", "resume": "Institut privé dédié au leadership, à la stratégie et au management. Fondé par le Groupe DWDG.", "contenu": "Institut privé dédié au leadership, à la stratégie et au management. Fondé par le Groupe DWDG.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Master", "contacts": "", "siteWeb": "https://isl.education", "offreFormation": "Masters en Stratégie d'\''Entreprise, Intelligence Artificielle, Management, Leadership. Formation hybride (en ligne et présentiel). Stages et projets consulting.", "estPublic": false}'

echo "  TG-ESCG-076 - École Supérieure de Communication et de Gestion"
post "bibliotheque/etablissements" \
  '{"titre": "École Supérieure de Communication et de Gestion", "resume": "École privée spécialisée dans les métiers de la mode, du design et des arts plastiques.", "contenu": "École privée spécialisée dans les métiers de la mode, du design et des arts plastiques.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence", "contacts": "", "siteWeb": "", "offreFormation": "Formations en Stylisme, Création de Mode, Design Textile, Arts Plastiques, Design Graphique.", "estPublic": false}'

echo "  TG-ISTM-077 - Institut Supérieur des Technologies et de Management"
post "bibliotheque/etablissements" \
  '{"titre": "Institut Supérieur des Technologies et de Management", "resume": "Institut privé de formation en management et entrepreneuriat.", "contenu": "Institut privé de formation en management et entrepreneuriat.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "+228 90 01 11 11", "siteWeb": "", "offreFormation": "Formations en Management, Entrepreneuriat, Marketing, Finance.", "estPublic": false}'

echo "  TG-ISLA-078 - Institut Supérieur des Langues et des Affaires (Langcenter International)"
post "bibliotheque/etablissements" \
  '{"titre": "Institut Supérieur des Langues et des Affaires (Langcenter International)", "resume": "Institut privé de formation en management et entrepreneuriat.", "contenu": "Institut privé de formation en management et entrepreneuriat.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "+228 90 01 11 11", "siteWeb": "", "offreFormation": "Formations en Management, Entrepreneuriat, Marketing, Finance.", "estPublic": false}'

echo "  TG-IUN-079 - Institut Universitaire Nobel"
post "bibliotheque/etablissements" \
  '{"titre": "Institut Universitaire Nobel", "resume": "Institut Universitaire Nobel — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Institut Universitaire Nobel — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-LUCAS-080 - LUCAS University College"
post "bibliotheque/etablissements" \
  '{"titre": "LUCAS University College", "resume": "LUCAS University College — Établissement d'\''enseignement supérieur au Togo.", "contenu": "LUCAS University College — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "UNIVERSITE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "https://lome-bs.com", "offreFormation": "Formations supérieures à Lomé.", "estPublic": true}'

echo "  TG-COA-081 - Centre Omnithérapeutique Africain"
post "bibliotheque/etablissements" \
  '{"titre": "Centre Omnithérapeutique Africain", "resume": "Centre Omnithérapeutique Africain — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Centre Omnithérapeutique Africain — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "CENTRE_FORMATION_PROFESSIONNELLE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-HEST-082 - École des Hautes Études de Sciences et Technologies"
post "bibliotheque/etablissements" \
  '{"titre": "École des Hautes Études de Sciences et Technologies", "resume": "École des Hautes Études de Sciences et Technologies — Établissement d'\''enseignement supérieur au Togo.", "contenu": "École des Hautes Études de Sciences et Technologies — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-IFORDD-083 - Institut de Formation et de Recherche pour le Développement Durable"
post "bibliotheque/etablissements" \
  '{"titre": "Institut de Formation et de Recherche pour le Développement Durable", "resume": "Institut de Formation et de Recherche pour le Développement Durable — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Institut de Formation et de Recherche pour le Développement Durable — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-IPNET-084 - IPNET Institute of Technology"
post "bibliotheque/etablissements" \
  '{"titre": "IPNET Institute of Technology", "resume": "IPNET Institute of Technology — Établissement d'\''enseignement supérieur au Togo.", "contenu": "IPNET Institute of Technology — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-IRFODEL-085 - Institut de Recherche et de Formation pour le Développement Local"
post "bibliotheque/etablissements" \
  '{"titre": "Institut de Recherche et de Formation pour le Développement Local", "resume": "Institut de Recherche et de Formation pour le Développement Local — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Institut de Recherche et de Formation pour le Développement Local — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-EFL-086 - École de Finance de Lomé (ex-AIA)"
post "bibliotheque/etablissements" \
  '{"titre": "École de Finance de Lomé (ex-AIA)", "resume": "École de Finance de Lomé (ex-AIA) — Établissement d'\''enseignement supérieur au Togo.", "contenu": "École de Finance de Lomé (ex-AIA) — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-ANCILLA-087 - Centre de Formation Professionnelle Hôtelière ANCILLA"
post "bibliotheque/etablissements" \
  '{"titre": "Centre de Formation Professionnelle Hôtelière ANCILLA", "resume": "Centre privé spécialisé dans la formation aux métiers de la banque et de la finance.", "contenu": "Centre privé spécialisé dans la formation aux métiers de la banque et de la finance.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "CENTRE_FORMATION_PROFESSIONNELLE", "niveau": "Formation professionnelle", "contacts": "", "siteWeb": "", "offreFormation": "Formations professionnelles en Banque, Finance, Assurance, Microfinance. Programmes certifiants.", "estPublic": false}'

echo "  TG-ECADRES-088 - École des Cadres de Lomé"
post "bibliotheque/etablissements" \
  '{"titre": "École des Cadres de Lomé", "resume": "École des Cadres de Lomé — Établissement d'\''enseignement supérieur au Togo.", "contenu": "École des Cadres de Lomé — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-EMC-089 - École des Micro-Entrepreneurs du Centre"
post "bibliotheque/etablissements" \
  '{"titre": "École des Micro-Entrepreneurs du Centre", "resume": "École privée d'\''ingénieurs située à Aného, spécialisée dans les formations techniques et scientifiques.", "contenu": "École privée d'\''ingénieurs située à Aného, spécialisée dans les formations techniques et scientifiques.", "estPublie": true, "adresse": "Aného", "ville": "Aného", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence", "contacts": "", "siteWeb": "", "offreFormation": "Formations d'\''ingénieurs et techniciens supérieurs. Filières: Génie Civil, Génie Électrique, Génie Informatique, Énergies Renouvelables.", "estPublic": false}'

echo "  TG-BAKPESSI-090 - Institut Supérieur de Management Monseigneur Bakpessi"
post "bibliotheque/etablissements" \
  '{"titre": "Institut Supérieur de Management Monseigneur Bakpessi", "resume": "Institut privé de formation en management et entrepreneuriat.", "contenu": "Institut privé de formation en management et entrepreneuriat.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "+228 90 01 11 11", "siteWeb": "", "offreFormation": "Formations en Management, Entrepreneuriat, Marketing, Finance.", "estPublic": false}'

echo "  TG-HTIB-091 - Institut des Hautes Technologies d'Informatique et de Bureautique Atlantis"
post "bibliotheque/etablissements" \
  '{"titre": "Institut des Hautes Technologies d'\''Informatique et de Bureautique Atlantis", "resume": "Institut des Hautes Technologies d'\''Informatique et de Bureautique Atlantis — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Institut des Hautes Technologies d'\''Informatique et de Bureautique Atlantis — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-ISSEC-092 - Institut Supérieur des Sciences Économiques et Commerciales KOUVAHEY"
post "bibliotheque/etablissements" \
  '{"titre": "Institut Supérieur des Sciences Économiques et Commerciales KOUVAHEY", "resume": "Institut privé de formation en management et entrepreneuriat.", "contenu": "Institut privé de formation en management et entrepreneuriat.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "+228 90 01 11 11", "siteWeb": "", "offreFormation": "Formations en Management, Entrepreneuriat, Marketing, Finance.", "estPublic": false}'

echo "  TG-KNOWBRIDGE-093 - Knowbridge University Institute"
post "bibliotheque/etablissements" \
  '{"titre": "Knowbridge University Institute", "resume": "Knowbridge University Institute — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Knowbridge University Institute — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "UNIVERSITE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": true}'

echo "  TG-ISBA-094 - Institut Supérieur du Bâtiment et du Design Ayin'A"
post "bibliotheque/etablissements" \
  '{"titre": "Institut Supérieur du Bâtiment et du Design Ayin'\''A", "resume": "Institut privé de formation en management et entrepreneuriat.", "contenu": "Institut privé de formation en management et entrepreneuriat.", "estPublie": true, "adresse": "Lomé", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "+228 90 01 11 11", "siteWeb": "", "offreFormation": "Formations en Management, Entrepreneuriat, Marketing, Finance.", "estPublic": false}'

echo "  TG-SIBI-095 - Social and Inclusive Business Institute of Togo"
post "bibliotheque/etablissements" \
  '{"titre": "Social and Inclusive Business Institute of Togo", "resume": "Social and Inclusive Business Institute of Togo — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Social and Inclusive Business Institute of Togo — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-AVENIDA-096 - Hôtel École Avenida"
post "bibliotheque/etablissements" \
  '{"titre": "Hôtel École Avenida", "resume": "Hôtel École Avenida — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Hôtel École Avenida — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo "  TG-IALEAD-097 - Institut Africain Le Leadership"
post "bibliotheque/etablissements" \
  '{"titre": "Institut Africain Le Leadership", "resume": "Institut Africain Le Leadership — Établissement d'\''enseignement supérieur au Togo.", "contenu": "Institut Africain Le Leadership — Établissement d'\''enseignement supérieur au Togo.", "estPublie": true, "adresse": "", "ville": "Lomé", "typeEtablissement": "ECOLE_SUPERIEURE", "niveau": "Licence, Master", "contacts": "", "siteWeb": "", "offreFormation": "Formations supérieures à Lomé.", "estPublic": false}'

echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║        SEED TERMINÉ AVEC SUCCÈS !             ║"
echo "╚═══════════════════════════════════════════════╝"

