using ClosedXML.Excel;
using DoAn.Core;
using DoAn.Model;
using DoAn.Views.Shared;
using System;
using System.Collections.ObjectModel;
using System.Data;
using Microsoft.Data.SqlClient;
using System.Windows;
using System.Windows.Input;

namespace DoAn.ViewModel
{
    class ThiHaiViewModel : BaseViewModel
    {
        public ObservableCollection<ThiHaiModel> DanhSachThiHai { get; set; }

        private ThiHaiModel _newThiHai;
        public ThiHaiModel NewThiHai
        {
            get => _newThiHai;
            set { _newThiHai = value; OnPropertyChanged(); }
        }

        private ThiHaiModel _selectedThiHai;
        public ThiHaiModel SelectedThiHai
        {
            get => _selectedThiHai;
            set
            {
                _selectedThiHai = value;
                OnPropertyChanged();

                if (_selectedThiHai != null)
                {
                    NewThiHai = new ThiHaiModel
                    {
                        MaTH = _selectedThiHai.MaTH,
                        HoTenTH = _selectedThiHai.HoTenTH,
                        GioiTinh = _selectedThiHai.GioiTinh,
                        NgaySinh = _selectedThiHai.NgaySinh,
                        NgayMat = _selectedThiHai.NgayMat
                    };
                }
                else
                {
                    ResetForm();
                }
            }
        }

        private string countThiHai = "Số lượng thi hài: 0";
        public string CountThiHai { get => countThiHai; set { countThiHai = value; OnPropertyChanged(); } }

        public ICommand LoadCommand { get; set; }
        public ICommand ThemCommand { get; set; }
        public ICommand SuaCommand { get; set; }
        public ICommand XoaCommand { get; set; }
        public ICommand XuatExcelCommand { get; set; }
        public ICommand TimSotCommand { get; set; }
        public ICommand XemChiTietCommand { get; set; }
        public ICommand NhapTuFileCommand { get; set; }
        public ICommand ThanhLyCommand { get; set; }

        public ThiHaiViewModel()
        {
            DanhSachThiHai = new ObservableCollection<ThiHaiModel>();

            LoadCommand = new RelayCommand(p => LoadData());
            ThemCommand = new RelayCommand(p => ThemThiHai(), p => NewThiHai != null && !string.IsNullOrWhiteSpace(NewThiHai.MaTH));
            SuaCommand = new RelayCommand(p => SuaThiHai(), p => NewThiHai != null && !string.IsNullOrWhiteSpace(NewThiHai.MaTH));
            XoaCommand = new RelayCommand(p => XoaThiHai(), p => NewThiHai != null && !string.IsNullOrWhiteSpace(NewThiHai.MaTH));
            XuatExcelCommand = new RelayCommand(p => XuatExcel());
            NhapTuFileCommand = new RelayCommand(p => NhapTuFile());
            TimSotCommand = new RelayCommand(p => TimSot());
            XemChiTietCommand = new RelayCommand(p => XemChiTiet(), p => NewThiHai != null && !string.IsNullOrEmpty(NewThiHai.MaTH));
            ThanhLyCommand = new RelayCommand(p => ThanhLyThiHaiHangLoat());

            LoadData();
            ResetForm();
        }
        private string TaoMaTH()
        {
            if (DanhSachThiHai == null || DanhSachThiHai.Count == 0) return "DV001";

            var maxId = DanhSachThiHai
                .Select(d => {
                    if (d.MaTH != null && d.MaTH.StartsWith("DV") && int.TryParse(d.MaTH.Substring(2), out int num))
                        return num;
                    return 0;
                })
                .DefaultIfEmpty(0)
                .Max();

            return $"DV{(maxId + 1):D3}";
        }

        private void ResetForm()
        {
            NewThiHai = new ThiHaiModel();
            NewThiHai.MaTH = TaoMaTH();
        }

        private void LoadData()
        {
            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;
            DanhSachThiHai.Clear();

            DataTable dt = DBConnect.GetData("EXEC SP_DSThiHai");

            foreach (DataRow row in dt.Rows)
            {
                DanhSachThiHai.Add(new ThiHaiModel
                {
                    MaTH = row["MATH"].ToString(),
                    HoTenTH = row["HOTEN_TH"].ToString(),
                    GioiTinh = row["GIOITINH"].ToString(),
                    NgaySinh = row["NGAYSINH"] != DBNull.Value ? (DateTime?)row["NGAYSINH"] : null,
                    NgayMat = row["NGAYMAT"] != DBNull.Value ? (DateTime?)row["NGAYMAT"] : null,
                    NhomTuoi = row["NHOMTUOI"].ToString()
                });
            }
            DemSoLuongThiHai();
        }

        private void XemChiTiet()
        {
            DetailWindow f = new DetailWindow(NewThiHai, "CHI TIẾT THI HÀI");
            f.ShowDialog();
        }

        private void ThemThiHai()
        {
            if (!DBConnect.RequireAdmin("Thêm thi hài")) return;
            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    string sql = "EXEC SP_ThemThiHai @ma, @ten, @ns, @nm, @gt";
                    var cmd = new SqlCommand(sql, conn);

                    cmd.Parameters.AddWithValue("@ma", NewThiHai.MaTH);
                    cmd.Parameters.AddWithValue("@ten", NewThiHai.HoTenTH ?? (object)DBNull.Value);
                    cmd.Parameters.AddWithValue("@gt", NewThiHai.GioiTinh ?? (object)DBNull.Value);
                    cmd.Parameters.AddWithValue("@ns", NewThiHai.NgaySinh ?? (object)DBNull.Value);
                    cmd.Parameters.AddWithValue("@nm", NewThiHai.NgayMat ?? (object)DBNull.Value);

                    cmd.ExecuteNonQuery();
                    MessageBox.Show("Thêm thành công!");
                    LoadData();
                    ResetForm();
                }
            }
            catch (Exception ex) { MessageBox.Show("Lỗi: " + ex.Message); }
        }

        private void SuaThiHai()
        {
            if (!DBConnect.RequireAdmin("Sửa thi hài")) return;
            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    string sqlUpdate = "EXEC SP_SuaThiHai @ma, @ten, @ns, @nm, @gt";
                    var cmdUpdate = new SqlCommand(sqlUpdate, conn);

                    cmdUpdate.Parameters.AddWithValue("@ma", NewThiHai.MaTH);
                    cmdUpdate.Parameters.AddWithValue("@ten", string.IsNullOrWhiteSpace(NewThiHai.HoTenTH) ? DBNull.Value : (object)NewThiHai.HoTenTH);
                    cmdUpdate.Parameters.AddWithValue("@gt", string.IsNullOrWhiteSpace(NewThiHai.GioiTinh) ? DBNull.Value : (object)NewThiHai.GioiTinh);
                    cmdUpdate.Parameters.AddWithValue("@ns", NewThiHai.NgaySinh ?? (object)DBNull.Value);
                    cmdUpdate.Parameters.AddWithValue("@nm", NewThiHai.NgayMat ?? (object)DBNull.Value);

                    if (cmdUpdate.ExecuteNonQuery() > 0)
                    {
                        MessageBox.Show("Cập nhật thành công!");
                        LoadData();
                        ResetForm();
                    }
                }
            }
            catch (Exception ex) { MessageBox.Show("Lỗi: " + ex.Message); }
        }

        private void XoaThiHai()
        {
            if (!DBConnect.RequireAdmin("Xóa thi hài")) return;
            if (MessageBox.Show("Bạn chắc chắn muốn xóa thi hài này?", "Cảnh báo", MessageBoxButton.YesNo, MessageBoxImage.Warning) == MessageBoxResult.Yes)
            {
                try
                {
                    using (var conn = new SqlConnection(DBConnect.ConnectionString))
                    {
                        conn.Open();
                        var cmd = new SqlCommand("EXEC SP_XoaThiHai @ma", conn);
                        cmd.Parameters.AddWithValue("@ma", NewThiHai.MaTH);
                        cmd.ExecuteNonQuery();

                        MessageBox.Show("Đã xóa!");
                        LoadData();
                        ResetForm();
                    }
                }
                catch (SqlException ex)
                {
                    if (ex.Number == 547) MessageBox.Show("Không thể xóa! Thi hài này đang có Hồ sơ khám hoặc đang nằm trong Ngăn kéo.");
                    else MessageBox.Show("Lỗi: " + ex.Message);
                }
            }
        }

        private void TimSot()
        {
            string sql = @"EXEC SP_ThiHaiSot";
            DataTable dt = DBConnect.GetData(sql);

            if (dt.Rows.Count > 0)
            {
                DanhSachThiHai.Clear();
                foreach (DataRow row in dt.Rows)
                {
                    DanhSachThiHai.Add(new ThiHaiModel
                    {
                        MaTH = row["MATH"].ToString(),
                        HoTenTH = row["HOTEN_TH"].ToString(),
                        GioiTinh = row["GIOITINH"].ToString(),
                        NgaySinh = row["NGAYSINH"] != DBNull.Value ? (DateTime?)row["NGAYSINH"] : null,
                        NgayMat = row["NGAYMAT"] != DBNull.Value ? (DateTime?)row["NGAYMAT"] : null,
                        NhomTuoi = row["NHOMTUOI"].ToString()
                    });
                }
                CountThiHai = "Kết quả lọc: " + DanhSachThiHai.Count.ToString();
                MessageBox.Show($"Cảnh báo: Có {dt.Rows.Count} thi hài chưa được xếp ngăn! \n(Đã lọc danh sách để bạn xử lý)");
            }
            else
            {
                MessageBox.Show("Tuyệt vời! Tất cả thi hài đều đã có chỗ nằm.");
                LoadData();
            }
        }


        private void XuatExcel()
        {
            if (!DBConnect.RequireAdmin("Xuất Excel thi hài")) return;

            if (DanhSachThiHai == null || DanhSachThiHai.Count == 0)
            {
                MessageBox.Show("Không có dữ liệu để xuất!", "Thông báo");
                return;
            }

            Microsoft.Win32.SaveFileDialog saveFileDialog = new Microsoft.Win32.SaveFileDialog();
            saveFileDialog.Filter = "Excel Files (*.xlsx)|*.xlsx";
            saveFileDialog.FileName = "DanhSach_ThiHai.xlsx";

            if (saveFileDialog.ShowDialog() == true)
            {
                try
                {
                    using (var workbook = new XLWorkbook())
                    {
                        var worksheet = workbook.Worksheets.Add("Danh sách Thi Hài");

                        // 1. Tạo Tiêu đề các cột
                        worksheet.Cell(1, 1).Value = "Mã Thi Hài";
                        worksheet.Cell(1, 2).Value = "Họ Tên";
                        worksheet.Cell(1, 3).Value = "Ngày Sinh";
                        worksheet.Cell(1, 4).Value = "Ngày Mất";
                        worksheet.Cell(1, 5).Value = "Giới Tính";

                        // Định dạng Tiêu đề
                        var headerRange = worksheet.Range("A1:E1");
                        headerRange.Style.Font.Bold = true;
                        headerRange.Style.Fill.BackgroundColor = XLColor.LightGreen; // Đổi màu xanh lá cho khác Bác sĩ
                        headerRange.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                        // 2. Đổ dữ liệu
                        int row = 2;
                        foreach (var th in DanhSachThiHai)
                        {
                            worksheet.Cell(row, 1).Value = th.MaTH;
                            worksheet.Cell(row, 2).Value = th.HoTenTH;

                            // Định dạng ngày tháng
                            if (th.NgaySinh.HasValue)
                                worksheet.Cell(row, 3).Value = th.NgaySinh.Value.ToString("dd/MM/yyyy");
                            if (th.NgayMat.HasValue)
                                worksheet.Cell(row, 4).Value = th.NgayMat.Value.ToString("dd/MM/yyyy");

                            worksheet.Cell(row, 5).Value = th.GioiTinh;
                            row++;
                        }

                        // Tự động căn chỉnh độ rộng các cột
                        worksheet.Columns().AdjustToContents();

                        // Lưu file
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

        // --- HÀM NHẬP EXCEL
        private void NhapTuFile()
        {
            if (!DBConnect.RequireAdmin("Nhập Excel thi hài")) return;

            Microsoft.Win32.OpenFileDialog dlg = new Microsoft.Win32.OpenFileDialog();
            dlg.Filter = "Excel Files (*.xlsx)|*.xlsx";
            dlg.Title = "Chọn file Excel Thi Hài";

            if (dlg.ShowDialog() == true)
            {
                try
                {
                    DataTable dt = new DataTable();
                    dt.Columns.Add("MATH", typeof(string));
                    dt.Columns.Add("HOTEN_TH", typeof(string));
                    dt.Columns.Add("NGAYSINH", typeof(DateTime));
                    dt.Columns.Add("NGAYMAT", typeof(DateTime));
                    dt.Columns.Add("GIOITINH", typeof(string));

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

                            string maTH = row.Cell(1).GetString().Trim();
                            string hoTen = row.Cell(2).GetString().Trim();

                            // Xử lý ngày tháng an toàn
                            string ngaySinhStr = row.Cell(3).GetString().Trim();
                            object ngaySinh = DateTime.TryParse(ngaySinhStr, out DateTime ns) ? (object)ns : DBNull.Value;

                            string ngayMatStr = row.Cell(4).GetString().Trim();
                            object ngayMat = DateTime.TryParse(ngayMatStr, out DateTime nm) ? (object)nm : DBNull.Value;

                            string gioiTinh = row.Cell(5).GetString().Trim();

                            // Thêm vào DataTable
                            if (!string.IsNullOrEmpty(maTH))
                            {
                                dt.Rows.Add(maTH, hoTen, ngaySinh, ngayMat, gioiTinh);
                            }
                        }
                    }

                    if (dt.Rows.Count == 0)
                    {
                        MessageBox.Show("File rỗng hoặc không có dữ liệu!", "Cảnh báo");
                        return;
                    }

                    using (SqlConnection conn = new SqlConnection(DBConnect.ConnectionString))
                    {
                        conn.Open();
                        using (SqlBulkCopy bulkCopy = new SqlBulkCopy(conn))
                        {
                            bulkCopy.DestinationTableName = "THIHAI";

                            bulkCopy.ColumnMappings.Add("MATH", "MATH");
                            bulkCopy.ColumnMappings.Add("HOTEN_TH", "HOTEN_TH");
                            bulkCopy.ColumnMappings.Add("NGAYSINH", "NGAYSINH");
                            bulkCopy.ColumnMappings.Add("NGAYMAT", "NGAYMAT");
                            bulkCopy.ColumnMappings.Add("GIOITINH", "GIOITINH");

                            bulkCopy.WriteToServer(dt);
                            MessageBox.Show($"Đã nhập thành công {dt.Rows.Count} thi hài từ file Excel!", "Thành công");

                            LoadData();
                            DemSoLuongThiHai();
                        }
                    }
                }
                catch (SqlException ex)
                {
                    if (ex.Number == 2627) MessageBox.Show("Lỗi: Có mã Thi Hài trong file Excel đã tồn tại trong phần mềm!");
                    else MessageBox.Show("Lỗi CSDL: " + ex.Message);
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Lỗi đọc file (Vui lòng kiểm tra định dạng ngày tháng hoặc đóng file Excel đang mở): " + ex.Message);
                }
            }
        }
        private void DemSoLuongThiHai()
        {
            string prefix = "Số lượng thi hài: ";
            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    string sql = "EXEC SP_DemThiHai";
                    using (var cmd = new SqlCommand(sql, conn))
                    {
                        object result = cmd.ExecuteScalar();
                        int soLuong = result != null ? Convert.ToInt32(result) : 0;
                        CountThiHai = prefix + soLuong.ToString();
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Lỗi tính tổng: " + ex.Message);
            }
        }

        // --- HÀM THANH LÝ THI HÀI QUÁ HẠN
        private void ThanhLyThiHaiHangLoat()
        {
            if (!DBConnect.RequireAdmin("Thanh lý thi hài")) return;

            try
            {
                // Khởi tạo Connection với using
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open(); // Mở kết nối

                    // Khởi tạo Command với using
                    using (SqlCommand cmd = new SqlCommand("SP_DonDepThiHaiQuaHan", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.ExecuteNonQuery();
                    }
                } // <--- Tại dấu ngoặc nhọn này, C# sẽ tự động gọi conn.Close() và conn.Dispose()

                // Hiển thị thông báo (Chuẩn WPF)
                MessageBox.Show("Đã quét và dọn dẹp xong các thi hài quá hạn 15 ngày!", "Thành công", MessageBoxButton.OK, MessageBoxImage.Information);

                // Cập nhật lại giao diện
                LoadData();
                DemSoLuongThiHai();
                SelectedThiHai = new ThiHaiModel();
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi khi thanh lý: " + ex.Message, "Lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }
    }
}