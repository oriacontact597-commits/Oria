package tg.edtch.activEducation.shared.i18n;

import lombok.RequiredArgsConstructor;
import org.springframework.context.MessageSource;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.LocaleResolver;

import java.util.*;

/**
 * Endpoint public qui expose les bundles i18n (FR/EN/PT) en JSON.
 * Le mobile/backoffice peuvent ainsi récupérer les libellés dynamiques
 * d'EventEngine ou d'autres composants serveur.
 */
@RestController
@RequestMapping("/api/v1/i18n")
@RequiredArgsConstructor
public class I18nController {

    private final MessageSource messageSource;
    private final LocaleResolver localeResolver;

    @GetMapping("/{locale}")
    public ResponseEntity<Map<String, String>> getBundle(
            @PathVariable String locale,
            @RequestHeader(value = "Accept-Language", required = false) String acceptLanguage) {
        Locale loc = Locale.forLanguageTag(locale);
        ResourceBundle bundle = ResourceBundle.getBundle("messages", loc);

        Map<String, String> result = new LinkedHashMap<>();
        for (String key : bundle.keySet()) {
            result.put(key, bundle.getString(key));
        }
        return ResponseEntity.ok(result);
    }

    @GetMapping("/locales")
    public ResponseEntity<List<String>> listSupported() {
        return ResponseEntity.ok(List.of("fr", "en", "pt"));
    }
}
