using DoAn.ViewModel;

namespace DoAn.Model
{
    public class AuditLogModel : BaseViewModel
    {
        private long _malog;
        private string _thoigian;
        private string _tenuser;
        private string _tentable;
        private string _hanhdog;
        private string _mabanghi;
        private string _noidung;

        public long MALOG
        {
            get => _malog;
            set { _malog = value; OnPropertyChanged(); }
        }

        public string THOIGIAN
        {
            get => _thoigian;
            set { _thoigian = value; OnPropertyChanged(); }
        }

        public string TENUSER
        {
            get => _tenuser;
            set { _tenuser = value; OnPropertyChanged(); }
        }

        public string TENTABLE
        {
            get => _tentable;
            set { _tentable = value; OnPropertyChanged(); }
        }

        public string HANHDOG
        {
            get => _hanhdog;
            set { _hanhdog = value; OnPropertyChanged(); OnPropertyChanged(nameof(MauHanhDong)); OnPropertyChanged(nameof(IconHanhDong)); }
        }

        public string MABANGHI
        {
            get => _mabanghi;
            set { _mabanghi = value; OnPropertyChanged(); }
        }

        public string NOIDUNG
        {
            get => _noidung;
            set { _noidung = value; OnPropertyChanged(); }
        }

        // Computed: màu badge theo hành động
        public string MauHanhDong => HANHDOG switch
        {
            "INSERT" => "#10B981",   // Xanh lá
            "UPDATE" => "#F59E0B",   // Vàng cam
            "DELETE" => "#EF4444",   // Đỏ
            _        => "#64748B"    // Xám
        };

        // Computed: icon hành động
        public string IconHanhDong => HANHDOG switch
        {
            "INSERT" => "➕",
            "UPDATE" => "✏️",
            "DELETE" => "🗑️",
            _        => "•"
        };
    }
}
