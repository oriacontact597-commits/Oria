#!/bin/bash
# seed_orientation_tests.sh — Crée 10 tests d'orientation complets via l'API
# Source: activeduction_plateform (Python/FastAPI → Java/Spring)

API="${API_URL:-http://localhost:8080/api/v1}"
EMAIL="${1:-admin@activeducation.tg}"
PASS="${2:-admin123!}"

echo "=== Authentification ==="
TOKEN=$(curl -s -X POST "$API/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL\", \"motDePasse\": \"$PASS\"}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['accessToken'])")
echo "Token obtenu"
AUTH="Authorization: Bearer $TOKEN"

create_quiz() {
  local titre="$1" desc="$2"
  local q=$(curl -s -X POST "$API/quiz" \
    -H "$AUTH" -H "Content-Type: application/json" \
    -d "{\"titre\": \"$titre\", \"description\": \"$desc\", \"estActif\": true}")
  echo "$q" | python3 -c "import sys,json; print(json.load(sys.stdin)['trackingId'])"
}

add_question() {
  local qid="$1" texte="$2" ordre="$3" typeq="$4" domaine="$5"
  local json="{\"texteQuestion\": \"$texte\", \"ordre\": $ordre"
  [ -n "$typeq" ] && json="$json, \"typeQuestion\": \"$typeq\""
  [ -n "$domaine" ] && json="$json, \"domaine\": \"$domaine\""
  json="$json}"
  local q=$(curl -s -X POST "$API/quiz/$qid/questions" \
    -H "$AUTH" -H "Content-Type: application/json" \
    -d "$json")
  echo "$q" | python3 -c "import sys,json; print(json.load(sys.stdin)['trackingId'])"
}

add_r() {
  local qst="$1" texte="$2" cat="$3" pts="$4"
  curl -s -X POST "$API/questions/$qst/reponses" \
    -H "$AUTH" -H "Content-Type: application/json" \
    -d "{\"texteReponse\": \"$texte\", \"categoriePoint\": \"$cat\", \"points\": $pts}" > /dev/null
}

add_likert_riasec() { local q="$1" c="$2"; add_r "$q" "Pas du tout" "$c" 1; add_r "$q" "Un peu" "$c" 2; add_r "$q" "Moyennement" "$c" 3; add_r "$q" "Beaucoup" "$c" 4; add_r "$q" "Passionnement" "$c" 5; }
add_likert_agree() { local q="$1" c="$2"; add_r "$q" "Pas du tout d'accord" "$c" 1; add_r "$q" "Peu d'accord" "$c" 2; add_r "$q" "Moyennement d'accord" "$c" 3; add_r "$q" "D'accord" "$c" 4; add_r "$q" "Tout à fait d'accord" "$c" 5; }

# ═══════════════════════════════════════════════
# TEST 1 : RIASEC (18 questions)
# ═══════════════════════════════════════════════
echo; echo "=== Test 1 : RIASEC ==="
QID1=$(create_quiz "Test d'Intérêts Professionnels (RIASEC)" "Découvre les métiers qui correspondent le mieux à tes centres d'intérêt selon la théorie de Holland.")
q() { add_question "$QID1" "$1" "$2" "RIASEC" "$3"; }
Q=$(q "J'aime réparer des appareils électriques ou mécaniques." 1 "R"); add_likert_riasec "$Q" "R"
Q=$(q "Je préfère travailler avec des outils et des machines." 2 "R"); add_likert_riasec "$Q" "R"
Q=$(q "J'aime construire ou fabriquer des objets de mes mains." 3 "R"); add_likert_riasec "$Q" "R"
Q=$(q "J'aime résoudre des problèmes mathématiques complexes." 4 "I"); add_likert_riasec "$Q" "I"
Q=$(q "Je suis curieux et j'aime comprendre comment les choses fonctionnent." 5 "I"); add_likert_riasec "$Q" "I"
Q=$(q "J'aime mener des expériences et analyser des données." 6 "I"); add_likert_riasec "$Q" "I"
Q=$(q "J'aime dessiner, peindre ou faire de la musique." 7 "A"); add_likert_riasec "$Q" "A"
Q=$(q "J'ai une imagination débordante et j'aime créer." 8 "A"); add_likert_riasec "$Q" "A"
Q=$(q "Je préfère m'exprimer de manière créative plutôt que suivre des règles." 9 "A"); add_likert_riasec "$Q" "A"
Q=$(q "J'aime aider les autres et leur enseigner de nouvelles choses." 10 "S"); add_likert_riasec "$Q" "S"
Q=$(q "Je suis à l'aise pour parler en public ou animer des groupes." 11 "S"); add_likert_riasec "$Q" "S"
Q=$(q "Je me soucie du bien-être des autres et j'aime les conseiller." 12 "S"); add_likert_riasec "$Q" "S"
Q=$(q "J'aime diriger une équipe et prendre des décisions." 13 "E"); add_likert_riasec "$Q" "E"
Q=$(q "Je suis motivé par la réussite et les défis ambitieux." 14 "E"); add_likert_riasec "$Q" "E"
Q=$(q "J'aime convaincre et négocier avec les autres." 15 "E"); add_likert_riasec "$Q" "E"
Q=$(q "J'aime organiser des dossiers et des données de manière ordonnée." 16 "C"); add_likert_riasec "$Q" "C"
Q=$(q "Je préfère suivre des procédures établies et claires." 17 "C"); add_likert_riasec "$Q" "C"
Q=$(q "Je suis minutieux et attentif aux détails." 18 "C"); add_likert_riasec "$Q" "C"
echo "  RIASEC : 18 questions, 90 réponses ✓"

# ═══════════════════════════════════════════════
# TEST 2 : Intelligences Multiples (19 questions)
# ═══════════════════════════════════════════════
echo; echo "=== Test 2 : Intelligences Multiples ==="
QID2=$(create_quiz "Test des Intelligences Multiples" "Identifie tes formes d'intelligence dominantes selon la théorie de Howard Gardner.")
q() { add_question "$QID2" "$1" "$2" "PERSONNALITE" "$3"; }
Q=$(q "J'aime lire des livres et écrire des histoires." 1 "Linguistique"); add_likert_agree "$Q" "Linguistique"
Q=$(q "Je m'exprime facilement à l'oral et à l'écrit." 2 "Linguistique"); add_likert_agree "$Q" "Linguistique"
Q=$(q "J'apprends mieux en lisant ou en écoutant des explications." 3 "Linguistique"); add_likert_agree "$Q" "Linguistique"
Q=$(q "J'aime résoudre des énigmes et des problèmes logiques." 4 "Logico-Mathematique"); add_likert_agree "$Q" "Logico-Mathematique"
Q=$(q "Je suis à l'aise avec les chiffres et les calculs." 5 "Logico-Mathematique"); add_likert_agree "$Q" "Logico-Mathematique"
Q=$(q "Je cherche toujours à comprendre le pourquoi des choses." 6 "Logico-Mathematique"); add_likert_agree "$Q" "Logico-Mathematique"
Q=$(q "Je visualise facilement des objets en 3D dans ma tête." 7 "Spatiale"); add_likert_agree "$Q" "Spatiale"
Q=$(q "J'ai un bon sens de l'orientation." 8 "Spatiale"); add_likert_agree "$Q" "Spatiale"
Q=$(q "J'aime dessiner, créer des schémas ou des cartes." 9 "Spatiale"); add_likert_agree "$Q" "Spatiale"
Q=$(q "Je retiens facilement les mélodies et les rythmes." 10 "Musicale"); add_likert_agree "$Q" "Musicale"
Q=$(q "J'aime chanter, jouer d'un instrument ou écouter de la musique." 11 "Musicale"); add_likert_agree "$Q" "Musicale"
Q=$(q "J'apprends mieux en faisant les choses moi-même." 12 "Kinesthesique"); add_likert_agree "$Q" "Kinesthesique"
Q=$(q "Je suis habile de mes mains et j'aime le sport." 13 "Kinesthesique"); add_likert_agree "$Q" "Kinesthesique"
Q=$(q "Je comprends facilement les émotions des autres." 14 "Interpersonnelle"); add_likert_agree "$Q" "Interpersonnelle"
Q=$(q "J'aime travailler en équipe et aider les autres." 15 "Interpersonnelle"); add_likert_agree "$Q" "Interpersonnelle"
Q=$(q "Je me connais bien et je sais identifier mes forces et faiblesses." 16 "Intrapersonnelle"); add_likert_agree "$Q" "Intrapersonnelle"
Q=$(q "J'aime réfléchir seul et planifier mes objectifs." 17 "Intrapersonnelle"); add_likert_agree "$Q" "Intrapersonnelle"
Q=$(q "J'aime observer et classer les éléments de la nature." 18 "Naturaliste"); add_likert_agree "$Q" "Naturaliste"
Q=$(q "Je suis sensible à l'environnement et à la protection de la nature." 19 "Naturaliste"); add_likert_agree "$Q" "Naturaliste"
echo "  Intelligences Multiples : 19 questions, 95 réponses ✓"

# ═══════════════════════════════════════════════
# TEST 3 : Valeurs Professionnelles (10 questions)
# ═══════════════════════════════════════════════
echo; echo "=== Test 3 : Valeurs Professionnelles ==="
QID3=$(create_quiz "Test des Valeurs Professionnelles" "Découvre ce qui te motive vraiment dans le travail.")
q() { add_question "$QID3" "$1" "$2" "PERSONNALITE" "$3"; }
Q=$(q "Gagner un bon salaire est très important pour moi." 1 "Remuneration"); add_likert_agree "$Q" "Remuneration"
Q=$(q "Je veux un travail qui me permette d'aider les autres." 2 "Altruisme"); add_likert_agree "$Q" "Altruisme"
Q=$(q "La sécurité de l'emploi est prioritaire dans mon choix de carrière." 3 "Securite"); add_likert_agree "$Q" "Securite"
Q=$(q "Je veux être libre et autonome dans mon travail." 4 "Autonomie"); add_likert_agree "$Q" "Autonomie"
Q=$(q "Je souhaite être reconnu et respecté pour mon travail." 5 "Reconnaissance"); add_likert_agree "$Q" "Reconnaissance"
Q=$(q "Avoir un bon équilibre vie professionnelle/vie personnelle est essentiel." 6 "Equilibre"); add_likert_agree "$Q" "Equilibre"
Q=$(q "Je veux un travail créatif où je peux innover." 7 "Creativite"); add_likert_agree "$Q" "Creativite"
Q=$(q "Diriger une équipe et avoir du pouvoir m'attire." 8 "Leadership"); add_likert_agree "$Q" "Leadership"
Q=$(q "Je veux un métier qui a un impact positif sur la société." 9 "Impact"); add_likert_agree "$Q" "Impact"
Q=$(q "Apprendre continuellement de nouvelles choses est important pour moi." 10 "Apprentissage"); add_likert_agree "$Q" "Apprentissage"
echo "  Valeurs Professionnelles : 10 questions, 50 réponses ✓"

# ═══════════════════════════════════════════════
# TEST 4 : MBTI Simplifié (8 questions)
# ═══════════════════════════════════════════════
echo; echo "=== Test 4 : MBTI Simplifié ==="
QID4=$(create_quiz "Test de Personnalité (MBTI Simplifié)" "Découvre ton type de personnalité parmi 16 profils possibles.")
q() { add_question "$QID4" "$1" "$2" "PERSONNALITE" "$3"; }
# MBTI uses bipolar score: high on one dimension means low on the other
# We use points 1-5 on E/I, S/N, T/F, J/P dimensions
Q=$(q "Dans un groupe, je suis plutôt celui qui prend la parole en premier." 1 "E-I"); add_likert_agree "$Q" "E-I"
Q=$(q "Je préfère les faits concrets aux idées abstraites." 2 "S-N"); add_likert_agree "$Q" "S-N"
Q=$(q "Je prends mes décisions avec la logique plutôt qu'avec les émotions." 3 "T-F"); add_likert_agree "$Q" "T-F"
Q=$(q "Je préfère planifier à l'avance plutôt qu'improviser." 4 "J-P"); add_likert_agree "$Q" "J-P"
Q=$(q "Les fêtes et les grands rassemblements me donnent de l'énergie." 5 "E-I"); add_likert_agree "$Q" "E-I"
Q=$(q "Je fais confiance à mon expérience plutôt qu'à mon intuition." 6 "S-N"); add_likert_agree "$Q" "S-N"
Q=$(q "L'harmonie dans le groupe est plus importante que la vérité." 7 "T-F"); add_likert_agree "$Q" "T-F"
Q=$(q "J'aime avoir mes affaires bien rangées et organisées." 8 "J-P"); add_likert_agree "$Q" "J-P"
echo "  MBTI : 8 questions, 40 réponses ✓"

# ═══════════════════════════════════════════════
# TEST 5 : Aptitudes Naturelles (10 questions)
# ═══════════════════════════════════════════════
echo; echo "=== Test 5 : Aptitudes Naturelles ==="
QID5=$(create_quiz "Test d'Aptitudes Naturelles" "Identifie tes talents naturels et tes forces.")
q() { add_question "$QID5" "$1" "$2" "PERSONNALITE" "$3"; }
Q=$(q "J'arrive facilement à expliquer des choses complexes aux autres." 1 "Communication"); add_likert_agree "$Q" "Communication"
Q=$(q "Je suis bon en calcul mental et en mathématiques." 2 "Analytique"); add_likert_agree "$Q" "Analytique"
Q=$(q "Je suis à l'aise pour organiser des événements ou des projets." 3 "Organisation"); add_likert_agree "$Q" "Organisation"
Q=$(q "J'ai une bonne mémoire visuelle." 4 "Visuelle"); add_likert_agree "$Q" "Visuelle"
Q=$(q "Je suis doué pour résoudre des conflits entre personnes." 5 "Mediation"); add_likert_agree "$Q" "Mediation"
Q=$(q "Je suis créatif et j'ai souvent des idées originales." 6 "Creativite"); add_likert_agree "$Q" "Creativite"
Q=$(q "Je suis patient et méthodique dans mon travail." 7 "Methode"); add_likert_agree "$Q" "Methode"
Q=$(q "Je m'adapte facilement aux nouvelles situations." 8 "Adaptabilite"); add_likert_agree "$Q" "Adaptabilite"
Q=$(q "Je suis bon pour convaincre et négocier." 9 "Persuasion"); add_likert_agree "$Q" "Persuasion"
Q=$(q "Je gère bien mon temps et mes priorités." 10 "Gestion du temps"); add_likert_agree "$Q" "Gestion du temps"
echo "  Aptitudes Naturelles : 10 questions, 50 réponses ✓"

# ═══════════════════════════════════════════════
# TEST 6 : Potentiel Entrepreneurial (8 questions)
# ═══════════════════════════════════════════════
echo; echo "=== Test 6 : Potentiel Entrepreneurial ==="
QID6=$(create_quiz "Test de Potentiel Entrepreneurial" "Es-tu fait pour entreprendre ? Évalue tes compétences et ta mentalité entrepreneuriales.")
q() { add_question "$QID6" "$1" "$2" "PERSONNALITE" "$3"; }
Q=$(q "Je préfère créer mon propre chemin plutôt que suivre celui des autres." 1 "Initiative"); add_likert_agree "$Q" "Initiative"
Q=$(q "L'échec ne me décourage pas, il me motive à essayer autrement." 2 "Resilience"); add_likert_agree "$Q" "Resilience"
Q=$(q "Je vois des opportunités business là où les autres voient des problèmes." 3 "Vision"); add_likert_agree "$Q" "Vision"
Q=$(q "Je suis prêt à prendre des risques calculés pour atteindre mes objectifs." 4 "Prise de risque"); add_likert_agree "$Q" "Prise de risque"
Q=$(q "J'ai déjà vendu quelque chose ou eu une petite activité générant des revenus." 5 "Experience"); add_likert_agree "$Q" "Experience"
Q=$(q "Je suis capable de motiver et entraîner les autres dans mes projets." 6 "Leadership"); add_likert_agree "$Q" "Leadership"
Q=$(q "Je gère bien mon argent et je comprends les bases de la finance." 7 "Finance"); add_likert_agree "$Q" "Finance"
Q=$(q "Je suis passionné et prêt à travailler dur pour réaliser mes rêves." 8 "Passion"); add_likert_agree "$Q" "Passion"
echo "  Potentiel Entrepreneurial : 8 questions, 40 réponses ✓"

# ═══════════════════════════════════════════════
# TEST 7 : Ancres de Carrière (16 questions)
# ═══════════════════════════════════════════════
echo; echo "=== Test 7 : Ancres de Carrière ==="
QID7=$(create_quiz "Test des Ancres de Carrière" "Identifie les motivations profondes qui orientent tes choix professionnels.")
q() { add_question "$QID7" "$1" "$2" "PERSONNALITE" "$3"; }
Q=$(q "Je veux devenir excellent dans un domaine technique précis." 1 "Technique"); add_likert_agree "$Q" "Technique"
Q=$(q "Je préfère être reconnu pour mon expertise plutôt que pour mon poste." 2 "Technique"); add_likert_agree "$Q" "Technique"
Q=$(q "Diriger des équipes et prendre des décisions me motive." 3 "Management"); add_likert_agree "$Q" "Management"
Q=$(q "Je me vois évoluer vers des responsabilités de coordination." 4 "Management"); add_likert_agree "$Q" "Management"
Q=$(q "Je veux garder ma liberté dans ma façon de travailler." 5 "Autonomie"); add_likert_agree "$Q" "Autonomie"
Q=$(q "Je préfère les missions où je peux choisir mes méthodes." 6 "Autonomie"); add_likert_agree "$Q" "Autonomie"
Q=$(q "La stabilité de l'emploi est une priorité pour moi." 7 "Securite"); add_likert_agree "$Q" "Securite"
Q=$(q "Je privilégie les environnements professionnels prévisibles." 8 "Securite"); add_likert_agree "$Q" "Securite"
Q=$(q "Avoir un impact positif sur les autres est essentiel." 9 "Service"); add_likert_agree "$Q" "Service"
Q=$(q "Je veux contribuer à une mission utile à la société." 10 "Service"); add_likert_agree "$Q" "Service"
Q=$(q "Je suis attiré par les situations difficiles à relever." 11 "Defi"); add_likert_agree "$Q" "Defi"
Q=$(q "Résoudre des problèmes complexes m'enthousiasme." 12 "Defi"); add_likert_agree "$Q" "Defi"
Q=$(q "Je veux un métier compatible avec ma vie personnelle." 13 "StyleDeVie"); add_likert_agree "$Q" "StyleDeVie"
Q=$(q "L'équilibre global compte plus que le statut." 14 "StyleDeVie"); add_likert_agree "$Q" "StyleDeVie"
Q=$(q "J'aime créer des projets à partir de zéro." 15 "Entrepreneuriat"); add_likert_agree "$Q" "Entrepreneuriat"
Q=$(q "Prendre des risques calculés ne me fait pas peur." 16 "Entrepreneuriat"); add_likert_agree "$Q" "Entrepreneuriat"
echo "  Ancres de Carrière : 16 questions, 80 réponses ✓"

# ═══════════════════════════════════════════════
# TEST 8 : VARK (12 questions)
# ═══════════════════════════════════════════════
echo; echo "=== Test 8 : VARK ==="
QID8=$(create_quiz "Test des Styles d'Apprentissage (VARK)" "Découvre comment tu apprends le plus efficacement.")
q() { add_question "$QID8" "$1" "$2" "PERSONNALITE" "$3"; }
Q=$(q "Je comprends mieux avec des schémas ou des graphiques." 1 "Visuel"); add_likert_agree "$Q" "Visuel"
Q=$(q "Les cartes mentales m'aident à retenir les informations." 2 "Visuel"); add_likert_agree "$Q" "Visuel"
Q=$(q "Je préfère regarder une démonstration plutôt que lire un texte." 3 "Visuel"); add_likert_agree "$Q" "Visuel"
Q=$(q "J'apprends facilement quand on m'explique oralement." 4 "Auditif"); add_likert_agree "$Q" "Auditif"
Q=$(q "Discuter d'un sujet m'aide à mieux le maîtriser." 5 "Auditif"); add_likert_agree "$Q" "Auditif"
Q=$(q "Je retiens bien les cours écoutés ou en podcast." 6 "Auditif"); add_likert_agree "$Q" "Auditif"
Q=$(q "Lire des notes détaillées est mon meilleur moyen d'apprendre." 7 "LectureEcriture"); add_likert_agree "$Q" "LectureEcriture"
Q=$(q "Écrire des résumés m'aide à mémoriser." 8 "LectureEcriture"); add_likert_agree "$Q" "LectureEcriture"
Q=$(q "Je préfère les supports textes aux vidéos." 9 "LectureEcriture"); add_likert_agree "$Q" "LectureEcriture"
Q=$(q "Je retiens mieux en pratiquant directement." 10 "Kinesthesique"); add_likert_agree "$Q" "Kinesthesique"
Q=$(q "Les exercices concrets me font progresser rapidement." 11 "Kinesthesique"); add_likert_agree "$Q" "Kinesthesique"
Q=$(q "Je préfère apprendre via des projets plutôt que par théorie seule." 12 "Kinesthesique"); add_likert_agree "$Q" "Kinesthesique"
echo "  VARK : 12 questions, 60 réponses ✓"

# ═══════════════════════════════════════════════
# TEST 9 : Environnement de Travail Idéal (12 questions)
# ═══════════════════════════════════════════════
echo; echo "=== Test 9 : Environnement de Travail Idéal ==="
QID9=$(create_quiz "Test d'Environnement de Travail Idéal" "Détermine les conditions de travail dans lesquelles tu performes le mieux.")
q() { add_question "$QID9" "$1" "$2" "PERSONNALITE" "$3"; }
Q=$(q "Je donne le meilleur de moi en travaillant avec une équipe." 1 "Collaboration"); add_likert_agree "$Q" "Collaboration"
Q=$(q "Les projets collectifs me motivent davantage que les missions solo." 2 "Collaboration"); add_likert_agree "$Q" "Collaboration"
Q=$(q "Je préfère organiser mon travail sans supervision constante." 3 "Autonomie"); add_likert_agree "$Q" "Autonomie"
Q=$(q "Je suis plus efficace quand je décide seul de mes priorités." 4 "Autonomie"); add_likert_agree "$Q" "Autonomie"
Q=$(q "Les règles claires et les procédures m'aident à performer." 5 "Structure"); add_likert_agree "$Q" "Structure"
Q=$(q "Je préfère des objectifs et un cadre bien définis." 6 "Structure"); add_likert_agree "$Q" "Structure"
Q=$(q "J'aime les environnements où l'on teste de nouvelles idées." 7 "Innovation"); add_likert_agree "$Q" "Innovation"
Q=$(q "Je m'épanouis dans des organisations qui changent vite." 8 "Innovation"); add_likert_agree "$Q" "Innovation"
Q=$(q "Je préfère les activités de terrain aux tâches de bureau." 9 "Terrain"); add_likert_agree "$Q" "Terrain"
Q=$(q "Bouger et voir des situations réelles me motive." 10 "Terrain"); add_likert_agree "$Q" "Terrain"
Q=$(q "J'aime analyser des données avant de prendre une décision." 11 "Analyse"); add_likert_agree "$Q" "Analyse"
Q=$(q "Les missions qui demandent de la rigueur intellectuelle me plaisent." 12 "Analyse"); add_likert_agree "$Q" "Analyse"
echo "  Environnement de Travail : 12 questions, 60 réponses ✓"

# ═══════════════════════════════════════════════
# TEST 10 : Maturité du Projet Professionnel (12 questions)
# ═══════════════════════════════════════════════
echo; echo "=== Test 10 : Maturité du Projet Professionnel ==="
QID10=$(create_quiz "Test de Maturité du Projet Professionnel" "Mesure ton niveau de clarté sur ton avenir professionnel.")
q() { add_question "$QID10" "$1" "$2" "PERSONNALITE" "$3"; }
Q=$(q "Je connais clairement mes points forts et mes limites." 1 "ConnaissanceDeSoi"); add_likert_agree "$Q" "ConnaissanceDeSoi"
Q=$(q "Je sais quelles activités me donnent de l'énergie." 2 "ConnaissanceDeSoi"); add_likert_agree "$Q" "ConnaissanceDeSoi"
Q=$(q "Je peux expliquer ce qui compte vraiment pour moi dans un métier." 3 "ConnaissanceDeSoi"); add_likert_agree "$Q" "ConnaissanceDeSoi"
Q=$(q "J'ai exploré plusieurs métiers qui m'intéressent." 4 "ExplorationMetiers"); add_likert_agree "$Q" "ExplorationMetiers"
Q=$(q "Je connais les formations nécessaires pour les métiers que je vise." 5 "ExplorationMetiers"); add_likert_agree "$Q" "ExplorationMetiers"
Q=$(q "Je me renseigne régulièrement sur les perspectives d'emploi." 6 "ExplorationMetiers"); add_likert_agree "$Q" "ExplorationMetiers"
Q=$(q "Je me sens capable de comparer plusieurs options de carrière." 7 "PriseDecision"); add_likert_agree "$Q" "PriseDecision"
Q=$(q "Je peux prioriser une voie professionnelle en fonction de critères clairs." 8 "PriseDecision"); add_likert_agree "$Q" "PriseDecision"
Q=$(q "Je prends des décisions sans rester bloqué trop longtemps." 9 "PriseDecision"); add_likert_agree "$Q" "PriseDecision"
Q=$(q "J'ai défini des étapes concrètes pour atteindre mon objectif." 10 "PlanAction"); add_likert_agree "$Q" "PlanAction"
Q=$(q "Je sais quelles compétences je dois développer cette année." 11 "PlanAction"); add_likert_agree "$Q" "PlanAction"
Q=$(q "Je passe à l'action (stages, projets, rencontres) pour avancer." 12 "PlanAction"); add_likert_agree "$Q" "PlanAction"
echo "  Maturité du Projet : 12 questions, 60 réponses ✓"

# ═══════════════════════════════════════════════
# Résumé
# ═══════════════════════════════════════════════
echo; echo "═══════════════════════════════════════════"
echo "  Seed terminé !"
echo "═══════════════════════════════════════════════"
echo "  1. RIASEC                  : $QID1"
echo "  2. Intelligences Multiples : $QID2"
echo "  3. Valeurs Pro.            : $QID3"
echo "  4. MBTI Simplifié          : $QID4"
echo "  5. Aptitudes Naturelles    : $QID5"
echo "  6. Potentiel Entrepreneur  : $QID6"
echo "  7. Ancres de Carrière      : $QID7"
echo "  8. VARK                    : $QID8"
echo "  9. Environnement Travail   : $QID9"
echo " 10. Maturité Projet Pro     : $QID10"
