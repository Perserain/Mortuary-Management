using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
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

        public Decimal GiaTien
        {
            get => _giaTien;
            set { _giaTien = value; OnPropertyChanged(); }
        }
        public string GhiChu
        {
            get => _ghiChu;
            set { _ghiChu = value; OnPropertyChanged(); }
        }
    }
}
