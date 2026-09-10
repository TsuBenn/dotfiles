package core;

import java.io.EOFException;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.util.ArrayList;
import java.util.List;

import tool.ConsoleInputter;

public class CustomerList extends ArrayList<Customer> {

    public void addCustomer() {
        String prefix, name, phone, email;
        prefix = ConsoleInputter.getStr(
            "Customer Code Prefix [C/G/K]:",
            Customer.CODE_PREFIX_PAT,
            "Only C,G or K allowed!"
        );
        name = ConsoleInputter.getStr(
            "Customer Name [2-25 char]:",
            Customer.NAME_PAT,
            "Name contains at least 2 and at most 25 characters!"
        );
        phone = ConsoleInputter.getStr(
            "Customer Phone [10 digits]:",
            Customer.PHONE_PAT,
            "Only VN phone (10 digits) allowed!"
        );
        email = ConsoleInputter.getStr(
            "Customer Email [example@company.com]:",
            Customer.EMAIL_PAT,
            "Only valid email allowed (example@company.com)!"
        );

        Customer newCustomer = new Customer(prefix, name, phone, email);
        this.add(newCustomer);
        System.out.printf("New customer %s was added" + "\n", newCustomer.code);
    }

    public void print() {
        if (this.isEmpty()) {
            System.out.println("List is Empty!");
            return;
        }

        String header =
                "----------------------------------------------------------------\n" +
                " Code   | Customer name          | Phone     | Email            \n" +
                "----------------------------------------------------------------";
        String footer =
                "----------------------------------------------------------------";

        System.out.println(header);
        for (Customer cust : this)
            System.out.println(cust);
        System.out.println(footer);
    }

    public Customer searchCustomer(String query, boolean canSkip) {
        if (this.isEmpty()) {
            System.out.println("List is Empty!");
            return null;
        }

        query = query.trim();

        if (query.isEmpty()) {
            do {
                query = ConsoleInputter.getStr("Code or Search Name: ").toLowerCase().replaceAll(" ", "").trim();
            } while (query.isEmpty() && !canSkip);
        }

        if (query.isEmpty()) {
            System.out.println("No Customer was selected, skipping!");
            return null;
        }

        CustomerList results = new CustomerList();
        List<String> result_codes = new ArrayList<>();

        for (Customer customer : this) {
            if (customer.getCode().toLowerCase().equalsIgnoreCase(query)) {
                return customer;
            } else if (customer.getName().toLowerCase().replaceAll(" ", "").contains(query)) {
                results.add(customer);
                result_codes.add(customer.getCode());
                if (results.size() >= 5) {
                    break;
                }
            }
        }

        if (results.size() == 0) {
            System.out.println("No results!");
            return null;
        } else if (results.size() == 1) {
            return results.get(0);
        }

        results.print();

        int choice = ConsoleInputter.intMenu(result_codes);
        return results.get(choice);

    }

    public Customer searchCustomer(String query) {
        return searchCustomer(query, false);
    }

    public void updateCustomer() {
        Customer customer = searchCustomer("");
        if (customer == null)
            return;

        String newName, newPhone, newEmail;

        newName = ConsoleInputter.getStr(
            String.format("Update Customer Name [%s]", customer.getName()),
            Customer.NAME_PAT + "|^$",
            "Name contains at least 2 and at most 25 characters! Leave blank to keep skip change."
        );
        customer.setName(newName.isEmpty() ? newName : customer.getName());

        newPhone = ConsoleInputter.getStr(
            String.format("Update Customer Phone [%s]", customer.getPhone()),
            Customer.PHONE_PAT + "|^$",
            "Only VN phone (10 digits) allowed! Leave blank to keep skip change."
        );
        customer.setPhone(newPhone.isEmpty() ? newPhone : customer.getPhone());

        newEmail = ConsoleInputter.getStr(
            String.format("Update Customer Email [%s]", customer.getEmail()),
            Customer.EMAIL_PAT + "|^$",
            "Only valid email allowed (example@company.com)! Leave blank to keep skip change."
        );
        customer.setEmail(newEmail.isEmpty() ? newEmail : customer.getEmail());

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
            Customer customer;
            while (true) {
                customer = (Customer) ois.readObject();
                this.add(customer);
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
            for (Customer customer : this) os.writeObject(customer);
            os.close();
            fo.close();
            System.out.println("Data are saved to file.");
        } catch (Exception e) {
            System.err.println(e);
        }

    }

}
