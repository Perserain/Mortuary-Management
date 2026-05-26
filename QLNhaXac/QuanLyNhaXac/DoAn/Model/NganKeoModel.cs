using DoAn.ViewModel;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DoAn.Model
{
    public class NganKeoModel : BaseViewModel
    {
        private string _maNgan;
        private string _viTri;
        private double _nhietDo;
        private string _maTH;
        private string _hoTenTH;
        public string MaNgan {
            get => _maNgan;
            set 
            {
                _maNgan = value; OnPropertyChanged(); 
            } 
        }
        public string ViTri
        { 
            get => _viTri;
            set { _viTri = value; OnPropertyChanged(); } 
        }

        public double NhietDo 
        { 
            get => _nhietDo; 
            set { _nhietDo = value; OnPropertyChanged(); } 
        }

        public string MaTH {
            get => _maTH; 
            set { _maTH = value; OnPropertyChanged(); } 
        }

        // Thuộc tính này chỉ dùng để hiển thị lên DataGrid (Lấy từ bảng ThiHai sang)
        public string HoTenTH {
            get => _hoTenTH; 
            set { _hoTenTH = value; OnPropertyChanged(); } 
        }
    }
}
