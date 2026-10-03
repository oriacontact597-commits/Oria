package tg.edtch.activEducation.shared.ai.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import tg.edtch.activEducation.bibliotheque.domain.entite.Fiche;
import tg.edtch.activEducation.bibliotheque.repository.FicheRepository;

import java.util.Arrays;
import java.util.List;
import java.util.Set;

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

    private static final Set<String> MOTS_VIDES = Set.of(
            "a", "au", "aux", "avec", "ce", "cette", "ces", "dans", "de", "des", "du",
            "en", "et", "est", "faire", "faut", "il", "la", "le", "les", "lui", "mais",
            "mon", "où", "par", "pour", "que", "quel", "quelle", "quelles", "qui", "sont",
            "sur", "un", "une", "vers", "bonjour", "oria", "étude", "études");

    private final AIEmbeddingService embeddingService;
    private final FicheRepository ficheRepository;

    /**
     * Proxy de soi-même : un appel interne (this.rechercheXxx()) contourne l'intercepteur
     * Spring, @Transactional(REQUIRES_NEW) ne s'appliquerait pas, et l'échec pgvector
     * aborterait la transaction parente de OriaService (chat ORIA en 500).
     */
    @Autowired
    @Lazy
    private OriaRechercheContexteService self;

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
                List<Fiche> result = self.rechercheVectorielle(message);
                if (!result.isEmpty()) return result;
            } catch (Exception e) {
                log.warn("RAG vectoriel indisponible, fallback mot-clé: {}", e.getMessage());
            }
        } else {
            log.debug("RAG vectoriel désactivé (oria.rag.vectoriel=false)");
        }
        return self.rechercheMotCle(message);
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
            var termes = Arrays.stream(mots.split("\\s+"))
                    .filter(mot -> mot.length() >= 3)
                    .filter(mot -> !MOTS_VIDES.contains(mot))
                    .distinct()
                    .limit(8)
                    .toList();
            if (termes.isEmpty()) return List.of();

            // Chaque requête typed ne sait chercher qu'un terme à la fois.
            // On agrège les mots significatifs pour gérer les questions naturelles.
            var resultats = new java.util.LinkedHashMap<Long, Fiche>();
            for (var terme : termes) {
                var etablissements = ficheRepository.rechercherEtablissement(terme, pageable);
                var filieres = ficheRepository.rechercherFiliere(terme, pageable);
                var metiers = ficheRepository.rechercherMetier(terme, pageable);
                var generiques = ficheRepository.rechercherParMotCle(terme, pageable).getContent();

                for (var f : etablissements) resultats.putIfAbsent(f.getId(), f);
                for (var f : filieres) resultats.putIfAbsent(f.getId(), f);
                for (var f : metiers) resultats.putIfAbsent(f.getId(), f);
                for (var f : generiques) resultats.putIfAbsent(f.getId(), f);
            }
            // Groq free = 8000 tokens/min : on plafonne le contexte injecté au LLM.
            var limite = filtrerParPays(message, new java.util.ArrayList<>(resultats.values()));
            if (limite.size() > 12) {
                limite = new java.util.ArrayList<>(limite.subList(0, 12));
            }
            return limite;
        } catch (Exception e) {
            log.warn("Recherche mot-clé échouée: {}", e.getMessage());
            return List.of();
        }
    }

    /** Le catalogue couvre TG/BJ/CI : si la question nomme un pays, on écarte les
     *  établissements des autres pays (sinon « universités au Togo » cite le Bénin). */
    private List<Fiche> filtrerParPays(String message, List<Fiche> fiches) {
        String msg = java.text.Normalizer.normalize(message.toLowerCase(), java.text.Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "");
        String pays = null;
        if (msg.contains("benin")) {
            pays = "BJ";
        } else if (msg.contains("ivoire")) {
            pays = "CI";
        } else if (msg.contains("togo")) {
            pays = "TG";
        }
        if (pays == null) {
            return fiches;
        }
        final String codePays = pays;
        fiches.removeIf(f -> f instanceof tg.edtch.activEducation.bibliotheque.domain.entite.FicheEtablissement fe
                && fe.getCountryCode() != null
                && !fe.getCountryCode().equalsIgnoreCase(codePays));
        return fiches;
    }
}
