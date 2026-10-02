using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using DoAn.ViewModel;

namespace DoAn.Model
{
    public class HoSoKBModel : BaseViewModel
    {
        private string _maHS;
        private DateTime? _tgKham;
        private string _ketLuan;
        private string _maTH;
        private string _maBS;

        public string MaHS
        {
            get => _maHS;
            set { _maHS = value; OnPropertyChanged(); }
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
    }
}
