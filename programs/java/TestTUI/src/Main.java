import org.jline.terminal.Terminal;
import org.jline.terminal.TerminalBuilder;
import org.jline.utils.InfoCmp;
import java.io.IOException;

public class Main {

    public static void main(String[] args) {
        try {
            // 1. Initialize the terminal and put it in raw mode
            Terminal terminal = TerminalBuilder.builder().system(true).build();
            terminal.enterRawMode();

            String[] options = {"View Profile", "Settings", "System Status", "Exit"};
            int selectedIndex = 0;
            boolean running = true;

            // Clear screen before starting
            terminal.puts(InfoCmp.Capability.clear_screen);

            while (running) {
                // 2. Render the menu
                terminal.writer().println("=== Use UP/DOWN arrows, ENTER to select ===");
                for (int i = 0; i < options.length; i++) {
                    if (i == selectedIndex) {
                        terminal.writer().println("> [ " + options[i] + " ] <"); // Highlighted
                    } else {
                        terminal.writer().println("  " + options[i]);
                    }
                }
                terminal.flush();

                // 3. Read a single keypress
                int read = terminal.reader().read();

                // 4. Handle Arrow Escape Sequences & Controls
                if (read == 27) { // Escape character
                    int next1 = terminal.reader().read();
                    int next2 = terminal.reader().read();

                    if (next1 == 91) { // '[' character
                        if (next2 == 65) { // 'A' is UP
                            selectedIndex = (selectedIndex - 1 + options.length) % options.length;
                        } else if (next2 == 66) { // 'B' is DOWN
                            selectedIndex = (selectedIndex + 1) % options.length;
                        }
                    }
                } else if (read == 13 || read == 10) { // Enter Key (CR or LF)
                    terminal.puts(InfoCmp.Capability.clear_screen);
                    terminal.writer().println("You selected: " + options[selectedIndex] + "\n");
                    
                    if (options[selectedIndex].equals("Exit")) {
                        running = false;
                    } else {
                        terminal.writer().println("Press any key to return to menu...");
                        terminal.flush();
                        terminal.reader().read(); // Wait for acknowledgment
                    }
                }

                // Clear screen for the next frame render
                if (running) {
                    terminal.puts(InfoCmp.Capability.clear_screen);
                }
            }

            // Clean up and restore terminal settings
            terminal.close();

        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
