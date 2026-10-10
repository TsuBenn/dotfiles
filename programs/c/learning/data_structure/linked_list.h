#pragma once

/**
 * @file utils.h
 * @brief Provides utility functions for string manipulation and mathematical operations.
 * @author Jane Doe
 * @date 2026-10-03
 */

typedef struct Node {
  int data;
  struct Node *next;
} Node;

/// @brief Create a Node using with a value
Node* create_node(int value);

/**
 *
 * @brief Push a Node into the front of a List
 *
 * @param head Is the head
 * @param value Is the value
 * @return void Because why not
 *
 */
void push_front(Node** head, int value);


void push_back(Node** head, int value);

void insert(Node** head, int value, int index);

int list_size(Node* head);

void print_list(Node* head);

void free_list(Node* head);

Node* pop_front(Node** head);

Node* pop_back(Node** head);

Node* remove_at(Node** head, int index);
