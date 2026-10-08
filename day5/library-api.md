# Library Books API

Base URL: `https://api.library.example/v1`

---

## Endpoints

### 1. List all books

| Field | Value |
|---|---|
| **Method** | `GET` |
| **Path** | `/books` |
| **Description** | Returns a paginated array of all books in the library. |
| **Request body** | — |
| **Success status** | `200 OK` |

---

### 2. Get a single book

| Field | Value |
|---|---|
| **Method** | `GET` |
| **Path** | `/books/:id` |
| **Description** | Returns the full details of the book with the given ID. |
| **Request body** | — |
| **Success status** | `200 OK` |

---

### 3. Create a book

| Field | Value |
|---|---|
| **Method** | `POST` |
| **Path** | `/books` |
| **Description** | Adds a new book to the library catalogue. |
| **Success status** | `201 Created` |

**Example request body:**
```json
{
  "title": "The Pragmatic Programmer",
  "author": "David Thomas",
  "isbn": "978-0-13-595705-9",
  "year": 2019,
  "genre": "Software Engineering"
}
```

---

### 4. Update a book (full replace)

| Field | Value |
|---|---|
| **Method** | `PUT` |
| **Path** | `/books/:id` |
| **Description** | Fully replaces the book record with the given ID. |
| **Success status** | `200 OK` |

**Example request body:**
```json
{
  "title": "The Pragmatic Programmer",
  "author": "David Thomas",
  "isbn": "978-0-13-595705-9",
  "year": 2019,
  "genre": "Computer Science"
}
```

---

### 5. Partially update a book

| Field | Value |
|---|---|
| **Method** | `PATCH` |
| **Path** | `/books/:id` |
| **Description** | Updates one or more fields of the book with the given ID without replacing the whole record. |
| **Success status** | `200 OK` |

**Example request body:**
```json
{
  "genre": "Computer Science"
}
```

---

### 6. Delete a book

| Field | Value |
|---|---|
| **Method** | `DELETE` |
| **Path** | `/books/:id` |
| **Description** | Permanently removes the book with the given ID from the catalogue. |
| **Request body** | — |
| **Success status** | `204 No Content` |

---

### 7. List books by author

| Field | Value |
|---|---|
| **Method** | `GET` |
| **Path** | `/books?author=<name>` |
| **Description** | Returns all books whose author field matches (or contains) the given name. Uses the same `/books` collection endpoint as #1 — no extra request needed; filtering is done via query parameter. |
| **Request body** | — |
| **Success status** | `200 OK` |

**Example:**
```
GET /books?author=Tolkien
```

---

## Error Codes

| Code | Name | When it happens |
|---|---|---|
| `400` | Bad Request | The request body is malformed or missing a required field — e.g. `POST /books` is sent without a `title`, or the `year` field contains a string instead of a number. |
| `404` | Not Found | The requested resource does not exist — e.g. `GET /books/9999` when no book with ID 9999 is in the database, or `DELETE /books/9999` for the same reason. |

**Example 400 response:**
```json
{
  "error": "Bad Request",
  "message": "Field 'title' is required."
}
```

**Example 404 response:**
```json
{
  "error": "Not Found",
  "message": "No book found with id 9999."
}
```
