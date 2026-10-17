package models;

import java.io.Serializable;
import java.util.Date;

public class Course implements Serializable {
    String id;
    Student student;
    String name;
    int weeks;
    Date startDate;

    public Course(String id, Student student, String name, int weeks, Date startDate) {
        this.id = id;
        this.student = student;
        this.name = name;
        this.weeks = weeks;
        this.startDate = startDate;
    }

	public String getId() {
		return id;
	}
	public void setId(String id) {
		this.id = id;
	}
	public Student getStudent() {
		return student;
	}
	public String getStudentId() {
		return student.getId();
	}
	public void setStudent(Student student) {
		this.student = student;
	}
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public int getWeeks() {
		return weeks;
	}
	public void setWeeks(int weeks) {
		this.weeks = weeks;
	}
	public Date getStartDate() {
		return startDate;
	}
	public void setStartDate(Date startDate) {
		this.startDate = startDate;
	}

}
