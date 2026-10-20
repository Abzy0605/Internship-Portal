package com.internship;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Types;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/ManageStudentAssignmentsServlet")
public class ManageStudentAssignmentsServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || !"admin".equals(session.getAttribute("role"))) {
            response.sendRedirect("login.jsp");
            return;
        }

        if (!CsrfToken.isValid(request, session)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid CSRF token.");
            return;
        }

        String studentId = trim(request.getParameter("student_id"));
        String mentorId = trim(request.getParameter("mentor_id"));
        if (studentId == null || studentId.isEmpty()) {
            response.sendRedirect("manage_student_assignments.jsp?assignment=invalid");
            return;
        }

        try (Connection con = DBConnector.getConnection()) {
            if (con == null || !exists(con, "SELECT 1 FROM student WHERE student_id=?", studentId)) {
                response.sendRedirect("manage_student_assignments.jsp?assignment=student");
                return;
            }
            if (mentorId != null && !mentorId.isEmpty()
                    && !exists(con, "SELECT 1 FROM staff WHERE staff_id=?", mentorId)) {
                response.sendRedirect("manage_student_assignments.jsp?assignment=staff");
                return;
            }

            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE student SET mentor_id=? WHERE student_id=?")) {
                if (mentorId == null || mentorId.isEmpty()) {
                    ps.setNull(1, Types.VARCHAR);
                } else {
                    ps.setString(1, mentorId);
                }
                ps.setString(2, studentId);
                if (ps.executeUpdate() == 1) {
                    response.sendRedirect("manage_student_assignments.jsp?assignment=success");
                } else {
                    response.sendRedirect("manage_student_assignments.jsp?assignment=student");
                }
            }
        } catch (Exception e) {
            response.sendRedirect("manage_student_assignments.jsp?assignment=error");
        }
    }

    private boolean exists(Connection con, String query, String value) throws Exception {
        try (PreparedStatement ps = con.prepareStatement(query)) {
            ps.setString(1, value);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
