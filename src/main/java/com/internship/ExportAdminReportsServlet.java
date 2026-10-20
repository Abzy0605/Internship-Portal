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

@WebServlet("/ExportAdminReportsServlet")
public class ExportAdminReportsServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || !"admin".equals(session.getAttribute("role"))) {
            response.sendRedirect("login.jsp");
            return;
        }

        String searchParam = request.getParameter("search");
        String search = (searchParam != null) ? searchParam.trim() : null;
        if (search != null && search.isEmpty()) {
            search = null;
        }

        String departmentParam = request.getParameter("department");
        String filterDepartment = (departmentParam != null && !departmentParam.trim().isEmpty())
                ? departmentParam.trim() : null;

        String mentorParam = request.getParameter("mentor_id");
        String filterMentorId = (mentorParam != null && !mentorParam.trim().isEmpty())
                ? mentorParam.trim() : null;

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
                + "m.name AS mentor_name, "
                + "i.company_name, i.internship_type, i.start_date, i.end_date, i.status, i.remarks "
                + "FROM internship i "
                + "JOIN student s ON i.student_id = s.student_id "
                + "LEFT JOIN staff m ON s.mentor_id = m.staff_id "
                + "WHERE 1=1"
        );

        List<Object> queryParams = new ArrayList<>();

        if (search != null) {
            queryBuilder.append(" AND (s.student_id LIKE ? OR s.name LIKE ? OR s.department LIKE ? OR i.company_name LIKE ?)");
            String searchPattern = "%" + search + "%";
            queryParams.add(searchPattern);
            queryParams.add(searchPattern);
            queryParams.add(searchPattern);
            queryParams.add(searchPattern);
        }

        if (filterDepartment != null) {
            queryBuilder.append(" AND s.department = ?");
            queryParams.add(filterDepartment);
        }

        if (filterMentorId != null) {
            queryBuilder.append(" AND s.mentor_id = ?");
            queryParams.add(filterMentorId);
        }

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
        response.setHeader("Content-Disposition", "attachment; filename=\"admin_internship_report.csv\"");

        try (PrintWriter out = response.getWriter()) {
            out.write('\uFEFF');

            out.println("Student ID,Student Name,Department,Mentor,Company,Internship Type,Start Date,End Date,Status,Remarks");

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
                        String mentorName = rs.getString("mentor_name");
                        String companyName = rs.getString("company_name");
                        String internshipType = rs.getString("internship_type");
                        Date startDate = rs.getDate("start_date");
                        Date endDate = rs.getDate("end_date");
                        String rowStatus = rs.getString("status");
                        String remarks = rs.getString("remarks");

                        if (rowStatus == null || rowStatus.trim().isEmpty()) {
                            rowStatus = "Pending";
                        }
                        if (mentorName == null || mentorName.trim().isEmpty()) {
                            mentorName = "Unassigned";
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
                        out.print(escapeCsv(mentorName));
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
        if (!s.isEmpty()) {
            char first = s.charAt(0);
            if (first == '=' || first == '+' || first == '-' || first == '@') {
                s = "'" + s;
            }
        }
        if (s.contains("\"") || s.contains(",") || s.contains("\n") || s.contains("\r") || s.startsWith("'")) {
            return "\"" + s.replace("\"", "\"\"") + "\"";
        }
        return s;
    }
}