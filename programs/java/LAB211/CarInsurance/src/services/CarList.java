package services;

import java.util.Arrays;
import java.util.Comparator;
import java.util.Date;
import tools.GenericList;
import models.Car;
import models.Car.CarType;
import tools.Input;
import tools.TablePrinter;

public class CarList extends GenericList<String, Car> {

    public String sortedByString = "";
    public String sortTypeString = "";

    public void printReport() {
        if (isEmpty()) {
            System.out.printf("Car List is Empty!\n\n");
            return;
        }

        Comparator<Car> comparator = getComparator();
        System.out.println("\nReport: UNINSURED CARS STATEMENTS");
        System.out.printf("Sorted by: %s\n", sortedByString);
        System.out.printf("Sort Type: %s\n\n", sortTypeString);
        listItems(
            comparator,
            false,
            car -> !car.isHasInsurance()
        );
    }

    @Override
    public Comparator<Car> getComparator() {
        System.out.println("Select field for Sorting:");
        int choice = Input.intMenu(
                Arrays.asList(
                        "License Plate",
                        "Vehicle Owner",
                        "Registration Date",
                        "Vehicle Type"),
                0);
        System.out.println("\nSelect Sorting Type:");
        int direction = Input.intMenu(
                Arrays.asList(
                    "ASC",
                    "DESC"
                ),
                0
            );
        System.out.println("");
        Comparator<Car> comparator;
        switch (choice) {
            case 1: comparator = Comparator.comparing(Car::getOwner); sortedByString = "Vehicle Owner"; break;
            case 2: comparator = Comparator.comparing(Car::getRegistrationDate); sortedByString = "Registration Date"; break;
            case 3: comparator = Comparator.comparing(Car::getType); sortedByString = "Vehicle Type"; break;
            default: comparator = Comparator.comparing(Car::getLicensePlate); sortedByString = "License Plate"; break;
        }
        switch (direction) {
            case 1: sortTypeString = "DESC"; return comparator.reversed();
            default: sortTypeString = "ASC"; return comparator;
        }
    }

    // Get key from a Car, which is the car's License Plate
    // Input: The Car.
    // Output: The License Plate.
    @Override
    protected String getKey(Car car) {
        return car.getLicensePlate();
    }

    // Set key of a Car, which is  the car's License Plate
    // Input: The Car and the new license plate.
    // Output: None.
    @Override
    protected void setKey(Car car, String newLicensePlate) {
        car.setLicensePlate(newLicensePlate);
    }

    // Customize search prompt
    // Input: None.
    // Output: String Prompt.
    @Override
    protected String getSearchPrompt() {
        return "Search Car by License Plate, Owner or Brand";
    }

    // Creating a Car from User Input
    // Input: A Car as a default value, can be NULL.
    // Output: A Car created by the User Input.
    //
    // Declare fields.
    // Let the User Input the fields with the default value of the provided Car. If the provided Car is null, force the User to Input something.
    // Create a Car from the Inputs and return it.
    @Override
    protected Car createItem(Car car) {
        String licensePlate = "";
        String owner = "";
        String brand;
        int value;
        Date registrationDate;
        String registrationPlace;
        CarType type;

        if (car == null) {
            do {
                licensePlate = Input.getStr("Enter Car's License Plate").trim();
                if (!keyAvailable(licensePlate)) {
                    System.out.println("This Car's License Plate is already exists!\n");
                }
            } while (!keyAvailable(licensePlate));
        }

        owner = Input.getStr("Enter Car's Owner [2-35 chars]", Car.OWNER_PAT, "Car's Owner Should be 2-35 Characters!", car != null ? car.getOwner() : null);
        brand = Input.getStr("Enter Car's Brand", car != null ? car.getBrand() : null);
        value = Input.getInt("Enter Car's Value", 1000, null, car != null ? car.getValue() : null);

        while (true) {
            registrationDate = Input.getDate("Enter Car's Registration Date", Car.REG_DATE_PAT, car != null ? car.getRegistrationDate() : new Date());
            if (Input.compareDate(registrationDate, new Date()) > 0) {
                System.out.println("Registration Date cannot be in the Future!\n");
            } else {
                break;
            }
        }

        registrationPlace = Input.getStr("Enter Car's Registration Place",
                car != null ? car.getRegistrationPlace() : null);

        System.out.println("Select Car Type:");
        int selectedType = Input.intMenu(Arrays.asList("5 Seaters", "7 Seaters", "9 Seaters"), car != null ? car.getType().ordinal() : 0);
        type = CarType.values()[selectedType];

        System.out.println("");
        return new Car(licensePlate, owner, brand, value, registrationDate, registrationPlace, type);
    }

    // Match Cars to Query, used for searching
    // Input: Car and a Query
    // Output: Boolean
    @Override
    protected boolean matchItem(Car car, String query) {
        String licensePlate = Input.flattenString(car.getLicensePlate());
        String owner = Input.flattenString(car.getOwner());
        String brand = Input.flattenString(car.getBrand());
        return licensePlate.contains(query) || owner.contains(query) || brand.contains(query);
    }

    // Create an Instance of oneself
    // Input: None
    // Output: A new instance of this List
    @Override
    protected GenericList<String, Car> createInstance() {
        return new CarList();
    }

    // Creating a TablePrinter
    // Input: None
    // Output: A TablePrinter
    @Override
    protected TablePrinter getTable() {
        TablePrinter table = new TablePrinter("No Car Information Available!");
        table.addColumn("License Plate", 13);
        table.addColumn("Vehicle Owner", 20);
        table.addColumn("Brand", 20);
        table.addColumn("Value", 12);
        table.addColumn("Registration Date", 17);
        table.addColumn("Registration Place", 18);
        table.addColumn("Vehicle Type", 12);
        return table;
    }

    // Getting a Table Row Values
    // Input: None
    // Output: A TablePrinter
    @Override
    protected Object[] getTableRow(Car car) {
        return new Object[] {
            car.getLicensePlate(),
            car.getOwner(),
            car.getBrand(),
            Input.formatInt(car.getValue(), "$ #,##0"),
            Input.dateToStr(car.getRegistrationDate(), "dd-MM-yyyy"),
            car.getRegistrationPlace(),
            car.getTypeString()
        };
    }

    // The object of the CarList is a "Car"
    // Input: None
    // Output: String
    @Override
    public String getType() {
        return "Car";
    }

    // Check if an Item can be deleted
    // Input: None
    // Output: A TablePrinter
    //
    // Check whether a Car is currently have an Insurance Statement or not
    // If so, then it cannot be deleted.
    @Override
    public boolean canDelete(Car car) {
        return !car.isHasInsurance();
    }

    // Get removal error
    // Input: None
    // Output: A TablePrinter
    @Override
    public String getDeleteError(Car car) {
        if (!car.isHasInsurance()) {
            return "This Car cannot be delete as it still has Insurance Statement.";
        }
        return "";
    }

}
