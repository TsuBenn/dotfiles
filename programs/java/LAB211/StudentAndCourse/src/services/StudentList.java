package services;

import java.util.Arrays;
import java.util.Comparator;

import models.Student;
import tools.GenericList;
import tools.Input;
import tools.TablePrinter;

public class StudentList extends GenericList<String, Student> {

    @ Override
    protected String getKey(Student item) {
        return item.getId();
    }

    @ Override
    protected void setKey(Student item, String new_key) {
        item.setId(new_key);
    }

    @Override
    public void postLoadFromFile() {
        for (Student item : getList()) {
            int id = Integer.parseInt(item.getId().substring(3));
            if (Student.idIterator <= id) {
                Student.idIterator = id + 1;
            }
        }
    }

    @Override
    protected String getSearchPrompt() {
        return "Search Student by ID, Name or Major";
    }

    @Override
    protected Student createItem(Student item) {
        String name = Input.getStr("Enter Student's name", item != null ? item.getName() : null);
        String major = Input.getStr("Enter Student's major", item != null ? item.getMajor() : null);
        double gpa = Input.getFloat("Enter Student's GPA", 0.0, 4.0, item != null ? item.getGpa() : null);

        return new Student(name, major, gpa);
    }

    @Override
    protected boolean matchItem(Student item, String query) {
        if (query.isEmpty()) return true;
        query = Input.flattenString(query.toLowerCase());
        String id = Input.flattenString(item.getId().toLowerCase());
        String name = Input.flattenString(item.getName().toLowerCase());
        String major = Input.flattenString(item.getMajor().toLowerCase());
        return id.contains(query) || name.contains(query) || major.contains(query);
    }

    @Override
    protected GenericList<String, Student> createInstance() {
        return new StudentList();
    }

    @Override
    protected TablePrinter getTable() {
        TablePrinter table = new TablePrinter();
        table.addColumn("Student ID", 10);
        table.addColumn("Name", 20);
        table.addColumn("Major", 30);
        table.addColumn("GPA", 3);
        return table;
    }

    @Override
    protected Object[] getTableRow(Student item) {
        return new Object[] {
            item.getId(),
            item.getName(),
            item.getMajor(),
            item.getGpa()
        };
    }

    @Override
    public String getType() {
        return "Student";
    }

    // Check if an Item can be deleted
    // Input: None
    // Output: A TablePrinter
    //
    // A helper function for checking Item removability.
    // Example:
    //     return person.inDebt;
    @Override
    public boolean canDelete(Student item) {
        return !item.isHasCourse();
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
    public String getDeleteError(Student item) {
        if (item.isHasCourse()) {
            return "Cannot Delete: Student is assigned to Courses!";
        }
        return "";
    }

    @Override
    public String textSerialize(Student item) {
        return String.join(", ", Arrays.asList(item.getId(), item.getName(), item.getMajor(), Double.toString(item.getGpa())));
    }

    @Override
    public Student textDeserialize(String itemString) {
        String parts[] = itemString.split(",");
        String id = parts[0].trim();
        String name = parts[1].trim();
        String major = parts[2].trim();
        double gpa = Double.parseDouble(parts[3].trim());

        return new Student(id, name, major, gpa);
    }

    @Override
    public Comparator<Student> getComparator() {
        return Comparator.comparing(Student::getGpa).reversed();
    }
}
