#include <filesystem>
#include <iostream>

using namespace std;


struct ListNode {
    int val;
    ListNode *next;
    ListNode() : val(0), next(nullptr) {}
    ListNode(int x) : val(x), next(nullptr) {}
    ListNode(int x, ListNode *next) : val(x), next(next) {}
};

void printList(ListNode* list) {
    while (list != nullptr) {
        cout << list->val;
        list = list->next;
    }
    cout << endl;
}

ListNode* addTwoNumbers(ListNode* l1, ListNode* l2) {

    ListNode *root = new ListNode();
    ListNode *curr = root;

    while (l1 != nullptr || l2 != nullptr) {
        int val1 = l1 ? l1->val : 0;
        int val2 = l2 ? l2->val : 0;
        int sum = curr->val + val1 + val2;
        l1 = l1->next ? l1->next : sum/10 ? new ListNode(0) : nullptr;
        l2 = l2->next ? l2->next : sum/10 ? new ListNode(0) : nullptr;
        if (l1 == nullptr && l2 == nullptr && sum/10 == 0) {
            break;
        }
        curr->val = sum%10;
        curr->next = new ListNode(sum/10);
        curr = curr->next;
    }

    return root;
}

int main (int argc, char *argv[]) {

    ListNode *l1 = new ListNode(2,new ListNode(4,new ListNode(3)));
    ListNode *l2 = new ListNode(5,new ListNode(6,new ListNode(4)));
    ListNode *result = addTwoNumbers(l1,l2);

    printList(result);

    return 0;
}

