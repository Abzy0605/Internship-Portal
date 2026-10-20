package com.internship;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/ExportStaffReportsServlet")
public class ExportStaffReportsServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || !"staff".equals(session.getAttribute("role"))) {
            response.sendRedirect("login.jsp");
            return;
        }
        Object staffIdValue = session.getAttribute("staff_id");
        String staffId = (staffIdValue == null) ? null : staffIdValue.toString().trim();

        if (staffId == null || staffId.isEmpty()) {
            response.sendRedirect("login.jsp");
            return;
        }

        String statusParam = request.getParameter("status");
        String typeParam = request.getParameter("internship_type");
        String startDateParam = request.getParameter("start_date");
        String endDateParam = request.getParameter("end_date");

        String filterStatus = null;
        if ("Pending".equalsIgnoreCase(statusParam)) {
            filterStatus = "Pending";
        } else if ("Approved".equalsIgnoreCase(statusParam)) {
            filterStatus = "Approved";
        } else if ("Rejected".equalsIgnoreCase(statusParam)) {
            filterStatus = "Rejected";
        }

        String filterType = null;
        if ("Stipend".equalsIgnoreCase(typeParam)) {
            filterType = "Stipend";
        } else if ("Non-Stipend".equalsIgnoreCase(typeParam)) {
            filterType = "Non-Stipend";
        }

        LocalDate validStartDate = null;
        if (startDateParam != null && !startDateParam.trim().isEmpty()) {
            try {
                validStartDate = LocalDate.parse(startDateParam.trim());
            } catch (Exception ignored) {
            }
        }

        LocalDate validEndDate = null;
        if (endDateParam != null && !endDateParam.trim().isEmpty()) {
            try {
                validEndDate = LocalDate.parse(endDateParam.trim());
            } catch (Exception ignored) {
            }
        }

        StringBuilder queryBuilder = new StringBuilder(
                "SELECT s.student_id, s.name AS student_name, s.department, "
                + "i.company_name, i.internship_type, i.start_date, i.end_date, i.status, i.remarks "
                + "FROM internship i "
                + "JOIN student s ON i.student_id = s.student_id "
                + "WHERE s.mentor_id = ?"
        );

        List<Object> queryParams = new ArrayList<>();
        queryParams.add(staffId);

        if ("Pending".equals(filterStatus)) {
            queryBuilder.append(" AND (i.status = 'Pending' OR i.status IS NULL OR TRIM(i.status) = '')");
        } else if (filterStatus != null) {
            queryBuilder.append(" AND i.status = ?");
            queryParams.add(filterStatus);
        }

        if (filterType != null) {
            queryBuilder.append(" AND i.internship_type = ?");
            queryParams.add(filterType);
        }

        if (validStartDate != null) {
            queryBuilder.append(" AND i.start_date >= ?");
            queryParams.add(Date.valueOf(validStartDate));
        }

        if (validEndDate != null) {
            queryBuilder.append(" AND i.end_date <= ?");
            queryParams.add(Date.valueOf(validEndDate));
        }

        queryBuilder.append(" ORDER BY i.internship_id DESC");

        response.setContentType("text/csv; charset=UTF-8");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Content-Disposition", "attachment; filename=\"staff_internship_report.csv\"");

        try (PrintWriter out = response.getWriter()) {
            // Write UTF-8 BOM so Excel opens special characters seamlessly
            out.write('\uFEFF');

            // Header line
            out.println("Student ID,Student Name,Department,Company,Internship Type,Start Date,End Date,Status,Remarks");

            try (Connection con = DBConnector.getConnection();
                 PreparedStatement ps = con.prepareStatement(queryBuilder.toString())) {

                if (con == null) {
                    throw new IOException("Database connection unavailable");
                }

                for (int i = 0; i < queryParams.size(); i++) {
                    Object param = queryParams.get(i);
                    if (param instanceof String) {
                        ps.setString(i + 1, (String) param);
                    } else if (param instanceof Date) {
                        ps.setDate(i + 1, (Date) param);
                    }
                }

                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        String studentIdVal = rs.getString("student_id");
                        String studentName = rs.getString("student_name");
                        String department = rs.getString("department");
                        String companyName = rs.getString("company_name");
                        String internshipType = rs.getString("internship_type");
                        Date startDate = rs.getDate("start_date");
                        Date endDate = rs.getDate("end_date");
                        String rowStatus = rs.getString("status");
                        String remarks = rs.getString("remarks");

                        if (rowStatus == null || rowStatus.trim().isEmpty()) {
                            rowStatus = "Pending";
                        }
                        if (remarks == null) {
                            remarks = "";
                        }

                        out.print(escapeCsv(studentIdVal));
                        out.print(",");
                        out.print(escapeCsv(studentName));
                        out.print(",");
                        out.print(escapeCsv(department));
                        out.print(",");
                        out.print(escapeCsv(companyName));
                        out.print(",");
                        out.print(escapeCsv(internshipType));
                        out.print(",");
                        out.print(escapeCsv(startDate != null ? startDate.toString() : ""));
                        out.print(",");
                        out.print(escapeCsv(endDate != null ? endDate.toString() : ""));
                        out.print(",");
                        out.print(escapeCsv(rowStatus));
                        out.print(",");
                        out.print(escapeCsv(remarks));
                        out.println();
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    private static String escapeCsv(String value) {
        if (value == null) {
            return "";
        }
        String s = value;
        // Formula injection mitigation: prepend single quote if cell starts with sensitive characters
        if (!s.isEmpty()) {
            char first = s.charAt(0);
            if (first == '=' || first == '+' || first == '-' || first == '@') {
                s = "'" + s;
            }
        }
        // If content contains comma, quote, newline or leading single quote, quote the cell and double inner quotes
        if (s.contains("\"") || s.contains(",") || s.contains("\n") || s.contains("\r") || s.startsWith("'")) {
            return "\"" + s.replace("\"", "\"\"") + "\"";
        }
        return s;
    }
}
