package services;

import models.Car;
import models.Insurance;
import models.Insurance.InsurancePeriod;
import tools.Input;
import tools.TablePrinter;
import java.util.Arrays;
import java.util.Comparator;
import java.util.Date;

import tools.GenericList;

public class InsuranceList extends GenericList<Integer, Insurance> {

    CarList carList;

    public int yearToDisplay = 0;
    public String sortedByString = "";
    public String sortTypeString = "";

    // Constructor needs to take a CarList
    public InsuranceList(CarList carList) {
        this.carList = carList;
    }

    // Update Insurance Iterator by iterating through the Insurance List and check for the highest ID and set the new ID Iterator above it 1 unit.
    public void updateIDIterator() {
        for (Insurance insurance : getList()) {
            if (Insurance.idIterator <= insurance.getInsuranceId()) {
                Insurance.idIterator = insurance.getInsuranceId() + 1;
            }
        }
    }

    // Update ID Iterator after Loading File
    @Override
    public void postLoadFromFile() {
        updateIDIterator();
    }

    // Get User Input for year to Display the Insurances
    // Input: None.
    // Output: None.
    public void setYearDisplay() {
        Date now = new Date();
        yearToDisplay = Input.getInt("Enter Year for Listing", Input.dateGetPart(now, 1));
        System.out.println("");
    }

    // Get key from an Insurance Statement, which is the Insurance's ID
    // Input: the Insurance.
    // Output: The ID.
    @Override
    protected Integer getKey(Insurance insurance) {
        return insurance.getInsuranceId();
    }

    // Set key of an Insurance Statement, which is the Insurance's ID
    // Input: The Insurance and the new ID.
    // Output: None.
    @Override
    protected void setKey(Insurance insurance, Integer newId) {
        insurance.setInsuranceId(newId);
    }

    // Customize search prompt
    // Input: None.
    // Output: String Prompt.
    @Override
    protected String getSearchPrompt() {
        return "Search Insurance by ID, Owner or License Plate";
    }

    // Creating an Insurance Statement from User Input
    // Input: An Insurance as a default value, can be NULL.
    // Output: An Insurance created by the User Input.
    //
    // Declare fields.
    // Let the User Input the fields without any default, since Insurance Statements are not Updatable.
    // First let the User choose a car.
    // Check whether Car is null
    // Else check if that car already has been insured
    // Next ask for establishedDate, and it shall not be before the Car's registrationDate
    // Next ask for the Periods option.
    // Create an Insurance from the Inputs and return it.
    @Override
    protected Insurance createItem(Insurance insurance) {

        if (carList.isEmpty()) {
            System.out.println("There is no Car to be insured!");
            return null;
        }

        System.out.println("Select Car to be Insured:");
        Car insuredCar = carList.searchItems().selectItem();

        if (insuredCar == null) {
            return null;
        }

        carList.printItem(insuredCar);
        System.out.println("");

        if (insuredCar.isHasInsurance()) {
            System.out.println("This Car has already been insured!");
            return null;
        }

        Date establishedDate;
        while (true) {
            establishedDate = Input.getDate("Enter Established Date", "MM-dd-yyyy", new Date());
            if (Input.compareDate(establishedDate, insuredCar.getRegistrationDate()) < 0) {
                System.out.println("Establishing Date cannot be before the Car's registration Date!\n");
            } else {
                break;
            }
        }

        insuredCar.setHasInsurance(true);

        System.out.println("Select Insurance Period:");
        int selectedPeriod = Input.intMenu(Arrays.asList("12-Months", "24-Months", "36-Months"), 0);
        InsurancePeriod period = InsurancePeriod.values()[selectedPeriod];

        System.out.println("");
        return new Insurance(establishedDate, insuredCar, period);
    }

    // Match Insurance to Query, used for searching
    // Input: Insurance Statement and a Query
    // Output: Boolean
    @Override
    protected boolean matchItem(Insurance insurance, String query) {
        String licensePlate = Input.flattenString(insurance.getLicensePlate());
        String owner = Input.flattenString(insurance.getOwner());
        return licensePlate.contains(query) || owner.contains(query);
    }

    // The object of the InsuranceList is a "Insurance Statement"
    // Input: None
    // Output: String
    @Override
    public String getType() {
        return "Insurance Statement";
    }

    // Create an Instance of oneself
    // Input: None
    // Output: A new instance of this List
    @Override
    protected GenericList<Integer, Insurance> createInstance() {
        return new InsuranceList(carList);
    }

    // Creating a TablePrinter
    // Input: None
    // Output: A TablePrinter
    @Override
    protected TablePrinter getTable() {
        TablePrinter table = new TablePrinter("No Insurance Statement Available!");
        table.addColumn("Insurance Id", 12);
        table.addColumn("Established Date", 16);
        table.addColumn("License Plate", 13);
        table.addColumn("Customer", 20);
        table.addColumn("Insurance Period", 16);
        table.addColumn("Insurance Fee", 13);
        return table;
    }

    // Print Report by getting Comparator first
    // Then print out the header
    // Then List Items and Filter out the Insurance Year
    public void printReport() {
        if (isEmpty()) {
            System.out.printf("Insurance List is Empty!\n\n");
            return;
        }

        setYearDisplay();
        Comparator<Insurance> comparator = getComparator();
        System.out.println("\nReport: INSURANCE STATEMENTS");
        System.out.printf("From: 01/01/%d To: 12/31/%d\n\n\n", yearToDisplay, yearToDisplay);
        System.out.printf("Sorted by: %s\n", sortedByString);
        System.out.printf("Sort Type: %s\n\n", sortTypeString);
        listItems(
                comparator,
                false,
                ins -> Input.dateGetPart(ins.getEstablisedDate(), 1) == yearToDisplay);
    }

    // Getting a Table Row Values
    // Input: None
    // Output: A TablePrinter
    @Override
    protected Object[] getTableRow(Insurance insurance) {
        return new Object[] {
                String.format("%04d", insurance.getInsuranceId()),
                Input.dateToStr(insurance.getEstablisedDate(), "MM/dd/yyyy"),
                insurance.getLicensePlate(),
                insurance.getOwner(),
                insurance.getPeriodString(),
                Input.formatFloat(insurance.getFee(), "$ #,##0.0")
        };
    }

    // Getting a comparator from User to use for Listing Sorted Items
    // Input: None
    // Output: Comparator
    //
    // Ask field to be sorted
    // Includes:
    //     Insurance ID
    //     Established Date
    //     License Plate
    //     Insurance Period
    //
    // Ask for sort order
    // Remeber to set the sortedByString and sortTypeString so the Header prints correctly
    @Override
    public Comparator<Insurance> getComparator() {
        System.out.println("Select field for Sorting:");
        int choice = Input.intMenu(
                Arrays.asList(
                        "Insurance ID",
                        "Established Date",
                        "License Plate",
                        "Insurance Period"),
                0);
        System.out.println("\nSelect Sorting Type:");
        int direction = Input.intMenu(
                Arrays.asList(
                        "ASC",
                        "DESC"
                    ),
                0);
        System.out.println("");
        Comparator<Insurance> comparator;
        switch (choice) {
            case 1:
                comparator = Comparator.comparing(Insurance::getEstablisedDate);
                sortedByString = "Establised Date";
                break;
            case 2:
                comparator = Comparator.comparing(Insurance::getLicensePlate);
                sortedByString = "License Plate";
                break;
            case 3:
                comparator = Comparator.comparing(Insurance::getPeriod);
                sortedByString = "Insurance Period";
                break;
            default:
                comparator = Comparator.comparing(Insurance::getInsuranceId);
                sortedByString = "Insurance ID";
                break;
        }
        switch (direction) {
            case 1:
                sortTypeString = "DESC";
                return comparator.reversed();
            default:
                sortTypeString = "ASC";
                return comparator;
        }
    }
}
