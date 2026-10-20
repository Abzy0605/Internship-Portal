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

if (role == null || !role.equals("admin")) {
    response.sendRedirect("login.jsp");
    return;
}
String csrfToken = CsrfToken.getOrCreate(session);
%>

<!DOCTYPE html>
<html lang="en">

<head>

<meta charset="UTF-8">

<meta name="viewport"
      content="width=device-width, initial-scale=1">

<title>Manage Students | EEC Internship Portal</title>

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


/* Highlight current page */

.active-link {

    background: rgba(255,255,255,.15);
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


.admin-badge {

    background: #6b1d1d;

    color: white;

    padding: 8px 18px;

    border-radius: 25px;
}


/* ==============================
   CARDS
   ============================== */

.portal-card {

    background: white;

    border: none;

    border-radius: 18px;

    padding: 25px;

    box-shadow: 0 3px 15px rgba(0,0,0,.08);
}


.section-title {

    font-size: 21px;

    font-weight: 700;

    margin-bottom: 20px;

    color: #222;
}


/* ==============================
   FORM
   ============================== */

.form-label {

    font-weight: 600;
}


.form-control {

    height: 50px;

    border-radius: 12px;
}


.form-control:focus {

    border-color: #7a1d1d;

    box-shadow: none;
}


.primary-btn {

    background: #6b1d1d;

    border: none;

    color: white;

    height: 48px;

    padding: 0 22px;

    border-radius: 12px;

    font-weight: 600;
}


.primary-btn:hover {

    background: #5f1515;

    color: white;
}


/* ==============================
   TABLE
   ============================== */

.table-container {

    overflow-x: auto;
}


.student-table {

    margin-bottom: 0;
}


.student-table thead th {

    background: #6b1d1d;

    color: white;

    border: none;

    padding: 14px;

    white-space: nowrap;
}


.student-table tbody td {

    vertical-align: middle;

    padding: 14px;
}


.student-table tbody tr:hover {

    background: #fafafa;
}


/* ==============================
   ACTION BUTTONS
   ============================== */

.action-btn {

    border-radius: 9px;

    margin: 2px;
}


/* ==============================
   ALERTS
   ============================== */

.alert {

    border-radius: 12px;
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


        <a href="admin_dashboard.jsp">

            <i class="bi bi-speedometer2"></i>

            Dashboard

        </a>


        <a href="manage_students.jsp"
           class="active-link">

            <i class="bi bi-people-fill"></i>

            Students

        </a>


        <a href="#">

            <i class="bi bi-person-workspace"></i>

            Staff

        </a>


        <a href="admin_internship_records.jsp">

            <i class="bi bi-folder-check"></i>

            Internship Records

        </a>


        <a href="#">

            <i class="bi bi-bar-chart-line-fill"></i>

            Reports

        </a>


        <form action="LogoutServlet" method="post"><input type="hidden" name="csrfToken" value="<%= csrfToken %>"><button type="submit" class="btn btn-link text-white p-0"><i class="bi bi-box-arrow-right"></i> Logout</button></form>


    </div>

</div>


<!-- =========================================
     MAIN CONTENT
     ========================================= -->

<div class="main-content">


    <!-- TOPBAR -->

    <div class="topbar">

        <h2 class="page-title">

            Manage Students

        </h2>


        <div class="admin-badge">

            Administrator

        </div>

    </div>



    <!-- =====================================
         ALERT MESSAGES
         ===================================== -->

    <div class="mt-4">

        <%

        if(request.getParameter("success") != null) {

        %>

        <div class="alert alert-success alert-dismissible fade show">

            <i class="bi bi-check-circle-fill me-2"></i>

            Student added successfully.

            <button
                type="button"
                class="btn-close"
                data-bs-dismiss="alert">
            </button>

        </div>

        <%

        }


        if(request.getParameter("updated") != null) {

        %>

        <div class="alert alert-info alert-dismissible fade show">

            <i class="bi bi-info-circle-fill me-2"></i>

            Student updated successfully.

            <button
                type="button"
                class="btn-close"
                data-bs-dismiss="alert">
            </button>

        </div>

        <%

        }


        if(request.getParameter("deleted") != null) {

        %>

        <div class="alert alert-warning alert-dismissible fade show">

            <i class="bi bi-trash-fill me-2"></i>

            Student deleted successfully.

            <button
                type="button"
                class="btn-close"
                data-bs-dismiss="alert">
            </button>

        </div>

        <%

        }


        if(request.getParameter("error") != null) {

        %>

        <div class="alert alert-danger alert-dismissible fade show">

            <i class="bi bi-exclamation-triangle-fill me-2"></i>

            Operation failed.

            <button
                type="button"
                class="btn-close"
                data-bs-dismiss="alert">
            </button>

        </div>

        <%

        }

        %>

    </div>



    <!-- =====================================
         ADD STUDENT
         ===================================== -->

    <div class="portal-card mt-4">


        <div class="section-title">

            <i class="bi bi-person-plus-fill me-2"></i>

            Add Student

        </div>


        <form action="AddStudentServlet"
              method="post">

            <input type="hidden" name="csrfToken" value="<%= csrfToken %>">


            <div class="row">


                <!-- STUDENT ID -->

                <div class="col-md-6 mb-3">

                    <label class="form-label">

                        Student ID

                    </label>

                    <input
                        type="text"
                        name="student_id"
                        class="form-control"
                        placeholder="Enter Student ID"
                        required>

                </div>


                <!-- NAME -->

                <div class="col-md-6 mb-3">

                    <label class="form-label">

                        Student Name

                    </label>

                    <input
                        type="text"
                        name="name"
                        class="form-control"
                        placeholder="Enter Student Name"
                        required>

                </div>


                <!-- DEPARTMENT -->

                <div class="col-md-6 mb-3">

                    <label class="form-label">

                        Department

                    </label>

                    <input
                        type="text"
                        name="department"
                        class="form-control"
                        placeholder="Enter Department"
                        required>

                </div>


                <!-- EMAIL -->

                <div class="col-md-6 mb-3">

                    <label class="form-label">

                        Email

                    </label>

                    <input
                        type="email"
                        name="email"
                        class="form-control"
                        placeholder="Enter Email"
                        required>

                </div>


                <!-- PASSWORD -->

                <div class="col-md-6 mb-3">

                    <label class="form-label">

                        Password

                    </label>

                    <input
                        type="password"
                        name="password"
                        class="form-control"
                        autocomplete="new-password"
                        placeholder="Enter Password"
                        required>
                    <div class="form-text">Use at least 12 characters.</div>

                </div>

            </div>


            <button
                type="submit"
                class="btn primary-btn">

                <i class="bi bi-person-plus-fill me-2"></i>

                Add Student

            </button>


        </form>

    </div>



    <!-- =====================================
         STUDENT LIST
         ===================================== -->

    <div class="portal-card mt-4">


        <div class="section-title">

            <i class="bi bi-people-fill me-2"></i>

            Student List

        </div>


        <div class="table-container">


            <table class="table table-hover student-table">


                <thead>

                    <tr>

                        <th>
                            Student ID
                        </th>

                        <th>
                            Name
                        </th>

                        <th>
                            Department
                        </th>

                        <th>
                            Email
                        </th>

                        <th class="text-center">
                            Actions
                        </th>

                    </tr>

                </thead>


                <tbody>


                <%

                try {


                    Connection con =
                        DBConnector.getConnection();


                    PreparedStatement ps =
                        con.prepareStatement(
                            "SELECT * FROM student " +
                            "ORDER BY student_id"
                        );


                    ResultSet rs =
                        ps.executeQuery();


                    while(rs.next()) {

                %>


                    <tr>


                        <td>

                            <strong>

                                <%= escapeHtml(rs.getString("student_id")) %>

                            </strong>

                        </td>


                        <td>

                            <%= escapeHtml(rs.getString("name")) %>

                        </td>


                        <td>

                            <%= escapeHtml(rs.getString("department")) %>

                        </td>


                        <td>

                            <%= escapeHtml(rs.getString("email")) %>

                        </td>


                        <td class="text-center">


                            <!-- EDIT -->

                            <a
                                href="edit_student.jsp?student_id=<%= java.net.URLEncoder.encode(rs.getString("student_id"), java.nio.charset.StandardCharsets.UTF_8) %>"
                                class="btn btn-primary btn-sm action-btn">

                                <i class="bi bi-pencil-square"></i>

                                Edit

                            </a>


                            <!-- DELETE -->

                            <form action="DeleteStudentServlet" method="post" class="d-inline"
                                  onsubmit="return confirm('Are you sure you want to delete this student?');">
                                <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                                <input type="hidden" name="student_id" value="<%= escapeHtml(rs.getString("student_id")) %>">
                                <button type="submit" class="btn btn-danger btn-sm action-btn">
                                    <i class="bi bi-trash"></i>
                                    Delete
                                </button>
                            </form>


                        </td>


                    </tr>


                <%

                    }


                    rs.close();

                    ps.close();

                    con.close();


                }

                catch(Exception e) {

                %>


                    <tr>

                        <td
                            colspan="5"
                            class="text-center text-danger">

                            <i class="bi bi-exclamation-triangle-fill me-2"></i>

                            Unable to load student records.

                        </td>

                    </tr>


                <%

                    e.printStackTrace();

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
