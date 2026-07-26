package tg.edtch.activEducation.referentiel.domain.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import tg.edtch.activEducation.referentiel.domain.entite.Series;

import java.util.List;

@Repository
public interface SeriesRepository extends JpaRepository<Series, Long> {

    List<Series> findByCountryCodeOrderByCodeAsc(String countryCode);
}
