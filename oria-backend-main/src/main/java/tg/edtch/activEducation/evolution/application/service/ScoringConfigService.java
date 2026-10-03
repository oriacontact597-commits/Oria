package tg.edtch.activEducation.evolution.application.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import tg.edtch.activEducation.evolution.domain.entite.ScoringConfig;
import tg.edtch.activEducation.evolution.domain.repository.ScoringConfigRepository;

import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class ScoringConfigService {

    private final ScoringConfigRepository configRepository;

    private static final Map<String, Double> DEFAULT_WEIGHTS = Map.of(
            "academic", 0.40,
            "interest", 0.20,
            "riasec", 0.15,
            "behaviour", 0.05,
            "skills", 0.10,
            "activities", 0.10,
            "career", 0.0,
            "university", 0.0,
            "confidence", 0.0);

    /**
     * Récupère les pondérations actives pour un (pays, name).
     * Mis en cache Redis sous "oria:sep:scoring:{countryCode}:{configName}" (TTL 1h).
     * Le cache est évincé par MlRegistry sur promote/rollback.
     */
    @Cacheable(value = "scoring", key = "#countryCode + ':' + #configName", unless = "#result == null")
    public Map<String, Double> getWeights(String countryCode, String configName) {
        String country = countryCode != null ? countryCode : "TG";
        String name = configName != null ? configName : "default_v1";
        Optional<ScoringConfig> config = configRepository
                .findByCountryCodeAndConfigNameAndIsActiveTrue(country, name);
        if (config.isPresent()) {
            return config.get().getWeights();
        }
        log.info("ScoringConfigService: no active config for {}/{}, using defaults", country, name);
        return DEFAULT_WEIGHTS;
    }

    public Map<String, Double> getDefaultWeights() {
        return DEFAULT_WEIGHTS;
    }
}
