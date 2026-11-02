-- ---------------------------------------------------------------------
-- 04_security.sql — roles and privileges, password hashing, secure coding
-- and transactions.
--
-- Run this as an admin user. The passwords in here are obvious demo ones,
-- so they would need changing before this went near a real system.
-- ---------------------------------------------------------------------
USE CrownfieldEyeHospitalDB;

-- ---------------- D1: Roles & privileges (four user types) ----------------
DROP USER IF EXISTS admin_user@localhost;
DROP USER IF EXISTS doctor_user@localhost;
DROP USER IF EXISTS reception_user@localhost;
DROP USER IF EXISTS patient_user@localhost;

CREATE USER admin_user@localhost     IDENTIFIED BY 'ChangeMe_Admin2026!';
CREATE USER doctor_user@localhost    IDENTIFIED BY 'ChangeMe_Doctor2026!';
CREATE USER reception_user@localhost IDENTIFIED BY 'ChangeMe_Reception2026!';
CREATE USER patient_user@localhost   IDENTIFIED BY 'ChangeMe_Patient2026!';

-- Administrator: full control
GRANT ALL PRIVILEGES ON CrownfieldEyeHospitalDB.* TO admin_user@localhost;

-- Doctor: view patients and manage appointments only (least privilege).
-- No access to PatientLogin (credentials), no DELETE, no schema changes.
GRANT SELECT                 ON CrownfieldEyeHospitalDB.Patient     TO doctor_user@localhost;
GRANT SELECT, INSERT, UPDATE ON CrownfieldEyeHospitalDB.Appointment TO doctor_user@localhost;

-- Receptionist: booking focus — read/insert/update patient & appointment only
GRANT SELECT, INSERT, UPDATE ON CrownfieldEyeHospitalDB.Patient     TO reception_user@localhost;
GRANT SELECT, INSERT, UPDATE ON CrownfieldEyeHospitalDB.Appointment TO reception_user@localhost;

-- Patient: read-only, restricted to OWN records via a view
CREATE OR REPLACE VIEW PatientOwnRecords AS
SELECT PatientID, FirstName, LastName, DateOfBirth, Postcode
FROM Patient
WHERE PatientID = (SELECT PatientID FROM PatientLogin
                   WHERE Username = SUBSTRING_INDEX(USER(),'@',1));
GRANT SELECT ON CrownfieldEyeHospitalDB.PatientOwnRecords TO patient_user@localhost;

-- Demonstration patient account: the view matches the connected account name to
-- PatientLogin.Username, so this account sees only Amina Yusuf's own row.
DROP USER IF EXISTS amina_yusuf@localhost;
CREATE USER amina_yusuf@localhost IDENTIFIED BY 'ChangeMe_Amina2026!';
GRANT SELECT ON CrownfieldEyeHospitalDB.PatientOwnRecords TO amina_yusuf@localhost;

FLUSH PRIVILEGES;

-- ---------------- D2: Data protection — password hashing (SHA-256) ----------------
-- The plaintext password is never stored, only the hash, and a hash can't be
-- turned back into the original password.
INSERT INTO PatientLogin (PatientID, Username, PasswordHash)
VALUES (6, 'david_chen', SHA2('David#2026', 256))
ON DUPLICATE KEY UPDATE PasswordHash = SHA2('David#2026', 256);

-- Evidence query (all stored values are 64-character SHA-256 hex digests):
-- SELECT Username, PasswordHash, LENGTH(PasswordHash) AS HashLength FROM PatientLogin;

-- Verification at login compares hashes (the plaintext is never recovered):
-- SELECT 1 FROM PatientLogin WHERE Username='david_chen'
--   AND PasswordHash = SHA2(user_supplied_password, 256);

-- SQL injection. The problem is building a query by gluing user input into a
-- string: type ' OR '1'='1 into the box and the WHERE clause stops filtering
-- anything. Using a parameter (or the stored procedure above) means the input
-- is treated as a value, never as part of the SQL.
-- BAD:  "SELECT * FROM Patient WHERE LastName = '" + userInput + "'"
-- GOOD: prepared statement with a ? placeholder, or CALL GetPatientAppointments(?)

-- ---------------- Transaction management (LO3) ----------------
-- Appointment + follow-up must succeed or fail together (atomicity).
-- NOTE: this adds one appointment. Run the queries in 02_individual_queries.sql
-- BEFORE this block if you want the row counts shown in my screenshots.
--
-- The date below is the one I used when I took the screenshot in my report.
-- The past-date trigger from file 03 rejects anything earlier than NOW(), so if
-- you are running this after 15 November 2026, change both dates to future ones
-- (or use DATE_ADD(NOW(), INTERVAL 14 DAY) and INTERVAL 44 DAY) before running.
USE CrownfieldEyeHospitalDB;

START TRANSACTION;

-- Book appointment for Patient 5
INSERT INTO Appointment (PatientID, ClinicianID, ClinicID, AppointmentDate, Status, Notes)
VALUES (5, 2, 2, '2026-11-15 10:00:00', 'Scheduled', 'Routine follow-up check');

-- Get the auto-generated AppointmentID
SET @new_appt_id = LAST_INSERT_ID();

-- Create linked follow-up plan
INSERT INTO FollowUpPlan (AppointmentID, DueDate, Priority, Status)
VALUES (@new_appt_id, '2026-12-15', 'Medium', 'Pending');

-- Only if BOTH succeed -> make permanent
COMMIT;

-- Rollback version (for testing): replace COMMIT above with ROLLBACK;
-- ROLLBACK undoes both inserts, so no partial or orphaned data is left behind.

-- Verify both records were created together
SELECT
  a.AppointmentID,
  a.PatientID,
  a.AppointmentDate,
  f.DueDate,
  f.Priority,
  f.Status AS FollowUpStatus
FROM Appointment a
JOIN FollowUpPlan f ON a.AppointmentID = f.AppointmentID
WHERE a.PatientID = 5
  AND a.AppointmentDate >= '2026-11-01';
