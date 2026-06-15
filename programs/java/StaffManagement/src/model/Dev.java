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
public class Dev extends Staff{
    private String proLanguage;

    public Dev() {
        super();
        this.proLanguage="";
    }

    public Dev(String proLanguage, String id, String name, String email, String pwd, double basicSalary, Laptop laptop) {
        super(id, name, email, pwd, basicSalary, laptop);
        this.proLanguage = proLanguage;
    }

    public String getProLanguage() {
        return proLanguage;
    }

    public void setProLanguage(String proLanguage) {
        this.proLanguage = proLanguage;
    }
    public void inputStaff(){
        super.inputStaff();
        Scanner sc=new Scanner(System.in);
        System.out.println("enter pro language:");
        this.proLanguage=sc.nextLine();
    }
    public void outputStaff(){
        super.outputStaff();
        System.out.format("%15s",this.proLanguage);
    }
}
