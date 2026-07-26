package tg.edtch.activEducation.shared.llm;

/**
 * Abstraction LLM multi-fournisseur.
 *
 * <p>Le LLM ne décide RIEN. Il reformule des résumés structurés
 * (calculés par le backend) en langage naturel pédagogique.</p>
 *
 * <p>Implémentations :</p>
 * <ul>
 *   <li>{@link impl.OllamaLlmGateway} — Ollama local (défaut)</li>
 *   <li>{@code OpenAiLlmGateway} — cloud (à venir)</li>
 *   <li>{@code GroqLlmGateway} — cloud (à venir)</li>
 * </ul>
 */
public interface LlmGateway {

    /**
     * Envoie une requête au LLM et retourne la réponse.
     *
     * @param request message + system prompt
     * @return réponse textuelle
     * @throws LlmException si le LLM est indisponible ou échoue
     */
    LlmResponse complete(LlmRequest request);

    /**
     * Indique si le provider est disponible.
     */
    boolean isAvailable();
}
