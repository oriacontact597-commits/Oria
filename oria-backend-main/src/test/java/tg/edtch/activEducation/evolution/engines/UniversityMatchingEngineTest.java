package tg.edtch.activEducation.evolution.engines;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import tg.edtch.activEducation.bibliotheque.domain.entite.FicheEtablissement;
import tg.edtch.activEducation.bibliotheque.repository.FicheEtablissementRepository;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UniversityMatchingEngineTest {

    @Mock
    private FicheEtablissementRepository etablissementRepository;

    private UniversityMatchingEngine engine;

    @BeforeEach
    void setUp() {
        engine = new UniversityMatchingEngine(etablissementRepository);
    }

    @Test
    void name_isUniversity() {
        assertEquals("university", engine.name());
    }

    @Test
    void evaluate_noEtablissements_returnsScore5() {
        UUID sid = UUID.randomUUID();
        when(etablissementRepository.findAllByEstPublieTrue(any())).thenReturn(Page.empty());

        Engine.Output out = engine.evaluate(sid);
        assertEquals(0.5, out.score());
        assertEquals("Aucun établissement référencé dans la base.", out.explanation());
    }

    @Test
    void evaluate_withEtablissements_returnsScore() {
        UUID sid = UUID.randomUUID();
        var e1 = etablissement("Lomé", "BAC+5", FicheEtablissement.TypeEtablissement.UNIVERSITE);
        var e2 = etablissement("Kara", "BAC+5", FicheEtablissement.TypeEtablissement.UNIVERSITE);
        var e3 = etablissement("Lomé", "BAC+3", FicheEtablissement.TypeEtablissement.ECOLE_SUPERIEURE);

        when(etablissementRepository.findAllByEstPublieTrue(any()))
                .thenReturn(new PageImpl<>(List.of(e1, e2, e3)));

        Engine.Output out = engine.evaluate(sid);
        assertTrue(out.score() > 0.2);
        assertEquals(3, out.details().get("etablissementsCount"));
        assertEquals(2L, out.details().get("universitesCount"));
        assertEquals(1L, out.details().get("ecolesCount"));
    }

    private static FicheEtablissement etablissement(String ville, String niveau,
                                                     FicheEtablissement.TypeEtablissement type) {
        var e = mock(FicheEtablissement.class);
        when(e.getTypeEtablissement()).thenReturn(type);
        when(e.getVille()).thenReturn(ville);
        when(e.getNiveau()).thenReturn(niveau);
        return e;
    }
}
