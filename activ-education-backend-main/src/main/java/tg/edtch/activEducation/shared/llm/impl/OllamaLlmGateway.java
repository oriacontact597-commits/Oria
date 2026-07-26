package tg.edtch.activEducation.shared.llm.impl;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import tg.edtch.activEducation.shared.llm.LlmException;
import tg.edtch.activEducation.shared.llm.LlmGateway;
import tg.edtch.activEducation.shared.llm.LlmRequest;
import tg.edtch.activEducation.shared.llm.LlmResponse;

import java.util.List;
import java.util.Map;

/**
 * Implémentation Ollama du LlmGateway.
 * Appelle l'API HTTP locale d'Ollama (POST /api/chat).
 *
 * <p>Le modèle et l'URL sont configurables via application.properties :
 * {@code ollama.api.base-url} et {@code ollama.api.model}.</p>
 */
@Component
@Slf4j
public class OllamaLlmGateway implements LlmGateway {

    @Value("${ollama.api.base-url:http://localhost:11434}")
    private String baseUrl;

    @Value("${ollama.api.model:mistral:7b-instruct}")
    private String model;

    @Value("${ollama.api.timeout-seconds:120}")
    private int timeoutSeconds;

    private final RestTemplate restTemplate = new RestTemplate();

    @Override
    public LlmResponse complete(LlmRequest request) {
        long start = System.currentTimeMillis();

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        List<Map<String, String>> messages;
        if (!request.messages().isEmpty()) {
            messages = request.messages();
        } else {
            messages = List.of(
                    Map.of("role", "system", "content", request.systemPrompt()),
                    Map.of("role", "user", "content", request.userMessage()));
        }

        Map<String, Object> body = Map.of(
                "model", model,
                "messages", messages,
                "stream", false,
                "options", Map.of(
                        "temperature", request.temperature(),
                        "num_predict", request.maxTokens()));

        try {
            ResponseEntity<Map> response = restTemplate.postForEntity(
                    baseUrl + "/api/chat",
                    new HttpEntity<>(body, headers),
                    Map.class);

            Map<String, Object> respBody = response.getBody();
            if (respBody == null) {
                throw new LlmException("Réponse Ollama vide");
            }

            Map<String, Object> message = (Map<String, Object>) respBody.get("message");
            String content = message != null && message.get("content") != null
                    ? message.get("content").toString()
                    : "";

            long latency = System.currentTimeMillis() - start;
            log.info("OllamaLlmGateway OK model={} latencyMs={}", model, latency);

            return new LlmResponse(content, model, null, null, latency, List.of());
        } catch (Exception e) {
            log.error("OllamaLlmGateway échec model={} : {}", model, e.getMessage());
            throw new LlmException("Appel Ollama échoué : " + e.getMessage(), e);
        }
    }

    @Override
    public boolean isAvailable() {
        try {
            ResponseEntity<String> response = restTemplate.getForEntity(
                    baseUrl + "/api/tags", String.class);
            return response.getStatusCode().is2xxSuccessful();
        } catch (Exception e) {
            return false;
        }
    }
}
