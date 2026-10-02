using System;
using DoAn.ViewModel;

namespace DoAn.Model
{
    public class SuDungModel : BaseViewModel
    {
        private string _maTH;
        private string _tenTH;
        private string _maDV;
        private string _tenDV;
        private DateTime? _ngaySD;
        private decimal _giaTien;
        private int _soLuong = 1;       // ← MỚI: số lượng/kỳ sử dụng
        private string _ghiChu;
        private string _maHD;
        private string _trangThaiHD;

        public string MaTH
        {
            get => _maTH;
            set { _maTH = value; OnPropertyChanged(); }
        }

        public string TenTH
        {
            get => _tenTH;
            set { _tenTH = value; OnPropertyChanged(); }
        }

        public string MaDV
        {
            get => _maDV;
            set { _maDV = value; OnPropertyChanged(); }
        }

        public string TenDV
        {
            get => _tenDV;
            set { _tenDV = value; OnPropertyChanged(); }
        }

        public DateTime? NgaySD
        {
            get => _ngaySD;
            set { _ngaySD = value; OnPropertyChanged(); }
        }

        public decimal GiaTien
        {
            get => _giaTien;
            set { _giaTien = value; OnPropertyChanged(); OnPropertyChanged(nameof(ThanhTien)); }
        }

        // ← MỚI: số lượng (VD: bảo quản lạnh 3 ngày → SoLuong = 3)
        public int SoLuong
        {
            get => _soLuong;
            set
            {
                _soLuong = value < 1 ? 1 : value;  // tối thiểu 1
                OnPropertyChanged();
                OnPropertyChanged(nameof(ThanhTien));
            }
        }

        // ← MỚI: thành tiền = đơn giá × số lượng (computed, không lưu DB)
        public decimal ThanhTien => GiaTien * SoLuong;

        public string GhiChu
        {
            get => _ghiChu;
            set { _ghiChu = value; OnPropertyChanged(); }
        }

        // Mã hóa đơn đã lập (NULL = chưa lập HĐ)
        public string MaHD
        {
            get => _maHD;
            set { _maHD = value; OnPropertyChanged(); OnPropertyChanged(nameof(DaLapHoaDon)); }
        }

        public string TrangThaiHD
        {
            get => _trangThaiHD;
            set { _trangThaiHD = value; OnPropertyChanged(); }
        }

        public bool DaLapHoaDon => !string.IsNullOrEmpty(MaHD);
    }
}