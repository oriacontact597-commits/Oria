package tg.edtch.activEducation.shared.ai.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tg.edtch.activEducation.bibliotheque.domain.entite.Fiche;
import tg.edtch.activEducation.bibliotheque.repository.FicheRepository;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class VectorSyncService {

    private final FicheRepository ficheRepository;
    private final AIEmbeddingService embeddingService;

    /**
     * Parcourt toutes les fiches de la bibliothèque et génère leurs embeddings.
     * Utile après un changement de modèle d'embedding ou un import massif de données.
     *
     * @return le nombre de fiches synchronisées.
     */
    @Transactional
    public int synchroniserTousLesEmbeddings() {
        log.info("Démarrage de la synchronisation des embeddings pour toutes les fiches...");

        List<Fiche> toutesLesFiches = ficheRepository.findAll();
        int count = 0;

        for (Fiche fiche : toutesLesFiches) {
            try {
                // Construction du texte à vectoriser (Titre + Résumé + Contenu)
                String texteAVectoriser = String.format("%s %s %s",
                    fiche.getTitre() != null ? fiche.getTitre() : "",
                    fiche.getResume() != null ? fiche.getResume() : "",
                    fiche.getContenu() != null ? fiche.getContenu() : ""
                ).trim();

                if (!texteAVectoriser.isBlank()) {
                    float[] vector = embeddingService.generateEmbedding(texteAVectoriser);
                    fiche.setEmbedding(vector);
                    ficheRepository.save(fiche);
                    count++;
                }
            } catch (Exception e) {
                log.error("Erreur lors de la vectorisation de la fiche {}: {}", fiche.getTitre(), e.getMessage());
            }
        }

        log.info("Synchronisation terminée. {} fiches mises à jour.", count);
        return count;
    }
}
