#include <stdio.h>

#include "linked_list.h"

int main() {
    Node* list = NULL;

    push_back(&list, 5);
    push_back(&list, 10);
    push_back(&list, 15);
    push_back(&list, 20);
    push_back(&list, 25);

    push_front(&list, 0);
    push_front(&list, -5);
    push_front(&list, -10);

    print_list(list);

    free_list(list);
    return 0;
}
