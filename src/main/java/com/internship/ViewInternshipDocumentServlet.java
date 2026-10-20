package com.internship;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Map;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/ViewInternshipDocumentServlet")
public class ViewInternshipDocumentServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private static final Map<String, String> DOCUMENT_COLUMNS = Map.of(
            "offer_letter", "offer_letter", "certificate", "certificate",
            "ppt_review", "ppt_review", "report_file", "report_file",
            "bank_statement", "bank_statement", "stipend_proof", "stipend_proof");

    private static final Map<String, String> CONTENT_TYPES = Map.of(
            ".pdf", "application/pdf", ".doc", "application/msword",
            ".docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            ".ppt", "application/vnd.ms-powerpoint",
            ".pptx", "application/vnd.openxmlformats-officedocument.presentationml.presentation",
            ".jpg", "image/jpeg", ".jpeg", "image/jpeg", ".png", "image/png");

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Login is required.");
            return;
        }

        String role = stringSessionValue(session, "role");
        if (!("student".equals(role) || "staff".equals(role) || "admin".equals(role))) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "You are not authorized to view this document.");
            return;
        }

        String staffId = null;
        if ("staff".equals(role)) {
            staffId = stringSessionValue(session, "staff_id");
            if (staffId == null) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You are not authorized to view this document.");
                return;
            }
        }

        int internshipId = parsePositiveInt(request.getParameter("internship_id"));
        String documentKey = request.getParameter("document_type");
        String column = DOCUMENT_COLUMNS.get(documentKey);
        if (internshipId == 0 || column == null) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid document request.");
            return;
        }

        String recordStudentId;
        String storedPath;
        String documentQuery = "staff".equals(role)
                ? "SELECT i.student_id, i." + column + " FROM internship i "
                        + "JOIN student s ON i.student_id=s.student_id "
                        + "WHERE i.internship_id=? AND s.mentor_id=?"
                : "SELECT student_id, " + column + " FROM internship WHERE internship_id=?";
        try (Connection con = DBConnector.getConnection();
                PreparedStatement ps = con.prepareStatement(documentQuery)) {
            if (con == null) {
                throw new IOException("Database connection unavailable");
            }
            ps.setInt(1, internshipId);
            if ("staff".equals(role)) {
                ps.setString(2, staffId);
            }
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    response.sendError(HttpServletResponse.SC_NOT_FOUND, "Internship record was not found.");
                    return;
                }
                recordStudentId = rs.getString("student_id");
                storedPath = rs.getString(column);
            }
        } catch (IOException e) {
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Unable to retrieve the document.");
            return;
        } catch (Exception e) {
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Unable to retrieve the document.");
            return;
        }

        if ("student".equals(role)) {
            String sessionStudentId = stringSessionValue(session, "student_id");
            if (sessionStudentId == null || !sessionStudentId.equals(recordStudentId)) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You are not authorized to view this document.");
                return;
            }
        }
        // Staff access is constrained in the SQL query by student.mentor_id.
        // Administrators may view all internship documents.

        if (storedPath == null || storedPath.trim().isEmpty()) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "This document has not been uploaded.");
            return;
        }

        Path document;
        String extension;
        try {
            document = resolveStoredDocument(recordStudentId, storedPath);
            extension = extensionOf(document.getFileName().toString());
        } catch (Exception e) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "Document file was not found.");
            return;
        }

        String contentType = CONTENT_TYPES.get(extension);
        if (contentType == null) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "Document file was not available.");
            return;
        }

        response.setContentType(contentType);
        response.setContentLengthLong(Files.size(document));
        String safeDownloadName = "internship-" + internshipId + "-" + documentKey + extension;
        boolean canOpenInline = ".pdf".equals(extension) || ".jpg".equals(extension)
                || ".jpeg".equals(extension) || ".png".equals(extension);
        response.setHeader("Content-Disposition", (canOpenInline ? "inline" : "attachment")
                + "; filename=\"" + safeDownloadName + "\"");
        Files.copy(document, response.getOutputStream());
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED, "GET is required for document viewing.");
    }

    private static Path resolveStoredDocument(String studentId, String storedPath) throws IOException {
        Path studentDirectory = ReplaceInternshipDocumentServlet.studentUploadDirectory(studentId);
        Path relative = Paths.get(storedPath.replace('\\', '/')).normalize();
        if (relative.isAbsolute() || relative.getNameCount() != 2
                || !studentId.equals(relative.getName(0).toString())) {
            throw new IOException("Unsafe document path");
        }
        Path file = studentDirectory.getParent().resolve(relative).normalize();
        if (!file.startsWith(studentDirectory) || !Files.isRegularFile(file)) {
            throw new IOException("Document file unavailable");
        }
        return file;
    }

    private static String extensionOf(String fileName) {
        int index = fileName.lastIndexOf('.');
        return index >= 0 ? fileName.substring(index).toLowerCase() : "";
    }

    private static int parsePositiveInt(String value) {
        try {
            int id = Integer.parseInt(value);
            return id > 0 ? id : 0;
        } catch (Exception e) {
            return 0;
        }
    }

    private static String stringSessionValue(HttpSession session, String name) {
        Object value = session.getAttribute(name);
        return value == null || value.toString().trim().isEmpty() ? null : value.toString().trim();
    }
}
