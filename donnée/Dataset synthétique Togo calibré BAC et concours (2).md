# Dataset synthétique Togo calibré BAC et concours

## Avertissement

Ce fichier contient **58 800 profils synthétiques**. Il ne représente pas 58 800 étudiants réels et ne constitue pas un résultat officiel. Les identifiants, notes, rangs, profils et labels sont générés artificiellement.

Le fichier peut servir à tester l’application, les importations, l’API et le pipeline ML. Il ne doit pas servir à publier des taux réels ni à entraîner le modèle de production comme s’il s’agissait de vérité terrain.

## Composition

| Groupe | Années | Volume |
|---|---:|---:|
| BAC 1 | 2021–2026 | 15 000 |
| BAC 2 | 2021–2026 | 15 000 |
| Concours/filières simulés | 2021–2026 | 28 800 |
| **Total** |  | **58 800** |

Le fichier contient 23 colonnes, dont `cohorte`, `serie_bac`, `type_enseignement`, `concours_filiere`, `taux_reference_admission`, `resultat_final`, `source_type` et `verification_status`.

## Séries représentées

Les profils sont répartis entre les séries générales et techniques suivantes : **A3, A4, C, D, E, G1, G2, G3, F1, F2, F3, F4, Ti1 et Ti2**. La répartition est pondérée pour éviter une distribution uniforme artificielle ; elle reste toutefois une simulation et ne doit pas être interprétée comme la distribution officielle des candidats togolais.

La colonne `type_enseignement` distingue `GENERAL` et `TECHNIQUE`.

## Taux BAC intégrés

| Année | BAC 1 | BAC 2 | Statut de la source |
|---:|---:|---:|---|
| 2021 | 76,58 % | 69,00 % | BAC 1 et comparaison BAC 2 rapportées par le portail officiel |
| 2022 | 75,00 % | 74,34 % | Portail officiel du Togo |
| 2023 | 78,50 % | 79,43 % | Portail officiel du Togo |
| 2024 | 71,73 % | 46,71 % | À revérifier dans les communiqués officiels originaux |
| 2025 | 60,49 % | 72,63 % | BAC 1 officiel ; BAC 2 à croiser avec la source institutionnelle originale |
| 2026 | 73,05 % | 81,27 % | Portail officiel du Togo |

Les valeurs de 2021–2023 et 2025–2026 sont utilisées comme repères documentaires. Les valeurs 2024 et BAC 2 2025 sont marquées avec prudence dans `taux_calibrage_bac_concours.csv` et doivent être revérifiées avant une analyse statistique.

## Concours et filières

Le scénario contient : IUT-Gestion, ESA-Agronomie, ESTBA-Sciences, EPL-Education, EAM-Arts-Métiers, INSE-Economie, Informatique, Droit, Médecine, Sciences économiques, Lettres et ENFPE-Education.

Les taux de ces concours ne sont **pas des taux nationaux officiels**. Ils servent uniquement à créer un scénario de test différencié. Chaque ligne porte `type_calibrage=SIMULE_SCENARIO_NON_OFFICIEL` et `source_type=SCENARIO_SIMULE` pour empêcher une confusion avec les données publiques.

## Sources documentaires BAC

- BAC 1 2021 — portail officiel : https://www.republiquetogolaise.tg/education/1707-5802-bac-1-76-58-de-taux-de-reussite-general
- BAC 2022 — portail officiel : https://www.republiquetogolaise.tg/education/2407-7112-bac-2022-74-de-taux-de-reussite-en-hausse
- BAC 1/BAC 2 2023 — portail officiel : https://www.republiquetogolaise.tg/education/0108-8290-annee-academique-2022-2023-les-resultats-de-nouveau-satisfaisants-a-l-issue-des-examens
- BAC 1 2025 — portail officiel : https://www.republiquetogolaise.tg/education/1606-10774-bac-1-60-de-taux-de-reussite
- BAC 1 2026 — portail officiel : https://www.republiquetogolaise.tg/education/0806-11964-bac-l-2026-73-05-de-taux-de-reussite-en-hausse
- BAC 2 2026 — portail officiel : https://www.republiquetogolaise.tg/education/1007-12084-bac-2026-81-27-de-taux-de-reussite

## Interprétation correcte

Un taux de réussite de 73,05 % signifie que, dans une cohorte simulée, environ 73,05 % des lignes BAC 1 reçoivent le label synthétique `ADMIS`. Cela ne signifie pas que ces lignes correspondent aux noms d’une liste officielle.

Pour obtenir un véritable dataset de production, il faut remplacer les lignes synthétiques par des profils réels obtenus avec autorisation, et rattacher chaque label à une preuve officielle vérifiable.
