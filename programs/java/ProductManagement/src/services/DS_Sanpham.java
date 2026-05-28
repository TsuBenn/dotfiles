package services;


import model.Sanpham;
import java.util.Scanner;

/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */

/**
 *
 * @author user
 */
public class DS_Sanpham {
    //khai bao array de chua cac product
    Sanpham [] arr=new Sanpham[20];
    int count=0; //nam giu so san pham da them vao array
    //khai bao cac method de quan ly ds product
    
    //add a product to arr
    void ThemSP(){
        Sanpham b=new Sanpham();
        b.nhapSP();
        arr[count]=b;
        count++;
    }
    //add nhieu products
    public void ThemNhieuSP(){
       boolean cont=false; 
       int i=0;
       do{
         //Sanpham sp=new Sanpham();
         //sp.nhapSP();
         arr[i]=new Sanpham();
         arr[i].nhapSP();
         i++;
         System.out.println("nhap nua khong(true|false)?");
         Scanner sc=new Scanner(System.in);
         cont=sc.nextBoolean();
       }while(cont&& i<20); 
       count=i;
    }    
    //view all products
    public void displayAll(){
        for (int i = 0; i < count; i++) {
            arr[i].xuatSP();
        }
    }
    //ham nay de xuat cac sp co gia >=100
    public void displaySPtheogia(int gia){
        for(int i=0;i<count;i++){
            if(arr[i].getGiasp()>=gia){
                arr[i].xuatSP();
            }
        }
    }
    //ham nay de xuat cac sp theo ten
    //vidu: ten="ao"
    public void displaySPtheoten(String ten){
        for(int i=0;i<count;i++){
            if(arr[i].getTensp().contains(ten)){
              arr[i].xuatSP();
            }
        }
    }
    //ham nay de xuat cac sp co gia nam giua min va max
    public void displaySPtheoMinMax(double min, double max){
        for(int i=0;i<count ;i++){
            if(arr[i].getGiasp()>=min && arr[i].getGiasp()<=max){
                arr[i].xuatSP();
            }
        }
    }
    //ham nay de xuat gia ban cua cac san pham 
    //dua vao vao giam gia
    public void displayGiabanSP(double giamgia){
      for(int i=0;i<count;i++){
          arr[i].xuatGiaban(giamgia);
        //  System.out.println("gia ban:" + arr[i].giasp*(1-giamgia));
      }  
    }
}
