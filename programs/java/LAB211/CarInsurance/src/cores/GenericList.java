package cores;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public abstract class GenericList<K, T> {

    Map<K, T> map = new HashMap<>();

    // Creating an Item from User Input
    // Input: An Item as a default value, can be NULL.
    // Output: An Item created by the User Input.
    //
    // Declare fields.
    // Let the User Input the fields with the default value of the provided Item. If the provided Item is null, force the User to Input something.
    // Create an Item from the Inputs and return it.
    protected abstract K getKey(T item);

    protected abstract T createItem(T item);

    protected abstract String getType();

    public String getAType(boolean capitalized){
        String type = getType();
        if (type.substring(0, 1).matches("[aiueoAIUEO]")) {
            if (capitalized)
                return "An";
            else
                return "an";
        }
        if (capitalized)
            return "A";
        else
            return "a";
    }

    // Creating a new Item without default Item
    // Input: None..
    // Output: Item.
    //
    // Create an Item without a default Item.
    public T createItem() {
        return createItem(null);
    }

    // Adding an existing item
    // Input: An Item.
    // Output: None.
    //
    // Add Item to the Map directly with a Item.
    public void addItem(T item) {
        map.put(getKey(item), item);
    }

    // Adding an Item from User Input
    // Input: None.
    // Output: None.
    //
    // Create an Item from User Inputer.
    // Add to this Map using by creating an Item from User Input and print a success notice.
    public void addItem() {
        addItem(createItem());
        System.out.printf("%s %s has been added!\n\n", getAType(true), getType());
    }


    // Removing a Car
    // Input: None
    // Output: None
    //
    // Let the User choose a Car to be Deleted by Search Car and Select Car in that Searched Result.
    // If Car to be Deleted is NULL, print a warning and return with no changes.
    // Else remove the Car from Map by using the Car License as Key and print a success notice.
    public void deleteItem() {
        T itemToDelete = searchItem().selectItem();
        if (itemToDelete == null) {
            System.out.printf("No %s has been Deleted!\n\n", getType());
            return;
        }

        if (Input.getBool("Comfirm Delete?")) {
            System.out.println("");
            map.remove(carToDelete.getLicensePlate());
            System.out.println("A Car has been Deleted!\n");
        } else
            System.out.println("No Car has been Deleted! (Canceled)\n");
    }

}
