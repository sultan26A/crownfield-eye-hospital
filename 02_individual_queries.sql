-- ---------------------------------------------------------------------
-- 02_individual_queries.sql — my Queries 1 to 4.
-- Run after 01_schema.sql. Each one says what question it answers.
-- ---------------------------------------------------------------------
USE CrownfieldEyeHospitalDB;

-- Q1: AGGREGATE with GROUP BY + HAVING
-- Question: Which clinicians have handled more than two appointments?
SELECT c.ClinicianID,
       CONCAT(c.FirstName, ' ', c.LastName) AS ClinicianName,
       COUNT(a.AppointmentID)               AS TotalAppointments
FROM Clinician c
JOIN Appointment a ON c.ClinicianID = a.ClinicianID
GROUP BY c.ClinicianID, CONCAT(c.FirstName, ' ', c.LastName)
HAVING COUNT(a.AppointmentID) > 2;

-- Q2: INNER JOIN across five tables
--     (Patient, Appointment, Clinician, Specialty, Clinic)
-- Question: show the full appointment picture in one list, the way the old
--           spreadsheet did, but without the duplication.
SELECT p.FirstName AS PatientFirstName, p.LastName AS PatientLastName,
       a.AppointmentDate, a.Status,
       c.FirstName AS ClinicianFirstName, c.LastName AS ClinicianLastName,
       s.SpecialtyName,
       cl.ClinicName, cl.Location
FROM Patient p
INNER JOIN Appointment a ON p.PatientID = a.PatientID
INNER JOIN Clinician c   ON a.ClinicianID = c.ClinicianID
INNER JOIN Specialty s   ON c.SpecialtyID = s.SpecialtyID
INNER JOIN Clinic cl     ON a.ClinicID = cl.ClinicID
ORDER BY a.AppointmentDate;

-- Q3: LEFT JOIN revealing missing / optional data
-- Question: Which patients are registered but have no appointment booked?
SELECT p.PatientID, p.FirstName, p.LastName, p.NHSNumber
FROM Patient p
LEFT JOIN Appointment a ON p.PatientID = a.PatientID
WHERE a.AppointmentID IS NULL;

-- Q4: NESTED SUBQUERY (derived table + aggregate comparison)
-- Question: Which clinicians have an appointment count ABOVE the average per clinician?
SELECT c.ClinicianID, c.FirstName, c.LastName,
       COUNT(a.AppointmentID) AS AppointmentCount
FROM Clinician c
JOIN Appointment a ON c.ClinicianID = a.ClinicianID
GROUP BY c.ClinicianID, c.FirstName, c.LastName
HAVING COUNT(a.AppointmentID) > (
    SELECT AVG(AppCount)
    FROM (SELECT COUNT(*) AS AppCount
          FROM Appointment
          GROUP BY ClinicianID) AS ClinicianAppCounts
);
