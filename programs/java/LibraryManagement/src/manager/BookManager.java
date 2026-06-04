package manager;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

import model.Book;

/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */

/**
 *
 * @author Nguyen Van Binh
 */
// Lớp BookManager: quản lý danh sách Book
public class BookManager {
    private List<Book> books;

    public BookManager() {
        this.books = new ArrayList<>();
    }

    public void addBook(Book book) {
        books.add(book);
    }

    public Book getBookById(UUID bookId) {
        for (Book b : books) {
            if (b.getBookId().equals(bookId)) {
                return b;
            }
        }
        return null;
    }

    public boolean updateBook(UUID bookId, Book updatedBook) {
        for (int i = 0; i < books.size(); i++) {
            if (books.get(i).getBookId().equals(bookId)) {
                books.set(i, updatedBook);
                return true;
            }
        }
        return false;
    }

    public boolean deleteBook(UUID bookId) {
        return books.removeIf(b -> b.getBookId().equals(bookId));
    }

    public List<Book> findBooksByTitle(String title) {
        return books.stream()
                .filter(b -> b.getTitle().equalsIgnoreCase(title))
                .collect(Collectors.toList());
    }

    public List<Book> findBooksByAuthor(String author) {
        return books.stream()
                .filter(b -> b.getAuthor().equalsIgnoreCase(author))
                .collect(Collectors.toList());
    }

    public List<Book> getAllBooks() {
        return new ArrayList<>(books);
    }
}
