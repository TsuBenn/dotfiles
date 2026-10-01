import java.util.Date;

import models.Car;
import services.CarList;

public class Main {
    public static void main(String[] args) {
        CarList carList = new CarList();

        carList.addCar("John Doe", "Toyota Fortuner", 45000, new Date(), "California", Car.CarType.SEVEN_SEATERS);

        carList.addCar("John Smith", "Toyota Corola", 32000, new Date(), "Washington", Car.CarType.FIVE_SEATERS);

        carList.addCar("Alice Smith", "Honda Civic", 22000, new Date(), "New York", Car.CarType.FIVE_SEATERS);

        carList.addCar("Bob Transit Co.", "Ford Transit Custom", 38000, new Date(), "Texas", Car.CarType.NINE_SEATERS);

        carList.addCar("Elena Rostova", "Tesla Model 3", 41000, new Date(), "Washington", Car.CarType.FIVE_SEATERS);

        carList.addCar("Exotic Rental Group",  "Bugatti Chiron Super Sport",  3800000, new Date(),  "Monaco",  Car.CarType.FIVE_SEATERS );

        carList.listCars();

        // carList.addCar();

        carList.updateCar();

        carList.listCars();

    }
}
