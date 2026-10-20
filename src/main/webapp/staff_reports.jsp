<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="com.internship.DBConnector" %>
<%@ page import="com.internship.CsrfToken" %>

<%!
private String escapeHtml(String value) {
    if (value == null) return "";
    return value.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
}
%>

<%
String role = (String) session.getAttribute("role");

if (role == null || !role.equals("staff")) {
    response.sendRedirect("login.jsp");
    return;
}

String staffId = (String) session.getAttribute("staff_id");

if (staffId == null || staffId.trim().isEmpty()) {
    response.sendRedirect("login.jsp");
    return;
}
String csrfToken = CsrfToken.getOrCreate(session);

int assignedStudentsCount = 0;
int totalInternships = 0;
int pendingCount = 0;
int approvedCount = 0;
int rejectedCount = 0;
int stipendCount = 0;
int nonStipendCount = 0;
boolean databaseError = false;

// Read filter parameters
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

List<Map<String, String>> reportList = new ArrayList<Map<String, String>>();

try (Connection con = DBConnector.getConnection()) {
    if (con == null) {
        throw new SQLException("Database connection unavailable");
    }

    // 1. Query Assigned Students count
    String studentCountQuery = "SELECT COUNT(*) FROM student WHERE mentor_id = ?";
    try (PreparedStatement ps = con.prepareStatement(studentCountQuery)) {
        ps.setString(1, staffId);
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                assignedStudentsCount = rs.getInt(1);
            }
        }
    }

    // 2. Query Internship Metrics (single aggregate query scoped by mentor_id)
    String statsQuery =
        "SELECT "
        + "COUNT(*) AS total_internships, "
        + "SUM(CASE WHEN i.status = 'Pending' OR i.status IS NULL OR TRIM(i.status) = '' THEN 1 ELSE 0 END) AS pending_count, "
        + "SUM(CASE WHEN i.status = 'Approved' THEN 1 ELSE 0 END) AS approved_count, "
        + "SUM(CASE WHEN i.status = 'Rejected' THEN 1 ELSE 0 END) AS rejected_count, "
        + "SUM(CASE WHEN i.internship_type = 'Stipend' THEN 1 ELSE 0 END) AS stipend_count, "
        + "SUM(CASE WHEN i.internship_type = 'Non-Stipend' THEN 1 ELSE 0 END) AS non_stipend_count "
        + "FROM internship i "
        + "JOIN student s ON i.student_id = s.student_id "
        + "WHERE s.mentor_id = ?";

    try (PreparedStatement ps = con.prepareStatement(statsQuery)) {
        ps.setString(1, staffId);
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                totalInternships = rs.getInt("total_internships");
                pendingCount = rs.getInt("pending_count");
                approvedCount = rs.getInt("approved_count");
                rejectedCount = rs.getInt("rejected_count");
                stipendCount = rs.getInt("stipend_count");
                nonStipendCount = rs.getInt("non_stipend_count");
            }
        }
    }

    // 3. Query Detailed Internship Reports with dynamic filters
    StringBuilder queryBuilder = new StringBuilder(
        "SELECT i.internship_id, s.student_id, s.name AS student_name, s.department, "
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
        queryParams.add(java.sql.Date.valueOf(validStartDate));
    }

    if (validEndDate != null) {
        queryBuilder.append(" AND i.end_date <= ?");
        queryParams.add(java.sql.Date.valueOf(validEndDate));
    }

    queryBuilder.append(" ORDER BY i.internship_id DESC");

    try (PreparedStatement ps = con.prepareStatement(queryBuilder.toString())) {
        for (int i = 0; i < queryParams.size(); i++) {
            Object param = queryParams.get(i);
            if (param instanceof String) {
                ps.setString(i + 1, (String) param);
            } else if (param instanceof java.sql.Date) {
                ps.setDate(i + 1, (java.sql.Date) param);
            }
        }

        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, String> record = new HashMap<String, String>();
                record.put("student_id", rs.getString("student_id"));
                record.put("student_name", rs.getString("student_name"));
                record.put("department", rs.getString("department"));
                record.put("company_name", rs.getString("company_name"));
                record.put("internship_type", rs.getString("internship_type"));
                java.sql.Date sDate = rs.getDate("start_date");
                record.put("start_date", sDate != null ? sDate.toString() : "");
                java.sql.Date eDate = rs.getDate("end_date");
                record.put("end_date", eDate != null ? eDate.toString() : "");
                String st = rs.getString("status");
                if (st == null || st.trim().isEmpty()) {
                    st = "Pending";
                }
                record.put("status", st);
                String rem = rs.getString("remarks");
                record.put("remarks", rem != null ? rem : "");

                reportList.add(record);
            }
        }
    }
} catch (Exception e) {
    e.printStackTrace();
    databaseError = true;
}

// Build Export CSV URL
StringBuilder exportParams = new StringBuilder();
if (filterStatus != null) {
    exportParams.append("status=").append(java.net.URLEncoder.encode(filterStatus, "UTF-8")).append("&");
}
if (filterType != null) {
    exportParams.append("internship_type=").append(java.net.URLEncoder.encode(filterType, "UTF-8")).append("&");
}
if (validStartDate != null) {
    exportParams.append("start_date=").append(java.net.URLEncoder.encode(validStartDate.toString(), "UTF-8")).append("&");
}
if (validEndDate != null) {
    exportParams.append("end_date=").append(java.net.URLEncoder.encode(validEndDate.toString(), "UTF-8")).append("&");
}
String exportUrl = "ExportStaffReportsServlet" + (exportParams.length() > 0 ? "?" + exportParams.substring(0, exportParams.length() - 1) : "");
%>

<!DOCTYPE html>
<html lang="en">

<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Staff Reports | EEC Internship Portal</title>

<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

<style>
body {
    background: #f5f7fb;
    font-family: 'Segoe UI', sans-serif;
    color: #30313a;
    overflow-x: hidden;
}

/* SIDEBAR */
.sidebar {
    position: fixed;
    top: 0;
    left: 0;
    width: 260px;
    height: 100vh;
    background: #6b1d1d;
    color: white;
    padding: 25px;
}

.logo-section {
    text-align: center;
    margin-bottom: 35px;
}

.logo-section img {
    width: 70px;
    height: 70px;
    object-fit: contain;
    background: white;
    border-radius: 12px;
    padding: 5px;
}

.college-title {
    margin-top: 15px;
    font-size: 18px;
    font-weight: 700;
}

.portal-text {
    font-size: 13px;
    opacity: .85;
}

.sidebar-menu {
    margin-top: 30px;
}

.sidebar-menu a {
    display: block;
    padding: 14px 18px;
    color: white;
    text-decoration: none;
    border-radius: 10px;
    margin-bottom: 10px;
    transition: .3s;
}

.sidebar-menu a:hover,
.active-link {
    background: rgba(255, 255, 255, .15);
}

.sidebar-menu i {
    margin-right: 10px;
}

.sidebar-footer {
    position: absolute;
    bottom: 25px;
    left: 25px;
    font-size: 13px;
    opacity: .9;
}

/* MAIN CONTENT */
.main-content {
    margin-left: 260px;
    padding: 30px;
}

.topbar {
    background: white;
    border-radius: 18px;
    padding: 22px 28px;
    box-shadow: 0 3px 15px rgba(0, 0, 0, .08);
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.page-title {
    font-size: 28px;
    font-weight: 700;
    margin: 0;
}

.staff-badge {
    background: #6b1d1d;
    color: white;
    padding: 8px 18px;
    border-radius: 25px;
    font-size: 14px;
}

/* METRIC CARDS */
.stats-card {
    background: white;
    border: none;
    border-radius: 18px;
    padding: 22px 24px;
    box-shadow: 0 3px 15px rgba(0, 0, 0, .08);
    transition: .3s;
    height: 100%;
}

.stats-card:hover {
    transform: translateY(-4px);
}

.stats-icon {
    font-size: 32px;
    color: #6b1d1d;
}

.stats-number {
    font-size: 28px;
    font-weight: 700;
    margin-top: 6px;
    color: #222;
}

.stats-label {
    color: #777;
    font-size: 13px;
    margin-top: 2px;
}

/* CARDS & TABLES */
.content-card {
    background: white;
    border-radius: 18px;
    padding: 25px;
    box-shadow: 0 3px 15px rgba(0, 0, 0, .08);
}

.section-title {
    font-size: 20px;
    font-weight: 700;
}

.report-table thead th {
    background: #6b1d1d;
    color: white;
    border: none;
    padding: 14px;
    white-space: nowrap;
    font-weight: 600;
    font-size: 14px;
}

.report-table tbody td {
    vertical-align: middle;
    padding: 13px 14px;
    font-size: 14px;
}

.report-table tbody tr:hover {
    background: #fafafa;
}

/* BADGES */
.badge-pending {
    background: #fff3cd;
    color: #856404;
    padding: 6px 12px;
    border-radius: 20px;
    font-size: 12px;
    font-weight: 600;
}

.badge-approved {
    background: #d1e7dd;
    color: #0f5132;
    padding: 6px 12px;
    border-radius: 20px;
    font-size: 12px;
    font-weight: 600;
}

.badge-rejected {
    background: #f8d7da;
    color: #842029;
    padding: 6px 12px;
    border-radius: 20px;
    font-size: 12px;
    font-weight: 600;
}

.btn-portal {
    background: #6b1d1d;
    border-color: #6b1d1d;
    color: white;
}

.btn-portal:hover {
    background: #521616;
    border-color: #521616;
    color: white;
}

/* RESPONSIVE */
@media (max-width: 991px) {
    .sidebar {
        width: 220px;
    }
    .main-content {
        margin-left: 220px;
    }
}

@media (max-width: 768px) {
    .sidebar {
        position: relative;
        width: 100%;
        height: auto;
    }
    .sidebar-footer {
        position: relative;
        bottom: auto;
        left: auto;
        margin-top: 20px;
    }
    .main-content {
        margin-left: 0;
        padding: 20px;
    }
}
</style>
</head>

<body>

<!-- SIDEBAR -->
<aside class="sidebar">
    <div class="logo-section">
        <img src="images/EEC_logo.png" alt="EEC Logo">
        <div class="college-title">EEC</div>
        <div class="portal-text">Internship Management System</div>
    </div>

    <nav class="sidebar-menu">
        <a href="staff_dashboard.jsp">
            <i class="bi bi-speedometer2"></i> Dashboard
        </a>
        <a href="staff_internship_reviews.jsp">
            <i class="bi bi-file-earmark-check"></i> Internship Reviews
        </a>
        <a href="staff_assigned_students.jsp">
            <i class="bi bi-people-fill"></i> Assigned Students
        </a>
        <a href="staff_reports.jsp" class="active-link">
            <i class="bi bi-bar-chart-line-fill"></i> Reports
        </a>
        <form action="LogoutServlet" method="post"><input type="hidden" name="csrfToken" value="<%= csrfToken %>"><button type="submit" class="btn btn-link text-white p-0"><i class="bi bi-box-arrow-right"></i> Logout</button></form>
    </nav>

    <div class="sidebar-footer">
        <strong>Faculty Mentor</strong><br>
        Staff Account
    </div>
</aside>

<!-- MAIN CONTENT -->
<main class="main-content">

    <!-- TOPBAR -->
    <div class="topbar">
        <div>
            <h1 class="page-title">Staff Reports</h1>
            <p class="text-muted mb-0 mt-1">Internship tracking, progress analytics, and exportable reports</p>
        </div>
        <div class="staff-badge">
            Faculty Mentor
        </div>
    </div>

    <% if (databaseError) { %>
        <div class="alert alert-danger mt-4">
            <i class="bi bi-exclamation-triangle-fill me-2"></i>
            Unable to load report data from the database. Please try again later.
        </div>
    <% } %>

    <!-- SUMMARY METRIC CARDS -->
    <div class="row mt-4 g-3">
        <!-- 1. Assigned Students -->
        <div class="col-sm-6 col-md-3">
            <div class="stats-card">
                <i class="bi bi-people-fill stats-icon"></i>
                <div class="stats-number"><%= assignedStudentsCount %></div>
                <div class="stats-label">Assigned Students</div>
            </div>
        </div>

        <!-- 2. Total Internships -->
        <div class="col-sm-6 col-md-3">
            <div class="stats-card">
                <i class="bi bi-folder-check stats-icon"></i>
                <div class="stats-number"><%= totalInternships %></div>
                <div class="stats-label">Total Internships</div>
            </div>
        </div>

        <!-- 3. Stipend -->
        <div class="col-sm-6 col-md-3">
            <div class="stats-card">
                <i class="bi bi-cash-coin stats-icon"></i>
                <div class="stats-number"><%= stipendCount %></div>
                <div class="stats-label">Stipend Internships</div>
            </div>
        </div>

        <!-- 4. Non-Stipend -->
        <div class="col-sm-6 col-md-3">
            <div class="stats-card">
                <i class="bi bi-briefcase stats-icon"></i>
                <div class="stats-number"><%= nonStipendCount %></div>
                <div class="stats-label">Non-Stipend Internships</div>
            </div>
        </div>
    </div>

    <div class="row mt-3 g-3">
        <!-- 5. Pending -->
        <div class="col-sm-12 col-md-4">
            <div class="stats-card">
                <i class="bi bi-clock-history stats-icon"></i>
                <div class="stats-number"><%= pendingCount %></div>
                <div class="stats-label">Pending Reviews</div>
            </div>
        </div>

        <!-- 6. Approved -->
        <div class="col-sm-12 col-md-4">
            <div class="stats-card">
                <i class="bi bi-check-circle-fill stats-icon"></i>
                <div class="stats-number"><%= approvedCount %></div>
                <div class="stats-label">Approved Internships</div>
            </div>
        </div>

        <!-- 7. Rejected -->
        <div class="col-sm-12 col-md-4">
            <div class="stats-card">
                <i class="bi bi-x-circle-fill stats-icon"></i>
                <div class="stats-number"><%= rejectedCount %></div>
                <div class="stats-label">Rejected Internships</div>
            </div>
        </div>
    </div>

    <!-- FILTERS -->
    <section class="content-card mt-4">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <div class="section-title">
                <i class="bi bi-funnel-fill me-2"></i>Filter Reports
            </div>
            <% if (filterStatus != null || filterType != null || validStartDate != null || validEndDate != null) { %>
                <a href="staff_reports.jsp" class="btn btn-sm btn-outline-secondary">
                    <i class="bi bi-x-circle me-1"></i>Reset Filters
                </a>
            <% } %>
        </div>

        <form method="get" action="staff_reports.jsp" class="row g-3 align-items-end">
            <div class="col-md-3 col-sm-6">
                <label class="form-label fw-semibold">Status</label>
                <select name="status" class="form-select">
                    <option value="" <%= (filterStatus == null) ? "selected" : "" %>>All</option>
                    <option value="Pending" <%= "Pending".equals(filterStatus) ? "selected" : "" %>>Pending</option>
                    <option value="Approved" <%= "Approved".equals(filterStatus) ? "selected" : "" %>>Approved</option>
                    <option value="Rejected" <%= "Rejected".equals(filterStatus) ? "selected" : "" %>>Rejected</option>
                </select>
            </div>

            <div class="col-md-3 col-sm-6">
                <label class="form-label fw-semibold">Internship Type</label>
                <select name="internship_type" class="form-select">
                    <option value="" <%= (filterType == null) ? "selected" : "" %>>All</option>
                    <option value="Stipend" <%= "Stipend".equals(filterType) ? "selected" : "" %>>Stipend</option>
                    <option value="Non-Stipend" <%= "Non-Stipend".equals(filterType) ? "selected" : "" %>>Non-Stipend</option>
                </select>
            </div>

            <div class="col-md-2 col-sm-6">
                <label class="form-label fw-semibold">Start Date From</label>
                <input type="date" name="start_date" class="form-control"
                       value="<%= (validStartDate != null) ? validStartDate.toString() : "" %>">
            </div>

            <div class="col-md-2 col-sm-6">
                <label class="form-label fw-semibold">End Date To</label>
                <input type="date" name="end_date" class="form-control"
                       value="<%= (validEndDate != null) ? validEndDate.toString() : "" %>">
            </div>

            <div class="col-md-2 col-sm-12 d-flex gap-2">
                <button type="submit" class="btn btn-portal w-100">
                    <i class="bi bi-funnel"></i> Apply
                </button>
            </div>
        </form>
    </section>

    <!-- DETAILED REPORT TABLE -->
    <section class="content-card mt-4">
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
            <div>
                <h2 class="section-title mb-0">
                    <i class="bi bi-table me-2"></i>Detailed Internship Report
                </h2>
                <div class="text-muted small mt-1">
                    Showing <%= reportList.size() %> records
                </div>
            </div>
            <div>
                <a href="<%= exportUrl %>" class="btn btn-success">
                    <i class="bi bi-file-earmark-spreadsheet-fill me-1"></i> Export to CSV
                </a>
            </div>
        </div>

        <div class="table-responsive">
            <table class="table table-hover report-table mb-0">
                <thead>
                    <tr>
                        <th>Student ID</th>
                        <th>Student Name</th>
                        <th>Department</th>
                        <th>Company</th>
                        <th>Internship Type</th>
                        <th>Start Date</th>
                        <th>End Date</th>
                        <th>Status</th>
                        <th>Remarks</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (reportList.isEmpty()) { %>
                        <tr>
                            <td colspan="9" class="text-center text-muted py-4">
                                <i class="bi bi-inbox fs-3 d-block mb-2"></i>
                                No internships found matching the selected filters.
                            </td>
                        </tr>
                    <% } else {
                        for (Map<String, String> row : reportList) {
                            String rowStatus = row.get("status");
                            String badgeClass = "badge-pending";
                            if ("Approved".equalsIgnoreCase(rowStatus)) {
                                badgeClass = "badge-approved";
                            } else if ("Rejected".equalsIgnoreCase(rowStatus)) {
                                badgeClass = "badge-rejected";
                            }
                    %>
                        <tr>
                            <td><strong><%= escapeHtml(row.get("student_id")) %></strong></td>
                            <td><%= escapeHtml(row.get("student_name")) %></td>
                            <td><%= escapeHtml(row.get("department")) %></td>
                            <td><%= escapeHtml(row.get("company_name")) %></td>
                            <td><%= escapeHtml(row.get("internship_type")) %></td>
                            <td><%= escapeHtml(row.get("start_date")) %></td>
                            <td><%= escapeHtml(row.get("end_date")) %></td>
                            <td>
                                <span class="<%= badgeClass %>">
                                    <%= escapeHtml(rowStatus) %>
                                </span>
                            </td>
                            <td>
                                <small class="text-muted">
                                    <%= escapeHtml(row.get("remarks")) %>
                                </small>
                            </td>
                        </tr>
                    <%  }
                    } %>
                </tbody>
            </table>
        </div>
    </section>

</main>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
