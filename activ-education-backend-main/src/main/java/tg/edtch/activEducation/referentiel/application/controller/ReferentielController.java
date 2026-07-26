package tg.edtch.activEducation.referentiel.application.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import tg.edtch.activEducation.referentiel.domain.entite.Country;
import tg.edtch.activEducation.referentiel.domain.entite.Series;
import tg.edtch.activEducation.referentiel.domain.repository.CountryRepository;
import tg.edtch.activEducation.referentiel.domain.repository.SeriesRepository;

import java.util.List;
import java.util.Map;

/**
 * Référentiel multi-pays : expose la liste des pays supportés et leurs séries.
 * Public (pas d'auth requise) car c'est de l'information pédagogique générique.
 */
@RestController
@RequestMapping("/api/v1/referentiel")
@RequiredArgsConstructor
public class ReferentielController {

    private final CountryRepository countryRepository;
    private final SeriesRepository seriesRepository;

    @GetMapping("/countries")
    public ResponseEntity<List<Country>> listCountries() {
        return ResponseEntity.ok(countryRepository.findByIsActiveTrueOrderByNameFrAsc());
    }

    @GetMapping("/countries/{code}")
    public ResponseEntity<Country> getCountry(@PathVariable String code) {
        return countryRepository.findByCode(code.toUpperCase())
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/countries/{code}/series")
    public ResponseEntity<List<Series>> listSeries(@PathVariable String code) {
        return ResponseEntity.ok(seriesRepository.findByCountryCodeOrderByCodeAsc(code.toUpperCase()));
    }

    @GetMapping("/_health")
    @PreAuthorize("permitAll()")
    public ResponseEntity<Map<String, String>> health() {
        return ResponseEntity.ok(Map.of("status", "ok", "module", "referentiel"));
    }
}
