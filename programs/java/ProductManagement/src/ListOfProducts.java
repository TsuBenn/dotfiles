import java.util.Scanner;

class ListOfProducts {

    Product[] arr = new Product[20];
    int len = 0; // Length

    void addProduct() {
        Product p = new Product();
        p.inputProduct();
        if (len < 20) {
            arr[len] = p;
        } else {
            System.out.println("List is full!");
        }
    }

    void addProducts() {
        boolean cont = false;
        do {

            Product p = new Product();
            p.inputProduct();
            arr[len] = p;
            len++;
            System.out.println("Continue adding (current length: " + len + ")? (true/false): ");
            Scanner sc = new Scanner(System.in);
            cont = sc.nextBoolean();

        } while (cont && len < 20);
    }

    void displayAll() {
        System.out.println("---DISPLAYING ALL---");
        System.out.println("---");
        for (int i = 0; i < len; i++) {
            arr[i].printProduct();
            System.out.println("---");
        }
    }

    void displayAllPrice(float price) {
        System.out.println("---DISPLAYING ALL THAT COSTS \"" + price + "\"---");
        for (int i = 0; i < len; i++) {
            if (arr[i].price == price) {
                arr[i].printProduct();
                System.out.println("---");
            }
        }
    }

    void displayAllName(String name) {
        System.out.println("---DISPLAYING ALL THAT CONTAINS \"" + name + "\"---");
        for (int i = 0; i < len; i++) {
            if (arr[i].name.toLowerCase().contains(name.toLowerCase())) {
                arr[i].printProduct();
                System.out.println("---");
            }
        }
    }

    void displayAllMinMax(double min, double max) {
        System.out.println("---DISPLAYING ALL THAT COSTS IN THE RANGE OF " + min + " to " + max + " ---");
        for (int i = 0; i < len; i++) {
            if (arr[i].price >= min && arr[i].price <= max) {
                arr[i].printProduct();
                System.out.println("---");
            }
        }
    }

    void displayAllSellPrice(double discount) {
        System.out.println("---DISPLAYING ALL WITH SELL PRICE---");
        for (int i = 0; i < len; i++) {
            arr[i].printSellPrice(discount);
        }
    }

}
