package tg.edtch.activEducation.evolution.domain.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import tg.edtch.activEducation.evolution.domain.entite.InterviewResponseHistory;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface InterviewResponseHistoryRepository
        extends JpaRepository<InterviewResponseHistory, Long> {

    Optional<InterviewResponseHistory> findByTrackingId(UUID trackingId);

    List<InterviewResponseHistory> findByStudentIdOrderByAskedAtDesc(UUID studentId);

    List<InterviewResponseHistory> findByInterviewSessionId(UUID interviewSessionId);
}
