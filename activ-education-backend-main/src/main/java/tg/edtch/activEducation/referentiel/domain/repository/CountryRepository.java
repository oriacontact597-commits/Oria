package tg.edtch.activEducation.referentiel.domain.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import tg.edtch.activEducation.referentiel.domain.entite.Country;

import java.util.List;
import java.util.Optional;

@Repository
public interface CountryRepository extends JpaRepository<Country, Long> {

    Optional<Country> findByCode(String code);

    List<Country> findByIsActiveTrueOrderByNameFrAsc();

    Optional<Country> findByTrackingId(java.util.UUID trackingId);
}
