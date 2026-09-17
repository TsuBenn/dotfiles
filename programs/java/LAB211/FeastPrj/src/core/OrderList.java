package core;

import java.io.EOFException;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.sql.ResultSetMetaData;
import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import core.SetMenu;
import tool.ConsoleInputter;

public class OrderList extends ArrayList<Order> {
    public static final String DATE_PAT = "dd/MM/yyyy";

    SetMenuList setMenuList;
    CustomerList customerList;

    public OrderList() {}

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
        Date preferedDate;

        Customer customer;
        SetMenu setMenu;

        customer = customerList.searchCustomer("");

        customerCode = customer.getCode();

        setMenu = (SetMenu) ConsoleInputter.objMenu(this.setMenuList);

        setMenuCode = setMenu.getCode();

        numTable = ConsoleInputter.getInt("Number of Tables", 1, 100);

        boolean before = true;

        do {
            preferedDate = ConsoleInputter.getDate("Prefered date (d/m/y): ", DATE_PAT);
            before = preferedDate.before(new Date());
            if (before) System.out.println("Prefered date must be after today");
        } while (before);

        printOrder(Order.getIdIterator(), customer, setMenu, numTable, preferedDate);

        boolean response = ConsoleInputter.getBoolean("Save order? Y/N");
        if (response) {
            Order newOrder = new Order(customerCode, setMenuCode, numTable, preferedDate);

            this.add(newOrder);
            System.out.printf("New order %d was added." + "\n", newOrder.getOrderCode());
        }

    }

    public Order searchOrder(String query) {
        if (this.isEmpty()) {
            System.out.println("List is Empty!");
            return null;
        }

        query = query.trim();

        while (query.isEmpty()) {
            query = ConsoleInputter.getStr("Code or Search Customer Name: ").toLowerCase().replaceAll(" ", "").trim();
        }
        OrderList results = new OrderList();
        results.setMenuList = setMenuList;

        for (Order order : this) {
            try {
                if (order.getOrderCode() == Integer.parseInt(query)) {
                    return order;
                }
            } catch (Exception e) {}
        }

        if (customerList.isEmpty()) {
            System.out.println("Customer List is Empty!");
            return null;
        }

        Customer customer = customerList.searchCustomer(query);

        for (Order order : this) {
            if (order.getCustCode().equalsIgnoreCase(customer.getCode())) {
                results.add(order);
            }
        }

        if (results.size() == 0) {
            System.out.println("No results!");
            return null;
        } else if (results.size() == 1) {
            results.print();
            return results.get(0);
        }

        results.print();

        int choice = ConsoleInputter.intMenu(results);
        return results.get(choice - 1);
    }

    public void updateOrder() {
        Order order = searchOrder("");
        if (order == null) {
            System.out.println("No order were selected!");
            return;
        }

        int pos = customerList.indexOf(new Customer(order.getCustCode()));
        Customer customer = customerList.get(pos);

        String newSetMenuCode;
        int newNumTable;
        Date newPreferedDate;

        System.out.println("Update Set Menu ["+ order.getSetMenuCode() +"]: ");
        SetMenu newSetMenu = (SetMenu) ConsoleInputter.objMenu(setMenuList, setMenuList.indexOf(new SetMenu(order.getSetMenuCode())));
        newSetMenuCode = newSetMenu.getCode();

        newNumTable = ConsoleInputter.getInt("Update number of tables ["+ order.getNumTable() +"]: ", 1, 100, order.getNumTable());

        boolean before = true;
        do {
            newPreferedDate = ConsoleInputter.getDate("Update prefered date [" + ConsoleInputter.dateStr(order.getPreferedDate(), DATE_PAT) + "]:", DATE_PAT, order.getPreferedDate());
            before = newPreferedDate.before(new Date());
            if (before) System.out.println("Prefered date must be after today!");
        } while (before);

        printOrder(order.getOrderCode(), customer, newSetMenu, newNumTable, newPreferedDate);
        boolean response = ConsoleInputter.getBoolean("Save order? Y/N");
        if (response) {
            order.setSetMenuCode(newSetMenuCode);
            order.setNumTable(newNumTable);
            order.setPreferedDate(newPreferedDate);
        }

    }

    public void print() {
        DecimalFormat dfCustom;
        dfCustom = new DecimalFormat("#,##0");
        if (this.isEmpty()) {
            System.out.println("The Order List is Empty!");
            return;
        }

        String header =
        "-----------------------------------------------------------------------------------\n" +
        "| ID   | Event Date | Customer ID | Set Menu |      Price |  Tables |        Cost |\n" +
        "-----------------------------------------------------------------------------------";

        System.out.println(header);

        String footer =
        "-----------------------------------------------------------------------------------\n";

        String setMenuCode;
        int pos;
        SetMenu setMenu;
        int total;

        for (Order order : this) {
            setMenuCode = order.getSetMenuCode();
            pos = setMenuList.indexOf(new SetMenu(setMenuCode));
            setMenu = setMenuList.get(pos);
            total = order.getNumTable() * setMenu.getPrice();
            Date preferedDate = order.getPreferedDate();
            String line = String.format("| %-4s | %-10s | %-11s | %-8s | %10s | %7s | %11s |",
                order.getOrderCode(),
                ConsoleInputter.dateStr(preferedDate, DATE_PAT),
                order.getCustCode(),
                order.getSetMenuCode(),
                dfCustom.format(setMenu.getPrice()),
                order.getNumTable(),
                dfCustom.format(total)
            );

            System.out.println(line);
        }

        System.out.println(footer);


    }
}
