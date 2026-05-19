#include <iostream>
#include <bits/stdc++.h>

using namespace std;

class PhanSo
{
    private:

        int Tuso;
        int Mauso;

    public:

        PhanSo()
        {
            Tuso = 0;
            Mauso = 1;
        }

        PhanSo(const int Tuso, const int Mauso)
        {
            this->Tuso = Tuso;
            this->Mauso = Mauso;
        }

        PhanSo(const PhanSo &ps)
        {
            this-> Tuso = ps.Tuso;
            this-> Mauso = ps.Mauso;
        }

        PhanSo operator+(const PhanSo &ps)
        {
            return PhanSo(Tuso*ps.Mauso + ps.Tuso*Mauso, Mauso*ps.Mauso);
        }

        bool operator==(const PhanSo &ps)
        {
            if(Tuso * ps.Mauso == ps.Tuso *  Mauso)
            {
            return true;
            }
            else{return false;}
        }

        PhanSo& operator=(const PhanSo &ps)
        {
            this->Tuso = ps.Tuso;
            this->Mauso = ps.Mauso;
            return *this;
        }

        PhanSo operator++(int x)
        {
            PhanSo Result = *this;
            Tuso = Tuso + Mauso;
            return Result;
        }

        PhanSo& operator++()
        {
             this->Tuso = this ->Tuso + this -> Mauso;
             return *this;
        }

        friend istream& operator>> (istream &is,PhanSo &ps)
        {
            cout<<"Nhap Tu so: "<<endl;
            is>>ps.Tuso;
            cout<<"Nhap Mau so: "<<endl;
            is>>ps.Mauso;
            return cin;
        }

        friend ostream& operator<< (ostream &os, const PhanSo &ps)
        {
            os<<"Phan So Vua Nhap:"<<ps.Tuso<<"/"<<ps.Mauso<<endl;
            return cout;
        }

};


int main()
{
    PhanSo a(5, 10);

    PhanSo b(a);

    cout<<a++;

    return 0;
}
