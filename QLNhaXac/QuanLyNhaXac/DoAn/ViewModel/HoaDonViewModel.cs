using ClosedXML.Excel;
using DoAn.Core;
using DoAn.Model;
using Microsoft.Data.SqlClient;
using Microsoft.Win32;
using System;
using System.Collections.ObjectModel;
using System.Data;
using System.Diagnostics;
using System.Linq;
using System.Windows;
using System.Windows.Input;

namespace DoAn.ViewModel
{
    public class HoaDonViewModel : BaseViewModel
    {
        // ──────────────────────────────────────────────
        //  Collections
        // ──────────────────────────────────────────────
        public ObservableCollection<HoaDonModel> DSHoaDonGoc { get; set; } = new();      // toàn bộ từ DB
        public ObservableCollection<HoaDonModel> DSHoaDon { get; set; } = new();         // hiển thị (đã filter)
        public ObservableCollection<ThiHaiModel> DSThiHai { get; set; } = new();
        public ObservableCollection<SuDungModel> DSDichVuDaDung { get; set; } = new();   // chi tiết dịch vụ của HD đang chọn

        public string[] DSTrangThai { get; } = { "Tất cả", "Chưa thanh toán", "Nợ", "Đã thanh toán", "Miễn phí" };
        public string[] DSPhuongThuc { get; } = { "Tiền mặt", "Chuyển khoản", "Thẻ ngân hàng", "Khác" };

        // ──────────────────────────────────────────────
        //  Tab lọc trạng thái
        // ──────────────────────────────────────────────
        private string _tabDangChon = "Tất cả";
        public string TabDangChon
        {
            get => _tabDangChon;
            set { _tabDangChon = value; OnPropertyChanged(); ApplyFilter(); }
        }

        private DateTime? _tuNgay;
        public DateTime? TuNgay
        {
            get => _tuNgay;
            set { _tuNgay = value; OnPropertyChanged(); ApplyFilter(); }
        }

        private DateTime? _denNgay;
        public DateTime? DenNgay
        {
            get => _denNgay;
            set { _denNgay = value; OnPropertyChanged(); ApplyFilter(); }
        }

        private string _timKiem;
        public string TimKiem
        {
            get => _timKiem;
            set { _timKiem = value; OnPropertyChanged(); ApplyFilter(); }
        }

        // ──────────────────────────────────────────────
        //  Dòng đang chọn trong DataGrid
        // ──────────────────────────────────────────────
        private HoaDonModel _selected;
        public HoaDonModel Selected
        {
            get => _selected;
            set
            {
                _selected = value;
                OnPropertyChanged();
                if (_selected != null)
                {
                    PhuongThucThanhToan = string.IsNullOrEmpty(_selected.PHUONGTHUCTT)
                        ? "Tiền mặt" : _selected.PHUONGTHUCTT;
                    // Load dịch vụ thuộc đúng hóa đơn này (theo MAHD, không phải MATH)
                    LoadDichVuTheoHoaDon(_selected.MAHD);
                }
                else
                {
                    DSDichVuDaDung.Clear();
                }
            }
        }

        // ──────────────────────────────────────────────
        //  Form tạo hóa đơn mới
        // ──────────────────────────────────────────────
        private ThiHaiModel _selectedThiHaiMoi;
        public ThiHaiModel SelectedThiHaiMoi
        {
            get => _selectedThiHaiMoi;
            set
            {
                _selectedThiHaiMoi = value;
                OnPropertyChanged();
                // Preview dịch vụ chưa lập HĐ khi chọn thi hài để tạo mới
                if (_selectedThiHaiMoi != null)
                    LoadDichVuChuaLapHD(_selectedThiHaiMoi.MaTH);
                else
                    DSDichVuChuaLap.Clear();
            }
        }

        private DateTime _ngayLapMoi = DateTime.Now;
        public DateTime NgayLapMoi
        {
            get => _ngayLapMoi;
            set { _ngayLapMoi = value; OnPropertyChanged(); }
        }

        private string _phuongThucMoi = "Tiền mặt";
        public string PhuongThucMoi
        {
            get => _phuongThucMoi;
            set { _phuongThucMoi = value; OnPropertyChanged(); }
        }

        private string _ghiChuMoi;
        public string GhiChuMoi
        {
            get => _ghiChuMoi;
            set { _ghiChuMoi = value; OnPropertyChanged(); }
        }

        // ──────────────────────────────────────────────
        //  Thanh toán hóa đơn đang chọn
        // ──────────────────────────────────────────────
        private string _phuongThucThanhToan = "Tiền mặt";
        public string PhuongThucThanhToan
        {
            get => _phuongThucThanhToan;
            set { _phuongThucThanhToan = value; OnPropertyChanged(); }
        }

        // ──────────────────────────────────────────────
        //  Tổng doanh thu (footer)
        // ──────────────────────────────────────────────
        private string _tongDoanhThu;
        public string TongDoanhThu
        {
            get => _tongDoanhThu;
            set { _tongDoanhThu = value; OnPropertyChanged(); }
        }

        private string _soLuong;
        public string SoLuong
        {
            get => _soLuong;
            set { _soLuong = value; OnPropertyChanged(); }
        }

        // ──────────────────────────────────────────────
        //  Commands
        // ──────────────────────────────────────────────
        public ICommand TaiLaiCommand { get; set; }
        public ICommand TaoHoaDonCommand { get; set; }
        public ICommand ThanhToanCommand { get; set; }
        public ICommand InHoaDonCommand { get; set; }

        public ICommand ChonTabCommand { get; set; } // <--- THÊM DÒNG NÀY

        // ──────────────────────────────────────────────
        //  Constructor
        // ──────────────────────────────────────────────
        public HoaDonViewModel()
        {
            TaiLaiCommand = new RelayCommand(p => LoadData());
            TaoHoaDonCommand = new RelayCommand(p => ExecuteTaoHoaDon(),
                                                  p => SelectedThiHaiMoi != null);
            ThanhToanCommand = new RelayCommand(p => ExecuteThanhToan(),
                                                  p => Selected != null
                                                       && Selected.TRANGTHAITT != "Đã thanh toán"
                                                       && Selected.TRANGTHAITT != "Miễn phí");


            InHoaDonCommand = new RelayCommand(p => XuatHoaDonExcel(), p => Selected != null);

            ChonTabCommand = new RelayCommand(p => {
                if (p != null) TabDangChon = p.ToString();
            });

            LoadDSThiHai();
            LoadData();
        }

        // ──────────────────────────────────────────────
        //  Load danh sách thi hài (cho form tạo hóa đơn)
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
        //  Load toàn bộ hóa đơn
        // ──────────────────────────────────────────────
        private void LoadData()
        {
            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;

            DSHoaDonGoc.Clear();
            Selected = null;

            try
            {
                DataTable dt = DBConnect.GetData("EXEC SP_DSHoaDon");
                foreach (DataRow row in dt.Rows)
                {
                    DSHoaDonGoc.Add(MapRow(row));
                }
                ApplyFilter();
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi tải hóa đơn: " + ex.Message, "Lỗi");
            }
        }

        private HoaDonModel MapRow(DataRow row)
        {
            return new HoaDonModel
            {
                MAHD = row["MAHD"].ToString(),
                MATH = row["MATH"].ToString(),
                HOTEN_TH = row["HOTEN_TH"].ToString(),
                NGUOI_NHAN = row.Table.Columns.Contains("NGUOI_NHAN") ? row["NGUOI_NHAN"]?.ToString() : "",
                SDT_NGUOI_NHAN = row.Table.Columns.Contains("SDT_NGUOI_NHAN") ? row["SDT_NGUOI_NHAN"]?.ToString() : "",
                NGAYLAP = row["NGAYLAP"] != DBNull.Value ? Convert.ToDateTime(row["NGAYLAP"]) : (DateTime?)null,
                TONGTIEN = row["TONGTIEN"] != DBNull.Value ? Convert.ToDecimal(row["TONGTIEN"]) : 0,
                TRANGTHAITT = row["TRANGTHAITT"].ToString(),
                PHUONGTHUCTT = row["PHUONGTHUCTT"]?.ToString(),
                NGAYTHANHTOAN = row["NGAYTHANHTOAN"] != DBNull.Value ? Convert.ToDateTime(row["NGAYTHANHTOAN"]) : (DateTime?)null,
                NGUOILAP = row["NGUOILAP"]?.ToString(),
                GHICHU = row["GHICHU"]?.ToString()
            };
        }

        // ──────────────────────────────────────────────
        //  Lọc theo tab / ngày / từ khóa
        // ──────────────────────────────────────────────
        private void ApplyFilter()
        {
            DSHoaDon.Clear();

            var query = DSHoaDonGoc.AsEnumerable();

            if (!string.IsNullOrEmpty(TabDangChon) && TabDangChon != "Tất cả")
                query = query.Where(h => h.TRANGTHAITT == TabDangChon);

            if (TuNgay.HasValue)
                query = query.Where(h => h.NGAYLAP.HasValue && h.NGAYLAP.Value.Date >= TuNgay.Value.Date);

            if (DenNgay.HasValue)
                query = query.Where(h => h.NGAYLAP.HasValue && h.NGAYLAP.Value.Date <= DenNgay.Value.Date);

            if (!string.IsNullOrWhiteSpace(TimKiem))
            {
                string kw = TimKiem.Trim().ToLower();
                query = query.Where(h =>
                    (h.MAHD?.ToLower().Contains(kw) ?? false) ||
                    (h.HOTEN_TH?.ToLower().Contains(kw) ?? false) ||
                    (h.NGUOI_NHAN?.ToLower().Contains(kw) ?? false));
            }

            decimal tong = 0;
            foreach (var hd in query)
            {
                DSHoaDon.Add(hd);
                tong += hd.TONGTIEN;
            }

            SoLuong = $"Tổng: {DSHoaDon.Count} hóa đơn";
            TongDoanhThu = $"Tổng tiền: {tong:N0} đ";
        }

        // ──────────────────────────────────────────────
        //  Load dịch vụ đã dùng của thi hài (cho panel chi tiết)
        // ──────────────────────────────────────────────
        // Dịch vụ thuộc hóa đơn đang chọn (theo MAHD)
        private void LoadDichVuTheoHoaDon(string maHD)
        {
            DSDichVuDaDung.Clear();
            if (string.IsNullOrEmpty(maHD) || string.IsNullOrEmpty(DBConnect.ConnectionString)) return;

            try
            {
                using var conn = new SqlConnection(DBConnect.ConnectionString);
                conn.Open();
                using var cmd = new SqlCommand("SP_DichVuTheoHoaDon", conn)
                {
                    CommandType = CommandType.StoredProcedure
                };
                cmd.Parameters.AddWithValue("@MAHD", maHD);
                using var da = new SqlDataAdapter(cmd);
                var dt = new DataTable();
                da.Fill(dt);

                foreach (DataRow row in dt.Rows)
                {
                    DSDichVuDaDung.Add(new SuDungModel
                    {
                        MaTH    = row["MATH"].ToString(),
                        TenTH   = row["HOTEN_TH"].ToString(),
                        MaDV    = row["MADV"].ToString(),
                        TenDV   = row["TENDV"].ToString(),
                        GiaTien = row["GIATIEN"] != DBNull.Value ? Convert.ToDecimal(row["GIATIEN"]) : 0,
                        NgaySD  = row["NGAYSUDUNG"] != DBNull.Value ? Convert.ToDateTime(row["NGAYSUDUNG"]) : (DateTime?)null,
                        GhiChu  = row["GHICHU"]?.ToString(),
                        MaHD    = row["MAHD"]?.ToString()
                    });
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi tải dịch vụ hóa đơn: " + ex.Message, "Lỗi");
            }
        }

        // Dịch vụ CHƯA lập HĐ của thi hài đang chọn để tạo (preview trước khi tạo HĐ)
        public ObservableCollection<SuDungModel> DSDichVuChuaLap { get; set; } = new();

        private void LoadDichVuChuaLapHD(string maTH)
        {
            DSDichVuChuaLap.Clear();
            if (string.IsNullOrEmpty(maTH) || string.IsNullOrEmpty(DBConnect.ConnectionString)) return;

            try
            {
                using var conn = new SqlConnection(DBConnect.ConnectionString);
                conn.Open();
                using var cmd = new SqlCommand("SP_DichVuChuaLapHD", conn)
                {
                    CommandType = CommandType.StoredProcedure
                };
                cmd.Parameters.AddWithValue("@MATH", maTH);
                using var da = new SqlDataAdapter(cmd);
                var dt = new DataTable();
                da.Fill(dt);

                foreach (DataRow row in dt.Rows)
                {
                    DSDichVuChuaLap.Add(new SuDungModel
                    {
                        MaTH    = row["MATH"].ToString(),
                        TenTH   = row["HOTEN_TH"].ToString(),
                        MaDV    = row["MADV"].ToString(),
                        TenDV   = row["TENDV"].ToString(),
                        GiaTien = row["GIATIEN"] != DBNull.Value ? Convert.ToDecimal(row["GIATIEN"]) : 0,
                        NgaySD  = row["NGAYSUDUNG"] != DBNull.Value ? Convert.ToDateTime(row["NGAYSUDUNG"]) : (DateTime?)null,
                        GhiChu  = row["GHICHU"]?.ToString()
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("LoadDichVuChuaLapHD: " + ex.Message);
            }
        }

        // ──────────────────────────────────────────────
        //  TẠO HÓA ĐƠN MỚI
        // ──────────────────────────────────────────────
        private void ExecuteTaoHoaDon()
        {
            if (!DBConnect.RequireStaffOrAdmin("Tạo hóa đơn")) return;
            if (SelectedThiHaiMoi == null)
            {
                MessageBox.Show("Vui lòng chọn thi hài để tạo hóa đơn.", "Thiếu thông tin");
                return;
            }

            string maHD = GenerateMAHD();

            try
            {
                using var conn = new SqlConnection(DBConnect.ConnectionString);
                conn.Open();
                using var cmd = new SqlCommand("SP_ThemHoaDon", conn)
                {
                    CommandType = CommandType.StoredProcedure
                };
                cmd.Parameters.AddWithValue("@MAHD", maHD);
                cmd.Parameters.AddWithValue("@MATH", SelectedThiHaiMoi.MaTH);
                cmd.Parameters.AddWithValue("@NGAYLAP", NgayLapMoi.Date);
                cmd.Parameters.AddWithValue("@PHUONGTHUCTT", (object?)PhuongThucMoi ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@GHICHU", (object?)GhiChuMoi ?? DBNull.Value);

                cmd.ExecuteNonQuery();
                MessageBox.Show($"Tạo hóa đơn '{maHD}' thành công!", "Thành công",
                                MessageBoxButton.OK, MessageBoxImage.Information);

                GhiChuMoi = string.Empty;
                LoadData();
            }
            catch (SqlException ex) when (ex.Number == 2627)
            {
                MessageBox.Show($"Mã hóa đơn '{maHD}' đã tồn tại. Vui lòng thử lại.", "Trùng mã");
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi tạo hóa đơn: " + ex.Message, "Lỗi");
            }
        }

        // Tự sinh mã HD theo pattern HD0001, HD0002 …
        private string GenerateMAHD()
        {
            int max = DSHoaDonGoc
                .Select(h =>
                {
                    if (h.MAHD != null && h.MAHD.StartsWith("HD") &&
                        int.TryParse(h.MAHD.Substring(2), out int n)) return n;
                    return 0;
                })
                .DefaultIfEmpty(0).Max();
            return $"HD{(max + 1):D4}";
        }

        // ──────────────────────────────────────────────
        //  THANH TOÁN HÓA ĐƠN
        // ──────────────────────────────────────────────
        private void ExecuteThanhToan()
        {
            if (!DBConnect.RequireStaffOrAdmin("Thanh toán hóa đơn")) return;
            if (Selected == null) return;

            var confirm = MessageBox.Show(
                $"Xác nhận đã thu tiền hóa đơn '{Selected.MAHD}'\n" +
                $"Số tiền: {Selected.TONGTIEN:N0} đ\n" +
                $"Phương thức: {PhuongThucThanhToan}?",
                "Xác nhận thanh toán", MessageBoxButton.YesNo, MessageBoxImage.Question);
            if (confirm != MessageBoxResult.Yes) return;

            try
            {
                using var conn = new SqlConnection(DBConnect.ConnectionString);
                conn.Open();
                using var cmd = new SqlCommand("SP_ThanhToanHoaDon", conn)
                {
                    CommandType = CommandType.StoredProcedure
                };
                cmd.Parameters.AddWithValue("@MAHD", Selected.MAHD);
                cmd.Parameters.AddWithValue("@PHUONGTHUCTT", PhuongThucThanhToan);
                cmd.ExecuteNonQuery();

                MessageBox.Show("Thanh toán thành công!", "Thành công",
                                MessageBoxButton.OK, MessageBoxImage.Information);
                LoadData();
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi thanh toán: " + ex.Message, "Lỗi");
            }
        }
        // ──────────────────────────────────────────────
        //  IN / XUẤT HÓA ĐƠN RA EXCEL (S2-01)
        // ──────────────────────────────────────────────
        private void XuatHoaDonExcel()
        {
            if (!DBConnect.RequireStaffOrAdmin("In hóa đơn")) return;
            if (Selected == null) return;

            // Đảm bảo dịch vụ đã load
            if (DSDichVuDaDung.Count == 0)
            {
                MessageBox.Show("Hóa đơn này chưa có dịch vụ nào để in.", "Thông báo",
                    MessageBoxButton.OK, MessageBoxImage.Information);
                return;
            }

            var dlg = new SaveFileDialog
            {
                Filter = "Excel Workbook (*.xlsx)|*.xlsx",
                FileName = $"HoaDon_{Selected.MAHD}_{DateTime.Now:yyyyMMdd}.xlsx",
                Title = "Lưu hóa đơn"
            };
            if (dlg.ShowDialog() != true) return;

            try
            {
                using var wb = new XLWorkbook();
                var ws = wb.Worksheets.Add("Hóa Đơn");

                // === HEADER ===
                ws.Cell("A1").Value = "NHÀ XÁC - BỆNH VIỆN";
                ws.Cell("A1").Style.Font.Bold = true;
                ws.Cell("A1").Style.Font.FontSize = 16;
                ws.Range("A1:F1").Merge();
                ws.Cell("A1").Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                ws.Cell("A2").Value = "HÓA ĐƠN DỊCH VỤ";
                ws.Cell("A2").Style.Font.Bold = true;
                ws.Cell("A2").Style.Font.FontSize = 13;
                ws.Range("A2:F2").Merge();
                ws.Cell("A2").Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                // === THÔNG TIN HÓA ĐƠN ===
                ws.Cell("A4").Value = "Mã hóa đơn:";
                ws.Cell("B4").Value = Selected.MAHD;
                ws.Cell("A5").Value = "Thi hài:";
                ws.Cell("B5").Value = Selected.HOTEN_TH;
                ws.Cell("A6").Value = "Người nhận:";
                ws.Cell("B6").Value = Selected.NGUOI_NHAN;
                ws.Cell("A7").Value = "SĐT người nhận:";
                ws.Cell("B7").Value = Selected.SDT_NGUOI_NHAN;
                ws.Cell("D4").Value = "Ngày lập:";
                ws.Cell("E4").Value = Selected.NGAYLAP?.ToString("dd/MM/yyyy");
                ws.Cell("D5").Value = "Trạng thái:";
                ws.Cell("E5").Value = Selected.TRANGTHAITT;
                ws.Cell("D6").Value = "Người lập:";
                ws.Cell("E6").Value = Selected.NGUOILAP;
                ws.Cell("D7").Value = "Ghi chú:";
                ws.Cell("E7").Value = Selected.GHICHU;

                foreach (var cell in new[] { "A4", "A5", "A6", "A7", "D4", "D5", "D6", "D7" })
                    ws.Cell(cell).Style.Font.Bold = true;

                // === BẢNG DỊCH VỤ ===
                int row = 10;
                ws.Cell(row, 1).Value = "STT";
                ws.Cell(row, 2).Value = "Tên dịch vụ";
                ws.Cell(row, 3).Value = "Ngày sử dụng";
                ws.Cell(row, 4).Value = "Giá tiền (VNĐ)";
                ws.Cell(row, 5).Value = "Ghi chú";

                var headerRange = ws.Range(row, 1, row, 5);
                headerRange.Style.Fill.BackgroundColor = XLColor.FromHtml("#1E293B");
                headerRange.Style.Font.FontColor = XLColor.White;
                headerRange.Style.Font.Bold = true;
                headerRange.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                int stt = 1;
                decimal tongTien = 0;
                foreach (var dv in DSDichVuDaDung)
                {
                    row++;
                    ws.Cell(row, 1).Value = stt++;
                    ws.Cell(row, 2).Value = dv.TenDV;
                    ws.Cell(row, 3).Value = dv.NgaySD?.ToString("dd/MM/yyyy");
                    ws.Cell(row, 4).Value = (double)dv.GiaTien;
                    ws.Cell(row, 4).Style.NumberFormat.Format = "#,##0";
                    ws.Cell(row, 4).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Right;
                    ws.Cell(row, 5).Value = dv.GhiChu;
                    tongTien += dv.GiaTien;

                    if (stt % 2 == 0)
                        ws.Range(row, 1, row, 5).Style.Fill.BackgroundColor = XLColor.FromHtml("#F8FAFC");
                }

                // === TỔNG TIỀN ===
                row += 2;
                ws.Cell(row, 3).Value = "TỔNG TIỀN:";
                ws.Cell(row, 3).Style.Font.Bold = true;
                ws.Cell(row, 3).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Right;
                ws.Cell(row, 4).Value = (double)tongTien;
                ws.Cell(row, 4).Style.NumberFormat.Format = "#,##0";
                ws.Cell(row, 4).Style.Font.Bold = true;
                ws.Cell(row, 4).Style.Font.FontColor = XLColor.FromHtml("#DC2626");
                ws.Cell(row, 4).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Right;

                // === CHÂN TRANG ===
                row += 3;
                ws.Cell(row, 4).Value = "Ngày xuất: " + DateTime.Now.ToString("dd/MM/yyyy HH:mm");
                ws.Cell(row, 4).Style.Font.Italic = true;

                // === FORMAT ===
                ws.Columns().AdjustToContents();
                ws.Column(1).Width = 6;
                ws.Column(4).Width = 18;

                // Bo viền bảng dịch vụ
                var tableRange = ws.Range(10, 1, row - 4, 5);
                tableRange.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
                tableRange.Style.Border.InsideBorder = XLBorderStyleValues.Hair;

                wb.SaveAs(dlg.FileName);

                var ask = MessageBox.Show(
                    $"Đã lưu hóa đơn thành công!\n\nBạn có muốn mở file không?",
                    "Xuất hóa đơn thành công", MessageBoxButton.YesNo, MessageBoxImage.Question);

                if (ask == MessageBoxResult.Yes)
                    Process.Start(new ProcessStartInfo(dlg.FileName) { UseShellExecute = true });
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi khi xuất hóa đơn: " + ex.Message, "Lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }
    }
}