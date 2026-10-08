-- =============================================================
-- school.sql  –  Day 6 assignment
-- Tables: students, courses, enrolments
-- =============================================================

-- ─── DROP (safe re-run) ───────────────────────────────────────
DROP TABLE IF EXISTS enrolments;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS students;

-- ─── CREATE TABLES ───────────────────────────────────────────

CREATE TABLE students (
    student_id    INTEGER  PRIMARY KEY AUTOINCREMENT,
    first_name    TEXT     NOT NULL,
    last_name     TEXT     NOT NULL,
    email         TEXT     NOT NULL UNIQUE,
    date_of_birth DATE
);

CREATE TABLE courses (
    course_id   INTEGER  PRIMARY KEY AUTOINCREMENT,
    course_code TEXT     NOT NULL UNIQUE,
    title       TEXT     NOT NULL,
    credits     INTEGER  NOT NULL DEFAULT 3
);

CREATE TABLE enrolments (
    enrolment_id INTEGER  PRIMARY KEY AUTOINCREMENT,
    student_id   INTEGER  NOT NULL,
    course_id    INTEGER  NOT NULL,
    enrolled_on  DATE     NOT NULL DEFAULT (DATE('now')),
    grade        TEXT,                          -- NULL until graded
    FOREIGN KEY (student_id) REFERENCES students (student_id),
    FOREIGN KEY (course_id)  REFERENCES courses  (course_id),
    UNIQUE (student_id, course_id)              -- prevents duplicate enrolments
);

-- ─── INSERT: students ────────────────────────────────────────

INSERT INTO students (first_name, last_name, email, date_of_birth) VALUES
    ('Alice', 'Mensah',  'alice.mensah@gmail.com',  '2003-04-12'),
    ('Bruno', 'Osei',    'bruno.osei@gmail.com',    '2002-11-30'),
    ('Chloe', 'Appiah',  'chloe.appiah@gmail.com',  '2004-01-22'),
    ('David', 'Asante',  'david.asante@gmail.com',  '2003-07-08');

-- ─── INSERT: courses ─────────────────────────────────────────

INSERT INTO courses (course_code, title, credits) VALUES
    ('CS101', 'Introduction to Computer Science', 3),
    ('MA201', 'Calculus I',                       4),
    ('EN102', 'Academic Writing',                 2),
    ('DB301', 'Database Systems',                 3);

-- ─── INSERT: enrolments ──────────────────────────────────────
-- Alice  -> CS101, MA201, DB301
-- Bruno  -> CS101, EN102
-- Chloe  -> MA201
-- David  -> (no enrolments -- used in query 4)

INSERT INTO enrolments (student_id, course_id, enrolled_on, grade) VALUES
    (1, 1, '2026-09-01', 'A'),    -- Alice  / CS101
    (1, 2, '2026-09-01', 'B+'),   -- Alice  / MA201
    (1, 4, '2026-09-01', NULL),   -- Alice  / DB301  (not yet graded)
    (2, 1, '2026-09-02', 'B'),    -- Bruno  / CS101
    (2, 3, '2026-09-02', 'A-'),   -- Bruno  / EN102
    (3, 2, '2026-09-03', NULL);   -- Chloe  / MA201  (not yet graded)

-- =============================================================
-- QUERIES
-- =============================================================

-- Q1: All courses for one student (by name)
--     e.g. all courses Alice Mensah is enrolled on
SELECT
    s.first_name,
    s.last_name,
    c.course_code,
    c.title,
    c.credits,
    e.grade
FROM   students   s
JOIN   enrolments e ON e.student_id = s.student_id
JOIN   courses    c ON c.course_id  = e.course_id
WHERE  s.first_name = 'Alice'
AND    s.last_name  = 'Mensah'
ORDER  BY c.course_code;

-- Q2: All students on one course
--     e.g. everyone enrolled in CS101
SELECT
    s.student_id,
    s.first_name,
    s.last_name,
    s.email,
    e.grade
FROM   students   s
JOIN   enrolments e ON e.student_id = s.student_id
JOIN   courses    c ON c.course_id  = e.course_id
WHERE  c.course_code = 'CS101'
ORDER  BY s.last_name, s.first_name;

-- Q3: Number of students per course
SELECT
    c.course_code,
    c.title,
    COUNT(e.student_id) AS student_count
FROM   courses c
LEFT JOIN enrolments e ON e.course_id = c.course_id
GROUP  BY c.course_id, c.course_code, c.title
ORDER  BY student_count DESC, c.course_code;

-- Q4: Students who have no enrolments
SELECT
    s.student_id,
    s.first_name,
    s.last_name,
    s.email
FROM   students s
LEFT JOIN enrolments e ON e.student_id = s.student_id
WHERE  e.enrolment_id IS NULL
ORDER  BY s.last_name, s.first_name;

-- Q5: Update one enrolment's grade
--     Set Alice's DB301 grade to 'A'
UPDATE enrolments
SET    grade = 'A'
WHERE  student_id = (SELECT student_id FROM students
                     WHERE first_name = 'Alice' AND last_name = 'Mensah')
AND    course_id  = (SELECT course_id  FROM courses
                     WHERE  course_code = 'DB301');

-- Verify the update
SELECT
    s.first_name,
    s.last_name,
    c.course_code,
    e.grade
FROM   enrolments e
JOIN   students   s ON s.student_id = e.student_id
JOIN   courses    c ON c.course_id  = e.course_id
WHERE  s.first_name = 'Alice'
AND    c.course_code = 'DB301';
