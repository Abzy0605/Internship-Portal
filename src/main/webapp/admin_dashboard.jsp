<%@ page import="java.sql.*" %>
<%@ page import="com.internship.DBConnector" %>

<%
String role = (String) session.getAttribute("role");
if (role == null || !role.equals("admin")) {
    response.sendRedirect("login.jsp");
    return;
}

int studentCount = 0;
int staffCount = 0;
int internshipCount = 0;
int adminCount = 0;

try {

    Connection con = DBConnector.getConnection();

    Statement st = con.createStatement();

    ResultSet rs1 = st.executeQuery(
        "SELECT COUNT(*) FROM student"
    );

    if(rs1.next()) {
        studentCount = rs1.getInt(1);
    }


    ResultSet rs2 = st.executeQuery(
        "SELECT COUNT(*) FROM staff"
    );

    if(rs2.next()) {
        staffCount = rs2.getInt(1);
    }


    ResultSet rs3 = st.executeQuery(
        "SELECT COUNT(*) FROM internship"
    );

    if(rs3.next()) {
        internshipCount = rs3.getInt(1);
    }


    ResultSet rs4 = st.executeQuery(
        "SELECT COUNT(*) FROM admin"
    );

    if(rs4.next()) {
        adminCount = rs4.getInt(1);
    }


    rs1.close();
    rs2.close();
    rs3.close();
    rs4.close();

    st.close();
    con.close();

}
catch(Exception e) {

    application.log("Unable to load admin dashboard statistics.", e);

}


%>


<!DOCTYPE html>

<html lang="en">

<head>

<meta charset="UTF-8">

<meta name="viewport"
      content="width=device-width, initial-scale=1">

<title>Admin Dashboard</title>


<link
    href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
    rel="stylesheet">


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
   STATISTICS CARDS
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

}


.stats-label {

    color: #777;

}


/* ==============================
   QUICK ACCESS CARDS
   ============================== */

.quick-card {

    background: white;

    border: none;

    border-radius: 18px;

    padding: 30px;

    text-align: center;

    box-shadow: 0 3px 15px rgba(0,0,0,.08);

    transition: .3s;

    height: 100%;

}


.quick-card:hover {

    transform: translateY(-5px);

}


.quick-card i {

    font-size: 45px;

    color: #6b1d1d;

}


.quick-title {

    margin-top: 15px;

    font-size: 20px;

    font-weight: 600;

}


.quick-desc {

    color: #777;

    margin-top: 10px;

}


.quick-link {

    text-decoration: none;

    color: inherit;

    display: block;

    height: 100%;

}


/* ==============================
   SYSTEM OVERVIEW
   ============================== */

.activity-card {

    background: white;

    border: none;

    border-radius: 18px;

    padding: 25px;

    box-shadow: 0 3px 15px rgba(0,0,0,.08);

}


/* ==============================
   RESPONSIVE
   ============================== */

@media(max-width: 991px) {

    .sidebar {

        width: 220px;

    }

    .main-content {

        margin-left: 220px;

    }

}


@media(max-width: 768px) {

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


        <!-- DASHBOARD -->

        <a href="admin_dashboard.jsp">

            <i class="bi bi-speedometer2"></i>

            Dashboard

        </a>


        <!-- STUDENTS -->

        <a href="manage_students.jsp">

            <i class="bi bi-people-fill"></i>

            Students

        </a>

        <a href="manage_student_assignments.jsp">

            <i class="bi bi-person-check-fill"></i>

            Student Assignments

        </a>


        <!-- STAFF -->

        <a href="manage_staff.jsp">

            <i class="bi bi-person-workspace"></i>

            Staff

        </a>


        <!-- INTERNSHIP RECORDS -->

        <a href="admin_internship_records.jsp">

            <i class="bi bi-folder-check"></i>

            Internship Records

        </a>


        <!-- REPORTS -->

        <a href="admin_reports.jsp">

            <i class="bi bi-bar-chart-line-fill"></i>

            Reports

        </a>


        <!-- LOGOUT -->

        <form action="LogoutServlet" method="post"><input type="hidden" name="csrfToken" value="<%= com.internship.CsrfToken.getOrCreate(session) %>"><button type="submit" class="btn btn-link text-white p-0"><i class="bi bi-box-arrow-right"></i> Logout</button></form>


    </div>

</div>



<!-- =========================================
     MAIN CONTENT
     ========================================= -->

<div class="main-content">


    <!-- TOPBAR -->

    <div class="topbar">

        <h2 class="page-title">

            Administrator Dashboard

        </h2>


        <div class="admin-badge">

            Administrator

        </div>

    </div>



    <!-- =====================================
         STATISTICS
         ===================================== -->

    <div class="row mt-4 g-4">


        <!-- STUDENTS -->

        <div class="col-md-3">

            <div class="stats-card">

                <i class="bi bi-people-fill stats-icon"></i>

                <div class="stats-number">

                    <%=studentCount%>

                </div>

                <div class="stats-label">

                    Students

                </div>

            </div>

        </div>



        <!-- STAFF -->

        <div class="col-md-3">

            <div class="stats-card">

                <i class="bi bi-person-workspace stats-icon"></i>

                <div class="stats-number">

                    <%=staffCount%>

                </div>

                <div class="stats-label">

                    Staff Members

                </div>

            </div>

        </div>



        <!-- INTERNSHIPS -->

        <div class="col-md-3">

            <div class="stats-card">

                <i class="bi bi-folder-check stats-icon"></i>

                <div class="stats-number">

                    <%=internshipCount%>

                </div>

                <div class="stats-label">

                    Internships

                </div>

            </div>

        </div>



        <!-- ADMINISTRATORS -->

        <div class="col-md-3">

            <div class="stats-card">

                <i class="bi bi-shield-lock stats-icon"></i>

                <div class="stats-number">

                    <%=adminCount%>

                </div>

                <div class="stats-label">

                    Administrators

                </div>

            </div>

        </div>


    </div>



    <!-- =====================================
         QUICK ACCESS
         ===================================== -->

    <div class="row mt-4 g-4">


        <!-- MANAGE STUDENTS -->

        <div class="col-md-6">

            <a
                href="manage_students.jsp"
                class="quick-link">


                <div class="quick-card">


                    <i class="bi bi-people-fill"></i>


                    <div class="quick-title">

                        Manage Students

                    </div>


                    <div class="quick-desc">

                        Add, update, view and delete student accounts.

                    </div>


                </div>


            </a>

        </div>



        <!-- MANAGE STAFF -->

        <div class="col-md-6">

            <a
                href="manage_staff.jsp"
                class="quick-link">


                <div class="quick-card">


                    <i class="bi bi-person-workspace"></i>


                    <div class="quick-title">

                        Manage Staff

                    </div>


                    <div class="quick-desc">

                        Create and manage faculty mentor accounts.

                    </div>


                </div>


            </a>

        </div>



        <!-- INTERNSHIP RECORDS -->

        <div class="col-md-6">

            <a
                href="admin_internship_records.jsp"
                class="quick-link">

                <div class="quick-card">


                    <i class="bi bi-folder-check"></i>


                    <div class="quick-title">

                        Internship Records

                    </div>


                    <div class="quick-desc">

                        Track student internship submissions and approvals.

                    </div>


                </div>

            </a>

        </div>



        <!-- REPORTS -->

        <div class="col-md-6">

            <div class="quick-card">


                <i class="bi bi-bar-chart-line-fill"></i>


                <div class="quick-title">

                    Reports

                </div>


                <div class="quick-desc">

                    Generate internship reports and analytics.

                </div>


            </div>

        </div>


    </div>



    <!-- =====================================
         SYSTEM OVERVIEW
         ===================================== -->

    <div class="activity-card mt-4">


        <h4>

            System Overview

        </h4>


        <hr>


        <p class="text-muted">

            Welcome to the Internship Management and Review System.

            Administrators can manage students, staff accounts,

            internship records, progress tracking and reports

            from this centralized dashboard.

        </p>


    </div>


</div>



<script
src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js">
</script>


</body>

</html>
