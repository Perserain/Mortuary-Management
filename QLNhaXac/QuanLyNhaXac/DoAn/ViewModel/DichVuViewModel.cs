using ClosedXML.Excel;
using DoAn.Model;
using DoAn.Views.Shared;
using System;
using System.Collections.ObjectModel;
using System.Data;
using Microsoft.Data.SqlClient;
using System.Windows;
using System.Windows.Input;
using DoAn.Core;

namespace DoAn.ViewModel
{
    public class DichVuViewModel : BaseViewModel
    {
        public ObservableCollection<DichVuModel> DanhSachDichVu { get; set; }

        private DichVuModel _newDichVu;
        public DichVuModel NewDichVu
        {
            get => _newDichVu;
            set { _newDichVu = value; OnPropertyChanged(); }
        }

        private DichVuModel _selectedDichVu;
        public DichVuModel SelectedDichVu
        {
            get => _selectedDichVu;
            set
            {
                _selectedDichVu = value;
                OnPropertyChanged();
                if (_selectedDichVu != null)
                {
                    NewDichVu = new DichVuModel
                    {
                        MaDV = _selectedDichVu.MaDV,
                        TenDV = _selectedDichVu.TenDV,
                        GiaTien = _selectedDichVu.GiaTien
                    };
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
        public ICommand DichVuECommand { get; set; }
        public ICommand XuatExcelCommand { get; set; }
        public ICommand NhapTuFileCommand { get; set; }
        public ICommand XemChiTietCommand { get; set; }

        public DichVuViewModel()
        {
            DanhSachDichVu = new ObservableCollection<DichVuModel>();

            LoadCommand = new RelayCommand(p => LoadData());
            ThemCommand = new RelayCommand(p => ThemDichVu(), p => NewDichVu != null && !string.IsNullOrWhiteSpace(NewDichVu.MaDV) && !string.IsNullOrWhiteSpace(NewDichVu.TenDV));
            SuaCommand = new RelayCommand(p => SuaDichVu(), p => NewDichVu != null && !string.IsNullOrWhiteSpace(NewDichVu.MaDV));
            XoaCommand = new RelayCommand(p => XoaDichVu(), p => NewDichVu != null && !string.IsNullOrWhiteSpace(NewDichVu.MaDV));
            DichVuECommand = new RelayCommand(p => DichVuE());
            XuatExcelCommand = new RelayCommand(p => XuatExcel());
            NhapTuFileCommand = new RelayCommand(p => NhapTuFile());
            XemChiTietCommand = new RelayCommand(p => XemChiTiet(), p => NewDichVu != null && !string.IsNullOrEmpty(NewDichVu.MaDV));

            LoadData();
            ResetForm();
        }


        private void LoadData()
        {
            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;
            DanhSachDichVu.Clear();
            string sql = "EXEC SP_DSDichVu";
            DataTable dt = DBConnect.GetData(sql);

            foreach (DataRow row in dt.Rows)
            {
                DanhSachDichVu.Add(new DichVuModel
                {
                    MaDV = row["MADV"].ToString(),
                    TenDV = row["TENDV"].ToString(),
                    GiaTien = row["GIATIEN"] != DBNull.Value ? Convert.ToDecimal(row["GIATIEN"]) : 0
                });
            }
        }

        private void XemChiTiet()
        {
            DetailWindow f = new DetailWindow(NewDichVu, "CHI TIẾT DỊCH VỤ");
            f.ShowDialog();
        }

        private string TaoMaDV()
        {
            if (DanhSachDichVu == null || DanhSachDichVu.Count == 0) return "DV001";

            var maxId = DanhSachDichVu
                .Select(d => {
                    if (d.MaDV != null && d.MaDV.StartsWith("DV") && int.TryParse(d.MaDV.Substring(2), out int num))
                        return num;
                    return 0;
                })
                .DefaultIfEmpty(0)
                .Max();

            return $"DV{(maxId + 1):D3}";
        }
        private void ResetForm()
        {
            NewDichVu = new DichVuModel();
            NewDichVu.MaDV = TaoMaDV();
        }
        private void ThemDichVu()
        {
            if (!DBConnect.RequireStaffOrAdmin("Thêm dịch vụ")) return;
            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    var cmd = new SqlCommand("EXEC SP_ThemDichVu @ma, @ten, @gia", conn);
                    cmd.Parameters.AddWithValue("@ma", NewDichVu.MaDV);
                    cmd.Parameters.AddWithValue("@ten", NewDichVu.TenDV);
                    cmd.Parameters.AddWithValue("@gia", NewDichVu.GiaTien);
                    cmd.ExecuteNonQuery();

                    MessageBox.Show("Thêm dịch vụ thành công!");
                    LoadData();
                    ResetForm();
                }
            }
            catch (Exception ex) { MessageBox.Show("Lỗi: " + ex.Message); }
        }

        private void SuaDichVu()
        {
            if (!DBConnect.RequireStaffOrAdmin("Sửa dịch vụ")) return;
            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    var cmdUpdate = new SqlCommand("EXEC SP_SuaDichVu @ma, @t, @g", conn);
                    cmdUpdate.Parameters.AddWithValue("@ma", NewDichVu.MaDV);
                    cmdUpdate.Parameters.AddWithValue("@t", string.IsNullOrWhiteSpace(NewDichVu.TenDV) ? DBNull.Value : (object)NewDichVu.TenDV);
                    cmdUpdate.Parameters.AddWithValue("@g", NewDichVu.GiaTien);

                    if (cmdUpdate.ExecuteNonQuery() > 0)
                    {
                        MessageBox.Show("Cập nhật dịch vụ thành công!");
                        LoadData();
                        ResetForm();
                    }
                }
            }
            catch (Exception ex) { MessageBox.Show("Lỗi: " + ex.Message); }
        }

        private void XoaDichVu()
        {
            if (!DBConnect.RequireStaffOrAdmin("Xóa dịch vụ")) return;
            if (MessageBox.Show("Xóa dịch vụ này?", "Xác nhận", MessageBoxButton.YesNo) == MessageBoxResult.Yes)
            {
                try
                {
                    using (var conn = new SqlConnection(DBConnect.ConnectionString))
                    {
                        conn.Open();
                        var cmd = new SqlCommand("EXEC SP_XoaDichVu @ma", conn);
                        cmd.Parameters.AddWithValue("@ma", NewDichVu.MaDV);
                        cmd.ExecuteNonQuery();

                        MessageBox.Show("Đã xóa!");
                        LoadData();
                        ResetForm();
                    }
                }
                catch (Exception) { MessageBox.Show("Không thể xóa dịch vụ này (Đang có người sử dụng)."); }
            }
        }

        private void DichVuE()
        {
            try
            {
                string sql = "EXEC SP_DichVuE";
                DataTable dt = DBConnect.GetData(sql);

                if (dt.Rows.Count > 0)
                {
                    DanhSachDichVu.Clear();
                    foreach (DataRow row in dt.Rows)
                    {
                        DanhSachDichVu.Add(new DichVuModel
                        {
                            MaDV = row["MADV"].ToString(),
                            TenDV = row["TENDV"].ToString(),
                            GiaTien = row["GIATIEN"] != DBNull.Value ? Convert.ToDecimal(row["GIATIEN"]) : 0
                        });
                    }
                    MessageBox.Show($"Có {dt.Rows.Count} dịch vụ chưa từng được ai sử dụng! \n(Cân nhắc giảm giá hoặc loại bỏ)");
                }
                else
                {
                    MessageBox.Show("Mừng quá! Dịch vụ nào cũng đắt khách (đã được dùng ít nhất 1 lần)");
                    LoadData();
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi: Có thể bạn chưa tạo bảng SUDUNG trong SQL?\n" + ex.Message);
            }
        }

        private string TinhPhanKhuc(decimal gia)
        {
            if (gia < 500000) return "Bình dân";
            if (gia < 2000000) return "Trung bình";
            return "Cao cấp";
        }

        // --- HÀM XUẤT EXCEL
        private void XuatExcel()
        {
            if (!DBConnect.RequireStaffOrAdmin("Xuất Excel dịch vụ")) return;

            if (DanhSachDichVu == null || DanhSachDichVu.Count == 0)
            {
                MessageBox.Show("Không có dữ liệu để xuất!", "Thông báo");
                return;
            }

            Microsoft.Win32.SaveFileDialog saveFileDialog = new Microsoft.Win32.SaveFileDialog();
            saveFileDialog.Filter = "Excel Files (*.xlsx)|*.xlsx";
            saveFileDialog.FileName = "BangGia_DichVu.xlsx";

            if (saveFileDialog.ShowDialog() == true)
            {
                try
                {
                    using (var workbook = new XLWorkbook())
                    {
                        var worksheet = workbook.Worksheets.Add("Bảng Giá Dịch Vụ");

                        // 1. Tạo Tiêu đề các cột
                        worksheet.Cell(1, 1).Value = "Mã DV";
                        worksheet.Cell(1, 2).Value = "Tên Dịch Vụ";
                        worksheet.Cell(1, 3).Value = "Giá Tiền (VNĐ)";

                        // Nếu bạn có dùng VIEW phân khúc giá ở bài trước thì xuất luôn cột này
                        worksheet.Cell(1, 4).Value = "Phân Khúc";

                        // Định dạng Tiêu đề (Bôi đậm, nền xanh lơ)
                        var headerRange = worksheet.Range("A1:D1");
                        headerRange.Style.Font.Bold = true;
                        headerRange.Style.Fill.BackgroundColor = XLColor.LightCyan;
                        headerRange.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                        // 2. Đổ dữ liệu vào các dòng
                        int row = 2;
                        foreach (var dv in DanhSachDichVu)
                        {
                            worksheet.Cell(row, 1).Value = dv.MaDV;
                            worksheet.Cell(row, 2).Value = dv.TenDV;

                            // Gán giá tiền và định dạng số có dấu phẩy (VD: 1,500,000)
                            worksheet.Cell(row, 3).Value = dv.GiaTien;
                            worksheet.Cell(row, 3).Style.NumberFormat.Format = "#,##0";

                            worksheet.Cell(row, 4).Value = TinhPhanKhuc(dv.GiaTien);
                            row++;
                        }

                        // Tự động căn chỉnh độ rộng các cột
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

        // --- HÀM NHẬP EXCEL ---
        private void NhapTuFile()
        {
            if (!DBConnect.RequireStaffOrAdmin("Nhập Excel dịch vụ")) return;

            Microsoft.Win32.OpenFileDialog dlg = new Microsoft.Win32.OpenFileDialog();
            dlg.Filter = "Excel Files (*.xlsx)|*.xlsx";
            dlg.Title = "Chọn file Excel Dịch Vụ";

            if (dlg.ShowDialog() == true)
            {
                try
                {
                    DataTable dt = new DataTable();
                    dt.Columns.Add("MADV", typeof(string));
                    dt.Columns.Add("TENDV", typeof(string));
                    dt.Columns.Add("GIATIEN", typeof(decimal));

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

                            string maDV = row.Cell(1).GetString().Trim();
                            string tenDV = row.Cell(2).GetString().Trim();

                            // Xử lý Giá tiền an toàn
                            string giaTienStr = row.Cell(3).GetString().Trim();
                            decimal giaTien = decimal.TryParse(giaTienStr, out decimal gt) ? gt : 0;

                            // Thêm vào DataTable (Mã và Tên không được rỗng)
                            if (!string.IsNullOrEmpty(maDV) && !string.IsNullOrEmpty(tenDV))
                            {
                                dt.Rows.Add(maDV, tenDV, giaTien);
                            }
                        }
                    }

                    if (dt.Rows.Count == 0)
                    {
                        MessageBox.Show("File rỗng hoặc bạn chưa nhập đủ Mã DV và Tên DV!", "Cảnh báo");
                        return;
                    }

                    using (SqlConnection conn = new SqlConnection(DBConnect.ConnectionString))
                    {
                        conn.Open();
                        using (SqlBulkCopy bulkCopy = new SqlBulkCopy(conn))
                        {
                            bulkCopy.DestinationTableName = "DICHVU";

                            // Chỉ map 3 cột chính của CSDL
                            bulkCopy.ColumnMappings.Add("MADV", "MADV");
                            bulkCopy.ColumnMappings.Add("TENDV", "TENDV");
                            bulkCopy.ColumnMappings.Add("GIATIEN", "GIATIEN");

                            bulkCopy.WriteToServer(dt);
                            MessageBox.Show($"Đã nhập thành công {dt.Rows.Count} dịch vụ từ file Excel!", "Thành công");

                            LoadData(); // Load lại giao diện
                        }
                    }
                }
                catch (SqlException ex)
                {
                    if (ex.Number == 2627)
                        MessageBox.Show("Lỗi: Có mã Dịch Vụ trong file Excel đã tồn tại trong phần mềm!");
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



