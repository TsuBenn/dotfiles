#include <iostream>
#include <bits/stdc++.h>
using namespace std;

class Animal
{
    protected:
        int weight;
        int height;
    public:
        int getweight()
        {
            return weight;
        }
        int getheight()
        {
            return height;
        }
        void setheight(int height)
        {
            this->height= height;
        }
        void setweight(int weight)
        {
            this->weight= weight;
        }

};

class Dog: public Animal
{
private:
    string Ten;
    int tuoi;
public:
    string getTen()
    {
        return Ten;
    }
    int gettuoi()
    {
        return tuoi;
    }
    void setTen(string Ten)
    {
        this->Ten = Ten;
    }
    void settuoi(int tuoi)
    {
        this->tuoi = tuoi;
    }
    Dog(){}
    Dog(int tuoi, string Ten, int weight, int height)
    {
        this->Ten=Ten;
        this->tuoi=tuoi;
        this->weight=weight;
        this->height=height;
    }
};


int main()
{
    Dog Xu(12,"Xu",14,7);

    cout << "Ten: " << Xu.getTen() << endl;
    cout << "Tuoi: " << Xu.gettuoi() << endl;
    cout << "Weight: " << Xu.getweight() << endl;
    cout << "Height: " << Xu.getheight() << endl;

    return 0;
}

