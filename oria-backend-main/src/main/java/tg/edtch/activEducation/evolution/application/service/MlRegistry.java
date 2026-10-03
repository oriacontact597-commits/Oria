package tg.edtch.activEducation.evolution.application.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tg.edtch.activEducation.evolution.application.dto.PromoteWeightsRequest;
import tg.edtch.activEducation.evolution.application.dto.ScoringConfigHistoryResponse;
import tg.edtch.activEducation.evolution.domain.entite.ScoringConfig;
import tg.edtch.activEducation.evolution.domain.entite.ScoringConfigHistory;
import tg.edtch.activEducation.evolution.domain.repository.ScoringConfigHistoryRepository;
import tg.edtch.activEducation.evolution.domain.repository.ScoringConfigRepository;

import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Optional;
import java.util.UUID;

/**
 * MlRegistry — service de versioning/rollback des pondérations de scoring (P2.1 ORIA).
 *
 * <p>Responsabilités :
 * <ul>
 *   <li>Publier une nouvelle configuration (PROMOTE) : historise, désactive l'ancienne, évince le cache.</li>
 *   <li>Restaurer une configuration passée (ROLLBACK) : copie les weights depuis l'historique source.</li>
 *   <li>Consulter l'historique (par (pays, name)) et la config active courante.</li>
 * </ul>
 *
 * <p>Pas d'intégration MLflow : on n'utilise pas de modèle ML dans RecommendationOrchestrator
 * (uniquement des engines heuristiques). Le "Ml" du nom suit la convention du cahier de charges ;
 * l'implémentation est une registry de configurations de scoring avec audit + rollback.</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class MlRegistry {

    private final ScoringConfigRepository configRepository;
    private final ScoringConfigHistoryRepository historyRepository;

    /** Tolérance pour la validation de la somme des weights. */
    private static final double WEIGHT_SUM_TOLERANCE = 0.001;
    /** Nom logique utilisé par défaut si l'admin n'en spécifie pas. */
    private static final String DEFAULT_CONFIG_NAME = "default_v1";

    // ─────────────────────────────────────────────────────────────────────────
    // PROMOTE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Promeut une nouvelle configuration de scoring :
     * <ol>
     *   <li>Valide la somme des weights (= 1.0 ± tolérance).</li>
     *   <li>Désactive l'éventuelle {@code ScoringConfig} active pour (pays, name).</li>
     *   <li>Crée la nouvelle {@code ScoringConfig} (is_active=true).</li>
     *   <li>Désactive l'éventuelle entrée d'historique {@code is_current=true} pour (pays, name).</li>
     *   <li>Crée l'entrée d'historique (action=PROMOTE, is_current=true).</li>
     *   <li>Évince le cache Redis pour forcer la relecture.</li>
     * </ol>
     *
     * @return l'entrée d'historique créée (avec son trackingId)
     * @throws IllegalArgumentException si la somme des weights n'est pas ≈ 1.0
     */
    @Transactional
    @CacheEvict(value = "scoring", key = "#request.countryCode + ':' + #request.configName")
    public ScoringConfigHistoryResponse promoteWeights(PromoteWeightsRequest request, String userEmail) {
        validateWeights(request.getWeights());

        String country = request.getCountryCode();
        String name = request.getConfigName();

        // 1. Désactiver l'ancienne ScoringConfig active (s'il y en a une)
        Optional<ScoringConfig> previous = configRepository.findByCountryCodeAndConfigNameAndIsActiveTrue(country, name);
        previous.ifPresent(old -> {
            old.setIsActive(false);
            configRepository.save(old);
            log.info("MlRegistry: désactivation de ScoringConfig trackingId={}", old.getTrackingId());
        });

        // 2. Créer la nouvelle ScoringConfig active
        ScoringConfig newConfig = ScoringConfig.builder()
                .countryCode(country)
                .configName(name)
                .weights(request.getWeights())
                .isActive(true)
                .build();
        newConfig = configRepository.save(newConfig);
        log.info("MlRegistry: nouvelle ScoringConfig créée trackingId={}", newConfig.getTrackingId());

        // 3. Désactiver l'ancienne entrée d'historique is_current=true
        Optional<ScoringConfigHistory> previousCurrent =
                historyRepository.findByCountryCodeAndConfigNameAndIsCurrentTrue(country, name);
        previousCurrent.ifPresent(old -> {
            old.setIsCurrent(false);
            historyRepository.save(old);
        });

        // 4. Créer l'entrée d'historique
        ScoringConfigHistory history = ScoringConfigHistory.builder()
                .countryCode(country)
                .configName(name)
                .weights(request.getWeights())
                .action(ScoringConfigHistory.ActionType.PROMOTE)
                .rolledBackFrom(null)
                .comment(request.getComment())
                .changedBy(userEmail)
                .isCurrent(true)
                .build();
        history = historyRepository.save(history);
        log.info("MlRegistry: PROMOTE history trackingId={} par {}", history.getTrackingId(), userEmail);

        return ScoringConfigHistoryResponse.fromEntity(history);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ROLLBACK
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Restaure les weights d'une entrée d'historique source. Crée une nouvelle
     * ScoringConfig (active) et une entrée d'historique (action=ROLLBACK) qui pointe
     * vers la source via {@code rolled_back_from}.
     *
     * @throws NoSuchElementException si l'historique source n'existe pas
     * @throws IllegalArgumentException si l'historique source est lui-même un ROLLBACK
     *         (empêche les chaînes de rollback vers rollback)
     */
    @Transactional
    @CacheEvict(value = "scoring", allEntries = true)
    public ScoringConfigHistoryResponse rollbackTo(UUID sourceTrackingId, String userEmail, String comment) {
        ScoringConfigHistory source = historyRepository.findByTrackingId(sourceTrackingId)
                .orElseThrow(() -> new NoSuchElementException(
                        "MlRegistry: historique introuvable trackingId=" + sourceTrackingId));

        if (source.getAction() == ScoringConfigHistory.ActionType.ROLLBACK) {
            throw new IllegalArgumentException(
                    "MlRegistry: impossible de rollback vers un ROLLBACK (trackingId=" + sourceTrackingId + ")");
        }

        String country = source.getCountryCode();
        String name = source.getConfigName();
        Map<String, Double> weights = source.getWeights();

        // 1. Désactiver l'ancienne ScoringConfig active
        configRepository.findByCountryCodeAndConfigNameAndIsActiveTrue(country, name)
                .ifPresent(old -> {
                    old.setIsActive(false);
                    configRepository.save(old);
                });

        // 2. Créer la nouvelle ScoringConfig avec les weights de la source
        ScoringConfig restored = ScoringConfig.builder()
                .countryCode(country)
                .configName(name)
                .weights(weights)
                .isActive(true)
                .build();
        configRepository.save(restored);

        // 3. Désactiver l'ancienne entrée d'historique is_current
        historyRepository.findByCountryCodeAndConfigNameAndIsCurrentTrue(country, name)
                .ifPresent(old -> {
                    old.setIsCurrent(false);
                    historyRepository.save(old);
                });

        // 4. Créer l'entrée d'historique ROLLBACK
        ScoringConfigHistory rollback = ScoringConfigHistory.builder()
                .countryCode(country)
                .configName(name)
                .weights(weights)
                .action(ScoringConfigHistory.ActionType.ROLLBACK)
                .rolledBackFrom(sourceTrackingId)
                .comment(comment)
                .changedBy(userEmail)
                .isCurrent(true)
                .build();
        rollback = historyRepository.save(rollback);
        log.info("MlRegistry: ROLLBACK history trackingId={} (source={}) par {}",
                rollback.getTrackingId(), sourceTrackingId, userEmail);

        return ScoringConfigHistoryResponse.fromEntity(rollback);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // QUERIES
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Historique paginé pour un (pays, name), le plus récent en premier.
     */
    @Transactional(readOnly = true)
    public Page<ScoringConfigHistoryResponse> getHistory(String countryCode, String configName, Pageable pageable) {
        String country = countryCode != null ? countryCode : "TG";
        String name = configName != null ? configName : DEFAULT_CONFIG_NAME;
        return historyRepository
                .findByCountryCodeAndConfigNameOrderByChangedAtDesc(country, name, pageable)
                .map(ScoringConfigHistoryResponse::fromEntity);
    }

    /**
     * Config active courante pour un (pays, name), ou null si aucune n'a été promue.
     */
    @Transactional(readOnly = true)
    public ScoringConfigHistoryResponse getCurrent(String countryCode, String configName) {
        String country = countryCode != null ? countryCode : "TG";
        String name = configName != null ? configName : DEFAULT_CONFIG_NAME;
        return historyRepository
                .findByCountryCodeAndConfigNameAndIsCurrentTrue(country, name)
                .map(ScoringConfigHistoryResponse::fromEntity)
                .orElse(null);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // VALIDATION
    // ─────────────────────────────────────────────────────────────────────────

    private void validateWeights(Map<String, Double> weights) {
        if (weights == null || weights.isEmpty()) {
            throw new IllegalArgumentException("MlRegistry: weights ne peut pas être null ou vide");
        }
        // Toutes les valeurs ≥ 0
        for (Map.Entry<String, Double> entry : weights.entrySet()) {
            Double value = entry.getValue();
            if (value == null || value < 0) {
                throw new IllegalArgumentException(
                        "MlRegistry: weight '" + entry.getKey() + "' doit être ≥ 0 (reçu: " + value + ")");
            }
        }
        // Somme ≈ 1.0
        double sum = weights.values().stream().mapToDouble(Double::doubleValue).sum();
        if (Math.abs(sum - 1.0) > WEIGHT_SUM_TOLERANCE) {
            throw new IllegalArgumentException(
                    "MlRegistry: la somme des weights doit être 1.0 (reçu: " + sum + ")");
        }
    }
}
