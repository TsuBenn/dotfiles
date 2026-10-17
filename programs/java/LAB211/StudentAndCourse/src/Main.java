import java.util.Date;

import services.CourseList;
import services.StudentList;
import tools.Input;

public class Main {
    public static void main(String[] args) {
        String studentFile = "Students.txt";
        String courseFile = "Courses.txt";

        StudentList studentList = new StudentList();
        studentList.loadFromTextFile(studentFile);
        CourseList courseList = new CourseList(studentList);
        courseList.loadFromTextFile(courseFile);

        boolean hasChanges = false;
        boolean quit = false;
        while (!quit) {
            System.out.println(
                    "-------------------------------------------------------------------\n" +
                    "                   STUDENTS AND COURSES MANAGEMENT                 \n" +
                    "-------------------------------------------------------------------"
            );

            int menuChoice = Input.intMenu(
                    "List all Students",
                    "Add a new Student",
                    "Search Student by ID",
                    "Update a Student by ID",
                    "List all Students by Major",
                    "Add a new course",
                    "List all courses by students (grouped)",
                    "Remove a Student by ID",
                    "Sort Student by GPA",
                    "Save data to file",
                    "Quit"
            );

            System.out.println("");

            switch (menuChoice) {
                case 0:
                    studentList.listItems();
                    break;
                case 1:
                    studentList.addItem();
                    hasChanges = true;
                    break;
                case 2:
                    studentList.printItem(studentList.searchItems().selectItem());
                    break;
                case 3:
                    studentList.updateItem();
                    hasChanges = true;
                    break;
                case 4:
                    studentList.searchItems().listItems();
                    break;
                case 5:
                    courseList.addItem();
                    hasChanges = true;
                    break;
                case 6:
                    courseList.listItems(courseList.getComparator(), false);
                    break;
                case 7:
                    studentList.deleteItem();
                    hasChanges = true;
                    break;
                case 8:
                    studentList.listItems(studentList.getComparator(), false);
                    break;
                case 9:
                    studentList.saveToTextFile(studentFile);
                    courseList.saveToTextFile(courseFile);
                    System.out.println();
                    System.out.println("Save successfully");
                    hasChanges = false;
                    break;
                default:
                    if (hasChanges && Input.getBool("Save Changes?")) {
                        System.out.println("");
                        studentList.saveToTextFile(studentFile);
                        courseList.saveToTextFile(courseFile);
                    }
                    quit = true;
                    break;
            }

            System.out.println("");
        }

    }
}
