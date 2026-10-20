<!DOCTYPE html>
<html lang="en">

<head>

<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">

<title>EEC Internship Management System</title>

<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">

<link rel="stylesheet"
href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

<style>

*{
    margin:0;
    padding:0;
    box-sizing:border-box;
}

body{
    min-height:100vh;
    background:#f5f6f8;
    font-family:'Segoe UI',sans-serif;
}

.left-panel{
    background:linear-gradient(135deg,#4a0f0f,#7a1d1d);
    color:white;
    min-height:100vh;
    display:flex;
    align-items:center;
    justify-content:center;
    padding:50px;
}

.brand-section{
    max-width:500px;
}

.logo-box{
    width:100px;
    height:100px;
    background:white;
    border-radius:20px;
    display:flex;
    align-items:center;
    justify-content:center;
    padding:10px;
    margin-bottom:25px;
}

.logo-box img{
    width:80px;
    height:80px;
    object-fit:contain;
}

.brand-title{
    font-size:38px;
    font-weight:700;
    margin-bottom:15px;
}

.brand-subtitle{
    font-size:18px;
    line-height:1.8;
    opacity:0.95;
}

.right-panel{
    min-height:100vh;
    display:flex;
    justify-content:center;
    align-items:center;
    padding:40px;
}

.login-card{
    width:100%;
    max-width:500px;
    background:white;
    border:none;
    border-radius:20px;
    padding:40px;
    box-shadow:0 10px 30px rgba(0,0,0,0.1);
}

.portal-badge{
    display:inline-block;
    padding:8px 15px;
    background:#f2f2f2;
    border-radius:30px;
    font-size:14px;
    margin-bottom:15px;
}

.login-title{
    font-size:32px;
    font-weight:700;
    color:#222;
}

.login-subtitle{
    color:#777;
    margin-bottom:30px;
}

.form-label{
    font-weight:600;
}

.form-control,
.form-select{
    height:50px;
    border-radius:12px;
}

.form-control:focus,
.form-select:focus{
    border-color:#7a1d1d;
    box-shadow:none;
}

.login-btn{
    background:#7a1d1d;
    border:none;
    height:50px;
    border-radius:12px;
    font-size:16px;
    font-weight:600;
}

.login-btn:hover{
    background:#5f1515;
}

.feature-box{
    margin-top:25px;
    display:flex;
    flex-wrap:wrap;
    gap:10px;
}

.feature-tag{
    padding:8px 14px;
    border:1px solid #e5e5e5;
    border-radius:25px;
    font-size:13px;
    background:#fafafa;
}

.footer-text{
    margin-top:25px;
    color:#888;
    font-size:13px;
    text-align:center;
}

@media(max-width:991px){

    .left-panel{
        display:none;
    }

    .login-card{
        margin-top:20px;
    }

}

</style>

</head>

<body>

<div class="container-fluid">

<div class="row">

<!-- LEFT SIDE -->

<div class="col-lg-6 left-panel">

    <div class="brand-section">

        <div class="logo-box">

            <img src="images/EEC_logo.png"
                 alt="EEC Logo">

        </div>

        <h1 class="brand-title">

            Easwari Engineering College

        </h1>

        <p class="brand-subtitle">

            Internship Management and Review System

            <br><br>

            A centralized platform for managing
            student internships, faculty reviews,
            internship tracking, progress monitoring,
            PPT evaluations and administrative reports.

        </p>

    </div>

</div>

<!-- RIGHT SIDE -->

<div class="col-lg-6 right-panel">

    <div class="login-card">

        <span class="portal-badge">

            Internship Portal

        </span>

        <h2 class="login-title">

            Welcome Back

        </h2>

        <p class="login-subtitle">

            Sign in to continue

        </p>

        <form action="LoginServlet" method="post">

            <div class="mb-3">

                <label class="form-label">

                    Username

                </label>

                <input
                type="text"
                name="username"
                class="form-control"
                placeholder="Enter Username"
                required>

            </div>

            <div class="mb-3">

                <label class="form-label">

                    Password

                </label>

                <input
                type="password"
                name="password"
                class="form-control"
                autocomplete="current-password"
                placeholder="Enter Password"
                required>

            </div>

            <div class="mb-4">

                <label class="form-label">

                    Select Role

                </label>

                <select
                name="role"
                class="form-select"
                required>

                    <option value="">
                        Select Role
                    </option>

                    <option value="student">
                        Student
                    </option>

                    <option value="staff">
                        Staff
                    </option>

                    <option value="admin">
                        Administrator
                    </option>

                </select>

            </div>

            <div class="mb-3 text-end">

                <a href="#"
                   class="text-decoration-none">

                    Forgot Password?

                </a>

            </div>

            <button
            type="submit"
            class="btn btn-danger login-btn w-100">

                Login

            </button>

        </form>

        <div class="feature-box">

            <span class="feature-tag">
                Internship Tracking
            </span>

            <span class="feature-tag">
                Faculty Review
            </span>

            <span class="feature-tag">
                PPT Evaluation
            </span>

            <span class="feature-tag">
                Progress Monitoring
            </span>

        </div>

        <div class="footer-text">

            Easwari Engineering College © 2025

        </div>

    </div>

</div>

</div>

</div>

</body>

</html>