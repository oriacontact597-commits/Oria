package tg.edtch.activEducation.evolution.engines;

import java.util.Map;

/**
 * Interface commune aux 9 moteurs de scoring.
 * Chaque moteur lit ce dont il a besoin depuis le SEP ou ses tables sources,
 * et produit un score 0-1 + une explication structurée.
 *
 * <p>Pattern : {@code Engine<TInput, TOutput>}.</p>
 */
public interface Engine<TInput, TOutput> {

    /** Nom du moteur (ex. "academic", "interest", "riasec"). */
    String name();

    /** Évalue le moteur pour un élève. */
    TOutput evaluate(TInput input);

    /**
     * Sortie standard d'un moteur.
     *
     * @param score       score 0-1
     * @param explanation explication structurée
     * @param details     détails techniques
     */
    record Output(
            double score,
            String explanation,
            Map<String, Object> details) {
    }
}
