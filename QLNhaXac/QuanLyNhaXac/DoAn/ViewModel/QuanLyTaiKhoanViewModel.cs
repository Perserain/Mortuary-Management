using DoAn.Core;
using DoAn.Model;
using Microsoft.Data.SqlClient;
using System;
using System.Collections.ObjectModel;
using System.Data;
using System.Linq;
using System.Windows;
using System.Windows.Input;

namespace DoAn.ViewModel
{
    public class QuanLyTaiKhoanViewModel : BaseViewModel
    {
        // ─── Danh sách 7 bảng hệ thống ───────────────────────────────────────
        private static readonly string[] DS_BANG =
        {
            "THIHAI", "DICHVU", "SUDUNG", "NGANKEO",
            "HOSOKHAMBENH", "NHANVIEN", "BACSI"
        };

        // ─── Tab hiện tại (0 = Nhân Viên, 1 = Bác Sĩ) ───────────────────────
        private int _tabIndex;
        public int TabIndex
        {
            get => _tabIndex;
            set
            {
                if (_tabIndex != value)
                {
                    _tabIndex = value;
                    OnPropertyChanged();
                    LoadUsers();
                    ResetPermissions();
                }
            }
        }

        // ─── Danh sách user hiển thị DataGrid ────────────────────────────────
        public ObservableCollection<UserModel> DanhSachUser { get; set; } = new();

        private UserModel _selectedUser;
        public UserModel SelectedUser
        {
            get => _selectedUser;
            set
            {
                _selectedUser = value;
                OnPropertyChanged();
                if (_selectedUser != null) LoadUserPermissions(_selectedUser.TenUser);
                else ResetPermissions();
            }
        }

        // ─── Danh sách quyền theo bảng ───────────────────────────────────────
        public ObservableCollection<TablePermissionModel> DanhSachBang { get; set; } = new();

        // ─── Tùy chọn toàn cục Grant With / Revoke Cascade ───────────────────
        private bool _withGrantOption;
        public bool WithGrantOption
        {
            get => _withGrantOption;
            set { _withGrantOption = value; OnPropertyChanged(); }
        }

        private bool _cascadeRevoke;
        public bool CascadeRevoke
        {
            get => _cascadeRevoke;
            set { _cascadeRevoke = value; OnPropertyChanged(); }
        }

        // ─── Commands ─────────────────────────────────────────────────────────
        public ICommand LuuCommand { get; }
        public ICommand HuyCommand { get; }
        public ICommand SelectAllCommand { get; }

        public QuanLyTaiKhoanViewModel()
        {
            // Khởi tạo danh sách bảng
            foreach (var b in DS_BANG)
                DanhSachBang.Add(new TablePermissionModel { TenBang = b });

            LuuCommand   = new RelayCommand(_ => ExecuteLuu(),  _ => SelectedUser != null);
            HuyCommand   = new RelayCommand(_ => ExecuteHuy());
            SelectAllCommand = new RelayCommand(p => ExecuteSelectAll(p));

            TabIndex = 0; // Kích hoạt load dữ liệu tab đầu
        }

        // ─── Load user theo tab (Nhân Viên / Bác Sĩ) ─────────────────────────
        private void LoadUsers()
        {
            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;

            DanhSachUser.Clear();
            SelectedUser = null;

            // Lọc theo nhóm quyền: tab 0 = QL_NHANVIEN, tab 1 = QL_BACSI
            string roleName = TabIndex == 0 ? "QL_NHANVIEN" : "QL_BACSI";

            try
            {
                using var conn = new SqlConnection(DBConnect.ConnectionString);
                conn.Open();

                // Sử dụng SP_UserTrongRole để chỉ load các user thuộc Tab tương ứng
                var cmd = new SqlCommand("SP_UserTrongRole", conn)
                { CommandType = CommandType.StoredProcedure };
                cmd.Parameters.AddWithValue("@TenRole", roleName);

                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    DanhSachUser.Add(new UserModel
                    {
                        TenUser = reader["TenUser"].ToString(),
                        LoaiUser = reader["LoaiUser"].ToString()
                    });
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi tải danh sách user: " + ex.Message);
            }
        }

        // ─── Load quyền hiện tại của user được chọn ─────────────────────────
        private void LoadUserPermissions(string tenUser)
        {
            ResetPermissions();
            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;

            try
            {
                using var conn = new SqlConnection(DBConnect.ConnectionString);
                conn.Open();

                var cmd = new SqlCommand($"EXEC SP_TatCaQuyenCuaUser @TenUser", conn);
                cmd.Parameters.AddWithValue("@TenUser", tenUser);

                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    string bang = reader["TenBang"].ToString().ToUpper();
                    string quyen = reader["TenQuyen"].ToString().ToUpper();

                    // THÊM DÒNG NÀY: Đọc trạng thái quyền (GRANT hoặc DENY)
                    string trangThai = reader["TrangThai"].ToString().ToUpper();

                    // THÊM DÒNG NÀY: Nếu quyền bị cấm (DENY) thì bỏ qua, không tick xanh trên UI
                    if (trangThai == "DENY") continue;

                    var row = DanhSachBang.FirstOrDefault(b => b.TenBang == bang);
                    if (row == null) continue;

                    switch (quyen)
                    {
                        case "SELECT": row.CoSelect = true; break;
                        case "INSERT": row.CoInsert = true; break;
                        case "UPDATE": row.CoUpdate = true; break;
                        case "DELETE": row.CoDelete = true; break;
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi tải quyền user: " + ex.Message);
            }
        }

        // ─── Lưu: thực hiện GRANT hoặc REVOKE tùy theo cờ Revoke ─────────────
        private void ExecuteLuu()
        {
            if (SelectedUser == null) return;
            if (!DBConnect.RequireAdmin("Phân quyền tài khoản")) return;

            try
            {
                using var conn = new SqlConnection(DBConnect.ConnectionString);
                conn.Open();

                int dem = 0;
                foreach (var row in DanhSachBang)
                {
                    // Gọi duy nhất 1 SP đồng bộ toàn bộ trạng thái CheckBox xuống DB
                    using var cmd = new SqlCommand("SP_CapNhatQuyenChoUser", conn)
                    { CommandType = CommandType.StoredProcedure };

                    cmd.Parameters.AddWithValue("@TenUser", SelectedUser.TenUser);
                    cmd.Parameters.AddWithValue("@TenBang", row.TenBang);

                    // Truyền trực tiếp kiểu bool, ADO.NET tự chuyển thành BIT (0/1) tương ứng trong SQL
                    cmd.Parameters.AddWithValue("@CoSelect", row.CoSelect);
                    cmd.Parameters.AddWithValue("@CoInsert", row.CoInsert);
                    cmd.Parameters.AddWithValue("@CoUpdate", row.CoUpdate);
                    cmd.Parameters.AddWithValue("@CoDelete", row.CoDelete);

                    cmd.Parameters.AddWithValue("@WithGrant", (row.WithGrant || WithGrantOption) ? 1 : 0);
                    cmd.Parameters.AddWithValue("@Cascade", CascadeRevoke ? 1 : 0);

                    cmd.ExecuteNonQuery();
                    dem++;
                }

                MessageBox.Show($"Đã đồng bộ và cập nhật quyền thành công cho [{SelectedUser.TenUser}] trên {dem} bảng hệ thống!", "Thành công");

                // Tải lại quyền từ cơ sở dữ liệu để đảm bảo giao diện hiển thị chuẩn xác nhất
                LoadUserPermissions(SelectedUser.TenUser);
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi đồng bộ quyền: " + ex.Message);
            }
        }

        // ─── Hủy: reset form về trạng thái gốc ──────────────────────────────
        private void ExecuteHuy()
        {
            SelectedUser = null;
            ResetPermissions();
            WithGrantOption = false;
            CascadeRevoke   = false;
        }

        // ─── Select/Deselect tất cả quyền trong 1 cột ────────────────────────
        private void ExecuteSelectAll(object param)
        {
            if (param?.ToString() is not string col) return;
            bool anyOff = DanhSachBang.Any(b => col switch
            {
                "SELECT" => !b.CoSelect,
                "INSERT" => !b.CoInsert,
                "UPDATE" => !b.CoUpdate,
                "DELETE" => !b.CoDelete,
                _        => false
            });

            foreach (var b in DanhSachBang)
            {
                switch (col)
                {
                    case "SELECT": b.CoSelect = anyOff; break;
                    case "INSERT": b.CoInsert = anyOff; break;
                    case "UPDATE": b.CoUpdate = anyOff; break;
                    case "DELETE": b.CoDelete = anyOff; break;
                }
            }
        }

        private void ResetPermissions()
        {
            foreach (var b in DanhSachBang)
            {
                b.CoSelect = b.CoInsert = b.CoUpdate = b.CoDelete = false;
                b.WithGrant = b.Cascade = b.Revoke = false;
            }
        }
    }
}
