using ClosedXML.Excel;
using DoAn.Core;
using DoAn.Model;
using System;
using System.Collections.ObjectModel;
using System.Data;
using Microsoft.Data.SqlClient;
using System.Windows;
using System.Windows.Input;

namespace DoAn.ViewModel
{
    public class SuDungViewModel : BaseViewModel
    {
        public ObservableCollection<SuDungModel> DanhSachSuDung { get; set; }
        public ObservableCollection<SuDungModel> LichSuDichVuTheoThiHai { get; set; }

        private SuDungModel _newSuDung;
        public SuDungModel NewSuDung
        {
            get => _newSuDung;
            set { _newSuDung = value; OnPropertyChanged(); }
        }

        private SuDungModel _selectedSuDung;
        public SuDungModel SelectedSuDung
        {
            get => _selectedSuDung;
            set
            {
                _selectedSuDung = value;
                OnPropertyChanged();
                if (_selectedSuDung != null)
                {
                    NewSuDung = new SuDungModel
                    {
                        MaTH = _selectedSuDung.MaTH,
                        TenTH = _selectedSuDung.TenTH,
                        MaDV = _selectedSuDung.MaDV,
                        TenDV = _selectedSuDung.TenDV,
                        GiaTien = _selectedSuDung.GiaTien,
                        NgaySD = _selectedSuDung.NgaySD,
                        SoLuong = _selectedSuDung.SoLuong,    // ← MỚI
                        GhiChu = _selectedSuDung.GhiChu
                    };
                }
                else
                {
                    ResetForm();
                }
            }
        }

        private string tongTien = "Tổng tiền: 0VNĐ";
        public string TongTien { get => tongTien; set { tongTien = value; OnPropertyChanged(); } }

        public ICommand LoadCommand { get; set; }
        public ICommand ThemCommand { get; set; }
        public ICommand XoaCommand { get; set; }
        public ICommand XuatExcelCommand { get; set; }
        public ICommand NhapTuFileCommand { get; set; }
        public ICommand TinhTongTienCommand { get; set; }
        public ICommand TraCuuLichSuDichVuCommand { get; set; }

        public SuDungViewModel()
        {
            DanhSachSuDung = new ObservableCollection<SuDungModel>();
            LichSuDichVuTheoThiHai = new ObservableCollection<SuDungModel>();

            LoadCommand = new RelayCommand(p => LoadData());
            ThemCommand = new RelayCommand(p => ThemSuDung(),
                                        p => NewSuDung != null
                                          && !string.IsNullOrWhiteSpace(NewSuDung.MaTH)
                                          && !string.IsNullOrWhiteSpace(NewSuDung.MaDV));
            XoaCommand = new RelayCommand(p => XoaSuDung(),
                                        p => NewSuDung != null
                                          && !string.IsNullOrWhiteSpace(NewSuDung.MaTH)
                                          && !string.IsNullOrWhiteSpace(NewSuDung.MaDV)
                                          && NewSuDung.NgaySD != null);
            XuatExcelCommand = new RelayCommand(p => XuatExcel());
            NhapTuFileCommand = new RelayCommand(p => NhapTuFile());
            TinhTongTienCommand = new RelayCommand(p => TinhTongTien(),
                                        p => NewSuDung != null && !string.IsNullOrEmpty(NewSuDung.MaTH));
            TraCuuLichSuDichVuCommand = new RelayCommand(p => TraCuuLichSuDichVu(),
                                        p => NewSuDung != null && !string.IsNullOrEmpty(NewSuDung.MaTH));

            LoadData();
            ResetForm();
        }

        private void ResetForm()
        {
            // ← MỚI: khởi tạo SoLuong = 1
            NewSuDung = new SuDungModel() { NgaySD = DateTime.Now, SoLuong = 1 };
        }

        private void LoadData()
        {
            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;
            DanhSachSuDung.Clear();

            string sql = "EXEC SP_DSDichVuSuDung";
            DataTable dt = DBConnect.GetData(sql);

            foreach (DataRow row in dt.Rows)
            {
                DanhSachSuDung.Add(new SuDungModel
                {
                    MaTH = row["MATH"].ToString(),
                    TenTH = row["HOTEN_TH"].ToString(),
                    MaDV = row["MADV"].ToString(),
                    TenDV = row["TENDV"].ToString(),
                    GiaTien = row["GIATIEN"] != DBNull.Value ? Convert.ToDecimal(row["GIATIEN"]) : 0,
                    SoLuong = row["SOLUONG"] != DBNull.Value ? Convert.ToInt32(row["SOLUONG"]) : 1,  // ← MỚI
                    NgaySD = row["NGAYSUDUNG"] != DBNull.Value ? (DateTime?)row["NGAYSUDUNG"] : null,
                    GhiChu = row["GHICHU"] != DBNull.Value ? row["GHICHU"].ToString() : "",
                    MaHD = row["MAHD"] != DBNull.Value ? row["MAHD"].ToString() : null,
                    TrangThaiHD = row.Table.Columns.Contains("TRANGTHAI_HD")
                                    ? row["TRANGTHAI_HD"].ToString() : ""
                });
            }
        }

        /// <summary>Truy xuất ngày mất của thi hài từ DB để so sánh logic thời gian.</summary>
        private DateTime? LayNgayMatThiHai(string maTH)
        {
            if (string.IsNullOrWhiteSpace(maTH) || string.IsNullOrEmpty(DBConnect.ConnectionString)) return null;
            try
            {
                string sql = $"SELECT NGAYMAT FROM THIHAI WHERE MATH = '{maTH}'";
                var dt = DBConnect.GetData(sql);
                if (dt != null && dt.Rows.Count > 0 && dt.Rows[0]["NGAYMAT"] != DBNull.Value)
                {
                    return Convert.ToDateTime(dt.Rows[0]["NGAYMAT"]);
                }
            }
            catch { /* Bỏ qua lỗi query, trả về null để SQL Trigger lo */ }
            return null;
        }

        /// <summary>Kiểm tra dữ liệu form Sử Dụng Dịch Vụ trước khi INSERT.</summary>
        private string? KiemTraSuDung(SuDungModel sd, DateTime? ngayMatThiHai)
        {
            if (!Validator.IsNotEmpty(sd.MaTH))
                return "Vui lòng chọn Thi Hài.";
            if (!Validator.IsNotEmpty(sd.MaDV))
                return "Vui lòng chọn Dịch Vụ.";
            if (!Validator.IsSoLuongHopLe(sd.SoLuong))
                return "Số lượng phải là số nguyên dương (>= 1).";

            if (sd.NgaySD.HasValue && ngayMatThiHai.HasValue)
            {
                if (!Validator.IsNgayDichVuHopLe(sd.NgaySD, ngayMatThiHai))
                    return $"Ngày sử dụng dịch vụ ({sd.NgaySD.Value:dd/MM/yyyy}) không được trước ngày mất thi hài ({ngayMatThiHai.Value:dd/MM/yyyy}).";
            }
            return null;
        }
        private void ThemSuDung()
        {
            if (!DBConnect.RequireStaffOrAdmin("Đăng ký dịch vụ")) return;

            // === KIỂM TRA VALIDATION ===
            DateTime? ngayMat = LayNgayMatThiHai(NewSuDung.MaTH);
            string? loi = KiemTraSuDung(NewSuDung, ngayMat);
            if (loi != null)
            {
                MessageBox.Show(loi, "Dữ liệu không hợp lệ", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    string sql = "EXEC SP_ThemDichVuSuDung @math, @madv, @ngaysudung, @ghichu, @soluong";
                    var cmd = new SqlCommand(sql, conn);
                    cmd.Parameters.AddWithValue("@math", NewSuDung.MaTH);
                    cmd.Parameters.AddWithValue("@madv", NewSuDung.MaDV);
                    cmd.Parameters.AddWithValue("@ngaysudung", NewSuDung.NgaySD);
                    cmd.Parameters.AddWithValue("@ghichu", string.IsNullOrWhiteSpace(NewSuDung.GhiChu) ? DBNull.Value : (object)NewSuDung.GhiChu);
                    cmd.Parameters.AddWithValue("@soluong", NewSuDung.SoLuong);

                    cmd.ExecuteNonQuery();

                    string msg = NewSuDung.SoLuong > 1
                        ? $"Đã đăng ký dịch vụ thành công! (Số lượng: {NewSuDung.SoLuong})"
                        : "Đã thêm/đăng ký dịch vụ thành công!";
                    MessageBox.Show(msg, "Thành công", MessageBoxButton.OK, MessageBoxImage.Information);

                    LoadData();
                    ResetForm();
                }
            }
            catch (SqlException ex)
            {
                // Bắt lỗi theo mã từ SQL
                if (ex.Number == 2627 || ex.Number == 2601)
                    MessageBox.Show("Dịch vụ này đã được đăng ký cho thi hài trong cùng một ngày! Vui lòng chọn sửa số lượng thay vì đăng ký mới.", "Trùng lặp", MessageBoxButton.OK, MessageBoxImage.Warning);
                else if (ex.Number == 547)
                    MessageBox.Show("Mã Thi Hài hoặc Mã Dịch Vụ không tồn tại trong hệ thống!", "Lỗi tham chiếu", MessageBoxButton.OK, MessageBoxImage.Warning);
                else if (ex.Message.Contains("sớm hơn ngày mất")) // Bắt lỗi từ TRG_KiemTraNgayDichVu
                    MessageBox.Show("Ngày sử dụng dịch vụ không được sớm hơn ngày mất của thi hài!", "Sai logic thời gian", MessageBoxButton.OK, MessageBoxImage.Warning);
                else
                    MessageBox.Show("Lỗi CSDL: " + ex.Message, "Lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi hệ thống: " + ex.Message, "Lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void XoaSuDung()
        {
            if (!DBConnect.RequireStaffOrAdmin("Hủy dịch vụ")) return;
            if (MessageBox.Show($"Bạn có chắc muốn hủy dịch vụ {NewSuDung.MaDV} của thi hài {NewSuDung.MaTH}?",
                "Xác nhận", MessageBoxButton.YesNo, MessageBoxImage.Warning) == MessageBoxResult.Yes)
            {
                try
                {
                    using (var conn = new SqlConnection(DBConnect.ConnectionString))
                    {
                        conn.Open();
                        string sql = "EXEC SP_XoaDichVuSuDung @math, @madv, @ngaysudung";
                        var cmd = new SqlCommand(sql, conn);
                        cmd.Parameters.AddWithValue("@math", NewSuDung.MaTH);
                        cmd.Parameters.AddWithValue("@madv", NewSuDung.MaDV);
                        cmd.Parameters.AddWithValue("@ngaysudung", NewSuDung.NgaySD);
                        cmd.ExecuteNonQuery();

                        MessageBox.Show("Đã hủy dịch vụ thành công!");
                        LoadData();
                        ResetForm();
                    }
                }
                catch (Exception ex) { MessageBox.Show("Lỗi xóa: " + ex.Message); }
            }
        }

        private void TinhTongTien()
        {
            if (!DBConnect.RequireStaffOrAdmin("Tính tổng tiền dịch vụ")) return;
            string maTH = NewSuDung.MaTH;
            try
            {
                using (SqlConnection conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    using (SqlCommand cmd = new SqlCommand("SELECT dbo.FN_TinhTongTienDichVu(@MaTH)", conn))
                    {
                        cmd.Parameters.AddWithValue("@MaTH", maTH);
                        object result = cmd.ExecuteScalar();
                        decimal total = result != DBNull.Value ? Convert.ToDecimal(result) : 0;
                        TongTien = $"Tổng tiền của thi hài {maTH} là: {total:N0} VNĐ";
                        MessageBox.Show($"Tổng tiền của thi hài {maTH} là: {total:N0} VNĐ", "Thông báo chi phí");
                    }
                }
            }
            catch (Exception ex) { MessageBox.Show("Lỗi tính toán: " + ex.Message); }
        }

        private void TraCuuLichSuDichVu()
        {
            if (!DBConnect.RequireStaffOrAdmin("Tra cứu lịch sử dịch vụ")) return;
            if (string.IsNullOrWhiteSpace(NewSuDung?.MaTH))
            {
                MessageBox.Show("Vui lòng nhập Mã Thi Hài để tra cứu lịch sử dịch vụ.");
                return;
            }

            LichSuDichVuTheoThiHai.Clear();
            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    using (var cmd = new SqlCommand("SELECT * FROM dbo.fn_LichSuDichVuCuaTuThi(@math)", conn))
                    {
                        cmd.Parameters.AddWithValue("@math", NewSuDung.MaTH);
                        using (var da = new SqlDataAdapter(cmd))
                        {
                            var dt = new DataTable();
                            da.Fill(dt);

                            foreach (DataRow row in dt.Rows)
                            {
                                LichSuDichVuTheoThiHai.Add(new SuDungModel
                                {
                                    TenDV = row["TENDV"].ToString(),
                                    GiaTien = row["GIATIEN"] != DBNull.Value ? Convert.ToDecimal(row["GIATIEN"]) : 0,
                                    SoLuong = row["SOLUONG"] != DBNull.Value ? Convert.ToInt32(row["SOLUONG"]) : 1,  // ← MỚI
                                    NgaySD = row["NGAYSUDUNG"] != DBNull.Value ? (DateTime?)row["NGAYSUDUNG"] : null,
                                    GhiChu = row["GHICHU"] != DBNull.Value ? row["GHICHU"].ToString() : ""
                                });
                            }

                            if (dt.Rows.Count == 0)
                                MessageBox.Show("Không có lịch sử dịch vụ cho thi hài này.");
                        }
                    }
                }
            }
            catch (Exception ex) { MessageBox.Show("Lỗi tra cứu: " + ex.Message); }
        }

        private void XuatExcel()
        {
            if (!DBConnect.RequireStaffOrAdmin("Xuất Excel dịch vụ đã mua")) return;
            if (DanhSachSuDung == null || DanhSachSuDung.Count == 0) return;

            Microsoft.Win32.SaveFileDialog sfd = new Microsoft.Win32.SaveFileDialog()
            { Filter = "Excel Files|*.xlsx", FileName = "ThongKe_SuDungDichVu.xlsx" };

            if (sfd.ShowDialog() == true)
            {
                try
                {
                    using (var wb = new XLWorkbook())
                    {
                        var ws = wb.Worksheets.Add("Dịch Vụ Đã Sử Dụng");

                        // ← MỚI: thêm cột Số Lượng và Thành Tiền
                        ws.Cell(1, 1).Value = "Mã TH";
                        ws.Cell(1, 2).Value = "Tên Thi Hài";
                        ws.Cell(1, 3).Value = "Mã DV";
                        ws.Cell(1, 4).Value = "Tên Dịch Vụ";
                        ws.Cell(1, 5).Value = "Đơn Giá";
                        ws.Cell(1, 6).Value = "Số Lượng";    // ← MỚI
                        ws.Cell(1, 7).Value = "Thành Tiền";  // ← MỚI
                        ws.Cell(1, 8).Value = "Ngày Sử Dụng";
                        ws.Cell(1, 9).Value = "Ghi Chú";

                        var header = ws.Range("A1:I1");
                        header.Style.Font.Bold = true;
                        header.Style.Fill.BackgroundColor = XLColor.Yellow;
                        header.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                        int r = 2;
                        foreach (var item in DanhSachSuDung)
                        {
                            ws.Cell(r, 1).Value = item.MaTH;
                            ws.Cell(r, 2).Value = item.TenTH;
                            ws.Cell(r, 3).Value = item.MaDV;
                            ws.Cell(r, 4).Value = item.TenDV;
                            ws.Cell(r, 5).Value = item.GiaTien;
                            ws.Cell(r, 5).Style.NumberFormat.Format = "#,##0";
                            ws.Cell(r, 6).Value = item.SoLuong;        // ← MỚI
                            ws.Cell(r, 7).Value = item.ThanhTien;      // ← MỚI
                            ws.Cell(r, 7).Style.NumberFormat.Format = "#,##0";
                            if (item.NgaySD.HasValue)
                                ws.Cell(r, 8).Value = item.NgaySD.Value.ToString("dd/MM/yyyy");
                            ws.Cell(r, 9).Value = item.GhiChu;
                            r++;
                        }

                        ws.Columns().AdjustToContents();
                        wb.SaveAs(sfd.FileName);
                        MessageBox.Show("Xuất báo cáo Excel thành công!\nĐường dẫn: " + sfd.FileName);
                    }
                }
                catch (Exception ex) { MessageBox.Show("Lỗi xuất Excel: " + ex.Message); }
            }
        }

        private void NhapTuFile()
        {
            if (!DBConnect.RequireStaffOrAdmin("Nhập Excel dịch vụ đã mua")) return;

            Microsoft.Win32.OpenFileDialog dlg = new Microsoft.Win32.OpenFileDialog();
            dlg.Filter = "Excel Files (*.xlsx)|*.xlsx";
            dlg.Title = "Chọn file Excel Dịch Vụ Đã Mua";

            if (dlg.ShowDialog() == true)
            {
                try
                {
                    DataTable dt = new DataTable();
                    dt.Columns.Add("MATH", typeof(string));
                    dt.Columns.Add("MADV", typeof(string));
                    dt.Columns.Add("NGAYSD", typeof(DateTime));
                    dt.Columns.Add("GHICHU", typeof(string));
                    dt.Columns.Add("SOLUONG", typeof(int));    // ← MỚI

                    using (var workbook = new XLWorkbook(dlg.FileName))
                    {
                        var worksheet = workbook.Worksheet(1);
                        var rows = worksheet.RangeUsed().RowsUsed();

                        bool isFirstRow = true;
                        foreach (var row in rows)
                        {
                            if (isFirstRow) { isFirstRow = false; continue; }

                            string maTH = row.Cell(1).GetString().Trim();
                            string maDV = row.Cell(2).GetString().Trim();

                            string ngaySDStr = row.Cell(3).GetString().Trim();
                            object ngaySD = DateTime.TryParse(ngaySDStr, out DateTime ns)
                                          ? (object)ns : DBNull.Value;

                            string ghiChu = row.Cell(4).GetString().Trim();

                            // ← MỚI: đọc cột Số Lượng (cột 5), mặc định 1 nếu không có
                            int soLuong = 1;
                            if (!int.TryParse(row.Cell(5).GetString().Trim(), out soLuong) || soLuong < 1)
                                soLuong = 1;

                            if (!string.IsNullOrEmpty(maTH) && !string.IsNullOrEmpty(maDV))
                                dt.Rows.Add(maTH, maDV, ngaySD,
                                            string.IsNullOrEmpty(ghiChu) ? (object)DBNull.Value : ghiChu,
                                            soLuong);
                        }
                    }

                    if (dt.Rows.Count == 0)
                    {
                        MessageBox.Show("File rỗng hoặc bạn để trống Mã TH / Mã DV!", "Cảnh báo");
                        return;
                    }

                    using (SqlConnection conn = new SqlConnection(DBConnect.ConnectionString))
                    {
                        conn.Open();
                        using (SqlBulkCopy bulkCopy = new SqlBulkCopy(conn))
                        {
                            bulkCopy.DestinationTableName = "SUDUNG";
                            bulkCopy.ColumnMappings.Add("MATH", "MATH");
                            bulkCopy.ColumnMappings.Add("MADV", "MADV");
                            bulkCopy.ColumnMappings.Add("NGAYSD", "NGAYSUDUNG");
                            bulkCopy.ColumnMappings.Add("GHICHU", "GHICHU");
                            bulkCopy.ColumnMappings.Add("SOLUONG", "SOLUONG");  // ← MỚI
                            bulkCopy.WriteToServer(dt);
                            MessageBox.Show($"Đã thêm thành công {dt.Rows.Count} lượt sử dụng dịch vụ từ file Excel!", "Thành công");
                            LoadData();
                        }
                    }
                }
                catch (SqlException ex)
                {
                    if (ex.Number == 2627)
                        MessageBox.Show("Lỗi: Dữ liệu bị trùng (1 thi hài dùng 1 dịch vụ 2 lần trong cùng 1 ngày)!");
                    else if (ex.Number == 547)
                        MessageBox.Show("Lỗi: Mã Thi Hài hoặc Mã Dịch Vụ trong file không tồn tại trong hệ thống!");
                    else
                        MessageBox.Show("Lỗi CSDL: " + ex.Message);
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Lỗi đọc file (Vui lòng đóng file Excel đang mở): " + ex.Message);
                }
            }
        }
    }
}