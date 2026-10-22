# Library Management System

A DBMS mini-project demonstrating relational database design, SQL querying, integrity constraints, triggers, and a browser-based library interface.

## Features
- Dashboard for book, member, active-loan, and overdue counts
- Searchable book catalog and category filtering
- Add books and register members
- Issue and return books with stock checks
- Automatic stock updates through SQLite triggers
- Fine calculation at ₹5 per overdue day
- Reports for overdue books, popular titles, fines, never-borrowed books, and active loans by author
- SQL console for running queries against the in-browser SQLite database

## Technology
- HTML, CSS, JavaScript
- SQLite in the browser using [sql.js](https://sql.js.org/)
- MySQL 8.0 schema, triggers, and stored procedure
- SQL joins, aggregation, subqueries, indexes, constraints, and normalization

## Repository Structure
```text
.
├── app.html
├── database/
│   ├── schema.sql
│   ├── queries.sql
│   └── sqlite_schema_and_seed.sql
├── docs/
│   └── project-report.md
└── README.md
```

## Run the Browser Demo
1. Download or clone this repository.
2. Open `app.html` in a modern browser with an internet connection (sql.js loads from a CDN).
3. The database is created in memory and populated with fictional sample records each time the page loads. Changes reset when the page is refreshed.

No separate server or database installation is required for the browser demo.

## Database Scripts
- `database/schema.sql` — MySQL 8.0 schema, constraints, triggers, and stored procedure.
- `database/queries.sql` — joins, subqueries, aggregation, overdue loans, and EXPLAIN/index examples.
- `database/sqlite_schema_and_seed.sql` — SQLite schema, triggers, and fictional sample records for local CLI testing.

**Caution:** The MySQL script begins with `DROP DATABASE IF EXISTS library_management`. Run it only in a test environment where replacing that database is acceptable.

## Privacy
Demo member and staff records use fictional labels and placeholder email addresses. Do not commit real student roll numbers, personal contact details, credentials, or private database dumps.

## Documentation
See `docs/project-report.md` for the public-safe project summary. The diagrams provided with the project can be added under a `diagrams/` folder.
