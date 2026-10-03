package tg.edtch.activEducation.riasec.application.controller;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import tg.edtch.activEducation.riasec.domain.dto.RIASECResultatResponse;
import tg.edtch.activEducation.riasec.domain.service.RIASECService;
import java.util.List;
import java.util.UUID;
@RestController @RequestMapping("/api/v1/riasec")
@PreAuthorize("isAuthenticated()")
public class RIASECController {
    private final RIASECService service;
    public RIASECController(RIASECService service) { this.service = service; }
    @PostMapping("/{eleveId}/passer")
    @PreAuthorize("@security.isOwner(#eleveId) or @security.isOwnChild(#eleveId) or hasRole('ADMIN')")
    public ResponseEntity<RIASECResultatResponse> passer(@PathVariable UUID eleveId, @RequestBody String reponses) {
        return ResponseEntity.ok(service.passerTest(eleveId.toString(), reponses));
    }
    @GetMapping("/{eleveId}/resultats")
    @PreAuthorize("@security.isOwner(#eleveId) or @security.isOwnChild(#eleveId) or hasRole('ADMIN')")
    public ResponseEntity<List<RIASECResultatResponse>> resultats(@PathVariable UUID eleveId) {
        return ResponseEntity.ok(service.getResultats(eleveId.toString()));
    }
}
