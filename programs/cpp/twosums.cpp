#include <iostream>
#include <vector>

using namespace std;


vector<int> twoSum(vector<int>&nums, int target) {

    int size = nums.size();

    for (int i = 0; i < size; i++) {
        for (int j = i + 1; j < size; j++) {
            if (nums[i] + nums[j] == target) {
                return {i,j};
            }
        }
    }

    return {};
}


int main() {

    vector<int> nums = {2, 7, 11, 15};
    int target = 9;

    vector<int> result = twoSum(nums, target);

    for (int i : result) {
        cout << i << " ";
    }
}


