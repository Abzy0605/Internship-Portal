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

@WebServlet("/DeleteStudentServlet")
public class DeleteStudentServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null ||
            !"admin".equals(session.getAttribute("role"))) {

            response.sendRedirect("login.jsp");
            return;
        }

        if (!CsrfToken.isValid(request, session)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid CSRF token.");
            return;
        }

        String studentId = request.getParameter("student_id");

        try {

            Connection con = DBConnector.getConnection();

            String query =
                    "DELETE FROM student WHERE student_id=?";

            PreparedStatement ps =
                    con.prepareStatement(query);

            ps.setString(1, studentId);

            int rows = ps.executeUpdate();

            ps.close();
            con.close();

            if(rows > 0) {

                response.sendRedirect(
                        "manage_students.jsp?deleted=1");

            }
            else {

                response.sendRedirect(
                        "manage_students.jsp?error=1");

            }

        }
        catch(Exception e) {

            e.printStackTrace();

            response.sendRedirect(
                    "manage_students.jsp?error=1");

        }

    }

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        response.sendError(
                HttpServletResponse.SC_METHOD_NOT_ALLOWED,
                "POST is required for student deletion."
        );
    }

}
