using DoAn.ViewModel;

namespace DoAn.Model
{
    // ─── Model đại diện cho 1 Database User ───────────────────────────────────
    public class UserModel : BaseViewModel
    {
        private string _tenUser;
        public string TenUser
        {
            get => _tenUser;
            set { _tenUser = value; OnPropertyChanged(); }
        }

        private string _loaiUser;
        public string LoaiUser
        {
            get => _loaiUser;
            set { _loaiUser = value; OnPropertyChanged(); }
        }

        private string _tenLogin;
        public string TenLogin
        {
            get => _tenLogin;
            set { _tenLogin = value; OnPropertyChanged(); }
        }

        private bool _isSelected;
        public bool IsSelected
        {
            get => _isSelected;
            set { _isSelected = value; OnPropertyChanged(); }
        }
    }

    // ─── Model đại diện cho 1 Database Role ───────────────────────────────────
    public class RoleModel : BaseViewModel
    {
        private string _tenRole;
        public string TenRole
        {
            get => _tenRole;
            set { _tenRole = value; OnPropertyChanged(); }
        }

        private string _loaiRole;
        public string LoaiRole
        {
            get => _loaiRole;
            set { _loaiRole = value; OnPropertyChanged(); }
        }

        private bool _isSelected;
        public bool IsSelected
        {
            get => _isSelected;
            set { _isSelected = value; OnPropertyChanged(); }
        }
    }

    // ─── Model lưu trạng thái quyền của 1 bảng ────────────────────────────────
    public class TablePermissionModel : BaseViewModel
    {
        private string _tenBang;
        public string TenBang
        {
            get => _tenBang;
            set { _tenBang = value; OnPropertyChanged(); }
        }

        // Quyền CRUD
        private bool _coSelect;
        public bool CoSelect
        {
            get => _coSelect;
            set { _coSelect = value; OnPropertyChanged(); }
        }

        private bool _coInsert;
        public bool CoInsert
        {
            get => _coInsert;
            set { _coInsert = value; OnPropertyChanged(); }
        }

        private bool _coUpdate;
        public bool CoUpdate
        {
            get => _coUpdate;
            set { _coUpdate = value; OnPropertyChanged(); }
        }

        private bool _coDelete;
        public bool CoDelete
        {
            get => _coDelete;
            set { _coDelete = value; OnPropertyChanged(); }
        }

        // Tuỳ chọn Grant
        private bool _withGrant;
        public bool WithGrant
        {
            get => _withGrant;
            set { _withGrant = value; OnPropertyChanged(); }
        }

        private bool _cascade;
        public bool Cascade
        {
            get => _cascade;
            set { _cascade = value; OnPropertyChanged(); }
        }

        private bool _revoke;
        public bool Revoke
        {
            get => _revoke;
            set { _revoke = value; OnPropertyChanged(); }
        }
    }
}
