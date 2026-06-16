using ClosedXML.Excel;
using DoAn.Core;
using DoAn.Model;
using DoAn.Views.Shared;
using System;
using System.Collections.ObjectModel;
using System.Data;
using System.Linq;
using Microsoft.Data.SqlClient;
using System.Windows;
using System.Windows.Input;

namespace DoAn.ViewModel
{
    public class HoSoKBViewModel : BaseViewModel
    {
        public ObservableCollection<HoSoKBModel> DanhSachHoSo { get; set; }
        public ObservableCollection<KhamNghiemTheoBacSiModel> DanhSachKhamNghiemTheoBacSi { get; set; }
        public ObservableCollection<KhamNghiemTheoTuThiModel> DanhSachKhamNghiemTheoTuThi { get; set; }
        public ObservableCollection<BacSiModel> DanhSachBacSi { get; set; }

        private BacSiModel _selectedBacSi;
        public BacSiModel SelectedBacSi
        {
            get => _selectedBacSi;
            set
            {
                _selectedBacSi = value;
                OnPropertyChanged();
                // Gán ngược về NewHoSo.MaBS để SP call vẫn dùng được
                if (NewHoSo != null)
                    NewHoSo.MaBS = value?.MaBS ?? string.Empty;
            }
        }

        private string _maBSTraCuu;
        public string MaBSTraCuu
        {
            get => _maBSTraCuu;
            set { _maBSTraCuu = value; OnPropertyChanged(); }
        }

        private string _maTHTraCuu;
        public string MaTHTraCuu
        {
            get => _maTHTraCuu;
            set { _maTHTraCuu = value; OnPropertyChanged(); }
        }

        private HoSoKBModel _newHoSo;
        public HoSoKBModel NewHoSo
        {
            get => _newHoSo;
            set { _newHoSo = value; OnPropertyChanged(); }
        }

        private HoSoKBModel _selectedHoSo;
        public HoSoKBModel SelectedHoSo
        {
            get => _selectedHoSo;
            set
            {
                _selectedHoSo = value;
                OnPropertyChanged();
                if (_selectedHoSo != null)
                {
                    NewHoSo = new HoSoKBModel
                    {
                        MaHS = _selectedHoSo.MaHS,
                        MaTH = _selectedHoSo.MaTH,
                        MaBS = _selectedHoSo.MaBS,
                        KetLuan = _selectedHoSo.KetLuan,
                        TgKham = _selectedHoSo.TgKham
                    };
                    // Đồng bộ ComboBox bác sĩ về đúng mục đang chọn
                    _selectedBacSi = DanhSachBacSi.FirstOrDefault(b => b.MaBS == _selectedHoSo.MaBS);
                    OnPropertyChanged(nameof(SelectedBacSi));
                }
                else
                {
                    ResetForm();
                }
            }
        }

        public ICommand LoadCommand { get; set; }
        public ICommand ThemCommand { get; set; }
        public ICommand SuaCommand { get; set; }
        public ICommand XoaCommand { get; set; }
        public ICommand XuatExcelCommand { get; set; }
        public ICommand NhapTuFileCommand { get; set; }
        public ICommand XemChiTietCommand { get; set; }
        public ICommand TraCuuTheoBacSiCommand { get; set; }
        public ICommand TraCuuTheoTuThiCommand { get; set; }
        public ICommand LamMoiTraCuuCommand { get; set; }

        public HoSoKBViewModel()
        {
            DanhSachHoSo = new ObservableCollection<HoSoKBModel>();
            DanhSachKhamNghiemTheoBacSi = new ObservableCollection<KhamNghiemTheoBacSiModel>();
            DanhSachKhamNghiemTheoTuThi = new ObservableCollection<KhamNghiemTheoTuThiModel>();
            DanhSachBacSi = new ObservableCollection<BacSiModel>();

            LoadCommand = new RelayCommand(p => LoadData());
            ThemCommand = new RelayCommand(p => ThemHoSo());
            SuaCommand = new RelayCommand(p => SuaHoSo());
            XoaCommand = new RelayCommand(p => XoaHoSo());
            XuatExcelCommand = new RelayCommand(p => XuatExcel());
            NhapTuFileCommand = new RelayCommand(p => NhapTuFile());
            XemChiTietCommand = new RelayCommand(p => XemChiTiet());
            TraCuuTheoBacSiCommand = new RelayCommand(p => TraCuuTheoBacSi());
            TraCuuTheoTuThiCommand = new RelayCommand(p => TraCuuTheoTuThi());
            LamMoiTraCuuCommand = new RelayCommand(p => LamMoiTraCuu());

            LoadData();
            LoadDanhSachBacSi();
            ResetForm();
        }

        private void LoadData()
        {
            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;
            DanhSachHoSo.Clear();
            string sql = "EXEC SP_DSHoSoKhamNghiem";
            DataTable dt = DBConnect.GetData(sql);

            foreach (DataRow row in dt.Rows)
            {
                DanhSachHoSo.Add(new HoSoKBModel
                {
                    MaHS = row["MAHS"].ToString(),
                    MaTH = row["MATH"].ToString(),
                    MaBS = row["MABS"].ToString(),
                    KetLuan = row["KETLUAN"].ToString(),
                    TgKham = row["THOIGIANKHAM"] != DBNull.Value ? (DateTime?)row["THOIGIANKHAM"] : null
                });
            }
        }

        private void LoadDanhSachBacSi()
        {
            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;
            DanhSachBacSi.Clear();
            try
            {
                DataTable dt = DBConnect.GetData("SELECT MABS, HOTEN_BS FROM BACSI ORDER BY HOTEN_BS");
                foreach (DataRow row in dt.Rows)
                {
                    DanhSachBacSi.Add(new BacSiModel
                    {
                        MaBS = row["MABS"].ToString(),
                        HoTenBS = row["HOTEN_BS"].ToString()
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Lỗi tải danh sách bác sĩ: " + ex.Message);
            }
        }

        private void XemChiTiet()
        {
            DetailWindow f = new DetailWindow(NewHoSo, "CHI TIẾT HỒ SƠ KHÁM");
            f.ShowDialog();
        }

        private string TaoMaHS()
        {
            if (DanhSachHoSo == null || DanhSachHoSo.Count == 0) return "HS001";

            var maxId = DanhSachHoSo
                .Select(h => {
                    if (h.MaHS != null && h.MaHS.StartsWith("HS") && int.TryParse(h.MaHS.Substring(2), out int num))
                        return num;
                    return 0;
                })
                .DefaultIfEmpty(0)
                .Max();

            return $"HS{(maxId + 1):D3}";
        }
        private void ResetForm()
        {
            NewHoSo = new HoSoKBModel { TgKham = DateTime.Now }; 
            NewHoSo.MaHS = TaoMaHS();
            _selectedBacSi = null;
            OnPropertyChanged(nameof(SelectedBacSi));
        }

        private void ThemHoSo()
        {
            if (!DBConnect.RequireAdmin("Thêm hồ sơ khám")) return;
            if (string.IsNullOrWhiteSpace(NewHoSo.MaTH) || string.IsNullOrWhiteSpace(NewHoSo.MaBS))
            {
                MessageBox.Show("Nhập thiếu Mã HS, Mã Thi Hài hoặc Mã Bác Sĩ!");
                return;
            }

            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    // Dùng CommandType.StoredProcedure để tránh mọi lỗi cú pháp SQL
                    var cmd = new SqlCommand("SP_ThemHoSoKhamBenh_V2", conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@MAHS", NewHoSo.MaHS);
                    cmd.Parameters.AddWithValue("@THOIGIANKHAM", NewHoSo.TgKham ?? (object)DBNull.Value);
                    cmd.Parameters.AddWithValue("@KETLUAN", string.IsNullOrWhiteSpace(NewHoSo.KetLuan) ? DBNull.Value : (object)NewHoSo.KetLuan);
                    cmd.Parameters.AddWithValue("@MATH", NewHoSo.MaTH);
                    cmd.Parameters.AddWithValue("@MABS", NewHoSo.MaBS);

                    cmd.ExecuteNonQuery();
                    MessageBox.Show("Lập hồ sơ thành công!");
                    LoadData();
                    ResetForm();
                }
            }
            catch (SqlException ex)
            {
                if (ex.Number == 547) MessageBox.Show("Mã Thi Hài hoặc Mã Bác Sĩ không tồn tại!");
                else MessageBox.Show("Lỗi CSDL: " + ex.Message);
            }
        }

        private void SuaHoSo()
        {
            if (!DBConnect.RequireAdmin("Sửa hồ sơ khám")) return;
            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    var cmdUpdate = new SqlCommand("SP_SuaHoSoKhamBenh_V2", conn);
                    cmdUpdate.CommandType = CommandType.StoredProcedure;
                    cmdUpdate.Parameters.AddWithValue("@MAHS", NewHoSo.MaHS);
                    cmdUpdate.Parameters.AddWithValue("@THOIGIANKHAM", NewHoSo.TgKham ?? (object)DBNull.Value);
                    cmdUpdate.Parameters.AddWithValue("@KETLUAN", string.IsNullOrWhiteSpace(NewHoSo.KetLuan) ? DBNull.Value : (object)NewHoSo.KetLuan);
                    cmdUpdate.Parameters.AddWithValue("@MATH", string.IsNullOrWhiteSpace(NewHoSo.MaTH) ? DBNull.Value : (object)NewHoSo.MaTH);
                    cmdUpdate.Parameters.AddWithValue("@MABS", string.IsNullOrWhiteSpace(NewHoSo.MaBS) ? DBNull.Value : (object)NewHoSo.MaBS);

                    if (cmdUpdate.ExecuteNonQuery() > 0)
                    {
                        MessageBox.Show("Cập nhật hồ sơ thành công!");
                        LoadData();
                        ResetForm();
                    }
                }
            }
            catch (SqlException ex)
            {
                if (ex.Number == 547) MessageBox.Show("Mã Thi Hài hoặc Mã Bác Sĩ không tồn tại!");
                else MessageBox.Show("Lỗi SQL: " + ex.Message);
            }
        }

        private void XoaHoSo()
        {
            if (!DBConnect.RequireAdmin("Xóa hồ sơ khám")) return;
            if (MessageBox.Show("Xóa hồ sơ này?", "Xác nhận", MessageBoxButton.YesNo) == MessageBoxResult.Yes)
            {
                try
                {
                    using (var conn = new SqlConnection(DBConnect.ConnectionString))
                    {
                        conn.Open();
                        var cmd = new SqlCommand("EXEC SP_XoaHoSoKhamBenh @ma", conn);
                        cmd.Parameters.AddWithValue("@ma", NewHoSo.MaHS);
                        cmd.ExecuteNonQuery();

                        MessageBox.Show("Đã xóa hồ sơ!");
                        LoadData();
                        ResetForm();
                    }
                }
                catch (Exception ex) { MessageBox.Show("Lỗi: " + ex.Message); }
            }
        }

        private void XuatExcel()
        {
            if (!DBConnect.RequireAdmin("Xuất Excel hồ sơ khám")) return;

            if (DanhSachHoSo == null || DanhSachHoSo.Count == 0)
            {
                MessageBox.Show("Không có dữ liệu để xuất!", "Thông báo");
                return;
            }

            Microsoft.Win32.SaveFileDialog saveFileDialog = new Microsoft.Win32.SaveFileDialog();
            saveFileDialog.Filter = "Excel Files (*.xlsx)|*.xlsx";
            saveFileDialog.FileName = "DanhSach_HoSoKham.xlsx";

            if (saveFileDialog.ShowDialog() == true)
            {
                try
                {
                    using (var workbook = new XLWorkbook())
                    {
                        var worksheet = workbook.Worksheets.Add("Danh sách Hồ Sơ");

                        // 1. Tạo Tiêu đề các cột
                        worksheet.Cell(1, 1).Value = "Mã HS";
                        worksheet.Cell(1, 2).Value = "Ngày Khám";
                        worksheet.Cell(1, 3).Value = "Kết Luận";
                        worksheet.Cell(1, 4).Value = "Mã Xác";
                        worksheet.Cell(1, 5).Value = "Bác Sĩ";

                        // Định dạng Tiêu đề (Bôi đậm, nền vàng nhạt)
                        var headerRange = worksheet.Range("A1:E1");
                        headerRange.Style.Font.Bold = true;
                        headerRange.Style.Fill.BackgroundColor = XLColor.LightYellow;
                        headerRange.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                        // 2. Đổ dữ liệu vào các dòng
                        int row = 2;
                        foreach (var hs in DanhSachHoSo)
                        {
                            worksheet.Cell(row, 1).Value = hs.MaHS;

                            // Xử lý Ngày Khám (vì có thể trống)
                            if (hs.TgKham.HasValue)
                                worksheet.Cell(row, 2).Value = hs.TgKham.Value.ToString("dd/MM/yyyy");

                            worksheet.Cell(row, 3).Value = hs.KetLuan;
                            worksheet.Cell(row, 4).Value = hs.MaTH;
                            worksheet.Cell(row, 5).Value = hs.MaBS;
                            row++;
                        }

                        // Tự động căn chỉnh độ rộng các cột cho đẹp
                        worksheet.Columns().AdjustToContents();

                        // Lưu file Excel
                        workbook.SaveAs(saveFileDialog.FileName);
                        MessageBox.Show("Xuất file Excel thành công!\nĐường dẫn: " + saveFileDialog.FileName);
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Lỗi xuất file (Vui lòng đóng file Excel nếu đang mở): " + ex.Message);
                }
            }
        }

        private void TraCuuTheoBacSi()
        {
            if (string.IsNullOrWhiteSpace(MaBSTraCuu))
            {
                MessageBox.Show("Vui lòng nhập Mã Bác Sĩ để tra cứu.");
                return;
            }

            DanhSachKhamNghiemTheoBacSi.Clear();
            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    using (var cmd = new SqlCommand("SELECT * FROM dbo.fn_DanhSachKhamNghiemTheoBacSi(@mabs)", conn))
                    {
                        cmd.Parameters.AddWithValue("@mabs", MaBSTraCuu);
                        using (var da = new SqlDataAdapter(cmd))
                        {
                            var dt = new DataTable();
                            da.Fill(dt);
                            foreach (DataRow row in dt.Rows)
                            {
                                DanhSachKhamNghiemTheoBacSi.Add(new KhamNghiemTheoBacSiModel
                                {
                                    MaTH = row["MATH"].ToString(),
                                    HoTenTH = row["HOTEN_TH"].ToString(),
                                    GioiTinh = row["GIOITINH"].ToString(),
                                    TgKham = row["THOIGIANKHAM"] != DBNull.Value ? (DateTime?)row["THOIGIANKHAM"] : null,
                                    KetLuan = row["KETLUAN"].ToString()
                                });
                            }

                            if (dt.Rows.Count == 0)
                            {
                                MessageBox.Show("Không có hồ sơ khám nghiệm cho bác sĩ này.");
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi tra cứu: " + ex.Message);
            }
        }

        private void TraCuuTheoTuThi()
        {
            if (string.IsNullOrWhiteSpace(MaTHTraCuu))
            {
                MessageBox.Show("Vui lòng nhập Mã Thi Hài để tra cứu.");
                return;
            }

            DanhSachKhamNghiemTheoTuThi.Clear();
            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    using (var cmd = new SqlCommand("SELECT * FROM dbo.fn_DanhSachKhamNghiemTheoTuThi(@math)", conn))
                    {
                        cmd.Parameters.AddWithValue("@math", MaTHTraCuu);
                        using (var da = new SqlDataAdapter(cmd))
                        {
                            var dt = new DataTable();
                            da.Fill(dt);
                            foreach (DataRow row in dt.Rows)
                            {
                                DanhSachKhamNghiemTheoTuThi.Add(new KhamNghiemTheoTuThiModel
                                {
                                    MaHS = row["MAHS"].ToString(),
                                    MaTH = row["MATH"].ToString(),
                                    MaBS = row["MABS"].ToString(),
                                    HoTenBS = row["HOTEN_BS"].ToString(),
                                    TgKham = row["THOIGIANKHAM"] != DBNull.Value ? (DateTime?)row["THOIGIANKHAM"] : null,
                                    KetLuan = row["KETLUAN"].ToString()
                                });
                            }

                            if (dt.Rows.Count == 0)
                            {
                                MessageBox.Show("Không có hồ sơ khám nghiệm cho thi hài này.");
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi tra cứu: " + ex.Message);
            }
        }

        private void LamMoiTraCuu()
        {
            MaBSTraCuu = string.Empty;
            MaTHTraCuu = string.Empty;
            DanhSachKhamNghiemTheoBacSi.Clear();
            DanhSachKhamNghiemTheoTuThi.Clear();
        }

        // --- HÀM NHẬP EXCEL
        private void NhapTuFile()
        {
            if (!DBConnect.RequireAdmin("Nhập Excel hồ sơ khám")) return;

            Microsoft.Win32.OpenFileDialog dlg = new Microsoft.Win32.OpenFileDialog();
            dlg.Filter = "Excel Files (*.xlsx)|*.xlsx";
            dlg.Title = "Chọn file Excel Hồ Sơ Khám";

            if (dlg.ShowDialog() == true)
            {
                try
                {
                    DataTable dt = new DataTable();
                    dt.Columns.Add("MAHS", typeof(string));
                    dt.Columns.Add("THOIGIANKHAM", typeof(DateTime));
                    dt.Columns.Add("KETLUAN", typeof(string));
                    dt.Columns.Add("MATH", typeof(string));
                    dt.Columns.Add("MABS", typeof(string));

                    using (var workbook = new XLWorkbook(dlg.FileName))
                    {
                        var worksheet = workbook.Worksheet(1);
                        var rows = worksheet.RangeUsed().RowsUsed();

                        bool isFirstRow = true;
                        foreach (var row in rows)
                        {
                            if (isFirstRow) // Bỏ qua dòng tiêu đề
                            {
                                isFirstRow = false;
                                continue;
                            }

                            string maHS = row.Cell(1).GetString().Trim();

                            // Xử lý ngày khám
                            string ngayKhamStr = row.Cell(2).GetString().Trim();
                            object ngayKham = DateTime.TryParse(ngayKhamStr, out DateTime nk) ? (object)nk : DBNull.Value;

                            string ketLuan = row.Cell(3).GetString().Trim();
                            string maTH = row.Cell(4).GetString().Trim();
                            string maBS = row.Cell(5).GetString().Trim();

                            // Điều kiện bắt buộc: Mã HS, Mã Thi Hài và Mã Bác Sĩ không được để trống
                            if (!string.IsNullOrEmpty(maHS) && !string.IsNullOrEmpty(maTH) && !string.IsNullOrEmpty(maBS))
                            {
                                dt.Rows.Add(maHS, ngayKham, ketLuan, maTH, maBS);
                            }
                        }
                    }

                    if (dt.Rows.Count == 0)
                    {
                        MessageBox.Show("File rỗng hoặc bạn đã để trống cột bắt buộc (Mã HS, Mã Xác, Bác Sĩ)!", "Cảnh báo");
                        return;
                    }

                    using (SqlConnection conn = new SqlConnection(DBConnect.ConnectionString))
                    {
                        conn.Open();
                        using (SqlBulkCopy bulkCopy = new SqlBulkCopy(conn))
                        {
                            bulkCopy.DestinationTableName = "HOSOKHAMBENH";

                            // Mapping các cột dữ liệu
                            bulkCopy.ColumnMappings.Add("MAHS", "MAHS");
                            bulkCopy.ColumnMappings.Add("THOIGIANKHAM", "THOIGIANKHAM");
                            bulkCopy.ColumnMappings.Add("KETLUAN", "KETLUAN");
                            bulkCopy.ColumnMappings.Add("MATH", "MATH");
                            bulkCopy.ColumnMappings.Add("MABS", "MABS");

                            bulkCopy.WriteToServer(dt);
                            MessageBox.Show($"Đã nhập thành công {dt.Rows.Count} hồ sơ từ file Excel!", "Thành công");

                            LoadData(); // Load lại Grid
                        }
                    }
                }
                catch (SqlException ex)
                {
                    if (ex.Number == 2627)
                        MessageBox.Show("Lỗi: Có mã Hồ Sơ trong file Excel đã tồn tại trong phần mềm!");
                    else if (ex.Number == 547)
                        MessageBox.Show("Lỗi: Trong file Excel có Mã Xác hoặc Mã Bác Sĩ chưa tồn tại trong hệ thống. Vui lòng kiểm tra lại!");
                    else
                        MessageBox.Show("Lỗi CSDL: " + ex.Message);
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Lỗi đọc file (Vui lòng kiểm tra định dạng ngày tháng hoặc đóng file Excel đang mở): " + ex.Message);
                }
            }
        }
    }
}
