package com.internship;

import java.io.IOException;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.time.LocalDate;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/EditInternshipServlet")
public class EditInternshipServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

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

        String studentId = stringSessionValue(session, "student_id");
        int internshipId = parsePositiveInt(request.getParameter("internship_id"));
        String companyName = trim(request.getParameter("companyName"));
        String internshipType = trim(request.getParameter("internshipType"));
        String startDateText = trim(request.getParameter("startDate"));
        String endDateText = trim(request.getParameter("endDate"));

        if (studentId == null || internshipId == 0 || companyName == null || companyName.isEmpty()
                || companyName.length() > 150 || !("Stipend".equals(internshipType)
                || "Non-Stipend".equals(internshipType))) {
            redirect(response, internshipId, "invalid");
            return;
        }

        LocalDate startDate;
        LocalDate endDate;
        try {
            startDate = LocalDate.parse(startDateText);
            endDate = LocalDate.parse(endDateText);
        } catch (Exception e) {
            redirect(response, internshipId, "date");
            return;
        }
        if (endDate.isBefore(startDate)) {
            redirect(response, internshipId, "dateorder");
            return;
        }

        String query = "UPDATE internship SET company_name=?, internship_type=?, start_date=?, end_date=? "
                + "WHERE internship_id=? AND student_id=? AND status IN ('Pending','Rejected')";
        try (Connection con = DBConnector.getConnection();
                PreparedStatement ps = con.prepareStatement(query)) {
            if (con == null) {
                throw new Exception("Database connection unavailable");
            }
            ps.setString(1, companyName);
            ps.setString(2, internshipType);
            ps.setDate(3, Date.valueOf(startDate));
            ps.setDate(4, Date.valueOf(endDate));
            ps.setInt(5, internshipId);
            ps.setString(6, studentId);
            if (ps.executeUpdate() == 1) {
                response.sendRedirect("student_dashboard.jsp?success=updated");
            } else {
                redirect(response, internshipId, "locked");
            }
        } catch (Exception e) {
            redirect(response, internshipId, "database");
        }
    }

    private static String stringSessionValue(HttpSession session, String name) {
        Object value = session.getAttribute(name);
        return value == null || value.toString().trim().isEmpty() ? null : value.toString().trim();
    }

    private static String trim(String value) { return value == null ? null : value.trim(); }
    private static int parsePositiveInt(String value) {
        try { int id = Integer.parseInt(value); return id > 0 ? id : 0; }
        catch (Exception e) { return 0; }
    }
    private static void redirect(HttpServletResponse response, int id, String error) throws IOException {
        response.sendRedirect("edit_internship.jsp?internship_id=" + id + "&error=" + error);
    }
}
