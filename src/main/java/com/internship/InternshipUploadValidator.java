package com.internship;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Path;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

import jakarta.servlet.http.Part;

/** Small, dependency-free validation for the document formats supported by the portal. */
final class InternshipUploadValidator {
    static final long MAX_FILE_SIZE = 10L * 1024L * 1024L;
    private static final Set<String> EXTENSIONS = Set.of(".pdf", ".doc", ".docx", ".ppt", ".pptx", ".jpg", ".jpeg", ".png");
    private static final Map<String, Set<String>> MIME_TYPES = Map.of(
            ".pdf", Set.of("application/pdf"), ".doc", Set.of("application/msword"),
            ".docx", Set.of("application/vnd.openxmlformats-officedocument.wordprocessingml.document"),
            ".ppt", Set.of("application/vnd.ms-powerpoint"),
            ".pptx", Set.of("application/vnd.openxmlformats-officedocument.presentationml.presentation"),
            ".jpg", Set.of("image/jpeg", "image/pjpeg"), ".jpeg", Set.of("image/jpeg", "image/pjpeg"),
            ".png", Set.of("image/png"));

    private InternshipUploadValidator() { }

    static String validate(Part part) throws IOException {
        if (part == null || part.getSize() <= 0 || part.getSize() > MAX_FILE_SIZE) throw new IOException("Invalid file size");
        String submitted = part.getSubmittedFileName();
        if (submitted == null || submitted.trim().isEmpty()) throw new IOException("Missing file name");
        String name = Path.of(submitted.replace('\\', '/')).getFileName().toString();
        if (name.isBlank() || name.indexOf('\0') >= 0) throw new IOException("Invalid file name");
        int dot = name.lastIndexOf('.');
        String extension = dot > 0 ? name.substring(dot).toLowerCase(Locale.ROOT) : "";
        if (!EXTENSIONS.contains(extension)) throw new IOException("Unsupported file type");
        String contentType = part.getContentType();
        if (contentType != null && !contentType.isBlank() && !"application/octet-stream".equalsIgnoreCase(contentType)
                && !MIME_TYPES.get(extension).contains(contentType.toLowerCase(Locale.ROOT))) throw new IOException("Mismatched file type");
        try (InputStream input = part.getInputStream()) {
            byte[] header = input.readNBytes(8);
            if (!hasExpectedSignature(extension, header)) throw new IOException("Invalid file content");
        }
        return extension;
    }

    private static boolean hasExpectedSignature(String extension, byte[] h) {
        if (".pdf".equals(extension)) return starts(h, 0x25, 0x50, 0x44, 0x46, 0x2D);
        if (".jpg".equals(extension) || ".jpeg".equals(extension)) return starts(h, 0xFF, 0xD8, 0xFF);
        if (".png".equals(extension)) return starts(h, 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A);
        if (".doc".equals(extension) || ".ppt".equals(extension)) return starts(h, 0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1);
        return starts(h, 0x50, 0x4B, 0x03, 0x04) || starts(h, 0x50, 0x4B, 0x05, 0x06) || starts(h, 0x50, 0x4B, 0x07, 0x08);
    }
    private static boolean starts(byte[] actual, int... expected) {
        if (actual.length < expected.length) return false;
        for (int i = 0; i < expected.length; i++) if ((actual[i] & 0xFF) != expected[i]) return false;
        return true;
    }
}
