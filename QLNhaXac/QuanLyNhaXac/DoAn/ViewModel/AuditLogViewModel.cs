using DoAn.Core;
using DoAn.Model;
using Microsoft.Data.SqlClient;
using System;
using System.Collections.ObjectModel;
using System.Data;
using System.Windows;
using System.Windows.Input;

namespace DoAn.ViewModel
{
    public class AuditLogViewModel : BaseViewModel
    {
        // ===================== COLLECTIONS =====================
        public ObservableCollection<AuditLogModel> DanhSachLog { get; set; }
        public ObservableCollection<string> DanhSachTable { get; set; }

        // ===================== SELECTED =====================
        private AuditLogModel _selectedLog;
        public AuditLogModel SelectedLog
        {
            get => _selectedLog;
            set { _selectedLog = value; OnPropertyChanged(); }
        }

        // ===================== FILTER FIELDS =====================
        private string _filterTable = "";
        public string FilterTable
        {
            get => _filterTable;
            set { _filterTable = value; OnPropertyChanged(); }
        }

        private DateTime? _tuNgay;
        public DateTime? TuNgay
        {
            get => _tuNgay;
            set { _tuNgay = value; OnPropertyChanged(); }
        }

        private DateTime? _denNgay;
        public DateTime? DenNgay
        {
            get => _denNgay;
            set { _denNgay = value; OnPropertyChanged(); }
        }

        private int _soLuong = 200;
        public int SoLuong
        {
            get => _soLuong;
            set { _soLuong = value; OnPropertyChanged(); }
        }

        private int _soNgayGiu = 90;
        public int SoNgayGiu
        {
            get => _soNgayGiu;
            set { _soNgayGiu = value; OnPropertyChanged(); }
        }

        // ===================== THỐNG KÊ =====================
        private int _tongInsert;
        public int TongInsert
        {
            get => _tongInsert;
            set { _tongInsert = value; OnPropertyChanged(); }
        }

        private int _tongUpdate;
        public int TongUpdate
        {
            get => _tongUpdate;
            set { _tongUpdate = value; OnPropertyChanged(); }
        }

        private int _tongDelete;
        public int TongDelete
        {
            get => _tongDelete;
            set { _tongDelete = value; OnPropertyChanged(); }
        }

        // ===================== COMMANDS =====================
        public ICommand LocCommand      { get; set; }
        public ICommand ResetCommand    { get; set; }
        public ICommand XoaLogCuCommand { get; set; }

        // ===================== CONSTRUCTOR =====================
        public AuditLogViewModel()
        {
            DanhSachLog = new ObservableCollection<AuditLogModel>();

            // Danh sách bảng để lọc
            DanhSachTable = new ObservableCollection<string>
            {
                "(Tất cả)",
                "THIHAI",
                "BACSI",
                "DICHVU",
                "NGANTU",
                "THAN_NHAN",
                "HOADON",
                "SUDUNG",
                "HOSOKB",
                "NHANVIEN",
                "CANH_BAO"
            };
            FilterTable = "(Tất cả)";

            // Mặc định: từ 30 ngày trước đến hôm nay
            TuNgay  = DateTime.Today.AddDays(-30);
            DenNgay = DateTime.Today;

            LocCommand      = new RelayCommand(p => ExecuteLoc());
            ResetCommand    = new RelayCommand(p => ExecuteReset());
            XoaLogCuCommand = new RelayCommand(p => ExecuteXoaLogCu());

            ExecuteLoc();
        }

        // ===================== LỌC / TẢI DỮ LIỆU =====================
        private void ExecuteLoc()
        {
            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;
            DanhSachLog.Clear();

            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    var cmd = new SqlCommand("SP_XemAuditLog", conn)
                    {
                        CommandType = CommandType.StoredProcedure
                    };

                    // @TENTABLE: null nếu chọn "Tất cả"
                    string tableParam = (FilterTable == "(Tất cả)" || string.IsNullOrEmpty(FilterTable))
                        ? null : FilterTable;
                    cmd.Parameters.AddWithValue("@TENTABLE", (object)tableParam ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@TuNgay",   TuNgay.HasValue  ? (object)TuNgay.Value  : DBNull.Value);
                    cmd.Parameters.AddWithValue("@DenNgay",  DenNgay.HasValue ? (object)DenNgay.Value : DBNull.Value);
                    cmd.Parameters.AddWithValue("@SoLuong",  SoLuong);

                    using (var da = new SqlDataAdapter(cmd))
                    {
                        var dt = new DataTable();
                        da.Fill(dt);

                        int ins = 0, upd = 0, del = 0;
                        foreach (DataRow row in dt.Rows)
                        {
                            string hd = row["HANHDOG"]?.ToString() ?? "";
                            var log = new AuditLogModel
                            {
                                MALOG    = Convert.ToInt64(row["MALOG"]),
                                THOIGIAN = row["THOIGIAN"] != DBNull.Value
                                           ? Convert.ToDateTime(row["THOIGIAN"]).ToString("dd/MM/yyyy HH:mm:ss")
                                           : "",
                                TENUSER  = row["TENUSER"].ToString(),
                                TENTABLE = row["TENTABLE"].ToString(),
                                HANHDOG  = hd,
                                MABANGHI = row["MABANGHI"]?.ToString() ?? "",
                                NOIDUNG  = row["NOIDUNG"]?.ToString() ?? ""
                            };
                            DanhSachLog.Add(log);

                            if (hd == "INSERT") ins++;
                            else if (hd == "UPDATE") upd++;
                            else if (hd == "DELETE") del++;
                        }

                        TongInsert = ins;
                        TongUpdate = upd;
                        TongDelete = del;
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi tải audit log: " + ex.Message);
            }
        }

        // ===================== RESET FILTER =====================
        private void ExecuteReset()
        {
            FilterTable = "(Tất cả)";
            TuNgay      = DateTime.Today.AddDays(-30);
            DenNgay     = DateTime.Today;
            SoLuong     = 200;
            ExecuteLoc();
        }

        // ===================== XÓA LOG CŨ =====================
        private void ExecuteXoaLogCu()
        {
            if (!DBConnect.RequireAdmin("Xóa Audit Log cũ")) return;

            var confirm = MessageBox.Show(
                $"Xóa toàn bộ log cũ hơn {SoNgayGiu} ngày?\n\nHành động này KHÔNG thể hoàn tác!",
                "Xác nhận xóa log cũ",
                MessageBoxButton.YesNo,
                MessageBoxImage.Warning);

            if (confirm != MessageBoxResult.Yes) return;

            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    var cmd = new SqlCommand("SP_XoaAuditLogCu", conn)
                    {
                        CommandType = CommandType.StoredProcedure
                    };
                    cmd.Parameters.AddWithValue("@SoNgayGiu", SoNgayGiu);
                    cmd.ExecuteNonQuery();
                }
                MessageBox.Show($"Đã xóa log cũ hơn {SoNgayGiu} ngày thành công!", "Hoàn tất");
                ExecuteLoc(); // Tải lại danh sách
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi: " + ex.Message);
            }
        }
    }
}
