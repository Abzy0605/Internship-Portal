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

@WebServlet("/UpdateStaffServlet")
public class UpdateStaffServlet extends HttpServlet {
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
            response.sendRedirect("manage_staff.jsp?error=1");
            return;
        }

        String query = changePassword
                ? "UPDATE staff SET name=?, department=?, email=?, password=? WHERE staff_id=?"
                : "UPDATE staff SET name=?, department=?, email=? WHERE staff_id=?";
        try (Connection con = DBConnector.getConnection()) {
            if (con == null) {
                response.sendRedirect("manage_staff.jsp?error=1");
                return;
            }
            try (PreparedStatement ps = con.prepareStatement(query)) {
                ps.setString(1, request.getParameter("name"));
                ps.setString(2, request.getParameter("department"));
                ps.setString(3, request.getParameter("email"));
                if (changePassword) {
                    ps.setString(4, PasswordHasher.hash(password));
                    ps.setString(5, request.getParameter("staff_id"));
                } else {
                    ps.setString(4, request.getParameter("staff_id"));
                }
                response.sendRedirect(ps.executeUpdate() > 0
                        ? "manage_staff.jsp?updated=1" : "manage_staff.jsp?error=1");
            }
        } catch (Exception e) {
            response.sendRedirect("manage_staff.jsp?error=1");
        }
    }
}
