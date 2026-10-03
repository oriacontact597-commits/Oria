package tg.edtch.activEducation.bibliotheque.repository;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import tg.edtch.activEducation.bibliotheque.application.dto.response.FicheEtablissementResponse;
import tg.edtch.activEducation.bibliotheque.application.mapper.FicheEtablissementMapper;
import tg.edtch.activEducation.bibliotheque.domain.entite.FicheEtablissement;
import tg.edtch.activEducation.shared.ai.service.AIEmbeddingService;
import tg.edtch.activEducation.shared.minio.service.MinioService;
import tg.edtch.activEducation.profil.domain.service.HistoriqueService;
import tg.edtch.activEducation.bibliotheque.repository.FicheFiliereRepository;
import tg.edtch.activEducation.bibliotheque.domain.service.RechercheOrphelineService;
import tg.edtch.activEducation.bibliotheque.domain.service.serviceImple.FicheEtablissementServiceImpl;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

/**
 * Test unitaire du filtre par pays (P1.1 ORIA).
 * Vérifie que {@link FicheEtablissementServiceImpl#listerParPays} délègue
 * correctement à {@code findByCountryCodeIgnoreCaseAndEstPublieTrue} ou,
 * si le code est vide, à {@code findAllByEstPublieTrue}.
 */
@ExtendWith(MockitoExtension.class)
class FicheEtablissementRepositoryTest {

        @Mock
        private FicheEtablissementRepository etablissementRepository;

        @Mock
        private FicheEtablissementMapper etablissementMapper;

        @Mock
        private FicheFiliereRepository filiereRepository;

        @Mock
        private MinioService minioService;

        @Mock
        private AIEmbeddingService aiEmbeddingService;

        @Mock
        private HistoriqueService historiqueService;

        @Mock
        private RechercheOrphelineService orphelineService;

        @InjectMocks
        private FicheEtablissementServiceImpl service;

        @Test
        void listerParPays_delegatesToCountryRepository() {
                Pageable pageable = PageRequest.of(0, 10);
                FicheEtablissement fake = new FicheEtablissement();
                fake.setTrackingId(UUID.randomUUID());
                fake.setCountryCode("TG");
                Page<FicheEtablissement> repoPage = new PageImpl<>(List.of(fake), pageable, 1);

                FicheEtablissementResponse resp = FicheEtablissementResponse.builder()
                                .trackingId(fake.getTrackingId())
                                .countryCode("TG")
                                .build();

                lenient().when(etablissementRepository
                                .findByCountryCodeIgnoreCaseAndEstPublieTrue(eq("TG"), any(Pageable.class)))
                                .thenReturn(repoPage);
                when(etablissementMapper.toResponse(any(FicheEtablissement.class))).thenReturn(resp);

                Page<FicheEtablissementResponse> result = service.listerParPays("TG", pageable);

                assertThat(result.getTotalElements()).isEqualTo(1);
                assertThat(result.getContent().get(0).getCountryCode()).isEqualTo("TG");
        }

        @Test
        void listerParPays_blankCode_fallsBackToAllPublies() {
                Pageable pageable = PageRequest.of(0, 10);
                Page<FicheEtablissement> repoPage = new PageImpl<>(List.of(), pageable, 0);

                lenient().when(etablissementRepository.findAllByEstPublieTrue(any(Pageable.class)))
                                .thenReturn(repoPage);

                Page<FicheEtablissementResponse> result = service.listerParPays("", pageable);

                assertThat(result.getTotalElements()).isZero();
        }

        @Test
        void listerParPays_nullCode_fallsBackToAllPublies() {
                Pageable pageable = PageRequest.of(0, 10);
                Page<FicheEtablissement> repoPage = new PageImpl<>(List.of(), pageable, 0);

                lenient().when(etablissementRepository.findAllByEstPublieTrue(any(Pageable.class)))
                                .thenReturn(repoPage);

                Page<FicheEtablissementResponse> result = service.listerParPays(null, pageable);

                assertThat(result.getTotalElements()).isZero();
        }

        @Test
        void listerParPays_lowercaseCode_delegatesToIgnoreCaseRepo() {
                // Vérifie que le service délègue bien la casse minuscule au repo
                // findByCountryCodeIgnoreCaseAndEstPublieTrue (qui match TG == tg).
                Pageable pageable = PageRequest.of(0, 10);
                FicheEtablissement fake = new FicheEtablissement();
                fake.setTrackingId(UUID.randomUUID());
                fake.setCountryCode("TG");
                Page<FicheEtablissement> repoPage = new PageImpl<>(List.of(fake), pageable, 1);

                FicheEtablissementResponse resp = FicheEtablissementResponse.builder()
                                .trackingId(fake.getTrackingId())
                                .countryCode("TG")
                                .build();

                lenient().when(etablissementRepository
                                .findByCountryCodeIgnoreCaseAndEstPublieTrue(eq("tg"), any(Pageable.class)))
                                .thenReturn(repoPage);
                when(etablissementMapper.toResponse(any(FicheEtablissement.class))).thenReturn(resp);

                Page<FicheEtablissementResponse> result = service.listerParPays("tg", pageable);

                assertThat(result.getTotalElements()).isEqualTo(1);
                assertThat(result.getContent().get(0).getCountryCode()).isEqualTo("TG");
        }
}