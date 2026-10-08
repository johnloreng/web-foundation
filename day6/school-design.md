# School Database – Design Notes

## Tables

### `students`

Stores one row per person who may enrol on courses.  
Key columns: `student_id` (surrogate primary key), `first_name`, `last_name` (both `NOT NULL`), `email` (`NOT NULL UNIQUE` — no two students can share an address), and an optional `date_of_birth`.

### `courses`

Stores one row per taught course.  
Key columns: `course_id` (surrogate primary key), `course_code` (`NOT NULL UNIQUE` — the human-readable identifier such as "CS101"), `title` (`NOT NULL`), and `credits` (`NOT NULL DEFAULT 3`).

### `enrolments`

The **join table** that sits between `students` and `courses`.  
Key columns: `enrolment_id` (surrogate primary key), `student_id` and `course_id` (both foreign keys, both `NOT NULL`), `enrolled_on` (defaults to today), and `grade` (nullable — unknown until the course is assessed).

---

## Relationships

### students → enrolments (one-to-many)

One student can have **many** enrolment records, but each enrolment row belongs to exactly **one** student.  
This is expressed with a foreign key `enrolments.student_id → students.student_id`.

### courses → enrolments (one-to-many)

One course can appear in **many** enrolment records, but each enrolment row references exactly **one** course.  
Expressed with `enrolments.course_id → courses.course_id`.

### students ↔ courses (many-to-many — via `enrolments`)

A student can be enrolled on **many** courses, and a course can have **many** students.  
Relational databases cannot represent a many-to-many link directly between two tables; attempting to do so would require repeating data in either table, making updates error-prone and violating normal form.  
A **join table** (`enrolments`) solves this: each row represents one specific student–course pairing, carries its own attributes (`enrolled_on`, `grade`), and the composite `UNIQUE (student_id, course_id)` constraint prevents the same student from enrolling on the same course twice.

---

## Index recommendation

```sql
CREATE INDEX idx_enrolments_student_id ON enrolments (student_id);
```

**Reason:** The most common query pattern is "find all courses for a given student", which filters `enrolments` by `student_id`.  
Without an index SQLite performs a full table scan of `enrolments` for every lookup.  
As the enrolments table grows (thousands of rows in a real school), this index lets the database jump directly to the relevant rows using a B-tree lookup — O(log n) instead of O(n) — significantly reducing query time.  
A matching index on `course_id` would be the natural second choice for the reverse query ("all students on a given course").

---

## SQL vs NoSQL

For this system, **SQL (a relational database such as SQLite, PostgreSQL, or MySQL) is clearly the right choice**.  
The data has a well-defined, stable schema: every student has the same fields, every course has the same fields, and the relationship between them is consistently represented through enrolments with a grade.  
Referential integrity — enforced by foreign keys — guarantees that an enrolment can never reference a student or course that does not exist, which is critical for academic records where data correctness matters far more than write throughput.  
The many-to-many relationship is modelled cleanly and efficiently with a join table, and SQL's `JOIN`, `GROUP BY`, and aggregation functions make the required queries (counts per course, unenrolled students, grade updates) straightforward and expressive.  
A NoSQL store such as MongoDB would require either embedding course arrays inside student documents (making cross-document queries like "all students on CS101" expensive and inconsistent) or duplicating data across collections — problems SQL was specifically designed to avoid.  
NoSQL would only become attractive here if the schema were highly variable across students or courses, or if the system needed to handle millions of writes per second, neither of which applies to a school enrolment database.
