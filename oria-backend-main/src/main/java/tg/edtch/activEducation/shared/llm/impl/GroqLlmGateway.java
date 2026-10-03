package tg.edtch.activEducation.shared.llm.impl;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import tg.edtch.activEducation.shared.llm.LlmException;
import tg.edtch.activEducation.shared.llm.LlmGateway;
import tg.edtch.activEducation.shared.llm.LlmRequest;
import tg.edtch.activEducation.shared.llm.LlmResponse;

import java.time.Duration;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Groq LlmGateway (OpenAI-compatible API).
 *
 * <p>Active quand groq.api.key est renseigné. Modèle par défaut :
 * openai/gpt-oss-120b.</p>
 */
@Component
@Slf4j
public class GroqLlmGateway implements LlmGateway {

    @Value("${groq.api.key:}")
    private String apiKey;

    @Value("${groq.api.model:openai/gpt-oss-120b}")
    private String model;

    /** Groq free = 8000 tokens/min : system + 7 derniers messages max par requête. */
    private static final int HISTORIQUE_MAX = 8;

    /** Timeouts + tentatives avec backoff 429 : des erreurs I/O intermittentes (wifi)
     *  ou le quota tokens/min ne doivent pas basculer sur Ollama local (~300 s). */
    private final RestTemplate restTemplate = createRestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    private static RestTemplate createRestTemplate() {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(5));
        factory.setReadTimeout(Duration.ofSeconds(45));
        return new RestTemplate(factory);
    }

    @Override
    public LlmResponse complete(LlmRequest request) {
        if (apiKey == null || apiKey.isBlank()) {
            throw new LlmException("GROQ_API_KEY non configurée");
        }

        long start = System.currentTimeMillis();

        List<Map<String, String>> messages = new ArrayList<>();
        if (request.messages() != null && !request.messages().isEmpty()) {
            messages.addAll(request.messages());
        } else {
            messages.add(Map.of("role", "system", "content", request.systemPrompt()));
            messages.add(Map.of("role", "user", "content", request.userMessage()));
        }

        if (messages.size() > HISTORIQUE_MAX) {
            List<Map<String, String>> reduit = new ArrayList<>(HISTORIQUE_MAX);
            reduit.add(messages.get(0));
            reduit.addAll(messages.subList(messages.size() - (HISTORIQUE_MAX - 1), messages.size()));
            messages.clear();
            messages.addAll(reduit);
        }

        Map<String, Object> payload = new HashMap<>();
        payload.put("model", model);
        payload.put("messages", messages);
        payload.put("temperature", request.temperature());
        payload.put("max_tokens", request.maxTokens());

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);

        Exception dernierEchec = null;
        for (int tentative = 1; tentative <= 3; tentative++) {
            try {
                ResponseEntity<String> response = restTemplate.postForEntity(
                        "https://api.groq.com/openai/v1/chat/completions",
                        new HttpEntity<>(payload, headers),
                        String.class);

                JsonNode root = objectMapper.readTree(response.getBody());
                JsonNode content = root.path("choices").path(0).path("message").path("content");
                if (content.isMissingNode() || content.asText().isBlank()) {
                    throw new LlmException("Réponse Groq vide");
                }

                long promptTokens = root.path("usage").path("prompt_tokens").asLong(0);
                long completionTokens = root.path("usage").path("completion_tokens").asLong(0);
                long latency = System.currentTimeMillis() - start;
                log.info("GroqLlmGateway OK model={} latencyMs={} tentative={} promptTokens={} completionTokens={}",
                        model, latency, tentative, promptTokens, completionTokens);
                return new LlmResponse(content.asText(), model, null, null, latency, List.of());
            } catch (Exception e) {
                dernierEchec = e;
                String msg = e.getMessage() == null ? "" : e.getMessage();
                boolean rateLimit = msg.contains("429") || msg.toLowerCase().contains("rate limit");
                log.warn("GroqLlmGateway tentative {}/3 échouée (rateLimit={}): {}", tentative, rateLimit, msg);
                if (tentative < 3) {
                    // 429 = quota tokens/min (8000 TPM en free) : Groq demande ~11 s d'attente.
                    long pause = rateLimit ? 11_000 : 700;
                    try {
                        Thread.sleep(pause);
                    } catch (InterruptedException ie) {
                        Thread.currentThread().interrupt();
                        break;
                    }
                }
            }
        }
        log.error("GroqLlmGateway échec après 3 tentatives: {}", dernierEchec.getMessage());
        throw new LlmException("Appel Groq échoué : " + dernierEchec.getMessage(), dernierEchec);
    }

    @Override
    public boolean isAvailable() {
        return apiKey != null && !apiKey.isBlank();
    }
}
