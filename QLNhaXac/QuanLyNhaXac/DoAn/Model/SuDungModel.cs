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
        private string _ghiChu;
        private string _maHD;       // NULL = chưa lập HĐ
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
            set { _giaTien = value; OnPropertyChanged(); }
        }

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

        // Trạng thái hiển thị
        public string TrangThaiHD
        {
            get => _trangThaiHD;
            set { _trangThaiHD = value; OnPropertyChanged(); }
        }

        // Computed: đã lập hóa đơn chưa
        public bool DaLapHoaDon => !string.IsNullOrEmpty(MaHD);
    }
}
