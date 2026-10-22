-- Combined SQLite schema + seed data (extracted from app.html for CLI testing)

CREATE TABLE Categories (
  category_id INTEGER PRIMARY KEY AUTOINCREMENT,
  category_name TEXT NOT NULL UNIQUE
);
CREATE TABLE Authors (
  author_id INTEGER PRIMARY KEY AUTOINCREMENT,
  author_name TEXT NOT NULL,
  nationality TEXT
);
CREATE TABLE Books (
  book_id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  isbn TEXT UNIQUE,
  author_id INTEGER NOT NULL REFERENCES Authors(author_id),
  category_id INTEGER NOT NULL REFERENCES Categories(category_id),
  publisher TEXT,
  total_copies INTEGER NOT NULL DEFAULT 1 CHECK(total_copies >= 0),
  available_copies INTEGER NOT NULL DEFAULT 1 CHECK(available_copies >= 0 AND available_copies <= total_copies)
);
CREATE TABLE Members (
  member_id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  address TEXT,
  membership_date TEXT NOT NULL DEFAULT (date('now'))
);
CREATE TABLE Staff (
  staff_id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'Librarian',
  email TEXT UNIQUE
);
CREATE TABLE BorrowRecords (
  record_id INTEGER PRIMARY KEY AUTOINCREMENT,
  book_id INTEGER NOT NULL REFERENCES Books(book_id),
  member_id INTEGER NOT NULL REFERENCES Members(member_id),
  staff_id INTEGER REFERENCES Staff(staff_id),
  issue_date TEXT NOT NULL DEFAULT (date('now')),
  due_date TEXT NOT NULL,
  return_date TEXT,
  fine_amount REAL NOT NULL DEFAULT 0,
  CHECK (due_date >= issue_date)
);

-- Trigger: reduce available copies when a book is issued
CREATE TRIGGER trg_after_issue AFTER INSERT ON BorrowRecords
BEGIN
  UPDATE Books SET available_copies = available_copies - 1 WHERE book_id = NEW.book_id;
END;

-- Trigger: restore available copies when a book is returned
CREATE TRIGGER trg_after_return AFTER UPDATE OF return_date ON BorrowRecords
WHEN NEW.return_date IS NOT NULL AND OLD.return_date IS NULL
BEGIN
  UPDATE Books SET available_copies = available_copies + 1 WHERE book_id = NEW.book_id;
END;

-- Trigger: enforce enterprise constraint - max 3 active loans per member
CREATE TRIGGER trg_borrow_limit BEFORE INSERT ON BorrowRecords
BEGIN
  SELECT CASE WHEN (
    (SELECT COUNT(*) FROM BorrowRecords WHERE member_id = NEW.member_id AND return_date IS NULL) >= 3
  ) THEN RAISE(ABORT, 'Member already has 3 books issued. Return one before borrowing again.')
  END;
END;

-- Trigger: prevent issuing a book with zero available copies
CREATE TRIGGER trg_no_stock BEFORE INSERT ON BorrowRecords
BEGIN
  SELECT CASE WHEN (
    (SELECT available_copies FROM Books WHERE book_id = NEW.book_id) < 1
  ) THEN RAISE(ABORT, 'No copies available for this book.')
  END;
END;


INSERT INTO Categories (category_name) VALUES ('Fiction'),('Science'),('History'),('Technology'),('Biography');
INSERT INTO Authors (author_name, nationality) VALUES
 ('R.K. Narayan','Indian'),('Yuval Noah Harari','Israeli'),('J.K. Rowling','British'),
 ('Robert C. Martin','American'),('Walter Isaacson','American');
INSERT INTO Books (title, isbn, author_id, category_id, publisher, total_copies, available_copies) VALUES
 ('Malgudi Days','9780143039655',1,1,'Indian Thought Publications',4,4),
 ('Sapiens','9780062316097',2,2,'Harper',3,3),
 ('Harry Potter and the Sorcerer''s Stone','9780590353427',3,1,'Scholastic',5,5),
 ('Clean Code','9780132350884',4,4,'Prentice Hall',2,2),
 ('Steve Jobs','9781451648539',5,5,'Simon & Schuster',3,3);
INSERT INTO Members (name, email, phone, address) VALUES
 ('Member One','member1@example.com','',''),
 ('Member Two','member2@example.com','',''),
 ('Member Three','member3@example.com','','');
INSERT INTO Staff (name, role, email) VALUES
 ('Librarian One','Head Librarian','librarian1@example.com'),
 ('Librarian Two ','Assistant Librarian','librarian2@example.com');
INSERT INTO BorrowRecords (book_id, member_id, staff_id, issue_date, due_date) VALUES
 (1,1,1, date('now','-5 day'), date('now','+9 day')),
 (3,2,1, date('now','-10 day'), date('now','-3 day')),
 (4,3,2, date('now','-2 day'), date('now','+12 day'));