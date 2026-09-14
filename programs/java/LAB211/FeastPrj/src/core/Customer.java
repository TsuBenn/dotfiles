package core;

import java.io.Serializable;
import java.util.Objects;

public class Customer implements Serializable {

  static public String CODE_PAT = "^[cCgGkK][\\d]{4}$";
  static public String CODE_PREFIX_PAT = "^[cCgGkK]$";
  static public String NAME_PAT = "^[\\w\\s]{2,25}$";
  static public String PHONE_PAT = "^0[235789][\\d]{8}$";
  static public String EMAIL_PAT = "^[\\w\\.-_+]*[\\w\\.-_]\\@([\\w]+\\.)+[\\w]+[\\w]$";

  static public int idIterator = 0;

  public String code;
  public int code_num;
  public String code_prefix;
  public String name;
  public String phone;
  public String email;

  public Customer(String prefix, String name, String phone, String email) {
    this.code = prefix.toUpperCase() + String.format("%04d", idIterator);
    this.code_num = idIterator;
    this.code_prefix = prefix;
    this.name = name;
    this.phone = phone;
    this.email = email;

    idIterator++;
  }

  public Customer(String code) {
    this.code = code;
  }

  @Override
  public String toString() {
    return String.format("%-8s| %-24s| %-11s| %-18s", code, name, phone, email);
  }

  public int hashCode() {
    int hash = 5;
    hash = 97 * hash + Objects.hashCode(this.code);
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
    final Customer other = (Customer) obj;
    return Objects.equals(this.code, other.code);
  }

  public String getCode() {
    return code;
  }

  public void setCode(String code) {
    code = code.trim();
    if (code.matches(CODE_PAT))
      this.code = code;
  }

  public String getName() {
    return name;
  }

  public void setName(String name) {
    name = name.trim();
    if (name.matches(NAME_PAT))
      this.name = name;
  }

  public String getPhone() {
    return phone;
  }

  public void setPhone(String phone) {
    phone = phone.trim();
    if (phone.matches(PHONE_PAT))
      this.phone = phone;
  }

  public String getEmail() {
    return email;
  }

  public void setEmail(String email) {
    email = email.trim();
    if (email.matches(EMAIL_PAT))
      this.email = email;
  }

}
