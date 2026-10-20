<%@ page import="java.sql.*" %>
<%@ page import="com.internship.DBConnector" %>
<%@ page import="com.internship.CsrfToken" %>
<%
String role = (String) session.getAttribute("role"); String studentId = (String) session.getAttribute("student_id");
if (!"student".equals(role) || studentId == null || studentId.trim().isEmpty()) { response.sendRedirect("login.jsp"); return; }
String csrfToken = CsrfToken.getOrCreate(session);
int internshipId = 0; try { internshipId = Integer.parseInt(request.getParameter("internship_id")); } catch (Exception e) { }
boolean editable = false; String internshipType = "";
if (internshipId > 0) {
    try (Connection con = DBConnector.getConnection(); PreparedStatement ps = con.prepareStatement(
            "SELECT internship_type FROM internship WHERE internship_id=? AND student_id=? AND status IN ('Pending','Rejected')")) {
        ps.setInt(1, internshipId); ps.setString(2, studentId);
        try (ResultSet rs = ps.executeQuery()) { if (rs.next()) { editable = true; internshipType = rs.getString("internship_type"); } }
    } catch (Exception e) { editable = false; }
}
String error = request.getParameter("error");
%>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Replace Documents | EEC Internship Portal</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet"><link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
<style>body{background:#f5f7fb;font-family:'Segoe UI',sans-serif}.portal-header{background:#6b1d1d;color:#fff;padding:18px 0}.portal-card{max-width:850px;margin:45px auto;padding:32px;border:0;border-radius:15px;box-shadow:0 2px 12px rgba(0,0,0,.08)}.btn-portal{background:#6b1d1d;border-color:#6b1d1d;color:#fff}.btn-portal:hover{background:#521616;color:#fff}.document-row{border-bottom:1px solid #e8e8e8;padding:18px 0}.document-row:last-child{border-bottom:0}</style></head>
<body><header class="portal-header"><div class="container d-flex justify-content-between"><strong>EEC Internship Management System</strong><a class="btn btn-light btn-sm" href="student_dashboard.jsp"><i class="bi bi-arrow-left"></i> Dashboard</a></div></header>
<main class="container"><section class="card portal-card"><h1 class="h3 fw-bold">Replace Internship Documents</h1><p class="text-muted">Each replacement is saved separately. Allowed: PDF, DOC, DOCX, PPT, PPTX, JPG, JPEG, PNG. Maximum size: 10 MB.</p>
<% if (!editable) { %><div class="alert alert-danger">This internship was not found, does not belong to you, or has already been approved.</div><a class="btn btn-portal" href="student_dashboard.jsp">Return to Dashboard</a>
<% } else { %><% if (error != null) { %><div class="alert alert-danger">The document could not be replaced. Confirm the file and try again.</div><% } %>
<% String[][] documents = {{"offer_letter","Offer Letter"},{"certificate","Internship Certificate"},{"ppt_review","Internship PPT / Review"},{"report_file","Internship Report"},{"bank_statement","Bank Statement"},{"stipend_proof","Stipend Proof"}}; for (String[] document : documents) { if (("bank_statement".equals(document[0]) || "stipend_proof".equals(document[0])) && !"Stipend".equals(internshipType)) continue; %>
<form class="document-row row g-2 align-items-end" action="ReplaceInternshipDocumentServlet" method="post" enctype="multipart/form-data"><input type="hidden" name="csrfToken" value="<%= csrfToken %>"><input type="hidden" name="internship_id" value="<%= internshipId %>"><input type="hidden" name="document_type" value="<%= document[0] %>"><div class="col-md-4 fw-semibold"><%= document[1] %></div><div class="col-md-5"><input class="form-control" type="file" name="document" required accept=".pdf,.doc,.docx,.ppt,.pptx,.jpg,.jpeg,.png"></div><div class="col-md-3"><button class="btn btn-portal w-100" type="submit">Replace</button></div></form><% } %>
<% } %></section></main></body></html>
