-- ============================================================
-- LIBRARY MANAGEMENT SYSTEM - DATABASE SCHEMA (MySQL 8.0)
-- ============================================================

DROP DATABASE IF EXISTS library_management;
CREATE DATABASE library_management;
USE library_management;

-- ------------------------------------------------------------
-- 1. CATEGORIES  (removes repeating "category" text from Books -> 2NF/3NF)
-- ------------------------------------------------------------
CREATE TABLE Categories (
    category_id   INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE
);

-- ------------------------------------------------------------
-- 2. AUTHORS  (removes transitive dependency of author details on Book -> 3NF)
-- ------------------------------------------------------------
CREATE TABLE Authors (
    author_id   INT AUTO_INCREMENT PRIMARY KEY,
    author_name VARCHAR(100) NOT NULL,
    nationality VARCHAR(50)
);

-- ------------------------------------------------------------
-- 3. BOOKS
-- ------------------------------------------------------------
CREATE TABLE Books (
    book_id           INT AUTO_INCREMENT PRIMARY KEY,
    title             VARCHAR(150) NOT NULL,
    isbn              VARCHAR(20) UNIQUE,
    author_id         INT NOT NULL,
    category_id       INT NOT NULL,
    publisher         VARCHAR(100),
    total_copies      INT NOT NULL DEFAULT 1,
    available_copies  INT NOT NULL DEFAULT 1,

    CONSTRAINT fk_book_author   FOREIGN KEY (author_id)   REFERENCES Authors(author_id),
    CONSTRAINT fk_book_category FOREIGN KEY (category_id) REFERENCES Categories(category_id),

    -- Enterprise constraint: copies can never be negative
    CONSTRAINT chk_total_copies     CHECK (total_copies >= 0),
    CONSTRAINT chk_available_copies CHECK (available_copies >= 0 AND available_copies <= total_copies)
);

-- ------------------------------------------------------------
-- 4. MEMBERS
-- ------------------------------------------------------------
CREATE TABLE Members (
    member_id       INT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    email           VARCHAR(100) UNIQUE NOT NULL,
    phone           VARCHAR(15),
    address         VARCHAR(200),
    membership_date DATE NOT NULL DEFAULT (CURRENT_DATE)
);

-- ------------------------------------------------------------
-- 5. STAFF / LIBRARIAN
-- ------------------------------------------------------------
CREATE TABLE Staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    name     VARCHAR(100) NOT NULL,
    role     VARCHAR(30) NOT NULL DEFAULT 'Librarian',
    email    VARCHAR(100) UNIQUE
);

-- ------------------------------------------------------------
-- 6. BORROW RECORDS  (junction / associative entity -> resolves M:N between Books & Members)
-- ------------------------------------------------------------
CREATE TABLE BorrowRecords (
    record_id    INT AUTO_INCREMENT PRIMARY KEY,
    book_id      INT NOT NULL,
    member_id    INT NOT NULL,
    staff_id     INT,
    issue_date   DATE NOT NULL DEFAULT (CURRENT_DATE),
    due_date     DATE NOT NULL,
    return_date  DATE NULL,
    fine_amount  DECIMAL(6,2) NOT NULL DEFAULT 0.00,

    CONSTRAINT fk_br_book   FOREIGN KEY (book_id)   REFERENCES Books(book_id),
    -- Referential integrity: cannot delete a member/book that still has borrow history
    CONSTRAINT fk_br_member FOREIGN KEY (member_id) REFERENCES Members(member_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_br_staff  FOREIGN KEY (staff_id)  REFERENCES Staff(staff_id),

    CONSTRAINT chk_due_after_issue CHECK (due_date >= issue_date)
);

-- ============================================================
-- TRIGGERS  (business/enterprise rules the relational model alone can't express)
-- ============================================================

DELIMITER //

-- (a) When a book is issued, reduce available_copies by 1
CREATE TRIGGER trg_after_issue
AFTER INSERT ON BorrowRecords
FOR EACH ROW
BEGIN
    UPDATE Books
    SET available_copies = available_copies - 1
    WHERE book_id = NEW.book_id;
END //

-- (b) When a book is returned, increase available_copies and auto-calculate fine
--     Rule: Rs. 5 per day late, based on due_date vs return_date
CREATE TRIGGER trg_after_return
BEFORE UPDATE ON BorrowRecords
FOR EACH ROW
BEGIN
    IF NEW.return_date IS NOT NULL AND OLD.return_date IS NULL THEN
        IF NEW.return_date > NEW.due_date THEN
            SET NEW.fine_amount = DATEDIFF(NEW.return_date, NEW.due_date) * 5.00;
        ELSE
            SET NEW.fine_amount = 0.00;
        END IF;
    END IF;
END //

CREATE TRIGGER trg_after_return_stock
AFTER UPDATE ON BorrowRecords
FOR EACH ROW
BEGIN
    IF NEW.return_date IS NOT NULL AND OLD.return_date IS NULL THEN
        UPDATE Books
        SET available_copies = available_copies + 1
        WHERE book_id = NEW.book_id;
    END IF;
END //

-- (c) Enterprise constraint: a member cannot borrow more than 3 books at a time
CREATE TRIGGER trg_borrow_limit
BEFORE INSERT ON BorrowRecords
FOR EACH ROW
BEGIN
    DECLARE active_count INT;
    SELECT COUNT(*) INTO active_count
    FROM BorrowRecords
    WHERE member_id = NEW.member_id AND return_date IS NULL;

    IF active_count >= 3 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Member already has 3 books issued. Return one before borrowing again.';
    END IF;
END //

DELIMITER ;

-- ============================================================
-- STORED PROCEDURE  (encapsulated business logic)
-- ============================================================
DELIMITER //
CREATE PROCEDURE sp_issue_book(IN p_book_id INT, IN p_member_id INT, IN p_staff_id INT, IN p_days INT)
BEGIN
    DECLARE copies INT;
    SELECT available_copies INTO copies FROM Books WHERE book_id = p_book_id;

    IF copies IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Book does not exist.';
    ELSEIF copies < 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No copies available.';
    ELSE
        INSERT INTO BorrowRecords (book_id, member_id, staff_id, issue_date, due_date)
        VALUES (p_book_id, p_member_id, p_staff_id, CURDATE(), DATE_ADD(CURDATE(), INTERVAL p_days DAY));
    END IF;
END //
DELIMITER ;

-- ============================================================
-- SAMPLE DATA
-- ============================================================
INSERT INTO Categories (category_name) VALUES
('Fiction'), ('Science'), ('History'), ('Technology'), ('Biography');

INSERT INTO Authors (author_name, nationality) VALUES
('R.K. Narayan', 'Indian'),
('Yuval Noah Harari', 'Israeli'),
('J.K. Rowling', 'British'),
('Robert C. Martin', 'American'),
('Walter Isaacson', 'American');

INSERT INTO Books (title, isbn, author_id, category_id, publisher, total_copies, available_copies) VALUES
('Malgudi Days', '9780143039655', 1, 1, 'Indian Thought Publications', 4, 4),
('Sapiens', '9780062316097', 2, 2, 'Harper', 3, 3),
('Harry Potter and the Sorcerer''s Stone', '9780590353427', 3, 1, 'Scholastic', 5, 5),
('Clean Code', '9780132350884', 4, 4, 'Prentice Hall', 2, 2),
('Steve Jobs', '9781451648539', 5, 5, 'Simon & Schuster', 3, 3);

INSERT INTO Members (name, email, phone, address) VALUES
('Member One', 'member1@example.com', '', ''),
('Member Two', 'member2@example.com', '', ''),
('tarunpreet', 'tarun@example.com', '9876543212', 'Delhi');

INSERT INTO Staff (name, role, email) VALUES
('Librarian One', 'Head Librarian', 'librarian1@example.com'),
('Librarian Two', 'Assistant Librarian', 'librarian2@example.com');

-- Issue a couple of books (fires trg_after_issue automatically)
CALL sp_issue_book(1, 1, 1, 14);   -- Member One borrows Malgudi Days, 14 days
CALL sp_issue_book(3, 2, 1, 7);    -- Member Two borrows Harry Potter, 7 days (short window -> can go overdue)
CALL sp_issue_book(4, 3, 2, 14);   -- Member Three borrows Clean Code