package tg.edtch.activEducation.shared.ai.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tg.edtch.activEducation.bibliotheque.domain.entite.Fiche;
import tg.edtch.activEducation.bibliotheque.repository.FicheRepository;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Re-vectorise les fiches de la bibliothèque en utilisant le provider d'embedding
 * configuré (Ollama par défaut, OpenAI en fallback).
 *
 * Utilisé par FicheEmbeddingAdminController et peut être appelé par un script CLI.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FicheEmbeddingIndexer {

    private final FicheRepository ficheRepository;
    private final AIEmbeddingService embeddingService;

    public record IndexResult(int total, int updated, int failed, int skipped) {}

    /**
     * Re-vectorise toutes les fiches publiées sans embedding, ou toutes les fiches
     * si forceReindex=true.
     */
    @Transactional
    public IndexResult reindexAll(boolean forceReindex, int batchSize) {
        var allFiches = ficheRepository.findAll();
        AtomicInteger updated = new AtomicInteger();
        AtomicInteger failed = new AtomicInteger();
        AtomicInteger skipped = new AtomicInteger();

        for (Fiche fiche : allFiches) {
            if (!Boolean.TRUE.equals(fiche.getEstPublie())) {
                skipped.incrementAndGet();
                continue;
            }
            if (!forceReindex && fiche.getEmbedding() != null && fiche.getEmbedding().length > 0) {
                skipped.incrementAndGet();
                continue;
            }
            try {
                String text = buildEmbeddingText(fiche);
                if (text.isBlank()) {
                    skipped.incrementAndGet();
                    continue;
                }
                float[] embedding = embeddingService.generateEmbedding(text);
                fiche.setEmbedding(embedding);
                ficheRepository.save(fiche);
                updated.incrementAndGet();
                if (updated.get() % 25 == 0) {
                    log.info("Reindex: {}/{} fiches mises à jour", updated.get(), allFiches.size());
                }
            } catch (Exception e) {
                failed.incrementAndGet();
                log.warn("Échec embedding fiche {} ({}): {}",
                    fiche.getId(), fiche.getTitre(), e.getMessage());
            }
        }
        log.info("Reindex terminé: total={}, updated={}, failed={}, skipped={}",
            allFiches.size(), updated.get(), failed.get(), skipped.get());
        return new IndexResult(allFiches.size(), updated.get(), failed.get(), skipped.get());
    }

    private String buildEmbeddingText(Fiche fiche) {
        // Combine titre + resume + contenu (tronqué) pour générer un embedding représentatif
        StringBuilder sb = new StringBuilder();
        if (fiche.getTitre() != null) sb.append(fiche.getTitre()).append(". ");
        if (fiche.getResume() != null) sb.append(fiche.getResume()).append(" ");
        if (fiche.getContenu() != null) {
            String contenu = fiche.getContenu();
            if (contenu.length() > 2000) contenu = contenu.substring(0, 2000);
            sb.append(contenu);
        }
        return sb.toString().trim();
    }
}
