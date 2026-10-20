<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="com.internship.DBConnector" %>

<%!
private String escapeHtml(String value) {
    if (value == null) return "";
    return value.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
}

private boolean hasFile(Map<String, String> record, String key) {
    String value = record.get(key);
    return value != null && !value.trim().isEmpty();
}
%>

<%
// ============================================================
// 1. ADMIN SESSION & ROLE VERIFICATION (BEFORE ANY DB QUERIES)
// ============================================================
String role = (String) session.getAttribute("role");

if (role == null || !role.equals("admin")) {
    response.sendRedirect("login.jsp");
    return;
}

// ============================================================
// 2. PARSE AND SANITIZE SEARCH & FILTER PARAMETERS
// ============================================================
String searchParam = request.getParameter("search");
String search = (searchParam != null) ? searchParam.trim() : null;

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

int totalInternships = 0;
int pendingCount = 0;
int approvedCount = 0;
int rejectedCount = 0;
int stipendCount = 0;
int nonStipendCount = 0;
boolean databaseError = false;

List<Map<String, String>> internshipList = new ArrayList<Map<String, String>>();

try (Connection con = DBConnector.getConnection()) {
    if (con == null) {
        throw new SQLException("Database connection unavailable");
    }

    // ========================================================
    // 3. SYSTEM-WIDE SUMMARY METRICS (NO MENTOR RESTRICTION)
    // ========================================================
    String statsQuery =
        "SELECT "
        + "COUNT(*) AS total_internships, "
        + "SUM(CASE WHEN i.status = 'Pending' OR i.status IS NULL OR TRIM(i.status) = '' THEN 1 ELSE 0 END) AS pending_count, "
        + "SUM(CASE WHEN i.status = 'Approved' THEN 1 ELSE 0 END) AS approved_count, "
        + "SUM(CASE WHEN i.status = 'Rejected' THEN 1 ELSE 0 END) AS rejected_count, "
        + "SUM(CASE WHEN i.internship_type = 'Stipend' THEN 1 ELSE 0 END) AS stipend_count, "
        + "SUM(CASE WHEN i.internship_type = 'Non-Stipend' THEN 1 ELSE 0 END) AS non_stipend_count "
        + "FROM internship i";

    try (PreparedStatement ps = con.prepareStatement(statsQuery);
         ResultSet rs = ps.executeQuery()) {
        if (rs.next()) {
            totalInternships = rs.getInt("total_internships");
            pendingCount = rs.getInt("pending_count");
            approvedCount = rs.getInt("approved_count");
            rejectedCount = rs.getInt("rejected_count");
            stipendCount = rs.getInt("stipend_count");
            nonStipendCount = rs.getInt("non_stipend_count");
        }
    }

    // ========================================================
    // 4. SYSTEM-WIDE INTERNSHIP RECORDS WITH SEARCH & FILTERS
    // ========================================================
    StringBuilder queryBuilder = new StringBuilder(
        "SELECT "
        + "i.internship_id, "
        + "s.student_id, "
        + "s.name AS student_name, "
        + "s.department, "
        + "m.name AS mentor_name, "
        + "i.company_name, "
        + "i.internship_type, "
        + "i.start_date, "
        + "i.end_date, "
        + "i.status, "
        + "i.remarks, "
        + "i.offer_letter, "
        + "i.certificate, "
        + "i.ppt_review, "
        + "i.report_file, "
        + "i.bank_statement, "
        + "i.stipend_proof "
        + "FROM internship i "
        + "JOIN student s ON i.student_id = s.student_id "
        + "LEFT JOIN staff m ON s.mentor_id = m.staff_id "
        + "WHERE 1=1"
    );

    List<Object> queryParams = new ArrayList<>();

    if (search != null && !search.isEmpty()) {
        queryBuilder.append(" AND (s.student_id LIKE ? OR s.name LIKE ? OR s.department LIKE ? OR i.company_name LIKE ?)");
        String searchPattern = "%" + search + "%";
        queryParams.add(searchPattern);
        queryParams.add(searchPattern);
        queryParams.add(searchPattern);
        queryParams.add(searchPattern);
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
                Map<String, String> row = new HashMap<String, String>();
                row.put("internship_id", String.valueOf(rs.getInt("internship_id")));
                row.put("student_id", rs.getString("student_id"));
                row.put("student_name", rs.getString("student_name"));
                row.put("department", rs.getString("department"));
                String mName = rs.getString("mentor_name");
                row.put("mentor_name", (mName != null && !mName.trim().isEmpty()) ? mName : "Unassigned");
                row.put("company_name", rs.getString("company_name"));
                row.put("internship_type", rs.getString("internship_type"));
                java.sql.Date sDate = rs.getDate("start_date");
                row.put("start_date", sDate != null ? sDate.toString() : "");
                java.sql.Date eDate = rs.getDate("end_date");
                row.put("end_date", eDate != null ? eDate.toString() : "");
                String st = rs.getString("status");
                if (st == null || st.trim().isEmpty()) {
                    st = "Pending";
                }
                row.put("status", st);
                String rem = rs.getString("remarks");
                row.put("remarks", rem != null ? rem : "");
                row.put("offer_letter", rs.getString("offer_letter"));
                row.put("certificate", rs.getString("certificate"));
                row.put("ppt_review", rs.getString("ppt_review"));
                row.put("report_file", rs.getString("report_file"));
                row.put("bank_statement", rs.getString("bank_statement"));
                row.put("stipend_proof", rs.getString("stipend_proof"));

                internshipList.add(row);
            }
        }
    }
} catch (Exception e) {
    e.printStackTrace();
    databaseError = true;
}
%>

<!DOCTYPE html>
<html lang="en">

<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Internship Records | EEC Internship Portal</title>

<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

<style>
* {
    box-sizing: border-box;
}

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

.admin-badge {
    background: #6b1d1d;
    color: white;
    padding: 8px 18px;
    border-radius: 25px;
    font-size: 14px;
}

/* STATS CARDS */
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

.record-table thead th {
    background: #6b1d1d;
    color: white;
    border: none;
    padding: 14px;
    white-space: nowrap;
    font-weight: 600;
    font-size: 14px;
}

.record-table tbody td {
    vertical-align: middle;
    padding: 13px 14px;
    font-size: 14px;
}

.record-table tbody tr:hover {
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

.doc-btn {
    font-size: 12px;
    padding: 2px 8px;
    border-radius: 6px;
    text-decoration: none;
    display: inline-flex;
    align-items: center;
    gap: 4px;
    margin: 2px 2px 2px 0;
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

<!-- =========================================
     SIDEBAR
     ========================================= -->
<aside class="sidebar">
    <div class="logo-section">
        <img src="images/EEC_logo.png" alt="EEC Logo">
        <div class="college-title">EEC</div>
        <div class="portal-text">Internship Management System</div>
    </div>

    <nav class="sidebar-menu">
        <a href="admin_dashboard.jsp">
            <i class="bi bi-speedometer2"></i> Dashboard
        </a>
        <a href="manage_students.jsp">
            <i class="bi bi-people-fill"></i> Students
        </a>
        <a href="manage_student_assignments.jsp">
            <i class="bi bi-person-check-fill"></i> Student Assignments
        </a>
        <a href="manage_staff.jsp">
            <i class="bi bi-person-workspace"></i> Staff
        </a>
        <a href="admin_internship_records.jsp" class="active-link">
            <i class="bi bi-folder-check"></i> Internship Records
        </a>
        <a href="admin_reports.jsp">
            <i class="bi bi-bar-chart-line-fill"></i> Reports
        </a>
        <form action="LogoutServlet" method="post"><input type="hidden" name="csrfToken" value="<%= com.internship.CsrfToken.getOrCreate(session) %>"><button type="submit" class="btn btn-link text-white p-0"><i class="bi bi-box-arrow-right"></i> Logout</button></form>
    </nav>

    <div class="sidebar-footer">
        <strong>Administrator</strong><br>
        Admin Account
    </div>
</aside>

<!-- =========================================
     MAIN CONTENT
     ========================================= -->
<main class="main-content">

    <!-- TOPBAR -->
    <div class="topbar">
        <div>
            <h1 class="page-title">Internship Records</h1>
            <p class="text-muted mb-0 mt-1">System-wide view of all student internship submissions and documents</p>
        </div>
        <div class="admin-badge">
            Administrator
        </div>
    </div>

    <% if (databaseError) { %>
        <div class="alert alert-danger mt-4">
            <i class="bi bi-exclamation-triangle-fill me-2"></i>
            Unable to load internship records from the database. Please try again later.
        </div>
    <% } %>

    <!-- =====================================
         SUMMARY METRIC CARDS
         ===================================== -->
    <div class="row mt-4 g-3">
        <div class="col-sm-6 col-md-4 col-xl-2">
            <div class="stats-card">
                <i class="bi bi-folder-check stats-icon"></i>
                <div class="stats-number"><%= totalInternships %></div>
                <div class="stats-label">Total Internships</div>
            </div>
        </div>

        <div class="col-sm-6 col-md-4 col-xl-2">
            <div class="stats-card">
                <i class="bi bi-clock-history stats-icon"></i>
                <div class="stats-number"><%= pendingCount %></div>
                <div class="stats-label">Pending Reviews</div>
            </div>
        </div>

        <div class="col-sm-6 col-md-4 col-xl-2">
            <div class="stats-card">
                <i class="bi bi-check-circle-fill stats-icon"></i>
                <div class="stats-number"><%= approvedCount %></div>
                <div class="stats-label">Approved</div>
            </div>
        </div>

        <div class="col-sm-6 col-md-4 col-xl-2">
            <div class="stats-card">
                <i class="bi bi-x-circle-fill stats-icon"></i>
                <div class="stats-number"><%= rejectedCount %></div>
                <div class="stats-label">Rejected</div>
            </div>
        </div>

        <div class="col-sm-6 col-md-4 col-xl-2">
            <div class="stats-card">
                <i class="bi bi-cash-coin stats-icon"></i>
                <div class="stats-number"><%= stipendCount %></div>
                <div class="stats-label">Stipend</div>
            </div>
        </div>

        <div class="col-sm-6 col-md-4 col-xl-2">
            <div class="stats-card">
                <i class="bi bi-briefcase stats-icon"></i>
                <div class="stats-number"><%= nonStipendCount %></div>
                <div class="stats-label">Non-Stipend</div>
            </div>
        </div>
    </div>

    <!-- =====================================
         SEARCH & FILTERS
         ===================================== -->
    <section class="content-card mt-4">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <div class="section-title">
                <i class="bi bi-funnel-fill me-2"></i>Search & Filter Records
            </div>
            <% if ((search != null && !search.isEmpty()) || filterStatus != null || filterType != null || validStartDate != null || validEndDate != null) { %>
                <a href="admin_internship_records.jsp" class="btn btn-sm btn-outline-secondary">
                    <i class="bi bi-x-circle me-1"></i>Clear Filters
                </a>
            <% } %>
        </div>

        <form method="get" action="admin_internship_records.jsp" class="row g-3 align-items-end">
            <!-- Search Keyword -->
            <div class="col-md-3 col-sm-12">
                <label class="form-label fw-semibold">Search</label>
                <div class="input-group">
                    <span class="input-group-text bg-white"><i class="bi bi-search"></i></span>
                    <input type="text" name="search" class="form-control"
                           placeholder="ID, Name, Company..."
                           value="<%= (search != null) ? escapeHtml(search) : "" %>">
                </div>
            </div>

            <!-- Status Filter -->
            <div class="col-md-2 col-sm-6">
                <label class="form-label fw-semibold">Status</label>
                <select name="status" class="form-select">
                    <option value="" <%= (filterStatus == null) ? "selected" : "" %>>All Statuses</option>
                    <option value="Pending" <%= "Pending".equals(filterStatus) ? "selected" : "" %>>Pending</option>
                    <option value="Approved" <%= "Approved".equals(filterStatus) ? "selected" : "" %>>Approved</option>
                    <option value="Rejected" <%= "Rejected".equals(filterStatus) ? "selected" : "" %>>Rejected</option>
                </select>
            </div>

            <!-- Internship Type Filter -->
            <div class="col-md-2 col-sm-6">
                <label class="form-label fw-semibold">Type</label>
                <select name="internship_type" class="form-select">
                    <option value="" <%= (filterType == null) ? "selected" : "" %>>All Types</option>
                    <option value="Stipend" <%= "Stipend".equals(filterType) ? "selected" : "" %>>Stipend</option>
                    <option value="Non-Stipend" <%= "Non-Stipend".equals(filterType) ? "selected" : "" %>>Non-Stipend</option>
                </select>
            </div>

            <!-- Start Date Filter -->
            <div class="col-md-2 col-sm-6">
                <label class="form-label fw-semibold">Start Date From</label>
                <input type="date" name="start_date" class="form-control"
                       value="<%= (validStartDate != null) ? validStartDate.toString() : "" %>">
            </div>

            <!-- End Date Filter -->
            <div class="col-md-2 col-sm-6">
                <label class="form-label fw-semibold">End Date To</label>
                <input type="date" name="end_date" class="form-control"
                       value="<%= (validEndDate != null) ? validEndDate.toString() : "" %>">
            </div>

            <!-- Submit Button -->
            <div class="col-md-1 col-sm-12">
                <button type="submit" class="btn btn-portal w-100">
                    <i class="bi bi-funnel"></i> Apply
                </button>
            </div>
        </form>
    </section>

    <!-- =====================================
         DETAILED INTERNSHIP RECORDS TABLE
         ===================================== -->
    <section class="content-card mt-4">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <div>
                <h2 class="section-title mb-0">
                    <i class="bi bi-table me-2"></i>All Internship Submissions
                </h2>
                <div class="text-muted small mt-1">
                    Showing <%= internshipList.size() %> records
                </div>
            </div>
        </div>

        <div class="table-responsive">
            <table class="table table-hover record-table mb-0">
                <thead>
                    <tr>
                        <th>Student ID</th>
                        <th>Student Name</th>
                        <th>Department</th>
                        <th>Mentor</th>
                        <th>Company</th>
                        <th>Type</th>
                        <th>Start Date</th>
                        <th>End Date</th>
                        <th>Status</th>
                        <th>Remarks</th>
                        <th>Documents</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (internshipList.isEmpty()) { %>
                        <tr>
                            <td colspan="11" class="text-center text-muted py-4">
                                <i class="bi bi-inbox fs-3 d-block mb-2"></i>
                                No internship records found matching the criteria.
                            </td>
                        </tr>
                    <% } else {
                        for (Map<String, String> row : internshipList) {
                            String internshipId = row.get("internship_id");
                            String rowStatus = row.get("status");
                            String badgeClass = "badge-pending";
                            if ("Approved".equalsIgnoreCase(rowStatus)) {
                                badgeClass = "badge-approved";
                            } else if ("Rejected".equalsIgnoreCase(rowStatus)) {
                                badgeClass = "badge-rejected";
                            }

                            boolean isStipend = "Stipend".equalsIgnoreCase(row.get("internship_type"));
                            boolean hasAnyDoc = hasFile(row, "offer_letter") || hasFile(row, "certificate")
                                    || hasFile(row, "ppt_review") || hasFile(row, "report_file")
                                    || (isStipend && (hasFile(row, "bank_statement") || hasFile(row, "stipend_proof")));
                    %>
                        <tr>
                            <td><strong><%= escapeHtml(row.get("student_id")) %></strong></td>
                            <td><%= escapeHtml(row.get("student_name")) %></td>
                            <td><%= escapeHtml(row.get("department")) %></td>
                            <td>
                                <span class="text-secondary">
                                    <i class="bi bi-person-badge me-1"></i><%= escapeHtml(row.get("mentor_name")) %>
                                </span>
                            </td>
                            <td><%= escapeHtml(row.get("company_name")) %></td>
                            <td><%= escapeHtml(row.get("internship_type")) %></td>
                            <td class="text-nowrap"><%= escapeHtml(row.get("start_date")) %></td>
                            <td class="text-nowrap"><%= escapeHtml(row.get("end_date")) %></td>
                            <td>
                                <span class="<%= badgeClass %>">
                                    <%= escapeHtml(rowStatus) %>
                                </span>
                            </td>
                            <td>
                                <small class="text-muted">
                                    <%= hasFile(row, "remarks") ? escapeHtml(row.get("remarks")) : "—" %>
                                </small>
                            </td>
                            <td>
                                <% if (!hasAnyDoc) { %>
                                    <span class="text-muted small">None</span>
                                <% } else { %>
                                    <div class="d-flex flex-wrap gap-1">
                                        <% if (hasFile(row, "offer_letter")) { %>
                                            <a href="ViewInternshipDocumentServlet?internship_id=<%= internshipId %>&document_type=offer_letter"
                                               target="_blank" rel="noopener"
                                               class="btn btn-sm btn-outline-primary doc-btn" title="Offer Letter">
                                                <i class="bi bi-file-earmark-text"></i> Offer
                                            </a>
                                        <% } %>
                                        <% if (hasFile(row, "certificate")) { %>
                                            <a href="ViewInternshipDocumentServlet?internship_id=<%= internshipId %>&document_type=certificate"
                                               target="_blank" rel="noopener"
                                               class="btn btn-sm btn-outline-primary doc-btn" title="Certificate">
                                                <i class="bi bi-award"></i> Cert
                                            </a>
                                        <% } %>
                                        <% if (hasFile(row, "ppt_review")) { %>
                                            <a href="ViewInternshipDocumentServlet?internship_id=<%= internshipId %>&document_type=ppt_review"
                                               target="_blank" rel="noopener"
                                               class="btn btn-sm btn-outline-primary doc-btn" title="PPT / Review">
                                                <i class="bi bi-file-earmark-slides"></i> PPT
                                            </a>
                                        <% } %>
                                        <% if (hasFile(row, "report_file")) { %>
                                            <a href="ViewInternshipDocumentServlet?internship_id=<%= internshipId %>&document_type=report_file"
                                               target="_blank" rel="noopener"
                                               class="btn btn-sm btn-outline-primary doc-btn" title="Report">
                                                <i class="bi bi-file-earmark-pdf"></i> Report
                                            </a>
                                        <% } %>
                                        <% if (isStipend) { %>
                                            <% if (hasFile(row, "bank_statement")) { %>
                                                <a href="ViewInternshipDocumentServlet?internship_id=<%= internshipId %>&document_type=bank_statement"
                                                   target="_blank" rel="noopener"
                                                   class="btn btn-sm btn-outline-primary doc-btn" title="Bank Statement">
                                                    <i class="bi bi-bank"></i> Bank
                                                </a>
                                            <% } %>
                                            <% if (hasFile(row, "stipend_proof")) { %>
                                                <a href="ViewInternshipDocumentServlet?internship_id=<%= internshipId %>&document_type=stipend_proof"
                                                   target="_blank" rel="noopener"
                                                   class="btn btn-sm btn-outline-primary doc-btn" title="Stipend Proof">
                                                    <i class="bi bi-receipt"></i> Proof
                                                </a>
                                            <% } %>
                                        <% } %>
                                    </div>
                                <% } %>
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
