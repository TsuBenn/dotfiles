package model;

import java.util.Scanner;

public class BA extends Staff {
    private String domain;

    public BA() {
        super();
        domain = "";
    }

	public BA(String id, String name, String email, String password, double baseSalary, String domain) {
		super(id, name, email, password, baseSalary);
		this.domain = domain;
	}

	public String getDomain() {
		return domain;
	}

	public void setDomain(String domain) {
		this.domain = domain;
	}

    public void inputBA() {
        inputStaff();
        Scanner sc = new Scanner(System.in);
        System.out.println("\u001B[A" + "Enter staff's domain:");
        domain = sc.nextLine();
        System.out.println("");
    }

    public void outputBA() {
        outputStaff();
        System.out.println("\u001B[A" + "Domain: " + domain);
        System.out.println("");
    }

}
