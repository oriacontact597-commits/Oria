package tg.edtch.activEducation.shared.llm.impl;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;
import tg.edtch.activEducation.shared.llm.LlmGateway;
import tg.edtch.activEducation.shared.llm.LlmRequest;
import tg.edtch.activEducation.shared.llm.LlmResponse;

/**
 * Routeur LLM : Groq (cloud, ~5 s) en priorité quand la clé est configurée,
 * repli sur Ollama local (CPU, ~6 min avec mistral:7b) sinon.
 *
 * <p>Sans routeur, le bean {@code @Primary} Ollama est toujours choisi et les
 * réponses ORIA dépassent le timeout de 120 s du client mobile.</p>
 */
@Component
@Primary
@RequiredArgsConstructor
@Slf4j
public class LlmGatewayRouter implements LlmGateway {

    private final GroqLlmGateway groq;
    private final OllamaLlmGateway ollama;

    @Override
    public LlmResponse complete(LlmRequest request) {
        if (groq.isAvailable()) {
            try {
                return groq.complete(request);
            } catch (Exception e) {
                log.warn("Groq échoué, repli sur Ollama: {}", e.getMessage());
            }
        }
        return ollama.complete(request);
    }

    @Override
    public boolean isAvailable() {
        return groq.isAvailable() || ollama.isAvailable();
    }
}
