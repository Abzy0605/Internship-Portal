package com.internship;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/AddStudentServlet")
public class AddStudentServlet extends HttpServlet {
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

        String password = request.getParameter("password");
        if (!PasswordHasher.isValidNewPassword(password)) {
            response.sendRedirect("manage_students.jsp?error=1");
            return;
        }

        String query = "INSERT INTO student(student_id, name, department, email, password) VALUES (?, ?, ?, ?, ?)";
        try (Connection con = DBConnector.getConnection()) {
            if (con == null) {
                response.sendRedirect("manage_students.jsp?error=1");
                return;
            }
            try (PreparedStatement ps = con.prepareStatement(query)) {
                ps.setString(1, request.getParameter("student_id"));
                ps.setString(2, request.getParameter("name"));
                ps.setString(3, request.getParameter("department"));
                ps.setString(4, request.getParameter("email"));
                ps.setString(5, PasswordHasher.hash(password));
                response.sendRedirect(ps.executeUpdate() > 0
                        ? "manage_students.jsp?success=1" : "manage_students.jsp?error=1");
            }
        } catch (Exception e) {
            response.sendRedirect("manage_students.jsp?error=1");
        }
    }
}
