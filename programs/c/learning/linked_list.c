#include <stdio.h>
#include <stdlib.h>

typedef struct Node {
  int data;
  struct Node *next;
} Node;

Node *create_node(int value) {
  // malloc() can return NULL! Always check!
  Node *new_node = malloc(sizeof(Node));
  if (new_node == NULL) {
    return NULL;
  }
  new_node->data = value;
  new_node->next = NULL;
  return new_node;
}

void push_front(Node **head, int value) {
  Node *new_node = create_node(value);
  if (new_node == NULL)
    return;
  new_node->next = *head;
  *head = new_node;
}

void push_back(Node **head, int value) {
  if (*head == NULL) {
    push_front(head, value);
    return;
  }
  Node *new_node = create_node(value);
  if (new_node == NULL)
    return;
  Node *current = *head;
  while (current->next != NULL) {
    current = current->next;
  }
  current->next = new_node;
}

void insert(Node **head, int value, int index) {
  if (index < 0) {
    printf("Insert index must be >= 0\n");
    return;
  }
  if (index == 0) {
    push_front(head, value);
    return;
  }
  if (*head == NULL) {
    printf("Cannot insert value of \"%d\" at position %d\n", value, index);
    return;
  }
  Node *new_node = create_node(value);
  if (new_node == NULL)
    return;
  Node *previous = NULL;
  Node *current = *head;
  int position = 0;
  while (current != NULL && position != index) {
    previous = current;
    current = current->next;
    position++;
  }
  if (position == index) {
    new_node->next = current;
    previous->next = new_node;
  } else {
    printf("Cannot insert value of \"%d\" at position %d\n", value, index);
    free(new_node);
  }
}

int list_size(Node *head) {
  if (head == NULL) {
    return 0;
  }
  int count = 0;
  Node *current = head;
  while (current != NULL) {
    count++;
    current = current->next;
  }
  return count;
}

void print_list(Node *head) {
  Node *current = head;
  while (current != NULL) {
    printf("%d -> ", current->data);
    current = current->next;
  }
  printf("NULL\n");
}

void free_list(Node *head) {
  Node *current = head;
  while (current != NULL) {
    Node *temp = current;
    current = current->next;
    free(temp);
  }
}

Node* pop_front(Node** head) {
  if (*head == NULL) {
    printf("Cannot Pop Front an Empty List!\n");
    return NULL;
  }
  Node* temp = *head;
  *head = (*head)->next;
  return temp;
}

Node* pop_back(Node** head) {
  if (*head == NULL) {
    printf("Cannot Pop Back an Empty List!\n");
    return NULL;
  }
  if ((*head)->next == NULL) {
    return pop_front(head);
  }
  Node* previous = NULL;
  Node* current = *head;
  while (current->next != NULL) {
    previous = current;
    current = current->next;
  }
  previous->next = NULL;
  return current;
}

Node* remove_at(Node** head, int index) {
  if (*head == NULL) {
    printf("Cannot Remove Item an Empty List!\n");
    return NULL;
  }
  if (index == 0) {
    return pop_front(head);
  }
  Node* previous = NULL;
  Node* current = *head;
  int position = 0;
  while (current != NULL && position != index) {
    previous = current;
    current = current->next;
    position++;
  }
  if (position == index && current != NULL) {
    previous->next = current->next;
    return current;
  } else {
    printf("Cannot remove item at position %d!\n", index);
    return NULL;
  }
}

int main() {

  Node *a = NULL;
  insert(&a, 1, 0);  // empty, index 0
  insert(&a, 2, 5);  // too far
  insert(&a, 3, 0);  // non-empty, index 0  <- this one
  insert(&a, 4, 1);  // middle
  insert(&a, 5, 3);  // end
  insert(&a, 6, -1); // negative
  free(pop_front(&a));
  free(pop_back(&a));
  free(remove_at(&a, 2));
  print_list(a);

  free_list(a);

  return 0;
}
