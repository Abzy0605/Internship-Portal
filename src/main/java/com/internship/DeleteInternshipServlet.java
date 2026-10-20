package com.internship;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/DeleteInternshipServlet")
public class DeleteInternshipServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final String[] FILE_COLUMNS = { "offer_letter", "certificate", "ppt_review", "report_file", "bank_statement", "stipend_proof" };

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || !"student".equals(session.getAttribute("role"))) { response.sendRedirect("login.jsp"); return; }
        if (!CsrfToken.isValid(request, session)) { response.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid CSRF token."); return; }
        Object value = session.getAttribute("student_id");
        String studentId = value == null ? null : value.toString().trim();
        int internshipId;
        try { internshipId = Integer.parseInt(request.getParameter("internship_id")); } catch (Exception e) { internshipId = 0; }
        if (studentId == null || studentId.isEmpty() || internshipId <= 0) { response.sendRedirect("student_dashboard.jsp?error=deleteinvalid"); return; }

        List<String> storedPaths = new ArrayList<>();
        try (Connection con = DBConnector.getConnection(); PreparedStatement ps = con.prepareStatement(
                "SELECT offer_letter, certificate, ppt_review, report_file, bank_statement, stipend_proof FROM internship "
                + "WHERE internship_id=? AND student_id=? AND status IN ('Pending','Rejected')")) {
            if (con == null) throw new Exception("Database connection unavailable");
            ps.setInt(1, internshipId); ps.setString(2, studentId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) { response.sendRedirect("student_dashboard.jsp?error=deletelocked"); return; }
                for (String column : FILE_COLUMNS) storedPaths.add(rs.getString(column));
            }
        } catch (Exception e) { response.sendRedirect("student_dashboard.jsp?error=deletedatabase"); return; }

        List<StagedFile> stagedFiles = new ArrayList<>();
        try {
            for (String storedPath : storedPaths) {
                StagedFile staged = stageStoredFile(studentId, storedPath);
                if (staged != null) stagedFiles.add(staged);
            }
        } catch (Exception e) {
            restoreStagedFiles(stagedFiles);
            response.sendRedirect("student_dashboard.jsp?error=deletefiles");
            return;
        }

        try (Connection con = DBConnector.getConnection(); PreparedStatement ps = con.prepareStatement(
                "DELETE FROM internship WHERE internship_id=? AND student_id=? AND status IN ('Pending','Rejected')")) {
            if (con == null) throw new Exception("Database connection unavailable");
            ps.setInt(1, internshipId); ps.setString(2, studentId);
            if (ps.executeUpdate() != 1) {
                restoreStagedFiles(stagedFiles);
                response.sendRedirect("student_dashboard.jsp?error=deletelocked");
                return;
            }
        } catch (Exception e) {
            restoreStagedFiles(stagedFiles);
            response.sendRedirect("student_dashboard.jsp?error=deletedatabase");
            return;
        }

        boolean fileIssue = false;
        for (StagedFile staged : stagedFiles) {
            try { Files.deleteIfExists(staged.stagedPath); }
            catch (Exception e) { fileIssue = true; }
        }
        response.sendRedirect(fileIssue ? "student_dashboard.jsp?success=deletedfiles" : "student_dashboard.jsp?success=deleted");
    }

    private static StagedFile stageStoredFile(String studentId, String storedPath) throws IOException {
        if (storedPath == null || storedPath.trim().isEmpty()) return null;
        Path directory = ReplaceInternshipDocumentServlet.studentUploadDirectory(studentId);
        Path relative = Path.of(storedPath.replace('\\', '/')).normalize();
        if (relative.isAbsolute() || relative.getNameCount() != 2 || !studentId.equals(relative.getName(0).toString())) {
            throw new IOException("Unsafe stored file path");
        }
        Path original = directory.getParent().resolve(relative).normalize();
        if (!original.startsWith(directory) || !Files.isRegularFile(original)) throw new IOException("Stored file unavailable");
        Path stagingDirectory = directory.resolve(".delete_pending").normalize();
        if (!stagingDirectory.startsWith(directory)) throw new IOException("Unsafe staging path");
        Files.createDirectories(stagingDirectory);
        Path staged = stagingDirectory.resolve(UUID.randomUUID() + "_" + original.getFileName()).normalize();
        Files.move(original, staged, StandardCopyOption.ATOMIC_MOVE);
        return new StagedFile(original, staged);
    }

    private static void restoreStagedFiles(List<StagedFile> stagedFiles) {
        for (StagedFile staged : stagedFiles) {
            try { if (Files.exists(staged.stagedPath)) Files.move(staged.stagedPath, staged.originalPath); }
            catch (IOException ignored) { }
        }
    }

    private static class StagedFile {
        private final Path originalPath;
        private final Path stagedPath;
        private StagedFile(Path originalPath, Path stagedPath) { this.originalPath = originalPath; this.stagedPath = stagedPath; }
    }
}
