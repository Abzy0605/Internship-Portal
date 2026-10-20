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


String staffId = request.getParameter("staff_id");

String name = "";
String department = "";
String email = "";


if (staffId == null || staffId.trim().isEmpty()) {

    response.sendRedirect("manage_staff.jsp?error=1");

    return;

}


try {

    Connection con = DBConnector.getConnection();

    PreparedStatement ps =
        con.prepareStatement(
            "SELECT staff_id, name, department, email FROM staff WHERE staff_id=?"
        );

    ps.setString(1, staffId);

    ResultSet rs = ps.executeQuery();


    if (rs.next()) {

        name = rs.getString("name");

        department = rs.getString("department");

        email = rs.getString("email");


    }

    else {

        rs.close();
        ps.close();
        con.close();

        response.sendRedirect(
            "manage_staff.jsp?error=1"
        );

        return;

    }


    rs.close();
    ps.close();
    con.close();

}

catch (Exception e) {

    e.printStackTrace();

    response.sendRedirect(
        "manage_staff.jsp?error=1"
    );

    return;

}

%>


<!DOCTYPE html>

<html lang="en">

<head>

<meta charset="UTF-8">

<meta name="viewport"
      content="width=device-width, initial-scale=1">

<title>Edit Staff - EEC Internship Portal</title>


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
   FORM CARD
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

    border-color: #6b1d1d;

    box-shadow: none;

}


.readonly-field {

    background: #f5f5f5;

    cursor: not-allowed;

}


/* ==============================
   BUTTONS
   ============================== */

.primary-btn {

    background: #6b1d1d;

    border: none;

    color: white;

    border-radius: 10px;

    padding: 11px 22px;

    font-weight: 600;

}


.primary-btn:hover {

    background: #531616;

    color: white;

}


.back-btn {

    border-radius: 10px;

    padding: 10px 18px;

    font-weight: 600;

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

        <img
            src="images/EEC_logo.png"
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


        <a href="manage_students.jsp">

            <i class="bi bi-people-fill"></i>

            Students

        </a>


        <a
            href="manage_staff.jsp"
            class="active-link">

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

            Edit Staff

        </h2>


        <div class="admin-badge">

            Administrator

        </div>

    </div>



    <!-- =====================================
         FORM
         ===================================== -->

    <div class="portal-card mt-4">


        <div class="section-title mb-4">

            <i class="bi bi-pencil-square me-2"></i>

            Edit Staff Details

        </div>


        <form
            action="UpdateStaffServlet"
            method="post">

            <input type="hidden" name="csrfToken" value="<%= csrfToken %>">


            <div class="row">


                <!-- STAFF ID -->

                <div class="col-md-6 mb-3">

                    <label class="form-label">

                        Staff ID

                    </label>


                    <input
                        type="text"
                        name="staff_id"
                        class="form-control readonly-field"
                        value="<%= escapeHtml(staffId) %>"
                        readonly>

                </div>



                <!-- NAME -->

                <div class="col-md-6 mb-3">

                    <label class="form-label">

                        Staff Name

                    </label>


                    <input
                        type="text"
                        name="name"
                        class="form-control"
                        value="<%= escapeHtml(name) %>"
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
                        value="<%= escapeHtml(department) %>"
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
                        value="<%= escapeHtml(email) %>"
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
                        placeholder="Leave blank to keep the current password.">

                </div>


            </div>



            <!-- BUTTONS -->

            <div class="mt-3">


                <button
                    type="submit"
                    class="btn primary-btn">

                    <i class="bi bi-check-circle-fill me-1"></i>

                    Update Staff

                </button>


                <a
                    href="manage_staff.jsp"
                    class="btn btn-outline-secondary back-btn ms-2">

                    <i class="bi bi-arrow-left me-1"></i>

                    Cancel

                </a>


            </div>


        </form>


    </div>


</div>



<script
src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js">
</script>


</body>

</html>
