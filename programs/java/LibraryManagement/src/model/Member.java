package model;

/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */

/**
 *
 * @author Admin
 */
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class Member {
    // Attributes from the UML diagram
    private final UUID memberId;
    private ContactInformation info; // Assumed helper class for contact details
    private int borrowLimit;
    private double fineMoney;
    private List<Book> borrowedBooks; // Relates to a Book class (can use a placeholder if not yet built)

    // Constructor
    public Member(ContactInformation info, int borrowLimit) {
        this.memberId = UUID.randomUUID(); // Generates a unique final UUID
        this.info = info;
        this.borrowLimit = borrowLimit;
        this.fineMoney = 0.0;
        this.borrowedBooks = new ArrayList<>();
    }

    // Getters and Setters as specified by +getter() and +setter()
    public UUID getMemberId() {
        return memberId;
    }

    public ContactInformation getInfo() {
        return info;
    }

    public void setInfo(ContactInformation info) {
        this.info = info;
    }

    public int getBorrowLimit() {
        return borrowLimit;
    }

    public void setBorrowLimit(int borrowLimit) {
        this.borrowLimit = borrowLimit;
    }

    public double getFineMoney() {
        return fineMoney;
    }

    public void setFineMoney(double fineMoney) {
        this.fineMoney = fineMoney;
    }

    public List<Book> getBorrowedBooks() {
        return borrowedBooks;
    }

    public void setBorrowedBooks(List<Book> borrowedBooks) {
        this.borrowedBooks = borrowedBooks;
    }
}