package tg.edtch.activEducation.shared.llm;

import java.util.List;
import java.util.Map;

/**
 * Requête envoyée au LLM.
 * On n'envoie PAS de scores bruts : uniquement un résumé structuré
 * que le LLM doit reformuler en langage naturel.
 *
 * <p>Deux modes :</p>
 * <ul>
 *   <li>Mode simple : {@code systemPrompt + userMessage} → message unique user</li>
 *   <li>Mode conversation : {@code messages} → liste complète (system + historique + user)</li>
 * </ul>
 */
public record LlmRequest(
        String systemPrompt,
        String userMessage,
        Double temperature,
        Integer maxTokens,
        List<Map<String, String>> messages) {

    public LlmRequest {
        if (temperature == null) temperature = 0.3;
        if (maxTokens == null) maxTokens = 600;
        if (messages == null) messages = List.of();
    }

    /** Mode simple : system + message utilisateur. */
    public LlmRequest(String systemPrompt, String userMessage, Double temperature, Integer maxTokens) {
        this(systemPrompt, userMessage, temperature, maxTokens, List.of());
    }

    /** Mode conversation : liste complète de messages (system inclus). */
    public static LlmRequest fromConversation(List<Map<String, String>> messages, Double temperature, Integer maxTokens) {
        return new LlmRequest(null, null, temperature, maxTokens, messages);
    }
}
