package model;

/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */

/**
 *
 * @author Nguyen Van Binh
 */

import java.time.LocalDate;

import java.util.UUID;


public class BorrowTransaction {
    private final UUID transactionId;
    private Book book;
    private Member member;
    private LocalDate borrowDate;
    private LocalDate dueDate;
    private LocalDate realReturnDate;
    private double fineMoney;

    public BorrowTransaction(Book book, Member member, LocalDate borrowDate, LocalDate dueDate) {
        this.transactionId = UUID.randomUUID();
        this.book = book;
        this.member = member;
        this.borrowDate = borrowDate;
        this.dueDate = dueDate;
        this.realReturnDate = null;
        this.fineMoney = 0.0;
    }

    public UUID getTransactionId() {
        return transactionId;
    }

    public Book getBook() {
        return book;
    }

    public Member getMember() {
        return member;
    }

    public LocalDate getBorrowDate() {
        return borrowDate;
    }

    public LocalDate getDueDate() {
        return dueDate;
    }

    public LocalDate getRealReturnDate() {
        return realReturnDate;
    }

    public double getFineMoney() {
        return fineMoney;
    }

    public void setRealReturnDate(LocalDate realReturnDate) {
        this.realReturnDate = realReturnDate;
    }

    public void setFineMoney(double fineMoney) {
        this.fineMoney = fineMoney;
    }

    @Override
    public String toString() {
        return "BorrowTransaction{" +
                "id=" + transactionId +
                ", book=" + book +
                ", member=" + member +
                ", borrowDate=" + borrowDate +
                ", dueDate=" + dueDate +
                ", returnDate=" + realReturnDate +
                ", fine=" + fineMoney +
                '}';
    }
}