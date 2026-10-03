package tg.edtch.activEducation.shared.llm;

import java.util.List;
import java.util.Map;

/**
 * Réponse du LLM.
 * Le contenu textuel est ce que l'utilisateur final voit.
 * Les sources contiennent les références (établissements, fiches) que
 * le LLM a utilisées pour formuler sa réponse.
 */
public record LlmResponse(
        String content,
        String model,
        Integer promptTokens,
        Integer completionTokens,
        Long latencyMs,
        List<Map<String, String>> sources) {
}
