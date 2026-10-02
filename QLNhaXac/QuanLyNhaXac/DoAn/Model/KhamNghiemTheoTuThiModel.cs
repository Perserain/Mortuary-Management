using System;
using DoAn.ViewModel;

namespace DoAn.Model
{
    public class KhamNghiemTheoTuThiModel : BaseViewModel
    {
        private string _maHS;
        private string _maTH;
        private string _maBS;
        private string _hoTenBS;
        private DateTime? _tgKham;
        private string _ketLuan;

        public string MaHS
        {
            get => _maHS;
            set { _maHS = value; OnPropertyChanged(); }
        }

        public string MaTH
        {
            get => _maTH;
            set { _maTH = value; OnPropertyChanged(); }
        }

        public string MaBS
        {
            get => _maBS;
            set { _maBS = value; OnPropertyChanged(); }
        }

        public string HoTenBS
        {
            get => _hoTenBS;
            set { _hoTenBS = value; OnPropertyChanged(); }
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
