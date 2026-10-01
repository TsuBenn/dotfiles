import java.util.Date;

import models.Car;
import services.CarList;

public class Main {
    public static void main(String[] args) {
        CarList carList = new CarList();

        // Standard SUV / Family car (7 seaters)
        carList.add(new Car("John Doe", "Toyota Fortuner", 45000, new Date(), "California", Car.CarType.SEVEN_SEATERS));

        // City Sedan (5 seaters)
        carList.add(new Car("Alice Smith", "Honda Civic", 22000, new Date(), "New York", Car.CarType.FIVE_SEATERS));

        // Passenger / Transport Van (9 seaters)
        carList.add(new Car("Bob Transit Co.", "Ford Transit Custom", 38000, new Date(), "Texas", Car.CarType.NINE_SEATERS));

        // Electric Vehicle (5 seaters)
        carList.add(new Car("Elena Rostova", "Tesla Model 3", 41000, new Date(), "Washington", Car.CarType.FIVE_SEATERS));

        carList.add(new Car("Exotic Rental Group",  "Bugatti Chiron Super Sport",  3800000, new Date(),  "Monaco",  Car.CarType.FIVE_SEATERS ));

        carList.listCars();
    }
}
