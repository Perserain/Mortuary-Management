using ClosedXML.Excel;
using DoAn.Core;
using Microsoft.Win32;
using System;
using System.Collections.ObjectModel;
using System.Data;
using System.Diagnostics;
using System.Windows;
using System.Windows.Input;

namespace DoAn.ViewModel
{
    public class BaoCaoRow : BaseViewModel
    {
        public string Col1 { get; set; }
        public string Col2 { get; set; }
        public string Col3 { get; set; }
        public string Col4 { get; set; }
        public string Col5 { get; set; }
        public string Col6 { get; set; }
        public string Col7 { get; set; }
        public string Col8 { get; set; }
    }

    public class BaoCaoViewModel : BaseViewModel
    {
        // ──────────────────────────────────────────────
        //  Bộ lọc năm
        // ──────────────────────────────────────────────
        private int _namChon = DateTime.Now.Year;
        public int NamChon
        {
            get => _namChon;
            set { _namChon = value; OnPropertyChanged(); }
        }

        public ObservableCollection<int> DSNam { get; set; } = new();

        // ──────────────────────────────────────────────
        //  Kết quả 3 tab
        // ──────────────────────────────────────────────
        public ObservableCollection<BaoCaoRow> KetQuaThiHai { get; set; } = new();
        public ObservableCollection<BaoCaoRow> KetQuaDoanhThu { get; set; } = new();
        public ObservableCollection<BaoCaoRow> KetQuaNhanVien { get; set; } = new();

        // Headers cho từng tab
        public string[] HeadersThiHai { get; } = { "Năm", "Tháng", "Tổng thi hài", "Nam", "Nữ", "Vị thành niên", "Trưởng thành", "Cao tuổi" };
        public string[] HeadersDoanhThu { get; } = { "Năm", "Tháng", "Số hóa đơn", "Tổng doanh thu", "Đã thanh toán", "Chưa thanh toán", "", "" };
        public string[] HeadersNhanVien { get; } = { "Nhân viên", "Tổng HĐ", "Đã TT", "Chưa TT", "Doanh thu thu được", "", "", "" };

        // DataTable gốc để xuất Excel
        private DataTable _dtThiHai;
        private DataTable _dtDoanhThu;
        private DataTable _dtNhanVien;

        private int _tabDangChon = 0;
        public int TabDangChon
        {
            get => _tabDangChon;
            set { _tabDangChon = value; OnPropertyChanged(); }
        }

        private string _thongBao = "";
        public string ThongBao
        {
            get => _thongBao;
            set { _thongBao = value; OnPropertyChanged(); }
        }

        // ──────────────────────────────────────────────
        //  Commands
        // ──────────────────────────────────────────────
        public ICommand LoadThiHaiCommand { get; set; }
        public ICommand LoadDoanhThuCommand { get; set; }
        public ICommand LoadNhanVienCommand { get; set; }
        public ICommand XuatExcelCommand { get; set; }

        public BaoCaoViewModel()
        {
            // Tạo danh sách năm (5 năm gần nhất)
            for (int y = DateTime.Now.Year; y >= DateTime.Now.Year - 5; y--)
                DSNam.Add(y);

            LoadThiHaiCommand = new RelayCommand(p => LoadBaoCaoThiHai());
            LoadDoanhThuCommand = new RelayCommand(p => LoadBaoCaoDoanhThu());
            LoadNhanVienCommand = new RelayCommand(p => LoadBaoCaoNhanVien());
            XuatExcelCommand = new RelayCommand(p => XuatExcel());

            // Load mặc định tab đầu
            LoadBaoCaoThiHai();
        }

        // ──────────────────────────────────────────────
        //  Load báo cáo thi hài theo tháng
        // ──────────────────────────────────────────────
        private void LoadBaoCaoThiHai()
        {
            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;
            KetQuaThiHai.Clear();
            try
            {
                _dtThiHai = DBConnect.GetData($"EXEC SP_BaoCao_ThiHaiTheoThang {NamChon}");
                foreach (DataRow row in _dtThiHai.Rows)
                {
                    KetQuaThiHai.Add(new BaoCaoRow
                    {
                        Col1 = row["Nam"]?.ToString(),
                        Col2 = row["Thang"]?.ToString(),
                        Col3 = row["SoLuongThiHai"]?.ToString(),
                        Col4 = row["SoNam"]?.ToString(),
                        Col5 = row["SoNu"]?.ToString(),
                        Col6 = row["ViThanhNien"]?.ToString(),
                        Col7 = row["TruongThanh"]?.ToString(),
                        Col8 = row["CaoTuoi"]?.ToString()
                    });
                }
                ThongBao = $"Báo cáo thi hài năm {NamChon}: {KetQuaThiHai.Count} tháng có dữ liệu";
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi tải báo cáo thi hài: " + ex.Message, "Lỗi");
            }
        }

        // ──────────────────────────────────────────────
        //  Load báo cáo doanh thu theo tháng
        // ──────────────────────────────────────────────
        private void LoadBaoCaoDoanhThu()
        {
            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;
            KetQuaDoanhThu.Clear();
            try
            {
                _dtDoanhThu = DBConnect.GetData($"EXEC SP_BaoCao_DoanhThuTheoThang {NamChon}");
                foreach (DataRow row in _dtDoanhThu.Rows)
                {
                    KetQuaDoanhThu.Add(new BaoCaoRow
                    {
                        Col1 = row["Nam"]?.ToString(),
                        Col2 = row["Thang"]?.ToString(),
                        Col3 = row["SoHoaDon"]?.ToString(),
                        Col4 = FormatTien(row["TongDoanhThu"]),
                        Col5 = FormatTien(row["DaThanhToan"]),
                        Col6 = FormatTien(row["ChuaThanhToan"])
                    });
                }
                ThongBao = $"Báo cáo doanh thu năm {NamChon}: {KetQuaDoanhThu.Count} tháng có dữ liệu";
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi tải báo cáo doanh thu: " + ex.Message, "Lỗi");
            }
        }

        // ──────────────────────────────────────────────
        //  Load báo cáo nhân viên
        // ──────────────────────────────────────────────
        private void LoadBaoCaoNhanVien()
        {
            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;
            KetQuaNhanVien.Clear();
            try
            {
                _dtNhanVien = DBConnect.GetData("SELECT * FROM VIEW_ThongKe_NhanVien_HoaDon ORDER BY TongHoaDon DESC");
                foreach (DataRow row in _dtNhanVien.Rows)
                {
                    KetQuaNhanVien.Add(new BaoCaoRow
                    {
                        Col1 = row["TenNhanVien"]?.ToString(),
                        Col2 = row["TongHoaDon"]?.ToString(),
                        Col3 = row["DaThanhToan"]?.ToString(),
                        Col4 = row["ChuaThanhToan"]?.ToString(),
                        Col5 = FormatTien(row["DoanhThuThuDuoc"])
                    });
                }
                ThongBao = $"Tổng cộng {KetQuaNhanVien.Count} nhân viên có lập hóa đơn";
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi tải báo cáo nhân viên: " + ex.Message, "Lỗi");
            }
        }

        // ──────────────────────────────────────────────
        //  Xuất Excel — tab đang chọn
        // ──────────────────────────────────────────────
        private void XuatExcel()
        {
            if (!DBConnect.RequireStaffOrAdmin("Xuất báo cáo Excel")) return;

            DataTable dt = null;
            string tenTab = "";
            string[] headers = null;

            switch (TabDangChon)
            {
                case 0:
                    dt = _dtThiHai;
                    tenTab = $"ThiHai_{NamChon}";
                    headers = HeadersThiHai;
                    break;
                case 1:
                    dt = _dtDoanhThu;
                    tenTab = $"DoanhThu_{NamChon}";
                    headers = HeadersDoanhThu;
                    break;
                case 2:
                    dt = _dtNhanVien;
                    tenTab = "NhanVien";
                    headers = HeadersNhanVien;
                    break;
            }

            if (dt == null || dt.Rows.Count == 0)
            {
                MessageBox.Show("Chưa có dữ liệu để xuất. Vui lòng tải báo cáo trước.", "Thông báo");
                return;
            }

            var dlg = new SaveFileDialog
            {
                Filter = "Excel Workbook (*.xlsx)|*.xlsx",
                FileName = $"BaoCao_{tenTab}_{DateTime.Now:yyyyMMdd}.xlsx",
                Title = "Lưu báo cáo Excel"
            };
            if (dlg.ShowDialog() != true) return;

            try
            {
                using var wb = new XLWorkbook();
                var ws = wb.Worksheets.Add("Báo Cáo");

                // Tiêu đề
                ws.Cell(1, 1).Value = $"BÁO CÁO: {tenTab.Replace("_", " ").ToUpper()}";
                ws.Cell(1, 1).Style.Font.Bold = true;
                ws.Cell(1, 1).Style.Font.FontSize = 14;
                ws.Range(1, 1, 1, dt.Columns.Count).Merge();
                ws.Cell(1, 1).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                ws.Cell(2, 1).Value = "Xuất ngày: " + DateTime.Now.ToString("dd/MM/yyyy HH:mm");
                ws.Cell(2, 1).Style.Font.Italic = true;

                // Header row
                for (int c = 0; c < dt.Columns.Count; c++)
                {
                    ws.Cell(4, c + 1).Value = dt.Columns[c].ColumnName;
                    ws.Cell(4, c + 1).Style.Font.Bold = true;
                    ws.Cell(4, c + 1).Style.Fill.BackgroundColor = XLColor.FromHtml("#1E293B");
                    ws.Cell(4, c + 1).Style.Font.FontColor = XLColor.White;
                    ws.Cell(4, c + 1).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                }

                // Data rows
                for (int r = 0; r < dt.Rows.Count; r++)
                {
                    for (int c = 0; c < dt.Columns.Count; c++)
                    {
                        ws.Cell(5 + r, c + 1).Value = dt.Rows[r][c]?.ToString();
                    }
                    if (r % 2 == 1)
                        ws.Range(5 + r, 1, 5 + r, dt.Columns.Count).Style.Fill.BackgroundColor = XLColor.FromHtml("#F8FAFC");
                }

                ws.Columns().AdjustToContents();
                var tableRange = ws.Range(4, 1, 4 + dt.Rows.Count, dt.Columns.Count);
                tableRange.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
                tableRange.Style.Border.InsideBorder = XLBorderStyleValues.Hair;

                wb.SaveAs(dlg.FileName);

                var ask = MessageBox.Show("Xuất Excel thành công! Bạn có muốn mở file không?",
                    "Thành công", MessageBoxButton.YesNo, MessageBoxImage.Question);
                if (ask == MessageBoxResult.Yes)
                    Process.Start(new ProcessStartInfo(dlg.FileName) { UseShellExecute = true });
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi xuất Excel: " + ex.Message, "Lỗi");
            }
        }

        private static string FormatTien(object val)
        {
            if (val == null || val == DBNull.Value) return "0";
            if (decimal.TryParse(val.ToString(), out decimal d))
                return d.ToString("N0") + " đ";
            return val.ToString();
        }
    }
}
