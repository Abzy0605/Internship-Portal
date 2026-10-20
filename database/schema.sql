-- Fresh-install schema for the Internship Portal.
-- Account identifier widths, most VARCHAR widths, nullability, and
-- referential actions are compatibility choices; see README.md for details.

CREATE TABLE staff (
    staff_id   VARCHAR(64)  NOT NULL,
    name       VARCHAR(150) NOT NULL,
    department VARCHAR(150) NOT NULL,
    email      VARCHAR(254) NOT NULL,
    password   VARCHAR(255) NOT NULL,
    PRIMARY KEY (staff_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE student (
    student_id VARCHAR(64)  NOT NULL,
    name       VARCHAR(150) NOT NULL,
    department VARCHAR(150) NOT NULL,
    email      VARCHAR(254) NOT NULL,
    password   VARCHAR(255) NOT NULL,
    mentor_id  VARCHAR(64)  NULL,
    PRIMARY KEY (student_id),
    KEY idx_student_mentor_id (mentor_id),
    CONSTRAINT fk_student_mentor
        FOREIGN KEY (mentor_id) REFERENCES staff (staff_id)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE admin (
    admin_id VARCHAR(64)  NOT NULL,
    username VARCHAR(100) NOT NULL,
    password VARCHAR(255) NOT NULL,
    PRIMARY KEY (admin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE internship (
    internship_id  INT NOT NULL AUTO_INCREMENT,
    student_id     VARCHAR(64)  NOT NULL,
    company_name   VARCHAR(150) NOT NULL,
    internship_type VARCHAR(20) NOT NULL,
    start_date     DATE NOT NULL,
    end_date       DATE NOT NULL,
    offer_letter   VARCHAR(512) NOT NULL,
    certificate    VARCHAR(512) NOT NULL,
    ppt_review     VARCHAR(512) NOT NULL,
    report_file    VARCHAR(512) NOT NULL,
    bank_statement VARCHAR(512) NULL,
    stipend_proof  VARCHAR(512) NULL,
    status         VARCHAR(20) NOT NULL DEFAULT 'Pending',
    remarks        TEXT NULL,
    PRIMARY KEY (internship_id),
    KEY idx_internship_student (student_id, internship_id),
    KEY idx_internship_status (status),
    KEY idx_internship_type (internship_type),
    KEY idx_internship_start_date (start_date),
    KEY idx_internship_end_date (end_date),
    CONSTRAINT fk_internship_student
        FOREIGN KEY (student_id) REFERENCES student (student_id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
