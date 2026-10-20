package com.internship;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/LoginServlet")
public class LoginServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String username = request.getParameter("username");
        String password = request.getParameter("password");
        String role = request.getParameter("role");

        if (username == null || username.trim().isEmpty()
                || password == null || password.trim().isEmpty()
                || role == null || role.trim().isEmpty()) {
            response.sendRedirect("login.jsp?error=invalid");
            return;
        }

        username = username.trim();
        role = role.trim();
        AccountQuery accountQuery = AccountQuery.forRole(role);
        if (accountQuery == null) {
            response.sendRedirect("login.jsp?error=invalid");
            return;
        }

        try (Connection con = DBConnector.getConnection()) {
            if (con == null) {
                response.sendRedirect("login.jsp?error=database");
                return;
            }

            try (PreparedStatement ps = con.prepareStatement(accountQuery.selectSql)) {
                ps.setString(1, username);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        response.sendRedirect("login.jsp?error=invalid");
                        return;
                    }

                    String userId = rs.getString(accountQuery.idColumn);
                    String displayName = rs.getString(accountQuery.nameColumn);
                    String storedCredential = rs.getString("password");
                    if (!verifyCredentialAndMigrate(con, accountQuery, userId,
                            password, storedCredential)) {
                        response.sendRedirect("login.jsp?error=invalid");
                        return;
                    }

                    // Rotate the pre-authentication identifier so an attacker cannot fixate it.
                    HttpSession existingSession = request.getSession(false);
                    if (existingSession != null) {
                        existingSession.invalidate();
                    }
                    HttpSession session = request.getSession(true);
                    session.setAttribute("userId", userId);
                    session.setAttribute("role", role);
                    session.setAttribute("name", displayName);
                    if ("student".equals(role)) {
                        session.setAttribute("student_id", userId);
                    } else if ("staff".equals(role)) {
                        session.setAttribute("staff_id", userId);
                    }
                    CsrfToken.create(session);

                    if ("student".equals(role)) {
                        response.sendRedirect("student_dashboard.jsp");
                    } else if ("staff".equals(role)) {
                        response.sendRedirect("staff_dashboard.jsp");
                    } else {
                        response.sendRedirect("admin_dashboard.jsp");
                    }
                }
            }
        }
        catch (Exception e) {
            response.sendRedirect("login.jsp?error=database");
        }
    }

    private boolean verifyCredentialAndMigrate(Connection con, AccountQuery accountQuery,
            String userId, String submittedPassword, String storedCredential) throws Exception {
        if (PasswordHasher.isPbkdf2Candidate(storedCredential)) {
            return PasswordHasher.isValidPbkdf2Record(storedCredential)
                    && PasswordHasher.verify(submittedPassword, storedCredential);
        }

        if (!PasswordHasher.legacyMatches(submittedPassword, storedCredential)) {
            return false;
        }

        String migrationSql = "UPDATE " + accountQuery.tableName
                + " SET password=? WHERE " + accountQuery.idColumn + "=? AND password=?";
        try (PreparedStatement ps = con.prepareStatement(migrationSql)) {
            ps.setString(1, PasswordHasher.hashLegacyPassword(submittedPassword));
            ps.setString(2, userId);
            ps.setString(3, storedCredential);
            return ps.executeUpdate() == 1;
        }
    }

    private static final class AccountQuery {
        private final String tableName;
        private final String idColumn;
        private final String nameColumn;
        private final String selectSql;

        private AccountQuery(String tableName, String idColumn, String nameColumn) {
            this.tableName = tableName;
            this.idColumn = idColumn;
            this.nameColumn = nameColumn;
            this.selectSql = "SELECT " + idColumn + ", " + nameColumn
                    + ", password FROM " + tableName + " WHERE " + idColumn + "=?";
        }

        private static AccountQuery forRole(String role) {
            switch (role) {
                case "student":
                    return new AccountQuery("student", "student_id", "name");
                case "staff":
                    return new AccountQuery("staff", "staff_id", "name");
                case "admin":
                    return new AccountQuery("admin", "admin_id", "username");
                default:
                    return null;
            }
        }
    }
}
