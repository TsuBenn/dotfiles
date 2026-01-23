A = []

n = int(input("Number of numbers: "))
k = int(input("How many time do you want to push right: "))

for i in range(n):
    A.append(i+1)

for i in range(k):
    temp = A[n-1]
    for j in range(n-1, 0, -1):
        A[j] = A[j-1]
    A[0] = temp

print(A)

