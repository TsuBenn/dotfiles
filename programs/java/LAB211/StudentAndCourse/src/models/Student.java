package models;

import java.io.Serializable;

public class Student implements Serializable {

    static public int idIterator = 0;

    String id;
    String name;
    String major;
    double gpa;
    boolean hasCourse;

    public Student(String id, String name, String major, double gpa) {
    	this.id = id;
        this.name = name;
        this.major = major;
        this.gpa = gpa;
    }

    public Student(String name, String major, double gpa) {
        id = String.format("STU%04d", idIterator++);
        this.name = name;
        this.major = major;
        this.gpa = gpa;
    }

	public String getId() {
		return id;
	}
	public void setId(String id) {
		this.id = id;
	}
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public String getMajor() {
		return major;
	}
	public void setMajor(String major) {
		this.major = major;
	}
	public double getGpa() {
		return gpa;
	}
	public void setGpa(float gpa) {
		this.gpa = gpa;
	}

	public static int getIdIterator() {
		return idIterator;
	}

	public static void setIdIterator(int idIterator) {
		Student.idIterator = idIterator;
	}

	public void setGpa(double gpa) {
		this.gpa = gpa;
	}

	public boolean isHasCourse() {
		return hasCourse;
	}

	public void setHasCourse(boolean hasCourse) {
		this.hasCourse = hasCourse;
	}

}
