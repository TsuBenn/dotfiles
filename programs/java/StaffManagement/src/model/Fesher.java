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
public class Fesher extends Dev{
    private boolean fullStack;
    public Fesher(){
        super();
        this.fullStack=true;
    }

    public Fesher(boolean fullStack, String proLanguage, String id, String name, String email, String pwd, double basicSalary, Laptop laptop) {
        super(proLanguage, id, name, email, pwd, basicSalary, laptop);
        this.fullStack = fullStack;
    }

    public boolean isFullStack() {
        return fullStack;
    }

    public void setFullStack(boolean fullStack) {
        this.fullStack = fullStack;
    }
    public void inputStaff(){
        super.inputStaff();
        Scanner sc=new Scanner(System.in);
        System.out.println("enter is fullstack(true|false)?:");
        this.fullStack=sc.nextBoolean();
    }
    public void outputStaff(){
        super.inputStaff();
        System.out.format("%10s",""+this.fullStack);
        
    }
}
