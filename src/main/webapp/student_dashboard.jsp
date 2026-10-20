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
%>

<%
/* ============================================================
   SESSION / ROLE CHECK
   ============================================================ */

String role = (String) session.getAttribute("role");

if (role == null || !role.equals("student")) {

    response.sendRedirect("login.jsp");
    return;
}


/* ============================================================
   GET STUDENT ID FROM SESSION
   ============================================================ */

String studentId =
        (String) session.getAttribute("student_id");

if (studentId == null || studentId.trim().isEmpty()) {

    response.sendRedirect("login.jsp");
    return;
}

String csrfToken = CsrfToken.getOrCreate(session);


/* ============================================================
   INTERNSHIP VARIABLES
   ============================================================ */

List<Map<String, String>> internships =
    new ArrayList<Map<String, String>>();

boolean internshipExists = false;

int internshipId = 0;

String companyName = "";
String internshipType = "";
String startDate = "";
String endDate = "";

String offerLetter = null;
String certificate = null;
String pptReview = null;
String reportFile = null;
String bankStatement = null;
String stipendProof = null;

String status = "";
String remarks = "";


/* ============================================================
   FETCH INTERNSHIP RECORD
   ============================================================ */

try {

    Connection con = DBConnector.getConnection();

    String query =
        "SELECT internship_id, company_name, internship_type, " +
        "start_date, end_date, offer_letter, certificate, " +
        "ppt_review, report_file, bank_statement, " +
        "stipend_proof, status, remarks " +
        "FROM internship " +
        "WHERE student_id=? " +
        "ORDER BY internship_id DESC";

    PreparedStatement ps =
        con.prepareStatement(query);

    ps.setString(1, studentId);

    ResultSet rs =
        ps.executeQuery();

    while (rs.next()) {

        Map<String, String> internship =
            new HashMap<String, String>();

        internship.put(
            "internship_id",
            rs.getString("internship_id")
        );
        internship.put(
            "company_name",
            rs.getString("company_name")
        );
        internship.put(
            "internship_type",
            rs.getString("internship_type")
        );
        internship.put(
            "start_date",
            rs.getString("start_date")
        );
        internship.put(
            "end_date",
            rs.getString("end_date")
        );
        internship.put(
            "offer_letter",
            rs.getString("offer_letter")
        );
        internship.put(
            "certificate",
            rs.getString("certificate")
        );
        internship.put(
            "ppt_review",
            rs.getString("ppt_review")
        );
        internship.put(
            "report_file",
            rs.getString("report_file")
        );
        internship.put(
            "bank_statement",
            rs.getString("bank_statement")
        );
        internship.put(
            "stipend_proof",
            rs.getString("stipend_proof")
        );
        internship.put(
            "status",
            rs.getString("status")
        );
        internship.put(
            "remarks",
            rs.getString("remarks")
        );

        internships.add(internship);
    }

    internshipExists = !internships.isEmpty();

    rs.close();
    ps.close();
    con.close();

}
catch (Exception e) {

    e.printStackTrace();
}


/* ============================================================
   REQUEST MESSAGE
   ============================================================ */

String success =
    request.getParameter("success");

String error =
    request.getParameter("error");

%>


<!DOCTYPE html>

<html lang="en">

<head>

    <meta charset="UTF-8">

    <meta name="viewport"
          content="width=device-width, initial-scale=1">

    <title>
        Student Dashboard | EEC Internship Portal
    </title>


    <!-- Bootstrap -->

    <link
        href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
        rel="stylesheet">


    <!-- Bootstrap Icons -->

    <link
        rel="stylesheet"
        href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">


    <style>

        * {
            box-sizing: border-box;
        }


        body {

            background: #f5f7fb;

            font-family: 'Segoe UI', sans-serif;

            overflow-x: hidden;

        }


        /* ====================================================
           HEADER
           ==================================================== */

        .header {

            background: #6b1d1d;

            color: white;

            padding: 20px 30px;

            box-shadow:
                0 2px 12px rgba(0,0,0,.08);

            position: relative;

        }


        .header-content {

            display: flex;

            justify-content: center;

            align-items: center;

            gap: 15px;

        }


        .college-logo {

            width: 65px;

            height: 65px;

            object-fit: contain;

            background: white;

            border-radius: 12px;

            padding: 5px;

        }


        .college-name {

            font-size: 28px;

            font-weight: 700;

            text-align: center;

        }


        .portal-name {

            font-size: 14px;

            text-align: center;

            opacity: .9;

        }


        /* ====================================================
           PROFILE MENU
           ==================================================== */

        .profile-menu {

            position: absolute;

            top: 20px;

            right: 30px;

        }


        .avatar-btn {

            width: 50px;

            height: 50px;

            border-radius: 50%;

            border: none;

            background: white;

            color: #6b1d1d;

            font-size: 28px;

            display: flex;

            align-items: center;

            justify-content: center;

            box-shadow:
                0 2px 8px rgba(0,0,0,.15);

            transition: .3s;

        }


        .avatar-btn:hover {

            transform: scale(1.05);

            background: #f8f9fa;

        }


        /* ====================================================
           MAIN CARD
           ==================================================== */

        .dashboard-card {

            margin-top: 30px;

            margin-bottom: 30px;

            border: none;

            border-radius: 18px;

            box-shadow:
                0 3px 15px rgba(0,0,0,.08);

            overflow: hidden;

        }


        .dashboard-header {

            background: white;

            color: #222;

            padding: 22px 28px;

            border-bottom: 1px solid #eee;

            font-size: 22px;

            font-weight: 700;

        }


        .dashboard-header i {

            color: #6b1d1d;

            margin-right: 10px;

        }


        .dashboard-body {

            padding: 30px;

        }


        /* ====================================================
           ALERTS
           ==================================================== */

        .portal-alert {

            border-radius: 12px;

            border: none;

        }


        /* ====================================================
           SECTION TITLE
           ==================================================== */

        .section-title {

            border-left: 5px solid #6b1d1d;

            padding-left: 12px;

            font-weight: 700;

            margin-bottom: 20px;

            color: #222;

        }


        /* ====================================================
           FORM
           ==================================================== */

        .form-label {

            font-weight: 600;

        }


        .form-control,
        .form-select {

            min-height: 50px;

            border-radius: 12px;

            border: 1px solid #dee2e6;

        }


        .form-control:focus,
        .form-select:focus {

            border-color: #6b1d1d;

            box-shadow: none;

        }


        /* ====================================================
           INFO BOX
           ==================================================== */

        .info-box {

            background: #fdf4f4;

            border: 1px solid #ead1d1;

            border-radius: 12px;

            padding: 15px;

            margin-top: 15px;

            margin-bottom: 15px;

            color: #6b1d1d;

        }


        /* ====================================================
           INTERNSHIP DETAILS CARD
           ==================================================== */

        .detail-card {

            background: #fafafa;

            border: 1px solid #e8e8e8;

            border-radius: 14px;

            padding: 20px;

            height: 100%;

        }


        .detail-label {

            color: #777;

            font-size: 13px;

            margin-bottom: 5px;

        }


        .detail-value {

            font-size: 17px;

            font-weight: 600;

            color: #222;

        }


        /* ====================================================
           STATUS BADGES
           ==================================================== */

        .status-badge {

            display: inline-block;

            padding: 8px 18px;

            border-radius: 25px;

            font-weight: 700;

            font-size: 14px;

        }


        .status-pending {

            background: #fff3cd;

            color: #856404;

        }


        .status-approved {

            background: #d1e7dd;

            color: #0f5132;

        }


        .status-rejected {

            background: #f8d7da;

            color: #842029;

        }


        /* ====================================================
           DOCUMENT STATUS
           ==================================================== */

        .document-table {

            border-radius: 12px;

            overflow: hidden;

            border: 1px solid #e5e5e5;

        }


        .document-table thead th {

            background: #6b1d1d;

            color: white;

            border: none;

            padding: 14px;

        }


        .document-table tbody td {

            padding: 14px;

            vertical-align: middle;

        }


        .document-uploaded {

            color: #198754;

            font-weight: 700;

        }


        .document-missing {

            color: #dc3545;

            font-weight: 700;

        }


        /* ====================================================
           COMPLETION
           ==================================================== */

        .completion-box {

            background: #f7f1f1;

            border: 1px solid #ead1d1;

            border-radius: 15px;

            padding: 20px;

            text-align: center;

            margin-top: 25px;

        }


        .completion-box h5 {

            color: #777;

            margin-bottom: 8px;

        }


        .completion-box h3 {

            color: #6b1d1d;

            font-weight: 700;

        }


        /* ====================================================
           REMARKS
           ==================================================== */

        .remarks-box {

            background: #f8f9fa;

            border-left: 5px solid #6b1d1d;

            border-radius: 10px;

            padding: 18px;

        }


        .remarks-empty {

            color: #777;

            font-style: italic;

        }


        /* ====================================================
           SUBMIT BUTTON
           ==================================================== */

        .submit-btn {

            background: #6b1d1d;

            color: white;

            border: none;

            padding: 12px 35px;

            border-radius: 12px;

            font-weight: 600;

            transition: .3s;

        }


        .submit-btn:hover {

            background: #5f1515;

            color: white;

            transform: translateY(-2px);

        }


        /* ====================================================
           RESPONSIVE
           ==================================================== */

        @media (max-width: 768px) {

            .header {

                padding: 20px 15px;

            }


            .header-content {

                justify-content: flex-start;

                padding-right: 60px;

            }


            .college-name {

                font-size: 20px;

            }


            .portal-name {

                font-size: 12px;

            }


            .college-logo {

                width: 50px;

                height: 50px;

            }


            .profile-menu {

                right: 15px;

            }


            .dashboard-body {

                padding: 20px;

            }

        }

    </style>

</head>


<body>


<!-- ========================================================
     HEADER
     ======================================================== -->

<div class="header">


    <!-- PROFILE -->

    <div class="profile-menu">

        <div class="dropdown">


            <button
                class="avatar-btn"
                type="button"
                data-bs-toggle="dropdown"
                aria-expanded="false">

                <i class="bi bi-person-circle"></i>

            </button>


            <ul class="dropdown-menu dropdown-menu-end">


                <li>

                    <h6 class="dropdown-header">

                        <%= escapeHtml(String.valueOf(session.getAttribute("name"))) %>

                    </h6>

                </li>


                <li>

                    <a
                        class="dropdown-item"
                        href="#">

                        <i class="bi bi-person me-2"></i>

                        My Profile

                    </a>

                </li>


                <li>

                    <a
                        class="dropdown-item"
                        href="#">

                        <i class="bi bi-key me-2"></i>

                        Change Password

                    </a>

                </li>


                <li>

                    <hr class="dropdown-divider">

                </li>


                <li>

                    <form action="LogoutServlet" method="post"><input type="hidden" name="csrfToken" value="<%= escapeHtml(csrfToken) %>"><button type="submit" class="dropdown-item text-danger"><i class="bi bi-box-arrow-right me-2"></i> Logout</button></form>

                </li>


            </ul>

        </div>

    </div>


    <!-- HEADER CONTENT -->

    <div class="header-content">


        <img
            src="images/EEC_logo.png"
            alt="College Logo"
            class="college-logo">


        <div>

            <div class="college-name">

                EASWARI ENGINEERING COLLEGE

            </div>


            <div class="portal-name">

                Internship Management and Review System

            </div>

        </div>


    </div>


</div>


<!-- ========================================================
     MAIN
     ======================================================== -->

<div class="container">


    <div class="card dashboard-card">


        <div class="dashboard-header">

            <i class="bi bi-mortarboard-fill"></i>

            Student Internship Dashboard

        </div>


        <div class="dashboard-body">


            <!-- =================================================
                 SUCCESS MESSAGE
                 ================================================= -->

            <% if (success != null) { %>

                <div
                    class="alert alert-success portal-alert"
                    role="alert">

                    <i class="bi bi-check-circle-fill me-2"></i>

                    <% if ("updated".equals(success)) { %>
                        Internship details updated successfully.
                    <% } else if ("document".equals(success)) { %>
                        Document replaced successfully.
                    <% } else if ("deleted".equals(success)) { %>
                        Internship and its uploaded documents were deleted successfully.
                    <% } else if ("deletedfiles".equals(success)) { %>
                        Internship was deleted. One or more old files could not be removed.
                    <% } else { %>
                        Internship submitted successfully.
                    <% } %>

                </div>

            <% } %>


            <!-- =================================================
                 ERROR MESSAGES
                 ================================================= -->

            <% if ("student".equals(error)) { %>

                <div
                    class="alert alert-danger portal-alert"
                    role="alert">

                    <i class="bi bi-exclamation-triangle-fill me-2"></i>

                    Unable to identify your student account.
                    Please log in again.

                </div>

            <% } %>


            <% if ("required".equals(error)) { %>

                <div
                    class="alert alert-danger portal-alert"
                    role="alert">

                    Please fill in all required internship details.

                </div>

            <% } %>


            <% if ("type".equals(error)) { %>

                <div
                    class="alert alert-danger portal-alert"
                    role="alert">

                    Invalid internship type.

                </div>

            <% } %>


            <% if ("date".equals(error)) { %>

                <div
                    class="alert alert-danger portal-alert"
                    role="alert">

                    Please enter valid internship dates.

                </div>

            <% } %>


            <% if ("dateorder".equals(error)) { %>

                <div
                    class="alert alert-danger portal-alert"
                    role="alert">

                    Internship end date cannot be before
                    the start date.

                </div>

            <% } %>


            <% if ("documents".equals(error)) { %>

                <div
                    class="alert alert-danger portal-alert"
                    role="alert">

                    Please upload all four required
                    internship documents.

                </div>

            <% } %>


            <% if ("stipenddocs".equals(error)) { %>

                <div
                    class="alert alert-danger portal-alert"
                    role="alert">

                    Bank Statement and Stipend Proof are
                    required for stipend internships.

                </div>

            <% } %>


            <% if ("exists".equals(error)) { %>

                <div
                    class="alert alert-warning portal-alert"
                    role="alert">

                    You have already submitted an internship.

                </div>

            <% } %>


            <% if ("upload".equals(error)) { %>

                <div
                    class="alert alert-danger portal-alert"
                    role="alert">

                    There was a problem saving your uploaded
                    documents.

                </div>

            <% } %>


            <% if ("database".equals(error)) { %>

                <div
                    class="alert alert-danger portal-alert"
                    role="alert">

                    There was a problem saving your internship
                    submission. Please try again.

                </div>

            <% } %>

            <% if ("deleteinvalid".equals(error) || "deletelocked".equals(error)) { %>
                <div class="alert alert-danger portal-alert" role="alert">
                    This internship was not found, does not belong to you, or has already been approved.
                </div>
            <% } %>

            <% if ("deletedatabase".equals(error)) { %>
                <div class="alert alert-danger portal-alert" role="alert">
                    The internship could not be deleted. Please try again.
                </div>
            <% } %>

            <% if ("deletefiles".equals(error)) { %>
                <div class="alert alert-danger portal-alert" role="alert">
                    The internship was not deleted because its uploaded files could not be safely removed.
                </div>
            <% } %>


            <!-- =================================================
                 IF INTERNSHIP EXISTS
                 ================================================= -->

            <% if (internshipExists) {

            %>

                <h3 class="section-title">

                    My Internships

                </h3>

            <%

                for (Map<String, String> internship : internships) {

                    internshipId =
                        Integer.parseInt(internship.get("internship_id"));
                    companyName = internship.get("company_name");
                    internshipType = internship.get("internship_type");
                    startDate = internship.get("start_date");
                    endDate = internship.get("end_date");
                    offerLetter = internship.get("offer_letter");
                    certificate = internship.get("certificate");
                    pptReview = internship.get("ppt_review");
                    reportFile = internship.get("report_file");
                    bankStatement = internship.get("bank_statement");
                    stipendProof = internship.get("stipend_proof");
                    status = internship.get("status");
                    remarks = internship.get("remarks");

                    if (status == null || status.trim().isEmpty()) {
                        status = "Pending";
                    }

                    boolean offerUploaded =
                        offerLetter != null &&
                        !offerLetter.trim().isEmpty();

                    boolean certificateUploaded =
                        certificate != null &&
                        !certificate.trim().isEmpty();

                    boolean pptUploaded =
                        pptReview != null &&
                        !pptReview.trim().isEmpty();

                    boolean reportUploaded =
                        reportFile != null &&
                        !reportFile.trim().isEmpty();

                    int uploadedDocuments = 0;

                    if (offerUploaded) {
                        uploadedDocuments++;
                    }

                    if (certificateUploaded) {
                        uploadedDocuments++;
                    }

                    if (pptUploaded) {
                        uploadedDocuments++;
                    }

                    if (reportUploaded) {
                        uploadedDocuments++;
                    }

                    String statusClass = "status-pending";
                    boolean canModify = "Pending".equalsIgnoreCase(status) ||
                            "Rejected".equalsIgnoreCase(status);

                    if ("Approved".equalsIgnoreCase(status)) {
                        statusClass = "status-approved";
                    }
                    else if ("Rejected".equalsIgnoreCase(status)) {
                        statusClass = "status-rejected";
                    }
            %>


                <!-- =============================================
                     SUBMISSION OVERVIEW
                     ============================================= -->

                <h3 class="section-title" id="internship-<%= internshipId %>">

                    Internship Details

                </h3>

                <div class="d-flex flex-wrap gap-2 mb-4">
                    <% if (canModify) { %>
                        <a class="btn btn-sm btn-outline-primary" href="edit_internship.jsp?internship_id=<%= internshipId %>"><i class="bi bi-pencil-square"></i> Edit</a>
                        <a class="btn btn-sm btn-outline-secondary" href="replace_internship_documents.jsp?internship_id=<%= internshipId %>"><i class="bi bi-file-earmark-arrow-up"></i> Replace Documents</a>
                        <form action="DeleteInternshipServlet" method="post" class="d-inline" onsubmit="return confirm('Delete this internship and its uploaded documents?');">
                            <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                            <input type="hidden" name="internship_id" value="<%= internshipId %>">
                            <button class="btn btn-sm btn-outline-danger" type="submit"><i class="bi bi-trash"></i> Delete</button>
                        </form>
                    <% } else { %>
                        <a class="btn btn-sm btn-outline-secondary" href="#internship-<%= internshipId %>"><i class="bi bi-eye"></i> View Details</a>
                    <% } %>
                </div>


                <div class="row g-3">


                    <!-- COMPANY -->

                    <div class="col-md-6">

                        <div class="detail-card">

                            <div class="detail-label">

                                Company Name

                            </div>

                            <div class="detail-value">

                                <%= escapeHtml(companyName) %>

                            </div>

                        </div>

                    </div>


                    <!-- TYPE -->

                    <div class="col-md-6">

                        <div class="detail-card">

                            <div class="detail-label">

                                Internship Type

                            </div>

                            <div class="detail-value">

                                <%= escapeHtml(internshipType) %>

                            </div>

                        </div>

                    </div>


                    <!-- START DATE -->

                    <div class="col-md-6">

                        <div class="detail-card">

                            <div class="detail-label">

                                Start Date

                            </div>

                            <div class="detail-value">

                                <%= escapeHtml(startDate) %>

                            </div>

                        </div>

                    </div>


                    <!-- END DATE -->

                    <div class="col-md-6">

                        <div class="detail-card">

                            <div class="detail-label">

                                End Date

                            </div>

                            <div class="detail-value">

                                <%= escapeHtml(endDate) %>

                            </div>

                        </div>

                    </div>


                </div>


                <hr class="my-4">


                <!-- =============================================
                     OVERALL STATUS
                     ============================================= -->

                <h3 class="section-title">

                    Review Status

                </h3>


                <div class="detail-card mb-4">


                    <div class="d-flex
                                justify-content-between
                                align-items-center
                                flex-wrap
                                gap-3">


                        <div>

                            <div class="detail-label">

                                Internship Submission Status

                            </div>


                            <div class="mt-2">

                                <span
                                    class="status-badge
                                    <%= statusClass %>">

                                    <%= escapeHtml(status) %>

                                </span>

                            </div>

                        </div>


                        <div class="text-muted">

                            Internship ID:
                            <strong>
                                #<%= internshipId %>
                            </strong>

                        </div>


                    </div>


                </div>


                <!-- =============================================
                     DOCUMENT STATUS
                     ============================================= -->

                <h3 class="section-title">

                    Submitted Documents

                </h3>


                <div class="table-responsive">


                    <table
                        class="table document-table">


                        <thead>

                            <tr>

                                <th>
                                    Document
                                </th>

                                <th>
                                    Status
                                </th>

                            </tr>

                        </thead>


                        <tbody>


                            <!-- OFFER -->

                            <tr>

                                <td>

                                    <i class="bi bi-file-earmark-text me-2"></i>

                                    Offer Letter

                                </td>


                                <td>

                                    <% if (offerUploaded) { %>

                                        <span
                                            class="document-uploaded">

                                            <i class="bi bi-check-circle-fill"></i>

                                            Uploaded

                                        </span>

                                        <a class="btn btn-sm btn-outline-primary ms-2" target="_blank" rel="noopener"
                                           href="ViewInternshipDocumentServlet?internship_id=<%= internshipId %>&document_type=offer_letter">
                                            <i class="bi bi-box-arrow-up-right"></i> View
                                        </a>

                                    <% } else { %>

                                        <span
                                            class="document-missing">

                                            <i class="bi bi-x-circle-fill"></i>

                                            Not Uploaded

                                        </span>

                                    <% } %>

                                </td>

                            </tr>


                            <!-- CERTIFICATE -->

                            <tr>

                                <td>

                                    <i class="bi bi-award me-2"></i>

                                    Internship Certificate

                                </td>


                                <td>

                                    <% if (certificateUploaded) { %>

                                        <span
                                            class="document-uploaded">

                                            <i class="bi bi-check-circle-fill"></i>

                                            Uploaded

                                        </span>

                                        <a class="btn btn-sm btn-outline-primary ms-2" target="_blank" rel="noopener"
                                           href="ViewInternshipDocumentServlet?internship_id=<%= internshipId %>&document_type=certificate">
                                            <i class="bi bi-box-arrow-up-right"></i> View
                                        </a>

                                    <% } else { %>

                                        <span
                                            class="document-missing">

                                            <i class="bi bi-x-circle-fill"></i>

                                            Not Uploaded

                                        </span>

                                    <% } %>

                                </td>

                            </tr>


                            <!-- PPT -->

                            <tr>

                                <td>

                                    <i class="bi bi-file-earmark-slides me-2"></i>

                                    Internship PPT / Review

                                </td>


                                <td>

                                    <% if (pptUploaded) { %>

                                        <span
                                            class="document-uploaded">

                                            <i class="bi bi-check-circle-fill"></i>

                                            Uploaded

                                        </span>

                                        <a class="btn btn-sm btn-outline-primary ms-2" target="_blank" rel="noopener"
                                           href="ViewInternshipDocumentServlet?internship_id=<%= internshipId %>&document_type=ppt_review">
                                            <i class="bi bi-box-arrow-up-right"></i> View
                                        </a>

                                    <% } else { %>

                                        <span
                                            class="document-missing">

                                            <i class="bi bi-x-circle-fill"></i>

                                            Not Uploaded

                                        </span>

                                    <% } %>

                                </td>

                            </tr>


                            <!-- REPORT -->

                            <tr>

                                <td>

                                    <i class="bi bi-file-earmark-text me-2"></i>

                                    Internship Report

                                </td>


                                <td>

                                    <% if (reportUploaded) { %>

                                        <span
                                            class="document-uploaded">

                                            <i class="bi bi-check-circle-fill"></i>

                                            Uploaded

                                        </span>

                                        <a class="btn btn-sm btn-outline-primary ms-2" target="_blank" rel="noopener"
                                           href="ViewInternshipDocumentServlet?internship_id=<%= internshipId %>&document_type=report_file">
                                            <i class="bi bi-box-arrow-up-right"></i> View
                                        </a>

                                    <% } else { %>

                                        <span
                                            class="document-missing">

                                            <i class="bi bi-x-circle-fill"></i>

                                            Not Uploaded

                                        </span>

                                    <% } %>

                                </td>

                            </tr>


                            <!-- BANK STATEMENT -->

                            <% if ("Stipend".equals(internshipType)) { %>

                                <tr>

                                    <td>

                                        <i class="bi bi-bank me-2"></i>

                                        Bank Statement

                                    </td>


                                    <td>

                                        <% if (bankStatement != null &&
                                              !bankStatement.trim().isEmpty()) { %>

                                            <span
                                                class="document-uploaded">

                                                <i class="bi bi-check-circle-fill"></i>

                                                Uploaded

                                            </span>

                                            <a class="btn btn-sm btn-outline-primary ms-2" target="_blank" rel="noopener"
                                               href="ViewInternshipDocumentServlet?internship_id=<%= internshipId %>&document_type=bank_statement">
                                                <i class="bi bi-box-arrow-up-right"></i> View
                                            </a>

                                        <% } else { %>

                                            <span
                                                class="document-missing">

                                                <i class="bi bi-x-circle-fill"></i>

                                                Not Uploaded

                                            </span>

                                        <% } %>

                                    </td>

                                </tr>


                                <!-- STIPEND PROOF -->

                                <tr>

                                    <td>

                                        <i class="bi bi-cash-stack me-2"></i>

                                        Stipend Proof

                                    </td>


                                    <td>

                                        <% if (stipendProof != null &&
                                              !stipendProof.trim().isEmpty()) { %>

                                            <span
                                                class="document-uploaded">

                                                <i class="bi bi-check-circle-fill"></i>

                                                Uploaded

                                            </span>

                                            <a class="btn btn-sm btn-outline-primary ms-2" target="_blank" rel="noopener"
                                               href="ViewInternshipDocumentServlet?internship_id=<%= internshipId %>&document_type=stipend_proof">
                                                <i class="bi bi-box-arrow-up-right"></i> View
                                            </a>

                                        <% } else { %>

                                            <span
                                                class="document-missing">

                                                <i class="bi bi-x-circle-fill"></i>

                                                Not Uploaded

                                            </span>

                                        <% } %>

                                    </td>

                                </tr>

                            <% } %>


                        </tbody>


                    </table>


                </div>


                <!-- =============================================
                     COMPLETION
                     ============================================= -->

                <div class="completion-box">


                    <h5>

                        Required Document Completion

                    </h5>


                    <h3>

                        <%= uploadedDocuments %> / 4

                        Documents Uploaded

                    </h3>


                </div>


                <!-- =============================================
                     REMARKS
                     ============================================= -->

                <div class="mt-4">


                    <h3 class="section-title">

                        Mentor / Administrator Remarks

                    </h3>


                    <div class="remarks-box">


                        <% if (remarks != null &&
                               !remarks.trim().isEmpty()) { %>


                            <i class="bi bi-chat-left-text me-2"></i>

                            <%= escapeHtml(remarks) %>


                        <% } else { %>


                            <span class="remarks-empty">

                                No remarks have been added yet.

                            </span>


                        <% } %>


                    </div>


                </div>


              <%
                 }
              } %>


              <!-- =================================================
                  SUBMIT NEW INTERNSHIP
                  ================================================= -->


                <h3 class="section-title">

                    Submit Internship

                </h3>


                <div class="info-box">

                    <i class="bi bi-info-circle me-2"></i>

                    Submit your internship details and required
                    documents for faculty review.

                </div>


                <!-- =============================================
                     SUBMISSION FORM
                     ============================================= -->

                <form
                    action="SubmitInternshipServlet"
                    method="post"
                    enctype="multipart/form-data"
                    id="internshipForm">

                    <input type="hidden" name="csrfToken" value="<%= csrfToken %>">


                    <!-- =========================================
                         INTERNSHIP DETAILS
                         ========================================= -->

                    <div class="row">


                        <!-- COMPANY -->

                        <div class="col-md-6 mb-3">

                            <label class="form-label">

                                Company Name

                            </label>


                            <input
                                type="text"
                                name="companyName"
                                class="form-control"
                                placeholder="Enter company name"
                                maxlength="150"
                                required>

                        </div>


                        <!-- TYPE -->

                        <div class="col-md-6 mb-3">

                            <label class="form-label">

                                Internship Type

                            </label>


                            <select
                                class="form-select"
                                name="internshipType"
                                id="internshipType"
                                onchange="toggleStipendFields()"
                                required>


                                <option value="">

                                    Select Internship Type

                                </option>


                                <option value="Non-Stipend">

                                    Non-Stipend

                                </option>


                                <option value="Stipend">

                                    Stipend

                                </option>


                            </select>

                        </div>


                        <!-- START DATE -->

                        <div class="col-md-6 mb-3">

                            <label class="form-label">

                                Internship Start Date

                            </label>


                            <input
                                type="date"
                                name="startDate"
                                class="form-control"
                                required>

                        </div>


                        <!-- END DATE -->

                        <div class="col-md-6 mb-3">

                            <label class="form-label">

                                Internship End Date

                            </label>


                            <input
                                type="date"
                                name="endDate"
                                class="form-control"
                                required>

                        </div>


                    </div>


                    <hr class="my-4">


                    <!-- =========================================
                         DOCUMENTS
                         ========================================= -->

                    <h3 class="section-title">

                        Required Documents

                    </h3>


                    <!-- OFFER LETTER -->

                    <div class="mb-3">

                        <label class="form-label">

                            Internship Offer Letter

                        </label>


                        <input
                            type="file"
                            name="offerLetter"
                            class="form-control"
                            id="offerLetter"
                            onchange="updateStatus()">

                    </div>


                    <!-- CERTIFICATE -->

                    <div class="mb-3">

                        <label class="form-label">

                            Internship Certificate

                        </label>


                        <input
                            type="file"
                            name="certificate"
                            class="form-control"
                            id="certificate"
                            onchange="updateStatus()">

                    </div>


                    <!-- PPT -->

                    <div class="mb-3">

                        <label class="form-label">

                            Internship PPT / Review

                        </label>


                        <input
                            type="file"
                            name="ppt"
                            class="form-control"
                            id="ppt"
                            onchange="updateStatus()">

                    </div>


                    <!-- REPORT -->

                    <div class="mb-3">

                        <label class="form-label">

                            Internship Report

                        </label>


                        <input
                            type="file"
                            name="report"
                            class="form-control"
                            id="report"
                            onchange="updateStatus()">

                    </div>


                    <hr class="my-4">


                    <!-- =========================================
                         STIPEND
                         ========================================= -->

                    <h3 class="section-title">

                        Stipend Documents

                    </h3>


                    <div
                        id="stipendSection"
                        style="display:none;">


                        <div class="info-box">

                            <i class="bi bi-info-circle me-2"></i>

                            Upload the following documents only if
                            your internship includes a stipend.

                        </div>


                        <!-- BANK -->

                        <div class="mb-3">

                            <label class="form-label">

                                Bank Statement

                            </label>


                            <input
                                type="file"
                                name="bankStatement"
                                class="form-control">

                        </div>


                        <!-- STIPEND PROOF -->

                        <div class="mb-3">

                            <label class="form-label">

                                Stipend Proof

                            </label>


                            <input
                                type="file"
                                name="stipendProof"
                                class="form-control">

                        </div>


                    </div>


                    <!-- =========================================
                         LOCAL FILE STATUS
                         ========================================= -->

                    <hr class="my-4">


                    <h3 class="section-title">

                        Current Upload Status

                    </h3>


                    <div class="table-responsive">


                        <table class="table document-table">


                            <thead>

                                <tr>

                                    <th>
                                        Document
                                    </th>

                                    <th>
                                        Status
                                    </th>

                                </tr>

                            </thead>


                            <tbody>


                                <tr>

                                    <td>
                                        Offer Letter
                                    </td>

                                    <td
                                        id="offerStatus"
                                        class="document-missing">

                                        Not Uploaded

                                    </td>

                                </tr>


                                <tr>

                                    <td>
                                        Internship Certificate
                                    </td>

                                    <td
                                        id="certificateStatus"
                                        class="document-missing">

                                        Not Uploaded

                                    </td>

                                </tr>


                                <tr>

                                    <td>
                                        Internship PPT / Review
                                    </td>

                                    <td
                                        id="pptStatus"
                                        class="document-missing">

                                        Not Uploaded

                                    </td>

                                </tr>


                                <tr>

                                    <td>
                                        Internship Report
                                    </td>

                                    <td
                                        id="reportStatus"
                                        class="document-missing">

                                        Not Uploaded

                                    </td>

                                </tr>


                            </tbody>


                        </table>


                    </div>


                    <!-- =========================================
                         COMPLETION
                         ========================================= -->

                    <div class="completion-box">


                        <h5>

                            Completion Status

                        </h5>


                        <h3 id="completionCount">

                            0 / 4 Documents Uploaded

                        </h3>


                    </div>


                    <!-- =========================================
                         SUBMIT
                         ========================================= -->

                    <div class="text-center mt-4">


                        <button
                            type="submit"
                            class="btn submit-btn">


                            <i
                                class="bi bi-cloud-arrow-up me-2">
                            </i>


                            Submit Internship


                        </button>


                    </div>


                </form>


        </div>

    </div>

</div>


<!-- ========================================================
     JAVASCRIPT
     ======================================================== -->

<script>


function toggleStipendFields()
{

    var internshipType =
        document.getElementById("internshipType");


    var stipendSection =
        document.getElementById("stipendSection");


    if (!internshipType ||
        !stipendSection) {

        return;

    }


    if (internshipType.value === "Stipend") {

        stipendSection.style.display =
            "block";

    }
    else {

        stipendSection.style.display =
            "none";

    }

}


function updateStatus()
{

    var uploadedCount = 0;


    checkFile(
        "offerLetter",
        "offerStatus"
    );


    checkFile(
        "certificate",
        "certificateStatus"
    );


    checkFile(
        "ppt",
        "pptStatus"
    );


    checkFile(
        "report",
        "reportStatus"
    );


    function checkFile(
        fileId,
        statusId
    )
    {

        var fileInput =
            document.getElementById(fileId);


        var statusCell =
            document.getElementById(statusId);


        if (!fileInput ||
            !statusCell) {

            return;

        }


        if (fileInput.files.length > 0) {

            statusCell.innerHTML =
                '<i class="bi bi-check-circle-fill"></i> Uploaded';

            statusCell.className =
                "document-uploaded";

            uploadedCount++;

        }
        else {

            statusCell.innerHTML =
                '<i class="bi bi-x-circle-fill"></i> Not Uploaded';

            statusCell.className =
                "document-missing";

        }

    }


    var completionCount =
        document.getElementById(
            "completionCount"
        );


    if (completionCount) {

        completionCount.innerHTML =
            uploadedCount
            + " / 4 Documents Uploaded";

    }

}


window.onload = function()
{

    toggleStipendFields();

    updateStatus();

};


</script>


<!-- ========================================================
     BOOTSTRAP JS
     ======================================================== -->

<script
    src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js">
</script>


</body>

</html>
