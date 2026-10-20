package com.internship;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

public final class CsrfToken {

    private static final String SESSION_ATTRIBUTE = "csrfToken";
    private static final String REQUEST_PARAMETER = "csrfToken";
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private CsrfToken() {
    }

    public static String create(HttpSession session) {
        byte[] bytes = new byte[32];
        SECURE_RANDOM.nextBytes(bytes);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        session.setAttribute(SESSION_ATTRIBUTE, token);
        return token;
    }

    public static String getOrCreate(HttpSession session) {
        Object value = session.getAttribute(SESSION_ATTRIBUTE);
        if (value instanceof String && !((String) value).isEmpty()) {
            return (String) value;
        }
        return create(session);
    }

    public static boolean isValid(HttpServletRequest request, HttpSession session) {
        Object value = session.getAttribute(SESSION_ATTRIBUTE);
        if (!(value instanceof String)) {
            return false;
        }

        String submitted = request.getParameter(REQUEST_PARAMETER);
        if (submitted == null) {
            return false;
        }

        return MessageDigest.isEqual(
                ((String) value).getBytes(StandardCharsets.UTF_8),
                submitted.getBytes(StandardCharsets.UTF_8));
    }
}
