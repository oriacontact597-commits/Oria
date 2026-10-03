# Guide de démonstration — Application ACTIV Education / ORIA
### Scénario de vidéo pas-à-pas pour un jury (public non-technique)

> **Durée estimée de la vidéo : 12 à 15 minutes.**
> Ce document décrit chaque écran dans l'ordre de la démo, ce qu'il faut cliquer,
> ce que le jury voit, et **une phrase simple à dire** pour chaque page.

---

## 1. Préparation avant d'enregistrer

### 1.1 Démarrage (à faire avant d'allumer la caméra)

```bash
# 1. Backend + base de données + stockage (depuis oria-backend-main/)
docker compose up -d
# attendre ~30 s, puis vérifier :
curl http://localhost:8085/api/v1/bibliotheque/faq   # doit répondre 200

# 2. Application mobile (depuis oria-fronted-main/activ_education/)
flutter run
# si téléphone branché : adb reverse tcp:8080 tcp:8080 (si backend sur 8080)
```

**Vérifications express :**
- [ ] L'app s'ouvre sur le logo puis l'onboarding
- [ ] Le catalogue affiche **929 établissements** (TG + Bénin + Côte d'Ivoire)
- [ ] Poser **une question test à ORIA** avant la caméra (réponse en 1-3 s)
- [ ] Batterie du téléphone à ≥ 50 %, mode avion désactivé mais **notifications masquées** (coupures gênantes)
- [ ] Désactiver les appels entrants ; Wi-Fi stable (les réponses IA passent par internet)

### 1.2 Comptes de démonstration

| Rôle | Email | Usage dans la vidéo |
|---|---|---|
| Élève (profil 2ᵉ, filière médecine) | `yawograceakogo@gmail.com` | **Écran principal de la vidéo** |
| Admin (back-office) | `admin@activeducation.tg` | Optionnel, hors vidéo recommandée |

> **Conseil :** la meilleure démo commence par **créer un compte en direct**
> (étape 2 ci-dessous) : cela prouve que l'application fonctionne réellement.
> Sinon, connectez-vous au compte élève existant.
> Les mots de passe sont ceux définis lors de la création des comptes (ne pas les afficher à l'écran).

---

## 2. Scénario de la vidéo — chaque page dans l'ordre

### Étape 1 — Lancement & Onboarding (≈ 45 s)

| | |
|---|---|
| **Où** | Ouverture de l'application |
| **Voir** | Logo, puis 3 pages pleine écran : « **Découvre les filières adaptées à ton profil** », « **Explore les universités et établissements** », « **Discute avec ORIA, ton assistant IA** » |
| **Faire** | Laisser chaque page 3-4 s, montrer le swipe, appuyer sur « **Passer** » (ou « Suivant » jusqu'à la page 3) |
| **Dire au jury** | *« L'application présente en trois écrans ce qu'elle fait : trouver la bonne filière, découvrir les établissements, et discuter avec notre assistant intelligent ORIA. »* |

---

### Étape 2 — Création de compte en 4 étapes (≈ 1 min 30)

| | |
|---|---|
| **Où** | « **J'ai déjà un compte** » → en bas, « **Créer mon compte** » |
| **Voir** | Un formulaire en 4 étapes (pastille « Étape 1 sur 4 ») |
| **Faire** | Remplir live : **① Faisons connaissance** (prénom, nom, email, mot de passe, pays, téléphone) → **② Ta scolarité** (Lycéen, classe, série) → **③ Ton objectif** (métier visé, ex. Médecin) → **④ Tes centres d'intérêt** (matières préférées, style d'apprentissage) → « **C'est parti !** » |
| **Voir (fin)** | Message « **Inscription réussie !** » puis arrivée sur l'accueil |
| **Dire au jury** | *« En quatre questions simples, on construit le profil de l'élève. Ces informations serviront ensuite à personnaliser toutes les recommandations. »* |

> **Alternative (plus rapide)** : sur l'écran de connexion, titre « **Bon retour !** »,
> saisir email + mot de passe → « **Se connecter** » (2 champs seulement).

---

### Étape 3 — L'accueil / Dashboard (≈ 2 min)

**Titre visible : « Salut, [Prénom] ! — Prêt(e) pour ton avenir ? »**

Démontrer les sections **dans l'ordre d'affichage** :

| # | Section à montrer | Action | Dire au jury |
|---|---|---|---|
| 1 | Bandeau de bienvenue + avatar + cloche de notifications | Toucher la cloche puis revenir | *« Chaque élève retrouve son nom, ses alertes personnalisées ici. »* |
| 2 | « **Profil complété à X %** » (barre de progression) | Montrer la barre | *« Plus le profil est complet, plus les recommandations sont précises. »* |
| 3 | « **Mes Services** » : *Chat avec ORIA · Mes Documents · Calendrier · Favoris* | Taper **Chat avec ORIA** (on y revient à l'étape 5) | *« Les services du quotidien sont en un seul clic. »* |
| 4 | « **ORIA te parle** » (message proactif) | Lire le message | *« ORIA n'attend pas qu'on lui parle : elle surveille le parcours de l'élève et l'alerte. »* |
| 5 | Carte « **ANALYSE IA** » → « *Ton parcours idéal a été généré !* » | Taper « **Découvrir mon parcours idéal** » → montrer l'écran puis **revenir** | *« L'IA a déjà analysé le profil et généré un parcours d'études sur mesure. On détaillera à l'étape 6. »* |
| 6 | « **Établissements suggérés** » (% de correspondance) | Faire glisser le carrousel, montrer un % | *« Ce sont les établissements qui correspondent le mieux à ce profil, avec un score de correspondance. »* |
| 7 | « **Explorer les filières** » | Aperçu puis revenir | *« Un catalogue complet de formations. »* |
| 8 | « **Besoin d'aide ?** » (FAQ / Support) | Ouvrir la FAQ, revenir | *« Un espace d'aide intégré. »* |

---

### Étape 4 — Explorer : le catalogue de formations (≈ 1 min 30)

| | |
|---|---|
| **Où** | Onglet « **Explorer** » (barre du bas) |
| **Voir** | Grille d'établissements avec photo, nom, ville, type ; chips de filtres par **pays : Togo 🇹🇬 / Bénin 🇧🇯 / Côte d'Ivoire 🇨🇮** et par type (Université, Grande École…) |
| **Faire** | 1) Montrer le nombre total (**929 établissements**) · 2) Taper un pays → le nombre correspond au pays · 3) Utiliser la **recherche** (ex. « Lomé ») · 4) Ouvrir une **fiche détaillée** (ex. Université de Kara) : présentation, localisation, site web, filières proposées · 5) Ajouter aux **favoris** (étoile) |
| **Dire au jury** | *« Le catalogue réunit près de 1000 établissements réels de trois pays d'Afrique de l'Ouest, avec des filtres par pays et par type, et chaque fiche contient les informations vérifiées : où étudier, quoi étudier, et comment les contacter. »* |

---

### Étape 5 — ORIA : la conversation avec l'assistant IA (≈ 3 min) — cœur de la démo

| | |
|---|---|
| **Où** | Dashboard → bouton « **Chat avec ORIA** » (dans *Mes Services*), ou bouton flottant ✨ sur les onglets Explorer/Profil |
| **Voir** | Écran de discussion : bulles de conversation, champ de saisie, suggestions |
| **Faire** | Poser **3 à 4 questions** (voir la banque de questions en §3.1), laisser ORIA répondre, montrer le **gras, titres et listes** bien rendus |

**Messages clés à faire passer au jury :**

- **Question simple** (ex. « Comment réviser les maths ? ») → *« ORIA répond en 1 à 3 secondes comme un mentor : une réponse directe, des conseils pratiques, et une question de suivi. »*
- **Question sur les établissements** (ex. « Quelles universités au Togo ? ») → *« La réponse s'appuie sur notre base réelle de 929 établissements — ce ne sont pas des informations inventées. »*
- **Mémoire** (ex. « Je suis en 1ʳᵉ D et je veux devenir médecin » puis, **après avoir fermé et rouvert le chat** : « Tu te souviens de moi ? ») → *« ORIA se souvient de votre profil et de vos ambitions d'une session à l'autre. »*
- **Hors sujet** (ex. « Raconte-moi une blague ») → *« ORIA sait rester dans son rôle : elle redirige poliment vers l'orientation. »*

**Dire au jury (phrase d'ensemble)** :
> *« ORIA n'est pas un simple chatbot : c'est un mentor. Elle connaît le catalogue de l'application, elle connaît le profil de chaque élève, elle donne des conseils personnalisés et elle revient vers vous au rendez-vous suivant. »*

---

### Étape 6 — Recommandation personnalisée « Conseils du conseiller IA » (≈ 1 min 30)

| | |
|---|---|
| **Où** | Dashboard → carte **« ANALYSE IA »** → « **Découvrir mon parcours idéal** » |
| **Voir** | Titre « **Mon orientation personnalisée** », bandeau violet « **Recommandation personnalisée — Basée sur ton profil, tes notes et tes quiz** », puis la carte « **Conseils du conseiller IA** » avec un texte structuré : filières proposées (ex. **Médecine générale**, **Droit des affaires**), les matières de l'élève, les métiers et les **établissements réels** cités |
| **Faire** | Lire à voix haute un extrait ; montrer que le texte est mis en forme (gras, titres, listes) ; appuyer sur « **Actualiser** » |
| **Dire au jury** | *« Cette recommandation est écrite par l'IA en tenant compte du profil de l'élève : ses matières préférées, ses notes, ses ambitions. Ce n'est pas un texte générique : chaque élève reçoit le sien, avec les établissements où suivre réellement cette formation. »* |

---

### Étape 7 — Recommandation v2 « 3 signaux » : profil + notes + engagement (≈ 2 min)

| | |
|---|---|
| **Où** | Même écran → encadré « **Nouvelle recommandation (3 signaux)** » → « **Tester la recommandation v2** » |
| **Écran A** | « **Ton niveau actuel** » : grille de cartes (Collège, Lycée, Supérieur) → choisir puis « **Continuer** » |
| **Écran B** | « **Mes bulletins** » : saisir (ou montrer) années scolaires, classes, matières + notes + coefficients → « **Voir mes recommandations** » (ou « Passer cette étape ») |
| **Écran C** | « **Recommandations 3 signaux** » : classement **#1, #2, #3…** avec score final %, badge « **Découverte** », et **3 barres de progression** : **Aspiration** (ce que l'élève veut) · **Réalité** (ses notes) · **Engagement** (ses consultations), + la raison du classement |
| **Dire au jury** | *« Le moteur croise trois signaux : ce que l'élève aspire à faire, ce que ses notes lui permettent réellement, et son comportement sur la plateforme. Chaque recommandation affiche les trois scores séparément : on explique donc l'IA au jury, on ne la subit pas. »* |

---

### Étape 8 — Diagnostic de personnalité (quiz RIASEC) (≈ 1 min 30)

| | |
|---|---|
| **Où** | Sur une fiche de filière (Explorer → fiche) → carte « **Teste tes connaissances** » / quiz |
| **Voir** | « **Sélectionne le quiz** » → questions avec barre de progression → « **Terminer le quiz** » |
| **Résultat** | « **Résultats du diagnostic** » : score animé, **Recommandation personnalisée** (texte IA), **Filières recommandées**, historique |
| **Dire au jury** | *« En quelques questions, l'application mesure le profil psychologique de l'élève (méthode RIASEC utilisée par les conseillers d'orientation du monde entier) et l'utilise comme un quatrième signal de recommandation. »* |

---

### Étape 9 — Aide humaine : conseillers, messages, rendez-vous (≈ 1 min 30)

| | |
|---|---|
| **Où** | Dashboard → « **Besoin d'aide ?** » → **Support** ; ou Explorer → onglet **Profil** |
| **Voir** | « **Support** » : *Foire Aux Questions · Contacter un conseiller · Prendre rendez-vous* ; « **Annuaire des conseillers** » ; « **Messages** » (discussion avec un conseiller) ; « **Mes rendez-vous** » (onglets À venir / Passés) |
| **Faire** | Ouvrir la FAQ → puis l'annuaire → montrer un message existant |
| **Dire au jury** | *« L'IA ne remplace pas l'humain : quand l'élève veut parler à une personne, il contacte un conseiller humain ou prend rendez-vous, directement depuis l'application. »* |

---

### Étape 10 — Profil & sécurité (≈ 45 s)

| | |
|---|---|
| **Où** | Onglet « **Profil** » (barre du bas) |
| **Voir** | Carte d'identité · stats (Favoris / Recommandations / RDV) · « Mon parcours » (niveau, objectif, bulletins) · Préférences · **Sécurité** (mot de passe, **2FA**) · À propos |
| **Faire** | Montrer la section Sécurité ; se déconnecter (dialogue « Se déconnecter ? ») pour finir la vidéo proprement |
| **Dire au jury** | *« Les données de l'élève sont protégées : mot de passe, double authentification, et respect des conditions de confidentialité. »* |

---

### Étape 11 — Conclusion à dire au jury (≈ 30 s)

> *« En résumé : un élève crée son compte en 30 secondes, il a un catalogue de 929 établissements réels dans 3 pays, un assistant IA disponible jour et nuit qui connaît son dossier, deux niveaux de recommandation — personnalisée et croisant profil, notes et engagement — et un accès à des conseillers humains. Le tout sur un téléphone, avec une interface pensée pour des élèves de 15 à 20 ans. »*

---

## 3. Banque de prêts à l'emploi

### 3.1 Questions à poser à ORIA pendant la vidéo

| # | Question | Ce qu'ORIA doit montrer |
|---|---|---|
| 1 | « **Quelles universités au Togo ?** » | Liste réelle (Lomé, Kara, UCAO…) — base de données, pas d'invention |
| 2 | « **Je stresse avant le bac, comment faire ?** » | Dimension mentor : conseils pratiques + plan |
| 3 | « **Comment s'inscrire au BAC au Togo ?** » | Connaissance générale du système éducatif |
| 4 | « **Je suis en 1ʳᵉ D, mon ambition est la médecine** » | Enregistre l'ambition (mémoire du profil) |
| 5 | « **Tu te souviens de mon ambition ?** » *(après fermeture/réouverture du chat)* | Se souvient d'une session à l'autre |
| 6 | « **Quelles universités au Bénin ?** » | Filtrage par pays (pas de confusion entre pays) |
| 7 | « **Raconte-moi une blague** » | Reste dans son rôle, redirige poliment |

> **Attention — Timing** : si une réponse met plus de ~10 s (quota de l'offre gratuite de l'IA),
> patienter en expliquant : *« L'IA réfléchit — elle vérifie ses sources avant de répondre. »*
> Ne jamais reposer la question immédiatement (cela prolonge l'attente).

### 3.2 Ce qu'il ne faut PAS dire au jury

- ❌ « C'est un ChatGPT » → dire : *« un assistant IA spécialisé en orientation »*
- ❌ « L'IA invente les établissements » → dire : *« l'IA s'appuie sur notre base vérifiée »*
- ❌ montrer les fichiers techniques, mots de passe, clés API

---

## 4. Pages secondaires (hors périmètre de la vidéo)

> Ces écrans existent dans l'application mais **ne font pas partie de la démonstration** :
> ils n'ont pas de bouton visible dans l'interface principale.
> Liste conservée uniquement comme référence.

| Écran | Route | Ce qu'il montre |
|---|---|---|
| Simulateur de parcours | `/simulateur` | « Et si je choisissais la série C ? » → filières accessibles + scores |
| Entretien IA | `/entretien` | Simulation d'entretien avec un recruteur IA + score final |
| Portfolio de compétences | `/portfolio` | Compétences notées 1-5, analyse, métiers recommandés |
| Recommandation ORIA agrégée | `/evolution` | Score global + 9 moteurs évalués avec poids |
| Passeport de badges | `/badges` | Gamification : badges débloqués |
| Réseau social | `/reseau` | Fil d'entraide entre élèves |
| Témoignages | `/temoignages` | Témoignages d'anciens |
| Carte thermique | `/datahub` | Statistiques par région |
| Mes documents | `/documents` | Bulletins, CV, attestations |
| Journal d'activité | `/historique` | Historique des actions de l'élève |
| Recherche globale | `/search` | Filières, métiers, séries, établissements |



---

## 5. Dépannage pendant l'enregistrement

| Problème | Solution immédiate |
|---|---|
| Réponse ORIA lente (~10-25 s) | Le quota gratuit de l'IA est atteint → patienter, ne pas reposer la question |
| Erreur réseau / écran blanc | Vérifier le Wi-Fi ; redémarrer l'app ; le backend doit répondre sur `localhost:8085` |
| Backend arrêté | `docker compose up -d` puis attendre 30 s |
| Aucun établissement affiché | Le backend est probablement arrêté (Explorer dépend de l'API) |
| Compte bloqué / mot de passe oublié | « Mot de passe oublié ? » → code à 4 chiffres → nouveau mot de passe |
| Login admin qui échoue | Le mot de passe admin par défaut est `admin123` (pas `admin123!`) |
| Notification pendant l'enregistrement | Couper les notifications du téléphone avant de filmer |

---

## 6. Glossaire pour le jury (mots simples)

| Terme technique | Explication à donner |
|---|---|
| **ORIA** | L'assistant IA de l'application : un conseiller d'orientation électronique qui discute avec l'élève |
| **IA générative / LLM** | Un programme capable de rédiger des textes dans la langue naturelle, comme un humain |
| **RAG / base de connaissances** | L'IA consulte notre base de 929 établissements *avant* de répondre : elle ne répond pas de mémoire |
| **RIASEC** | Une méthode reconnue mondialement qui classe les goûts en 6 grandes familles (Réaliste, Investigateur, Artistique, Social, Entreprenant, Conventionnel) |
| **3 signaux** | Le croisement de : l'aspiration de l'élève + ses notes réelles + son activité sur la plateforme |
| **Score de correspondance** | Un pourcentage qui indique à quel point une formation correspond au profil |
| **API / backend** | Le « cerveau » serveur que l'application contacte ; les données y sont stockées |
| **2FA** | La double vérification de sécurité (mot de passe + code) |

---

*Guide préparé pour la démonstration vidéo — version du 30/09/2026.*
