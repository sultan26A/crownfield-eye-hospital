-- ---------------------------------------------------------------------
-- Crownfield Eye Hospital (fictional teaching scenario)
-- 01_schema.sql — creates the 12 tables and loads the data.
--
-- Run this one first. It drops and recreates CrownfieldEyeHospitalDB, so if you
-- already have a database with that name, it will be deleted.
--
-- The past-date trigger is not in here, it's in 03_procedure_and_trigger.sql.
-- The Appendix 1 appointments have already happened, so if the trigger existed
-- at this point it would reject all of them.
--
-- Needs MySQL 8.0.16 or newer, or the CHECK constraints are parsed and ignored.
-- ---------------------------------------------------------------------

DROP DATABASE IF EXISTS CrownfieldEyeHospitalDB;
CREATE DATABASE CrownfieldEyeHospitalDB CHARACTER SET utf8mb4;
USE CrownfieldEyeHospitalDB;

-- ---------------- Reference tables ----------------
CREATE TABLE Specialty (
    SpecialtyID   INT PRIMARY KEY AUTO_INCREMENT,
    SpecialtyName VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Clinic (
    ClinicID   INT PRIMARY KEY AUTO_INCREMENT,
    ClinicName VARCHAR(100) NOT NULL,
    Location   VARCHAR(100) NOT NULL
);

CREATE TABLE Patient (
    PatientID   INT PRIMARY KEY AUTO_INCREMENT,
    NHSNumber   VARCHAR(20)  NOT NULL UNIQUE,
    FirstName   VARCHAR(50)  NOT NULL,
    LastName    VARCHAR(50)  NOT NULL,
    DateOfBirth DATE         NOT NULL,
    Gender      VARCHAR(10),
    Phone       VARCHAR(20),
    Email       VARCHAR(100),
    Address     VARCHAR(255),
    Postcode    VARCHAR(10)
);

CREATE TABLE Clinician (
    ClinicianID INT PRIMARY KEY AUTO_INCREMENT,
    FirstName   VARCHAR(50) NOT NULL,
    LastName    VARCHAR(50) NOT NULL,
    SpecialtyID INT NOT NULL,
    Email       VARCHAR(100),
    Phone       VARCHAR(20),
    FOREIGN KEY (SpecialtyID) REFERENCES Specialty(SpecialtyID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE Medicine (
    MedicineID   INT PRIMARY KEY AUTO_INCREMENT,
    MedicineName VARCHAR(100) NOT NULL UNIQUE
);

-- ---------------- Central fact table ----------------
CREATE TABLE Appointment (
    AppointmentID   INT PRIMARY KEY AUTO_INCREMENT,
    PatientID       INT NOT NULL,
    ClinicianID     INT NOT NULL,
    ClinicID        INT NOT NULL,
    AppointmentDate DATETIME NOT NULL,
    Status          ENUM('Scheduled','Completed','Cancelled') DEFAULT 'Scheduled',
    Notes           TEXT,
    FOREIGN KEY (PatientID)   REFERENCES Patient(PatientID)     ON DELETE CASCADE,
    FOREIGN KEY (ClinicianID) REFERENCES Clinician(ClinicianID) ON DELETE RESTRICT,
    FOREIGN KEY (ClinicID)    REFERENCES Clinic(ClinicID)       ON DELETE RESTRICT
);

-- ---------------- Dependent tables ----------------
CREATE TABLE Diagnosis (
    DiagnosisID   INT PRIMARY KEY AUTO_INCREMENT,
    AppointmentID INT NOT NULL,
    DiagnosisName VARCHAR(100) NOT NULL,
    Notes         TEXT,
    FOREIGN KEY (AppointmentID) REFERENCES Appointment(AppointmentID) ON DELETE CASCADE
);

CREATE TABLE Prescription (
    PrescriptionID   INT PRIMARY KEY AUTO_INCREMENT,
    AppointmentID    INT NOT NULL,
    PrescriptionDate DATE NOT NULL,
    FOREIGN KEY (AppointmentID) REFERENCES Appointment(AppointmentID) ON DELETE CASCADE
);

CREATE TABLE PrescriptionItem (
    PrescriptionItemID INT PRIMARY KEY AUTO_INCREMENT,
    PrescriptionID     INT NOT NULL,
    MedicineID         INT NOT NULL,
    Dose               VARCHAR(50) NOT NULL,
    Route              VARCHAR(50),
    Frequency          VARCHAR(50),
    DurationDays       INT,
    FOREIGN KEY (PrescriptionID) REFERENCES Prescription(PrescriptionID) ON DELETE CASCADE,
    FOREIGN KEY (MedicineID)     REFERENCES Medicine(MedicineID)         ON DELETE RESTRICT
);

CREATE TABLE Treatment (
    TreatmentID   INT PRIMARY KEY AUTO_INCREMENT,
    AppointmentID INT NOT NULL,
    TreatmentName VARCHAR(100) NOT NULL,
    Notes         TEXT,
    FOREIGN KEY (AppointmentID) REFERENCES Appointment(AppointmentID) ON DELETE CASCADE
);

CREATE TABLE FollowUpPlan (
    FollowUpID    INT PRIMARY KEY AUTO_INCREMENT,
    AppointmentID INT NOT NULL UNIQUE,   -- at most one follow-up plan per appointment (business rule)
    DueDate       DATE NOT NULL,
    Priority      ENUM('Low','Medium','High') DEFAULT 'Medium',
    Status        ENUM('Pending','Completed','Cancelled') DEFAULT 'Pending',
    FOREIGN KEY (AppointmentID) REFERENCES Appointment(AppointmentID) ON DELETE CASCADE
);

CREATE TABLE PatientLogin (
    LoginID      INT PRIMARY KEY AUTO_INCREMENT,
    PatientID    INT NOT NULL UNIQUE,
    Username     VARCHAR(50)  NOT NULL UNIQUE,
    PasswordHash VARCHAR(255) NOT NULL,
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- The data. Patients 1-4 and appointments 1-5 are the Appendix 1 rows;
-- everything after that is synthetic data I added for testing.
-- ---------------------------------------------------------------------

INSERT INTO Specialty (SpecialtyName) VALUES
('Glaucoma'), ('Retina'), ('Cornea'), ('Cataract Surgery'), ('Paediatric Ophthalmology');

INSERT INTO Clinic (ClinicName, Location) VALUES
('City Road Eye Centre',      'London EC1'),
('Bedford General Eye Unit',  'Bedford MK42'),
('Croydon University Eye Clinic','Croydon CR7'),
("St Paul's Ophthalmology",   'Liverpool L6');

INSERT INTO Medicine (MedicineName) VALUES
('Latanoprost 0.005% eye drops'),
('Timolol 0.5% eye drops'),
('Aflibercept intravitreal injection'),
('Sodium chloride 5% eye drops'),
('Prednisolone acetate 1% eye drops'),
('Brimonidine 0.2% eye drops'),
('Dorzolamide 2% eye drops'),
('Cyclopentolate 1% eye drops');

INSERT INTO Patient (NHSNumber, FirstName, LastName, DateOfBirth, Gender, Phone, Email, Address, Postcode) VALUES
('NHS100101','Amina','Yusuf',   '1968-04-12','Female','07700900101','amina.y@example.com','12 Jesmond Road',   'NE1 4AB'),  -- OP001
('NHS100102','Daniel','Reed',   '1955-09-30','Male',  '07700900102','daniel.r@example.com','45 Green Lanes',    'N16 7QP'),  -- OP002
('NHS100103','Sofia','Bennett', '1990-01-22','Female','07700900103','sofia.b@example.com', '8 Orwell Road',     'E8 2LD'),   -- OP003
('NHS100104','Michael','Okoro', '1972-06-15','Male',  '07700900104','michael.o@example.com','23 Bromley Road',  'SE6 3RT'),  -- OP004
('NHS100105','Margaret','Turner','1948-11-03','Female','07700900105','margaret.t@example.com','7 Acacia Avenue','L1 3XY'),
('NHS100106','David','Chen',    '1985-03-19','Male',  '07700900106','david.c@example.com',  '56 Station Road',   'CR0 2AB'),
('NHS100107','Aisha','Rahman',  '1979-07-08','Female','07700900107','aisha.r@example.com',  '3 Rose Cottages',   'MK40 1JH'),
('NHS100108','Robert','Williams','1952-12-01','Male', '07700900108','robert.w@example.com', '91 High Street',    'L6 4BN'),
('NHS100109','Priya','Sharma',  '1995-05-27','Female','07700900109','priya.s@example.com',  '14 Park View',      'SE1 7PQ'),
('NHS100110','Thomas','Gallagher','1963-08-14','Male','07700900110','thomas.g@example.com','22 Mill Lane',      'BD1 5RT'),
('NHS100111','Fatima','Al-Sayed','1988-02-11','Female','07700900111','fatima.a@example.com','67 Kingsway',       'N1 9XZ'),
('NHS100112','John','Miller',   '1945-10-30','Male',  '07700900112','john.m@example.com',   '5 Elm Close',       'CR7 6FG'),
('NHS100113','Lisa','Carter',   '1992-03-17','Female','07700900113','lisa.c@example.com',  '9 Clapham Road',    'SW4 0HJ');   -- no appointment: demonstrates LEFT JOIN (Query 3)

INSERT INTO Clinician (FirstName, LastName, SpecialtyID, Email, Phone) VALUES
('Maya',  'Shah',    1, 'maya.shah@ceh.nhs.uk',   '02079460001'),
('Leo',   'Grant',   2, 'leo.grant@ceh.nhs.uk',   '02079460002'),
('Priya', 'Nair',    3, 'priya.nair@ceh.nhs.uk',  '02079460003'),
('Ahmed', 'Rahman',  4, 'ahmed.rahman@ceh.nhs.uk','02079460004'),
('Elena', 'Volkov',  2, 'elena.volkov@ceh.nhs.uk','02079460005'),
('James', 'Okafor',  1, 'james.okafor@ceh.nhs.uk','02079460006');

INSERT INTO Appointment (PatientID, ClinicianID, ClinicID, AppointmentDate, Status, Notes) VALUES
(1,1,1,'2026-10-05 09:00:00','Scheduled','Review IOP'),                       -- OP001 / Appendix 1 (marked Completed by the UPDATE test below)
(2,2,1,'2026-10-05 09:30:00','Completed','OCT before review'),                -- OP002
(1,1,2,'2026-11-16 10:15:00','Scheduled','Visual field test'),                -- OP001 second appointment
(3,1,1,'2026-10-06 11:00:00','Completed','Monitor'),                          -- OP003
(4,3,3,'2026-10-07 14:00:00','Completed','Corneal topography'),               -- OP004
(5,4,1,'2026-10-20 10:30:00','Scheduled','Pre-op cataract assessment'),
(6,2,4,'2026-10-21 09:00:00','Scheduled','Anti-VEGF follow-up'),
(7,6,2,'2026-10-22 11:30:00','Scheduled','IOP check'),
(8,5,1,'2026-10-23 14:30:00','Scheduled','Retinal review'),
(9,3,3,'2026-10-24 09:45:00','Scheduled','Contact lens review'),
(10,4,4,'2026-10-25 13:15:00','Scheduled','Cataract surgery booking'),
(11,1,1,'2026-10-26 10:00:00','Scheduled','Glaucoma clinic'),
(12,2,2,'2026-10-27 11:00:00','Scheduled','Macular clinic'),
(5,6,3,'2026-10-28 15:00:00','Scheduled','Second opinion');

INSERT INTO Diagnosis (AppointmentID, DiagnosisName, Notes) VALUES
(1,'Ocular hypertension','Raised IOP both eyes; no field defect'),
(2,'Diabetic macular oedema','Centre-involving DME, right eye'),
(3,'Ocular hypertension','Stable; continue drops'),
(4,'Glaucoma suspect','Thin neuroretinal rim; monitor'),
(5,'Keratoconus','Progressive astigmatism; cross-linking discussed'),
(6,'Age-related cataract','Visually significant, left eye'),
(7,'Wet AMD','Loading phase of anti-VEGF'),
(8,'Primary open-angle glaucoma','On maximal medical therapy'),
(9,'Dry eye syndrome','Evaporative type; lid hygiene advised'),
(10,'Age-related cataract','Bilateral; right eye listed first'),
(11,'Ocular hypertension','Family history of glaucoma'),
(12,'Epiretinal membrane','Observation, vision 6/9');

INSERT INTO Prescription (AppointmentID, PrescriptionDate) VALUES
(1,'2026-10-05'),(2,'2026-10-05'),(3,'2026-11-16'),(5,'2026-10-07'),
(6,'2026-10-20'),(7,'2026-10-21'),(8,'2026-10-22'),(9,'2026-10-24'),
(10,'2026-10-25'),(11,'2026-10-26');

INSERT INTO PrescriptionItem (PrescriptionID, MedicineID, Dose, Route, Frequency, DurationDays) VALUES
(1,1,'One drop','Left eye','At night',90),
(1,2,'One drop','Both eyes','Twice daily',90),
(2,3,'2mg/0.05ml','Intravitreal','Monthly loading',30),
(3,1,'One drop','Both eyes','At night',90),
(4,4,'One drop','Right eye','Four times daily',28),
(5,5,'One drop','Both eyes','Four times daily',14),
(6,3,'2mg/0.05ml','Intravitreal','Monthly',30),
(7,6,'One drop','Both eyes','Twice daily',60),
(7,7,'One drop','Both eyes','Twice daily',60),
(8,8,'One drop','Right eye','For dilation only',1),
(9,5,'One drop','Left eye','Four times daily',21),
(10,1,'One drop','Both eyes','At night',90);

INSERT INTO Treatment (AppointmentID, TreatmentName, Notes) VALUES
(2,'Intravitreal aflibercept injection','Right eye, loading dose 1 of 3'),
(5,'Corneal collagen cross-linking','Booked for right eye'),
(6,'Phacoemulsification cataract surgery','Left eye, awaiting date'),
(7,'Intravitreal aflibercept injection','Left eye, injection 2'),
(8,'Selective laser trabeculoplasty','Consider if IOP not controlled'),
(10,'Phacoemulsification cataract surgery','Right eye first'),
(12,'Observation','6-month OCT review'),
(14,'Laser peripheral iridotomy','Prophylactic, narrow angles');

INSERT INTO FollowUpPlan (AppointmentID, DueDate, Priority, Status) VALUES
(1,'2026-11-16','High',  'Pending'),    -- 6 weeks
(2,'2026-11-02','High',  'Pending'),    -- 4 weeks (source: "Urgent" -> High)
(3,'2027-02-08','Medium','Pending'),    -- 12 weeks
(4,'2027-04-06','Low',   'Pending'),    -- 26 weeks (2026-10-06 + 26 weeks)
(5,'2026-12-02','Medium','Pending'),    -- 8 weeks
(6,'2026-11-03','High',  'Pending'),
(7,'2026-11-18','High',  'Pending'),
(8,'2026-12-22','Medium','Pending'),
(9,'2027-01-24','Low',   'Pending'),
(10,'2026-11-25','Medium','Pending');

INSERT INTO PatientLogin (PatientID, Username, PasswordHash) VALUES
(1,'amina_yusuf',   SHA2('Amina#2026',256)),
(2,'daniel_reed',   SHA2('Daniel#2026',256)),
(3,'sofia_bennett', SHA2('Sofia#2026',256)),
(4,'michael_okoro', SHA2('Michael#2026',256)),
(5,'margaret_turner',SHA2('Margaret#2026',256)),
(6,'david_chen',    SHA2('David#2026',256));

-- ---------------- Post-creation DDL (ALTER TABLE + CHECK + index) ----------------
ALTER TABLE PrescriptionItem
    ADD CONSTRAINT chk_duration CHECK (DurationDays > 0);
ALTER TABLE Appointment
    ADD INDEX idx_patient_date (PatientID, AppointmentDate);

-- ---------------- Controlled UPDATE and DELETE tests ----------------
-- 1. Appointment 1 has already taken place, so mark it Completed. It is seeded
--    as 'Scheduled' above, so this genuinely changes a row. Nothing else
--    depends on Status, so referential integrity is unaffected.
UPDATE Appointment SET Status = 'Completed' WHERE AppointmentID = 1;

-- 2. DELETE one diagnosis. The appointment it belonged to stays, because
--    Diagnosis is the child in that relationship.
DELETE FROM Diagnosis WHERE DiagnosisID = 12;

-- Then check nothing was orphaned. This should come back as 0.
SELECT COUNT(*) AS OrphanCount
FROM Diagnosis d LEFT JOIN Appointment a ON d.AppointmentID = a.AppointmentID
WHERE a.AppointmentID IS NULL;
