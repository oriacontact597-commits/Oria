package tg.edtch.activEducation.evolution.domain.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import tg.edtch.activEducation.evolution.domain.entite.ScoringConfig;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ScoringConfigRepository extends JpaRepository<ScoringConfig, Long> {

    Optional<ScoringConfig> findByTrackingId(UUID trackingId);

    Optional<ScoringConfig> findByCountryCodeAndConfigNameAndIsActiveTrue(
            String countryCode, String configName);

    List<ScoringConfig> findByCountryCodeAndIsActiveTrue(String countryCode);
}
