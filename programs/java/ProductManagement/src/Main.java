/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */

/**
 *
 * @author tsubenn
 */

public class Main {

    public static void main(String[] args) {
        
        ListOfProducts arr = new ListOfProducts();

        arr.addProducts();

        arr.displayAll();

        arr.displayAllPrice(800);

        arr.displayAllName("iphone");

        arr.displayAllMinMax(500, 1000);

        arr.displayAllSellPrice(0.1);
        
    }

}


