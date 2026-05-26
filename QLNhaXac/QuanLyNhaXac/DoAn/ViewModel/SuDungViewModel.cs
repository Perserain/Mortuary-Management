using ClosedXML.Excel;
using DoAn.Model;
using DoAn.QuanLy;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Input;

namespace DoAn.ViewModel
{
    public class SuDungViewModel : BaseViewModel
    {
        public ObservableCollection<SuDungModel> DanhSachSuDung { get; set; }

        private SuDungModel _selectedSuDung;
        public SuDungModel SelectedSuDung
        {
            get => _selectedSuDung;
            set { _selectedSuDung = value; OnPropertyChanged(); }
        }

        private string tongTien = "Tổng tiền: 0VNĐ";
        public string TongTien { get => tongTien; set { tongTien = value; OnPropertyChanged(); } }

        public ICommand LoadCommand { get; set; }
        public ICommand ThemCommand { get; set; }
        public ICommand XoaCommand { get; set; }
        public ICommand XuatExcelCommand { get; set; }
        public ICommand NhapTuFileCommand { get; set; }
        public ICommand TinhTongTienCommand { get; set; }
        public SuDungViewModel()
        {
            DanhSachSuDung = new ObservableCollection<SuDungModel>();
            SelectedSuDung = new SuDungModel() { NgaySD = DateTime.Now };
            LoadCommand = new RelayCommand(p => LoadData());
            ThemCommand = new RelayCommand(p => ThemSuDung(), p => SelectedSuDung != null && !string.IsNullOrWhiteSpace(SelectedSuDung.MaTH) && !string.IsNullOrWhiteSpace(SelectedSuDung.MaDV));
            XoaCommand = new RelayCommand(p => XoaSuDung(), p => SelectedSuDung != null && !string.IsNullOrWhiteSpace(SelectedSuDung.MaTH) && !string.IsNullOrWhiteSpace(SelectedSuDung.MaDV) && SelectedSuDung.NgaySD != null);
            XuatExcelCommand = new RelayCommand(p => XuatExcel());
            NhapTuFileCommand = new RelayCommand(p => NhapTuFile());
            TinhTongTienCommand = new RelayCommand(p => TinhTongTien(), p => SelectedSuDung != null && !string.IsNullOrEmpty(SelectedSuDung.MaTH));
            LoadData();
        }

        private void LoadData()
        {
            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;
            DanhSachSuDung.Clear();

            // Gọi VIEW siêu ngắn gọn
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
                    NgaySD = row["NGAYSUDUNG"] != DBNull.Value ? (DateTime?)row["NGAYSUDUNG"] : null,
                    GhiChu = row["GHICHU"].ToString()
                });
            }
        }

        private void ThemSuDung()
        {
            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    // Khi Thêm dữ liệu, vẫn phải tác động vào bảng gốc (SUDUNG)
                    string sql = "EXEC SP_ThemDichVuSuDung @math, @madv, @ngaysudung, @ghichu";
                    var cmd = new SqlCommand(sql, conn);

                    cmd.Parameters.AddWithValue("@math", SelectedSuDung.MaTH);
                    cmd.Parameters.AddWithValue("@madv", SelectedSuDung.MaDV);
                    cmd.Parameters.AddWithValue("@ngaysudung", SelectedSuDung.NgaySD);
                    cmd.Parameters.AddWithValue("@ghichu", SelectedSuDung.GhiChu);
                    cmd.ExecuteNonQuery();
                    MessageBox.Show("Đã thêm/đăng ký dịch vụ thành công!", "Thành công");

                    LoadData();
                    SelectedSuDung = new SuDungModel() { NgaySD = DateTime.Now };
                }
            }
            catch (SqlException ex)
            {
                if (ex.Number == 547) MessageBox.Show("Mã Thi Hài hoặc Mã Dịch Vụ không tồn tại trong hệ thống!");
                else if (ex.Number == 2627) MessageBox.Show("Thi hài này đã đăng ký dịch vụ này vào cùng ngày rồi!");
                else MessageBox.Show("Lỗi CSDL: " + ex.Message);
            }
        }

        private void XoaSuDung()
        {
            if (MessageBox.Show($"Bạn có chắc muốn hủy dịch vụ {SelectedSuDung.MaDV} của thi hài {SelectedSuDung.MaTH}?", "Xác nhận", MessageBoxButton.YesNo, MessageBoxImage.Warning) == MessageBoxResult.Yes)
            {
                try
                {
                    using (var conn = new SqlConnection(DBConnect.ConnectionString))
                    {
                        conn.Open();
                        // Phải xóa dựa trên bảng gốc
                        string sql = "EXEC SP_XoaDichVuSuDung @math, @madv, @ngaysudung";
                        var cmd = new SqlCommand(sql, conn);
                        cmd.Parameters.AddWithValue("@math", SelectedSuDung.MaTH);
                        cmd.Parameters.AddWithValue("@madv", SelectedSuDung.MaDV);
                        cmd.Parameters.AddWithValue("@ngaysudung", SelectedSuDung.NgaySD);
                        cmd.Parameters.AddWithValue("@ghichu", SelectedSuDung.GhiChu);
                        cmd.ExecuteNonQuery();

                        MessageBox.Show("Đã hủy dịch vụ thành công!");
                        LoadData();
                        SelectedSuDung = new SuDungModel() { NgaySD = DateTime.Now };
                    }
                }
                catch (Exception ex) { MessageBox.Show("Lỗi xóa: " + ex.Message); }
            }
        }

        private void XuatExcel()
        {
            if (DanhSachSuDung == null || DanhSachSuDung.Count == 0) return;

            Microsoft.Win32.SaveFileDialog sfd = new Microsoft.Win32.SaveFileDialog() { Filter = "Excel Files|*.xlsx", FileName = "ThongKe_SuDungDichVu.xlsx" };
            if (sfd.ShowDialog() == true)
            {
                try
                {
                    using (var wb = new XLWorkbook())
                    {
                        var ws = wb.Worksheets.Add("Dịch Vụ Đã Sử Dụng");

                        // Tiêu đề
                        ws.Cell(1, 1).Value = "Mã TH";
                        ws.Cell(1, 2).Value = "Tên Thi Hài";
                        ws.Cell(1, 3).Value = "Mã DV";
                        ws.Cell(1, 4).Value = "Tên Dịch Vụ";
                        ws.Cell(1, 5).Value = "Giá Tiền";
                        ws.Cell(1, 6).Value = "Ngày Sử Dụng";
                        ws.Cell(1, 7).Value = "Ghi Chú";

                        var header = ws.Range("A1:G1");
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

                            // Xuất giá tiền có định dạng dấu phẩy
                            ws.Cell(r, 5).Value = item.GiaTien;
                            ws.Cell(r, 5).Style.NumberFormat.Format = "#,##0";

                            if (item.NgaySD.HasValue) ws.Cell(r, 6).Value = item.NgaySD.Value.ToString("dd/MM/yyyy");
                            ws.Cell(r, 7).Value = item.GhiChu;
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
        // HÀM NHẬP TỪ FILE
        private void NhapTuFile()
        {
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
                            string maDV = row.Cell(2).GetString().Trim();

                            // Xử lý ngày tháng an toàn
                            string ngaySDStr = row.Cell(3).GetString().Trim();
                            object ngaySD = DateTime.TryParse(ngaySDStr, out DateTime ns) ? (object)ns : DBNull.Value;

                            string ghiChu = row.Cell(4).GetString().Trim();

                            // Thêm vào DataTable
                            if (!string.IsNullOrEmpty(maTH) && !string.IsNullOrEmpty(maDV))
                            {
                                dt.Rows.Add(maTH, maDV, ngaySD, ghiChu);
                            }
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
                            bulkCopy.ColumnMappings.Add("NGAYSUDUNG", "NGAYSUDUNG");
                            bulkCopy.ColumnMappings.Add("GHICHU", "GHICHU");

                            bulkCopy.WriteToServer(dt);
                            MessageBox.Show($"Đã thêm thành công {dt.Rows.Count} lượt sử dụng dịch vụ từ file Excel!", "Thành công");

                            LoadData(); // Load lại Grid

                        }
                    }
                }
                catch (SqlException ex)
                {
                    if (ex.Number == 2627) MessageBox.Show("Lỗi: Dữ liệu bị trùng (1 thi hài dùng 1 dịch vụ 2 lần trong cùng 1 ngày)!");
                    else if (ex.Number == 547) MessageBox.Show("Lỗi: Mã Thi Hài hoặc Mã Dịch Vụ trong file không tồn tại trong hệ thống!");
                    else MessageBox.Show("Lỗi CSDL: " + ex.Message);
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Lỗi đọc file (Vui lòng đóng file Excel đang mở): " + ex.Message);
                }
            }
        }

        private void TinhTongTien()
        {
            string maTH = SelectedSuDung.MaTH;
            try
            {
                using (SqlConnection conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    using (SqlCommand cmd = new SqlCommand("sp_TinhTongTienDichVu", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;

                        cmd.Parameters.AddWithValue("@MaTH", maTH);

                        SqlParameter outParam = new SqlParameter("@TongTien", SqlDbType.Money);
                        outParam.Direction = ParameterDirection.Output;
                        cmd.Parameters.Add(outParam);

                        cmd.ExecuteNonQuery();

                        decimal tongTien = (decimal)cmd.Parameters["@TongTien"].Value;
                        if (cmd.Parameters["@TongTien"].Value != DBNull.Value)
                        {
                            tongTien= (decimal)cmd.Parameters["@TongTien"].Value;
                        }
                        TongTien = $"Tổng tiền của thi hài {maTH} là: {tongTien:N0} VNĐ";
                        MessageBox.Show($"Tổng tiền của thi hài {maTH} là: {tongTien:N0} VNĐ", "Thông báo chi phí");
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi tính toán: " + ex.Message);
            }
        }
    }
}
