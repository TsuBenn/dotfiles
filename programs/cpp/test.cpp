#include <iostream>
#include <bits/stdc++.h>
using namespace std;

class NhanVatGame {
    private:
        int hp;
        string tenNhanvat;

    public:
        string gettenNhanvat()
        {
            return tenNhanvat;
        }

        int getHP()//ham xem
        {
            return hp;
        }

        void setTenNhanVat(string ten) {
            tenNhanvat = ten;
        }

        void setHP(int newhp)
        {
           if(newhp > 100)
           {
                hp = 100;
           }
           else if(newhp < 0)
           {
                hp = 0;
                cout<<"Nhan Vat "<<tenNhanvat<<" Da heo";
           }
           else 
           {
                hp = newhp;
           }
        }
};



int main()
{
    NhanVatGame Yasuo;

    Yasuo.setTenNhanVat("Yasou");

    Yasuo.setHP(-4);
    cout<<Yasuo.getHP()<<endl;
    Yasuo.setHP(106);
    cout<<Yasuo.getHP()<<endl;
    Yasuo.setHP(99);
    cout<<Yasuo.getHP()<<endl;
    return 0;
}
