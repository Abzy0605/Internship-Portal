-- Phase 8E: allow versioned PBKDF2 password records.
-- Verified before this migration: student.password, staff.password, and
-- admin.password were all VARCHAR(100) NOT NULL.
--
-- This migration does not read, rewrite, or expose existing credential values.
-- Existing plaintext values remain intact for migration-on-successful-login.

ALTER TABLE student MODIFY COLUMN password VARCHAR(255) NOT NULL;
ALTER TABLE staff MODIFY COLUMN password VARCHAR(255) NOT NULL;
ALTER TABLE admin MODIFY COLUMN password VARCHAR(255) NOT NULL;

-- Rollback, only if no PBKDF2 records longer than 100 characters have been
-- written. Do not run blindly, because it can truncate credentials:
-- ALTER TABLE student MODIFY COLUMN password VARCHAR(100) NOT NULL;
-- ALTER TABLE staff MODIFY COLUMN password VARCHAR(100) NOT NULL;
-- ALTER TABLE admin MODIFY COLUMN password VARCHAR(100) NOT NULL;
