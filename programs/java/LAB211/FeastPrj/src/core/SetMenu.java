package core;

import java.io.Serializable;
import java.text.DecimalFormat;
import java.util.Objects;

public class SetMenu implements Serializable {
    String code;
    String name;
    int price;
    String ingredients;

    @Override
    public String toString() {
        return code + ", " + name + ", " + price;
    }

    public String toStringScreen() {
        DecimalFormat dfCustom;
        dfCustom = new DecimalFormat("#,##0");
        String S =  "Code        : " + code + "\n" +
                    "Name        : " + name + "\n" +
                    "Price       : " + dfCustom.format(price) + " VND\n" +
                    "Ingredients :" + "\n";
        String[] items = ingredients.split("#");
        for (String str : items) S += str + "\n";
        S += "-------------------------------------------------------";
        return S;
    }

    public int hashCoe() {
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

    public SetMenu(String code, String name, int price, String ingredients) {
        this.code = code;
        this.name = name;
        this.price = price;
        this.ingredients = ingredients;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getPrice() {
        return price;
    }

    public void setPrice(int price) {
        this.price = price;
    }

    public String getIngredients() {
        return ingredients;
    }

    public void setIngredients(String ingredients) {
        this.ingredients = ingredients;
    }

}
