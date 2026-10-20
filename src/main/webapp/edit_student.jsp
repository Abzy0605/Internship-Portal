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

String studentId = request.getParameter("student_id");

String name = "";
String department = "";
String email = "";

try {

    Connection con = DBConnector.getConnection();

    PreparedStatement ps =
        con.prepareStatement(
            "SELECT student_id, name, department, email FROM student WHERE student_id=?"
        );

    ps.setString(1, studentId);

    ResultSet rs = ps.executeQuery();

    if (rs.next()) {

        name = rs.getString("name");
        department = rs.getString("department");
        email = rs.getString("email");
    }

    rs.close();
    ps.close();
    con.close();

}
catch(Exception e) {

    e.printStackTrace();
}
%>

<!DOCTYPE html>

<html lang="en">

<head>

<meta charset="UTF-8">

<meta name="viewport"
      content="width=device-width, initial-scale=1">

<title>Edit Student | EEC Internship Portal</title>

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
   EDIT CARD
   ============================== */

.portal-card {

    background: white;

    border: none;

    border-radius: 18px;

    padding: 30px;

    box-shadow: 0 3px 15px rgba(0,0,0,.08);
}


.section-title {

    font-size: 21px;

    font-weight: 700;

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


.form-control[readonly] {

    background: #f2f2f2;

    cursor: not-allowed;
}


/* ==============================
   BUTTONS
   ============================== */

.update-btn {

    background: #6b1d1d;

    border: none;

    color: white;

    height: 48px;

    padding: 0 24px;

    border-radius: 12px;

    font-weight: 600;
}


.update-btn:hover {

    background: #5f1515;

    color: white;
}


.back-btn {

    background: white;

    color: #6b1d1d;

    border: 1px solid #6b1d1d;

    height: 44px;

    padding: 0 18px;

    border-radius: 10px;

    font-weight: 600;

    text-decoration: none;

    display: inline-flex;

    align-items: center;
}


.back-btn:hover {

    background: #6b1d1d;

    color: white;
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

            Edit Student

        </h2>


        <div class="admin-badge">

            Administrator

        </div>

    </div>


    <!-- EDIT STUDENT CARD -->

    <div class="portal-card mt-4">


        <div class="d-flex justify-content-between
                    align-items-center mb-4">

            <div class="section-title">

                <i class="bi bi-pencil-square me-2"></i>

                Edit Student Details

            </div>


            <a href="manage_students.jsp"
               class="back-btn">

                <i class="bi bi-arrow-left me-2"></i>

                Back to Students

            </a>

        </div>


        <hr>


        <form action="UpdateStudentServlet"
              method="post">

            <input type="hidden" name="csrfToken" value="<%= csrfToken %>">


            <div class="row mt-4">


                <!-- STUDENT ID -->

                <div class="col-md-6 mb-4">

                    <label class="form-label">

                        Student ID

                    </label>

                    <input
                        type="text"
                        name="student_id"
                        class="form-control"
                        value="<%= escapeHtml(studentId) %>"
                        readonly>

                </div>


                <!-- NAME -->

                <div class="col-md-6 mb-4">

                    <label class="form-label">

                        Student Name

                    </label>

                    <input
                        type="text"
                        name="name"
                        class="form-control"
                        value="<%= escapeHtml(name) %>"
                        required>

                </div>


                <!-- DEPARTMENT -->

                <div class="col-md-6 mb-4">

                    <label class="form-label">

                        Department

                    </label>

                    <input
                        type="text"
                        name="department"
                        class="form-control"
                        value="<%= escapeHtml(department) %>"
                        required>

                </div>


                <!-- EMAIL -->

                <div class="col-md-6 mb-4">

                    <label class="form-label">

                        Email

                    </label>

                    <input
                        type="email"
                        name="email"
                        class="form-control"
                        value="<%= escapeHtml(email) %>"
                        required>

                </div>


                <!-- PASSWORD -->

                <div class="col-md-6 mb-4">

                    <label class="form-label">

                        Password

                    </label>

                    <input
                        type="password"
                        name="password"
                        class="form-control"
                        autocomplete="new-password"
                        placeholder="Leave blank to keep the current password.">

                </div>

            </div>


            <div class="mt-2">

                <button
                    type="submit"
                    class="btn update-btn">

                    <i class="bi bi-check-circle-fill me-2"></i>

                    Update Student

                </button>

            </div>


        </form>

    </div>


</div>


<script
src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js">
</script>


</body>

</html>
