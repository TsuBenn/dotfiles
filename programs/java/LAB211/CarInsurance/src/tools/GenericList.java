package tools;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;

public abstract class GenericList<K, T> implements Serializable {

    Map<K, T> map = new HashMap<>();

    // Get key from an Item
    // Input: The Value.
    // Output: The Key.
    //
    // Example:
    //     return item.getID();
    protected abstract K getKey(T item);

    // Set key of an Item
    // Input: The Item and the new key.
    // Output: None.
    //
    // Example:
    //     item.setID(key);
    protected abstract void setKey(T item, K new_key);

    // Customize search prompt
    // Input: None.
    // Output: String Prompt.
    //
    // Prompt use to hint the User what to search for.
    // Example:
    //     return "Search by ID, Name or Occupation"
    protected abstract String getSearchPrompt();

    // Creating an Item from User Input
    // Input: An Item as a default value, can be NULL.
    // Output: An Item created by the User Input.
    //
    // Declare fields.
    // Let the User Input the fields with the default value of the provided Item. If the provided Item is null, force the User to Input something.
    // Create an Item from the Inputs and return it.
    // Example:
    //    String name = Input.getStr("Enter name: ", item != null ? item.getName() : null);
    //    int health = Input.getInt("Enter health: ", 0, 100, item != null ? item.getHealth() : null);
    //    return new Player(name, health);
    protected abstract T createItem(T item);

    // Match Item to query
    // Input: Item and a Query
    // Output: Boolean
    //
    // A helper function for comparing Item and query during searching.
    // Exmaple:
    //    return item.getName().contains(query) || item.getOccupation().contains(query)
    protected abstract boolean matchItem(T item, String query);

    // Create an Instance of oneself
    // Input: None
    // Output: A new instance of the List
    //
    // A helper function for instantiating the List which extends this abstract class.
    // Example:
    //     public class CarList extends GenericList<String, Car> {
    //     ...
    //         @Override
    //         protected GenericList<String, Car> createInstance() {
    //             return new CarList();
    //         }
    //     ...
    //     }
    protected abstract GenericList<K, T> createInstance();

    // Creating a TablePrinter
    // Input: None
    // Output: A TablePrinter
    //
    // A helper function for creating a table for printing.
    // Example:
    //     TablePrinter table = new TablePrinter();
    //     table.addColumn("License Plate", 13);
    //     table.addColumn("Owner", 20);
    //     table.addColumn("Brand", 20);
    //     table.addColumn("Value", 9);
    //     table.addColumn("Registration Date", 17);
    //     table.addColumn("Registration Place", 18);
    //     table.addColumn("Type", 9);
    //     return table;
    protected abstract TablePrinter getTable();

    // Getting a Table Row Values
    // Input: None
    // Output: A TablePrinter
    //
    // A helper function for creating row for table printing.
    // Example:
    //     return new Object[] {
    //         player.getId(),
    //         player.getName(),
    //         player.getHealth(),
    //         player.getDefense()
    //     }
    protected abstract Object[] getTableRow(T item);

    // Getting a comparator from User to use for Listing Sorted Items
    // Input: None
    // Output: Comparator
    //
    // A helper function for creating a Comparator used for sorting lists
    // Example:
    //     System.out.println("Select field for sorting:");
    //     int choice = Input.intMenu(
    //             Arrays.asList(
    //                     "Insurance ID",
    //                     "Established Date",
    //                     "License Plate",
    //                     "Insurance Period"),
    //             1);
    //     int direction = Input.intMenu(
    //             Arrays.asList(
    //                 "ASC",
    //                 "DESC"
    //             ),
    //             1
    //         );
    //     Comparator<Insurance> comparator;
    //     switch (choice) {
    //         case 2: comparator = Comparator.comparing(Insurance::getEstablisedDate); break;
    //         case 3: comparator = Comparator.comparing(Insurance::getLicensePlate); break;
    //         case 4: comparator = Comparator.comparing(Insurance::getPeriod); break;
    //         default: comparator = Comparator.comparing(Insurance::getInsuranceId); break;
    //     }
    //     switch (direction) {
    //         case 2: return comparator;
    //         default: return comparator.reversed();
    //     }
    public Comparator<T> getComparator() {
        return null;
    }

    // Get the Object "pronoun"
    // Input: None
    // Output: String
    //
    // A helper function for getting the "pronoun" of the Object to use in print statements.
    // For example, the object can be a "Car", "Employee", etc.
    public String getType() {
        return "Item";
    }

    // Check if an Item can be deleted
    // Input: None
    // Output: A TablePrinter
    //
    // A helper function for checking Item removability.
    // Example:
    //     return person.inDebt;
    public boolean canDelete(T item) {
        return true;
    }

    // Get removal error
    // Input: None
    // Output: A TablePrinter
    //
    // A helper function for fetching the reason why you can't delete this Item.
    // Example:
    //     if (person.inDebt) {
    //         return "This Person is in debt and needs to pay it first!";
    //     } else {
    //         return "";
    //     }
    public String getDeleteError(T item) {
        return "";
    }

    // Check if an Item can be updated
    // Input: None
    // Output: A TablePrinter
    //
    // A helper function for checking Item updatability.
    // Example:
    //     return person.role == Person.Role.Admin;
    public boolean canUpdate(T item) {
        return true;
    }

    // Get update error
    // Input: None
    // Output: A TablePrinter
    //
    // A helper function for fetching the reason why you can't update this Item.
    // Example:
    //     if (person.role == Person.Role.Admin) {
    //         return "Thou shall not Update an Admin!";
    //     } else {
    //         return "";
    //     }
    public String getUpdateError(T item) {
        return "";
    }

    // Decie whether the Object is "An" Object or "A" Something
    // Input: An option to capitalize incase it's at the start of a sentence.
    // Output: String
    //
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
    public T addItem(T item) {
        if (!containsKey(getKey(item))) {
            map.put(getKey(item), item);
            return item;
        } else {
            System.out.printf("Key has already existed. No %s has been added!\n\n", getType());
        }
        return null;
    }

    // Adding an Item from User Input
    // Input: None.
    // Output: None.
    //
    // Create an Item from User Inputer.
    // Add to this Map using by creating an Item from User Input and print a success notice.
    public T addItem() {
        T new_item = createItem();
        if (new_item == null) {
            System.out.printf("\nNo %s has been added!\n\n", getType());
            return null;
        }
        addItem(new_item);
        printItem(new_item);
        System.out.printf("\n%s %s has been added!\n\n", getAType(true), getType());
        return new_item;
    }

    // Print a Car as a One Row Table
    // Input: None.
    // Output: None.
    public void printItem(T item) {
        if (item == null) {
            return;
        }
    	TablePrinter table = getTable();
        table.printHeader();
        table.printRow(getTableRow(item));
        table.printFooter();
    }

    // Listing Items
    // Input: Comparator (For Sorting) and printIndex (option to print the Index of each Rows, used for searching items) and a Function Object as a Filter for which item should be and should not be listed.
    // Output: None, just printing a Table
    //
    // Create a Table using getTable helper function to get the headers for the right Data Model.
    // Turn the Map into a List using getList and if the Comparator is NOT NULL then use it to sort the List.
    // Print Header
    // Loop through each items in List:
    //     Check whether Filter is NULL, if not then apply the Filter and decided whether to print that Row or not.
    //     PrintRow using the helper function getTableRow for the Columns Values.
    // Print Footer
    public void listItems(Comparator<T> comparator, boolean printIndex, Function<T, Boolean> filter) {
        TablePrinter table = getTable();

        if (printIndex) {
            table.addIndexColumn("Idx");
        }

        List<T> list = getList();
        if (comparator != null) {
            list.sort(comparator);
        }

        table.printHeader();
        for (T item : list) {
            if (filter != null) {
                if (filter.apply(item)) {
                    table.printRow(getTableRow(item));
                }
            } else {
                table.printRow(getTableRow(item));
            }
        }
        table.printFooter();

        System.out.println("");
    }

    public void listItems(Comparator<T> comparator, boolean printIndex) {
        listItems(comparator, printIndex, null);
    }

    // Listing Items without Comparator means no sorting needed
    public void listItems(boolean printIndex) {
        listItems(null, printIndex);
    }

    // Listing Items default to printing the Table without Index and Sorting.
    public void listItems() {
        listItems(false);
    }

    // Listing Items
    // Input: None
    // Output: List of items
    //
    // Return the GenericList as a List instead of a Map.
    public List<T> getList() {
        // if (map.isEmpty()) {
        //     System.out.printf("%s List is Empty!\n", getType());
        //     return new ArrayList<>();
        // }
        return new ArrayList<>(map.values());
    }

    public List<T> getSortedList(Comparator<T> comparator) {
        List<T> list = (ArrayList<T>) getList();
        list.sort(comparator);
        return list;
    }

    // Searching Items
    // Input: Search Query.
    // Output: A GenericList contains matching Items.
    //
    // Create an Empty GenericList acting as the Search Result.
    // Check if the query is directly searching for License Plate by checking whether the Map has similar Key or not.
    // If not convert GenericList into a List, flatten the query and iterate through each car:
    //    Check car against query using Match Item function.
    //    If match then add that Item to the Search Result List.
    // Return the Search Result List.
    public GenericList<K, T> searchItems(String query) {

        GenericList<K, T> searchedItem = createInstance();

        if (map.containsKey(query)) {
            searchedItem.addItem(map.get(query));
            return searchedItem;
        }

        List<T> items = getList();

        query = Input.flattenString(query);

        for (T item : items) {
            if (matchItem(item, query)) {
                searchedItem.addItem(item);
            }
        }

        if (searchedItem.map.isEmpty()) {
            System.out.printf("No %s is found!\n", getType());
        }

        return searchedItem;
    }

    // Asking the User for query then call searchCar with the inputted query.
    public GenericList<K, T> searchItems() {
        if (map.isEmpty()) {
            return createInstance();
        }
        String query = Input.getStr(getSearchPrompt(), "");
        System.out.println("");
        return searchItems(query);
    }


    // Select an Item
    // Input: None
    // Output: Item
    //
    // Convert GenericList into a List.
    // Print out the Item Table with the Index Column.
    // If the List only has 1 item then return that item
    // Else ask the user for their selection on the List via the Index from 1 -> List size.
    // Return the Item that the user selected from the list.
    public T selectItem() {
        if (map.isEmpty()) {
            System.out.printf("%s List is Empty!\n\n", getType());
            return null;
        }
        List<T> list = getList();

        if (map.size() == 1) {
            return list.get(0);
        }

        listItems(true);

        int choice = Input.getInt("Select index", 1, list.size(), 1);

        System.out.println("");
        return list.get(choice - 1);
    }

    // Removing an Item
    // Input: None
    // Output: None
    //
    // Let the User choose an Item to be Deleted by Search Item and Select Item in that Searched Result.
    // If the Item to be Deleted is NULL, print a warning and return with no changes.
    // Else remove the Item from the Map by using the Item's Key and print a success notice.
    public void deleteItem() {
        T itemToDelete = searchItems().selectItem();
        if (itemToDelete == null) {
            System.out.printf("No %s has been Deleted!\n\n", getType());
            return;
        }
        if (!canDelete(itemToDelete)) {
            System.out.println(getDeleteError(itemToDelete));
            return;
        }

        if (Input.getBool("Comfirm Delete?")) {
            System.out.println("");
            map.remove(getKey(itemToDelete));
            System.out.printf("%s %s has been Deleted!\n\n", getAType(true), getType());
        } else
            System.out.printf("No %s has been Deleted! (Canceled)\n\n", getType());
    }

    // Updating a Item
    // Input: None
    // Output: None
    //
    // Let the User choose an Item to be Updated by Search Item and Select Item in that Searched Result.
    // If Item to be Updated is NULL, print a warning and return with no changes.
    // Else Create a new Item with the To be Updated Item as the default value.
    // after that override the To Be Updated Item in the map with the Updated one using the To Be Updated Item License Plate as Key.
    public void updateItem() {
        T itemToUpdate = searchItems().selectItem();
        if (itemToUpdate == null) {
            System.out.printf("No %s has been Updated!\n\n", getType());
            return;
        }
        if (!canUpdate(itemToUpdate)) {
            System.out.println(getUpdateError(itemToUpdate));
            return;
        }

        T updatedItem = createItem(itemToUpdate);
        setKey(updatedItem, getKey(itemToUpdate));

        System.out.println("OLD:");
        printItem(itemToUpdate);
        System.out.println("NEW:");
        printItem(updatedItem);

        if (Input.getBool("Comfirm Update?")) {
            System.out.println("");
            map.put(getKey(itemToUpdate), updatedItem);
            System.out.printf("%s %s has been Updated!\n\n", getAType(true), getType());
        } else {
            System.out.println("");
            System.out.printf("No %s has been Updateds! (Canceled)\n\n", getType());
        }
    }

    // Save collection state to a binary file
    // Input: File path string where the .dat file should be written.
    // Output: Boolean indicating success (true) or failure (false).
    //
    // Open an ObjectOutputStream wrapped in a FileOutputStream via try-with-resources.
    // Serialize the entire map object directly into the specified file path.
    // Run postSaveFromFile() In case any class extending this Class can do extra stuff after.
    // Catch IOException, notify the user with a friendly error notice, and return false.
    // Note: FileOutputStream automatically creates the file if it does not exist yet.
    //
    // Example:
    //     carList.saveToFile("cars.dat");
    //     insuranceList.saveToFile("data/insurances.dat");
    public boolean saveToFile(String filePath) {

        try (ObjectOutputStream oos = new ObjectOutputStream(new FileOutputStream(filePath))) {
            oos.writeObject(this.map);
            System.out.printf("%s data saved successfully to %s!\n\n", getType(), filePath);
            postSaveFromFile();
            return true;
        } catch (IOException e) {
            System.out.printf("Error saving %s data: %s\n\n", getType(), e.getMessage());
            return false;
        }
    }

    // Load collection state from a binary file
    // Input: File path string pointing to the target .dat file.
    // Output: Boolean indicating success (true) or failure/file missing (false).
    //
    // Check if the target file exists before attempting to open streams to avoid unneeded stack traces.
    // Open an ObjectInputStream wrapped in a FileInputStream via try-with-resources.
    // Read the serialized Map object, safely cast it to Map<K, T>, and assign it back to this instance's map.
    // Run postLoadFromFile() In case any class extending this Class can do extra stuff after.
    // Catch IOException or ClassNotFoundException, notify the user with a friendly error notice, and return false.
    //
    // Example:
    //     carList.loadFromFile("cars.dat");
    //     insuranceList.loadFromFile("data/insurances.dat");
    public boolean loadFromFile(String filePath) {
        File file = new File(filePath);

        if (!file.exists()) {
            System.out.printf("No existing %s data file found (%s). Starting with an empty list.\n\n", getType(), filePath);
            return false;
        }

        try (ObjectInputStream ois = new ObjectInputStream(new FileInputStream(file))) {
            this.map = (Map<K, T>) ois.readObject();
            System.out.printf("%s data loaded successfully from %s!\n\n", getType(), filePath);
            postLoadFromFile();
            return true;
        } catch (IOException | ClassNotFoundException e) {
            System.out.printf("Error loading %s data: %s\n\n", getType(), e.getMessage());
            return false;
        }
    }

    // Runs after SUCCESSFULL Save
    public void postSaveFromFile() {}

    // Runs after SUCCESSFULL Load
    public void postLoadFromFile() {}

    public boolean isEmpty() {
        return map.isEmpty();
    }

    public boolean containsKey(K key) {
        return map.containsKey(key);
    }

}
