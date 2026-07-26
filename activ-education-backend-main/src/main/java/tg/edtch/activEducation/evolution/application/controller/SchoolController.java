package tg.edtch.activEducation.evolution.application.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import tg.edtch.activEducation.evolution.application.dto.BulletinSubmissionRequest;
import tg.edtch.activEducation.evolution.application.dto.BulletinSubmissionResponse;
import tg.edtch.activEducation.evolution.domain.entite.BulletinHistory;
import tg.edtch.activEducation.evolution.domain.repository.BulletinHistoryRepository;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Endpoint pour les ÉCOLES — permet à un établissement scolaire authentifié
 * d'envoyer les notes trimestrielles d'un élève.
 *
 * <p>POST /api/v1/school/bulletins</p>
 * <p>Réservé au rôle ROLE_ECOLE (à créer en DB).</p>
 *
 * <p>Ce endpoint alimente le Student Evolution Engine : les notes insérées
 * déclenchent un recalcul automatique du SEP à la prochaine requête
 * /evolution/{studentId}/compute.</p>
 */
@RestController
@RequestMapping("/api/v1/school")
@RequiredArgsConstructor
@Slf4j
public class SchoolController {

    private final BulletinHistoryRepository bulletinRepository;

    @PostMapping("/bulletins")
    @PreAuthorize("hasAnyRole('ECOLE', 'ADMIN', 'SUPER_ADMIN')")
    public ResponseEntity<BulletinSubmissionResponse> submitBulletin(
            @Valid @RequestBody BulletinSubmissionRequest request) {

        log.info("SchoolController.submitBulletin student={} year={} T{} grades={}",
                request.getStudentId(), request.getAcademicYear(),
                request.getTrimester(), request.getGrades().size());

        UUID submissionId = UUID.randomUUID();
        List<UUID> insertedTrackingIds = new ArrayList<>();

        for (BulletinSubmissionRequest.SubjectGrade sg : request.getGrades()) {
            BulletinHistory bulletin = BulletinHistory.builder()
                    .studentId(request.getStudentId())
                    .academicYear(request.getAcademicYear())
                    .trimester(request.getTrimester())
                    .subject(sg.getSubject())
                    .grade(sg.getGrade())
                    .classAverage(sg.getClassAverage())
                    .rankInClass(sg.getRankInClass())
                    .appreciation(sg.getAppreciation())
                    .isOfficial(true)
                    .sentByEstablishmentId(request.getEstablishmentId())
                    .receivedAt(java.time.LocalDateTime.now())
                    .build();
            BulletinHistory saved = bulletinRepository.save(bulletin);
            insertedTrackingIds.add(saved.getTrackingId());
        }

        BulletinSubmissionResponse response = BulletinSubmissionResponse.builder()
                .submissionId(submissionId)
                .studentId(request.getStudentId())
                .academicYear(request.getAcademicYear())
                .trimester(request.getTrimester())
                .gradesInserted(insertedTrackingIds.size())
                .bulletinTrackingIds(insertedTrackingIds)
                .message("Bulletin enregistré. Le profil élève sera recalculé à la prochaine consultation.")
                .build();

        log.info("SchoolController OK submission={} bulletins={}",
                submissionId, insertedTrackingIds.size());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/bulletins/{studentId}")
    @PreAuthorize("hasAnyRole('ECOLE', 'CONSEILLER', 'ADMIN', 'SUPER_ADMIN')")
    public ResponseEntity<List<BulletinHistory>> getBulletins(@PathVariable UUID studentId) {
        return ResponseEntity.ok(
                bulletinRepository.findByStudentIdOrderByAcademicYearDescTrimesterDesc(studentId));
    }
}
