package tools;

import java.util.ArrayList;
import java.util.List;

public class TablePrinter {
    private final List<String> columnHeaders = new ArrayList<>();
    private final List<Integer> columnSizes = new ArrayList<>();

    private int printedRows = 0;
    private boolean hasIndex = false;
    private int index = 1;

    String emptyMessage = "Empty Table!";

    public TablePrinter() {}

    public TablePrinter(String emptyMessage) {
        this.emptyMessage = emptyMessage;
    }

    // Adds a column header and its corresponding width
    public void addColumn(String header, int width) {
        columnHeaders.add(header);
        columnSizes.add(width);
    }

    // Adds an Index Column at the front
    public void addIndexColumn(String header) {
        columnHeaders.add(0, header);
        columnSizes.add(0, Math.max(header.length(), 3));
        hasIndex = true;
    }

    // Prints top border and header row
    public void printHeader() {
        index = 1;
        printedRows = 0;
        printDivider();
        printFormattedRow(columnHeaders.toArray());
        printDivider();
    }

    // Prints a row of data matching column order
    public void printRow(Object... values) {
        if (hasIndex) {
            Object[] combined = new Object[values.length + 1];
            combined[0] = index++;
            for (int i = 0; i < values.length; i++) {
                combined[i+1] = values[i];
            }
            printFormattedRow(combined);
        } else {
            printFormattedRow(values);
        }
        printedRows++;
    }

    public void printEmpty(String message) {
        int innerWidth = getFullWidth() - 2;

        if (message.length() > innerWidth) {
            message = message.substring(0, innerWidth);
        }

        int totalPadding = innerWidth - message.length();
        int leftPadding = totalPadding / 2;
        int rightPadding = totalPadding - leftPadding;

        StringBuilder emptyRow = new StringBuilder("|");
        for (int i = 0; i < leftPadding; i++) {
            emptyRow.append(" ");
        }
        emptyRow.append(message);
        for (int i = 0; i < rightPadding; i++) {
            emptyRow.append(" ");
        }
        emptyRow.append("|");

        System.out.println(emptyRow.toString());
    }

    // Prints the closing bottom border
    public void printFooter() {
        index = 1;
        if (printedRows == 0) {
            printEmpty(emptyMessage);
        }
        printedRows = 0;
        printDivider();
    }

    // Helper method to format cells with padding and borders
    private void printFormattedRow(Object[] values) {
        StringBuilder row = new StringBuilder("|");
        for (int i = 0; i < columnSizes.size(); i++) {
            String cellText = (i < values.length && values[i] != null) ? values[i].toString() : "";
            int width = columnSizes.get(i);

            // Truncate text if it exceeds column width
            if (cellText.length() > width) {
                if (width > 1) {
                    cellText = cellText.substring(0, width - 1) + "…";
                } else {
                    cellText = cellText.substring(0, width);
                }
            }

            // %-10s left-aligns text with a total padded width of 10
            row.append(String.format(" %-" + width + "s |", cellText));
        }
        System.out.println(row.toString());
    }

    // Helper method to draw horizontal divider lines (+----+-----+)
    private void printDivider() {
        StringBuilder divider = new StringBuilder("+");
        for (int width : columnSizes) {
            for (int i = 0; i < width + 2; i++) {
                divider.append("-");
            }
            divider.append("+");
        }
        System.out.println(divider.toString());
    }

    // Get the Theoretical Width of the Table
    public int getFullWidth() {
        int totalCellWidth = 0;
        for (int width : columnSizes) {
            totalCellWidth += width;
        }

        // Each column has 2 spaces of padding plus 1 border character
        // Add 1 final border character for the far-left border
        return totalCellWidth + (columnSizes.size() * 3) + 1;
    }
}
