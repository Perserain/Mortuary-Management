using DoAn.ViewModel;

namespace DoAn.Model
{
    public class CanhBaoModel : BaseViewModel
    {
        private int _macb;
        private string _thoigian;
        private string _loaicb;
        private string _math;
        private string _mangan;
        private string _noidung;
        private bool _daoc;
        private string _hotenTH;
        private int _mucDoUuTien;
        private string _mucDoHienThi;

        public int MACB
        {
            get => _macb;
            set { _macb = value; OnPropertyChanged(); }
        }

        public string THOIGIAN
        {
            get => _thoigian;
            set { _thoigian = value; OnPropertyChanged(); }
        }

        public string LOAICB
        {
            get => _loaicb;
            set { _loaicb = value; OnPropertyChanged(); OnPropertyChanged(nameof(IconCanhBao)); OnPropertyChanged(nameof(MauCanhBao)); }
        }

        public string MATH
        {
            get => _math;
            set { _math = value; OnPropertyChanged(); }
        }

        public string MANGAN
        {
            get => _mangan;
            set { _mangan = value; OnPropertyChanged(); }
        }

        public string NOIDUNG
        {
            get => _noidung;
            set { _noidung = value; OnPropertyChanged(); }
        }

        public bool DAOC
        {
            get => _daoc;
            set { _daoc = value; OnPropertyChanged(); }
        }

        // Từ JOIN với THIHAI
        public string HOTEN_TH
        {
            get => _hotenTH;
            set { _hotenTH = value; OnPropertyChanged(); }
        }

        public int MUC_DO_UU_TIEN
        {
            get => _mucDoUuTien;
            set { _mucDoUuTien = value; OnPropertyChanged(); }
        }

        public string MUC_DO_HIEN_THI
        {
            get => _mucDoHienThi;
            set { _mucDoHienThi = value; OnPropertyChanged(); OnPropertyChanged(nameof(IconCanhBao)); OnPropertyChanged(nameof(MauCanhBao)); }
        }

        // Computed properties cho UI
        public string IconCanhBao => LOAICB switch
        {
            "QuaHan"   => "⏰",
            "NhietDo"  => "🌡️",
            "ChuaKham" => "🔬",
            _          => "🔔"
        };

        public string MauCanhBao => MUC_DO_UU_TIEN switch
        {
            1 => "#EF4444",   // Đỏ - Khẩn cấp / Nguy hiểm
            2 => "#F97316",   // Cam - Cần xử lý
            _ => "#64748B"    // Xám - Thông báo
        };

        public string TenThiHaiHienThi => !string.IsNullOrEmpty(HOTEN_TH) ? HOTEN_TH : (MATH ?? "—");
    }
}
