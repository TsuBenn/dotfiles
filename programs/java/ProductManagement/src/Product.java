import java.util.Scanner;

/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */

/**
 *
 * @author tsubenn
 */

public class Product {

    // Khu vực khai báo field.

    int id;
    String name;
    double price;


    // Khu vực khai báo field.

    // Take input from user for product's name, code and price.
    void inputProduct() { 
        Scanner sc= new Scanner(System.in);
        System.out.println("Enter product's id: ");
        id = sc.nextInt();
        sc = new Scanner(System.in);

        System.out.println("Enter product's name: ");
        name = sc.nextLine();

        System.out.println("Enter product's price: ");
        price = sc.nextDouble();
    }

    // Prints out product's code, name and price onto screen
    void printProduct() {
        System.out.println("Code : " + id);
        System.out.println("Name : " + name);
        System.out.println("Price: " + price);
    }

    void printSellPrice(double discount) {
        System.out.println("Selling price: " + price*(1-discount) );
    }

    // Must declare all fields and methods that the exam tells you to

    Product() {

    }

    Product(String name, double price) {
        this.name = name;
        this.price = price;
        id = (int) System.currentTimeMillis();
    }

}
