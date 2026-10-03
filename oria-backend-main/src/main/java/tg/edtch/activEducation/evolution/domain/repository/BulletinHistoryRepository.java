package tg.edtch.activEducation.evolution.domain.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import tg.edtch.activEducation.evolution.domain.entite.BulletinHistory;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface BulletinHistoryRepository extends JpaRepository<BulletinHistory, Long> {

    Optional<BulletinHistory> findByTrackingId(UUID trackingId);

    List<BulletinHistory> findByStudentIdOrderByAcademicYearDescTrimesterDesc(UUID studentId);

    @Query("""
            SELECT b FROM BulletinHistory b
            WHERE b.studentId = :studentId
              AND b.academicYear = :academicYear
              AND b.trimester = :trimester
            ORDER BY b.subject ASC
            """)
    List<BulletinHistory> findByStudentAndPeriod(
            @Param("studentId") UUID studentId,
            @Param("academicYear") String academicYear,
            @Param("trimester") Integer trimester);

    @Query("""
            SELECT b.subject, AVG(b.grade)
            FROM BulletinHistory b
            WHERE b.studentId = :studentId
            GROUP BY b.subject
            """)
    List<Object[]> averageGradeBySubject(@Param("studentId") UUID studentId);
}
