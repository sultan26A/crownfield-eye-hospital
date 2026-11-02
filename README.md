# Crownfield Eye Hospital — ophthalmology database

This is my individual repository for the Crownfield Eye Hospital assignment.

It's a fictional scenario. The hospital keeps its ophthalmology records across paper files, Word documents and spreadsheets, so the same patient gets written down several times, the formats don't match and nothing stops bad data going in. Flytech Ltd asked us to replace all of that with a proper relational database in MySQL, normalised to 3NF.

## What I did

I worked in a group of three. We agreed the overall design and the schema together, and after that we each built and tested our own version.

Everything in this repository is my own work. I did the anomaly analysis on the Appendix 1 data and took it from UNF through to 3NF. I worked out the Prescription and PrescriptionItem split that sorts out the many-to-many link between prescriptions and medicines. I wrote, ran and explained all six queries myself, with Queries 1, 4 and 6 as my particular focus. I also set up the four user roles and the password hashing.

## Running it

I built and tested this in MySQL Workbench on MySQL 8.0. You need at least 8.0.16, because older versions parse CHECK constraints but don't actually enforce them.

Log in as `root` or another admin account, then run the four files in the order below. Each one depends on the one before it, so don't skip ahead.

**Before you start:** `01_schema.sql` begins with a `DROP DATABASE`. If you already have a database called `CrownfieldEyeHospitalDB`, running it will delete it.

| Order | File | What it does |
|---|---|---|
| 1 | `01_schema.sql` | Creates the database and all 12 tables, then loads the five Appendix 1 rows plus my synthetic test data (13 patients, 14 appointments at this point). Adds the CHECK constraints and an index, and runs the controlled UPDATE and DELETE tests. |
| 2 | `02_individual_queries.sql` | Queries 1 to 4: GROUP BY with HAVING, a five-table INNER JOIN, a LEFT JOIN, and a nested subquery. |
| 3 | `03_procedure_and_trigger.sql` | Queries 5 and 6: the stored procedure with an input parameter, and the past-date trigger. The trigger is created here rather than in file 01 — see the assumptions below for why. Also adds one future-dated test appointment, which takes the total to 15. |
| 4 | `04_security.sql` | The four roles and their grants, the patient-only view, SHA-256 password hashing, a note on SQL injection, and the transaction that creates an appointment and its follow-up plan together. |
| — | `05_ERD/` | My three ER diagrams in Crow's Foot notation: conceptual, logical and physical. |

From the command line instead:

```bash
mysql -u root -p < 01_schema.sql
mysql -u root -p < 02_individual_queries.sql
mysql -u root -p < 03_procedure_and_trigger.sql
mysql -u root -p < 04_security.sql
```

One thing to watch: the transaction at the end of file 04 adds another appointment, and it's for Leo Grant. If you run file 04 and then go back and re-run Query 1, he'll show 4 appointments instead of the 3 in my screenshots. Run the queries in file 02 first if you want to match them.

## Assumptions I made

Appendix 1 left a few things open, so I had to decide how to read them.

- Appendix 1 doesn't include NHS numbers, so I generated one per patient and made the column UNIQUE.
- Each clinician has one main specialty, and can take many appointments.
- `Date` and `Time` are really one appointment slot, so I merged them into a single `DATETIME` column.
- A follow-up written as "6 weeks" is an offset from the appointment date, so I worked it out into a real `DueDate`.
- Priority came through as "High", "Routine" and "Urgent". I standardised it to `Low`, `Medium` and `High`, so "Urgent" became High, and "Routine" became Medium at 8 to 12 weeks or Low at 26 weeks. This does lose the distinction between Urgent and High, which I've noted as a limitation in my report.
- "None" under Medicines means there was no prescription at all, so OP003 gets no Prescription row rather than an empty one.
- The trigger blocks appointments dated in the past, which is a problem for the Appendix 1 data because those appointments have already happened. So I create the trigger in file 03, after the seed data has loaded. Everything historical goes in, and from then on any new past-dated booking is rejected.
- Every name, NHS number and contact detail is made up. This is a teaching exercise, not real patient data.

## The accounts and what they can do

I checked each of these with `SHOW GRANTS` — the output is in my report.

| Account | What it can do |
|---|---|
| `admin_user` | Everything. |
| `doctor_user` | Read `Patient`. Read, insert and update `Appointment`. No access to `PatientLogin` at all, no DELETE anywhere, and no schema changes. |
| `reception_user` | Read, insert and update `Patient` and `Appointment`, so it can register people and book them in, but it can't touch diagnoses or prescriptions. |
| `patient_user`, `amina_yusuf` | Read-only, and only through the `PatientOwnRecords` view, which matches the logged-in account name against `PatientLogin.Username` so each patient sees just their own row. |

## What you should see when you run it

These are the numbers in my screenshots. They assume files 01 to 03 have all run, because file 03 adds the future-dated test appointment that takes the count to 15. If you run the files straight through in order, Query 1 in file 02 runs before that, so it shows Maya Shah on 4 rather than 5. Re-run file 02 after file 03 and you get the numbers below.

- **Query 1** (more than 2 appointments): Maya Shah with 5 and Leo Grant with 3.
- **Query 2** (five-table join): 15 rows, one per appointment.
- **Query 3** (patients with no appointment): just Lisa Carter, PatientID 13. I added her without an appointment deliberately, because that's exactly what a LEFT JOIN with `IS NULL` is meant to catch. An INNER JOIN would drop her.
- **Query 4** (above average): the same two clinicians. The average is 15 ÷ 6 = 2.5.
- **Query 5**: `CALL GetPatientAppointments(1)` gives two rows for Amina Yusuf, appointments 3 (2026-11-16) and 1 (2026-10-05).
- **Query 6**: the past-dated INSERT is commented out in the file. Uncomment it and it fails with `SQLSTATE '45000'` and my error message. The future-dated one goes in fine.
- **Transaction** (file 04): the appointment and its follow-up plan are inserted together and committed, and the SELECT at the end returns them joined on `AppointmentID`. Swap the `COMMIT` for a `ROLLBACK` and neither row survives, which is the point.
- **Password hashes**: `SELECT Username, PasswordHash, LENGTH(PasswordHash) FROM PatientLogin;` returns 6 rows, every hash 64 characters.

The passwords in `04_security.sql` are obvious demo ones. They'd need changing before this went anywhere near a real system.
