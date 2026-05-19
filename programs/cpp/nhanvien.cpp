#include <iostream> 
#include <string> 

using namespace std;

enum NVType {
    NVSX,
    NVVP,
    None,
};

class NhanVien {
protected:
    string hoTen;
    string ngaySinh;
    float luong;
    NVType type;

public:

    NhanVien() {
        type = None;
    }

    string getHoTen() {
        return hoTen;
    }

    float getLuong() {
        return luong;
    }

    NVType getType() {
        return type;
    }

    virtual void nhapNhanVien() {
        cout << "Nhap ten nhan vien: ";
        getline(cin, hoTen);
        cout << "Nhap ngay sinh nhan vien: ";
        getline(cin, ngaySinh);
    }

    virtual void xuatNhanVien() {
        cout << "Ho ten: " << hoTen << endl;
        cout << "Ngay sinh: " << ngaySinh << endl;
        cout << "Luong: " << luong << endl;
    }

    virtual void tinhLuong() {}

    int getNamSinh() { // 23/04/2005

        int slash = 0;

        string year = "";

        for (int i = 0; i < ngaySinh.length(); i++) {
            if (slash < 2) {
                if (ngaySinh[i] == '/') {
                    slash++;
                }
                continue;
            } else {
                year += ngaySinh[i];
            }
        }

        return stoi(year);
    }

};

class SanXuat: public NhanVien {
private:
    float luongCB;
    int soSP;

public: 

    SanXuat() {
        type = NVSX;
    }

    void tinhLuong() override {
        luong = luongCB + soSP*5000;
    }

    void nhapNhanVien() override {
        cout << "Nhập họ tên NVSX: ";
        getline(cin, hoTen);
        cout << "Nhập ngày sinh NVSX: ";
        getline(cin, ngaySinh);
        cout << "Nhập lương cơ bản NVSX: ";
        string luongCB;
        getline(cin, luongCB);
        this->luongCB = stoi(luongCB);
        cout << "Nhập số sản phẩm NVSX: ";
        string soSP;
        getline(cin, soSP);
        this->soSP = stoi(soSP);
    }

    void xuatNhanVien() override {
        cout << "Họ tên NVSX: " << hoTen << endl;
        cout << "Ngày sinh NVSX: " << ngaySinh << endl;
        cout << "Lương NVSX: " << luong << endl;
    }

};

class VanPhong: public NhanVien {
private:
    int ngayLV;

public: 

    VanPhong() {
        type = NVVP;
    }

    void tinhLuong() override {
        luong = ngayLV * 100000;
    }

    void nhapNhanVien() override {
        cout << "Nhập họ tên NVVP: ";
        getline(cin, hoTen);
        cout << "Nhập ngày sinh NVVP: ";
        getline(cin, ngaySinh);
        cout << "Nhập ngày làm việc NVVP: ";
        string ngayLV;
        getline(cin, ngayLV);
        this->ngayLV = stoi(ngayLV);
    }

    void xuatNhanVien() override {
        cout << "Họ tên NVVP: " << hoTen << endl;
        cout << "Ngày sinh NVVP: " << ngaySinh << endl;
        cout << "Lương NVVP: " << luong << endl;
    }

};

class DanhSachNhanVien {
public:

    NhanVien* arr[100];
    int len;

    DanhSachNhanVien() {
        len = 0;
    }

    void nhapCacNhanVien() {
        
        bool cont = false;

        do {
            int choice;
            NhanVien* newNhanVien;
            cout << "Nhân viên sản xuất(1) hay nhân viên văn phòng(2)? 1 or 2: ";
            string choiceBuff;
            getline(cin, choiceBuff);
            choice = stoi(choiceBuff);
            if (choice == 1) {
                newNhanVien = new SanXuat();
            } else if (choice == 2) {
                newNhanVien = new VanPhong();
            }
            newNhanVien->nhapNhanVien();

            arr[len++] = newNhanVien;
            cout << endl;

            string choice2;
            cout << "Tiếp tục thêm nhân viên (Số nhân viên hiện tại: " << len << ")? (y/n): ";
            getline(cin, choice2);
            choice2 == "y" ? cont = true : cont = false;

            cout << endl;

        } while (cont && len < 100);

    }

    void tinhLuong() {
        for (int i = 0; i < len; i++) {
            arr[i]->tinhLuong();
        }
        cout << endl;
    }
        
    void xuatDanhSachNhanVien() {
        cout << "Danh sách các nhân viên: " << endl;
        for (int i = 0; i < len; i++) {
            arr[i]->xuatNhanVien();
        }
        cout << endl;
    }

    void xuatTongLuong() {
        float sum = 0;
        for (int i = 0; i < len; i++) {
            sum += arr[i]->getLuong();
        }
        cout << "Tổng lương công ty phải trả các nhân viên: " << sum << endl;
        cout << endl;
    }

    void minLuongNVSX() {
        NhanVien* minLuong = nullptr;
        for (int i = 0; i < len; i++) {
            if (arr[i]->getType() == NVSX) {
                if (minLuong == nullptr) {
                    minLuong = arr[i];
                }
                if (arr[i]->getLuong() < minLuong->getLuong()) {
                    minLuong = arr[i];
                }
            }
        }
        if (minLuong != nullptr) {
            cout << "Nhân viên sản xuất " << minLuong->getHoTen() << " có mức lương thấp nhất là " << minLuong->getLuong();
        } else {
            cout << "Không có nhân viên sản xuất nào trong danh sách.";
        }
        cout << endl;
    }

    void maxTuoiNVVP() {
        NhanVien* oldest = nullptr;
        for (int i = 0; i < len; i++) {
            if (arr[i]->getType() == NVVP) {
                if (oldest == nullptr) {
                    oldest = arr[i];
                }
                if (arr[i]->getNamSinh() < oldest->getNamSinh()) {
                    oldest = arr[i];
                }
            }
        }
        if (oldest != nullptr) {
            cout << "Nhân viên văn phòng " << oldest->getHoTen() << " có tuổi lớn nhất";
        } else {
            cout << "Không có nhân viên văn phòng nào trong danh sách.";
        }
        cout << endl;
    }

};

int main() {

    DanhSachNhanVien dsnv;

    dsnv.nhapCacNhanVien();
    dsnv.tinhLuong();
    dsnv.xuatDanhSachNhanVien();
    dsnv.xuatTongLuong();
    dsnv.minLuongNVSX();
    dsnv.maxTuoiNVVP();

    return 0;
}
