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
public class Laptop {
   private String id;
   private String brand;
   private boolean status;
   
   public Laptop() {
       this.id="";
       this.brand="";
       this.status=false;
   }

    public Laptop(String id, String brand, boolean status) {
        this.id = id;
        this.brand = brand;
        this.status=status;
    }

    public boolean isStatus() {
        return status;
    }

    public void setStatus(boolean status) {
        this.status = status;
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
   
    public void input(){
        Scanner sc=new Scanner(System.in);
        System.out.println("enter laptop's id:");
        this.id=sc.nextLine();
        sc=new Scanner(System.in);
        System.out.println("enter brand:");
        this.brand=sc.nextLine();
        System.out.println("enter status:");
        this.status=sc.nextBoolean();
    }
    public void output(){
        System.out.println("laptop:"+ this.id+","+this.brand+","+ this.status);
    }
}
