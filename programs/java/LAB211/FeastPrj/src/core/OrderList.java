package core;

import java.io.EOFException;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.Date;

import tool.ConsoleInputter;

public class OrderList extends ArrayList<Order> {
    public static final String DATE_PAT = "dd/MM/yyyy";

    SetMenuList setMenuList;
    CustomerList customerList;

    public OrderList(SetMenuList setMenuList, CustomerList customerList) {
        this.setMenuList = setMenuList;
        this.customerList = customerList;
    }

    public void readFile(String file) {
        File f = new File(file);
        if (!f.exists()) {
            System.out.printf("the file %s does not exist." + "\n", file);
            return;
        }

        try {
            FileInputStream fis = new FileInputStream(f);
            ObjectInputStream ois = new ObjectInputStream(fis);
            Order anOrder;
            while ((anOrder = (Order) ois.readObject()) != null) {
                this.add(anOrder);
                if (Order.getIdIterator() <= anOrder.getOrderCode()) {
                    Order.setIdIterator(anOrder.getOrderCode() + 1);
                }
            }
        }
        catch (EOFException e) {
            System.out.println("All data in the were read.");
        }
        catch (IOException e) {
            System.err.println(e.getMessage());
        }
        catch (ClassNotFoundException e){
            System.err.println(e.getMessage());
        }
    }

    public void writeFile(String file) {
        if (this.isEmpty()) {
            System.out.println("List is Empty!");
            return;
        }

        try {
            FileOutputStream fo = new FileOutputStream(file);
            ObjectOutputStream os = new ObjectOutputStream(fo);
            for (Order anOrder : this) os.writeObject(anOrder);
            os.close();
            fo.close();
            System.out.println("Data are saved to file");
        }
        catch (Exception e) {
            System.err.println();
        }
    }

    public void printOrder(int orderCode, Customer customer, SetMenu setMenu, int numTable, Date preferedDate) {
        int total = numTable * setMenu.getPrice();
        String frame =
        "-------------------------------------------------------------\n"+
        " Customer order Information [Order ID: " + orderCode + "]\n"+
        "-------------------------------------------------------------";

        System.out.println(frame);
        String customerInfo;
        customerInfo =
        "Code          : " + customer.getCode() + "\n" +
        "Customer Name : " + customer.getName() + "\n" +
        "Phone number  : " + customer.getPhone() + "\n" +
        "Email         : " + customer.getEmail() + "\n" +
        "-------------------------------------------------------------";

        System.out.println(customerInfo);

        DecimalFormat dfCustom;
        dfCustom = new DecimalFormat("#,##0");
        String menuInfo =
        "Code of set menu : " + setMenu.getCode() + "\n" +
        "Set menu name    : " + setMenu.getName() + "\n" +
        "Event date       : " + ConsoleInputter.dateStr(preferedDate, DATE_PAT) + "\n" +
        "Number of tables : " + numTable + "\n" +
        "Price            : " + dfCustom.format(setMenu.getPrice()) + " VND";

        System.out.print(menuInfo);

        String ingredientsInfo = "Ingredients:\n";
        String[] items = setMenu.getIngredients().split("#");
        ingredientsInfo += (items[0] + "\n" + items[1] + "\n" + items[2]);
        System.out.println(ingredientsInfo);
        System.out.println("-------------------------------------------------------------");
        System.out.println(" Total cost: " + dfCustom.format(total) + " VND");
        System.out.println("-------------------------------------------------------------");

    }

    public void addOrder() {
        String customerCode;
        String setMenuCode;
        int numTable;
        Date preferDate;

        Customer customer;
        SetMenu setMenu;

        customer = customerList.searchCustomer();
    }
}
