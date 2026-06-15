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
//is-a duoc thay bang "extends"
//Staff: supclass/father
//BA: subclass/son
public class BA extends Staff{
    private String domain;

    public BA() {
        super();
        this.domain="";
    }

    public BA(String domain, String id, String name, String email, String pwd, double basicSalary) {
        super(id, name, email, pwd, basicSalary);
        this.domain = domain;
    }

    public String getDomain() {
        return domain;
    }

    public void setDomain(String domain) {
        this.domain = domain;
    }
    @Override
    public void inputStaff(){
        super.inputStaff();
        Scanner sc=new Scanner(System.in);
        System.out.println("enter domain:");
        this.domain=sc.nextLine();
    }   
    @Override
    public void outputStaff(){
        super.outputStaff();
        System.out.format("%15s", domain);
    }
    public void sendRequestDayoff(){
        //todo
    }
}
