package tg.edtch.activEducation.shared.ai.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tg.edtch.activEducation.bibliotheque.domain.entite.FicheEtablissement;
import tg.edtch.activEducation.bibliotheque.domain.entite.FicheFiliere;
import tg.edtch.activEducation.bibliotheque.domain.entite.FicheMetier;
import tg.edtch.activEducation.bibliotheque.repository.FicheEtablissementRepository;
import tg.edtch.activEducation.bibliotheque.repository.FicheFiliereRepository;
import tg.edtch.activEducation.bibliotheque.repository.FicheMetierRepository;
import tg.edtch.activEducation.diagnostic.domain.entite.Quiz;
import tg.edtch.activEducation.diagnostic.domain.entite.ResultatDiagnostic;
import tg.edtch.activEducation.diagnostic.repository.QuizRepository;
import tg.edtch.activEducation.diagnostic.repository.ResultatDiagnosticRepository;
import tg.edtch.activEducation.profil.domain.entite.Eleve;
import tg.edtch.activEducation.profil.domain.entite.NoteSaisiManuel;
import tg.edtch.activEducation.profil.repository.EleveRepository;
import tg.edtch.activEducation.profil.repository.NoteSaisiManuelRepository;
import tg.edtch.activEducation.shared.llm.LlmGateway;
import tg.edtch.activEducation.shared.llm.LlmRequest;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class RecommandationIAService {

    private final EleveRepository eleveRepository;
    private final NoteSaisiManuelRepository noteRepository;
    private final ResultatDiagnosticRepository resultatRepository;
    private final QuizRepository quizRepository;
    private final FicheFiliereRepository filiereRepository;
    private final FicheMetierRepository metierRepository;
    private final FicheEtablissementRepository etablissementRepository;
    private final LlmGateway llmGateway;
    private final tg.edtch.activEducation.prediction.application.service.Recommandation3SignauxService recommandation3SignauxService;
    private final OriaRechercheContexteService rechercheService;

    public String genererRecommandation(UUID eleveTrackingId) {
        Eleve eleve = eleveRepository.findByTrackingId(eleveTrackingId)
                .orElseThrow(() -> new RuntimeException("Élève introuvable"));

        boolean profilRempli = false;
        StringBuilder profilBuilder = new StringBuilder();
        profilBuilder.append("Profil de l'élève :\n");
        profilBuilder.append("- Niveau : ").append(eleve.getNiveau() != null ? eleve.getNiveau() : "Non renseigné").append("\n");
        profilBuilder.append("- Type : ").append(eleve.getTypeApprenant() != null ? eleve.getTypeApprenant().name() : "Non renseigné").append("\n");
        profilBuilder.append("- Établissement : ").append(eleve.getEtablissement() != null ? eleve.getEtablissement() : "Non renseigné").append("\n");
        profilBuilder.append("- Filière actuelle : ").append(eleve.getFiliere() != null ? eleve.getFiliere() : "Non renseigné").append("\n");
        profilBuilder.append("- Métier souhaité : ").append(eleve.getMetierSouhaite() != null ? eleve.getMetierSouhaite() : "Non renseigné").append("\n");
        profilBuilder.append("- Matières préférées : ").append(eleve.getMatieresPreferees() != null ? eleve.getMatieresPreferees() : "Non renseigné").append("\n");

        boolean aDesNotes = false;
        List<NoteSaisiManuel> notes = noteRepository.findByEleveTrackingIdOrderByAnneeScolaireDesc(eleveTrackingId);
        if (!notes.isEmpty()) {
            aDesNotes = true;
            profilBuilder.append("\nNotes scolaires :\n");
            for (NoteSaisiManuel note : notes) {
                profilBuilder.append("- ").append(note.getMatiere()).append(" : ").append(note.getNote()).append("/20\n");
            }
        }

        boolean aDesQuiz = false;
        List<ResultatDiagnostic> resultats = resultatRepository
                .findByEleveTrackingIdOrderByDatePassageDesc(eleveTrackingId,
                        org.springframework.data.domain.PageRequest.of(0, 5))
                .getContent();
        if (!resultats.isEmpty()) {
            aDesQuiz = true;
            profilBuilder.append("\nRésultats de quiz d'orientation :\n");
            for (ResultatDiagnostic r : resultats) {
                Optional<Quiz> quiz = quizRepository.findByTrackingId(r.getQuiz().getTrackingId());
                String nomQuiz = quiz.map(Quiz::getTitre).orElse("Quiz inconnu");
                profilBuilder.append("- ").append(nomQuiz).append(" : score ").append(r.getScoreFinal()).append("\n");
            }
        }

        profilRempli = eleve.getNiveau() != null || eleve.getFiliere() != null
                || eleve.getMetierSouhaite() != null || eleve.getMatieresPreferees() != null
                || aDesNotes || aDesQuiz;

        if (!profilRempli) {
            return "Je n'ai pas encore assez d'informations sur toi pour te faire une recommandation personnalisée. "
                    + "Pour obtenir ta recommandation, je te propose de :\n\n"
                    + "1️⃣ Compléter ton profil (niveau, filière, métier souhaité)\n"
                    + "2️⃣ Renseigner tes notes scolaires\n"
                    + "3️⃣ Passer les quiz d'orientation (RIASEC, personnalité)\n\n"
                    + "Une fois ces informations remplies, reviens ici et je pourrai te générer "
                    + "une recommandation sur mesure adaptée à ton profil ! 🎯";
        }

        // --- Récupération Intelligente des Données ---

        // 1. Filières : via le moteur 3 signaux (Aspiration, Réalité, Engagement)
        List<FicheFiliere> filieres = new java.util.ArrayList<>();
        try {
            var recResponse = recommandation3SignauxService.recommander(eleveTrackingId);
            if (recResponse != null && recResponse.getTop() != null) {
                for (var item : recResponse.getTop()) {
                    filiereRepository.findByTrackingId(item.getTrackingId())
                        .ifPresent(filieres::add);
                }
            }
        } catch (Exception e) {
            log.warn("Échec recommandation 3 signaux, fallback aléatoire : {}", e.getMessage());
            filieres.addAll(filiereRepository.findAllByEstPublieTrue(org.springframework.data.domain.PageRequest.of(0, 5)).getContent());
        }

        // 2. Métiers et Établissements : via recherche sémantique/mots-clés
        List<FicheMetier> metiers = new java.util.ArrayList<>();
        List<FicheEtablissement> etablissements = new java.util.ArrayList<>();

        String queryRecherche = "";
        if (eleve.getMetierSouhaite() != null) queryRecherche += eleve.getMetierSouhaite() + " ";
        if (eleve.getMatieresPreferees() != null) queryRecherche += eleve.getMatieresPreferees() + " ";

        if (!queryRecherche.isBlank()) {
            try {
                var fiches = rechercheService.rechercher(queryRecherche.trim());
                if (fiches != null) {
                    for (var fiche : fiches) {
                        if (fiche instanceof FicheMetier m) metiers.add(m);
                        else if (fiche instanceof FicheEtablissement e) etablissements.add(e);
                    }
                }
            } catch (Exception e) {
                log.warn("Échec recherche contexte, fallback aléatoire : {}", e.getMessage());
            }
        }

        // Fallback si les listes sont trop courtes
        if (metiers.isEmpty()) {
            metiers.addAll(metierRepository.findAllByEstPublieTrue(org.springframework.data.domain.PageRequest.of(0, 5)).getContent());
        }
        if (etablissements.isEmpty()) {
            etablissements.addAll(etablissementRepository.findAllByEstPublieTrue(org.springframework.data.domain.PageRequest.of(0, 5)).getContent());
        }

        StringBuilder contexteBuilder = new StringBuilder();
        contexteBuilder.append("\nFilières disponibles au Togo :\n");
        for (FicheFiliere f : filieres) {
            contexteBuilder.append("- ").append(f.getTitre()).append(" : ").append(f.getResume()).append("\n");
        }
        contexteBuilder.append("\nMétiers disponibles au Togo :\n");
        for (FicheMetier m : metiers) {
            contexteBuilder.append("- ").append(m.getTitre()).append(" : ").append(m.getResume()).append("\n");
        }
        contexteBuilder.append("\nÉtablissements au Togo :\n");
        for (FicheEtablissement e : etablissements) {
            contexteBuilder.append("- ").append(e.getTitre()).append(" (").append(e.getVille()).append(")\n");
        }

        String question = "En tant que conseiller d'orientation, fais une recommandation personnalisée pour cet élève. "
                + "Propose-lui jusqu'à 3 filières d'études adaptées à son profil, jusqu'à 3 métiers qui correspondent, "
                + "et les établissements où il peut les étudier au Togo. "
                + "Justifie chaque recommandation en t'appuyant sur son profil, ses notes et ses résultats de quiz. "
                + "Sois encourageant et concret.";

        try {
            String userPrompt = question + "\n\n" + profilBuilder + contexteBuilder;
            return llmGateway.complete(new LlmRequest(
                    "Tu es un conseiller d'orientation scolaire au Togo. "
                            + "Base-toi uniquement sur les informations fournies, n'invente aucune donnée, "
                            + "et réponds en français de manière claire et encourageante.",
                    userPrompt,
                    0.2,
                    3000)).content();
        } catch (Exception e) {
            log.error("Erreur génération recommandation IA", e);
            return "Désolé, je n'ai pas pu générer une recommandation pour le moment. "
                    + "Veuillez réessayer plus tard ou consulter un conseiller.";
        }
    }
}
