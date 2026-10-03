package tg.edtch.activEducation.shared.llm;

/**
 * Exception levée quand un appel LLM échoue.
 */
public class LlmException extends RuntimeException {
    public LlmException(String message) {
        super(message);
    }

    public LlmException(String message, Throwable cause) {
        super(message, cause);
    }
}
