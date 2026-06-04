package librarymanager;

import java.util.Scanner;
import java.time.LocalDate;
import java.util.UUID;

import manager.BookManager;
import manager.MemberManager;
import manager.BorrowTransactionManager;
import manager.ReportManager;
import manager.Validator;

import model.Book;
import model.ContactInformation;
import model.Member;
import model.BorrowTransaction;

public class LibraryManager {

    private final Scanner sc = new Scanner(System.in);

    private BookManager bookManager;
    private MemberManager memberManager;
    private BorrowTransactionManager transactionManager;
    private ReportManager reportManager;
    private Validator validator;

    public LibraryManager() {
        bookManager = new BookManager();
        memberManager = new MemberManager();
        transactionManager = new BorrowTransactionManager();
        reportManager = new ReportManager(transactionManager);
        validator = new Validator();
    }

    // Look-ahead helpers to protect against type conversion errors
    private boolean isNumeric(String str) {
        if (str == null || str.isEmpty()) return false;
        for (char c : str.toCharArray()) {
            if (!Character.isDigit(c)) return false;
        }
        return true;
    }

    private boolean isValidUUIDString(String str) {
        if (str == null || str.isEmpty()) return false;
        String regex = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$";
        return str.matches(regex);
    }

    // Safely reads menu selection options using pure logic
    private int readSafeMenuChoice() {
        String input = sc.nextLine().trim();
        if (!isNumeric(input)) {
            return -1; // Fallback to trigger default invalid menu switch block
        }
        return Integer.parseInt(input);
    }

    // ===================== BOOK MENU =====================
    private void bookService() {
        while (true) {
            System.out.println("\n===== BOOK MANAGEMENT =====");
            System.out.println("1. Add Book");
            System.out.println("2. View All Books");
            System.out.println("3. Search Book By Title");
            System.out.println("4. Delete Book");
            System.out.println("0. Back");

            int choice = readSafeMenuChoice();

            switch (choice) {
                case 1:
                    System.out.print("Title: ");
                    String title = sc.nextLine().trim();

                    System.out.print("Author: ");
                    String author = sc.nextLine().trim();

                    System.out.print("Genre: ");
                    String genre = sc.nextLine().trim();

                    if (title.isEmpty() || author.isEmpty() || genre.isEmpty()) {
                        System.out.println("Validation Failed: Fields cannot be blank!");
                        break;
                    }

                    System.out.print("Year: ");
                    String yearInput = sc.nextLine().trim();

                    System.out.print("Quantity: ");
                    String qtyInput = sc.nextLine().trim();

                    // Pure conditional filtering instead of a catch-block wrapper
                    if (!isNumeric(yearInput) || !isNumeric(qtyInput)) {
                        System.out.println("Validation Failed: Year and Quantity must contain numeric digits only!");
                        break;
                    }

                    int year = Integer.parseInt(yearInput);
                    int quantity = Integer.parseInt(qtyInput);

                    Book book = new Book(title, author, genre, year, quantity);

                    if (!validator.isValidBook(book)) {
                        System.out.println("Validation Failed: Book validation constraints failed.");
                        break;
                    }

                    bookManager.addBook(book);
                    System.out.println("Add book successfully!");
                    break;

                case 2:
                    for (Book b : bookManager.getAllBooks()) {
                        System.out.println(b);
                    }
                    break;

                case 3:
                    System.out.print("Enter title: ");
                    String searchTitle = sc.nextLine().trim();
                    if (searchTitle.isEmpty()) {
                        System.out.println("Search keyword cannot be empty!");
                        break;
                    }
                    for (Book b : bookManager.findBooksByTitle(searchTitle)) {
                        System.out.println(b);
                    }
                    break;

                case 4:
                    System.out.println("Enter Book ID:");
                    String idStr = sc.nextLine().trim();

                    // Look ahead check to guarantee conversion safely succeeds
                    if (!isValidUUIDString(idStr)) {
                        System.out.println("Invalid UUID string format.");
                        break;
                    }

                    UUID bookId = UUID.fromString(idStr);
                    if (bookManager.deleteBook(bookId)) {
                        System.out.println("Book deleted successfully!");
                    } else {
                        System.out.println("Book ID not found.");
                    }
                    break;

                case 0:
                    return;

                default:
                    System.out.println("Invalid choice! Please input a valid option number.");
            }
        }
    }

    // ===================== MEMBER MENU =====================
    private void memberService() {
        while (true) {
            System.out.println("\n===== MEMBER MANAGEMENT =====");
            System.out.println("1. Add Member");
            System.out.println("2. View Members (With UUIDs)");
            System.out.println("3. Find Member");
            System.out.println("0. Back");

            int choice = readSafeMenuChoice();

            switch (choice) {
                case 1:
                    System.out.print("Member Name: ");
                    String name = sc.nextLine().trim();

                    System.out.print("Email: ");
                    String email = sc.nextLine().trim();

                    System.out.print("Phone: ");
                    String phone = sc.nextLine().trim();

                    if (name.isEmpty() || email.isEmpty() || phone.isEmpty()) {
                        System.out.println("Validation Failed: All fields are mandatory!");
                        break;
                    }

                    if (!validator.isValidMemberInfo(name) || !validator.isValidMemberInfo(email)) {
                        System.out.println("Validation Failed: Formatting constraints violation.");
                        break;
                    }

                    ContactInformation contactInformation = new ContactInformation(name, email, phone);
                    Member member = new Member(contactInformation, 4);

                    if (!validator.isValidMember(member)) {
                        System.out.println("Validation Failed: Corrupt internal member structure.");
                        break;
                    }

                    memberManager.addMember(member);
                    System.out.println("Add member successfully!");
                    break;

                case 2:
                    if (memberManager.getAllMembers().isEmpty()) {
                        System.out.println("No members found.");
                    } else {
                        System.out.println("\n--- MEMBER LIST ---");
                        for (Member m : memberManager.getAllMembers()) {
                            System.out.println("ID: " + m.getMemberId() + " | Name: " + m.getInfo().getName() + " (" + m.getInfo().getEmail() + ")");
                        }
                    }
                    break;

                case 3:
                    System.out.print("Enter member name: ");
                    String memberName = sc.nextLine().trim();
                    if (memberName.isEmpty()) {
                        System.out.println("Search term cannot be empty!");
                        break;
                    }
                    for (Member m : memberManager.findMembersByName(memberName)) {
                        System.out.println("ID: " + m.getMemberId() + " | Name: " + m.getInfo().getName());
                    }
                    break;

                case 0:
                    return;

                default:
                    System.out.println("Invalid choice! Please input a valid option number.");
            }
        }
    }

    // ===================== BORROW MENU =====================
    private void borrowService() {
        while (true) {
            System.out.println("\n===== BORROW MANAGEMENT =====");
            System.out.println("1. Borrow Book");
            System.out.println("2. Return Book");
            System.out.println("3. View Transactions (With UUIDs)");
            System.out.println("0. Back");

            int choice = readSafeMenuChoice();

            switch (choice) {
                case 1:
                    System.out.print("Enter Member ID: ");
                    String mIdStr = sc.nextLine().trim();
                    Member m = memberManager.getMemberById(mIdStr);
                    if (m == null) {
                        System.out.println("Member not found!");
                        break;
                    }

                    if (m.getBorrowedBooks().size() >= m.getBorrowLimit()) {
                        System.out.println("Validation Failed: Member has reached their maximum borrowing limit!");
                        break;
                    }

                    System.out.print("Enter Book ID: ");
                    String bIdStr = sc.nextLine().trim();

                    if (!isValidUUIDString(bIdStr)) {
                        System.out.println("Invalid Book UUID format.");
                        break;
                    }

                    UUID bId = UUID.fromString(bIdStr);
                    Book b = bookManager.getBookById(bId);
                    if (b == null) {
                        System.out.println("Book not found!");
                        break;
                    }

                    if (b.getQuantity() <= 0) {
                        System.out.println("This book is currently out of stock!");
                        break;
                    }

                    System.out.print("Enter days allowed to borrow: ");
                    String daysInput = sc.nextLine().trim();

                    if (!isNumeric(daysInput)) {
                        System.out.println("Validation Failed: Days must be a valid numeric quantity!");
                        break;
                    }

                    int days = Integer.parseInt(daysInput);
                    if (days <= 0) {
                        System.out.println("Invalid duration! Must borrow for at least 1 day.");
                        break;
                    }

                    LocalDate dueDate = LocalDate.now().plusDays(days);
                    BorrowTransaction tx = transactionManager.processBorrow(m, b, dueDate);
                    
                    if (!validator.isValidTransaction(tx)) {
                        System.out.println("Transaction validation failed!");
                        transactionManager.deleteTransaction(tx); 
                        break;
                    }
                    
                    b.setQuantity(b.getQuantity() - 1);
                    System.out.println("Transaction created successfully! ID: " + tx.getTransactionId());
                    break;

                case 2:
                    System.out.print("Enter Transaction ID to return: ");
                    String tIdStr = sc.nextLine().trim();

                    if (!isValidUUIDString(tIdStr)) {
                        System.out.println("Invalid Transaction UUID format.");
                        break;
                    }

                    UUID txId = UUID.fromString(tIdStr);
                    BorrowTransaction returnTx = transactionManager.getTransaction(txId);
                    if (returnTx == null) {
                        System.out.println("Transaction not found!");
                        break;
                    }

                    if (returnTx.getRealReturnDate() != null) {
                        System.out.println("This book was already returned!");
                        break;
                    }

                    transactionManager.processReturn(returnTx);
                    Book returnedBook = returnTx.getBook();
                    returnedBook.setQuantity(returnedBook.getQuantity() + 1);

                    System.out.println("Book returned successfully!");
                    if (returnTx.getFineMoney() > 0) {
                        System.out.println("Overdue Alert! Penalty fine added: $" + returnTx.getFineMoney());
                    }
                    break;

                case 3:
                    if (transactionManager.getAllBorrowTransaction().isEmpty()) {
                        System.out.println("No transactions recorded yet.");
                    } else {
                        System.out.println("\n--- TRANSACTION RECORDS ---");
                        for (BorrowTransaction t : transactionManager.getAllBorrowTransaction()) {
                            System.out.println("TX-ID: " + t.getTransactionId());
                            System.out.println("  Member: " + t.getMember().getInfo().getName() + " [" + t.getMember().getMemberId() + "]");
                            System.out.println("  Book:   " + t.getBook().getTitle());
                            System.out.println("  Status: " + (t.getRealReturnDate() == null ? "ACTIVE (Due: " + t.getDueDate() + ")" : "RETURNED"));
                            System.out.println("----------------------------------------");
                        }
                    }
                    break;

                case 0:
                    return;

                default:
                    System.out.println("Invalid choice! Please input a valid option number.");
            }
        }
    }

    // ===================== REPORT MENU =====================
    private void reportService() {
        while (true) {
            System.out.println("\n===== REPORTS =====");
            System.out.println("1. Current Borrowed Books");
            System.out.println("2. Overdue Books");
            System.out.println("3. Popular Books");
            System.out.println("4. Most Loaned Member");
            System.out.println("0. Back");

            int choice = readSafeMenuChoice();

            switch (choice) {
                case 1:
                    reportManager.displayCurrentBorrowedBooks();
                    break;
                case 2:
                    reportManager.displayOverdueBorrowedBook();
                    break;
                case 3:
                    reportManager.displayPopularBook();
                    break;
                case 4:
                    reportManager.displayMostLoanPerson();
                    break;
                case 0:
                    return;
                default:
                    System.out.println("Invalid choice! Please input a valid option number.");
            }
        }
    }

    // ===================== MAIN MENU =====================
    public void start() {
        while (true) {
            System.out.println("\n========== LIBRARY MANAGEMENT ==========");
            System.out.println("1. Book Management");
            System.out.println("2. Member Management");
            System.out.println("3. Borrow Management");
            System.out.println("4. Reports");
            System.out.println("0. Exit");

            int choice = readSafeMenuChoice();

            switch (choice) {
                case 1:
                    bookService();
                    break;
                case 2:
                    memberService();
                    break;
                case 3:
                    borrowService();
                    break;
                case 4:
                    reportService();
                    break;
                case 0:
                    System.out.println("Program terminated!");
                    return;
                default:
                    System.out.println("Invalid choice! Please input a valid option number.");
            }
        }
    }

    public static void main(String[] args) {
        LibraryManager app = new LibraryManager();
        app.start();
    }
}
