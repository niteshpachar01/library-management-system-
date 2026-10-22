# Library Management System — Project Report

> Public portfolio edition. Student names, roll numbers, and personal contact details have been omitted. The technical project content is retained in this summary.

## 1. Introduction and Scope
The system models books, authors, categories, members, staff, and borrowing transactions using a relational database. It demonstrates conceptual and logical design, normalization, physical schema design, procedural logic, query processing, and a browser-based front end.

## 2. Objectives
- Model a normalized relational schema (targeting BCNF).
- Enforce entity, referential, and business integrity through keys, constraints, and triggers.
- Demonstrate joins, aggregation, subqueries, and indexing.
- Encapsulate issuing and fine logic in database procedures and triggers.
- Document the system with ER, UML, DFD, and deployment diagrams.
- Provide a demonstrable interface for catalog, membership, issue/return, and reports.

## 3. Data Model
Six entities are used: Authors, Categories, Books, Members, Staff, and BorrowRecords. BorrowRecords resolves the many-to-many relationship between Books and Members and stores issue date, due date, return date, staff reference, and fine amount.

## 4. Normalization
The report discusses UNF, 1NF, 2NF, 3NF, and BCNF, using functional dependencies such as book_id → title/isbn/author/category/copy counts, author_id → author details, category_id → category name, and record_id → loan details. Separate entity tables reduce repeated data and update anomalies.

## 5. Codd's Rules
Selected relational principles are mapped to project features, including information representation, guaranteed access, NULL treatment, online catalog access, high-level data manipulation, integrity independence, and non-subversion.

## 6. Integrity and Business Constraints
- Primary keys identify every record.
- Foreign keys preserve referential integrity.
- CHECK constraints keep copy counts valid and due dates consistent.
- A member may have at most three active loans.
- A book cannot be issued when no copies are available.
- Late returns accrue a fine of ₹5 per day.

## 7. Structural and Behavioural Models
The supplied diagrams cover ER modelling in Chen notation, class structure, issue-book sequence, DFD Level 0 and Level 1, and a simplified deployment model. The original report also describes use-case and activity diagrams.

## 8. Database Schema
The MySQL 8.0 DDL defines Categories, Authors, Books, Members, Staff, and BorrowRecords with primary keys, foreign keys, uniqueness, and CHECK constraints. A parallel SQLite schema supports the in-browser demo.

## 9. Triggers and Stored Procedure
The design includes triggers to reduce stock on issue, restore stock on return, calculate late fines, enforce the three-active-loan limit, and prevent issuing unavailable books. The MySQL script includes `sp_issue_book` to validate availability and insert a loan.

## 10. Query Processing and Cost
Sample queries demonstrate selection/projection, multi-table joins, overdue loans, aggregation with GROUP BY/HAVING, nested queries, and EXPLAIN-based index comparison. Index examples cover BorrowRecords.member_id and BorrowRecords.book_id.

## 11. Application
The single-page `app.html` interface provides:
- Dashboard and current loans
- Searchable catalog and book entry
- Member registration
- Issue and return flows
- Overdue, popularity, fines, never-borrowed, and author-loan reports
- An SQL console for demonstration

The browser demo uses sql.js and an in-memory SQLite database, so demo changes reset on refresh. The MySQL scripts are provided separately and should be run with MySQL.

## 12. References
- Silberschatz, Korth, and Sudarshan, *Database System Concepts*
- Elmasri and Navathe, *Fundamentals of Database Systems*
- E. F. Codd, “A Relational Model of Data for Large Shared Data Banks” (1970)
- MySQL 8.0 Reference Manual
- SQLite Documentation
- sql.js Documentation
