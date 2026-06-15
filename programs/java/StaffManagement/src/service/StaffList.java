/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package service;

import java.util.Scanner;
import model.BA;
import model.Dev;
import model.Fesher;
import model.Laptop;
import model.Senior;
import model.Staff;

/**
 *
 * @author user
 */
public class StaffList {
    private Staff[] arr=new Staff[100];
    private int count=0;
    
    //ham nay de tao nhieu  Staff dat vao arr
    public void addManyStaffs(){            
        boolean cont=false;
        do{
            Staff tmp = null;
            System.out.println("Tao thong tin NV theo 1 role sau");
            System.out.println("1. BA");
            System.out.println("2. Fesher");
            System.out.println("3. Senior");
            System.out.println("4. Dev");
            System.out.println("enter a role:");
            Scanner sc = new Scanner(System.in);
            int choice = sc.nextInt();
            switch (choice) {
                case 1:
                    tmp = new BA();                    
                    break;
                case 2:
                    tmp = new Fesher();                   
                    break;
                case 3:
                    tmp = new Senior();                  
                    break;
                case 4:
                    tmp = new Dev();                  
                    break;
            }
            tmp.inputStaff();
            arr[count]=tmp;
            count++;
            sc=new Scanner(System.in);
            System.out.println("add more(true|false)?:");
            cont=sc.nextBoolean();
        }while(cont);

    }
    public void displayALL(){
        for(int i=0;i<count;i++){
            arr[i].outputStaff();
        }
    }
    
    public int searchPositionById(String id){
       for(int i=0;i<count;i++){
          Staff kq=arr[i];
          if(kq.getId().equals(id)){  
             return i;
          }
       }
       return -1;
   }
    public Staff searchStaffById(String id){
       for(int i=0;i<count;i++){
          Staff kq=arr[i];
          if(kq.getId().equals(id)){  
             return kq;
          }
       }
       return null;
   }
    public Staff searchStaff(String name){
      return null;    
    }
    public boolean searchStaff(int salary){
        return true;
    }
    public boolean searchStaff(double salary){
        return true;
    }
    public Staff removeStaff(String id){
       Staff result=null;
       int pos=searchPositionById(id);//0
       if(pos!=-1){
          result=arr[pos]; 
          for(int i=pos;i<count-1;i++){
              arr[i]=arr[i+1];
          } 
          arr[count-1]=null;
          count--;
       }
       return result;
   }
}
