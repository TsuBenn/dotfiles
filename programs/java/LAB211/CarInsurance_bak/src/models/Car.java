package models;

import java.io.Serializable;
import java.util.Date;

public class Car implements Serializable {

    // ENUMS for Car Type.
    static public enum CarType {
        FIVE_SEATERS,
        SEVEN_SEATERS,
        NINE_SEATERS
    }

    String licensePlate;      // UNIQUE, NOT NULL
    String owner;             // 2-35 CHARS, NOT NULL
    String brand;             // NOT NULL
    int value;                // > 999
    Date registrationDate;    // Valid Date, NOT NULL
    String registrationPlace; // Valid Place, NOT NULL
    CarType type;             // FIVE_SEATS, SEVEN_SEATS, NINE_SEATS
    boolean hasInsurance;     // TRUE OR FALSE

    static final public String OWNER_PAT =    "^[\\w\\s]{2,35}$"; // 2-35 CHARS PATTERN
    static final public String REG_DATE_PAT = "MM-dd-yyyy"; // 2-35 CHARS PATTERN

    // Car Constructor
    public Car(String licensePlate, String owner, String brand, int value, Date registrationDate, String registrationPlace, CarType type) {
        this.licensePlate = licensePlate;
        this.owner = owner;
        this.brand = brand;
        this.value = value;
        this.registrationDate = registrationDate;
        this.registrationPlace = registrationPlace;
        this.type = type;
        this.hasInsurance = false;
    }

    // Basic Getter & Setters
	public String getLicensePlate() {
		return licensePlate;
	}
	public void setLicensePlate(String licensePlate) {
		this.licensePlate = licensePlate;
	}

	public String getOwner() {
		return owner;
	}
	public void setOwner(String owner) {
		this.owner = owner;
	}

	public String getBrand() {
		return brand;
	}
	public void setBrand(String brand) {
		this.brand = brand;
	}

	public int getValue() {
		return value;
	}
	public void setValue(int value) {
		this.value = value;
	}

	public Date getRegistrationDate() {
		return registrationDate;
	}
	public void setRegistrationDate(Date registrationDate) {
		this.registrationDate = registrationDate;
	}

	public String getRegistrationPlace() {
		return registrationPlace;
	}
	public void setRegistrationPlace(String registrationPlace) {
		this.registrationPlace = registrationPlace;
	}

	public String getTypeString() {
	    switch (type) {
	        case FIVE_SEATERS: return "5 Seaters";
	        case SEVEN_SEATERS: return "7 Seaters";
	        case NINE_SEATERS: return "9 Seaters";
	        default: return "Unknown";
	    }
	}
	public CarType getType() {
		return type;
	}
	public void setType(CarType type) {
		this.type = type;
	}

	public boolean isHasInsurance() {
		return hasInsurance;
	}

	public void setHasInsurance(boolean hasInsurance) {
		this.hasInsurance = hasInsurance;
	}

}
