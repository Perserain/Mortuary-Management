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
                        NgayMat = _selectedThiHai.NgayMat,
                        // S3-02
                        NoiTimThay = _selectedThiHai.NoiTimThay,
                        CoCuaNhan = _selectedThiHai.CoCuaNhan
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

        private DateTime? _ngayTimKiem;
        public DateTime? NgayTimKiem
        {
            get => _ngayTimKiem;
            set { _ngayTimKiem = value; OnPropertyChanged(); }
        }

        public ICommand LoadCommand { get; set; }
        public ICommand ThemCommand { get; set; }
        public ICommand SuaCommand { get; set; }
        public ICommand XoaCommand { get; set; }
        public ICommand BanGiaoCommand { get; set; }
        public ICommand XuatExcelCommand { get; set; }
        public ICommand TimSotCommand { get; set; }
        public ICommand XemChiTietCommand { get; set; }
        public ICommand NhapTuFileCommand { get; set; }
        public ICommand ThanhLyCommand { get; set; }
        public ICommand TimTheoNgayCommand { get; set; }
        public ICommand TaiLaiDanhSachCommand { get; set; }

        // ── Phân quyền ──
        public bool IsAdmin => DBConnect.IsAdmin;
        // Admin và Staff mới được chỉnh sửa thi hài — Bác sĩ chỉ được xem
        public bool CanEditThiHai => DBConnect.IsAdmin || DBConnect.IsStaff;

        public ThiHaiViewModel()
        {
            DanhSachThiHai = new ObservableCollection<ThiHaiModel>();

            LoadCommand = new RelayCommand(p => LoadData());
            ThemCommand = new RelayCommand(p => ThemThiHai(), p => NewThiHai != null && !string.IsNullOrWhiteSpace(NewThiHai.MaTH));
            SuaCommand = new RelayCommand(p => SuaThiHai(), p => NewThiHai != null && !string.IsNullOrWhiteSpace(NewThiHai.MaTH));
            XoaCommand = new RelayCommand(p => XoaThiHai(), p => NewThiHai != null && !string.IsNullOrWhiteSpace(NewThiHai.MaTH));
            BanGiaoCommand = new RelayCommand(
                p => BanGiaoThiHai(),
                p => NewThiHai != null && !string.IsNullOrEmpty(NewThiHai.MaTH)
            );
            XuatExcelCommand = new RelayCommand(p => XuatExcel());
            NhapTuFileCommand = new RelayCommand(p => NhapTuFile());
            TimSotCommand = new RelayCommand(p => TimSot());
            XemChiTietCommand = new RelayCommand(p => XemChiTiet(), p => NewThiHai != null && !string.IsNullOrEmpty(NewThiHai.MaTH));
            ThanhLyCommand = new RelayCommand(p => ThanhLyThiHaiHangLoat());
            TimTheoNgayCommand = new RelayCommand(p => TimTheoNgay());
            TaiLaiDanhSachCommand = new RelayCommand(p => TaiLaiDanhSach());

            LoadData();
            ResetForm();
        }
        private string TaoMaTH()
        {
            if (DanhSachThiHai == null || DanhSachThiHai.Count == 0) return "TH001";

            var maxId = DanhSachThiHai
                .Select(d => {
                    if (d.MaTH != null && d.MaTH.StartsWith("TH") && int.TryParse(d.MaTH.Substring(2), out int num))
                        return num;
                    return 0;
                })
                .DefaultIfEmpty(0)
                .Max();

            return $"TH{(maxId + 1):D3}";
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
                    NhomTuoi = row["NHOMTUOI"].ToString(),
                    // S3-02: Trường pháp y
                    NoiTimThay = row.Table.Columns.Contains("NOITIMTHAY") && row["NOITIMTHAY"] != DBNull.Value ? row["NOITIMTHAY"].ToString() : null,
                    CoCuaNhan = row.Table.Columns.Contains("COCUANHAN") && row["COCUANHAN"] != DBNull.Value ? row["COCUANHAN"].ToString() : null
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
            if (!DBConnect.RequireStaffOrAdmin("Thêm thi hài")) return;
            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    string sql = "EXEC SP_ThemThiHai @ma, @ten, @ns, @nm, @gt, @noiTimThay, @coCuaNhan";
                    var cmd = new SqlCommand(sql, conn);

                    cmd.Parameters.AddWithValue("@ma", NewThiHai.MaTH);
                    cmd.Parameters.AddWithValue("@ten", NewThiHai.HoTenTH ?? (object)DBNull.Value);
                    cmd.Parameters.AddWithValue("@gt", NewThiHai.GioiTinh ?? (object)DBNull.Value);
                    cmd.Parameters.AddWithValue("@ns", NewThiHai.NgaySinh ?? (object)DBNull.Value);
                    cmd.Parameters.AddWithValue("@nm", NewThiHai.NgayMat ?? (object)DBNull.Value);
                    // S3-02
                    cmd.Parameters.AddWithValue("@noiTimThay", string.IsNullOrWhiteSpace(NewThiHai.NoiTimThay) ? DBNull.Value : (object)NewThiHai.NoiTimThay);
                    cmd.Parameters.AddWithValue("@coCuaNhan", string.IsNullOrWhiteSpace(NewThiHai.CoCuaNhan) ? DBNull.Value : (object)NewThiHai.CoCuaNhan);

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
            if (!DBConnect.RequireStaffOrAdmin("Sửa thi hài")) return;
            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    string sqlUpdate = "EXEC SP_SuaThiHai @ma, @ten, @ns, @nm, @gt, @noiTimThay, @coCuaNhan";
                    var cmdUpdate = new SqlCommand(sqlUpdate, conn);

                    cmdUpdate.Parameters.AddWithValue("@ma", NewThiHai.MaTH);
                    cmdUpdate.Parameters.AddWithValue("@ten", string.IsNullOrWhiteSpace(NewThiHai.HoTenTH) ? DBNull.Value : (object)NewThiHai.HoTenTH);
                    cmdUpdate.Parameters.AddWithValue("@gt", string.IsNullOrWhiteSpace(NewThiHai.GioiTinh) ? DBNull.Value : (object)NewThiHai.GioiTinh);
                    cmdUpdate.Parameters.AddWithValue("@ns", NewThiHai.NgaySinh ?? (object)DBNull.Value);
                    cmdUpdate.Parameters.AddWithValue("@nm", NewThiHai.NgayMat ?? (object)DBNull.Value);
                    // S3-02
                    cmdUpdate.Parameters.AddWithValue("@noiTimThay", string.IsNullOrWhiteSpace(NewThiHai.NoiTimThay) ? DBNull.Value : (object)NewThiHai.NoiTimThay);
                    cmdUpdate.Parameters.AddWithValue("@coCuaNhan", string.IsNullOrWhiteSpace(NewThiHai.CoCuaNhan) ? DBNull.Value : (object)NewThiHai.CoCuaNhan);

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
            if (!DBConnect.RequireStaffOrAdmin("Xóa thi hài")) return;
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

        private void TimTheoNgay()
        {
            if (NgayTimKiem == null)
            {
                MessageBox.Show("Vui lòng chọn ngày cần tìm.");
                return;
            }

            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;
            DanhSachThiHai.Clear();

            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    using (var cmd = new SqlCommand("SELECT * FROM dbo.fn_TimKiemThiHaiTheoNgay(@ngay)", conn))
                    {
                        cmd.Parameters.AddWithValue("@ngay", NgayTimKiem.Value.Date);
                        using (var da = new SqlDataAdapter(cmd))
                        {
                            var dt = new DataTable();
                            da.Fill(dt);

                            foreach (DataRow row in dt.Rows)
                            {
                                DateTime? ngaySinh = row["NGAYSINH"] != DBNull.Value ? (DateTime?)row["NGAYSINH"] : null;
                                DateTime? ngayMat = row["NGAYMAT"] != DBNull.Value ? (DateTime?)row["NGAYMAT"] : null;

                                DanhSachThiHai.Add(new ThiHaiModel
                                {
                                    MaTH = row["MATH"].ToString(),
                                    HoTenTH = row["HOTEN_TH"].ToString(),
                                    GioiTinh = row["GIOITINH"].ToString(),
                                    NgaySinh = ngaySinh,
                                    NgayMat = ngayMat,
                                    NhomTuoi = TinhNhomTuoi(ngaySinh, ngayMat)
                                });
                            }

                            CountThiHai = "Kết quả lọc: " + DanhSachThiHai.Count;
                            if (dt.Rows.Count == 0)
                            {
                                MessageBox.Show("Không tìm thấy thi hài theo ngày đã chọn.");
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi tìm kiếm: " + ex.Message);
            }
        }

        private void TaiLaiDanhSach()
        {
            NgayTimKiem = null;
            LoadData();
        }

        private string TinhNhomTuoi(DateTime? ngaySinh, DateTime? ngayMat)
        {
            if (!ngaySinh.HasValue || !ngayMat.HasValue) return "Chưa rõ";

            int age = ngayMat.Value.Year - ngaySinh.Value.Year;
            if (ngayMat.Value < ngaySinh.Value.AddYears(age)) age--;

            if (age < 18) return "Vị thành niên";
            if (age <= 59) return "Trưởng thành";
            return "Cao tuổi";
        }


        private void XuatExcel()
        {
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
            if (!DBConnect.RequireStaffOrAdmin("Nhập Excel thi hài")) return;

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

        // --- HÀM BÀN GIAO THI HÀI
        private void BanGiaoThiHai()
        {
            if (!DBConnect.RequireStaffOrAdmin("Bàn giao thi hài")) return;

            var confirm = MessageBox.Show(
                $"Bạn có chắc muốn bàn giao thi hài [{NewThiHai.MaTH} - {NewThiHai.HoTenTH}]?\n\n" +
                "Thao tác này sẽ:\n" +
                "  • Đánh dấu thi hài là ĐÃ BÀN GIAO\n" +
                "  • Giải phóng ngăn kéo đang sử dụng\n\n" +
                "Lưu ý: Hóa đơn phải được thanh toán trước khi bàn giao.",
                "Xác nhận Bàn Giao",
                MessageBoxButton.YesNo,
                MessageBoxImage.Warning);

            if (confirm != MessageBoxResult.Yes) return;

            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();

                    // Bắt PRINT messages từ SP (SP dùng PRINT thay vì RAISERROR)
                    string serverMessage = string.Empty;
                    conn.InfoMessage += (sender, e) => { serverMessage = e.Message; };

                    var cmd = new SqlCommand("EXEC SP_BanGiaoThiHai @maTH", conn);
                    cmd.Parameters.AddWithValue("@maTH", NewThiHai.MaTH);
                    cmd.ExecuteNonQuery();

                    // SP dùng PRINT để báo lỗi nghiệp vụ (chưa thanh toán)
                    if (!string.IsNullOrEmpty(serverMessage) && serverMessage.Contains("Chưa thể"))
                    {
                        MessageBox.Show(serverMessage, "Không thể Bàn Giao", MessageBoxButton.OK, MessageBoxImage.Warning);
                        return;
                    }

                    MessageBox.Show(
                        $"Đã bàn giao thi hài [{NewThiHai.MaTH}] thành công!\nNgăn kéo đã được giải phóng.",
                        "Bàn Giao Thành Công",
                        MessageBoxButton.OK,
                        MessageBoxImage.Information);

                    LoadData();
                    ResetForm();
                }
            }
            catch (SqlException ex)
            {
                // Lỗi nghiệp vụ rõ ràng từ DB (nếu SP nâng cấp lên RAISERROR sau này)
                if (ex.Number >= 50000)
                    MessageBox.Show(ex.Message, "Không thể Bàn Giao", MessageBoxButton.OK, MessageBoxImage.Warning);
                else
                    MessageBox.Show(
                        $"Lỗi cơ sở dữ liệu khi bàn giao:\n{ex.Message}",
                        "Lỗi",
                        MessageBoxButton.OK,
                        MessageBoxImage.Error);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Lỗi không xác định:\n{ex.Message}", "Lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        // --- HÀM THANH LÝ THI HÀI QUÁ HẠN
        private void ThanhLyThiHaiHangLoat()
        {
            if (!DBConnect.RequireAdmin("Dọn dẹp thi hài quá hạn")) return;

            var confirm = MessageBox.Show(
                "⚠️ CẢNH BÁO: Hành động này sẽ XÓA VĨNH VIỄN toàn bộ thi hài đã lưu quá 15 ngày!\n\n" +
                "Dữ liệu liên quan (ngăn kéo, hóa đơn, hồ sơ...) cũng sẽ bị xóa theo.\n\n" +
                "Hành động này KHÔNG THỂ HOÀN TÁC. Bạn có chắc chắn muốn tiếp tục không?",
                "⚠️ Xác nhận dọn dẹp thi hài",
                MessageBoxButton.YesNo,
                MessageBoxImage.Warning);

            if (confirm != MessageBoxResult.Yes) return;

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