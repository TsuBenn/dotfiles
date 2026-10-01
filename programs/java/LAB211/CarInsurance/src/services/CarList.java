package services;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import models.Car;
import models.Car.CarType;
import tools.Input;
import tools.TablePrinter;

public class CarList extends ArrayList<Car> {

    // Adding a Car
    // Input: None
    // Output: None
    //
    // Declare fields
    // Let the User Input the fields
    // Add to This ArrayList using Car Constructor
    public void addCar() {

        String owner;
        String brand;
        int value;
        Date registrationDate;
        String registrationPlace;
        CarType type;

        owner             = Input.getStr("Enter Car's Owner [2-35 chars]", Car.OWNER_PAT, "Car's Owner Should be 2-35 Characters!");
        brand             = Input.getStr("Enter Car's Brand");
        value             = Input.getInt("Enter Car's Value", 1000, null);
        registrationDate  = Input.getDate("Enter Car's Registration Date", Car.REG_DATE_PAT);
        registrationPlace = Input.getStr("Enter Car's Registration Place");
        type              = Car.CarType.values()[Input.intMenu("Five Seaters", "Seven Seaters", "Nine Seaters")-1];

        this.add(new Car(owner, brand, value, registrationDate, registrationPlace, type));
    }

    public void deleteCar() {

    }

    // Listing Cars
    // Input: printIndex (option to print the Index of each Rows, used for searching items)
    // Output: None, just printing a Table
    //
    // Create a Table from TablePrinter for printing Tables
    // Add Columns for each Car's field, if printIndex then add an extra column for the Index at the front of the table
    // Declare index incase we need it.
    // Print Header
    // Loop through each car:
    //     Print a Table Row and passing in the fields, if printIndex then pass in an index in the front and increment it.
    //     Using List we so can turn it into args for table.printRow() since the args can either have index or not.
    // Print Footer
    public void listCars(boolean printIndex) {

        TablePrinter table = new TablePrinter();

        if (printIndex)
            table.addColumn("Index", 5);
        table.addColumn("License Plate", 13);
        table.addColumn("Owner", 20);
        table.addColumn("Brand", 20);
        table.addColumn("Value", 9);
        table.addColumn("Registration Date", 17);
        table.addColumn("Registration Place", 18);
        table.addColumn("Type", 9);

        int index = 1;

        table.printHeader();
        for (Car car : this) {
            List<Object> rowData = new ArrayList<>();
            if (printIndex)
                rowData.add(index++);
            rowData.add(car.getLicensePlate());
            rowData.add(car.getOwner());
            rowData.add(car.getBrand());
            rowData.add(Input.formatInt(car.getValue(), "#,##0"));
            rowData.add(Input.dateToStr(car.getRegistrationDate(),"dd-MM-yyyy"));
            rowData.add(car.getRegistrationPlace());
            rowData.add(car.getTypeString());

            table.printRow(rowData.toArray());
        }
        table.printFooter();

    }

    // Listing Cars default to printing the Table without Index.
    public void listCars() {
        listCars(false);
    }

}
