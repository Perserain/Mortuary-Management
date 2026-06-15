using DoAn.ViewModel;

namespace DoAn.Model
{
    public class ThanNhanModel : BaseViewModel
    {
        private string _matn;
        private string _math;
        private string _hotentn;
        private string _quanhe;
        private string _dienthoai;
        private string _diachi;
        private bool _laliendhe;
        private string _ghichu;
        private string _hotenTH;   // từ JOIN VIEW_ThanNhanThiHai
        private string _trangthaiTH;

        public string MATN
        {
            get => _matn;
            set { _matn = value; OnPropertyChanged(); }
        }

        public string MATH
        {
            get => _math;
            set { _math = value; OnPropertyChanged(); }
        }

        public string HOTEN_TN
        {
            get => _hotentn;
            set { _hotentn = value; OnPropertyChanged(); }
        }

        public string QUANHE
        {
            get => _quanhe;
            set { _quanhe = value; OnPropertyChanged(); }
        }

        public string DIENTHOAI
        {
            get => _dienthoai;
            set { _dienthoai = value; OnPropertyChanged(); }
        }

        public string DIACHI
        {
            get => _diachi;
            set { _diachi = value; OnPropertyChanged(); }
        }

        public bool LALIENDHE
        {
            get => _laliendhe;
            set { _laliendhe = value; OnPropertyChanged(); OnPropertyChanged(nameof(BadgeLienHe)); }
        }

        public string GHICHU
        {
            get => _ghichu;
            set { _ghichu = value; OnPropertyChanged(); }
        }

        // Từ JOIN với THIHAI
        public string HOTEN_TH
        {
            get => _hotenTH;
            set { _hotenTH = value; OnPropertyChanged(); }
        }

        public string TRANGTHAI
        {
            get => _trangthaiTH;
            set { _trangthaiTH = value; OnPropertyChanged(); }
        }

        // Hiển thị badge ★ vàng cho người liên hệ chính
        public string BadgeLienHe => LALIENDHE ? "★ Liên hệ chính" : "";
    }
}