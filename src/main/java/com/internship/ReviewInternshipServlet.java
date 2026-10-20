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

@WebServlet("/ReviewInternshipServlet")
public class ReviewInternshipServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null ||
            !"staff".equals(session.getAttribute("role"))) {

            response.sendRedirect("login.jsp");
            return;
        }

        if (!CsrfToken.isValid(request, session)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid CSRF token.");
            return;
        }

        Object staffIdValue = session.getAttribute("staff_id");
        String staffId = staffIdValue == null ? null
                : staffIdValue.toString().trim();

        if (staffId == null || staffId.isEmpty()) {
            response.sendRedirect("login.jsp");
            return;
        }

        String internshipIdParameter =
                request.getParameter("internship_id");
        String status = request.getParameter("status");
        String remarks = request.getParameter("remarks");
        boolean returnToReviews =
                "reviews".equals(request.getParameter("return_to"));
        String returnPage = returnToReviews
                ? "staff_internship_reviews.jsp"
                : "staff_dashboard.jsp";

        int internshipId;

        try {
            internshipId = Integer.parseInt(internshipIdParameter);
        }
        catch (Exception e) {
            response.sendRedirect(returnPage + "?review=invalid");
            return;
        }

        if (internshipId <= 0 ||
            (!"Approved".equals(status) &&
             !"Rejected".equals(status))) {

            response.sendRedirect(
                returnPage + "?review=invalid&internship_id="
                + internshipId
            );
            return;
        }

        if (remarks != null) {
            remarks = remarks.trim();
        }

        String updateQuery =
                "UPDATE internship i "
                + "JOIN student s ON i.student_id=s.student_id "
                + "SET i.status=?, i.remarks=? "
                + "WHERE i.internship_id=? AND s.mentor_id=? AND i.status='Pending'";

        try (
            Connection con = DBConnector.getConnection();
            PreparedStatement ps = con.prepareStatement(updateQuery)
        ) {
            ps.setString(1, status);
            ps.setString(2, remarks);
            ps.setInt(3, internshipId);
            ps.setString(4, staffId);

            int rows = ps.executeUpdate();

            if (rows > 0) {
                response.sendRedirect(
                    returnPage + "?review=success&internship_id="
                    + internshipId
                );
            }
            else {
                response.sendRedirect(
                    returnPage + "?review=notfound&internship_id="
                    + internshipId
                );
            }
        }
        catch (Exception e) {
            getServletContext().log("Unable to update internship review.", e);
            response.sendRedirect(
                returnPage + "?review=error&internship_id="
                + internshipId
            );
        }
    }
}
