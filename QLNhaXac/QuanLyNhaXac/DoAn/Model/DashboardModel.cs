using DoAn.ViewModel;
using System;

namespace DoAn.Model
{
    /// <summary>KPI tổng quan từ VIEW_Dashboard / SP_Dashboard</summary>
    public class DashboardModel : BaseViewModel
    {
        private int _tongThiHai;
        private int _dangBaoQuan;
        private int _choThanhLy;
        private int _nganKeoTrong;
        private int _nganKeoDang;
        private int _tongNganKeo;
        private decimal _doanhThuHomNay;
        private decimal _doanhThuThang;
        private int _soCanhBaoChuaDoc;
        private int _hoaDonChuaTT;

        public int TongThiHai { get => _tongThiHai; set { _tongThiHai = value; OnPropertyChanged(); } }
        public int DangBaoQuan { get => _dangBaoQuan; set { _dangBaoQuan = value; OnPropertyChanged(); } }
        public int ChoThanhLy { get => _choThanhLy; set { _choThanhLy = value; OnPropertyChanged(); } }
        public int NganKeoTrong { get => _nganKeoTrong; set { _nganKeoTrong = value; OnPropertyChanged(); } }
        public int NganKeoDang { get => _nganKeoDang; set { _nganKeoDang = value; OnPropertyChanged(); } }
        public int TongNganKeo { get => _tongNganKeo; set { _tongNganKeo = value; OnPropertyChanged(); } }
        public decimal DoanhThuHomNay { get => _doanhThuHomNay; set { _doanhThuHomNay = value; OnPropertyChanged(); } }
        public decimal DoanhThuThang { get => _doanhThuThang; set { _doanhThuThang = value; OnPropertyChanged(); } }
        public int SoCanhBaoChuaDoc { get => _soCanhBaoChuaDoc; set { _soCanhBaoChuaDoc = value; OnPropertyChanged(); } }
        public int HoaDonChuaTT { get => _hoaDonChuaTT; set { _hoaDonChuaTT = value; OnPropertyChanged(); } }
    }

    /// <summary>Mỗi cột trong biểu đồ thi hài theo tháng</summary>
    public class ThiHaiTheoThangModel
    {
        public string Thang { get; set; }   // "T1", "T2", ...
        public int SoLuong { get; set; }
        public double ChieuCaoChuanHoa { get; set; } // 0.0 – 1.0, tính trong VM
    }

    /// <summary>Mỗi tháng trong biểu đồ doanh thu</summary>
    public class DoanhThuTheoThangModel
    {
        public string Thang { get; set; }
        public decimal DoanhThu { get; set; }
        public double ChieuCaoChuanHoa { get; set; }
    }

    /// <summary>Phân bổ nguyên nhân tử vong</summary>
    public class LoaiCauTuModel
    {
        public string LoaiCauTu { get; set; }
        public int SoLuong { get; set; }
        public double GocRad { get; set; }  // góc (radian) của slice
        public double GocBatDau { get; set; }  // góc bắt đầu của slice
        public string MauSac { get; set; }  // hex color
    }

    /// <summary>Một dòng cảnh báo trong bảng Top 5</summary>
    public class CanhBaoModel : BaseViewModel
    {
        private string _maCB;
        private DateTime _thoiGian;
        private string _loaiCB;
        private string _noiDung;
        private string _mucDoHienThi;
        private bool _daOc;

        public string MaCB { get => _maCB; set { _maCB = value; OnPropertyChanged(); } }
        public DateTime ThoiGian { get => _thoiGian; set { _thoiGian = value; OnPropertyChanged(); } }
        public string LoaiCB { get => _loaiCB; set { _loaiCB = value; OnPropertyChanged(); } }
        public string NoiDung { get => _noiDung; set { _noiDung = value; OnPropertyChanged(); } }
        public string MucDoHienThi { get => _mucDoHienThi; set { _mucDoHienThi = value; OnPropertyChanged(); } }
        public bool DaDoc { get => _daOc; set { _daOc = value; OnPropertyChanged(); } }
    }
}