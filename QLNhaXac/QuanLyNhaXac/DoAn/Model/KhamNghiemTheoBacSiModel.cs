using System;
using DoAn.ViewModel;

namespace DoAn.Model
{
    public class KhamNghiemTheoBacSiModel : BaseViewModel
    {
        private string _maTH;
        private string _hoTenTH;
        private string _gioiTinh;
        private DateTime? _tgKham;
        private string _ketLuan;

        public string MaTH
        {
            get => _maTH;
            set { _maTH = value; OnPropertyChanged(); }
        }

        public string HoTenTH
        {
            get => _hoTenTH;
            set { _hoTenTH = value; OnPropertyChanged(); }
        }

        public string GioiTinh
        {
            get => _gioiTinh;
            set { _gioiTinh = value; OnPropertyChanged(); }
        }

        public DateTime? TgKham
        {
            get => _tgKham;
            set { _tgKham = value; OnPropertyChanged(); }
        }

        public string KetLuan
        {
            get => _ketLuan;
            set { _ketLuan = value; OnPropertyChanged(); }
        }
    }
}
