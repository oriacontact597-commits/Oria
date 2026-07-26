package tg.edtch.activEducation.evolution.application.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
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

    public Map<String, Double> getWeights(String countryCode, String configName) {
        Optional<ScoringConfig> config = configRepository
                .findByCountryCodeAndConfigNameAndIsActiveTrue(
                        countryCode != null ? countryCode : "TG",
                        configName != null ? configName : "default_v1");
        if (config.isPresent()) {
            return config.get().getWeights();
        }
        log.info("ScoringConfigService: no active config for {}/{}, using defaults",
                countryCode, configName);
        return DEFAULT_WEIGHTS;
    }

    public Map<String, Double> getDefaultWeights() {
        return DEFAULT_WEIGHTS;
    }
}
