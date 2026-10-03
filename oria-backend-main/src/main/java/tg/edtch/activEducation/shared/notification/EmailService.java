package tg.edtch.activEducation.shared.notification;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;

import jakarta.mail.internet.MimeMessage;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class EmailService {

    private final JavaMailSender mailSender;
    private final TemplateEngine templateEngine;

    @Value("${spring.mail.host:}")
    private String smtpHost;

    @Value("${smtp.from:noreply@oria.activeducation.tg}")
    private String fromAddress;

    public boolean sendOtp(String to, String code, String prenom) {
        if (smtpHost == null || smtpHost.isBlank()) {
            log.info("[EMAIL SIMULATED] À {}: OTP {} pour {}", to, code, prenom);
            return true;
        }
        try {
            Context ctx = new Context();
            ctx.setVariables(Map.of("code", code, "prenom", prenom));
            String html = templateEngine.process("email/otp", ctx);

            MimeMessage msg = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(msg, true, "UTF-8");
            helper.setTo(to);
            helper.setFrom(fromAddress);
            helper.setSubject("Votre code de vérification ORIA");
            helper.setText(html, true);
            mailSender.send(msg);
            log.info("OTP envoyé par email à {}", to);
            return true;
        } catch (Exception e) {
            log.error("Erreur envoi email à {}: {}", to, e.getMessage());
            return false;
        }
    }
}
