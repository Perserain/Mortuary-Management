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

        // Dành cho form thêm/sửa
        public ObservableCollection<BacSiModel> DanhSachBacSi { get; set; }

        // --- MỚI: DANH SÁCH DÙNG CHO TÍNH NĂNG TRA CỨU REAL-TIME ---
        public ObservableCollection<BacSiModel> DanhSachBacSiGoc { get; set; }
        public ObservableCollection<BacSiModel> DanhSachBacSiLoc { get; set; }
        public ObservableCollection<ThiHaiModel> DanhSachThiHaiGoc { get; set; }
        public ObservableCollection<ThiHaiModel> DanhSachThiHaiLoc { get; set; }

        // --- PROPERTIES TÌM KIẾM ---
        private string _tuKhoaBacSi;
        public string TuKhoaBacSi
        {
            get => _tuKhoaBacSi;
            set { _tuKhoaBacSi = value; OnPropertyChanged(); LocBacSi(); }
        }

        private string _tuKhoaThiHai;
        public string TuKhoaThiHai
        {
            get => _tuKhoaThiHai;
            set { _tuKhoaThiHai = value; OnPropertyChanged(); LocThiHai(); }
        }

        private BacSiModel _bacSiTraCuuDangChon;
        public BacSiModel BacSiTraCuuDangChon
        {
            get => _bacSiTraCuuDangChon;
            set
            {
                _bacSiTraCuuDangChon = value;
                OnPropertyChanged();
                if (_bacSiTraCuuDangChon != null) TraCuuTheoBacSi(_bacSiTraCuuDangChon.MaBS);
                else DanhSachKhamNghiemTheoBacSi.Clear();
            }
        }

        private ThiHaiModel _thiHaiTraCuuDangChon;
        public ThiHaiModel ThiHaiTraCuuDangChon
        {
            get => _thiHaiTraCuuDangChon;
            set
            {
                _thiHaiTraCuuDangChon = value;
                OnPropertyChanged();
                if (_thiHaiTraCuuDangChon != null) TraCuuTheoTuThi(_thiHaiTraCuuDangChon.MaTH);
                else DanhSachKhamNghiemTheoTuThi.Clear();
            }
        }

        // --- PROPERTIES FORM THÊM/SỬA ---
        private BacSiModel _selectedBacSi;
        public BacSiModel SelectedBacSi
        {
            get => _selectedBacSi;
            set
            {
                _selectedBacSi = value;
                OnPropertyChanged();
                if (NewHoSo != null) NewHoSo.MaBS = value?.MaBS ?? string.Empty;
            }
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
                    _selectedBacSi = DanhSachBacSi.FirstOrDefault(b => b.MaBS == _selectedHoSo.MaBS);
                    OnPropertyChanged(nameof(SelectedBacSi));
                }
                else ResetForm();
            }
        }

        public ICommand LoadCommand { get; set; }
        public bool IsAdmin => DBConnect.IsAdmin;
        public ICommand ThemCommand { get; set; }
        public ICommand SuaCommand { get; set; }
        public ICommand XoaCommand { get; set; }
        public ICommand XuatExcelCommand { get; set; }
        public ICommand NhapTuFileCommand { get; set; }
        public ICommand XemChiTietCommand { get; set; }
        public ICommand LamMoiTraCuuCommand { get; set; }

        public HoSoKBViewModel()
        {
            DanhSachHoSo = new ObservableCollection<HoSoKBModel>();
            DanhSachKhamNghiemTheoBacSi = new ObservableCollection<KhamNghiemTheoBacSiModel>();
            DanhSachKhamNghiemTheoTuThi = new ObservableCollection<KhamNghiemTheoTuThiModel>();
            DanhSachBacSi = new ObservableCollection<BacSiModel>();

            DanhSachBacSiGoc = new ObservableCollection<BacSiModel>();
            DanhSachBacSiLoc = new ObservableCollection<BacSiModel>();
            DanhSachThiHaiGoc = new ObservableCollection<ThiHaiModel>();
            DanhSachThiHaiLoc = new ObservableCollection<ThiHaiModel>();

            LoadCommand = new RelayCommand(p => LoadData());
            ThemCommand = new RelayCommand(p => ThemHoSo());
            SuaCommand = new RelayCommand(p => SuaHoSo());
            XoaCommand = new RelayCommand(p => XoaHoSo());
            XuatExcelCommand = new RelayCommand(p => XuatExcel());
            NhapTuFileCommand = new RelayCommand(p => NhapTuFile());
            XemChiTietCommand = new RelayCommand(p => XemChiTiet(), p => SelectedHoSo != null); // Đã sửa lỗi xem chi tiết
            LamMoiTraCuuCommand = new RelayCommand(p => LamMoiTraCuu());

            LoadData();
            LoadDanhSachBacSi();
            LoadDanhSachThiHai(); // MỚI
            ResetForm();
        }

        private void LoadData()
        {
            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;
            DanhSachHoSo.Clear();
            DataTable dt = DBConnect.GetData("EXEC SP_DSHoSoKhamNghiem");
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
            DanhSachBacSi.Clear(); DanhSachBacSiGoc.Clear(); DanhSachBacSiLoc.Clear();
            try
            {
                DataTable dt = DBConnect.GetData("SELECT MABS, HOTEN_BS FROM BACSI ORDER BY HOTEN_BS");
                foreach (DataRow row in dt.Rows)
                {
                    var bs = new BacSiModel { MaBS = row["MABS"].ToString(), HoTenBS = row["HOTEN_BS"].ToString() };
                    DanhSachBacSi.Add(bs);
                    DanhSachBacSiGoc.Add(bs);
                    DanhSachBacSiLoc.Add(bs);
                }
            }
            catch (Exception ex) { System.Diagnostics.Debug.WriteLine(ex.Message); }
        }

        private void LoadDanhSachThiHai()
        {
            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;
            DanhSachThiHaiGoc.Clear(); DanhSachThiHaiLoc.Clear();
            try
            {
                DataTable dt = DBConnect.GetData("SELECT MATH, HOTEN_TH FROM THIHAI ORDER BY HOTEN_TH");
                foreach (DataRow row in dt.Rows)
                {
                    var th = new ThiHaiModel { MaTH = row["MATH"].ToString(), HoTenTH = row["HOTEN_TH"].ToString() };
                    DanhSachThiHaiGoc.Add(th);
                    DanhSachThiHaiLoc.Add(th);
                }
            }
            catch (Exception ex) { System.Diagnostics.Debug.WriteLine(ex.Message); }
        }

        // --- LOGIC LỌC TÌM KIẾM ---
        private void LocBacSi()
        {
            DanhSachBacSiLoc.Clear();
            var kw = (TuKhoaBacSi ?? "").Trim().ToLower();
            var result = string.IsNullOrEmpty(kw) ? DanhSachBacSiGoc : DanhSachBacSiGoc.Where(b => (b.HoTenBS ?? "").ToLower().Contains(kw) || b.MaBS.ToLower().Contains(kw));
            foreach (var b in result) DanhSachBacSiLoc.Add(b);
        }

        private void LocThiHai()
        {
            DanhSachThiHaiLoc.Clear();
            var kw = (TuKhoaThiHai ?? "").Trim().ToLower();
            var result = string.IsNullOrEmpty(kw) ? DanhSachThiHaiGoc : DanhSachThiHaiGoc.Where(t => (t.HoTenTH ?? "").ToLower().Contains(kw) || t.MaTH.ToLower().Contains(kw));
            foreach (var t in result) DanhSachThiHaiLoc.Add(t);
        }

        // --- TRA CỨU ĐỘNG ---
        private void TraCuuTheoBacSi(string maBS)
        {
            DanhSachKhamNghiemTheoBacSi.Clear();
            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    using (var cmd = new SqlCommand("SELECT * FROM dbo.fn_DanhSachKhamNghiemTheoBacSi(@mabs)", conn))
                    {
                        cmd.Parameters.AddWithValue("@mabs", maBS);
                        using (var da = new SqlDataAdapter(cmd))
                        {
                            var dt = new DataTable(); da.Fill(dt);
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
                        }
                    }
                }
            }
            catch (Exception ex) { MessageBox.Show("Lỗi tra cứu: " + ex.Message); }
        }

        private void TraCuuTheoTuThi(string maTH)
        {
            DanhSachKhamNghiemTheoTuThi.Clear();
            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    using (var cmd = new SqlCommand("SELECT * FROM dbo.fn_DanhSachKhamNghiemTheoTuThi(@math)", conn))
                    {
                        cmd.Parameters.AddWithValue("@math", maTH);
                        using (var da = new SqlDataAdapter(cmd))
                        {
                            var dt = new DataTable(); da.Fill(dt);
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
                        }
                    }
                }
            }
            catch (Exception ex) { MessageBox.Show("Lỗi tra cứu: " + ex.Message); }
        }

        private void LamMoiTraCuu()
        {
            TuKhoaBacSi = string.Empty;
            TuKhoaThiHai = string.Empty;
            BacSiTraCuuDangChon = null;
            ThiHaiTraCuuDangChon = null;
        }

        // --- CÁC HÀM CŨ ---
        private void XemChiTiet()
        {
            DetailWindow f = new DetailWindow(SelectedHoSo, "CHI TIẾT HỒ SƠ KHÁM");
            f.ShowDialog();
        }

        private string TaoMaHS()
        {
            if (DanhSachHoSo == null || DanhSachHoSo.Count == 0) return "HS001";
            var maxId = DanhSachHoSo.Select(h => {
                if (h.MaHS != null && h.MaHS.StartsWith("HS") && int.TryParse(h.MaHS.Substring(2), out int num)) return num;
                return 0;
            }).DefaultIfEmpty(0).Max();
            return $"HS{(maxId + 1):D3}";
        }

        private void ResetForm()
        {
            NewHoSo = new HoSoKBModel { TgKham = DateTime.Now };
            NewHoSo.MaHS = TaoMaHS();
            _selectedBacSi = null;
            OnPropertyChanged(nameof(SelectedBacSi));
        }

        /// <summary>Kiểm tra dữ liệu form Hồ Sơ trước khi INSERT/UPDATE.</summary>
        private string? KiemTraHoSo(HoSoKBModel hs)
        {
            if (!Validator.IsNotEmpty(hs.MaHS))
                return "Vui lòng nhập Mã Hồ Sơ.";
            if (!Validator.IsNotEmpty(hs.MaTH))
                return "Vui lòng nhập hoặc chọn Mã Thi Hài cần khám nghiệm.";
            if (!Validator.IsNotEmpty(hs.MaBS))
                return "Vui lòng chọn Bác Sĩ thực hiện khám.";

            // Lưu ý: Việc kiểm tra "Ngày khám >= Ngày mất" sẽ do Trigger TRG_KiemTraNgayKham dưới SQL đảm nhiệm.
            return null; // Hợp lệ
        }

        private void ThemHoSo()
        {
            if (!DBConnect.RequireStaffOrAdmin("Thêm hồ sơ khám")) return;

            // === KIỂM TRA VALIDATION ===
            string? loi = KiemTraHoSo(NewHoSo);
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
                    var cmd = new SqlCommand("SP_ThemHoSoKhamBenh_V2", conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@MAHS", NewHoSo.MaHS);
                    cmd.Parameters.AddWithValue("@THOIGIANKHAM", NewHoSo.TgKham ?? (object)DBNull.Value);
                    cmd.Parameters.AddWithValue("@KETLUAN", string.IsNullOrWhiteSpace(NewHoSo.KetLuan) ? DBNull.Value : (object)NewHoSo.KetLuan);
                    cmd.Parameters.AddWithValue("@MATH", NewHoSo.MaTH);
                    cmd.Parameters.AddWithValue("@MABS", NewHoSo.MaBS);

                    cmd.ExecuteNonQuery();
                    MessageBox.Show("Lập hồ sơ thành công!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Information);
                    LoadData();
                    ResetForm();
                }
            }
            catch (SqlException ex)
            {
                // Bắt lỗi Trùng mã, Lỗi Khóa ngoại, và các lỗi từ Trigger
                if (ex.Number == 2627 || ex.Number == 2601)
                    MessageBox.Show("Mã Hồ Sơ đã tồn tại trong hệ thống!", "Trùng mã", MessageBoxButton.OK, MessageBoxImage.Warning);
                else if (ex.Number == 547)
                    MessageBox.Show("Mã Thi Hài hoặc Mã Bác Sĩ không tồn tại!", "Lỗi tham chiếu", MessageBoxButton.OK, MessageBoxImage.Warning);
                else if (ex.Message.Contains("Ngày khám không được trước"))
                    MessageBox.Show("Ngày khám không được trước ngày mất của thi hài!", "Sai logic thời gian", MessageBoxButton.OK, MessageBoxImage.Warning);
                else if (ex.Message.Contains("quá 3 ca"))
                    MessageBox.Show("Bác sĩ này đã đạt giới hạn 3 ca khám trong ngày!", "Vượt giới hạn", MessageBoxButton.OK, MessageBoxImage.Warning);
                else
                    MessageBox.Show("Lỗi CSDL: " + ex.Message, "Lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi không xác định: " + ex.Message, "Lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void SuaHoSo()
        {
            if (!DBConnect.RequireStaffOrAdmin("Sửa hồ sơ khám")) return;

            // === KIỂM TRA VALIDATION ===
            string? loi = KiemTraHoSo(NewHoSo);
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
                    var cmdUpdate = new SqlCommand("SP_SuaHoSoKhamBenh_V2", conn);
                    cmdUpdate.CommandType = CommandType.StoredProcedure;
                    cmdUpdate.Parameters.AddWithValue("@MAHS", NewHoSo.MaHS);
                    cmdUpdate.Parameters.AddWithValue("@THOIGIANKHAM", NewHoSo.TgKham ?? (object)DBNull.Value);
                    cmdUpdate.Parameters.AddWithValue("@KETLUAN", string.IsNullOrWhiteSpace(NewHoSo.KetLuan) ? DBNull.Value : (object)NewHoSo.KetLuan);
                    cmdUpdate.Parameters.AddWithValue("@MATH", string.IsNullOrWhiteSpace(NewHoSo.MaTH) ? DBNull.Value : (object)NewHoSo.MaTH);
                    cmdUpdate.Parameters.AddWithValue("@MABS", string.IsNullOrWhiteSpace(NewHoSo.MaBS) ? DBNull.Value : (object)NewHoSo.MaBS);

                    if (cmdUpdate.ExecuteNonQuery() > 0)
                    {
                        MessageBox.Show("Cập nhật hồ sơ thành công!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Information);
                        LoadData();
                        ResetForm();
                    }
                }
            }
            catch (SqlException ex)
            {
                if (ex.Number == 547)
                    MessageBox.Show("Mã Thi Hài hoặc Mã Bác Sĩ không tồn tại!", "Lỗi tham chiếu", MessageBoxButton.OK, MessageBoxImage.Warning);
                else if (ex.Message.Contains("Ngày khám không được trước"))
                    MessageBox.Show("Ngày khám không được trước ngày mất của thi hài!", "Sai logic thời gian", MessageBoxButton.OK, MessageBoxImage.Warning);
                else if (ex.Message.Contains("quá 3 ca"))
                    MessageBox.Show("Bác sĩ này đã đạt giới hạn 3 ca khám trong ngày!", "Vượt giới hạn", MessageBoxButton.OK, MessageBoxImage.Warning);
                else
                    MessageBox.Show("Lỗi CSDL: " + ex.Message, "Lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi không xác định: " + ex.Message, "Lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void XoaHoSo()
        {
            if (!DBConnect.RequireStaffOrAdmin("Xóa hồ sơ khám")) return;
            if (MessageBox.Show("Bạn có chắc muốn xóa hồ sơ này?", "Xác nhận xóa", MessageBoxButton.YesNo, MessageBoxImage.Warning) == MessageBoxResult.Yes)
            {
                try
                {
                    using (var conn = new SqlConnection(DBConnect.ConnectionString))
                    {
                        conn.Open();
                        var cmd = new SqlCommand("EXEC SP_XoaHoSoKhamBenh @ma", conn);
                        cmd.Parameters.AddWithValue("@ma", NewHoSo.MaHS);
                        cmd.ExecuteNonQuery();

                        MessageBox.Show("Đã xóa hồ sơ thành công!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Information);
                        LoadData();
                        ResetForm();
                    }
                }
                catch (SqlException ex)
                {
                    // Bắt lỗi trigger cấm xóa hồ sơ pháp y
                    if (ex.Message.Contains("Hồ sơ pháp y không được phép xóa"))
                        MessageBox.Show("Hồ sơ pháp y đã lưu không thể bị xóa! Đây là dữ liệu được bảo vệ.", "Bảo vệ dữ liệu", MessageBoxButton.OK, MessageBoxImage.Warning);
                    else
                        MessageBox.Show("Lỗi CSDL: " + ex.Message, "Lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Lỗi không xác định: " + ex.Message, "Lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
                }
            }
        }

        private void XuatExcel()
        {
            if (DanhSachHoSo == null || DanhSachHoSo.Count == 0) { MessageBox.Show("Không có dữ liệu!", "Thông báo"); return; }
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
                        worksheet.Cell(1, 1).Value = "Mã HS"; worksheet.Cell(1, 2).Value = "Ngày Khám";
                        worksheet.Cell(1, 3).Value = "Kết Luận"; worksheet.Cell(1, 4).Value = "Mã Xác";
                        worksheet.Cell(1, 5).Value = "Bác Sĩ";
                        var headerRange = worksheet.Range("A1:E1");
                        headerRange.Style.Font.Bold = true; headerRange.Style.Fill.BackgroundColor = XLColor.LightYellow;
                        headerRange.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                        int row = 2;
                        foreach (var hs in DanhSachHoSo)
                        {
                            worksheet.Cell(row, 1).Value = hs.MaHS;
                            if (hs.TgKham.HasValue) worksheet.Cell(row, 2).Value = hs.TgKham.Value.ToString("dd/MM/yyyy");
                            worksheet.Cell(row, 3).Value = hs.KetLuan; worksheet.Cell(row, 4).Value = hs.MaTH; worksheet.Cell(row, 5).Value = hs.MaBS;
                            row++;
                        }
                        worksheet.Columns().AdjustToContents();
                        workbook.SaveAs(saveFileDialog.FileName);
                        MessageBox.Show("Xuất file Excel thành công!\nĐường dẫn: " + saveFileDialog.FileName);
                    }
                }
                catch (Exception ex) { MessageBox.Show("Lỗi xuất file: " + ex.Message); }
            }
        }

        private void NhapTuFile()
        {
            if (!DBConnect.RequireAdmin("Nhập Excel hồ sơ khám")) return;
            Microsoft.Win32.OpenFileDialog dlg = new Microsoft.Win32.OpenFileDialog();
            dlg.Filter = "Excel Files (*.xlsx)|*.xlsx"; dlg.Title = "Chọn file Excel Hồ Sơ Khám";
            if (dlg.ShowDialog() == true)
            {
                try
                {
                    DataTable dt = new DataTable();
                    dt.Columns.Add("MAHS", typeof(string)); dt.Columns.Add("THOIGIANKHAM", typeof(DateTime));
                    dt.Columns.Add("KETLUAN", typeof(string)); dt.Columns.Add("MATH", typeof(string)); dt.Columns.Add("MABS", typeof(string));
                    using (var workbook = new XLWorkbook(dlg.FileName))
                    {
                        var worksheet = workbook.Worksheet(1); var rows = worksheet.RangeUsed().RowsUsed();
                        bool isFirstRow = true;
                        foreach (var row in rows)
                        {
                            if (isFirstRow) { isFirstRow = false; continue; }
                            string maHS = row.Cell(1).GetString().Trim();
                            string ngayKhamStr = row.Cell(2).GetString().Trim();
                            object ngayKham = DateTime.TryParse(ngayKhamStr, out DateTime nk) ? (object)nk : DBNull.Value;
                            string ketLuan = row.Cell(3).GetString().Trim();
                            string maTH = row.Cell(4).GetString().Trim();
                            string maBS = row.Cell(5).GetString().Trim();
                            if (!string.IsNullOrEmpty(maHS) && !string.IsNullOrEmpty(maTH) && !string.IsNullOrEmpty(maBS))
                                dt.Rows.Add(maHS, ngayKham, ketLuan, maTH, maBS);
                        }
                    }
                    if (dt.Rows.Count == 0) { MessageBox.Show("File rỗng hoặc trống cột bắt buộc!", "Cảnh báo"); return; }
                    using (SqlConnection conn = new SqlConnection(DBConnect.ConnectionString))
                    {
                        conn.Open();
                        using (SqlBulkCopy bulkCopy = new SqlBulkCopy(conn))
                        {
                            bulkCopy.DestinationTableName = "HOSOKHAMBENH";
                            bulkCopy.ColumnMappings.Add("MAHS", "MAHS"); bulkCopy.ColumnMappings.Add("THOIGIANKHAM", "THOIGIANKHAM");
                            bulkCopy.ColumnMappings.Add("KETLUAN", "KETLUAN"); bulkCopy.ColumnMappings.Add("MATH", "MATH"); bulkCopy.ColumnMappings.Add("MABS", "MABS");
                            bulkCopy.WriteToServer(dt);
                            MessageBox.Show($"Đã nhập thành công {dt.Rows.Count} hồ sơ!", "Thành công"); LoadData();
                        }
                    }
                }
                catch (SqlException ex)
                {
                    if (ex.Number == 2627) MessageBox.Show("Lỗi: Mã Hồ Sơ đã tồn tại!");
                    else if (ex.Number == 547) MessageBox.Show("Lỗi: Mã Xác hoặc Mã Bác Sĩ chưa tồn tại!");
                    else MessageBox.Show("Lỗi CSDL: " + ex.Message);
                }
                catch (Exception ex) { MessageBox.Show("Lỗi đọc file: " + ex.Message); }
            }
        }
    }
}