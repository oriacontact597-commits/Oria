package tg.edtch.activEducation.shared.ai.service.impl;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import tg.edtch.activEducation.shared.ai.service.AIEmbeddingService;

import java.util.List;
import java.util.Map;

/**
 * Implémentation de AIEmbeddingService utilisant Ollama en local pour les embeddings,
 * avec délégation à OpenAI (si bean disponible) pour les autres méthodes.
 *
 * Activer avec : EMBEDDING_PROVIDER=ollama
 * Modèle par défaut : nomic-embed-text (768 dimensions, pull : ollama pull nomic-embed-text)
 */
@Service
@org.springframework.boot.autoconfigure.condition.ConditionalOnProperty(
    name = "embedding.provider",
    havingValue = "ollama"
)
@Slf4j
public class OllamaEmbeddingServiceImpl implements AIEmbeddingService {

    @Value("${ollama.api.url:http://localhost:11434}")
    private String ollamaUrl;

    @Value("${ollama.api.embedding.model:nomic-embed-text}")
    private String embeddingModel;

    // Injection optionnelle : si OpenAI n'est pas chargé, on délègue à un stub HTTP minimal.
    private final ObjectProvider<OpenAIEmbeddingServiceImpl> delegateProvider;
    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    public OllamaEmbeddingServiceImpl(ObjectProvider<OpenAIEmbeddingServiceImpl> delegateProvider) {
        this.delegateProvider = delegateProvider;
        log.info("ORIA embeddings: provider=ollama, model={}, url={}", embeddingModel, ollamaUrl);
    }

    @Override
    public float[] generateEmbedding(String text) {
        if (text == null || text.isBlank()) {
            return new float[0];
        }
        String url = ollamaUrl + "/api/embeddings";
        Map<String, Object> payload = Map.of(
            "model", embeddingModel,
            "prompt", text
        );
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        try {
            var response = restTemplate.postForEntity(url, new HttpEntity<>(payload, headers), String.class);
            JsonNode root = objectMapper.readTree(response.getBody());
            JsonNode embedding = root.path("embedding");
            if (embedding.isMissingNode() || !embedding.isArray()) {
                throw new RuntimeException("Réponse embedding invalide d'Ollama");
            }
            float[] result = new float[embedding.size()];
            for (int i = 0; i < embedding.size(); i++) {
                result[i] = (float) embedding.get(i).asDouble();
            }
            return result;
        } catch (org.springframework.web.client.ResourceAccessException e) {
            log.warn("Ollama embeddings non disponible: {}", e.getMessage());
            throw new RuntimeException("Ollama non disponible pour embeddings", e);
        } catch (Exception e) {
            log.error("Erreur génération embedding Ollama: {}", e.getMessage());
            throw new RuntimeException("Erreur embedding Ollama", e);
        }
    }

    // === Délégation aux autres méthodes (chat, vision, audio, TTS) ===
    // Utilise ObjectProvider pour éviter la dépendance circulaire quand OpenAI n'est pas chargé.

    @Override
    public String generateAnswer(String question, List<String> contextes) {
        var delegate = delegateProvider.getIfAvailable();
        if (delegate != null) return delegate.generateAnswer(question, contextes);
        return fallback("generateAnswer indisponible sans provider OpenAI");
    }

    @Override
    public String extractTextFromImage(byte[] imageData, String mimeType) {
        var delegate = delegateProvider.getIfAvailable();
        if (delegate != null) return delegate.extractTextFromImage(imageData, mimeType);
        return fallback("extractTextFromImage indisponible sans provider OpenAI");
    }

    @Override
    public String generateQuizQuestions(String context, int nombre) {
        var delegate = delegateProvider.getIfAvailable();
        if (delegate != null) return delegate.generateQuizQuestions(context, nombre);
        return fallback("generateQuizQuestions indisponible sans provider OpenAI");
    }

    @Override
    public String transcribeAudio(byte[] audioData, String filename) {
        var delegate = delegateProvider.getIfAvailable();
        if (delegate != null) return delegate.transcribeAudio(audioData, filename);
        return fallback("transcribeAudio indisponible sans provider OpenAI");
    }

    @Override
    public byte[] generateSpeech(String text) {
        var delegate = delegateProvider.getIfAvailable();
        if (delegate != null) return delegate.generateSpeech(text);
        throw new UnsupportedOperationException("generateSpeech indisponible sans provider OpenAI");
    }

    private String fallback(String msg) {
        log.warn(msg);
        return "Service IA secondaire non configuré : " + msg;
    }
}
