package manager;

import model.Book;
import model.Member;
import model.BorrowTransaction;

public class Validator {

    // Kiểm tra sách hợp lệ
    public boolean isValidBook(Book book) {

        if (book == null) {
            return false;
        }

        if (book.getTitle() == null || book.getTitle().trim().isEmpty()) {
            return false;
        }

        if (book.getAuthor() == null || book.getAuthor().trim().isEmpty()) {
            return false;
        }

        if (book.getGenre() == null || book.getGenre().trim().isEmpty()) {
            return false;
        }

        return book.getQuantity() >= 0;
    }

    // Kiểm tra thông tin thành viên
    public boolean isValidMemberInfo(String contactInfo) {

        return contactInfo != null && !contactInfo.trim().isEmpty();
    }

    // Kiểm tra member hợp lệ
    public boolean isValidMember(Member member) {

        if (member == null) {
            return false;
        }

        if (member.getInfo() == null) {
            return false;
        }

        return member.getBorrowLimit() >= 0;
    }

    // Kiểm tra giao dịch mượn sách
    public boolean isValidTransaction(BorrowTransaction transaction) {

        if (transaction == null) {
            return false;
        }

        if (transaction.getBook() == null) {
            return false;
        }

        if (transaction.getMember() == null) {
            return false;
        }

        if (transaction.getBorrowDate() == null) {
            return false;
        }

        if (transaction.getDueDate() == null) {
            return false;
        }

        return !transaction.getDueDate()
                .isBefore(transaction.getBorrowDate());
    }
}