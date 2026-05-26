using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using DoAn.ViewModel;

namespace DoAn.Model
{
    public class BacSiModel : BaseViewModel
    {
        private string _maBS;
        public string MaBS
        {
            get => _maBS;
            set { _maBS = value; OnPropertyChanged(); }
        }

        private string _hoTenBS;
        public string HoTenBS
        {
            get => _hoTenBS;
            set { _hoTenBS = value; OnPropertyChanged(); }
        }

        private string _chuyenKhoa;
        public string ChuyenKhoa
        {
            get => _chuyenKhoa;
            set { _chuyenKhoa = value; OnPropertyChanged(); }
        }

        private int _namKinhNghiem;
        public int NamKinhNghiem
        {
            get => _namKinhNghiem;
            set { _namKinhNghiem = value; OnPropertyChanged(); }
        }

        private string _maTruongKhoa;
        public string MaTruongKhoa
        {
            get => _maTruongKhoa;
            set { _maTruongKhoa = value; OnPropertyChanged(); }
        }

        public string _capBac;
        public string CapBac 
        { 
            get => _capBac;
            set { _capBac = value; OnPropertyChanged(); }
        }
    }
}
