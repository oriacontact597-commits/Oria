package tg.edtch.activEducation.shared.ai.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import tg.edtch.activEducation.shared.ai.service.FicheEmbeddingIndexer;

/**
 * Endpoints d'administration pour la maintenance des embeddings ORIA/RAG.
 * Réservé aux admins.
 */
@RestController
@RequestMapping("/api/v1/admin/oria")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
@Tag(name = "Admin ORIA", description = "Maintenance de l'index vectoriel")
public class AdminOriaController {

    private final FicheEmbeddingIndexer indexer;

    @PostMapping("/reindex")
    @Operation(summary = "Re-vectorise toutes les fiches (ou seulement celles sans embedding)")
    public ResponseEntity<FicheEmbeddingIndexer.IndexResult> reindex(
            @RequestParam(defaultValue = "false") boolean force) {
        var result = indexer.reindexAll(force, 50);
        return ResponseEntity.ok(result);
    }
}
