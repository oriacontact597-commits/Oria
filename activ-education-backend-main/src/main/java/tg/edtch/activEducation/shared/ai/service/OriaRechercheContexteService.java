package tg.edtch.activEducation.shared.ai.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import tg.edtch.activEducation.bibliotheque.domain.entite.Fiche;
import tg.edtch.activEducation.bibliotheque.repository.FicheRepository;

import java.util.List;

/**
 * Service isolé pour la recherche de contexte ORIA.
 * <p>
 * IMPORTANT : utilise REQUIRES_NEW pour que les exceptions pgvector (ou autres) ne
 * polluent pas la transaction parente. Chaque recherche est autonome et retourne
 * null en cas d'échec au lieu de remonter une exception.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class OriaRechercheContexteService {

    private final AIEmbeddingService embeddingService;
    private final FicheRepository ficheRepository;

    /**
     * Active ou désactive la recherche vectorielle. Mettre à false quand pgvector
     * n'est pas installé pour éviter les erreurs "type vector does not exist".
     */
    @Value("${oria.rag.vectoriel:false}")
    private boolean vectorielActive;

    /**
     * Tente la recherche vectorielle ; en cas d'échec (pgvector indispo, embedding
     * échoué, etc.), bascule sur la recherche mot-clé enrichie. Ne lève jamais
     * d'exception.
     */
    public List<Fiche> rechercher(String message) {
        if (vectorielActive) {
            try {
                List<Fiche> result = rechercheVectorielle(message);
                if (!result.isEmpty()) return result;
            } catch (Exception e) {
                log.warn("RAG vectoriel indisponible, fallback mot-clé: {}", e.getMessage());
            }
        } else {
            log.debug("RAG vectoriel désactivé (oria.rag.vectoriel=false)");
        }
        return rechercheMotCle(message);
    }

    /**
     * Sous-transaction isolée : en cas d'erreur SQL (pgvector indispo), seule cette
     * transaction est rollback, pas la transaction parente.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW, noRollbackFor = Exception.class)
    public List<Fiche> rechercheVectorielle(String message) {
        float[] embedding = embeddingService.generateEmbedding(message);
        if (embedding == null || embedding.length == 0) return List.of();
        var ids = ficheRepository.rechercherIdsParSimilariteGlobale(embedding, 8);
        if (ids.isEmpty()) return List.of();
        return ficheRepository.trouverParIdsOrdonnes(ids);
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW, noRollbackFor = Exception.class)
    public List<Fiche> rechercheMotCle(String message) {
        var mots = message.toLowerCase().replaceAll("[^a-zàâçéèêëîïôûùüÿœ ]", " ").trim();
        if (mots.isBlank()) return List.of();
        try {
            var pageable = org.springframework.data.domain.PageRequest.of(0, 4);
            // 4 requêtes typées (évite le bug InheritanceType.JOINED + clazz_ avec SQL natif)
            var etablissements = ficheRepository.rechercherEtablissement(mots, pageable);
            var filieres = ficheRepository.rechercherFiliere(mots, pageable);
            var metiers = ficheRepository.rechercherMetier(mots, pageable);
            // Recherche générique sur titre/resume/contenu pour les fiches publiées
            var generiques = ficheRepository.rechercherParMotCle(mots, pageable).getContent();

            // Agrège et dédoublonne par ID
            var ids = new java.util.LinkedHashMap<Long, Fiche>();
            for (var f : etablissements) ids.putIfAbsent(f.getId(), f);
            for (var f : filieres) ids.putIfAbsent(f.getId(), f);
            for (var f : metiers) ids.putIfAbsent(f.getId(), f);
            for (var f : generiques) ids.putIfAbsent(f.getId(), f);
            return new java.util.ArrayList<>(ids.values());
        } catch (Exception e) {
            log.warn("Recherche mot-clé échouée: {}", e.getMessage());
            return List.of();
        }
    }
}

