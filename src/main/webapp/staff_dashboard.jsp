<%@ page import="java.sql.*" %>
<%@ page import="com.internship.DBConnector" %>
<%@ page import="com.internship.CsrfToken" %>
<%!
private String escapeHtml(String value) {
    if (value == null) return "";
    return value.replace("&", "&amp;").replace("<", "&lt;")
            .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
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

int pendingCount = 0;
int approvedCount = 0;
int rejectedCount = 0;

int selectedInternshipId = 0;
boolean selectedSubmission = false;
String selectedStudentId = "";
String selectedStudentName = "";
String selectedCompanyName = "";
String selectedInternshipType = "";
String selectedStartDate = "";
String selectedEndDate = "";
String selectedStatus = "Pending";
String selectedRemarks = "";
String selectedOfferLetter = "";
String selectedCertificate = "";
String selectedPptReview = "";
String selectedReportFile = "";
String selectedBankStatement = "";
String selectedStipendProof = "";
boolean databaseError = false;

String internshipIdParameter =
        request.getParameter("internship_id");

if (internshipIdParameter != null &&
    !internshipIdParameter.trim().isEmpty()) {

    try {
        selectedInternshipId =
                Integer.parseInt(internshipIdParameter);
    }
    catch (NumberFormatException e) {
        selectedInternshipId = 0;
    }
}

try (Connection con = DBConnector.getConnection()) {

    if (con == null) {
        throw new SQLException("Database connection unavailable");
    }

    String countQuery =
            "SELECT i.status, COUNT(*) AS total "
            + "FROM internship i JOIN student s ON i.student_id=s.student_id "
            + "WHERE s.mentor_id=? GROUP BY i.status";

    try (PreparedStatement countStatement =
            con.prepareStatement(countQuery)) {

        countStatement.setString(1, staffId);

        try (ResultSet countResults = countStatement.executeQuery()) {

        while (countResults.next()) {

            String status = countResults.getString("status");
            int total = countResults.getInt("total");

            if (status == null || "Pending".equalsIgnoreCase(status)) {
                pendingCount += total;
            }
            else if ("Approved".equalsIgnoreCase(status)) {
                approvedCount += total;
            }
            else if ("Rejected".equalsIgnoreCase(status)) {
                rejectedCount += total;
            }
        }
    }

    }

    if (selectedInternshipId > 0) {

        String selectedQuery =
                "SELECT i.student_id, s.name AS student_name, "
                + "i.company_name, i.internship_type, "
                + "i.start_date, i.end_date, i.status, i.remarks, "
                + "i.offer_letter, i.certificate, i.ppt_review, "
                + "i.report_file, i.bank_statement, i.stipend_proof "
                + "FROM internship i "
                + "JOIN student s ON i.student_id=s.student_id "
                + "WHERE i.internship_id=? AND s.mentor_id=?";

        try (PreparedStatement selectedStatement =
                con.prepareStatement(selectedQuery)) {

            selectedStatement.setInt(1, selectedInternshipId);
            selectedStatement.setString(2, staffId);

            try (ResultSet selectedResults =
                    selectedStatement.executeQuery()) {

                if (selectedResults.next()) {

                    selectedSubmission = true;
                    selectedStudentId =
                            selectedResults.getString("student_id");
                    selectedStudentName =
                            selectedResults.getString("student_name");
                    selectedCompanyName =
                            selectedResults.getString("company_name");
                    selectedInternshipType =
                            selectedResults.getString("internship_type");
                    selectedStartDate =
                            String.valueOf(selectedResults.getDate("start_date"));
                    selectedEndDate =
                            String.valueOf(selectedResults.getDate("end_date"));
                    selectedStatus =
                            selectedResults.getString("status");
                    selectedRemarks =
                            selectedResults.getString("remarks");
                    selectedOfferLetter =
                            selectedResults.getString("offer_letter");
                    selectedCertificate =
                            selectedResults.getString("certificate");
                    selectedPptReview =
                            selectedResults.getString("ppt_review");
                    selectedReportFile =
                            selectedResults.getString("report_file");
                    selectedBankStatement =
                            selectedResults.getString("bank_statement");
                    selectedStipendProof =
                            selectedResults.getString("stipend_proof");

                    if (selectedStatus == null ||
                        selectedStatus.trim().isEmpty()) {
                        selectedStatus = "Pending";
                    }

                    if (selectedRemarks == null) {
                        selectedRemarks = "";
                    }
                }
            }
        }
    }
}
catch (Exception e) {
    e.printStackTrace();
    databaseError = true;
}

String reviewResult = request.getParameter("review");
%>

<!DOCTYPE html>

<html lang="en">

<head>

<meta charset="UTF-8">

<meta name="viewport"
      content="width=device-width, initial-scale=1">

<title>Staff Dashboard | EEC Internship Portal</title>

<link
    href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
    rel="stylesheet">

<link
    rel="stylesheet"
    href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

<style>

/* ==============================
   GENERAL
   ============================== */

body {

    background: #f5f7fb;

    font-family: 'Segoe UI', sans-serif;

    overflow-x: hidden;
}


/* ==============================
   SIDEBAR
   ============================== */

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


.sidebar-menu a:hover {

    background: rgba(255,255,255,.15);
}


.sidebar-menu i {

    margin-right: 10px;
}


.active-link {

    background: rgba(255,255,255,.15);
}


/* ==============================
   SIDEBAR FOOTER
   ============================== */

.sidebar-footer {

    position: absolute;

    bottom: 0;

    left: 0;

    width: 100%;

    padding: 20px 25px;

    border-top: 1px solid rgba(255,255,255,.15);

    font-size: 13px;

    opacity: .9;
}


/* ==============================
   MAIN CONTENT
   ============================== */

.main-content {

    margin-left: 260px;

    padding: 30px;
}


/* ==============================
   TOPBAR
   ============================== */

.topbar {

    background: white;

    border-radius: 15px;

    padding: 18px 25px;

    box-shadow: 0 2px 12px rgba(0,0,0,.08);

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
}


/* ==============================
   PAGE INTRO
   ============================== */

.page-intro {

    color: #777;

    margin-top: 8px;

    margin-bottom: 0;
}


/* ==============================
   STATISTICS
   ============================== */

.stats-card {

    background: white;

    border: none;

    border-radius: 18px;

    padding: 25px;

    box-shadow: 0 3px 15px rgba(0,0,0,.08);

    transition: .3s;
}


.stats-card:hover {

    transform: translateY(-5px);
}


.stats-icon {

    font-size: 35px;

    color: #6b1d1d;
}


.stats-number {

    font-size: 30px;

    font-weight: 700;

    margin-top: 8px;
}


.stats-label {

    color: #777;
}


/* ==============================
   REVIEW CARD
   ============================== */

.review-card {

    background: white;

    border: none;

    border-radius: 18px;

    padding: 25px;

    box-shadow: 0 3px 15px rgba(0,0,0,.08);
}


.section-title {

    font-size: 21px;

    font-weight: 700;

    margin-bottom: 5px;
}


.section-subtitle {

    color: #777;

    font-size: 14px;
}


/* ==============================
   TABLE
   ============================== */

.table-container {

    overflow-x: auto;
}


.review-table {

    margin-top: 20px;

    margin-bottom: 0;
}


.review-table thead th {

    background: #6b1d1d;

    color: white;

    border: none;

    padding: 14px;

    white-space: nowrap;
}


.review-table tbody td {

    vertical-align: middle;

    padding: 14px;
}


.review-table tbody tr:hover {

    background: #fafafa;
}


/* ==============================
   STATUS BADGES
   ============================== */

.badge-pending {

    background: #fff3cd;

    color: #856404;

    padding: 7px 12px;

    border-radius: 20px;
}


.badge-approved {

    background: #d1e7dd;

    color: #0f5132;

    padding: 7px 12px;

    border-radius: 20px;
}


.badge-rejected {

    background: #f8d7da;

    color: #842029;

    padding: 7px 12px;

    border-radius: 20px;
}


/* ==============================
   ACTION BUTTONS
   ============================== */

.action-btn {

    border-radius: 9px;

    margin: 2px;
}


/* ==============================
   RESPONSIVE
   ============================== */

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

    .main-content {

        margin-left: 0;
    }

    .sidebar-footer {

        position: relative;

        margin-top: 20px;
    }

}

</style>

</head>


<body>


<!-- =========================================
     SIDEBAR
     ========================================= -->

<div class="sidebar">


    <div class="logo-section">

        <img src="images/EEC_logo.png"
             alt="EEC Logo">

        <div class="college-title">

            EEC

        </div>

        <div class="portal-text">

            Internship Management System

        </div>

    </div>



    <div class="sidebar-menu">


        <a href="staff_dashboard.jsp"
           class="active-link">

            <i class="bi bi-speedometer2"></i>

            Dashboard

        </a>


        <a href="staff_internship_reviews.jsp">

            <i class="bi bi-file-earmark-check"></i>

            Internship Reviews

        </a>


        <a href="staff_assigned_students.jsp">

            <i class="bi bi-people-fill"></i>

            Assigned Students

        </a>


        <a href="staff_reports.jsp">

            <i class="bi bi-bar-chart-line-fill"></i>

            Reports

        </a>


        <form action="LogoutServlet" method="post"><input type="hidden" name="csrfToken" value="<%= csrfToken %>"><button type="submit" class="btn btn-link text-white p-0"><i class="bi bi-box-arrow-right"></i> Logout</button></form>


    </div>


    <div class="sidebar-footer">

        <strong>

            Faculty Mentor

        </strong>

        <br>

        Staff Account

    </div>


</div>



<!-- =========================================
     MAIN CONTENT
     ========================================= -->

<div class="main-content">


    <!-- TOPBAR -->

    <div class="topbar">

        <div>

            <h2 class="page-title">

                Staff Dashboard

            </h2>

            <p class="page-intro">

                Review and approve internship submissions

            </p>

        </div>


        <div class="staff-badge">

            Faculty Mentor

        </div>

    </div>



    <% if (databaseError) { %>
        <div class="alert alert-danger mt-4">
            Unable to load internship data from the database.
        </div>
    <% } %>

    <% if ("success".equals(reviewResult)) { %>
        <div class="alert alert-success mt-4">
            Internship review updated successfully.
        </div>
    <% } else if ("invalid".equals(reviewResult)) { %>
        <div class="alert alert-warning mt-4">
            Please select a valid internship and review status.
        </div>
    <% } else if ("notfound".equals(reviewResult)) { %>
        <div class="alert alert-warning mt-4">
            The selected internship could not be found.
        </div>
    <% } else if ("error".equals(reviewResult)) { %>
        <div class="alert alert-danger mt-4">
            Unable to update the internship review.
        </div>
    <% } %>

    <% if (selectedSubmission) { %>
        <div class="review-card mt-4">
            <div class="section-title">
                <i class="bi bi-file-earmark-text-fill me-2"></i>
                Internship Details
            </div>

            <div class="row g-3 mt-1">
                <div class="col-md-6">
                    <strong>Student</strong>
                    <div><%= escapeHtml(selectedStudentName != null &&
                        !selectedStudentName.trim().isEmpty()
                        ? selectedStudentName : selectedStudentId) %></div>
                    <small class="text-muted"><%= escapeHtml(selectedStudentId) %></small>
                </div>
                <div class="col-md-6">
                    <strong>Company</strong>
                    <div><%= escapeHtml(selectedCompanyName) %></div>
                </div>
                <div class="col-md-4">
                    <strong>Internship Type</strong>
                    <div><%= escapeHtml(selectedInternshipType) %></div>
                </div>
                <div class="col-md-4">
                    <strong>Start Date</strong>
                    <div><%= escapeHtml(selectedStartDate) %></div>
                </div>
                <div class="col-md-4">
                    <strong>End Date</strong>
                    <div><%= escapeHtml(selectedEndDate) %></div>
                </div>
            </div>

            <hr>

            <h5>Submitted Documents</h5>
            <div class="row g-2">
                <div class="col-md-4">Offer Letter:
                    <strong><%=selectedOfferLetter != null &&
                        !selectedOfferLetter.trim().isEmpty()
                        ? "Uploaded" : "Not Uploaded"%></strong>
                    <% if (selectedOfferLetter != null && !selectedOfferLetter.trim().isEmpty()) { %>
                        <a class="btn btn-sm btn-outline-primary ms-1" target="_blank" rel="noopener" href="ViewInternshipDocumentServlet?internship_id=<%=selectedInternshipId%>&document_type=offer_letter">View</a>
                    <% } %>
                </div>
                <div class="col-md-4">Certificate:
                    <strong><%=selectedCertificate != null &&
                        !selectedCertificate.trim().isEmpty()
                        ? "Uploaded" : "Not Uploaded"%></strong>
                    <% if (selectedCertificate != null && !selectedCertificate.trim().isEmpty()) { %>
                        <a class="btn btn-sm btn-outline-primary ms-1" target="_blank" rel="noopener" href="ViewInternshipDocumentServlet?internship_id=<%=selectedInternshipId%>&document_type=certificate">View</a>
                    <% } %>
                </div>
                <div class="col-md-4">PPT / Review:
                    <strong><%=selectedPptReview != null &&
                        !selectedPptReview.trim().isEmpty()
                        ? "Uploaded" : "Not Uploaded"%></strong>
                    <% if (selectedPptReview != null && !selectedPptReview.trim().isEmpty()) { %>
                        <a class="btn btn-sm btn-outline-primary ms-1" target="_blank" rel="noopener" href="ViewInternshipDocumentServlet?internship_id=<%=selectedInternshipId%>&document_type=ppt_review">View</a>
                    <% } %>
                </div>
                <div class="col-md-4">Report:
                    <strong><%=selectedReportFile != null &&
                        !selectedReportFile.trim().isEmpty()
                        ? "Uploaded" : "Not Uploaded"%></strong>
                    <% if (selectedReportFile != null && !selectedReportFile.trim().isEmpty()) { %>
                        <a class="btn btn-sm btn-outline-primary ms-1" target="_blank" rel="noopener" href="ViewInternshipDocumentServlet?internship_id=<%=selectedInternshipId%>&document_type=report_file">View</a>
                    <% } %>
                </div>
                <% if ("Stipend".equals(selectedInternshipType)) { %>
                    <div class="col-md-4">Bank Statement:
                        <strong><%=selectedBankStatement != null &&
                            !selectedBankStatement.trim().isEmpty()
                            ? "Uploaded" : "Not Uploaded"%></strong>
                        <% if (selectedBankStatement != null && !selectedBankStatement.trim().isEmpty()) { %>
                            <a class="btn btn-sm btn-outline-primary ms-1" target="_blank" rel="noopener" href="ViewInternshipDocumentServlet?internship_id=<%=selectedInternshipId%>&document_type=bank_statement">View</a>
                        <% } %>
                    </div>
                    <div class="col-md-4">Stipend Proof:
                        <strong><%=selectedStipendProof != null &&
                            !selectedStipendProof.trim().isEmpty()
                            ? "Uploaded" : "Not Uploaded"%></strong>
                        <% if (selectedStipendProof != null && !selectedStipendProof.trim().isEmpty()) { %>
                            <a class="btn btn-sm btn-outline-primary ms-1" target="_blank" rel="noopener" href="ViewInternshipDocumentServlet?internship_id=<%=selectedInternshipId%>&document_type=stipend_proof">View</a>
                        <% } %>
                    </div>
                <% } %>
            </div>

            <hr>

            <form action="ReviewInternshipServlet" method="post">
                <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                <input type="hidden" name="internship_id"
                       value="<%=selectedInternshipId%>">
                <div class="mb-3">
                    <label class="form-label">Remarks (optional)</label>
                    <textarea name="remarks" class="form-control"
                              rows="3"><%= escapeHtml(selectedRemarks) %></textarea>
                </div>
                <button type="submit" name="status" value="Approved"
                        class="btn btn-success action-btn">
                    <i class="bi bi-check-lg"></i> Approve
                </button>
                <button type="submit" name="status" value="Rejected"
                        class="btn btn-danger action-btn">
                    <i class="bi bi-x-lg"></i> Reject
                </button>
                <span class="ms-2 text-muted">
                    Current status: <strong><%= escapeHtml(selectedStatus) %></strong>
                </span>
            </form>
        </div>
    <% } %>


    <!-- =====================================
         STATISTICS
         ===================================== -->

    <div class="row mt-4 g-4">


        <!-- PENDING -->

        <div class="col-md-4">

            <div class="stats-card">

                <i class="bi bi-clock-history stats-icon"></i>

                <div class="stats-number">

                    <%=pendingCount%>

                </div>

                <div class="stats-label">

                    Pending Reviews

                </div>

            </div>

        </div>


        <!-- APPROVED -->

        <div class="col-md-4">

            <div class="stats-card">

                <i class="bi bi-check-circle-fill stats-icon"></i>

                <div class="stats-number">

                    <%=approvedCount%>

                </div>

                <div class="stats-label">

                    Approved

                </div>

            </div>

        </div>


        <!-- REJECTED -->

        <div class="col-md-4">

            <div class="stats-card">

                <i class="bi bi-x-circle-fill stats-icon"></i>

                <div class="stats-number">

                    <%=rejectedCount%>

                </div>

                <div class="stats-label">

                    Rejected

                </div>

            </div>

        </div>


    </div>



    <!-- =====================================
         INTERNSHIP SUBMISSIONS
         ===================================== -->

    <div class="review-card mt-4">


        <div class="section-title">

            <i class="bi bi-file-earmark-check-fill me-2"></i>

            Internship Submissions

        </div>


        <div class="section-subtitle">

            Review internship submissions from assigned students.

        </div>


        <div class="table-container">


            <table class="table table-hover review-table">


                <thead>

                    <tr>

                        <th>

                            Student

                        </th>

                        <th>

                            Company

                        </th>

                        <th>

                            Internship Type

                        </th>

                        <th>

                            Status

                        </th>

                        <th>

                            Action

                        </th>

                    </tr>

                </thead>


                <tbody>

                <%
                try (
                    Connection listConnection =
                            DBConnector.getConnection();

                    PreparedStatement listStatement =
                            listConnection.prepareStatement(
                                "SELECT i.internship_id, i.student_id, "
                                + "s.name AS student_name, "
                                + "i.company_name, i.internship_type, "
                                + "i.status "
                                + "FROM internship i "
                                + "JOIN student s "
                                + "ON i.student_id=s.student_id "
                                + "WHERE s.mentor_id=? "
                                + "ORDER BY i.internship_id DESC"
                            )
                ) {
                    listStatement.setString(1, staffId);

                    ResultSet listResults =
                            listStatement.executeQuery();

                    boolean hasSubmissions = false;

                    while (listResults.next()) {

                        hasSubmissions = true;

                        String rowStatus =
                                listResults.getString("status");

                        if (rowStatus == null ||
                            rowStatus.trim().isEmpty()) {

                            rowStatus = "Pending";
                        }

                        String rowStatusClass = "badge-pending";

                        if ("Approved".equalsIgnoreCase(rowStatus)) {

                            rowStatusClass = "badge-approved";

                        }
                        else if ("Rejected".equalsIgnoreCase(rowStatus)) {

                            rowStatusClass = "badge-rejected";

                        }
                %>

                    <tr>

                        <td>
                            <strong>
                                <%= escapeHtml(listResults.getString("student_name") != null
                                    ? listResults.getString("student_name")
                                    : listResults.getString("student_id")) %>
                            </strong>
                            <br>
                            <small class="text-muted">
                                <%= escapeHtml(listResults.getString("student_id")) %>
                            </small>
                        </td>

                        <td>
                            <%= escapeHtml(listResults.getString("company_name")) %>
                        </td>

                        <td>
                            <%= escapeHtml(listResults.getString("internship_type")) %>
                        </td>

                        <td>
                            <span class="<%=rowStatusClass%>">
                                <%= escapeHtml(rowStatus) %>
                            </span>
                        </td>

                        <td>
                            <a
                                href="staff_dashboard.jsp?internship_id=<%=listResults.getInt("internship_id")%>"
                                class="btn btn-primary btn-sm action-btn">
                                <i class="bi bi-eye"></i>
                                View
                            </a>
                        </td>

                    </tr>

                <%
                    }

                    if (!hasSubmissions) {
                %>

                    <tr>
                        <td colspan="5" class="text-center text-muted">
                            No internship submissions found.
                        </td>
                    </tr>

                <%
                    }
                }
                catch (Exception e) {
                    e.printStackTrace();
                %>

                    <tr>
                        <td colspan="5" class="text-center text-danger">
                            Unable to load internship submissions.
                        </td>
                    </tr>

                <%
                }
                %>

                </tbody>


            </table>

        </div>


    </div>


</div>



<script
src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js">
</script>


</body>

</html>
