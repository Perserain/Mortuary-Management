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
            set { _nhietDo = value; OnPropertyChanged(); OnPropertyChanged(nameof(IsWarning)); } 
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

        // ── S2-04: Ngưỡng nhiệt độ cảnh báo từng ngăn ──
        private double? _nhietDoCanhBao;
        public double? NhietDoCanhBao
        {
            get => _nhietDoCanhBao;
            set { _nhietDoCanhBao = value; OnPropertyChanged(); OnPropertyChanged(nameof(IsWarning)); }
        }

        // True khi nhiệt độ hiện tại vượt ngưỡng cảnh báo
        public bool IsWarning =>
            NhietDoCanhBao.HasValue && NhietDo > NhietDoCanhBao.Value;

        // ── S3-03: Lịch bảo trì ──
        private DateTime? _ngayBaoTri;
        public DateTime? NgayBaoTri
        {
            get => _ngayBaoTri;
            set { _ngayBaoTri = value; OnPropertyChanged(); OnPropertyChanged(nameof(IsBaoTriOverdue)); }
        }

        // True khi ngày bảo trì đã qua (quá hạn)
        public bool IsBaoTriOverdue =>
            NgayBaoTri.HasValue && NgayBaoTri.Value.Date < DateTime.Today;
    }
}
