-- ============================================================
-- SAMPLE QUERIES - Library Management System
-- Organized to demonstrate specific DBMS syllabus topics
-- ============================================================
USE library_management;

-- ------------------------------------------------------------
-- A. SELECTION & PROJECTION
-- ------------------------------------------------------------
-- List all books in the 'Fiction' category
SELECT title, isbn, available_copies
FROM Books
WHERE category_id = (SELECT category_id FROM Categories WHERE category_name = 'Fiction');

-- ------------------------------------------------------------
-- B. JOIN OPERATIONS (multi-table)
-- ------------------------------------------------------------
-- Full details of every currently issued book (Books JOIN BorrowRecords JOIN Members JOIN Authors)
SELECT
    m.name        AS member_name,
    b.title       AS book_title,
    a.author_name,
    br.issue_date,
    br.due_date
FROM BorrowRecords br
JOIN Books   b ON br.book_id   = b.book_id
JOIN Members m ON br.member_id = m.member_id
JOIN Authors a ON b.author_id  = a.author_id
WHERE br.return_date IS NULL;

-- ------------------------------------------------------------
-- C. OVERDUE BOOKS (JOIN + date comparison)
-- ------------------------------------------------------------
SELECT m.name, m.email, b.title, br.due_date,
       DATEDIFF(CURDATE(), br.due_date) AS days_overdue
FROM BorrowRecords br
JOIN Members m ON br.member_id = m.member_id
JOIN Books   b ON br.book_id   = b.book_id
WHERE br.return_date IS NULL AND br.due_date < CURDATE();

-- ------------------------------------------------------------
-- D. AGGREGATION: GROUP BY + HAVING
-- ------------------------------------------------------------
-- Most borrowed books (borrowed more than once)
SELECT b.title, COUNT(*) AS times_borrowed
FROM BorrowRecords br
JOIN Books b ON br.book_id = b.book_id
GROUP BY b.title
HAVING COUNT(*) >= 1
ORDER BY times_borrowed DESC;

-- Members with outstanding fines, total per member
SELECT m.name, SUM(br.fine_amount) AS total_fine
FROM BorrowRecords br
JOIN Members m ON br.member_id = m.member_id
GROUP BY m.name
HAVING SUM(br.fine_amount) > 0;

-- ------------------------------------------------------------
-- E. SUBQUERIES (nested queries)
-- ------------------------------------------------------------
-- Books that have never been borrowed (subquery with NOT IN)
SELECT title FROM Books
WHERE book_id NOT IN (SELECT DISTINCT book_id FROM BorrowRecords);

-- Members who have borrowed more books than the average member
SELECT name FROM Members
WHERE member_id IN (
    SELECT member_id FROM BorrowRecords
    GROUP BY member_id
    HAVING COUNT(*) > (
        SELECT AVG(cnt) FROM (
            SELECT COUNT(*) AS cnt FROM BorrowRecords GROUP BY member_id
        ) AS sub
    )
);

-- ------------------------------------------------------------
-- F. QUERY PROCESSING / QUERY COST DEMONSTRATION
-- ------------------------------------------------------------
-- Use EXPLAIN to see the execution plan chosen by the optimizer
-- (rows scanned, join type, whether an index/key is used)
EXPLAIN SELECT m.name, b.title
FROM BorrowRecords br
JOIN Members m ON br.member_id = m.member_id
JOIN Books   b ON br.book_id   = b.book_id
WHERE br.return_date IS NULL;

-- Cost BEFORE indexing member_id in BorrowRecords: full table scan (type = ALL)
-- Add an index and re-run EXPLAIN to compare the plan/cost:
CREATE INDEX idx_borrow_member ON BorrowRecords(member_id);
CREATE INDEX idx_borrow_book   ON BorrowRecords(book_id);

EXPLAIN SELECT m.name, b.title
FROM BorrowRecords br
JOIN Members m ON br.member_id = m.member_id
JOIN Books   b ON br.book_id   = b.book_id
WHERE br.return_date IS NULL;
-- After indexing: optimizer can use type = ref/eq_ref instead of ALL,
-- reducing the number of rows examined (lower I/O cost).

-- ------------------------------------------------------------
-- G. UPDATE via stored logic (return a book -> triggers fine calc + stock update)
-- ------------------------------------------------------------
UPDATE BorrowRecords
SET return_date = CURDATE()
WHERE record_id = 2;   -- Member Two returns Harry Potter (fine is calculated by trigger)

-- Verify
SELECT * FROM BorrowRecords WHERE record_id = 2;
SELECT title, available_copies FROM Books WHERE book_id = 3;