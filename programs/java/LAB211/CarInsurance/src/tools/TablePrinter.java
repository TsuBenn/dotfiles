package tools;

import java.util.ArrayList;
import java.util.List;

public class TablePrinter {
    private final List<String> columnHeaders = new ArrayList<>();
    private final List<Integer> columnSizes = new ArrayList<>();

    // Adds a column header and its corresponding width
    public void addColumn(String header, int width) {
        columnHeaders.add(header);
        columnSizes.add(width);
    }

    // Prints top border and header row
    public void printHeader() {
        printDivider();
        printFormattedRow(columnHeaders.toArray());
        printDivider();
    }

    // Prints a row of data matching column order
    public void printRow(Object... values) {
        printFormattedRow(values);
    }

    // Prints the closing bottom border
    public void printFooter() {
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
