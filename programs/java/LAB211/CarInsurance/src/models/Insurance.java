package models;

import java.io.Serializable;
import java.util.Date;

public class Insurance implements Serializable {

	static public int idIterator = 0;

    static public enum InsurancePeriod {
        PERIOD_12,
        PERIOD_24,
        PERIOD_36,
    }

    int insuranceId;
    Date establisedDate;
    Car insuredCar;
    InsurancePeriod period;

    public Insurance(Date establishedDate, Car insuredCar, InsurancePeriod period) {
    	this.insuranceId = idIterator++;
    	this.establisedDate = establishedDate;
    	this.insuredCar = insuredCar;
    	this.period = period;
    }

    public double getFee() {
        switch (period) {
            case PERIOD_12: return 0.25*insuredCar.getValue();
            case PERIOD_24: return 0.2 *insuredCar.getValue()*2;
            case PERIOD_36: return 0.15*insuredCar.getValue()*3;
            default: return 0;
        }
    }

	public int getInsuranceId() {
		return insuranceId;
	}
	public void setInsuranceId(int insuranceId) {
		this.insuranceId = insuranceId;
	}
	public Date getEstablisedDate() {
		return establisedDate;
	}
	public void setEstablisedDate(Date establisedDate) {
		this.establisedDate = establisedDate;
	}

	public String getLicensePlate() {
		return insuredCar.getLicensePlate();
	}
	public String getOwner() {
		return insuredCar.getOwner();
	}

	public InsurancePeriod getPeriod() {
		return period;
	}
	public void setPeriod(InsurancePeriod period) {
		this.period = period;
	}

	public String getPeriodString() {
	    switch (period) {
	        case PERIOD_12: return "12";
	        case PERIOD_24: return "24";
	        case PERIOD_36: return "36";
	        default: return "Unknown";
	    }
	}

}
