import core.CustomerList;
import core.OrderList;
import core.SetMenuList;
import tool.ConsoleInputter;

public class Main {
    public static void main(String[] args) {

        String setMenuFile = "FeastMenu.csv";
        String customerFile = "customers.dat";
        String orderFile = "feast_order_service.dat";

        SetMenuList setMenuList = new SetMenuList();
        setMenuList.readFile(setMenuFile);
        if (setMenuList.isEmpty()) {
            System.out.println("Set menus are not ready. The program can not run!");
            ConsoleInputter.getStr("Enter to quit.");
            System.exit(0);
        }
        CustomerList customerList = new CustomerList();
        customerList.readFile(customerFile);
        OrderList orderList = new OrderList(setMenuList, customerList);
        orderList.readFile(orderFile);

        Object[] menuOptions = {
                "Register Customers",
                "Update customer information",
                "Search for customer information by name",
                "Display feast menus",
                "Place a feast order",
                "Update order information",
                "Save data to file",
                "Display Customer List",
                "Display Order Lists",
                "Quit",
        };

        int choice;
        boolean customerChanged = false;
        boolean orderChanged = false;
        String title = "\nFEAST ORDER MANAGEMENT\n------------------------------------";

        do {
            System.out.println(title);
            choice = ConsoleInputter.intMenu(menuOptions);
            switch(choice) {
                case 1: customerList.addCustomer(); customerChanged = true; break;
                case 2: customerList.updateCustomer(); customerChanged = true; break;
                case 3: System.out.println(customerList.searchCustomer("").toString()); break;
                case 4: setMenuList.print(); break;
                case 5: orderList.addOrder(); orderChanged = true; break;
                case 6: orderList.updateOrder(); orderChanged = true; break;
                case 7:
                    if (customerChanged) {
                        customerList.writeFile(customerFile);
                        customerChanged = false;
                    }
                    if (orderChanged) {
                        orderList.writeFile(orderFile);
                        orderChanged = false;
                    }
                    break;
                case 8: customerList.print(); break;
                case 9: orderList.print(); break;
                default:
                    if (customerChanged || orderChanged) {
                        boolean response = ConsoleInputter.getBoolean("Save Changes? Y/N");
                        if (response) {
                            if (customerChanged) {
                                customerList.writeFile(customerFile);
                                customerChanged = false;
                            }
                            if (orderChanged) {
                                orderList.writeFile(orderFile);
                                orderChanged = false;
                            }
                            System.out.println("Saved. Good bye!");
                        }
                    }
            }
        } while (choice < menuOptions.length);

    }
}
