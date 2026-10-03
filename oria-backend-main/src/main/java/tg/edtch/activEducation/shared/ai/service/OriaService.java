package tg.edtch.activEducation.shared.ai.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;
import tg.edtch.activEducation.bibliotheque.domain.entite.Fiche;
import tg.edtch.activEducation.bibliotheque.repository.FicheRepository;
import tg.edtch.activEducation.shared.ai.domain.dto.OriaRequest;
import tg.edtch.activEducation.shared.ai.domain.dto.OriaResponse;
import tg.edtch.activEducation.shared.ai.domain.dto.OriaResponse.MessageDto;
import tg.edtch.activEducation.shared.ai.domain.entite.OriaMessage;
import tg.edtch.activEducation.shared.ai.domain.entite.ProfilOrientation;
import tg.edtch.activEducation.shared.ai.repository.OriaMessageRepository;
import tg.edtch.activEducation.shared.ai.repository.ProfilOrientationRepository;
import tg.edtch.activEducation.shared.llm.LlmGateway;
import tg.edtch.activEducation.shared.llm.LlmRequest;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import static java.util.Locale.ROOT;

@Service
@RequiredArgsConstructor
@Slf4j
public class OriaService {

    private final LlmGateway llmGateway;

    @Value("${openai.api.key:}")
    private String openaiApiKey;

    @Value("${openai.api.chat.model:gpt-4o-mini}")
    private String chatModel;

    @Value("${groq.api.key:}")
    private String groqApiKey;

    @Value("${groq.api.model:openai/gpt-oss-120b}")
    private String groqModel;

    private final OriaMessageRepository messageRepository;
    private final ProfilOrientationRepository profilOrientationRepository;
    private final AIEmbeddingService aiEmbeddingService;
    private final FicheRepository ficheRepository;
    private final OriaRechercheContexteService rechercheService;
    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    private static final int MAX_MESSAGES_IN_MEMORY = 50;
    private static final int PROFIL_UPDATE_INTERVAL = 5;

    private final ConcurrentHashMap<String, OriaSession> sessions = new ConcurrentHashMap<>();

    private static final Pattern INJECTION_PATTERN = Pattern.compile(
        "(?i)(ignore\\s+(all\\s+)?(previous|above|below)|forget\\s+(all\\s+)?(instructions|context)|" +
        "system\\s+(prompt|message|instruction)|you\\s+are\\s+(now|not\\s+really)|" +
        "act\\s+as\\s+(if|though)|pretend\\s+(to\\s+)?be|bypass|jailbreak)",
        Pattern.CASE_INSENSITIVE
    );

    private static final Set<String> BLOCKED_WORDS = Set.of(
        "hack", "pirate", "exploit", "vuln", "malware", "virus", "phish"
    );

    @Transactional
    public OriaResponse sendMessage(OriaRequest request, String userId) {
        String message = request.getMessage().trim();

        String validationError = validateMessage(message);
        if (validationError != null) {
            return buildErrorResponse(validationError);
        }

        String sessionId = resolveSessionId(request, userId);
        OriaSession session = getOrCreateSession(sessionId, request.getContexteOrientation());

        session.messages.add(new ChatMessage("user", message, Instant.now()));
        if (session.messages.size() > MAX_MESSAGES_IN_MEMORY) {
            session.messages.remove(0);
        }

        try {
            var contexte = rechercherContexte(message);
            String response = callLLM(session, contexte);
            session.messages.add(new ChatMessage("assistant", response, Instant.now()));
            if (session.messages.size() > MAX_MESSAGES_IN_MEMORY) {
                session.messages.remove(0);
            }

            List<MessageDto> historique = session.messages.stream()
                .map(m -> new MessageDto(m.role, m.contenu, m.timestamp))
                .collect(Collectors.toList());

            return new OriaResponse(response, sessionId, historique);
        } catch (Exception e) {
            log.error("Erreur ORIA: {}", e.getMessage());
            session.messages.remove(session.messages.size() - 1);
            List<MessageDto> historique = session.messages.stream()
                .map(m -> new MessageDto(m.role, m.contenu, m.timestamp))
                .collect(Collectors.toList());

            String userMessage = "Désolé, je rencontre une difficulté technique. Veuillez réessayer dans quelques instants.";
            if (e.getMessage() != null && (e.getMessage().contains("Erreur Groq") || e.getMessage().contains("Erreur OpenAI") || e.getMessage().contains("Aucun provider"))) {
                userMessage = e.getMessage();
            }

            return new OriaResponse(
                userMessage,
                sessionId, historique
            );
        }
    }

    @Transactional
    public OriaResponse sendMessageAndPersist(OriaRequest request, String userId) {
        String message = request.getMessage().trim();

        String validationError = validateMessage(message);
        if (validationError != null) {
            return buildErrorResponse(validationError);
        }

        String sessionId = resolveSessionId(request, userId);
        OriaSession session = getOrCreateSession(sessionId, request.getContexteOrientation());

        var now = Instant.now();
        session.messages.add(new ChatMessage("user", message, now));
        saveMessage(sessionId, "user", message, now, userId);
        updateProfilOrientation(userId, message);
        if (session.messages.size() > MAX_MESSAGES_IN_MEMORY) {
            session.messages.remove(0);
        }

        try {
            var contexte = rechercherContexte(message);
            String resume = profilOrientationRepository.findByUserId(userId)
                    .map(this::resumeEf)
                    .filter(s -> !s.isBlank())
                    .orElse(null);
            String response = callLLM(session, contexte, resume);

            var responseTime = Instant.now();
            session.messages.add(new ChatMessage("assistant", response, responseTime));
            saveMessage(sessionId, "assistant", response, responseTime, userId);
            if (session.messages.size() > MAX_MESSAGES_IN_MEMORY) {
                session.messages.remove(0);
            }

            List<MessageDto> historique = session.messages.stream()
                .map(m -> new MessageDto(m.role, m.contenu, m.timestamp))
                .collect(Collectors.toList());

            return new OriaResponse(response, sessionId, historique);
        } catch (Exception e) {
            log.error("Erreur ORIA: {}", e.getMessage());
            session.messages.remove(session.messages.size() - 1);
            List<MessageDto> historique = session.messages.stream()
                .map(m -> new MessageDto(m.role, m.contenu, m.timestamp))
                .collect(Collectors.toList());

            String userMessage = "Désolé, je rencontre une difficulté technique. Veuillez réessayer dans quelques instants.";
            if (e.getMessage() != null && (e.getMessage().contains("Erreur Groq") || e.getMessage().contains("Erreur OpenAI") || e.getMessage().contains("Aucun provider"))) {
                userMessage = e.getMessage();
            }

            return new OriaResponse(
                userMessage,
                sessionId, historique
            );
        }
    }

    private void saveMessage(String sessionId, String role, String contenu, Instant timestamp, String userId) {
        var msg = OriaMessage.builder()
            .sessionId(sessionId)
            .role(role)
            .contenu(contenu)
            .messageTimestamp(timestamp)
            .userId(userId)
            .build();
        messageRepository.save(msg);
    }

    private static final Set<String> DOMAIN_KEYWORDS = Set.of(
        "informatique", "mathématiques", "physique", "génie civil", "génie électrique",
        "médecine", "pharmacie", "biologie", "santé",
        "droit", "lettres", "communication", "psychologie",
        "gestion", "économie", "commerce", "comptabilité",
        "architecture", "design", "arts", "sport", "éducation",
        "agriculture", "environnement", "tourisme", "hôtellerie"
    );

    /** Mémoire de suivi injectée dans le prompt : reprend resume_parcours s'il est
     *  renseigné, sinon recompose depuis les domaines d'intérêt relevés au fil des
     *  conversations (updateProfilOrientation). */
    private String resumeEf(ProfilOrientation p) {
        if (p.getResumeParcours() != null && !p.getResumeParcours().isBlank()) {
            return p.getResumeParcours();
        }
        StringBuilder sb = new StringBuilder();
        if (p.getPremiereAmbition() != null && !p.getPremiereAmbition().isBlank()) {
            sb.append("Première ambition évoquée : ").append(p.getPremiereAmbition()).append(". ");
        }
        if (p.getDomainesInteret() != null && !p.getDomainesInteret().isBlank()) {
            sb.append("Domaines d'intérêt relevés au fil des échanges : ").append(p.getDomainesInteret()).append(". ");
        }
        if (p.getDernierDomaine() != null && !p.getDernierDomaine().isBlank()) {
            sb.append("Dernier domaine mentionné : ").append(p.getDernierDomaine()).append(".");
        }
        return sb.toString().trim();
    }

    private void updateProfilOrientation(String userId, String message) {
        try {
            String lower = message.toLowerCase(ROOT);
            Set<String> mentions = new HashSet<>();
            for (String kw : DOMAIN_KEYWORDS) {
                if (lower.contains(kw)) {
                    mentions.add(kw);
                }
            }
            if (mentions.isEmpty()) return;

            var opt = profilOrientationRepository.findByUserId(userId);
            ProfilOrientation profil = opt.orElseGet(() -> {
                var p = ProfilOrientation.builder()
                    .userId(userId)
                    .ambitions("")
                    .domainesInteret("")
                    .resumeParcours("")
                    .dernierDomaine("")
                    .premiereAmbition("")
                    .build();
                return profilOrientationRepository.save(p);
            });

            String nouveau = String.join(", ", mentions);
            if (profil.getPremiereAmbition() == null || profil.getPremiereAmbition().isBlank()) {
                profil.setPremiereAmbition(nouveau);
            }
            Set<String> existants = new HashSet<>();
            if (profil.getDomainesInteret() != null) {
                String[] parts = profil.getDomainesInteret().split(",\\s*");
                Collections.addAll(existants, parts);
            }
            existants.addAll(mentions);
            profil.setDomainesInteret(String.join(", ", existants));
            profil.setDernierDomaine(nouveau);
            profilOrientationRepository.save(profil);
        } catch (Exception e) {
            log.warn("Erreur mise à jour ProfilOrientation: {}", e.getMessage());
        }
    }

    @Transactional(readOnly = true)
    public OriaResponse getSessionHistory(String sessionId) {
        var messages = messageRepository.findBySessionIdOrderByMessageTimestampAsc(sessionId);
        var dtoList = messages.stream()
            .map(m -> new MessageDto(m.getRole(), m.getContenu(), m.getMessageTimestamp()))
            .collect(Collectors.toList());
        return new OriaResponse(null, sessionId, dtoList);
    }

    private String validateMessage(String message) {
        if (message.length() > 2000) {
            return "Votre message est trop long (2000 caractères maximum).";
        }
        if (INJECTION_PATTERN.matcher(message).find()) {
            return "Je suis un assistant d'orientation éducative. " +
                   "Posez-moi des questions sur les parcours, métiers, études ou formations.";
        }
        for (String word : BLOCKED_WORDS) {
            if (message.toLowerCase().contains(word)) {
                return "Je ne peux pas vous aider avec cette requête. " +
                       "Posez-moi des questions sur l'orientation scolaire.";
            }
        }
        return null;
    }

    private String resolveSessionId(OriaRequest request, String userId) {
        return "conv-" + userId;
    }

    private OriaSession getOrCreateSession(String sessionId, String contexte) {
        return sessions.computeIfAbsent(sessionId, k -> new OriaSession(contexte));
    }

    private String callLLM(OriaSession session, String contexteRecherche) {
        return callLLM(session, contexteRecherche, null);
    }

    private String callLLM(OriaSession session, String contexteRecherche, String resumeParcours) {
        if (llmGateway.isAvailable()) {
            try {
                List<Map<String, String>> messages = new ArrayList<>();
                var systemContent = buildSystemPrompt(session.contexteOrientation, resumeParcours);
                if (contexteRecherche != null) systemContent += contexteRecherche;
                messages.add(Map.of("role", "system", "content", systemContent));
                for (ChatMessage msg : session.messages) {
                    messages.add(Map.of("role", msg.role, "content", msg.contenu));
                }
                LlmRequest request = LlmRequest.fromConversation(messages, 0.2, 800);
                return llmGateway.complete(request).content();
            } catch (Exception e) {
                log.warn("LlmGateway prioritaire a échoué, fallback OpenAI/Groq: {}", e.getMessage());
                // Si le bean LlmGateway principal (Groq/Ollama) plante, on tente OpenAI puis Groq en bas
                if (openaiApiKey != null && !openaiApiKey.isBlank()) {
                    try { return callOpenAI(session, contexteRecherche, resumeParcours); }
                    catch (Exception ex) { log.warn("OpenAI a échoué, fallback: {}", ex.getMessage()); }
                }
                if (groqApiKey != null && !groqApiKey.isBlank()) {
                    return callGroq(session, contexteRecherche, resumeParcours);
                }
            }
        }
        if (openaiApiKey != null && !openaiApiKey.isBlank()) {
            try {
                return callOpenAI(session, contexteRecherche, resumeParcours);
            } catch (Exception e) {
                log.warn("OpenAI a échoué, fallback: {}", e.getMessage());
            }
        }
        if (groqApiKey != null && !groqApiKey.isBlank()) {
            return callGroq(session, contexteRecherche, resumeParcours);
        }
        throw new RuntimeException("Aucun provider LLM disponible");
    }

    private String callGroq(OriaSession session, String contexteRecherche) {
        return callGroq(session, contexteRecherche, null);
    }

    private String callGroq(OriaSession session, String contexteRecherche, String resumeParcours) {
        String url = "https://api.groq.com/openai/v1/chat/completions";

        List<Map<String, String>> messages = new ArrayList<>();
        var systemContent = buildSystemPrompt(session.contexteOrientation, resumeParcours);
        if (contexteRecherche != null) systemContent += contexteRecherche;
        messages.add(Map.of("role", "system", "content", systemContent));
        for (ChatMessage msg : session.messages) {
            messages.add(Map.of("role", msg.role, "content", msg.contenu));
        }

        Map<String, Object> payload = new HashMap<>();
        payload.put("model", groqModel);
        payload.put("messages", messages);
        payload.put("temperature", 0.2);
        payload.put("max_tokens", 800);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(groqApiKey);
        HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(payload, headers);

        try {
            var response = restTemplate.postForEntity(url, requestEntity, String.class);
            JsonNode root = objectMapper.readTree(response.getBody());
            JsonNode textNode = root.path("choices").get(0).path("message").path("content");

            if (textNode.isMissingNode()) {
                throw new RuntimeException("Réponse vide de Groq");
            }
            return textNode.asText();
        } catch (org.springframework.web.client.HttpClientErrorException e) {
            log.error("Erreur HTTP Groq: {} - {}", e.getStatusCode(), e.getMessage());
            throw new RuntimeException("Erreur Groq: " + e.getStatusCode());
        } catch (Exception e) {
            log.error("Erreur parsing réponse Groq: {}", e.getMessage());
            throw new RuntimeException("Erreur parsing Groq");
        }
    }

    private String callOpenAI(OriaSession session, String contexteRecherche) {
        return callOpenAI(session, contexteRecherche, null);
    }

    private String callOpenAI(OriaSession session, String contexteRecherche, String resumeParcours) {
        String url = "https://api.openai.com/v1/chat/completions";

        List<Map<String, String>> messages = new ArrayList<>();
        var systemContent = buildSystemPrompt(session.contexteOrientation, resumeParcours);
        if (contexteRecherche != null) systemContent += contexteRecherche;
        messages.add(Map.of("role", "system", "content", systemContent));
        for (ChatMessage msg : session.messages) {
            messages.add(Map.of("role", msg.role, "content", msg.contenu));
        }

        Map<String, Object> payload = new HashMap<>();
        payload.put("model", chatModel);
        payload.put("messages", messages);
        payload.put("temperature", 0.2);
        payload.put("max_tokens", 800);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(openaiApiKey);
        HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(payload, headers);

        try {
            var response = restTemplate.postForEntity(url, requestEntity, String.class);
            JsonNode root = objectMapper.readTree(response.getBody());
            JsonNode textNode = root.path("choices").get(0).path("message").path("content");

            if (textNode.isMissingNode()) {
                throw new RuntimeException("Réponse vide d'OpenAI");
            }
            return textNode.asText();
        } catch (org.springframework.web.client.HttpClientErrorException e) {
            log.error("Erreur HTTP OpenAI: {} - {}", e.getStatusCode(), e.getMessage());
            throw new RuntimeException("Erreur OpenAI: " + e.getStatusCode());
        } catch (Exception e) {
            log.error("Erreur parsing réponse OpenAI: {}", e.getMessage());
            throw new RuntimeException("Erreur parsing OpenAI");
        }
    }

    private String rechercherContexte(String message) {
        var fiches = rechercheService.rechercher(message);
        if (fiches == null || fiches.isEmpty()) return null;
        return formaterContexte(fiches);
    }

    private String formaterContexte(List<Fiche> fiches) {
        var ctx = new StringBuilder();
        ctx.append("\n\n=== DONNÉES EXTRAITES DE LA BASE (filtre ces informations avant d'inventer) ===\n");
        // Regrouper par type pour faciliter la lecture par le LLM
        var etablissements = new java.util.ArrayList<String>();
        var filieres = new java.util.ArrayList<String>();
        var metiers = new java.util.ArrayList<String>();
        var series = new java.util.ArrayList<String>();
        var autres = new java.util.ArrayList<String>();

        for (var fiche : fiches) {
            if (fiche instanceof tg.edtch.activEducation.bibliotheque.domain.entite.FicheEtablissement e) {
                etablissements.add(formaterEtablissement(e));
            } else if (fiche instanceof tg.edtch.activEducation.bibliotheque.domain.entite.FicheFiliere fi) {
                filieres.add(formaterFiliere(fi));
            } else if (fiche instanceof tg.edtch.activEducation.bibliotheque.domain.entite.FicheMetier m) {
                metiers.add(formaterMetier(m));
            } else if (fiche instanceof tg.edtch.activEducation.bibliotheque.domain.entite.FicheSerie s) {
                series.add(formaterSerie(s));
            } else {
                autres.add("- " + fiche.getTitre() + (fiche.getResume() != null ? " | " + abreger(fiche.getResume(), 150) : ""));
            }
        }

        if (!etablissements.isEmpty()) {
            ctx.append("\n[ÉTABLISSEMENTS PERTINENTS — résultats ").append(etablissements.size()).append("]\n");
            etablissements.forEach(e -> ctx.append(e).append("\n"));
        }
        if (!filieres.isEmpty()) {
            ctx.append("\n[FILIÈRES PERTINENTES — résultats ").append(filieres.size()).append("]\n");
            filieres.forEach(f -> ctx.append(f).append("\n"));
        }
        if (!metiers.isEmpty()) {
            ctx.append("\n[MÉTIERS PERTINENTS — résultats ").append(metiers.size()).append("]\n");
            metiers.forEach(m -> ctx.append(m).append("\n"));
        }
        if (!series.isEmpty()) {
            ctx.append("\n[SÉRIES SCOLAIRES PERTINENTES — résultats ").append(series.size()).append("]\n");
            series.forEach(s -> ctx.append(s).append("\n"));
        }
        if (!autres.isEmpty()) {
            ctx.append("\n[AUTRES FICHES]\n");
            autres.forEach(o -> ctx.append(o).append("\n"));
        }
        ctx.append("\n=== FIN DES DONNÉES ===\n");
        return ctx.toString();
    }

    private String formaterEtablissement(tg.edtch.activEducation.bibliotheque.domain.entite.FicheEtablissement e) {
        var sb = new StringBuilder("• ").append(safe(e.getTitre()));
        if (e.getVille() != null) sb.append(" — ").append(e.getVille());
        if (e.getTypeEtablissement() != null) sb.append(" (").append(e.getTypeEtablissement()).append(")");
        if (e.getNiveau() != null) sb.append(" — Niveau: ").append(e.getNiveau());
        if (e.getSiteWeb() != null) sb.append(" — Site: ").append(e.getSiteWeb());
        if (e.getContacts() != null) sb.append(" — Contact: ").append(e.getContacts());
        if (e.getAdresse() != null) sb.append(" — Adresse: ").append(abreger(e.getAdresse(), 120));
        return sb.toString();
    }

    private String formaterFiliere(tg.edtch.activEducation.bibliotheque.domain.entite.FicheFiliere fi) {
        var sb = new StringBuilder("• ").append(safe(fi.getTitre()));
        if (fi.getDuree() != null) sb.append(" — Durée: ").append(fi.getDuree());
        if (fi.getNiveauRequis() != null) sb.append(" — Niveau requis: ").append(fi.getNiveauRequis());
        if (fi.getResume() != null) sb.append("\n   Description: ").append(abreger(fi.getResume(), 200));
        return sb.toString();
    }

    private String formaterMetier(tg.edtch.activEducation.bibliotheque.domain.entite.FicheMetier m) {
        var sb = new StringBuilder("• ").append(safe(m.getTitre()));
        if (m.getSecteur() != null) sb.append(" — Secteur: ").append(m.getSecteur());
        if (m.getResume() != null) sb.append("\n   Description: ").append(abreger(m.getResume(), 200));
        if (m.getCompetences() != null) sb.append("\n   Compétences: ").append(abreger(m.getCompetences(), 150));
        return sb.toString();
    }

    private String formaterSerie(tg.edtch.activEducation.bibliotheque.domain.entite.FicheSerie s) {
        var sb = new StringBuilder("• ").append(safe(s.getTitre()));
        if (s.getResume() != null) sb.append(" — ").append(abreger(s.getResume(), 150));
        return sb.toString();
    }

    private String safe(String s) {
        return s == null ? "" : s;
    }

    private String abreger(String texte, int max) {
        if (texte == null) return null;
        return texte.length() <= max ? texte : texte.substring(0, max) + "...";
    }

    private String buildSystemPrompt(String contexteOrientation) {
        return buildSystemPrompt(contexteOrientation, null);
    }

    private String buildSystemPrompt(String contexteOrientation, String resumeParcours) {
        StringBuilder prompt = new StringBuilder();
        prompt.append("# ORIA — Mentor scolaire et universitaire (Togo)\n\n")
              .append("## Rôle\n")
              .append("Tu es ORIA, mentor et conseiller d'orientation pour les élèves et étudiants togolais (collège → université, concours, stages, premiers emplois, études à l'étranger). ")
              .append("Tu réponds à TOUTE question du cadre scolaire et universitaire : matières, méthodes de travail, examens et concours (BEPC, BAC, concours d'entrée), choix de série et de filière, établissements, métiers, bourses, inscriptions, vie étudiante, motivation, gestion du stress. ")
              .append("Tu es un mentor dans la durée : tu donnes des conseils pratiques et des étapes concrètes, tu suis ce que l'élève te confie (niveau, série, ambitions, difficultés) et tu le relances par une question de suivi quand cela l'aide.\n\n")
              .append("## RÈGLES ABSOLUES (PRIORITÉ MAXIMALE — AUCUNE EXCEPTION)\n\n")
              .append("### 1. RÈGLE D'OR : CITATION STRICTE DEPUIS LA BASE\n")
              .append("Quand des fiches te sont fournies entre les balises « === DONNÉES EXTRAITES DE LA BASE » et « === FIN DES DONNÉES === » :\n")
              .append("- Tu ne peux citer QUE les noms qui apparaissent LITTÉRALEMENT dans la liste fournie.\n")
              .append("- Tu n'as PAS le droit d'ajouter un nom de mémoire, même si tu crois le connaître.\n")
              .append("- Si la liste contient 3 fiches, tu cites ces 3 fiches. Tu n'en ajoutes pas une 4e que tu « connais » par ailleurs.\n")
              .append("- Si la liste est vide ou ne couvre pas la question, tu ne cites AUCUN nom d'établissement, de filière ou de métier précis : tu réponds quand même avec tes conseils généraux et tu invites l'élève à explorer le catalogue ou à reformuler avec des mots-clés plus précis (ex. « université », « médecine », « informatique »).\n\n")
              .append("### 2. INTERDICTIONS EXPLICITES\n")
              .append("- INTERDIT d'inventer un nom d'université, d'école, de filière ou de métier.\n")
              .append("- INTERDIT d'inventer un site web, un contact, une ville, un chiffre.\n")
              .append("- INTERDIT de confondre un établissement d'un autre pays avec un établissement togolais (ex. « Université du Bénin » n'est PAS togolaise).\n")
              .append("- INTERDIT de compléter une liste de fiches par des noms qui n'y figurent pas.\n")
              .append("- SÉRIES DU BACCALAURÉAT TOGOLAIS UNIQUEMENT — utilise TOUJOURS le nom de série togolais (A4, C, D, E, F, G, S, T), JAMAIS « SVT » seul, JAMAIS « L », « ES », « S (français) ». Si l'élève veut faire médecine/santé au Togo → série D. Si maths/physique/ingénieur → série C ou E ou F. Si commerce/gestion → série G. Si lettres/langues → série A4.\n\n")
              .append("### 3. RÉPONDRE À TOUTE QUESTION SCOLAIRE OU UNIVERSITAIRE\n")
              .append("- Tu ne refuses JAMAIS une question liée aux études, à l'orientation, à la vie scolaire ou universitaire, même quand la base ne contient rien sur le sujet.\n")
              .append("- Sans fiche pertinente, tu réponds avec tes connaissances générales ; signale simplement que les dates, frais, tarifs et conditions évoluent et se vérifient auprès de l'établissement ou du site officiel.\n")
              .append("- Le refus « je n'ai pas d'information sur ce sujet » est INTERDIT. Au pire, aide l'élève à préciser sa question ou à chercher dans le catalogue.\n\n")
              .append("### 4. MENTORAT ET SUIVI\n")
              .append("- Première phrase = réponse directe, puis 1 à 3 conseils concrets et actionnables.\n")
              .append("- Termine quand c'est utile par UNE question de suivi ou une prochaine étape proposée (ex. « Quelle série suis-tu actuellement ? », « On peut préparer un plan de révision si tu veux »).\n")
              .append("- Personnalise tes réponses avec le contexte de l'élève et son résumé de parcours (fournis plus bas) : montre que tu retiens ce qu'il te dit d'une conversation à l'autre.\n")
              .append("- Si l'élève exprime un doute ou un découragement, encourage-le d'abord, puis donne le conseil.\n\n")
              .append("### 5. FORMAT DE RÉPONSE STRICT\n")
              .append("- Pour une question sur les ÉTABLISSEMENTS : liste à puces Markdown au format : « - Nom — Ville (Type) — Site: URL ».\n")
              .append("- Pour une FILIÈRE : « - Nom — Durée — Niveau requis ».\n")
              .append("- Pour un MÉTIER : « - Nom — Secteur ».\n")
              .append("- N'utilise JAMAIS le caractère « • » dans tes réponses (l'application affiche déjà la puce elle-même) : utilise uniquement le marqueur de liste Markdown « - » en début de ligne.\n")
              .append("- Maximum 8 résultats, dans l'ordre où ils apparaissent dans la base.\n\n")
              .append("### 6. STYLE\n")
              .append("- Français uniquement. Première phrase = réponse directe. Pas de pavés.\n")
              .append("- Pas de politesses inutiles (« Bien sûr ! », « Avec plaisir ! »).\n")
              .append("- Tutoiement, ton bienveillant et direct, comme un mentor.\n\n")
              .append("### 7. VIE PRIVÉE\n")
              .append("- Tu ne refuses JAMAIS un nom d'établissement public (information publique).\n\n")
              .append("## Limites\n")
              .append("- Questions sans rapport avec les études ou l'orientation (recettes, jeux, célébrités...) : redirige poliment vers ton rôle de mentor scolaire.\n\n");

        if (contexteOrientation != null && !contexteOrientation.isBlank()) {
            prompt.append("## Contexte de l'élève\n").append(contexteOrientation).append("\n");
        }
        if (resumeParcours != null && !resumeParcours.isBlank()) {
            prompt.append("## Résumé du parcours de l'élève\n").append(resumeParcours).append("\n");
        }
        return prompt.toString();
    }

    private OriaResponse buildErrorResponse(String errorMessage) {
        return new OriaResponse(errorMessage, null, List.of());
    }

    private static class OriaSession {
        final List<ChatMessage> messages = Collections.synchronizedList(new ArrayList<>());
        final String contexteOrientation;
        final Instant createdAt = Instant.now();

        OriaSession(String contexteOrientation) {
            this.contexteOrientation = contexteOrientation;
        }
    }

    private record ChatMessage(String role, String contenu, Instant timestamp) {}
}
