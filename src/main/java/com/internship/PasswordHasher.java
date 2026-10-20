package com.internship;

import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Arrays;
import java.util.Base64;

import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

/**
 * Creates and verifies versioned PBKDF2 password records. Stored records use:
 * PBKDF2-SHA256$iterations$url-safe-base64-salt$url-safe-base64-derived-key
 */
public final class PasswordHasher {

    public static final int MIN_PASSWORD_LENGTH = 12;

    private static final String ALGORITHM_LABEL = "PBKDF2-SHA256";
    private static final String KDF_ALGORITHM = "PBKDF2WithHmacSHA256";
    private static final int ITERATIONS = 600_000;
    private static final int SALT_BYTES = 16;
    private static final int DERIVED_KEY_BITS = 256;
    private static final int DERIVED_KEY_BYTES = DERIVED_KEY_BITS / 8;
    private static final int MIN_ACCEPTED_ITERATIONS = 100_000;
    private static final int MAX_ACCEPTED_ITERATIONS = 2_000_000;
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final Base64.Encoder ENCODER = Base64.getUrlEncoder().withoutPadding();
    private static final Base64.Decoder DECODER = Base64.getUrlDecoder();

    private PasswordHasher() {
    }

    public static boolean isValidNewPassword(String password) {
        return password != null
                && !password.trim().isEmpty()
                && password.length() >= MIN_PASSWORD_LENGTH;
    }

    public static String hash(String password) {
        if (!isValidNewPassword(password)) {
            throw new IllegalArgumentException("Password does not meet the minimum policy.");
        }

        return createHash(password);
    }

    /**
     * Hashes a credential that has already passed legacy authentication during
     * a one-time migration. New-password policy remains enforced by hash().
     */
    public static String hashLegacyPassword(String password) {
        if (password == null || password.trim().isEmpty()) {
            throw new IllegalArgumentException("Legacy password is blank.");
        }

        return createHash(password);
    }

    private static String createHash(String password) {
        byte[] salt = new byte[SALT_BYTES];
        RANDOM.nextBytes(salt);
        char[] passwordChars = password.toCharArray();

        try {
            byte[] derivedKey = derive(passwordChars, salt, ITERATIONS);
            try {
                return ALGORITHM_LABEL + "$" + ITERATIONS + "$"
                        + ENCODER.encodeToString(salt) + "$"
                        + ENCODER.encodeToString(derivedKey);
            }
            finally {
                Arrays.fill(derivedKey, (byte) 0);
            }
        }
        finally {
            Arrays.fill(passwordChars, '\0');
            Arrays.fill(salt, (byte) 0);
        }
    }

    public static boolean isValidPbkdf2Record(String storedValue) {
        ParsedRecord record = parse(storedValue);
        if (record == null) {
            return false;
        }
        record.clear();
        return true;
    }

    /**
     * A value beginning with the reserved format label is never accepted as
     * legacy plaintext when it is malformed.
     */
    public static boolean isPbkdf2Candidate(String storedValue) {
        return storedValue != null && storedValue.startsWith(ALGORITHM_LABEL + "$");
    }

    public static boolean verify(String password, String storedValue) {
        ParsedRecord record = parse(storedValue);
        if (record == null || password == null) {
            return false;
        }

        char[] passwordChars = password.toCharArray();
        try {
            byte[] actual = derive(passwordChars, record.salt, record.iterations);
            try {
                return MessageDigest.isEqual(actual, record.derivedKey);
            }
            finally {
                Arrays.fill(actual, (byte) 0);
            }
        }
        finally {
            Arrays.fill(passwordChars, '\0');
            record.clear();
        }
    }

    public static boolean legacyMatches(String submittedPassword, String storedLegacyPassword) {
        if (submittedPassword == null || storedLegacyPassword == null) {
            return false;
        }

        byte[] submitted = submittedPassword.getBytes(StandardCharsets.UTF_8);
        byte[] stored = storedLegacyPassword.getBytes(StandardCharsets.UTF_8);
        try {
            return MessageDigest.isEqual(submitted, stored);
        }
        finally {
            Arrays.fill(submitted, (byte) 0);
            Arrays.fill(stored, (byte) 0);
        }
    }

    private static ParsedRecord parse(String storedValue) {
        if (storedValue == null) {
            return null;
        }

        String[] parts = storedValue.split("\\$", -1);
        if (parts.length != 4 || !ALGORITHM_LABEL.equals(parts[0])) {
            return null;
        }

        int iterations;
        try {
            if (!parts[1].matches("[1-9][0-9]*")) {
                return null;
            }
            iterations = Integer.parseInt(parts[1]);
        }
        catch (NumberFormatException e) {
            return null;
        }

        if (iterations < MIN_ACCEPTED_ITERATIONS || iterations > MAX_ACCEPTED_ITERATIONS) {
            return null;
        }

        byte[] salt = decodeCanonical(parts[2]);
        byte[] derivedKey = decodeCanonical(parts[3]);
        if (salt == null || derivedKey == null
                || salt.length != SALT_BYTES
                || derivedKey.length != DERIVED_KEY_BYTES) {
            clear(salt);
            clear(derivedKey);
            return null;
        }

        return new ParsedRecord(iterations, salt, derivedKey);
    }

    private static byte[] decodeCanonical(String encoded) {
        try {
            byte[] decoded = DECODER.decode(encoded);
            if (!ENCODER.encodeToString(decoded).equals(encoded)) {
                Arrays.fill(decoded, (byte) 0);
                return null;
            }
            return decoded;
        }
        catch (IllegalArgumentException e) {
            return null;
        }
    }

    private static byte[] derive(char[] password, byte[] salt, int iterations) {
        PBEKeySpec specification = new PBEKeySpec(password, salt, iterations, DERIVED_KEY_BITS);
        try {
            return SecretKeyFactory.getInstance(KDF_ALGORITHM)
                    .generateSecret(specification)
                    .getEncoded();
        }
        catch (GeneralSecurityException e) {
            throw new IllegalStateException("Password hashing is unavailable.", e);
        }
        finally {
            specification.clearPassword();
        }
    }

    private static void clear(byte[] value) {
        if (value != null) {
            Arrays.fill(value, (byte) 0);
        }
    }

    private static final class ParsedRecord {
        private final int iterations;
        private final byte[] salt;
        private final byte[] derivedKey;

        private ParsedRecord(int iterations, byte[] salt, byte[] derivedKey) {
            this.iterations = iterations;
            this.salt = salt;
            this.derivedKey = derivedKey;
        }

        private void clear() {
            Arrays.fill(salt, (byte) 0);
            Arrays.fill(derivedKey, (byte) 0);
        }
    }
}
