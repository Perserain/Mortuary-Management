using DoAn.Model;
using DoAn.Views.Shared;
using System.Collections.ObjectModel;
using System.Data;
using Microsoft.Data.SqlClient;
using System.IO;
using System.Text;
using System.Windows;
using System.Windows.Input; 
using ClosedXML.Excel;
using DoAn.Core;
namespace DoAn.ViewModel
{
    public class BacSiViewModel : BaseViewModel
    {
        // Danh sách hiển thị lên DataGrid
        public ObservableCollection<BacSiModel> DanhSachBacSi { get; set; }

        // Bác sĩ đang được chọn trên DataGrid hoặc đang nhập liệu
        private BacSiModel _selectedBacSi;
        public BacSiModel SelectedBacSi
        {
            get => _selectedBacSi;
            set { _selectedBacSi = value; OnPropertyChanged(); }
        }

        // Commands cho các nút bấm
        public ICommand LoadCommand { get; set; }
        public ICommand XemChiTietCommand { get; set; }
        public ICommand ThemCommand { get; set; }
        public ICommand XoaCommand { get; set; }
        public ICommand SuaCommand { get; set; }
        public ICommand XuatExcelCommand { get; set; }
        public ICommand NhapTuFileCommand { get; set; }
        public ICommand XuatLaoLangCommand { get; set; }

        public BacSiViewModel()
        {
            DanhSachBacSi = new ObservableCollection<BacSiModel>();
            SelectedBacSi = new BacSiModel(); // Khởi tạo form
            // Commands
            LoadCommand = new RelayCommand(p => LoadData());
            XemChiTietCommand = new RelayCommand(p => XemChiTiet(), p => SelectedBacSi != null && !string.IsNullOrEmpty(SelectedBacSi.MaBS));
            ThemCommand = new RelayCommand(p => ThemBacSi(), p => CanThemBacSi());
            XoaCommand = new RelayCommand(p => XoaBacSi(), p => SelectedBacSi != null && !string.IsNullOrEmpty(SelectedBacSi.MaBS));
            SuaCommand = new RelayCommand(p => SuaBacSi(), p => SelectedBacSi != null && !string.IsNullOrEmpty(SelectedBacSi.MaBS));
            XuatExcelCommand = new RelayCommand(p => XuatExcel());
            NhapTuFileCommand = new RelayCommand(p => NhapTuFile());
            XuatLaoLangCommand = new RelayCommand(p => BSLaoLang());
            LoadData();
        }

        private void LoadData()
        {
            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;
            DanhSachBacSi.Clear();
            DataTable dt = DBConnect.GetData("EXEC SP_DSBacSi");

            foreach (DataRow row in dt.Rows)
            {
                DanhSachBacSi.Add(new BacSiModel
                {
                    MaBS = row["MABS"].ToString(),
                    HoTenBS = row["HOTEN_BS"].ToString(),
                    ChuyenKhoa = row["CHUYENKHOA"].ToString(),
                    NamKinhNghiem = row["NAMKINHNGHIEM"] != DBNull.Value ? Convert.ToInt32(row["NAMKINHNGHIEM"]) : 0,
                    MaTruongKhoa = row["MA_TRUONGKHOA"].ToString(),
                    CapBac = row["CAPBAC"].ToString() 
                });
            }
        }
        private void XemChiTiet()
        {

            DetailWindow f = new DetailWindow(SelectedBacSi, "CHI TIẾT BÁC SĨ");
            f.ShowDialog();
        }
        private bool CanThemBacSi()
        {
            // Điều kiện để nút Thêm sáng lên: Mã và Tên không được rỗng
            return SelectedBacSi != null &&
                   !string.IsNullOrWhiteSpace(SelectedBacSi.MaBS) &&
                   !string.IsNullOrWhiteSpace(SelectedBacSi.HoTenBS);
        }

        private void ThemBacSi()
        {
            if (!DBConnect.RequireAdmin("Thêm bác sĩ")) return;

            try
            {
                using (SqlConnection conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    string sql = "EXEC SP_THEMBACSI @ma, @ten, @ck, @kn, @sep";
                    SqlCommand cmd = new SqlCommand(sql, conn);
                    cmd.Parameters.AddWithValue("@ma", SelectedBacSi.MaBS);
                    cmd.Parameters.AddWithValue("@ten", SelectedBacSi.HoTenBS);
                    cmd.Parameters.AddWithValue("@ck", SelectedBacSi.ChuyenKhoa);
                    cmd.Parameters.AddWithValue("@kn", SelectedBacSi.NamKinhNghiem);

                    if (string.IsNullOrEmpty(SelectedBacSi.MaTruongKhoa))
                        cmd.Parameters.AddWithValue("@sep", DBNull.Value);
                    else
                        cmd.Parameters.AddWithValue("@sep", SelectedBacSi.MaTruongKhoa);

                    cmd.ExecuteNonQuery();
                    MessageBox.Show("Thêm bác sĩ thành công!");
                    LoadData(); // Tải lại danh sách
                    SelectedBacSi = new BacSiModel(); // Xóa trắng form
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi: " + ex.Message);
            }
        }

        private void XoaBacSi()
        {
            if (!DBConnect.RequireAdmin("Xóa bác sĩ")) return;

            if (MessageBox.Show("Bạn có chắc muốn xóa?", "Xác nhận", MessageBoxButton.YesNo) == MessageBoxResult.Yes)
            {
                try
                {
                    using (var conn = new SqlConnection(DBConnect.ConnectionString))
                    {
                        conn.Open();
                        string sql = "EXEC SP_XoaBacSi @ma";
                        var cmd = new SqlCommand(sql, conn);
                        cmd.Parameters.AddWithValue("@ma", SelectedBacSi.MaBS);
                        cmd.ExecuteNonQuery();

                        MessageBox.Show("Đã xóa!");
                        LoadData();
                        SelectedBacSi = new BacSiModel();
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Lỗi: " + ex.Message);
                }
            }
        }
        private void SuaBacSi()
        {
            if (!DBConnect.RequireAdmin("Sửa bác sĩ")) return;

            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();

                    // Câu lệnh Update đơn giản, sử dụng luôn dữ liệu từ SelectedBacSi
                    string sqlUpdate = @"EXEC SP_SuaBacSi @ma, @ten, @ck, @kn, @sep";

                    var cmdUpdate = new SqlCommand(sqlUpdate, conn);

                    cmdUpdate.Parameters.AddWithValue("@ma", SelectedBacSi.MaBS);

                    // Xử lý các trường có thể null hoặc rỗng
                    cmdUpdate.Parameters.AddWithValue("@ten", string.IsNullOrWhiteSpace(SelectedBacSi.HoTenBS) ? (object)DBNull.Value : SelectedBacSi.HoTenBS);
                    cmdUpdate.Parameters.AddWithValue("@ck", string.IsNullOrWhiteSpace(SelectedBacSi.ChuyenKhoa) ? (object)DBNull.Value : SelectedBacSi.ChuyenKhoa);
                    cmdUpdate.Parameters.AddWithValue("@kn", SelectedBacSi.NamKinhNghiem);

                    if (string.IsNullOrWhiteSpace(SelectedBacSi.MaTruongKhoa))
                        cmdUpdate.Parameters.AddWithValue("@sep", DBNull.Value);
                    else
                        cmdUpdate.Parameters.AddWithValue("@sep", SelectedBacSi.MaTruongKhoa);

                    int rowsAffected = cmdUpdate.ExecuteNonQuery();

                    if (rowsAffected > 0)
                    {
                        MessageBox.Show($"Đã cập nhật thông tin cho bác sĩ {SelectedBacSi.MaBS}!");
                        LoadData(); // Load lại để làm mới lưới dữ liệu
                        SelectedBacSi = new BacSiModel(); // Reset form nhập liệu
                    }
                    else
                    {
                        MessageBox.Show("Không tìm thấy Bác sĩ có mã này để sửa!");
                    }
                }
            }
            catch (SqlException ex)
            {
                if (ex.Number == 547)
                {
                    if (ex.Message.Contains("CK_BACSI_NAMKN"))
                        MessageBox.Show("Nếu sửa Kinh nghiệm, số năm phải > 1!", "Vi phạm điều kiện");
                    else
                        MessageBox.Show("Mã Trưởng khoa mới nhập không tồn tại!", "Lỗi tham chiếu");
                }
                else
                {
                    MessageBox.Show("Lỗi CSDL: " + ex.Message);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi hệ thống: " + ex.Message);
            }
        }
        // --- HÀM XUẤT EXCEL ---
        private void XuatExcel()
        {
            if (!DBConnect.RequireAdmin("Xuất Excel bác sĩ")) return;

            if (DanhSachBacSi == null || DanhSachBacSi.Count == 0)
            {
                MessageBox.Show("Không có dữ liệu để xuất!", "Thông báo");
                return;
            }

            Microsoft.Win32.SaveFileDialog saveFileDialog = new Microsoft.Win32.SaveFileDialog();
            // Đổi đuôi file sang chuẩn Excel .xlsx
            saveFileDialog.Filter = "Excel Files (*.xlsx)|*.xlsx";
            saveFileDialog.FileName = "DanhSach_BacSi.xlsx";

            if (saveFileDialog.ShowDialog() == true)
            {
                try
                {
                    using (var workbook = new XLWorkbook())
                    {
                        var worksheet = workbook.Worksheets.Add("Danh sách Bác Sĩ");

                        // 1. Tạo Tiêu đề các cột (Header)
                        worksheet.Cell(1, 1).Value = "Mã BS";
                        worksheet.Cell(1, 2).Value = "Họ Tên";
                        worksheet.Cell(1, 3).Value = "Chuyên Khoa";
                        worksheet.Cell(1, 4).Value = "Kinh Nghiệm";
                        worksheet.Cell(1, 5).Value = "Mã Trưởng Khoa";

                        // Bôi đậm và tô màu nền cho dòng Tiêu đề
                        var headerRange = worksheet.Range("A1:E1");
                        headerRange.Style.Font.Bold = true;
                        headerRange.Style.Fill.BackgroundColor = XLColor.LightBlue;
                        headerRange.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                        // 2. Đổ dữ liệu từ DanhSachBacSi vào Excel
                        int row = 2; // Bắt đầu từ dòng số 2
                        foreach (var bs in DanhSachBacSi)
                        {
                            worksheet.Cell(row, 1).Value = bs.MaBS;
                            worksheet.Cell(row, 2).Value = bs.HoTenBS;
                            worksheet.Cell(row, 3).Value = bs.ChuyenKhoa;
                            worksheet.Cell(row, 4).Value = bs.NamKinhNghiem;
                            worksheet.Cell(row, 5).Value = bs.MaTruongKhoa;
                            row++;
                        }

                        // Tự động căn chỉnh độ rộng các cột cho vừa với chữ
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

        //Nhập từ FILE
        private void NhapTuFile()
        {
            if (!DBConnect.RequireAdmin("Nhập Excel bác sĩ")) return;

            Microsoft.Win32.OpenFileDialog dlg = new Microsoft.Win32.OpenFileDialog();
            dlg.Filter = "Excel Files (*.xlsx)|*.xlsx";
            dlg.Title = "Chọn file Excel Bác Sĩ";

            if (dlg.ShowDialog() == true)
            {
                try
                {
                    DataTable dt = new DataTable();
                    dt.Columns.Add("MABS", typeof(string));
                    dt.Columns.Add("HOTEN_BS", typeof(string));
                    dt.Columns.Add("CHUYENKHOA", typeof(string));
                    dt.Columns.Add("NAMKINHNGHIEM", typeof(int));
                    dt.Columns.Add("MA_TRUONGKHOA", typeof(string));

                    // Đọc file Excel bằng ClosedXML
                    using (var workbook = new XLWorkbook(dlg.FileName))
                    {
                        var worksheet = workbook.Worksheet(1); // Lấy sheet đầu tiên
                        var rows = worksheet.RangeUsed().RowsUsed(); // Chỉ lấy các dòng có chứa dữ liệu

                        bool isFirstRow = true;
                        foreach (var row in rows)
                        {
                            // Bỏ qua dòng số 1 (vì đó là dòng Tiêu đề cột)
                            if (isFirstRow)
                            {
                                isFirstRow = false;
                                continue;
                            }

                            string maBS = row.Cell(1).GetString().Trim();
                            string hoTen = row.Cell(2).GetString().Trim();
                            string chuyenKhoa = row.Cell(3).GetString().Trim();

                            // Xử lý an toàn cho số năm kinh nghiệm
                            string kinhNghiemStr = row.Cell(4).GetString().Trim();
                            int.TryParse(kinhNghiemStr, out int kinhNghiem);

                            string maTruongKhoa = row.Cell(5).GetString().Trim();
                            object maTKObj = string.IsNullOrWhiteSpace(maTruongKhoa) ? DBNull.Value : (object)maTruongKhoa;

                            // Thêm vào DataTable
                            if (!string.IsNullOrEmpty(maBS))
                            {
                                dt.Rows.Add(maBS, hoTen, chuyenKhoa, kinhNghiem, maTKObj);
                            }
                        }
                    }

                    if (dt.Rows.Count == 0)
                    {
                        MessageBox.Show("File rỗng hoặc không có dữ liệu phù hợp!", "Cảnh báo");
                        return;
                    }

                    // Đẩy toàn bộ dữ liệu vào SQL bằng SqlBulkCopy
                    using (SqlConnection conn = new SqlConnection(DBConnect.ConnectionString))
                    {
                        conn.Open();
                        using (SqlBulkCopy bulkCopy = new SqlBulkCopy(conn))
                        {
                            bulkCopy.DestinationTableName = "BACSI";

                            // Map đúng tên cột để tránh lỗi
                            bulkCopy.ColumnMappings.Add("MABS", "MABS");
                            bulkCopy.ColumnMappings.Add("HOTEN_BS", "HOTEN_BS");
                            bulkCopy.ColumnMappings.Add("CHUYENKHOA", "CHUYENKHOA");
                            bulkCopy.ColumnMappings.Add("NAMKINHNGHIEM", "NAMKINHNGHIEM");
                            bulkCopy.ColumnMappings.Add("MA_TRUONGKHOA", "MA_TRUONGKHOA");

                            bulkCopy.WriteToServer(dt);
                            MessageBox.Show($"Đã nhập thành công {dt.Rows.Count} bác sĩ từ file Excel!", "Thành công");

                            LoadData(); // Cập nhật lại giao diện
                        }
                    }
                }
                catch (SqlException ex)
                {
                    if (ex.Number == 2627) MessageBox.Show("Lỗi: Mã Bác sĩ trong file Excel bị trùng với dữ liệu đã có trong phần mềm!");
                    else if (ex.Number == 547) MessageBox.Show("Lỗi: Mã Trưởng khoa trong file Excel không tồn tại!");
                    else MessageBox.Show("Lỗi CSDL: " + ex.Message);
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Lỗi đọc file (Vui lòng đóng file Excel trước khi nhập): " + ex.Message);
                }
            }
        }
        // --- HÀM TÌM BÁC SĨ LÃO LÀNG ---
        private void BSLaoLang()
        {
            string sql = @"EXEC SP_BSLaoLang";
            DataTable dt = DBConnect.GetData(sql);

            if (dt.Rows.Count > 0)
            {
                // Cập nhật lại DanhSachBacSi để giao diện tự động thay đổi
                DanhSachBacSi.Clear();
                foreach (DataRow row in dt.Rows)
                {
                    DanhSachBacSi.Add(new BacSiModel
                    {
                        MaBS = row["MABS"].ToString(),
                        HoTenBS = row["HOTEN_BS"].ToString(),
                        ChuyenKhoa = row["CHUYENKHOA"].ToString(),
                        NamKinhNghiem = row["NAMKINHNGHIEM"] != DBNull.Value ? Convert.ToInt32(row["NAMKINHNGHIEM"]) : 0,
                        MaTruongKhoa = row["MA_TRUONGKHOA"].ToString(),
                        CapBac = row["CAPBAC"].ToString()
                    });
                }
                MessageBox.Show($"Danh sách các Bác sĩ có kinh nghiệm trên mức trung bình ({dt.Rows.Count} người).");
            }
            else
            {
                MessageBox.Show("Không có bác sĩ nào nổi bật hơn mức trung bình (hoặc dữ liệu chưa đủ).");
                LoadData(); // Load lại dữ liệu gốc nếu không có ai
            }
        }
    }  
}


