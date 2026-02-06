#include <iostream>


 struct ListNode {
     int val;
     ListNode *next;
     ListNode() : val(0), next(nullptr) {}
     ListNode(int x) : val(x), next(nullptr) {}
     ListNode(int x, ListNode *next) : val(x), next(next) {}
 };
 


ListNode* addTwoNumbers(ListNode* l1, ListNode* l2) {

    ListNode *root;

    ListNode *curr = root;

    while (l1->next != nullptr && l2->next != nullptr ) {
        int sum = l1->val + l2->val;
        curr = new ListNode(curr->val + 10%(sum), new ListNode(sum/10));
        curr=curr->next;
        l1=l1->next;
        l2=l2->next;
    }

    return root;
}
