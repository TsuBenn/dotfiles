package services;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import models.Car;
import models.Car.CarType;
import tools.Input;
import tools.TablePrinter;

public class CarList {

    // Managing a HashMap separately instead of extending.
    // HashMap having the Car's License Plate as the Key, and the Car Object itself
    // as Value.
    Map<String, Car> map = new HashMap<>();

    public String getKey(Car car) {
        return car.getLicensePlate();
    }

    // Creating a Car from User Input
    // Input: A Car as a default value, can be NULL.
    // Output: A Car created by the User Input.
    //
    // Declare fields.
    // Let the User Input the fields with the default value of the provided Car. If the provided Car is null, force the User to Input something.
    // Create a Car from the Inputs and return it.
    public Car createCar(Car car) {
        String owner = "";
        String brand;
        int value;
        Date registrationDate;
        String registrationPlace;
        CarType type;

        owner = Input.getStr("Enter Car's Owner [2-35 chars]", Car.OWNER_PAT, "Car's Owner Should be 2-35 Characters!", car != null ? car.getOwner() : null);
        brand = Input.getStr("Enter Car's Brand", car != null ? car.getBrand() : null);
        value = Input.getInt("Enter Car's Value", 1000, null, car != null ? car.getValue() : null);
        registrationDate = Input.getDate("Enter Car's Registration Date", Car.REG_DATE_PAT, car != null ? car.getRegistrationDate() : null);
        registrationPlace = Input.getStr("Enter Car's Registration Place", car != null ? car.getRegistrationPlace() : null);

        int selectedType = Input.intMenu(List.of("Five Seaters", "Seven Seaters", "Nine Seaters"), car != null ? car.getType().ordinal() : null) - 1;
        type = Car.CarType.values()[selectedType];

        System.out.println("");
        return new Car(owner, brand, value, registrationDate, registrationPlace, type);
    }

    // Creating a new car from nothing
    // Input: None..
    // Output: Car.
    //
    // Create car without a default Car.
    public Car createCar() {
        return createCar(null);
    }

    // Adding a Car from User Input
    // Input: None.
    // Output: None.
    //
    // Create Car from User Inputer.
    // Add to this Map using by creating a Car from User Input and print a success notice.
    public void addCar() {
        addCar(createCar());
        System.out.println("A Car has been added!\n");
    }

    // Adding a Car from Fields
    // Input: Car fields except License Plate since it's automated.
    // Output: None.
    //
    // Add Car directly with fields instead of asking User Input.
    public void addCar(String owner, String brand, int value, Date registrationDate, String registrationPlace,
            Car.CarType type) {
        Car new_car = new Car(owner, brand, value, registrationDate, registrationPlace, type);
        addCar(new_car);
    }

    // Adding an existing Car
    // Input: A Car.
    // Output: None.
    //
    // Add Car directly with a Car.
    public void addCar(Car car) {
        map.put(car.getLicensePlate(), car);
    }

    // Removing a Car
    // Input: None
    // Output: None
    //
    // Let the User choose a Car to be Deleted by Search Car and Select Car in that Searched Result.
    // If Car to be Deleted is NULL, print a warning and return with no changes.
    // Else remove the Car from Map by using the Car License as Key and print a success notice.
    public void deleteCar() {
        Car carToDelete = searchCar().selectCar();
        if (carToDelete == null) {
            System.out.println("No Car has been Deleted!\n");
            return;
        }

        if (Input.getBool("Comfirm Delete?")) {
            System.out.println("");
            map.remove(carToDelete.getLicensePlate());
            System.out.println("A Car has been Deleted!\n");
        } else
            System.out.println("No Car has been Deleted! (Canceled)\n");
    }

    // Updating a Car
    // Input: None
    // Output: None
    //
    // Let the User choose a Car to be Updated by Search Car and Select Car in that Searched Result.
    // If Car to be Updated is NULL, print a warning and return with no changes.
    // Else Create a new Car with the To be Updated Car as the default value.
    // after that override the To Be Updated Car in the map with the Updated one using the To Be Updated Car License Plate as Key.
    public void updateCar() {
        Car carToBeUpdated = searchCar().selectCar();
        if (carToBeUpdated == null) {
            System.out.println("No Car has been Updated!\n");
            return;
        }

        Car updatedCar = createCar(carToBeUpdated);
        updatedCar.setLicensePlate(carToBeUpdated.getLicensePlate());

        System.out.println("OLD:");
        printCar(carToBeUpdated);
        System.out.println("NEW:");
        printCar(updatedCar);

        if (Input.getBool("Comfirm Update?")) {
            System.out.println("");
            map.put(carToBeUpdated.getLicensePlate(), updatedCar);
            System.out.println("A Car has been Updated!\n");
        } else {
            System.out.println("");
            System.out.println("No Car has been Updated! (Canceled)\n");
        }
    }

    // Match Cars
    // Input: Car and Query
    // Output: Boolean
    //
    // A helper function for comparing during searching.
    // In this case, matching query against licensePlate, Owner and Brand.
    public boolean matchCar(Car car, String query) {
        String licensePlate = Input.flattenString(car.getLicensePlate());
        String owner = Input.flattenString(car.getOwner());
        String brand = Input.flattenString(car.getBrand());
        return licensePlate.contains(query) || owner.contains(query) || brand.contains(query);
    }

    // Searching Cars
    // Input: Search Query.
    // Output: A CarList contains matching Cars.
    //
    // Create an Empty CarList acting as the Search Result.
    // Check if the query is directly searching for License Plate by checking whether the Map has simlar Key or not.
    // If not convert CarList into a List, flatten the query and iterate through each car:
    //    Check car against query using Match Car function.
    //    If match then add that Car to the Search Result List.
    // Return the Search Result List.
    public CarList searchCar(String query) {

        CarList searchedCar = new CarList();

        if (map.containsKey(query)) {
            searchedCar.addCar(map.get(query));
            return searchedCar;
        }

        List<Car> cars = getList();

        query = Input.flattenString(query);

        for (Car car : cars) {
            if (matchCar(car, query)) {
                searchedCar.addCar(car);
            }
        }

        System.out.println("");
        return searchedCar;
    }

    // Asking the User for query then call searchCar with the inputted query.
    public CarList searchCar() {
        String query = Input.getStr("Search Car by License Plate, Owner or Brand");
        return searchCar(query);
    }

    // Listing Cars
    // Input: None
    // Output: Car
    //
    // Convert CarList into a List.
    // Print out the Car Table with the Index Column.
    // If the List only has 1 item then return that item
    // Else ask the user for their selection on the List via the Index from 1 -> List size.
    // Return the Car that the user selected from the list.
    public Car selectCar() {
        if (map.isEmpty()) {
            System.out.println("Car List is Empty!");
            return null;
        }
        List<Car> list = getList();

        listCars(true);

        if (map.size() == 1) {
            return list.get(0);
        }

        int choice = Input.getInt("Select index", 1, list.size(), 1);

        System.out.println("");
        return list.get(choice - 1);
    }

    // Listing Cars
    // Input: None
    // Output: List of cars
    //
    // Return the CarList as a List instead of a Map.
    public List<Car> getList() {
        if (map.isEmpty()) {
            System.out.println("Car List is Empty!");
            return new ArrayList<>();
        }
        return new ArrayList<>(map.values());
    }

    // Listing Cars
    // Input: printIndex (option to print the Index of each Rows, used for searching
    // items)
    // Output: None, just printing a Table
    //
    // Create a Table from TablePrinter for printing Tables
    // Add Columns for each Car's field, if printIndex then add an extra column for
    // the Index at the front of the table
    // Declare index incase we need it.
    // Print Header
    // Loop through each car:
    // Print a Table Row and passing in the fields, if printIndex then pass in an
    // index in the front and increment it.
    // Using List we so can turn it into args for table.printRow() since the args
    // can either have index or not.
    // Print Footer
    public void listCars(boolean printIndex) {
        if (map.isEmpty()) {
            System.out.println("Car List is Empty!");
            return;
        }

        TablePrinter table = new TablePrinter();

        if (printIndex)
            table.addColumn("Idx", 3);
        table.addColumn("License Plate", 13);
        table.addColumn("Owner", 20);
        table.addColumn("Brand", 20);
        table.addColumn("Value", 9);
        table.addColumn("Registration Date", 17);
        table.addColumn("Registration Place", 18);
        table.addColumn("Type", 9);

        int index = 1;

        table.printHeader();
        for (Car car : map.values()) {
            List<Object> rowData = new ArrayList<>();
            if (printIndex)
                rowData.add(index++);
            rowData.add(car.getLicensePlate());
            rowData.add(car.getOwner());
            rowData.add(car.getBrand());
            rowData.add(Input.formatInt(car.getValue(), "#,##0"));
            rowData.add(Input.dateToStr(car.getRegistrationDate(), "dd-MM-yyyy"));
            rowData.add(car.getRegistrationPlace());
            rowData.add(car.getTypeString());

            table.printRow(rowData.toArray());
        }
        table.printFooter();

        System.out.println("");
    }

    public void printCar(Car car) {
    	TablePrinter table = new TablePrinter();
        table.addColumn("License Plate", 13);
        table.addColumn("Owner", 20);
        table.addColumn("Brand", 20);
        table.addColumn("Value", 9);
        table.addColumn("Registration Date", 17);
        table.addColumn("Registration Place", 18);
        table.addColumn("Type", 9);
        table.printHeader();
            table.printRow(
            car.getLicensePlate(),
            car.getOwner(),
            car.getBrand(),
            Input.formatInt(car.getValue(), "#,##0"),
            Input.dateToStr(car.getRegistrationDate(), "dd-MM-yyyy"),
            car.getRegistrationPlace(),
            car.getTypeString()
            );
        table.printFooter();
    }

    // Listing Cars default to printing the Table without Index.
    public void listCars() {
        listCars(false);
    }

}
