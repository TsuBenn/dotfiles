package model;

import java.util.Scanner;

public class Laptop {

    private String id;
    private String brand;

	public Laptop() {
		this.id = "";
		this.brand = "";
	}

	public Laptop(String id, String brand) {
		this.id = id;
		this.brand = brand;
	}

	public String getId() {
		return id;
	}
	public void setId(String id) {
		this.id = id;
	}
	public String getBrand() {
		return brand;
	}
	public void setBrand(String brand) {
		this.brand = brand;
	}

    public void input() {
        Scanner sc = new Scanner(System.in);
        System.out.println("Enter laptop's ID:");
        id = sc.nextLine();
        System.out.println("Enter laptop's brand:");
        brand = sc.nextLine();
        System.out.println("");
    }

    public void output() {
        System.out.println("Laptop info:");
        System.out.println("ID: " + id);
        System.out.println("Brand: " + brand);
        System.out.println("");
    }

}
