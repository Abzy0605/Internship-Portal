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
String studentId = (String) session.getAttribute("student_id");
if (!"student".equals(role) || studentId == null || studentId.trim().isEmpty()) {
    response.sendRedirect("login.jsp");
    return;
}
String csrfToken = CsrfToken.getOrCreate(session);
int internshipId = 0;
try { internshipId = Integer.parseInt(request.getParameter("internship_id")); } catch (Exception e) { }
String companyName = "", internshipType = "", startDate = "", endDate = "";
boolean editable = false;
if (internshipId > 0) {
    try (Connection con = DBConnector.getConnection(); PreparedStatement ps = con.prepareStatement(
            "SELECT company_name, internship_type, start_date, end_date FROM internship "
            + "WHERE internship_id=? AND student_id=? AND status IN ('Pending','Rejected')")) {
        ps.setInt(1, internshipId); ps.setString(2, studentId);
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                editable = true;
                companyName = rs.getString("company_name"); internshipType = rs.getString("internship_type");
                startDate = String.valueOf(rs.getDate("start_date")); endDate = String.valueOf(rs.getDate("end_date"));
            }
        }
    } catch (Exception e) { editable = false; }
}
String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Edit Internship | EEC Internship Portal</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
<style>
body { background:#f5f7fb; font-family:'Segoe UI',sans-serif; color:#30313a; }
.portal-header { background:#6b1d1d; color:#fff; padding:18px 0; box-shadow:0 2px 10px rgba(0,0,0,.15); }
.portal-card { max-width:800px; margin:45px auto; padding:32px; border:0; border-radius:15px; box-shadow:0 2px 12px rgba(0,0,0,.08); }
.page-title { font-size:28px; font-weight:700; } .btn-portal { background:#6b1d1d; border-color:#6b1d1d; color:#fff; }
.btn-portal:hover { background:#521616; border-color:#521616; color:#fff; }
</style></head><body>
<header class="portal-header"><div class="container d-flex justify-content-between align-items-center"><strong>EEC Internship Management System</strong><a href="student_dashboard.jsp" class="btn btn-light btn-sm"><i class="bi bi-arrow-left"></i> Dashboard</a></div></header>
<main class="container"><section class="card portal-card"><h1 class="page-title mb-2">Edit Internship</h1><p class="text-muted mb-4">Only Pending or Rejected internship records may be changed.</p>
<% if (!editable) { %><div class="alert alert-danger">This internship was not found, does not belong to you, or has already been approved.</div>
<a class="btn btn-portal" href="student_dashboard.jsp">Return to Dashboard</a>
<% } else { %>
<% if (error != null) { %><div class="alert alert-danger">Unable to save the changes. Please check the details and try again.</div><% } %>
<form action="EditInternshipServlet" method="post"><input type="hidden" name="csrfToken" value="<%= csrfToken %>"><input type="hidden" name="internship_id" value="<%= internshipId %>">
<div class="row g-3"><div class="col-md-6"><label class="form-label">Company Name</label><input class="form-control" name="companyName" maxlength="150" required value="<%= escapeHtml(companyName) %>"></div>
<div class="col-md-6"><label class="form-label">Internship Type</label><select class="form-select" name="internshipType" required><option value="Stipend" <%= "Stipend".equals(internshipType) ? "selected" : "" %>>Stipend</option><option value="Non-Stipend" <%= "Non-Stipend".equals(internshipType) ? "selected" : "" %>>Non-Stipend</option></select></div>
<div class="col-md-6"><label class="form-label">Start Date</label><input class="form-control" type="date" name="startDate" required value="<%= escapeHtml(startDate) %>"></div>
<div class="col-md-6"><label class="form-label">End Date</label><input class="form-control" type="date" name="endDate" required value="<%= escapeHtml(endDate) %>"></div></div>
<div class="mt-4 d-flex gap-2"><button class="btn btn-portal" type="submit"><i class="bi bi-save"></i> Save Changes</button><a class="btn btn-outline-secondary" href="student_dashboard.jsp">Cancel</a></div>
</form><% } %></section></main></body></html>
