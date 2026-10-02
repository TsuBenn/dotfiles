import java.util.Date;

import models.Car;
import models.Insurance;
import models.Car.CarType;
import models.Insurance.InsurancePeriod;
import services.CarList;
import services.InsuranceList;
import tools.Input;

public class Main {

    public static void main(String[] args) {
        final String CAR_LIST_PATH = "carInfo.dat";
        final String INSURANCE_LIST_PATH = "insurances.dat";

        CarList carList = new CarList();
        InsuranceList insuranceList = new InsuranceList(carList);

        boolean empty = true;
        boolean hasChanges = false;
        boolean quit = false;
        while (!quit) {

                System.out.println(
                        "+---------------------------------------------------------+\n" +
                        "|                 CAR INSURANCE MANAGEMENT                |\n" +
                        "+---------------------------------------------------------+"
                );

                int menuChoice = Input.intMenu(
                        "Add Car Information",
                        "Find a Car",
                        "Update a Car",
                        "Delete a Car",
                        "Add an Insurance Statement",
                        "List of Insurance Statements",
                        "Report on Uninsured Cars",
                        "Save data",
                        "Load data",
                        "Inject Mock Data",
                        "Quit"
                );

                System.out.println("");

                switch (menuChoice) {
                        case 0:
                                carList.addItem();
                                empty = false;
                                hasChanges = true;
                                break;
                        case 1:
                                Car selectedCar = carList.searchItems().selectItem();
                                carList.printItem(selectedCar);
                                break;
                        case 2:
                                carList.updateItem();
                                empty = false;
                                hasChanges = true;
                                break;
                        case 3:
                                carList.deleteItem();
                                empty = false;
                                hasChanges = true;
                                break;
                        case 4:
                                insuranceList.addItem();
                                empty = false;
                                hasChanges = true;
                                break;
                        case 5:
                                insuranceList.printReport();
                                break;
                        case 6:
                                carList.printReport();
                                break;
                        case 7:
                                if (empty && !Input.getBool("The Program is currently Empty, are you sure you wanna Overide Previous Data?")) {
                                        break;
                                }
                                carList.saveToFile(CAR_LIST_PATH);
                                insuranceList.saveToFile(INSURANCE_LIST_PATH);
                                hasChanges = false;
                                break;
                        case 8:
                                carList.loadFromFile(CAR_LIST_PATH);
                                insuranceList.loadFromFile(INSURANCE_LIST_PATH);
                                empty = false;
                                break;
                        case 9:
                                injectExampleData(carList, insuranceList);
                                empty = false;
                                hasChanges = true;
                                break;
                        default:
                                if (hasChanges && Input.getBool("Save Changes?")) {
                                        System.out.println("");
                                        carList.saveToFile(CAR_LIST_PATH);
                                        insuranceList.saveToFile(INSURANCE_LIST_PATH);
                                }
                                quit = true;
                                break;
                }

                System.out.println("");
        }
    }

    // Inject preset mock records into carList and insuranceList for fast testing
    private static void injectExampleData(CarList carList, InsuranceList insuranceList) {
        Date now = new Date();

        // 1. Create sample cars
        Car car1 = new Car("Minecraft", "Nguyen Ngoc Dang Khang", "Lamborghini", 35000, now, "Saigon", CarType.FIVE_SEATERS);
        Car car2 = new Car("Terraria", "Nguyen Van Binh", "Ferrari", 48000, now, "Ha Noi", CarType.SEVEN_SEATERS);
        Car car3 = new Car("ZZZero", "Pham Nguyen Anh Benn", "BMW", 52000, now, "Da Nang", CarType.NINE_SEATERS);
        Car car4 = new Car("CS2", "Pham Nguyen Anh Duy", "Honda", 28000, now, "Dong Nai", CarType.FIVE_SEATERS);
        Car car5 = new Car("Genshin", "Pham Nguyen Anh Huy", "Honda", 120000, now, "New York", CarType.FIVE_SEATERS);

        // 2. Add cars to carList using GenericList's addItem(T item)
        carList.addItem(car1);
        carList.addItem(car2);
        carList.addItem(car3);
        carList.addItem(car4);
        carList.addItem(car5);

        System.out.println("Mock data injected successfully!\n");
    }
}
