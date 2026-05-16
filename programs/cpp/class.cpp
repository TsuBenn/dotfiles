#include<iostream>

int mssvGlobal = 1;

class SinhVien {
private: 
    int mssv;
    double gpa;
    double drl;

public:

    SinhVien() {
        mssv = mssvGlobal++;
        gpa = 0;
        drl = 0;
    }

    SinhVien(const SinhVien &sv) {
        mssv = sv.mssv;
        gpa = sv.gpa;
        drl = sv.drl;
    }

};

int main() {

    int x;

    char y;

    SinhVien a;

    SinhVien c(a);
    
}
