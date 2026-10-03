-- seed_bibliotheque.sql — FAQ, séries, filières, métiers, établissements
BEGIN;

-- FAQ
INSERT INTO entrees_faq (tracking_id, question, reponse, categorie, est_publie, nb_vues, created_by, created_at) VALUES
  (gen_random_uuid(), 'Comment créer un compte élève ?', 'Téléchargez l application et suivez les étapes d inscription.', 'Inscription', true, 0, 'seed', '2026-05-23 10:40:18'),
  (gen_random_uuid(), 'Qu est-ce que le test RIASEC ?', 'Questionnaire d orientation selon 6 profils : Réaliste, Investigateur, Artistique, Social, Entreprenant, Conventionnel.', 'Orientation', true, 0, 'seed', '2026-05-23 10:40:18'),
  (gen_random_uuid(), 'Comment prendre rendez-vous avec un conseiller ?', 'Allez dans Messages, sélectionnez un conseiller et proposez un créneau.', 'Rendez-vous', true, 0, 'seed', '2026-05-23 10:40:18'),
  (gen_random_uuid(), 'Les résultats sont-ils fiables ?', 'Le RIASEC est un outil reconnu. Il ne remplace pas un conseiller.', 'Orientation', true, 0, 'seed', '2026-05-23 10:40:18'),
  (gen_random_uuid(), 'Comment modifier mon profil ?', 'Rendez-vous dans la section Profil.', 'Compte', true, 0, 'seed', '2026-05-23 10:40:18'),
  (gen_random_uuid(), 'Puis-je passer le test plusieurs fois ?', 'Oui, l historique est conservé.', 'Diagnostic', true, 0, 'seed', '2026-05-23 10:40:18'),
  (gen_random_uuid(), 'Comment sont protégées mes données ?', 'Stockage sécurisé, jamais partagées sans consentement.', 'Confidentialité', true, 0, 'seed', '2026-05-23 10:40:18'),
  (gen_random_uuid(), 'Que faire si j oublie mon mot de passe ?', 'Utilisez Mot de passe oublié sur l écran de connexion.', 'Connexion', true, 0, 'seed', '2026-05-23 10:40:18');

-- Séries
INSERT INTO fiches (tracking_id, titre, resume, contenu, est_publie, nb_consultations, created_by, created_at) VALUES
  (gen_random_uuid(), 'Série C (Mathématiques)', 'Scientifique axée sur les mathématiques.', 'La série C prépare aux études en maths, physique, informatique, ingénierie.', true, 0, 'seed', '2026-05-23 10:40:18'),
  (gen_random_uuid(), 'Série D (Sciences expérimentales)', 'Scientifique axée sur les SVT.', 'La série D prépare aux carrières en santé, agronomie, environnement.', true, 0, 'seed', '2026-05-23 10:40:18');

-- Schéma actuel : fiches_serie(id, coefficients, debouches, matieres_principales, niveau)
-- (la colonne "code" n'existe plus — voir migration Flyway / ddl-auto=update)
INSERT INTO fiches_serie (id, niveau, matieres_principales)
SELECT id, 'BAC', 'Mathématiques, Physique-Chimie, Informatique' FROM fiches WHERE titre LIKE 'Série C%';
INSERT INTO fiches_serie (id, niveau, matieres_principales)
SELECT id, 'BAC', 'SVT, Physique-Chimie, Mathématiques' FROM fiches WHERE titre LIKE 'Série D%';

-- Filières
INSERT INTO fiches (tracking_id, titre, resume, contenu, est_publie, nb_consultations, created_by, created_at) VALUES
  (gen_random_uuid(), 'Médecine Générale', 'Devenir médecin.', 'Études de 7 à 10 ans. Stages hospitaliers, spécialisation.', true, 0, 'seed', '2026-05-23 10:40:18'),
  (gen_random_uuid(), 'Génie Informatique', 'Développer des solutions informatiques.', 'Formation d ingénieurs en systèmes complexes.', true, 0, 'seed', '2026-05-23 10:40:18'),
  (gen_random_uuid(), 'Droit des Affaires', 'Conseiller juridique.', 'Prépare aux carrières juridiques en entreprise.', true, 0, 'seed', '2026-05-23 10:40:18');

INSERT INTO fiches_filiere (id, duree, niveau_requis, conditions_admission, programme, debouches_metiers, domaine) VALUES
  ((SELECT id FROM fiches WHERE titre = 'Médecine Générale'), '7-10 ans', 'Bac+1 validé', 'Concours après 1ère année.', 'PACES/LAS, stages.', 'Médecin généraliste, spécialiste.', 'Santé'),
  ((SELECT id FROM fiches WHERE titre = 'Génie Informatique'), '5 ans', 'Bac C, D, E', 'Concours ou dossier.', 'Algo, prog, BD, réseaux, IA.', 'Développeur, DevOps, architecte.', 'Technologie'),
  ((SELECT id FROM fiches WHERE titre = 'Droit des Affaires'), '5 ans', 'Bac toutes séries', 'Dossier.', 'Droit civil, commercial, fiscal.', 'Juriste, avocat, notaire.', 'Droit');

-- Métiers
INSERT INTO fiches (tracking_id, titre, resume, contenu, est_publie, nb_consultations, created_by, created_at) VALUES
  (gen_random_uuid(), 'Médecin Généraliste', 'Soigner et diagnostiquer.', 'Premier recours pour les soins de santé.', true, 0, 'seed', '2026-05-23 10:40:18'),
  (gen_random_uuid(), 'Développeur Full-Stack', 'Créer des applications.', 'Conçoit et développe frontend et backend.', true, 0, 'seed', '2026-05-23 10:40:18'),
  (gen_random_uuid(), 'Avocat', 'Défendre et conseiller.', 'Conseille et défend devant les tribunaux.', true, 0, 'seed', '2026-05-23 10:40:18');

INSERT INTO fiches_metier (id, secteur, missions, competences, formations_acces, debouches_togo, fourchette_salaire) VALUES
  ((SELECT id FROM fiches WHERE titre = 'Médecin Généraliste'), 'Santé', 'Diagnostiquer, prescrire, suivre.', 'Analyse, rigueur, écoute.', 'Doctorat en Médecine.', 'Hôpitaux, cliniques.', '300 000 - 800 000 FCFA'),
  ((SELECT id FROM fiches WHERE titre = 'Développeur Full-Stack'), 'Technologie', 'Concevoir, développer, déployer.', 'JS/TS, React, Node, SQL, Git.', 'Licence/Master Informatique.', 'Startups, entreprises.', '200 000 - 600 000 FCFA'),
  ((SELECT id FROM fiches WHERE titre = 'Avocat'), 'Justice', 'Conseiller, rédiger, plaider.', 'Expression, argumentation.', 'Master Droit + CAPA.', 'Cabinets, services juridiques.', '250 000 - 700 000 FCFA');

-- Établissements
INSERT INTO fiches (tracking_id, titre, resume, contenu, est_publie, nb_consultations, created_by, created_at) VALUES
  (gen_random_uuid(), 'Université de Lomé (UL)', 'Plus grande université publique du Togo.', 'Formations en sciences, droit, économie, lettres, médecine.', true, 0, 'seed', '2026-05-23 10:40:18'),
  (gen_random_uuid(), 'Institut Africain d Informatique (IAI)', 'École spécialisée en informatique.', 'Licence/Master en Génie Informatique, Data Science.', true, 0, 'seed', '2026-05-23 10:40:18');

INSERT INTO fiches_etablissement (id, ville, type_etablissement, site_web, adresse, contacts, offre_formation, est_public, country_code) VALUES
  ((SELECT id FROM fiches WHERE titre = 'Université de Lomé (UL)'), 'Lomé', 'UNIVERSITE', 'https://univ-lome.tg', 'BP: 1515 Lomé, Togo', '+228 22 25 38 45', 'Sciences, Droit, Économie, Lettres, Médecine', true, 'TG'),
  ((SELECT id FROM fiches WHERE titre = 'Institut Africain d Informatique (IAI)'), 'Lomé', 'ECOLE_SUPERIEURE', 'https://iaitogo.tg', 'Lomé, Togo', '+228 22 21 47 57', 'Génie Informatique, Sécurité, Data Science', true, 'TG');

-- Relations ManyToMany
INSERT INTO serie_filiere (serie_id, filiere_id)
SELECT s.id, f.id FROM fiches_serie s, fiches_filiere f
WHERE s.id = (SELECT id FROM fiches WHERE titre LIKE 'Série C%') AND f.id = (SELECT id FROM fiches WHERE titre = 'Médecine Générale')
ON CONFLICT DO NOTHING;
INSERT INTO serie_filiere (serie_id, filiere_id)
SELECT s.id, f.id FROM fiches_serie s, fiches_filiere f
WHERE s.id = (SELECT id FROM fiches WHERE titre LIKE 'Série D%') AND f.id = (SELECT id FROM fiches WHERE titre = 'Médecine Générale')
ON CONFLICT DO NOTHING;
INSERT INTO serie_filiere (serie_id, filiere_id)
SELECT s.id, f.id FROM fiches_serie s, fiches_filiere f
WHERE s.id = (SELECT id FROM fiches WHERE titre LIKE 'Série C%') AND f.id = (SELECT id FROM fiches WHERE titre = 'Génie Informatique')
ON CONFLICT DO NOTHING;

INSERT INTO filiere_metier (metier_id, filiere_id)
SELECT m.id, f.id FROM fiches_metier m, fiches_filiere f
WHERE m.id = (SELECT id FROM fiches WHERE titre = 'Médecin Généraliste') AND f.id = (SELECT id FROM fiches WHERE titre = 'Médecine Générale')
ON CONFLICT DO NOTHING;
INSERT INTO filiere_metier (metier_id, filiere_id)
SELECT m.id, f.id FROM fiches_metier m, fiches_filiere f
WHERE m.id = (SELECT id FROM fiches WHERE titre = 'Développeur Full-Stack') AND f.id = (SELECT id FROM fiches WHERE titre = 'Génie Informatique')
ON CONFLICT DO NOTHING;
INSERT INTO filiere_metier (metier_id, filiere_id)
SELECT m.id, f.id FROM fiches_metier m, fiches_filiere f
WHERE m.id = (SELECT id FROM fiches WHERE titre = 'Avocat') AND f.id = (SELECT id FROM fiches WHERE titre = 'Droit des Affaires')
ON CONFLICT DO NOTHING;

INSERT INTO etablissement_filiere (etablissement_id, filiere_id)
SELECT e.id, f.id FROM fiches_etablissement e, fiches_filiere f
WHERE e.id = (SELECT id FROM fiches WHERE titre = 'Université de Lomé (UL)') AND f.id = (SELECT id FROM fiches WHERE titre = 'Médecine Générale')
ON CONFLICT DO NOTHING;
INSERT INTO etablissement_filiere (etablissement_id, filiere_id)
SELECT e.id, f.id FROM fiches_etablissement e, fiches_filiere f
WHERE e.id = (SELECT id FROM fiches WHERE titre = 'Institut Africain d Informatique (IAI)') AND f.id = (SELECT id FROM fiches WHERE titre = 'Génie Informatique')
ON CONFLICT DO NOTHING;

-- ===== Établissements multi-pays (P1.1 ORIA) : Bénin (BJ) + Côte d'Ivoire (CI) =====
-- Note : country_code est explicite ici car le DEFAULT 'TG' de V3 ne suffit pas pour BJ/CI.

-- Bénin (BJ) — 5 universités
INSERT INTO fiches (tracking_id, titre, resume, contenu, est_publie, nb_consultations, created_by, created_at) VALUES
  (gen_random_uuid(), 'Université d''Abomey-Calavi (UAC)', 'Plus grande université publique du Bénin.', 'Formations pluridisciplinaires : sciences, droit, lettres, médecine, agronomie.', true, 0, 'seed', '2026-08-25 10:00:00'),
  (gen_random_uuid(), 'Université de Parakou (UP)', 'Université publique du Nord-Bénin.', 'Formations en sciences, lettres, droit, agronomie, médecine.', true, 0, 'seed', '2026-08-25 10:00:00'),
  (gen_random_uuid(), 'Institut National de la Statistique et de la Démographie (INStaD)', 'École spécialisée en statistique et démographie.', 'Licence/Master en statistique, démographie, économie appliquée.', true, 0, 'seed', '2026-08-25 10:00:00'),
  (gen_random_uuid(), 'École Polytechnique d''Abomey-Calavi (EPAC)', 'Grande école d''ingénieurs publique.', 'Cycle ingénieur en génie civil, électrique, mécanique, informatique.', true, 0, 'seed', '2026-08-25 10:00:00'),
  (gen_random_uuid(), 'Université Catholique de l''Afrique de l''Ouest - UCAO (Bénin)', 'Université privée confessionnelle.', 'Formations en droit, gestion, lettres, théologie, sciences infirmières.', true, 0, 'seed', '2026-08-25 10:00:00');

INSERT INTO fiches_etablissement (id, ville, type_etablissement, site_web, adresse, contacts, offre_formation, est_public, country_code) VALUES
  ((SELECT id FROM fiches WHERE titre = 'Université d''Abomey-Calavi (UAC)'), 'Abomey-Calavi', 'UNIVERSITE', 'https://www.uac.bj', '01 BP 526 Cotonou, Bénin', '+229 21 36 00 74', 'Sciences, Droit, Lettres, Médecine, Agronomie', true, 'BJ'),
  ((SELECT id FROM fiches WHERE titre = 'Université de Parakou (UP)'), 'Parakou', 'UNIVERSITE', 'https://www.univ-parakou.bj', 'BP 123 Parakou, Bénin', '+229 23 61 07 26', 'Sciences, Lettres, Droit, Agronomie, Médecine', true, 'BJ'),
  ((SELECT id FROM fiches WHERE titre = 'Institut National de la Statistique et de la Démographie (INStaD)'), 'Cotonou', 'ECOLE_SUPERIEURE', 'https://www.instad.bj', '01 BP 323 Cotonou, Bénin', '+229 21 30 82 22', 'Statistique, Démographie, Économie appliquée', true, 'BJ'),
  ((SELECT id FROM fiches WHERE titre = 'École Polytechnique d''Abomey-Calavi (EPAC)'), 'Abomey-Calavi', 'ECOLE_SUPERIEURE', 'https://www.epac.bj', '01 BP 2009 Cotonou, Bénin', '+229 21 36 00 91', 'Génie civil, électrique, mécanique, informatique', true, 'BJ'),
  ((SELECT id FROM fiches WHERE titre = 'Université Catholique de l''Afrique de l''Ouest - UCAO (Bénin)'), 'Cotonou', 'UNIVERSITE', 'https://www.ucaobenin.com', 'BP 0128 Cotonou, Bénin', '+229 21 30 17 47', 'Droit, Gestion, Lettres, Théologie, Sciences infirmières', false, 'BJ');

-- Côte d'Ivoire (CI) — 5 universités
INSERT INTO fiches (tracking_id, titre, resume, contenu, est_publie, nb_consultations, created_by, created_at) VALUES
  (gen_random_uuid(), 'Université Félix Houphouët-Boigny (UFHB)', 'Plus grande université publique de Côte d''Ivoire.', 'Formations pluridisciplinaires : sciences, droit, lettres, médecine, pharmacie.', true, 0, 'seed', '2026-08-25 10:00:00'),
  (gen_random_uuid(), 'Université Nangui Abrogoua (UNA)', 'Université publique d''Abidjan (ex-Université d''Abobo-Adjamé).', 'Formations en sciences, technologies, sciences économiques.', true, 0, 'seed', '2026-08-25 10:00:00'),
  (gen_random_uuid(), 'Institut National Polytechnique Félix Houphouët-Boigny (INP-HB)', 'Grande école d''ingénieurs publique.', 'Cycle ingénieur en génie chimique, électrique, mécanique, alimentaire.', true, 0, 'seed', '2026-08-25 10:00:00'),
  (gen_random_uuid(), 'Université Jean Lorougnon Guédé (UJLoG)', 'Université publique de Daloa.', 'Formations en sciences, lettres, droit, sciences économiques.', true, 0, 'seed', '2026-08-25 10:00:00'),
  (gen_random_uuid(), 'Université Catholique de l''Afrique de l''Ouest - UCAO (Côte d''Ivoire)', 'Université privée confessionnelle (antenne ivoirienne).', 'Formations en droit, gestion, lettres, théologie, sciences infirmières.', true, 0, 'seed', '2026-08-25 10:00:00');

INSERT INTO fiches_etablissement (id, ville, type_etablissement, site_web, adresse, contacts, offre_formation, est_public, country_code) VALUES
  ((SELECT id FROM fiches WHERE titre = 'Université Félix Houphouët-Boigny (UFHB)'), 'Abidjan', 'UNIVERSITE', 'https://www.ufhb.edu.ci', 'BP V34 Abidjan 01, Côte d''Ivoire', '+225 27 22 44 27 09', 'Sciences, Droit, Lettres, Médecine, Pharmacie', true, 'CI'),
  ((SELECT id FROM fiches WHERE titre = 'Université Nangui Abrogoua (UNA)'), 'Abidjan', 'UNIVERSITE', 'https://www.una.ci', '02 BP 801 Abidjan 02, Côte d''Ivoire', '+225 27 21 27 84 12', 'Sciences, Technologies, Sciences économiques', true, 'CI'),
  ((SELECT id FROM fiches WHERE titre = 'Institut National Polytechnique Félix Houphouët-Boigny (INP-HB)'), 'Yamoussoukro', 'ECOLE_SUPERIEURE', 'https://www.inphb.ci', 'BP 1093 Yamoussoukro, Côte d''Ivoire', '+225 27 30 64 32 26', 'Génie chimique, électrique, mécanique, alimentaire', true, 'CI'),
  ((SELECT id FROM fiches WHERE titre = 'Université Jean Lorougnon Guédé (UJLoG)'), 'Daloa', 'UNIVERSITE', 'https://www.ujlog.ci', 'BP 150 Daloa, Côte d''Ivoire', '+225 27 32 78 32 12', 'Sciences, Lettres, Droit, Sciences économiques', true, 'CI'),
  ((SELECT id FROM fiches WHERE titre = 'Université Catholique de l''Afrique de l''Ouest - UCAO (Côte d''Ivoire)'), 'Abidjan', 'UNIVERSITE', 'https://www.ucao-uuc.ci', 'BP 4148 Abidjan 04, Côte d''Ivoire', '+225 27 22 49 30 60', 'Droit, Gestion, Lettres, Théologie, Sciences infirmières', false, 'CI');

COMMIT;
