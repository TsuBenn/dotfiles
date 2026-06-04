package manager;


import model.BorrowTransaction;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import model.Book;
import model.Member;

/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */

/**
 *
 * @author Nguyen Van Binh
 */
public class BorrowTransactionManager {
    private final List<BorrowTransaction> transactions;

    public BorrowTransactionManager() {
        this.transactions = new ArrayList<>();
    }

    public List<BorrowTransaction> borrowTransactions() {
        return transactions;
    }

    public BorrowTransaction processBorrow(Member member, Book book, LocalDate dueDate) {
        BorrowTransaction tx = new BorrowTransaction(book, member, LocalDate.now(), dueDate);
        transactions.add(tx);
        return tx;
    }

    public void processReturn(BorrowTransaction transaction) {
        transaction.setRealReturnDate(LocalDate.now());
        // Ví dụ tính tiền phạt nếu trả muộn
        if (transaction.getRealReturnDate().isAfter(transaction.getDueDate())) {
            transaction.setFineMoney(50.0); // giả định phạt cố định
        }
    }

    public BorrowTransaction getTransaction(UUID transactionId) {
        for (BorrowTransaction tx : transactions) {
            if (tx.getTransactionId().equals(transactionId)) {
                return tx;
            }
        }
        return null;
    }

    public boolean updateTransaction(BorrowTransaction updatedTx) {
        for (int i = 0; i < transactions.size(); i++) {
            if (transactions.get(i).getTransactionId().equals(updatedTx.getTransactionId())) {
                transactions.set(i, updatedTx);
                return true;
            }
        }
        return false;
    }

    public boolean deleteTransaction(BorrowTransaction tx) {
        return transactions.remove(tx);
    }
    
    public List<BorrowTransaction> getAllBorrowTransaction() {
        return transactions;
    }
    
    public List<BorrowTransaction> getTransactionHistoryByMember(Member member) {
        return transactions.stream()
                .filter(tx -> tx.getMember().equals(member))
                .collect(Collectors.toList());
    }

    public List<BorrowTransaction> getTransactionHistoryByBook(Book book) {
        return transactions.stream()
                .filter(tx -> tx.getBook().equals(book))
                .collect(Collectors.toList());
    }

    public List<Book> getAllBorrowedBooks() {
        return transactions.stream()
                .map(BorrowTransaction::getBook)
                .collect(Collectors.toList());
    }
}