using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using DoAn.ViewModel;
namespace DoAn.Model
{
    public class DichVuModel : BaseViewModel
    {
        private string _maDV;
        private string _tenDV;
        private decimal _giaTien;

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
        public decimal GiaTien
        {
            get => _giaTien;
            set { _giaTien = value; OnPropertyChanged(); }
        }
    }
}
