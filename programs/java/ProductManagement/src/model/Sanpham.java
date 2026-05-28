package model;


import java.util.Scanner;

/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */

/**
 *
 * @author user
 */
public class Sanpham {
   //khu vuc khai bao fields
    private int masp;
    private String tensp;
    private double giasp;
    
   //khu vuc khai bao methods  
   //muc tieu:ham nay de nhap tu ban pham ma,ten,gia 
    
   public void nhapSP(){
       //code
       Scanner sc=new Scanner(System.in);
       System.out.println("nhap ma:");
       masp=sc.nextInt();
       System.out.println("nhap ten:");
       sc=new Scanner(System.in);
       tensp=sc.nextLine();
       System.out.println("nhap gia:");
       giasp=sc.nextDouble();
   } 
   //ham nay de xuat : ma,ten gia ra man hinh
   public void xuatSP(){
      /* System.out.println("ma:"+this.masp);
       System.out.println("ten:"+tensp);
       System.out.println("gia:"+giasp);*/
      System.out.format("%5d%20s%10.2f\n",this.masp,tensp,giasp);
      
   }
   public void xuatGiaban(double giamgia){
       System.out.println("gia ban:" + ( giasp*(1-giamgia) ) );
   }
   
   
   //constructors
   
   //default constructor
   //gan 3 fields voi 3 value gi do
   public Sanpham(){
       this.masp=1;
       this.tensp="hoa giay";
       this.giasp=100;
   }
   //constructor with input parameters
   public Sanpham(int ma, String ten, double gia){
      this.masp=ma; 
      this.tensp=ten;
      this.giasp=gia;
   }
   public Sanpham(Sanpham sp){
       this.masp=sp.masp;
       this.tensp=sp.tensp;
       this.giasp=sp.giasp;
   }
   //create a constructor assigned 2 given parameters
   // to 2 fields: tensp,giasp.
   //field "masp" is assigned by current date
   public Sanpham(String ten,double gia){
       this.tensp=ten;
       this.giasp=gia;
       this.masp=(int)System.currentTimeMillis();
   }

    public int getMasp() {
        return masp;
    }

    public void setMasp(int masp) {
        if(masp>0){
           this.masp = masp;
        }
    }

    public String getTensp() {
        return tensp.toUpperCase();
    }

    public void setTensp(String tensp) {
      if(tensp!=null && !tensp.isEmpty())  
        this.tensp = tensp;
    }

    public double getGiasp() {
        return giasp;
    }

    public void setGiasp(double giasp) {
        this.giasp = giasp;
    }
   
   

   
}

