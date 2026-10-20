<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.internship.DBConnector" %>
<%@ page import="com.internship.CsrfToken" %>
<%!
private String escapeHtml(String value) {
    if (value == null) return "";
    return value.replace("&", "&amp;").replace("<", "&lt;")
            .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
}
private boolean hasFile(Map<String, String> record, String key) {
    String value = record.get(key);
    return value != null && !value.trim().isEmpty();
}
%>
<%
String role = (String) session.getAttribute("role");
if (!"staff".equals(role)) {
    response.sendRedirect("login.jsp");
    return;
}
String staffId = (String) session.getAttribute("staff_id");
if (staffId == null || staffId.trim().isEmpty()) { response.sendRedirect("login.jsp"); return; }
String csrfToken = CsrfToken.getOrCreate(session);

List<Map<String, String>> pendingRecords = new ArrayList<Map<String, String>>();
List<Map<String, String>> approvedRecords = new ArrayList<Map<String, String>>();
List<Map<String, String>> rejectedRecords = new ArrayList<Map<String, String>>();
boolean databaseError = false;

String query = "SELECT i.internship_id, i.student_id, i.company_name, i.internship_type, i.start_date, i.end_date, "
        + "i.offer_letter, i.certificate, i.ppt_review, i.report_file, i.bank_statement, i.stipend_proof, i.status, i.remarks "
        + "FROM internship i JOIN student s ON i.student_id=s.student_id "
        + "WHERE s.mentor_id=? ORDER BY CASE i.status WHEN 'Pending' THEN 0 WHEN 'Approved' THEN 1 ELSE 2 END, i.internship_id DESC";
try (Connection con = DBConnector.getConnection(); PreparedStatement ps = con.prepareStatement(query)) {
    ps.setString(1, staffId);
    try (ResultSet rs = ps.executeQuery()) {
    while (rs.next()) {
        Map<String, String> record = new HashMap<String, String>();
        String[] columns = {"internship_id", "student_id", "company_name", "internship_type", "start_date", "end_date",
                "offer_letter", "certificate", "ppt_review", "report_file", "bank_statement", "stipend_proof", "status", "remarks"};
        for (String column : columns) record.put(column, rs.getString(column));
        String status = record.get("status");
        if (status == null || status.trim().isEmpty() || "Pending".equalsIgnoreCase(status)) pendingRecords.add(record);
        else if ("Approved".equalsIgnoreCase(status)) approvedRecords.add(record);
        else rejectedRecords.add(record);
    }
    }
} catch (Exception e) { databaseError = true; }
String reviewResult = request.getParameter("review");
String[][] documentTypes = {{"offer_letter", "Offer Letter"}, {"certificate", "Certificate"}, {"ppt_review", "PPT / Review"},
        {"report_file", "Report"}, {"bank_statement", "Bank Statement"}, {"stipend_proof", "Stipend Proof"}};
%>
<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Internship Reviews | EEC Internship Portal</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
<style>
body{background:#f5f7fb;font-family:'Segoe UI',sans-serif;color:#30313a}.sidebar{position:fixed;top:0;left:0;width:260px;height:100vh;background:#6b1d1d;color:#fff;padding:25px}.logo-section{text-align:center;margin-bottom:35px}.logo-section img{width:70px;height:70px;object-fit:contain;background:#fff;border-radius:12px;padding:5px}.college-title{margin-top:15px;font-size:18px;font-weight:700}.portal-text{font-size:13px;opacity:.85}.sidebar-menu{margin-top:30px}.sidebar-menu a{display:block;padding:14px 18px;color:#fff;text-decoration:none;border-radius:10px;margin-bottom:10px}.sidebar-menu a:hover,.active-link{background:rgba(255,255,255,.15)}.sidebar-menu i{margin-right:10px}.sidebar-footer{position:absolute;bottom:25px;font-size:13px;opacity:.9}.main-content{margin-left:260px;padding:30px}.topbar,.review-card{background:#fff;border-radius:18px;padding:25px;box-shadow:0 3px 15px rgba(0,0,0,.08)}.topbar{display:flex;justify-content:space-between;align-items:center}.page-title{font-size:28px;font-weight:700;margin:0}.staff-badge{background:#6b1d1d;color:#fff;padding:8px 14px;border-radius:20px;font-size:13px}.review-card{margin-top:22px}.section-title{font-size:21px;font-weight:700}.status-badge{padding:6px 11px;border-radius:20px;font-size:13px;font-weight:600}.status-pending{background:#fff3cd;color:#856404}.status-approved{background:#d1e7dd;color:#0f5132}.status-rejected{background:#f8d7da;color:#842029}.document-link{font-size:13px}.empty-state{padding:30px;text-align:center;color:#777;background:#fff;border-radius:14px;box-shadow:0 2px 10px rgba(0,0,0,.05)}@media(max-width:768px){.sidebar{position:relative;width:100%;height:auto}.sidebar-footer{position:relative;bottom:auto;margin-top:20px}.main-content{margin-left:0;padding:20px}}
</style></head><body>
<aside class="sidebar"><div class="logo-section"><img src="images/EEC_logo.png" alt="EEC Logo"><div class="college-title">EEC</div><div class="portal-text">Internship Management System</div></div><nav class="sidebar-menu"><a href="staff_dashboard.jsp"><i class="bi bi-speedometer2"></i>Dashboard</a><a class="active-link" href="staff_internship_reviews.jsp"><i class="bi bi-file-earmark-check"></i>Internship Reviews</a><a href="staff_assigned_students.jsp"><i class="bi bi-people-fill"></i>Assigned Students</a><a href="staff_reports.jsp"><i class="bi bi-bar-chart-line-fill"></i>Reports</a><form action="LogoutServlet" method="post"><input type="hidden" name="csrfToken" value="<%= csrfToken %>"><button type="submit" class="btn btn-link text-white p-0"><i class="bi bi-box-arrow-right"></i>Logout</button></form></nav><div class="sidebar-footer"><strong>Faculty Mentor</strong><br>Staff Account</div></aside>
<main class="main-content"><div class="topbar"><div><h1 class="page-title">Internship Reviews</h1><div class="text-muted">Review submitted internships and supporting documents.</div></div><div class="staff-badge">Faculty Mentor</div></div>
<% if (databaseError) { %><div class="alert alert-danger mt-4">Unable to load internship reviews from the database.</div><% } %>
<% if ("success".equals(reviewResult)) { %><div class="alert alert-success mt-4">Internship review updated successfully.</div><% } else if ("invalid".equals(reviewResult)) { %><div class="alert alert-warning mt-4">Please select a valid internship and review status.</div><% } else if ("notfound".equals(reviewResult)) { %><div class="alert alert-warning mt-4">The selected internship could not be found.</div><% } else if ("error".equals(reviewResult)) { %><div class="alert alert-danger mt-4">Unable to update the internship review.</div><% } %>
<ul class="nav nav-pills mt-4" id="reviewTabs" role="tablist"><li class="nav-item"><button class="nav-link active" data-bs-toggle="pill" data-bs-target="#pending" type="button">Pending <span class="badge text-bg-warning"><%= pendingRecords.size() %></span></button></li><li class="nav-item"><button class="nav-link" data-bs-toggle="pill" data-bs-target="#approved" type="button">Approved <span class="badge text-bg-success"><%= approvedRecords.size() %></span></button></li><li class="nav-item"><button class="nav-link" data-bs-toggle="pill" data-bs-target="#rejected" type="button">Rejected <span class="badge text-bg-danger"><%= rejectedRecords.size() %></span></button></li></ul>
<div class="tab-content"><%
List<Map<String, String>>[] groups = new List[] { pendingRecords, approvedRecords, rejectedRecords };
String[] ids = { "pending", "approved", "rejected" }; String[] labels = { "Pending internships needing review", "Approved internships", "Rejected internships" }; String[] classes = { "status-pending", "status-approved", "status-rejected" };
for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) { List<Map<String, String>> records = groups[groupIndex]; %>
<section class="tab-pane fade <%= groupIndex == 0 ? "show active" : "" %>" id="<%= ids[groupIndex] %>"><% if (records.isEmpty()) { %><div class="empty-state mt-4"><i class="bi bi-inbox fs-3"></i><div class="mt-2">No <%= ids[groupIndex] %> internships found.</div></div><% } else { for (Map<String, String> record : records) { int internshipId = Integer.parseInt(record.get("internship_id")); %>
<article class="review-card"><div class="d-flex flex-wrap justify-content-between gap-2"><div><div class="section-title"><i class="bi bi-building me-2"></i><%= escapeHtml(record.get("company_name")) %></div><div class="text-muted">Internship #<%= internshipId %> · Student ID: <%= escapeHtml(record.get("student_id")) %></div></div><span class="status-badge <%= classes[groupIndex] %>"><%= escapeHtml(record.get("status") == null || record.get("status").trim().isEmpty() ? "Pending" : record.get("status")) %></span></div>
<div class="row g-3 mt-1"><div class="col-md-4"><strong>Type</strong><div><%= escapeHtml(record.get("internship_type")) %></div></div><div class="col-md-4"><strong>Start Date</strong><div><%= escapeHtml(record.get("start_date")) %></div></div><div class="col-md-4"><strong>End Date</strong><div><%= escapeHtml(record.get("end_date")) %></div></div></div>
<div class="mt-3"><strong>Remarks</strong><div class="text-muted"><%= hasFile(record, "remarks") ? escapeHtml(record.get("remarks")) : "No remarks added." %></div></div><hr><strong>Documents</strong><div class="d-flex flex-wrap gap-2 mt-2"><% for (String[] document : documentTypes) { if (("bank_statement".equals(document[0]) || "stipend_proof".equals(document[0])) && !"Stipend".equals(record.get("internship_type"))) continue; if (hasFile(record, document[0])) { %><a class="btn btn-sm btn-outline-primary document-link" target="_blank" rel="noopener" href="ViewInternshipDocumentServlet?internship_id=<%= internshipId %>&document_type=<%= document[0] %>"><i class="bi bi-box-arrow-up-right"></i> <%= document[1] %></a><% } else { %><span class="btn btn-sm btn-outline-secondary disabled document-link"><%= document[1] %> unavailable</span><% } } %></div>
<% if (groupIndex == 0) { %><hr><form action="ReviewInternshipServlet" method="post"><input type="hidden" name="csrfToken" value="<%= escapeHtml(csrfToken) %>"><input type="hidden" name="internship_id" value="<%= internshipId %>"><input type="hidden" name="return_to" value="reviews"><div class="mb-3"><label class="form-label">Remarks (optional)</label><textarea name="remarks" class="form-control" rows="3"><%= escapeHtml(record.get("remarks")) %></textarea></div><button type="submit" name="status" value="Approved" class="btn btn-success"><i class="bi bi-check-lg"></i> Approve</button><button type="submit" name="status" value="Rejected" class="btn btn-danger ms-1"><i class="bi bi-x-lg"></i> Reject</button></form><% } %>
</article><% } } %></section><% } %></div></main><script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script></body></html>
