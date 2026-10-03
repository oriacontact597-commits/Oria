package tg.edtch.activEducation.evolution.domain.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import tg.edtch.activEducation.evolution.domain.entite.StudentEvolutionProfile;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface StudentEvolutionProfileRepository
        extends JpaRepository<StudentEvolutionProfile, Long> {

    Optional<StudentEvolutionProfile> findByStudentId(UUID studentId);
}
