/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package model;

import java.util.Scanner;

/**
 *
 * @author user
 */
public class Staff {
    private String id, name,email,pwd;
    private double basicSalary;
    //vi: 1 Staff has-a 1 Laptop 
    private Laptop laptop;
    
    public Staff() {
        this.id="";
        this.name="";
        this.email="";
        this.pwd="";
        this.basicSalary=0;
        this.laptop=new Laptop(); 
    }

    public Staff(String id, String name, String email, String pwd, double basicSalary) {
        this.id = id;
        this.name = name;
        this.email = email;
        this.pwd = pwd;
        this.basicSalary = basicSalary;
        this.laptop=new Laptop();
    }

    public Staff(String id, String name, String email, String pwd, double basicSalary, Laptop laptop) {
        this.id = id;
        this.name = name;
        this.email = email;
        this.pwd = pwd;
        this.basicSalary = basicSalary;
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

    public String getPwd() {
        return pwd;
    }

    public void setPwd(String pwd) {
        this.pwd = pwd;
    }

    public double getBasicSalary() {
        return basicSalary;
    }

    public void setBasicSalary(double basicSalary) {
        this.basicSalary = basicSalary;
    }

    public Laptop getLaptop() {
        return laptop;
    }

    public void setLaptop(Laptop laptop) {
        this.laptop = laptop;
    }
    
    public void inputStaff(){
       Scanner sc=new Scanner(System.in);
        System.out.println("enter staff's id:");
        this.id=sc.nextLine();
        sc=new Scanner(System.in);
        System.out.println("enter name:");
        this.name=sc.nextLine();
        sc=new Scanner(System.in);
        System.out.println("enter email:");
        this.email=sc.nextLine();
        sc=new Scanner(System.in);
        System.out.println("enter pwd:");
        this.pwd=sc.nextLine();
        sc=new Scanner(System.in);
        System.out.println("enter basic salary:");
        this.basicSalary=sc.nextDouble();
        this.laptop.input();
    }
    public void outputStaff(){
        System.out.format("%10s%15s%15s%10.2f",id,name,email,basicSalary);
        this.laptop.output();
    }
    public boolean checkLogin(String email, String pwd){
        return this.email.equalsIgnoreCase(email) && this.pwd.equals(pwd);
    }
    public void logout(){
        System.out.println("chao ban");
    }
    public void viewPayslip(){
        //todo sau
    }
}
