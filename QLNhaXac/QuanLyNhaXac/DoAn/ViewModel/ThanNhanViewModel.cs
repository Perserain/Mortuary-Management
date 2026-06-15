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
    public class ThanNhanViewModel : BaseViewModel
    {
        // ──────────────────────────────────────────────
        //  Collections
        // ──────────────────────────────────────────────
        public ObservableCollection<ThanNhanModel> DSThanNhan { get; set; } = new();
        public ObservableCollection<ThiHaiModel> DSThiHai { get; set; } = new();

        // ──────────────────────────────────────────────
        //  Thi hài đang chọn ở ComboBox
        // ──────────────────────────────────────────────
        private ThiHaiModel _selectedThiHai;
        public ThiHaiModel SelectedThiHai
        {
            get => _selectedThiHai;
            set
            {
                _selectedThiHai = value;
                OnPropertyChanged();
                LoadThanNhan();   // tự tải danh sách thân nhân khi đổi thi hài
            }
        }

        // ──────────────────────────────────────────────
        //  Dòng đang chọn trong DataGrid
        // ──────────────────────────────────────────────
        private ThanNhanModel _selected;
        public ThanNhanModel Selected
        {
            get => _selected;
            set
            {
                _selected = value;
                OnPropertyChanged();
                if (_selected != null) PopulateForm(_selected);
            }
        }

        // ──────────────────────────────────────────────
        //  Form fields (binding 2 chiều)
        // ──────────────────────────────────────────────
        private string _matn;
        public string MATN
        {
            get => _matn;
            set { _matn = value; OnPropertyChanged(); }
        }

        private string _hotentn;
        public string HOTEN_TN
        {
            get => _hotentn;
            set { _hotentn = value; OnPropertyChanged(); }
        }

        private string _quanhe;
        public string QUANHE
        {
            get => _quanhe;
            set { _quanhe = value; OnPropertyChanged(); }
        }

        private string _dienthoai;
        public string DIENTHOAI
        {
            get => _dienthoai;
            set { _dienthoai = value; OnPropertyChanged(); }
        }

        private string _diachi;
        public string DIACHI
        {
            get => _diachi;
            set { _diachi = value; OnPropertyChanged(); }
        }

        private bool _laliendhe;
        public bool LALIENDHE
        {
            get => _laliendhe;
            set { _laliendhe = value; OnPropertyChanged(); }
        }

        private string _ghichu;
        public string GHICHU
        {
            get => _ghichu;
            set { _ghichu = value; OnPropertyChanged(); }
        }

        // Thông báo số lượng
        private string _soLuong = "Chưa chọn thi hài";
        public string SoLuong
        {
            get => _soLuong;
            set { _soLuong = value; OnPropertyChanged(); }
        }

        // ──────────────────────────────────────────────
        //  Commands
        // ──────────────────────────────────────────────
        public ICommand ThemCommand { get; set; }
        public ICommand SuaCommand { get; set; }
        public ICommand XoaCommand { get; set; }
        public ICommand LamMoiCommand { get; set; }
        public ICommand TaiLaiCommand { get; set; }

        // ──────────────────────────────────────────────
        //  Constructor
        // ──────────────────────────────────────────────
        public ThanNhanViewModel()
        {
            ThemCommand = new RelayCommand(p => ExecuteThem(),
                                             p => SelectedThiHai != null && !string.IsNullOrWhiteSpace(HOTEN_TN));
            SuaCommand = new RelayCommand(p => ExecuteSua(),
                                             p => Selected != null);
            XoaCommand = new RelayCommand(p => ExecuteXoa(),
                                             p => Selected != null);
            LamMoiCommand = new RelayCommand(p => ResetForm());
            TaiLaiCommand = new RelayCommand(p => LoadThanNhan());

            LoadDSThiHai();
        }

        // ──────────────────────────────────────────────
        //  Load danh sách thi hài vào ComboBox
        // ──────────────────────────────────────────────
        private void LoadDSThiHai()
        {
            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;
            DSThiHai.Clear();
            try
            {
                DataTable dt = DBConnect.GetData("EXEC SP_DSThiHai");
                foreach (DataRow row in dt.Rows)
                {
                    DSThiHai.Add(new ThiHaiModel
                    {
                        MaTH = row["MATH"].ToString(),
                        HoTenTH = row["HOTEN_TH"].ToString()
                    });
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi tải danh sách thi hài: " + ex.Message, "Lỗi");
            }
        }

        // ──────────────────────────────────────────────
        //  Load thân nhân theo thi hài đang chọn
        // ──────────────────────────────────────────────
        private void LoadThanNhan()
        {
            DSThanNhan.Clear();
            ResetForm();

            if (SelectedThiHai == null)
            {
                SoLuong = "Chưa chọn thi hài";
                return;
            }

            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;

            try
            {
                using var conn = new SqlConnection(DBConnect.ConnectionString);
                conn.Open();
                using var cmd = new SqlCommand("SP_DSThanNhan", conn)
                {
                    CommandType = CommandType.StoredProcedure
                };
                cmd.Parameters.AddWithValue("@MATH", SelectedThiHai.MaTH);

                using var da = new SqlDataAdapter(cmd);
                var dt = new DataTable();
                da.Fill(dt);

                foreach (DataRow row in dt.Rows)
                {
                    DSThanNhan.Add(new ThanNhanModel
                    {
                        MATN = row["MATN"].ToString(),
                        MATH = row["MATH"].ToString(),
                        HOTEN_TN = row["HOTEN_TN"].ToString(),
                        QUANHE = row["QUANHE"].ToString(),
                        DIENTHOAI = row["DIENTHOAI"].ToString(),
                        DIACHI = row["DIACHI"].ToString(),
                        LALIENDHE = row["LALIENDHE"] != DBNull.Value && (bool)row["LALIENDHE"],
                        GHICHU = row["GHICHU"].ToString(),
                        HOTEN_TH = row["HOTEN_TH"].ToString(),
                        TRANGTHAI = row["TRANGTHAI"].ToString()
                    });
                }

                SoLuong = $"Tổng: {DSThanNhan.Count} thân nhân — Thi hài: {SelectedThiHai.HoTenTH}";
                GenerateMATN(); // chuẩn bị mã mới cho form Thêm
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi tải thân nhân: " + ex.Message, "Lỗi");
            }
        }

        // ──────────────────────────────────────────────
        //  Điền dữ liệu từ dòng đang chọn vào form
        // ──────────────────────────────────────────────
        private void PopulateForm(ThanNhanModel tn)
        {
            MATN = tn.MATN;
            HOTEN_TN = tn.HOTEN_TN;
            QUANHE = tn.QUANHE;
            DIENTHOAI = tn.DIENTHOAI;
            DIACHI = tn.DIACHI;
            LALIENDHE = tn.LALIENDHE;
            GHICHU = tn.GHICHU;
        }

        // ──────────────────────────────────────────────
        //  Reset form về trạng thái Thêm mới
        // ──────────────────────────────────────────────
        private void ResetForm()
        {
            Selected = null;
            HOTEN_TN = string.Empty;
            QUANHE = string.Empty;
            DIENTHOAI = string.Empty;
            DIACHI = string.Empty;
            LALIENDHE = false;
            GHICHU = string.Empty;
            GenerateMATN();
        }

        // Tự sinh mã MATN theo pattern TN001, TN002 …
        private void GenerateMATN()
        {
            if (DSThanNhan == null || DSThanNhan.Count == 0)
            {
                MATN = "TN001";
                return;
            }
            int max = DSThanNhan
                .Select(t => {
                    if (t.MATN != null && t.MATN.StartsWith("TN") &&
                        int.TryParse(t.MATN.Substring(2), out int n)) return n;
                    return 0;
                })
                .DefaultIfEmpty(0).Max();
            MATN = $"TN{(max + 1):D3}";
        }

        // ──────────────────────────────────────────────
        //  THÊM
        // ──────────────────────────────────────────────
        private void ExecuteThem()
        {
            if (!DBConnect.RequireStaffOrAdmin("Thêm thân nhân")) return;
            if (SelectedThiHai == null) { MessageBox.Show("Vui lòng chọn thi hài.", "Thiếu thông tin", MessageBoxButton.OK, MessageBoxImage.Warning); return; }
            if (string.IsNullOrWhiteSpace(HOTEN_TN)) { MessageBox.Show("Họ tên thân nhân không được để trống.", "Thiếu thông tin", MessageBoxButton.OK, MessageBoxImage.Warning); return; }
            if (!string.IsNullOrWhiteSpace(DIENTHOAI) && !Validator.IsValidPhone(DIENTHOAI))
            {
                MessageBox.Show("Số điện thoại không hợp lệ!\nVui lòng nhập đúng định dạng VN (10 số, bắt đầu bằng 03x / 05x / 07x / 08x / 09x).",
                    "Số điện thoại không hợp lệ", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            try
            {
                using var conn = new SqlConnection(DBConnect.ConnectionString);
                conn.Open();
                using var cmd = new SqlCommand("SP_ThemThanNhan", conn)
                {
                    CommandType = CommandType.StoredProcedure
                };
                cmd.Parameters.AddWithValue("@MATN", MATN ?? string.Empty);
                cmd.Parameters.AddWithValue("@MATH", SelectedThiHai.MaTH);
                cmd.Parameters.AddWithValue("@HOTEN_TN", HOTEN_TN);
                cmd.Parameters.AddWithValue("@QUANHE", (object?)QUANHE ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@DIENTHOAI", (object?)DIENTHOAI ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@DIACHI", (object?)DIACHI ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@LALIENDHE", LALIENDHE);
                cmd.Parameters.AddWithValue("@GHICHU", (object?)GHICHU ?? DBNull.Value);

                cmd.ExecuteNonQuery();
                MessageBox.Show("Thêm thân nhân thành công!", "Thành công",
                                MessageBoxButton.OK, MessageBoxImage.Information);
                LoadThanNhan();
            }
            catch (SqlException ex) when (ex.Number == 2627)
            {
                MessageBox.Show($"Mã thân nhân '{MATN}' đã tồn tại. Vui lòng thử lại.", "Trùng mã");
                GenerateMATN();
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi thêm thân nhân: " + ex.Message, "Lỗi");
            }
        }

        // ──────────────────────────────────────────────
        //  SỬA
        // ──────────────────────────────────────────────
        private void ExecuteSua()
        {
            if (!DBConnect.RequireStaffOrAdmin("Sửa thân nhân")) return;
            if (Selected == null) return;
            if (string.IsNullOrWhiteSpace(HOTEN_TN)) { MessageBox.Show("Họ tên không được để trống.", "Thiếu thông tin", MessageBoxButton.OK, MessageBoxImage.Warning); return; }
            if (!string.IsNullOrWhiteSpace(DIENTHOAI) && !Validator.IsValidPhone(DIENTHOAI))
            {
                MessageBox.Show("Số điện thoại không hợp lệ!\nVui lòng nhập đúng định dạng VN (10 số, bắt đầu bằng 03x / 05x / 07x / 08x / 09x).",
                    "Số điện thoại không hợp lệ", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            try
            {
                using var conn = new SqlConnection(DBConnect.ConnectionString);
                conn.Open();
                using var cmd = new SqlCommand("SP_SuaThanNhan", conn)
                {
                    CommandType = CommandType.StoredProcedure
                };
                cmd.Parameters.AddWithValue("@MATN", Selected.MATN);
                cmd.Parameters.AddWithValue("@HOTEN_TN", HOTEN_TN);
                cmd.Parameters.AddWithValue("@QUANHE", (object?)QUANHE ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@DIENTHOAI", (object?)DIENTHOAI ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@DIACHI", (object?)DIACHI ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@LALIENDHE", LALIENDHE);
                cmd.Parameters.AddWithValue("@GHICHU", (object?)GHICHU ?? DBNull.Value);

                cmd.ExecuteNonQuery();
                MessageBox.Show("Cập nhật thành công!", "Thành công",
                                MessageBoxButton.OK, MessageBoxImage.Information);
                LoadThanNhan();
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi sửa thân nhân: " + ex.Message, "Lỗi");
            }
        }

        // ──────────────────────────────────────────────
        //  XÓA
        // ──────────────────────────────────────────────
        private void ExecuteXoa()
        {
            if (!DBConnect.RequireStaffOrAdmin("Xóa thân nhân")) return;
            if (Selected == null) return;

            // Ràng buộc: không xóa nếu chỉ còn 1 thân nhân
            if (DSThanNhan.Count <= 1)
            {
                MessageBox.Show(
                    "Không thể xóa — thi hài này chỉ còn 1 thân nhân duy nhất.\n" +
                    "Vui lòng thêm thân nhân khác trước khi xóa.",
                    "Cảnh báo", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            var confirm = MessageBox.Show(
                $"Xóa thân nhân '{Selected.HOTEN_TN}'?\nThao tác này không thể hoàn tác.",
                "Xác nhận xóa", MessageBoxButton.YesNo, MessageBoxImage.Question);
            if (confirm != MessageBoxResult.Yes) return;

            try
            {
                using var conn = new SqlConnection(DBConnect.ConnectionString);
                conn.Open();
                using var cmd = new SqlCommand("SP_XoaThanNhan", conn)
                {
                    CommandType = CommandType.StoredProcedure
                };
                cmd.Parameters.AddWithValue("@MATN", Selected.MATN);
                cmd.ExecuteNonQuery();

                MessageBox.Show("Đã xóa thân nhân.", "Thành công",
                                MessageBoxButton.OK, MessageBoxImage.Information);
                LoadThanNhan();
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi xóa thân nhân: " + ex.Message, "Lỗi");
            }
        }
    }
}