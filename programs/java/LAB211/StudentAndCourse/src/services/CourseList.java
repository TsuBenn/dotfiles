package services;

import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Comparator;
import java.util.Date;

import models.Course;
import models.Student;
import tools.GenericList;
import tools.Input;
import tools.TablePrinter;

public class CourseList extends GenericList<String, Course> {

    StudentList studentList;

    public CourseList(StudentList studentList) {
        this.studentList = studentList;
    }

    @Override
    public void postLoadFromFile() {
        for (Course course : getList()) {
            Student student = course.getStudent();
            if (student != null) {
                student.setHasCourse(true);
            } else {
                map.remove(getKey(course));
            }

        }
    }

    @ Override
    protected String getKey(Course item) {
        return item.getId();
    }

    @ Override
    protected void setKey(Course item, String new_key) {
        item.setId(new_key);
    }

    @Override
    protected String getSearchPrompt() {
        return "";
    }

    @Override
    protected Course createItem(Course item) {

        String id = Input.getStr("Enter Course's id", item != null ? item.getId() : null);
        Student student = studentList.searchItems().selectItem();
        student.setHasCourse(true);
        String name = Input.getStr("Enter Course's name", item != null ? item.getName() : null);
        int weeks = Input.getInt("Enter Course's week duration", 1, null, item != null ? item.getWeeks() : null);
        Date startDate;
        while (true) {
            Date today = new Date();
            Calendar calendar = Calendar.getInstance();
            calendar.setTime(today);
            calendar.add(Calendar.DAY_OF_MONTH, 1);
            Date tomorrow = calendar.getTime();
            startDate = Input.getDate("Enter Course's starting date", "dd/MM/yyyy", tomorrow);
            if (Input.compareDate(startDate, today) <= 0) {
                System.out.println("Starting date should be a future date!");
            } else {
                break;
            }
        }

        return new Course(id, student, name, weeks, startDate);

    }


    @Override
    protected boolean matchItem(Course item, String query) {
        return true;
    }

    @Override
    protected GenericList<String, Course> createInstance() {
        return new CourseList(studentList);
    }

    @Override
    protected TablePrinter getTable() {
        TablePrinter table = new TablePrinter();
        studentId_temp = "";
        table.addColumn("Student ID", 10);
        table.addColumn("Name", 20);
        table.addColumn("Major", 30);
        table.addColumn("GPA", 3);
        table.addColumn("Course ID", 12);
        table.addColumn("Course name", 20);
        table.addColumn("Duration", 8);
        table.addColumn("Start Date", 10);
        return table;
    }

    String studentId_temp = "";

    @Override
    protected Object[] getTableRow(Course item) {
        boolean please = studentId_temp.equals(item.getStudentId());
        if (!please) {
            studentId_temp = item.getStudentId();
        }
        return new Object[] {
            please ? "" : item.getStudent().getId(),
            please ? "" : item.getStudent().getName(),
            please ? "" : item.getStudent().getMajor(),
            Input.formatFloat(item.getStudent().getGpa(), "#,##0.0"),
            item.getId(),
            item.getName(),
            Input.formatFloat(item.getWeeks(), "#,##0"),
            Input.dateToStr(item.getStartDate(),"dd/MM/yyyy")
        };
    }

    @Override
    public String textSerialize(Course item) {
        return String.join(", ", Arrays.asList(item.getId(), item.getStudentId(), item.getName(), Integer.toString(item.getWeeks()), Input.dateToStr(item.getStartDate(), "dd/MM/yyyy")));
    }

    @Override
    public Course textDeserialize(String itemString) {
        String parts[] = itemString.split(",");
        String id = parts[0].trim();
        Student student = studentList.map.get(parts[1].trim());
        String name = parts[2].trim();
        int weeks = Integer.parseInt(parts[3].trim());
        DateFormat formatter = new SimpleDateFormat("dd/MM/yyyy");
        Date startDate;
        try {
            startDate = formatter.parse(parts[4].trim());
        } catch (ParseException e) {
            System.err.println("Error loading Course data");
            return null;
        }
        return new Course(id, student, name, weeks, startDate);
    }

    @Override
    public String getType() {
        return "Course";
    }

    @Override
    public Comparator<Course> getComparator() {
        return Comparator.comparing(Course::getStudentId);
    }
}
