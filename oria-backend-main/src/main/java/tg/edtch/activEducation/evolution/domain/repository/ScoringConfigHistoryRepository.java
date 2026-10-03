package tg.edtch.activEducation.evolution.domain.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import tg.edtch.activEducation.evolution.domain.entite.ScoringConfigHistory;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface ScoringConfigHistoryRepository extends JpaRepository<ScoringConfigHistory, Long> {

    Optional<ScoringConfigHistory> findByTrackingId(UUID trackingId);

    /**
     * Historique complet pour un (pays, nom), le plus récent en premier.
     */
    Page<ScoringConfigHistory> findByCountryCodeAndConfigNameOrderByChangedAtDesc(
            String countryCode, String configName, Pageable pageable);

    /**
     * L'entrée actuellement active (is_current=true) pour un (pays, nom).
     * Renvoie Optional.empty() si la table principale n'a pas encore été initialisée.
     */
    Optional<ScoringConfigHistory> findByCountryCodeAndConfigNameAndIsCurrentTrue(
            String countryCode, String configName);
}
