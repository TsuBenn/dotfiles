package view;


import java.util.Date;
import model.Sanpham;

/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */

/**
 *
 * @author user
 */
public class Main2 {
    public static void main(String[] args) {
        Sanpham a=new Sanpham();
        a.nhapSP();
        a.xuatSP();
       
        Sanpham b=new Sanpham(2,"hoa lan", 400);
        b.xuatSP();
        
        Sanpham c=new Sanpham(b);
        c.xuatSP();
        
        Sanpham d=new Sanpham("hoa hue", 300);
        d.xuatSP();
        
        //sua masp cua d=nam hien hanh
        Date curDate=new Date();
        int year=curDate.getYear()+1900;
        d.setMasp(year);
        System.out.println("masp sau khi sua cua d:"+ d.getMasp());
        //sua giasp c la 600
        c.setGiasp(600);
        System.out.println("gia cua c sau khi sua:" + c.getGiasp());
   }
 
}
