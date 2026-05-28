list = [8, 4, 11, 3, 10]

def max(list):
    max = list[0]
    for n in list:
        if n > max:
            max = n
    return max


print(max(list))
