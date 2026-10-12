#include <limits.h>
#include <stdio.h>
#include <string.h>

char* convert(char* s, int numRows) {
    if (numRows == 1) {
        return s;
    }
    int stringLength = strlen(s);
    char tmp[stringLength+1];
    strcpy(tmp, s);
    int resultIndex = 0;

    for (int r = 0; r < numRows; r++) {
            for (int i = r; i < stringLength;) {
                if (resultIndex >= stringLength) return s;
                s[resultIndex++] = tmp[i];
                i += numRows + (numRows-2);
                if (r == 0 || r == numRows - 1)
                  continue;
                if (i - r*2 < stringLength) s[resultIndex++] = tmp[i - r*2];
            }
    }
    return s;
}

int main(void) {

    char input[1000];
    char tmp[1000];
    char output[1000];

    strcpy(input, "0123456789");
    strcpy(tmp, input);

    strcpy(output, convert(tmp, 4));

    printf("%s\n%s\nMatch: %d\n", input, output, strcmp(input, output) == 0);

    return 0;
}
