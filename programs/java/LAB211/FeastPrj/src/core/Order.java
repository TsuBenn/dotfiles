package core;

import java.util.Date;
import java.util.Objects;

public class Order {

  static private int idIterator = 0;

  public int orderCode;
  public String custCode;
  public String setMenuCode;
  public int numTable;
  public Date preferedDate;

  public Order(String custCode, String setMenuCode, int numTable, Date preferedDate) {
    this.orderCode = idIterator++;
    this.custCode = custCode;
    this.setMenuCode = setMenuCode;
    this.numTable = numTable;
    this.preferedDate = preferedDate;
  }

  public Order(int orderCode) {
    this.orderCode = orderCode;
  }

  @Override
  public int hashCode() {
    int hash = 5;
    hash = 97 * hash + Objects.hashCode(this.orderCode);
    return hash;
  }

  @Override
  public boolean equals(Object obj) {
    if (this == obj) {
      return true;
    }
    if (obj == null) {
      return false;
    }
    if (getClass() != obj.getClass()) {
      return false;
    }
    final Order other = (Order) obj;
    return Objects.equals(this.custCode, other.custCode);
  }

  public int getOrderCode() {
    return orderCode;
  }

  public void setOrderCode(int orderCode) {
    this.orderCode = orderCode;
  }

  public String getCustCode() {
    return custCode;
  }

  public void setCustCode(String custCode) {
    this.custCode = custCode;
  }

  public String getSetMenuCode() {
    return setMenuCode;
  }

  public void setSetMenuCode(String setMenuCode) {
    this.setMenuCode = setMenuCode;
  }

  public int getNumTable() {
    return numTable;
  }

  public void setNumTable(int numTable) {
    this.numTable = numTable;
  }

  public Date getPreferedDate() {
    return preferedDate;
  }

  public void setPreferedDate(Date preferedDate) {
    this.preferedDate = preferedDate;
  }

  public static int getIdIterator() {
	return idIterator;
  }

  public static void setIdIterator(int idIterator) {
	Order.idIterator = idIterator;
  }


}
