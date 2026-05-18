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
        for (int i = 0; i < len; i++) {
            arr[i].printProduct();
        }
    }

}
