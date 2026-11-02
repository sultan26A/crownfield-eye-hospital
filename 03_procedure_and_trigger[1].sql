-- ---------------------------------------------------------------------
-- 03_procedure_and_trigger.sql — my Queries 5 and 6.
-- Run after 01_schema.sql and 02_individual_queries.sql.
--
-- The trigger is created here, not in file 01, so that the Appendix 1
-- appointments (which are in the past) could be loaded first.
-- ---------------------------------------------------------------------
USE CrownfieldEyeHospitalDB;

-- Q5: STORED PROCEDURE with an input parameter
-- Question: Retrieve all appointments for a given patient ID.
DROP PROCEDURE IF EXISTS GetPatientAppointments;

DELIMITER //
CREATE PROCEDURE GetPatientAppointments(IN p_patient_id INT)
BEGIN
    SELECT AppointmentID, AppointmentDate, Status, Notes
    FROM Appointment
    WHERE PatientID = p_patient_id
    ORDER BY AppointmentDate DESC;
END //
DELIMITER ;

-- Execute:
CALL GetPatientAppointments(1);   -- Amina Yusuf (OP001) — two appointments
CALL GetPatientAppointments(9);   -- Priya Sharma — one appointment

-- Q6: TRIGGER enforcing a meaningful business rule
-- Question: Prevent appointment dates being inserted in the past.
DROP TRIGGER IF EXISTS ValidateFutureAppointmentDate;

DELIMITER //
CREATE TRIGGER ValidateFutureAppointmentDate
BEFORE INSERT ON Appointment
FOR EACH ROW
BEGIN
    IF NEW.AppointmentDate < NOW() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Appointment date cannot be in the past.';
    END IF;
END //
DELIMITER ;

-- Test 1 (should FAIL with the signal message above):
-- INSERT INTO Appointment (PatientID, ClinicianID, ClinicID, AppointmentDate)
-- VALUES (1, 1, 1, '2020-01-01 09:00:00');

-- Test 2 (should SUCCEED — future date):
INSERT INTO Appointment (PatientID, ClinicianID, ClinicID, AppointmentDate, Status)
VALUES (9, 1, 1, DATE_ADD(NOW(), INTERVAL 7 DAY), 'Scheduled');
