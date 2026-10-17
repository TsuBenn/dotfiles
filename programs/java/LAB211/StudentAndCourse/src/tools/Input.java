package tools;

import java.text.DateFormat;
import java.text.DecimalFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.List;
import java.util.Scanner;

public class Input {

    private static Scanner sc = new Scanner(System.in);

    public static boolean getBool(String prompt, boolean defaultValue) {
        if (defaultValue) {
            System.out.print(prompt + " (Y/n): ");
        } else {
            System.out.print(prompt + " (y/N): ");
        }
        String data = sc.nextLine().trim().toUpperCase();
        if (data.isEmpty()) {
            return defaultValue;
        }
        char c = data.charAt(0);

        return c == 'Y' || c == 'T' || c == '1';
    }

    public static boolean getBool(String prompt) {
        return getBool(prompt, true);
    }

    public static int getInt(String prompt, Integer min, Integer max, Integer defaultValue) {
        int result = 0;

        boolean hasMin = true;
        boolean hasMax = true;

        if (min == null) {
            min = Integer.MIN_VALUE;
            hasMin = false;
        }
        if (max == null) {
            max = Integer.MAX_VALUE;
            hasMax = false;
        }

        String hint = "";
        String defaultHint = "";
        if (hasMin && !hasMax) {
            hint = " [" + min + " - " + "inf" + "]";
        } else if (!hasMin && hasMax) {
            hint = " [" + "inf" + " - " + max + "]";
        } else if (hasMin && hasMax) {
            hint = " [" + min + " - " + max + "]";
        }
        if (defaultValue != null) {
            defaultHint = String.format(" [%d]", defaultValue);
        }

        do {
            boolean valid = true;
            do {
                try {
                    System.out.print(prompt + hint + defaultHint + ": ");
                    String input = sc.nextLine().trim();
                    if (input.isEmpty()) {
                        if (defaultValue != null) {
                            return defaultValue;
                        } else {
                            valid = false;
                            System.out.println("Input is blank!");
                            continue;
                        }
                    }
                    result = Integer.parseInt(input);
                    valid = true;
                } catch (Exception e) {
                    valid = false;
                    System.out.println("Invalid Int!");
                }
            } while (!valid);
            if (result < min || result > max) {
                System.out.println("Out of range! " + hint);
            }
        } while (result < min || result > max);

        return result;
    }

    public static int getInt(String prompt, Integer min, Integer max) {
        return getInt(prompt, min, max, null);
    }

    public static int getInt(String prompt) {
        return getInt(prompt, null, null, null);
    }

    public static int getInt(String prompt, int defaultValue) {
        return getInt(prompt, null, null, defaultValue);
    }

    public static double getFloat(String prompt, Double min, Double max, Double defaultValue) {
        double result = 0.0;

        boolean hasMin = true;
        boolean hasMax = true;

        if (min == null) {
            min = Double.MIN_VALUE;
            hasMin = false;
        }
        if (max == null) {
            max = Double.MAX_VALUE;
            hasMax = false;
        }

        String hint = "";
        String defaultHint = "";
        if (hasMin && !hasMax) {
            hint = " [" + min + " - " + "inf" + "]";
        } else if (!hasMin && hasMax) {
            hint = " [" + "inf" + " - " + max + "]";
        } else if (hasMin && hasMax) {
            hint = " [" + min + " - " + max + "]";
        }
        if (defaultValue != null) {
            defaultHint = String.format(" [%.2f]", defaultValue);
        }

        do {
            boolean valid = true;
            do {
                try {
                    System.out.print(prompt + hint + defaultHint + ": ");
                    String input = sc.nextLine().trim();
                    if (input.isEmpty()) {
                        if (defaultValue != null) {
                            return defaultValue;
                        } else {
                            valid = false;
                            System.out.println("Input is blank!");
                            continue;
                        }
                    }
                    result = Double.parseDouble(input);
                    valid = true;
                } catch (Exception e) {
                    valid = false;
                    System.out.println("Invalid Float!");
                }
            } while (!valid);
            if (result < min || result > max) {
                System.out.println("Out of range! " + hint);
            }
        } while (result < min || result > max);

        return result;
    }

    public static double getFloat(String prompt, double min, double max) {
        return getFloat(prompt, min, max, null);
    }

    public static double getFloat(String prompt) {
        return getFloat(prompt, null, null, null);
    }

    public static String getStr(String prompt, String pattern, String errorMsg, String defaultValue) {
        String data;
        boolean valid;
        do{
            data = getStr(prompt, defaultValue);
            valid = data.matches(pattern);
            if (!valid) System.out.println(errorMsg);
        } while (!valid);

        return data;
    }

    public static String getStr(String prompt, String pattern, String errorMsg) {
        return getStr(prompt, pattern, errorMsg, null);
    }

    public static String getStr(String prompt, String defaultValue) {
        String hint = "";
        if (defaultValue != null && !defaultValue.isEmpty()) {
            hint = " [" + defaultValue + "]";
        }
        String input = "";
        do {
            System.out.print(prompt + hint + ": ");
            input = sc.nextLine().trim();
            if (input.isEmpty()) {
                if (defaultValue != null)
                    return defaultValue;
                else
                    System.out.println("This field cannot be empty!\n");
            }
        } while(input.isEmpty());
        return input;
    }

    public static String getStr(String prompt) {
        return getStr(prompt, null);
    }

    public static String flattenString(String str) {
        return str.trim().toLowerCase().replaceAll(" |-|_", "");
    }

    public static Date getDate(String prompt, String dateFormat, Date defaultValue){
        String dateStr;
        Date d;
        String hint = " ("+dateFormat+")";
        if (defaultValue != null) {
            hint += " [" + dateToStr(defaultValue, dateFormat) + "]";
        }
        // Tạo DateFormat formatter với date format trong tham sồ
        DateFormat formatter = new SimpleDateFormat(dateFormat);
        do{
            System.out.print(prompt + hint + ": "); // xuất lời nhắc
            dateStr = sc.nextLine().trim(); // nhập data
            if (dateStr.isEmpty() && defaultValue != null) {
                return defaultValue;
            }
            try{ // phân tích String -> Date. Hành vi parse sẽ tự động điều
                //chỉnh phù hợp. Thí dụ 32-12-2024 sẽ chuyển thành 01/01/2025
                d = formatter.parse(dateStr);
            }
            catch (ParseException e){ // nếu phân tích có lỗi xuất thông báo
                System.out.println("Date format should be " + dateFormat + ".");
                d = null;
            }
        } while (d==null);

        return d;
    }
    public static Date getDate(String prompt, String dateFormat){
        return getDate(prompt, dateFormat, null);
    }

    public static String formatInt(int num, String numFormat) {
        DecimalFormat formatter = new DecimalFormat(numFormat);
        return formatter.format(num);
    }
    public static String formatFloat(double num, String numFormat) {
        DecimalFormat formatter = new DecimalFormat(numFormat);
        return formatter.format(num);
    }

    public static int compareDate(Date thisDate, Date thatDate) {
        String dateThis = dateToStr(thisDate, "yyyy-MM-dd");
        String dateThat = dateToStr(thatDate, "yyyy-MM-dd");
        return dateThis.compareTo(dateThat);
    }

    public static String dateToStr(Date date, String dateFormat){
        if (date==null) return null;
        DateFormat formatter = new SimpleDateFormat(dateFormat);
        return formatter.format(date);
    }

    public static int dateGetPart(Date d, int calendarPart){
        GregorianCalendar cal = new GregorianCalendar();// tạo calandar
        cal.setTime(d); // cho calendar mang ngày d
        return cal.get(calendarPart); // lấy ra thành phần thời gian này
    }

    public int getAge(Date birthDate){
        int currentYear = dateGetPart(new Date(), Calendar.YEAR);
        int birthYear = dateGetPart(birthDate, Calendar.YEAR);
        return currentYear-birthYear;
    }

    public static int intMenu (Object... options){
       // int choice;
        int n= options.length ; // số mục trong menu
        for (int i=0; i< n; i++) // xuất các options
            System.out.println((i+1) + "-" + options[i]);

        System.out.println();

        return getInt("Choose", 1, n)-1; // User bị buộc nhập số phù hợp 1..n
    }

    public static int intMenu(List options, Integer defaultValue) {
        int n= options.size() ;
        for (int i=0; i< n; i++)
            System.out.println((i+1) + "-" + options.get(i));
        if (defaultValue == null) {
            return getInt("Choose", 1, n)-1;
        }

        System.out.println();

        return getInt("Choose", 1, n, defaultValue + 1) - 1;
    }

    public static int intMenu(List options) {
        return intMenu(options, null);
    }

    public static Object objMenu (Object... options){
        int choice = intMenu(options);
        return options[choice-1];
    }

    public static Object objMenu(List options, Integer defaultValue){
        int choice = intMenu(options, defaultValue);
        return options.get(choice);
    }

    public static Object objMenu(List options) {
        int choice = intMenu(options, null);
        return options.get(choice);
    }

    public static String dateKeyGen(){
        Date now = new Date(); // lấy ngày hiện tại
        // chuyển thành dạng chuỗi theo mẫu
        SimpleDateFormat f = new SimpleDateFormat("yyyyMMddhhmmss");
        return f.format(now);
    }

    public static void main() {
        DecimalFormat dfCustom = new DecimalFormat("#,##0.0#");
        System.out.println (dfCustom.format(323897654));
        // Test nhập boolean
        boolean b = getBool("Gender");
        System.out.println("Data input: " + b);
        // Test nhập số
        int any = getInt("Any num");
        System.out.println("Any Int inputted: " + any);
        int age = getInt("Age", 18, 60);
        System.out.println("Age inputted: " + age);
        /* Nhập số int lớn hơn 0. Các kiểu dữ liệu số đã định nghĩa sẵn
           tầm trị bằng 2 hằng MIN_VLUE, MAX_VALUE */
        int nItem = getInt("Number of Item", 1, Integer.MAX_VALUE);
        System.out.println("Number of items: " + nItem);
        // Nhập lương là số thực ít nhất là 200
        double salary = getFloat("Sal", 200, Double.MAX_VALUE);
        System.out.println("Salaray inputted: " + salary);
        // Test nhập 1 String bất kỳ
        String str;
        str = getStr("Input a string");
        System.out.println("Data input: " + str);
        // Test nhập số phone theo mẫu: 9 số hoặc 11 số có chỉ định tính từ
        // đầu chuỗi nhập (chỉ định bằng ^) đến cuối chuỗi nhập ($)
        str = getStr("Phone 1","^[\\d]{9}|[\\d]{11}$","9/11 digits!");
        System.out.println("Phone 1 input: " + str);
        str = getStr("Phone 2","[\\d]{9}|[\\d]{11}","9/11 digits!");
        System.out.println("Phone 2 input: " + str);
        // Test xuất Date, truy xuất thành phần của Date
        Date d = new Date(); //Lấy ngày hiện hành trong máy tính
        System.out.println(d);
        System.out.println("MM-dd-yyyy: " + dateToStr(d, "MM-dd-yyyy"));
        System.out.println("dd-MM-yyyy: " +  dateToStr(d, "dd-MM-yyyy"));
        System.out.println("yyyy-MM: " +  dateToStr(d, "yyyy-MM"));
        System.out.println("Year: " + dateGetPart(d, Calendar.YEAR));
        // Month bắt đầu từ 0 nên phải cộng thêm 1
        System.out.println("Month: " + dateGetPart(d, Calendar.MONTH + 1));
        System.out.println("Date: " + dateGetPart(d, Calendar.DATE));
        // Test nhập và xuất Date
        d= getDate("Date of birth dd-MM-yyyy", "dd-MM-yyyy");
        System.out.println(d);
        System.out.println("dd-MM-yyyy: " + dateToStr(d, "dd-MM-yyyy"));
        // Test các menu
        int choice = intMenu("Add", "Search", "Remove", "Update", "Print");
        System.out.println("User choice (int): " + choice);
        String objChoice = (String)objMenu("Add", "Search", "Remove", "Update");
        System.out.println("User choice (obj): " + objChoice);
        // test sinh mã tự động
        String code = dateKeyGen();
        System.out.println("Code: " + code);
    } // main()
}
