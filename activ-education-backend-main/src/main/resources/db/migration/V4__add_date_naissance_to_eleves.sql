-- V4 : Date de naissance pour les élèves (P1.2 ORIA — consentement parental)
-- Le service de consentement parental (profil.ConsentementParentalService)
-- se base sur l'âge pour décider si un consentement est requis (< 15 ans).
-- Colonne nullable : pas de migration de données (date inconnue pour les existants).

ALTER TABLE eleves
    ADD COLUMN date_naissance DATE;
