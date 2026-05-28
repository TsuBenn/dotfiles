package model;

import java.util.Scanner;

public class Staff {

    private String id, name, email, password;
    private double baseSalary;

    private Laptop laptop;

    public Staff() {
        id = "";
        name = "";
        email = "";
        password = "";
        baseSalary = 0;
        laptop = new Laptop();
    }

    public Staff(String id, String name, String email, String password, double baseSalary) {
        this.id = id;
        this.name = name;
        this.email = email;
        this.password = password;
        this.baseSalary = baseSalary;
        laptop = new Laptop();
    }

    public Staff(String id, String name, String email, String password, double baseSalary, Laptop laptop) {
		this.id = id;
		this.email = email;
        this.name = name;
		this.password = password;
		this.baseSalary = baseSalary;
		this.laptop = laptop;
	}

	public Laptop getLaptop() {
		return laptop;
	}

	public void setLaptop(Laptop laptop) {
		this.laptop = laptop;
	}

	public String getId() {
        return id;
    }
    public void setId(String id) {
        this.id = id;
    }
    public String getName() {
        return name;
    }
    public void setName(String name) {
        this.name = name;
    }
    public String getEmail() {
        return email;
    }
    public void setEmail(String email) {
        this.email = email;
    }
    public String getPassword() {
        return password;
    }
    public void setPassword(String password) {
        this.password = password;
    }
    public double getBaseSalary() {
        return baseSalary;
    }
    public void setBaseSalary(double baseSalary) {
        this.baseSalary = baseSalary;
    }

    public void inputStaff() {
        Scanner sc = new Scanner(System.in);
        System.out.println("Enter staff's ID:");
        id = sc.nextLine();
        System.out.println("Enter staff's name:");
        name = sc.nextLine();
        System.out.println("Enter staff's email:");
        email = sc.nextLine();
        System.out.println("Enter staff's password:");
        password = sc.nextLine();
        System.out.println("Enter staff's baseSalary:");
        baseSalary = sc.nextDouble();
        sc.nextLine();
        System.out.println("\u001B[A");
        laptop.input();
    }

    public void outputStaff() {
        System.out.println("Staff info:");
        System.out.println("ID: " + id);
        System.out.println("Name: " + name);
        System.out.println("Email: " + email);
        System.out.println("Base salary: " + baseSalary);
        System.out.println("");
    }

    public boolean checkLogin(String email, String password) {
        return this.email.equalsIgnoreCase(email) && this.password.equals(password);
    }

    public void logout() {
        System.out.println(name + " has logged out");
        System.out.println("");
    }

    public void viewPayslip() {
        System.out.println(name + "'s payslip: " + baseSalary);
        System.out.println("");
    }

}
