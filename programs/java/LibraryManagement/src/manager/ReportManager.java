package manager;


import java.util.List;
import java.util.Map;
import java.util.stream.Collector;
import java.util.stream.Collectors;
import manager.BorrowTransactionManager;
import model.Book;
import model.BorrowTransaction;

/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */

/**
 *
 * @author Nguyen Van Binh
 */
public class ReportManager {
    public static int numberTopMembers = 1;
    public static int numberTopBooks = 1;
    
    private final BorrowTransactionManager transactionManager;
    
     public ReportManager(BorrowTransactionManager transactionManager) {
        this.transactionManager = transactionManager;
    }
     
      public void displayCurrentBorrowedBooks() {
        List<Book> borrowedBooks = transactionManager.getAllBorrowedBooks();
        System.out.println("Danh sách sách đang được mượn:");
        borrowedBooks.forEach(System.out::println);
    }
      
      public void displayOverdueBorrowedBook() {
          System.out.println("Overdue book!!!\n");
          
          transactionManager.getAllBorrowTransaction()
                  .stream()
                  .filter(tx -> tx.getRealReturnDate().isAfter(tx.getDueDate()))
                  .forEach(System.out::println);
      }
      
      public void displayPopularBook() {
          System.out.println("Popular book");
          
          Map<Book, Long> result =  transactionManager.getAllBorrowTransaction().stream()
                  .collect(Collectors.groupingBy(bx -> bx.getBook(), Collectors.counting()));

          for (Map.Entry<Book, Long> r : result.entrySet())
              System.out.println(r.getKey() + ": " + r.getValue());
      }
      
      public void displayMostLoanPerson() {
          System.out.println("Most loan person!!!\n");
          transactionManager.getAllBorrowTransaction()
                  .stream()
                  .collect(Collectors.groupingBy(bx -> bx.getMember(), Collectors.counting()))
                  .entrySet()
                  .stream()
                  .sorted((e1, e2) -> (e1.getValue() > e2.getValue()) ? -1 : 1)
                  .limit(numberTopMembers)
                  .forEach(System.out::println);
      }
}
