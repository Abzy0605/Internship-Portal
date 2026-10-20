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

@WebServlet("/UpdateStudentServlet")
public class UpdateStudentServlet extends HttpServlet {
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
        boolean changePassword = password != null && !password.trim().isEmpty();
        if (changePassword && !PasswordHasher.isValidNewPassword(password)) {
            response.sendRedirect("manage_students.jsp?error=1");
            return;
        }

        String query = changePassword
                ? "UPDATE student SET name=?, department=?, email=?, password=? WHERE student_id=?"
                : "UPDATE student SET name=?, department=?, email=? WHERE student_id=?";
        try (Connection con = DBConnector.getConnection()) {
            if (con == null) {
                response.sendRedirect("manage_students.jsp?error=1");
                return;
            }
            try (PreparedStatement ps = con.prepareStatement(query)) {
                ps.setString(1, request.getParameter("name"));
                ps.setString(2, request.getParameter("department"));
                ps.setString(3, request.getParameter("email"));
                if (changePassword) {
                    ps.setString(4, PasswordHasher.hash(password));
                    ps.setString(5, request.getParameter("student_id"));
                } else {
                    ps.setString(4, request.getParameter("student_id"));
                }
                response.sendRedirect(ps.executeUpdate() > 0
                        ? "manage_students.jsp?updated=1" : "manage_students.jsp?error=1");
            }
        } catch (Exception e) {
            response.sendRedirect("manage_students.jsp?error=1");
        }
    }
}
