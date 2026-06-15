/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package view;

import service.StaffList;

/**
 *
 * @author user
 */
public class Tester4 {
    public static void main(String[] args) {
         StaffList a=new StaffList();
         a.addManyStaffs();
         a.displayALL();
         a.searchStaff("thi no");
         a.searchStaff(1.5);
    }
}
