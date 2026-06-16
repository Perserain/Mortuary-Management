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
    public class QuanLyNhomQuyenViewModel : BaseViewModel
    {
        private static readonly string[] DS_BANG =
        {
            "THIHAI", "DICHVU", "SUDUNG", "NGANKEO",
            "HOSOKHAMBENH", "NHANVIEN", "BACSI"
        };

        // ─── Tab: 0 = Tạo nhóm quyền, 1 = Thêm User vào nhóm ────────────────
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
                    if (_tabIndex == 1)
                    {
                        LoadRoles();
                        LoadAllUsers();
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════════
        // TAB 1 – TẠO NHÓM QUYỀN
        // ═══════════════════════════════════════════════════════════════════════

        private string _tenNhomMoi;
        public string TenNhomMoi
        {
            get => _tenNhomMoi;
            set { _tenNhomMoi = value; OnPropertyChanged(); }
        }

        // Danh sách bảng + quyền để chọn khi tạo nhóm
        public ObservableCollection<TablePermissionModel> DanhSachBangTaoNhom { get; set; } = new();

        public ICommand TaoNhomCommand { get; }

        // ═══════════════════════════════════════════════════════════════════════
        // TAB 2 – THÊM USER VÀO NHÓM
        // ═══════════════════════════════════════════════════════════════════════

        // Bảng nhóm quyền bên trái
        public ObservableCollection<RoleModel> DanhSachRole { get; set; } = new();

        private RoleModel _selectedRole;
        public RoleModel SelectedRole
        {
            get => _selectedRole;
            set
            {
                _selectedRole = value;
                OnPropertyChanged();
                if (_selectedRole != null) LoadUsersInRole(_selectedRole.TenRole);
                else
                {
                    DanhSachUserTrongRole.Clear();
                    DanhSachUserChuaThuoc.Clear();
                }
            }
        }

        // Bảng user đang trong role (bên phải, trạng thái bình thường)
        public ObservableCollection<UserModel> DanhSachUserTrongRole { get; set; } = new();

        // Bảng user CHƯA thuộc role (hiển thị khi nhấn Grant)
        public ObservableCollection<UserModel> DanhSachUserChuaThuoc { get; set; } = new();

        private bool _showGrantPanel;
        public bool ShowGrantPanel
        {
            get => _showGrantPanel;
            set { _showGrantPanel = value; OnPropertyChanged(); }
        }

        private bool _showRevokePanel;
        public bool ShowRevokePanel
        {
            get => _showRevokePanel;
            set { _showRevokePanel = value; OnPropertyChanged(); }
        }

        public ICommand GrantCommand  { get; }
        public ICommand RevokeCommand { get; }
        public ICommand LuuUserCommand { get; }
        public ICommand HuyUserCommand { get; }

        // ─── Constructor ─────────────────────────────────────────────────────
        public QuanLyNhomQuyenViewModel()
        {
            foreach (var b in DS_BANG)
                DanhSachBangTaoNhom.Add(new TablePermissionModel { TenBang = b });

            TaoNhomCommand = new RelayCommand(
                _  => ExecuteTaoNhom(),
                _  => !string.IsNullOrWhiteSpace(TenNhomMoi));

            GrantCommand   = new RelayCommand(_ => ExecuteGrant(),  _ => SelectedRole != null);
            RevokeCommand  = new RelayCommand(_ => ExecuteRevoke(), _ => SelectedRole != null);
            LuuUserCommand = new RelayCommand(_ => ExecuteLuuUser(), _ => SelectedRole != null);
            HuyUserCommand = new RelayCommand(_ => ExecuteHuyUser());

            TabIndex = 0;
        }

        // ─── Tab 1: Tạo nhóm quyền mới ───────────────────────────────────────
        private void ExecuteTaoNhom()
        {
            if (string.IsNullOrWhiteSpace(TenNhomMoi))
            {
                MessageBox.Show("Vui lòng nhập tên nhóm quyền!", "Cảnh báo");
                return;
            }
            if (!DBConnect.RequireAdmin("Tạo nhóm quyền")) return;

            try
            {
                using var conn = new SqlConnection(DBConnect.ConnectionString);
                conn.Open();

                var cmd = new SqlCommand("SP_TaoRoleMoi", conn)
                { CommandType = CommandType.StoredProcedure };

                cmd.Parameters.AddWithValue("@TenRole", TenNhomMoi.Trim());

                // Map quyền từng bảng
                var bangMap = DanhSachBangTaoNhom.ToDictionary(b => b.TenBang);
                AddBangParams(cmd, bangMap, "THIHAI",       "TH");
                AddBangParams(cmd, bangMap, "DICHVU",       "DV");
                AddBangParams(cmd, bangMap, "SUDUNG",       "SD");
                AddBangParams(cmd, bangMap, "NGANKEO",      "NK");
                AddBangParams(cmd, bangMap, "HOSOKHAMBENH", "HS");
                AddBangParams(cmd, bangMap, "NHANVIEN",     "NV");
                AddBangParams(cmd, bangMap, "BACSI",        "BS");

                cmd.ExecuteNonQuery();

                MessageBox.Show($"Đã tạo nhóm quyền [{TenNhomMoi}] thành công!", "Thành công");

                // Reset form
                TenNhomMoi = string.Empty;
                foreach (var b in DanhSachBangTaoNhom)
                    b.CoSelect = b.CoInsert = b.CoUpdate = b.CoDelete = false;
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi tạo nhóm quyền: " + ex.Message);
            }
        }

        private static void AddBangParams(
            SqlCommand cmd,
            System.Collections.Generic.Dictionary<string, TablePermissionModel> map,
            string tenBang, string prefix)
        {
            var b = map.TryGetValue(tenBang, out var val) ? val : null;
            cmd.Parameters.AddWithValue($"@{prefix}_Select", b?.CoSelect == true ? 1 : 0);
            cmd.Parameters.AddWithValue($"@{prefix}_Insert", b?.CoInsert == true ? 1 : 0);
            cmd.Parameters.AddWithValue($"@{prefix}_Update", b?.CoUpdate == true ? 1 : 0);
            cmd.Parameters.AddWithValue($"@{prefix}_Delete", b?.CoDelete == true ? 1 : 0);
        }

        // ─── Tab 2: Load danh sách role ───────────────────────────────────────
        private void LoadRoles()
        {
            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;
            DanhSachRole.Clear();
            try
            {
                var dt = DBConnect.GetData("EXEC SP_DanhSachRole");
                foreach (DataRow row in dt.Rows)
                {
                    DanhSachRole.Add(new RoleModel
                    {
                        TenRole  = row["TenRole"].ToString(),
                        LoaiRole = row["LoaiRole"].ToString()
                    });
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi tải danh sách nhóm: " + ex.Message);
            }
        }

        // ─── Load user đang trong role được chọn ─────────────────────────────
        private void LoadUsersInRole(string tenRole)
        {
            DanhSachUserTrongRole.Clear();
            DanhSachUserChuaThuoc.Clear();
            ShowGrantPanel  = false;
            ShowRevokePanel = false;

            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;
            try
            {
                using var conn = new SqlConnection(DBConnect.ConnectionString);
                conn.Open();

                var cmd = new SqlCommand("SP_UserTrongRole", conn)
                { CommandType = CommandType.StoredProcedure };
                cmd.Parameters.AddWithValue("@TenRole", tenRole);

                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    DanhSachUserTrongRole.Add(new UserModel
                    {
                        TenUser  = reader["TenUser"].ToString(),
                        LoaiUser = reader["LoaiUser"].ToString()
                    });
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi tải user trong nhóm: " + ex.Message);
            }
        }

        // ─── Load tất cả user (để hiển thị datagrid bên phải khi Revoke) ────
        private void LoadAllUsers()
        {
            // Tái dụng SP_DanhSachUser; sẽ được gọi khi cần ở panel Revoke
        }

        // ─── Nút Grant: hiện bảng user CHƯA thuộc role ───────────────────────
        private void ExecuteGrant()
        {
            if (SelectedRole == null) return;
            DanhSachUserChuaThuoc.Clear();
            ShowRevokePanel = false;

            try
            {
                using var conn = new SqlConnection(DBConnect.ConnectionString);
                conn.Open();

                var cmd = new SqlCommand("SP_UserChuaThuocRole", conn)
                { CommandType = CommandType.StoredProcedure };
                cmd.Parameters.AddWithValue("@TenRole", SelectedRole.TenRole);

                using var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    DanhSachUserChuaThuoc.Add(new UserModel
                    {
                        TenUser  = reader["TenUser"].ToString(),
                        LoaiUser = reader["LoaiUser"].ToString(),
                        IsSelected = false
                    });
                }

                ShowGrantPanel = true;
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi tải danh sách user: " + ex.Message);
            }
        }

        // ─── Nút Revoke: hiện bảng user ĐANG trong role ──────────────────────
        private void ExecuteRevoke()
        {
            if (SelectedRole == null) return;
            DanhSachUserChuaThuoc.Clear();
            ShowGrantPanel = false;

            // Dùng lại DanhSachUserTrongRole, đặt IsSelected để user tick
            foreach (var u in DanhSachUserTrongRole)
                u.IsSelected = false;

            ShowRevokePanel = true;
        }

        // ─── Nút Lưu: thực hiện Grant hoặc Revoke tùy panel đang hiển thị ───
        private void ExecuteLuuUser()
        {
            if (SelectedRole == null) return;
            if (!DBConnect.RequireAdmin("Phân quyền nhóm")) return;

            try
            {
                using var conn = new SqlConnection(DBConnect.ConnectionString);
                conn.Open();

                int dem = 0;

                if (ShowGrantPanel)
                {
                    // Grant các user được check
                    foreach (var u in DanhSachUserChuaThuoc.Where(x => x.IsSelected))
                    {
                        var cmd = new SqlCommand("SP_GrantUserVaoRole", conn)
                        { CommandType = CommandType.StoredProcedure };
                        cmd.Parameters.AddWithValue("@TenUser", u.TenUser);
                        cmd.Parameters.AddWithValue("@TenRole", SelectedRole.TenRole);
                        cmd.ExecuteNonQuery();
                        dem++;
                    }
                    MessageBox.Show($"Đã grant {dem} user vào nhóm [{SelectedRole.TenRole}]!", "Thành công");
                }
                else if (ShowRevokePanel)
                {
                    // Revoke các user được check
                    foreach (var u in DanhSachUserTrongRole.Where(x => x.IsSelected))
                    {
                        // Lệnh cũ: Xóa user khỏi Role
                        var cmd = new SqlCommand("SP_RevokeUserKhoiRole", conn)
                        { CommandType = CommandType.StoredProcedure };
                        cmd.Parameters.AddWithValue("@TenUser", u.TenUser);
                        cmd.Parameters.AddWithValue("@TenRole", SelectedRole.TenRole);
                        cmd.ExecuteNonQuery();

                        // Dọn sạch mọi quyền trực tiếp đã từng cấp riêng cho user này
                        var cmdClear = new SqlCommand("SP_XoaQuyenTrucTiepCuaUser", conn)
                        { CommandType = CommandType.StoredProcedure };
                        cmdClear.Parameters.AddWithValue("@TenUser", u.TenUser);
                        cmdClear.ExecuteNonQuery();

                        dem++;
                    }
                    MessageBox.Show($"Đã revoke {dem} user khỏi nhóm [{SelectedRole.TenRole}]!", "Thành công");
                }

                // Reload
                LoadUsersInRole(SelectedRole.TenRole);
                ShowGrantPanel  = false;
                ShowRevokePanel = false;
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi cập nhật nhóm: " + ex.Message);
            }
        }

        private void ExecuteHuyUser()
        {
            ShowGrantPanel  = false;
            ShowRevokePanel = false;
            DanhSachUserChuaThuoc.Clear();
            foreach (var u in DanhSachUserTrongRole)
                u.IsSelected = false;
        }
    }
}
