package com.internship;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;

@WebServlet("/SubmitInternshipServlet")
@MultipartConfig(fileSizeThreshold = 1024 * 1024, maxFileSize = 10 * 1024 * 1024, maxRequestSize = 60 * 1024 * 1024)
public class SubmitInternshipServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || !"student".equals(session.getAttribute("role"))) { response.sendRedirect("login.jsp"); return; }
        if (!CsrfToken.isValid(request, session)) { response.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid CSRF token."); return; }
        String studentId = sessionString(session, "student_id");
        String company = trim(request.getParameter("companyName"));
        String type = trim(request.getParameter("internshipType"));
        LocalDate start, end;
        try { start = LocalDate.parse(trim(request.getParameter("startDate"))); end = LocalDate.parse(trim(request.getParameter("endDate"))); }
        catch (Exception e) { fail(response, "date"); return; }
        if (studentId == null || company == null || company.isEmpty() || company.length() > 150 || end.isBefore(start)) { fail(response, "required"); return; }
        if (!("Stipend".equals(type) || "Non-Stipend".equals(type))) { fail(response, "type"); return; }

        Part offer, certificate, ppt, report, bank, proof;
        try { offer = request.getPart("offerLetter"); certificate = request.getPart("certificate"); ppt = request.getPart("ppt"); report = request.getPart("report"); bank = request.getPart("bankStatement"); proof = request.getPart("stipendProof"); }
        catch (Exception e) { fail(response, "documents"); return; }
        if (isMissing(offer) || isMissing(certificate) || isMissing(ppt) || isMissing(report)) { fail(response, "documents"); return; }
        if ("Stipend".equals(type) && (isMissing(bank) || isMissing(proof))) { fail(response, "stipenddocs"); return; }

        List<Path> created = new ArrayList<>();
        try {
            Path directory = ReplaceInternshipDocumentServlet.studentUploadDirectory(studentId);
            Files.createDirectories(directory);
            String offerPath = save(offer, directory, "offer_letter", created);
            String certificatePath = save(certificate, directory, "certificate", created);
            String pptPath = save(ppt, directory, "ppt_review", created);
            String reportPath = save(report, directory, "report", created);
            String bankPath = "Stipend".equals(type) ? save(bank, directory, "bank_statement", created) : null;
            String proofPath = "Stipend".equals(type) ? save(proof, directory, "stipend_proof", created) : null;
            String sql = "INSERT INTO internship (student_id, company_name, internship_type, start_date, end_date, offer_letter, certificate, ppt_review, report_file, bank_statement, stipend_proof, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Pending')";
            try (Connection con = DBConnector.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
                if (con == null) throw new IOException("Database unavailable");
                ps.setString(1, studentId); ps.setString(2, company); ps.setString(3, type); ps.setDate(4, Date.valueOf(start)); ps.setDate(5, Date.valueOf(end));
                ps.setString(6, offerPath); ps.setString(7, certificatePath); ps.setString(8, pptPath); ps.setString(9, reportPath); ps.setString(10, bankPath); ps.setString(11, proofPath);
                if (ps.executeUpdate() != 1) throw new IOException("Insert failed");
            }
            response.sendRedirect("student_dashboard.jsp?success=1");
        } catch (Exception e) {
            deleteCreated(created);
            getServletContext().log("Internship submission failed; newly created upload files were removed.", e);
            fail(response, "upload");
        }
    }

    private static String save(Part part, Path directory, String prefix, List<Path> created) throws IOException {
        String extension = InternshipUploadValidator.validate(part);
        Path destination = directory.resolve(prefix + "_" + UUID.randomUUID() + extension).normalize();
        if (!destination.startsWith(directory)) throw new IOException("Invalid upload path");
        try (var input = part.getInputStream()) { Files.copy(input, destination, StandardCopyOption.REPLACE_EXISTING); }
        created.add(destination);
        return directory.getFileName() + "/" + destination.getFileName();
    }
    private static void deleteCreated(List<Path> created) { for (Path path : created) try { Files.deleteIfExists(path); } catch (IOException ignored) { } }
    private static boolean isMissing(Part part) { return part == null || part.getSize() <= 0 || part.getSubmittedFileName() == null || part.getSubmittedFileName().trim().isEmpty(); }
    private static String sessionString(HttpSession s, String key) { Object value = s.getAttribute(key); return value == null || value.toString().trim().isEmpty() ? null : value.toString().trim(); }
    private static String trim(String value) { return value == null ? null : value.trim(); }
    private static void fail(HttpServletResponse response, String error) throws IOException { response.sendRedirect("student_dashboard.jsp?error=" + error); }
}
