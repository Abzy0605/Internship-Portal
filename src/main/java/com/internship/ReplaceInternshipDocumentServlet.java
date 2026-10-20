package com.internship;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Map;
import java.util.UUID;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;

@WebServlet("/ReplaceInternshipDocumentServlet")
@MultipartConfig(fileSizeThreshold = 1024 * 1024, maxFileSize = 10 * 1024 * 1024,
        maxRequestSize = 12 * 1024 * 1024)
public class ReplaceInternshipDocumentServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Map<String, String> DOCUMENT_COLUMNS = Map.of(
            "offer_letter", "offer_letter", "certificate", "certificate",
            "ppt_review", "ppt_review", "report_file", "report_file",
            "bank_statement", "bank_statement", "stipend_proof", "stipend_proof");

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || !"student".equals(session.getAttribute("role"))) {
            response.sendRedirect("login.jsp");
            return;
        }
        if (!CsrfToken.isValid(request, session)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid CSRF token.");
            return;
        }
        String studentId = sessionValue(session, "student_id");
        int internshipId = parsePositiveInt(request.getParameter("internship_id"));
        String documentType = request.getParameter("document_type");
        String column = DOCUMENT_COLUMNS.get(documentType);
        if (studentId == null || internshipId == 0 || column == null) {
            redirect(response, internshipId, "invalid");
            return;
        }

        Part part;
        try { part = request.getPart("document"); }
        catch (Exception e) { redirect(response, internshipId, "file"); return; }
        if (isEmpty(part)) { redirect(response, internshipId, "missing"); return; }

        String oldPath;
        try (Connection con = DBConnector.getConnection();
                PreparedStatement ps = con.prepareStatement("SELECT " + column + " FROM internship "
                        + "WHERE internship_id=? AND student_id=? AND status IN ('Pending','Rejected')")) {
            if (con == null) throw new Exception("Database connection unavailable");
            ps.setInt(1, internshipId);
            ps.setString(2, studentId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) { redirect(response, internshipId, "locked"); return; }
                oldPath = rs.getString(column);
            }
        } catch (Exception e) { redirect(response, internshipId, "database"); return; }

        Path studentDirectory;
        Path newFile = null;
        try {
            studentDirectory = studentUploadDirectory(studentId);
            Files.createDirectories(studentDirectory);
            newFile = saveFile(part, studentDirectory, documentType);
            String storedPath = studentDirectory.getFileName() + "/" + newFile.getFileName();
            String update = "UPDATE internship SET " + column + "=? WHERE internship_id=? AND student_id=? "
                    + "AND status IN ('Pending','Rejected')";
            int rows;
            try (Connection con = DBConnector.getConnection(); PreparedStatement ps = con.prepareStatement(update)) {
                if (con == null) throw new Exception("Database connection unavailable");
                ps.setString(1, storedPath);
                ps.setInt(2, internshipId);
                ps.setString(3, studentId);
                rows = ps.executeUpdate();
            }
            if (rows != 1) {
                Files.deleteIfExists(newFile);
                redirect(response, internshipId, "locked");
                return;
            }
            // The database now owns the replacement. A cleanup failure must never remove it.
            try { deleteStoredFile(studentId, oldPath); }
            catch (IOException cleanupFailure) { getServletContext().log("Replacement succeeded but old document cleanup failed.", cleanupFailure); }
            response.sendRedirect("student_dashboard.jsp?success=document");
        } catch (Exception e) {
            if (newFile != null) {
                try { Files.deleteIfExists(newFile); } catch (IOException ignored) { }
            }
            redirect(response, internshipId, "file");
        }
    }

    static Path studentUploadDirectory(String studentId) throws IOException {
        Path base = Paths.get(System.getProperty("user.home"), "EEC_Internship_Uploads").toAbsolutePath().normalize();
        Path directory = base.resolve(studentId).normalize();
        if (!directory.startsWith(base)) throw new IOException("Invalid upload directory");
        return directory;
    }

    static void deleteStoredFile(String studentId, String storedPath) throws IOException {
        if (storedPath == null || storedPath.trim().isEmpty()) return;
        Path directory = studentUploadDirectory(studentId);
        Path relative = Paths.get(storedPath.replace('\\', '/')).normalize();
        if (relative.isAbsolute() || relative.getNameCount() != 2 || !studentId.equals(relative.getName(0).toString())) {
            throw new IOException("Unsafe stored file path");
        }
        Path file = directory.getParent().resolve(relative).normalize();
        if (!file.startsWith(directory) || !Files.isRegularFile(file)) throw new IOException("Stored file unavailable");
        Files.delete(file);
    }

    private static Path saveFile(Part part, Path directory, String prefix) throws IOException {
        String extension = InternshipUploadValidator.validate(part);
        Path destination = directory.resolve(prefix + "_" + UUID.randomUUID() + extension).normalize();
        if (!destination.startsWith(directory)) throw new IOException("Invalid upload path");
        try (InputStream input = part.getInputStream()) { Files.copy(input, destination, StandardCopyOption.REPLACE_EXISTING); }
        return destination;
    }
    private static boolean isEmpty(Part part) { return part == null || part.getSize() <= 0 || part.getSubmittedFileName() == null || part.getSubmittedFileName().trim().isEmpty(); }
    private static String sessionValue(HttpSession session, String name) { Object value = session.getAttribute(name); return value == null || value.toString().trim().isEmpty() ? null : value.toString().trim(); }
    private static int parsePositiveInt(String value) { try { int id = Integer.parseInt(value); return id > 0 ? id : 0; } catch (Exception e) { return 0; } }
    private static void redirect(HttpServletResponse response, int id, String error) throws IOException { response.sendRedirect("replace_internship_documents.jsp?internship_id=" + id + "&error=" + error); }
}
