/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package view;

import java.util.Date;
import java.util.Scanner;
import model.BA;
import model.Dev;
import model.Fesher;
import model.Senior;
import model.Staff;

/**
 *
 * @author user
 */
public class Tester {
    public static void main(String[] args) {
        Staff tmp=null;
        
        System.out.println("Tao thong tin NV theo 1 role sau");
        System.out.println("1. BA");
        System.out.println("2. Fesher");
        System.out.println("3. Senior");
        System.out.println("4. Dev");
        System.out.println("enter a role:");
        Scanner sc=new Scanner(System.in);
        int choice=sc.nextInt();
        switch (choice) {
            case 1:
                tmp=new BA();
                tmp.inputStaff();//source cua BA
                break;
            case 2:
                tmp=new Fesher();
                tmp.inputStaff();//source Fesher
                break;
            case 3:
                tmp=new Senior();
                tmp.inputStaff();//source Senior
                break;
            case 4:
                tmp=new Dev();
                tmp.inputStaff();//source Dev
                break;
        }
        System.out.println("Thong tin NV vua tao");
        tmp.outputStaff();//source ???
          
    }
}
