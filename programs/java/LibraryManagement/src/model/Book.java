/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package model;

/**
 *
 * @author Nguyen Van Binh
 */
import java.util.*;


public class Book {
    private final UUID bookId;
    private String title;
    private String author;
    private String genre;
    private int pubYear;
    private int quantity;

    public Book(String title, String author, String genre, int pubYear, int quantity) {
        this.bookId = UUID.randomUUID();
        this.title = title;
        this.author = author;
        this.genre = genre;
        this.pubYear = pubYear;
        this.quantity = quantity;
    }

    public UUID getBookId() {
        return bookId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getAuthor() {
        return author;
    }

    public void setAuthor(String author) {
        this.author = author;
    }

    public String getGenre() {
        return genre;
    }

    public void setGenre(String genre) {
        this.genre = genre;
    }

    public int getPubYear() {
        return pubYear;
    }

    public void setPubYear(int pubYear) {
        this.pubYear = pubYear;
    }

    public int getQuantity() {
        return quantity;
    }

    public void setQuantity(int quantity) {
        this.quantity = quantity;
    }

    @Override
    public String toString() {
        return "Book{" +
                "id=" + bookId +
                ", title='" + title + '\'' +
                ", author='" + author + '\'' +
                ", genre='" + genre + '\'' +
                ", pubYear=" + pubYear +
                ", quantity=" + quantity +
                '}';
    }
}