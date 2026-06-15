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
public class Senior extends Dev{
    private int expYear;
    public Senior(){
        super();
        this.expYear=0;
    }

    public Senior(int expYear, String proLanguage, String id, String name, String email, String pwd, double basicSalary, Laptop laptop) {
        super(proLanguage, id, name, email, pwd, basicSalary, laptop);
        this.expYear = expYear;
    }

    public int getExpYear() {
        return expYear;
    }

    public void setExpYear(int expYear) {
        this.expYear = expYear;
    }
    public void inputStaff(){
        super.inputStaff();
        Scanner sc=new Scanner(System.in);
        System.out.println("enter exp year:");
        this.expYear=sc.nextInt();
    }
    public void outputStaff(){
        super.outputStaff();
        System.out.format("%15s",""+ this.expYear);
    }
}
