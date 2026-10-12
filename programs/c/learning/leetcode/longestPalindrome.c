#include <stdio.h>
#include <string.h>

char* longestPalindrome(char* s) {
    char* result = s;
    int len = strlen(s);
    int size = 1;

    for (int i = 0;s[i] != '\0'; i++) {
        if (i < 1) {
            continue;
        }
        if (s[i] == s[i-1]) {
            for (int j = i;; j++) {
                int neg_idx = 2*i-j-1;
                if (s[j] != '\0' && neg_idx >= 0 && s[j] == s[neg_idx]) {
                    continue;
                }
                int sub_size = j - (++neg_idx);
                if (size < sub_size) {
                    size = sub_size;
                    result = s + neg_idx;
                }
                break;
            }
        }
        if (i < 2) {
            continue;
        }
        if (s[i] == s[i-2]) {
            for (int j = i;; j++) {
                int neg_idx = 2*i-j-2;
                if (s[j] != '\0' && neg_idx >= 0 && s[j] == s[neg_idx]) {
                    continue;
                }
                int sub_size = j - (++neg_idx);
                if (size < sub_size) {
                    size = sub_size;
                    result = s + neg_idx;
                }
                break;
            }
        }
        if (size == len) {
            break;
        }
    }

    if (size <= len) {
        result[size] = '\0';
    }
    return result;
}

int main(void) {

    char input[1000] = "babad";


    printf("%s", longestPalindrome(input));

    return 0;
}
