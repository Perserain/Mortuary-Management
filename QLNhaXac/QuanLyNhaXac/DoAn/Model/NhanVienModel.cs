using DoAn.ViewModel;

namespace DoAn.Model
{
    public class NhanVienModel : BaseViewModel
    {
        private string _manv;
        private string _hotenNV;
        private string _chucvu;
        private string _dienthoai;

        public string MANV
        {
            get => _manv;
            set { _manv = value; OnPropertyChanged(); }
        }

        public string HOTEN_NV
        {
            get => _hotenNV;
            set { _hotenNV = value; OnPropertyChanged(); }
        }

        public string CHUCVU
        {
            get => _chucvu;
            set { _chucvu = value; OnPropertyChanged(); }
        }

        public string DIENTHOAI
        {
            get => _dienthoai;
            set { _dienthoai = value; OnPropertyChanged(); }
        }
    }
}
