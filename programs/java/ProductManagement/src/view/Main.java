package view;


import services.DS_Sanpham;

/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */

/**
 *
 * @author user
 */
public class Main {
    public static void main(String[] args) {
        
      /*Sanpham b=new Sanpham() ;          
        b.nhapSP();     
       
        Sanpham c=new Sanpham();
        c.nhapSP();
       
        System.out.format("%5s%20s%10s\n", "MA","TEN","GIA");
        b.xuatSP();
        c.xuatSP();*/
        DS_Sanpham ds=new DS_Sanpham();
        ds.ThemNhieuSP();
        ds.displayAll();
        System.out.println("sp theo gia:\n");
        int gia=100;
        ds.displaySPtheogia(gia);
        System.out.println("sp theo ten:\n");
        String ten="ao";
        ds.displaySPtheoten(ten);
        double min=100;
        double max=500;
        ds.displaySPtheoMinMax(min, max);
        double giamgia=0.1;
        ds.displayGiabanSP(giamgia);
    }
}
