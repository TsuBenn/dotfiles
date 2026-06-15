/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package service;

import java.util.ArrayList;
import java.util.Scanner;
import model.Laptop;

/**
 *
 * @author user
 */
public class LaptopList {
   private ArrayList<Laptop> arr=new ArrayList<>();
   
   //ham nay de them nhieu Laptop vao arr
   public void addManyLaptops(){
       boolean cont=false;
       do{
           Laptop tmp=new Laptop();
           tmp.input();
           arr.add(tmp);
           System.out.println("add more(true|false)?:");
           Scanner sc=new Scanner(System.in);
           cont=sc.nextBoolean();
       }while(cont);

   }
   public void displayAll(){
       for(int i=0;i<arr.size();i++){
           //Laptop kq=arr.get(i);
           //kq.output();
           arr.get(i).output();
       }
   }
   
   public int searchPositionById(String id){
       for(int i=0;i<arr.size();i++){
          Laptop kq=arr.get(i);
          if(kq.getId().equals(id)){  
             return i;
          }
       }
       return -1;
   }
   public Laptop searchLaptopById(String id){
       for(int i=0;i<arr.size();i++){
          Laptop kq=arr.get(i);
          if(kq.getId().equals(id)){  
             return kq;
          }
       }
       return null;
   }
   
   public Laptop removeLaptop(String id){
       int pos=searchPositionById(id);
       if(pos!=-1){
           return arr.remove(pos);
       }
       return null;
   }
}
