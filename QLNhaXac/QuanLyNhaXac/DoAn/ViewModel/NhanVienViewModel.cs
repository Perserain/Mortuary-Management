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
    public class NhanVienViewModel : BaseViewModel
    {
        // ===================== COLLECTIONS =====================
        public ObservableCollection<NhanVienModel> DanhSachNhanVien { get; set; }
        public ObservableCollection<string> DanhSachChucVu { get; set; }

        // ===================== SELECTED & FORM =====================
        private NhanVienModel _selectedNhanVien;
        public NhanVienModel SelectedNhanVien
        {
            get => _selectedNhanVien;
            set
            {
                if (_selectedNhanVien == value) return;

                _selectedNhanVien = value;
                OnPropertyChanged();
                if (_selectedNhanVien != null)
                {
                    NewNhanVien = new NhanVienModel
                    {
                        MANV = _selectedNhanVien.MANV,
                        HOTEN_NV = _selectedNhanVien.HOTEN_NV,
                        CHUCVU = _selectedNhanVien.CHUCVU,
                        DIENTHOAI = _selectedNhanVien.DIENTHOAI
                    };
                }
                else
                {
                    ResetForm();
                }
            }
        }

        private NhanVienModel _newNhanVien;
        public NhanVienModel NewNhanVien
        {
            get => _newNhanVien;
            set { _newNhanVien = value; OnPropertyChanged(); }
        }

        // ===================== SEARCH =====================
        private string _tuKhoa = "";
        public string TuKhoa
        {
            get => _tuKhoa;
            set { _tuKhoa = value; OnPropertyChanged(); ApplyFilter(); }
        }

        private ObservableCollection<NhanVienModel> _allNhanVien;

        // ===================== COMMANDS =====================
        public ICommand ThemCommand   { get; set; }
        public ICommand SuaCommand    { get; set; }
        public ICommand XoaCommand    { get; set; }
        public ICommand LamMoiCommand { get; set; }

        // ===================== CONSTRUCTOR =====================
        public NhanVienViewModel()
        {
            DanhSachNhanVien = new ObservableCollection<NhanVienModel>();
            _allNhanVien     = new ObservableCollection<NhanVienModel>();

            DanhSachChucVu = new ObservableCollection<string>
            {
                "Lễ tân",
                "Nhân viên chăm sóc thi hài",
                "Kế toán",
                "Bảo vệ",
                "Quản lý kho lạnh",
                "Y tá hỗ trợ",
                "Nhân viên vệ sinh",
                "Khác"
            };

            NewNhanVien = new NhanVienModel();

            ThemCommand   = new RelayCommand(p => ExecuteThem(),  p => CanThem());
            SuaCommand    = new RelayCommand(p => ExecuteSua(),   p => SelectedNhanVien != null && !string.IsNullOrEmpty(NewNhanVien?.MANV));
            XoaCommand    = new RelayCommand(p => ExecuteXoa(),   p => SelectedNhanVien != null && !string.IsNullOrEmpty(NewNhanVien?.MANV));
            LamMoiCommand = new RelayCommand(p => { TuKhoa = ""; LoadData(); });

            LoadData();
            ResetForm();
        }

        // ===================== LOAD DATA =====================
        private void LoadData()
        {
            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;
            _allNhanVien.Clear();
            DanhSachNhanVien.Clear();

            DataTable dt = DBConnect.GetData("EXEC SP_DSNhanVien");
            foreach (DataRow row in dt.Rows)
            {
                var nv = new NhanVienModel
                {
                    MANV      = row["MANV"].ToString(),
                    HOTEN_NV  = row["HOTEN_NV"].ToString(),
                    CHUCVU    = row["CHUCVU"].ToString(),
                    DIENTHOAI = row["DIENTHOAI"]?.ToString() ?? ""
                };
                _allNhanVien.Add(nv);
                DanhSachNhanVien.Add(nv);
            }
        }

        // ===================== FILTER =====================
        private void ApplyFilter()
        {
            DanhSachNhanVien.Clear();
            var kw = TuKhoa.Trim().ToLower();
            foreach (var nv in _allNhanVien)
            {
                if (string.IsNullOrEmpty(kw)
                    || (nv.HOTEN_NV?.ToLower().Contains(kw) == true)
                    || (nv.MANV?.ToLower().Contains(kw) == true)
                    || (nv.CHUCVU?.ToLower().Contains(kw) == true)
                    || (nv.DIENTHOAI?.Contains(kw) == true))
                {
                    DanhSachNhanVien.Add(nv);
                }
            }
        }

        // ===================== AUTO-ID =====================
        private string TaoMaNV()
        {
            if (_allNhanVien == null || _allNhanVien.Count == 0) return "NV001";
            var maxId = _allNhanVien
                .Select(n => {
                    if (n.MANV != null && n.MANV.StartsWith("NV") && int.TryParse(n.MANV.Substring(2), out int num))
                        return num;
                    return 0;
                })
                .DefaultIfEmpty(0)
                .Max();
            return $"NV{(maxId + 1):D3}";
        }

        private void ResetForm()
        {
            _selectedNhanVien = null; // Dùng biến có dấu gạch dưới
            OnPropertyChanged(nameof(SelectedNhanVien)); // Báo cho UI biết để xóa bôi xanh
            NewNhanVien = new NhanVienModel { MANV = TaoMaNV() };
        }

        // ===================== VALIDATION =====================
        private bool CanThem()
        {
            return NewNhanVien != null
                && !string.IsNullOrWhiteSpace(NewNhanVien.MANV)
                && !string.IsNullOrWhiteSpace(NewNhanVien.HOTEN_NV);
        }

        // ===================== THÊM =====================
        private void ExecuteThem()
        {
            if (!DBConnect.RequireAdmin("Thêm nhân viên")) return;
            if (!string.IsNullOrWhiteSpace(NewNhanVien.DIENTHOAI) && !Validator.IsValidPhone(NewNhanVien.DIENTHOAI))
            {
                MessageBox.Show("Số điện thoại không hợp lệ!\nVui lòng nhập đúng định dạng VN (10 số, bắt đầu bằng 03x / 05x / 07x / 08x / 09x).",
                    "Số điện thoại không hợp lệ", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    var cmd = new SqlCommand("EXEC SP_ThemNhanVien @MANV, @HOTEN_NV, @CHUCVU, @DIENTHOAI", conn);
                    cmd.Parameters.AddWithValue("@MANV",      NewNhanVien.MANV.Trim());
                    cmd.Parameters.AddWithValue("@HOTEN_NV",  NewNhanVien.HOTEN_NV.Trim());
                    cmd.Parameters.AddWithValue("@CHUCVU",    string.IsNullOrWhiteSpace(NewNhanVien.CHUCVU)    ? (object)DBNull.Value : NewNhanVien.CHUCVU);
                    cmd.Parameters.AddWithValue("@DIENTHOAI", string.IsNullOrWhiteSpace(NewNhanVien.DIENTHOAI) ? (object)DBNull.Value : NewNhanVien.DIENTHOAI.Trim());
                    cmd.ExecuteNonQuery();
                }
                MessageBox.Show($"Đã thêm nhân viên {NewNhanVien.HOTEN_NV} thành công!", "Thành công");
                LoadData();
                ResetForm();
            }
            catch (SqlException ex) when (ex.Number == 2627)
            {
                MessageBox.Show($"Mã nhân viên \"{NewNhanVien.MANV}\" đã tồn tại!", "Trùng mã");
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi: " + ex.Message);
            }
        }

        // ===================== SỬA =====================
        private void ExecuteSua()
        {
            if (!DBConnect.RequireAdmin("Sửa nhân viên")) return;
            if (string.IsNullOrWhiteSpace(NewNhanVien.HOTEN_NV))
            {
                MessageBox.Show("Họ tên không được để trống!", "Thiếu thông tin");
                return;
            }
            if (!string.IsNullOrWhiteSpace(NewNhanVien.DIENTHOAI) && !Validator.IsValidPhone(NewNhanVien.DIENTHOAI))
            {
                MessageBox.Show("Số điện thoại không hợp lệ!\nVui lòng nhập đúng định dạng VN (10 số, bắt đầu bằng 03x / 05x / 07x / 08x / 09x).",
                    "Số điện thoại không hợp lệ", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    var cmd = new SqlCommand("EXEC SP_SuaNhanVien @MANV, @HOTEN_NV, @CHUCVU, @DIENTHOAI", conn);
                    cmd.Parameters.AddWithValue("@MANV",      NewNhanVien.MANV);
                    cmd.Parameters.AddWithValue("@HOTEN_NV",  NewNhanVien.HOTEN_NV.Trim());
                    cmd.Parameters.AddWithValue("@CHUCVU",    string.IsNullOrWhiteSpace(NewNhanVien.CHUCVU)    ? (object)DBNull.Value : NewNhanVien.CHUCVU);
                    cmd.Parameters.AddWithValue("@DIENTHOAI", string.IsNullOrWhiteSpace(NewNhanVien.DIENTHOAI) ? (object)DBNull.Value : NewNhanVien.DIENTHOAI.Trim());
                    int rows = cmd.ExecuteNonQuery();

                    if (rows > 0)
                    {
                        MessageBox.Show($"Đã cập nhật thông tin nhân viên {NewNhanVien.MANV}!", "Thành công");
                        LoadData();
                        ResetForm();
                    }
                    else
                    {
                        MessageBox.Show("Không tìm thấy nhân viên để cập nhật.", "Cảnh báo");
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi: " + ex.Message);
            }
        }

        // ===================== XÓA =====================
        private void ExecuteXoa()
        {
            if (!DBConnect.RequireAdmin("Xóa nhân viên")) return;

            var confirm = MessageBox.Show(
                $"Xóa nhân viên \"{NewNhanVien.HOTEN_NV}\" ({NewNhanVien.MANV})?",
                "Xác nhận xóa", MessageBoxButton.YesNo, MessageBoxImage.Warning);

            if (confirm != MessageBoxResult.Yes) return;

            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    var cmd = new SqlCommand("EXEC SP_XoaNhanVien @MANV", conn);
                    cmd.Parameters.AddWithValue("@MANV", NewNhanVien.MANV);
                    cmd.ExecuteNonQuery();
                }
                MessageBox.Show("Đã xóa nhân viên thành công!", "Hoàn tất");
                LoadData();
                ResetForm();
            }
            catch (SqlException ex) when (ex.Number == 547)
            {
                MessageBox.Show("Không thể xóa! Nhân viên này đang được tham chiếu bởi dữ liệu khác.", "Ràng buộc dữ liệu");
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi: " + ex.Message);
            }
        }
    }
}
