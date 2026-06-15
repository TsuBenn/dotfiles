/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package view;

import java.util.Scanner;
import model.Laptop;
import model.Staff;
import service.LaptopList;
import service.StaffList;

/**
 *
 * @author user
 */
public class Tester2 {
    public static void main(String[] args) {
         StaffList a=new StaffList();
         a.addManyStaffs();
         a.displayALL();
        
        System.out.println("ds may cua cong ty"); 
        LaptopList b=new LaptopList();
        b.addManyLaptops();
        b.displayAll();
       
        boolean cont=false;
        do{
           System.out.println("chon 1 lap top de cap cho nv");
           Scanner sc=new Scanner(System.in);
           System.out.println("nhap ma may can cap:");
           String id=sc.nextLine();//1
           Laptop kq=b.searchLaptopById(id);//F1
        
            System.out.println("chon 1 staff de cap laptop");
            sc=new Scanner(System.in);
            System.out.println("nhap ma nv can tim:");
            String id2=sc.nextLine();//Se123
            Staff kq2=a.searchStaffById(id2);//A1

            if(kq!=null && kq.isStatus()==false && kq2!=null){
                kq2.setLaptop(kq);
                kq.setStatus(true);
                System.out.println("Thong tin nv nhan may:");
                kq2.outputStaff();
            }
            System.out.println("cap may toinh nua ko?:");
            cont=sc.nextBoolean();
        }while(cont);
        
        Scanner sc=new Scanner(System.in);
        System.out.println("test chuc nang xoa nv");
        System.out.println("nhap ma nv can xoa:");
        String idcanxoa=sc.nextLine();
        Staff result=a.removeStaff(idcanxoa);
        if(result==null){
            System.out.println("id ko thay");
        }else{
            System.out.println("nv bi xoa:");
            result.outputStaff();
            result.getLaptop().setStatus(false);
            result.setLaptop(null);
        }
        
    }
}
