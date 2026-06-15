using DoAn.Core;
using DoAn.Model;
using Microsoft.Data.SqlClient;
using System;
using System.Collections.ObjectModel;
using System.Data;
using System.Windows;
using System.Windows.Input;
using System.Windows.Threading;

namespace DoAn.ViewModel
{
    public class CanhBaoViewModel : BaseViewModel
    {
        // ===================== COLLECTIONS =====================
        public ObservableCollection<CanhBaoModel> DanhSachCanhBao { get; set; }

        // ===================== TIMER =====================
        private DispatcherTimer _timer;

        // ===================== SELECTED =====================
        private CanhBaoModel _selectedCanhBao;
        public CanhBaoModel SelectedCanhBao
        {
            get => _selectedCanhBao;
            set { _selectedCanhBao = value; OnPropertyChanged(); }
        }

        // ===================== THỐNG KÊ (HEADER) =====================
        private int _tongChuaDoc;
        public int TongChuaDoc
        {
            get => _tongChuaDoc;
            set { _tongChuaDoc = value; OnPropertyChanged(); OnPropertyChanged(nameof(TieuDeHeader)); }
        }

        private int _soKhanCap;
        public int SoKhanCap
        {
            get => _soKhanCap;
            set { _soKhanCap = value; OnPropertyChanged(); }
        }

        private int _soCannXuLy;
        public int SoCanXuLy
        {
            get => _soCannXuLy;
            set { _soCannXuLy = value; OnPropertyChanged(); }
        }

        public string TieuDeHeader
        {
            get => TongChuaDoc > 0 ? $"Tổng chưa đọc: {TongChuaDoc}" : "Không có cảnh báo mới";
            set { } // Thêm set rỗng để WPF không văng lỗi khi Binding
        }

        // ===================== TAB FILTER =====================
        private bool _chiHienChuaDoc = true;
        public bool ChiHienChuaDoc
        {
            get => _chiHienChuaDoc;
            set { _chiHienChuaDoc = value; OnPropertyChanged(); LoadData(); }
        }

        // ===================== COMMANDS =====================
        public ICommand QuetMoiCommand     { get; set; }
        public ICommand DocTatCaCommand    { get; set; }
        public ICommand DocMotCommand      { get; set; }
        public ICommand LamMoiCommand      { get; set; }
        public ICommand XemThiHaiCommand   { get; set; }

        // ===================== CONSTRUCTOR =====================
        public CanhBaoViewModel()
        {
            DanhSachCanhBao = new ObservableCollection<CanhBaoModel>();

            QuetMoiCommand   = new RelayCommand(p => ExecuteQuetMoi());
            DocTatCaCommand  = new RelayCommand(p => ExecuteDocTatCa());
            DocMotCommand    = new RelayCommand(p => ExecuteDocMot(), p => SelectedCanhBao != null);
            LamMoiCommand    = new RelayCommand(p => LoadData());
            XemThiHaiCommand = new RelayCommand(p => ExecuteXemThiHai(), p => SelectedCanhBao != null && !string.IsNullOrEmpty(SelectedCanhBao.MATH));

            // Quét mới rồi load lần đầu
            ExecuteQuetMoi();

            // Timer tự động quét mỗi 3 phút
            _timer = new DispatcherTimer { Interval = TimeSpan.FromMinutes(3) };
            _timer.Tick += (s, e) => ExecuteQuetMoi();
            _timer.Start();
        }

        // ===================== LOAD DATA =====================
        private void LoadData()
        {
            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;
            DanhSachCanhBao.Clear();

            // SP_DSCanhBao lấy từ VIEW_CanhBaoChuaDoc (chỉ chưa đọc)
            // Nếu người dùng muốn xem tất cả, query thêm cột DAOC
            string query = ChiHienChuaDoc
                ? "EXEC SP_DSCanhBao"
                : "SELECT cb.MACB, cb.THOIGIAN, cb.LOAICB, cb.MATH, cb.MANGAN, cb.NOIDUNG, cb.DAOC, th.HOTEN_TH, " +
                  "CASE cb.LOAICB WHEN N'QuaHan' THEN 1 WHEN N'NhietDo' THEN 1 WHEN N'ChuaKham' THEN 2 ELSE 3 END AS MUC_DO_UU_TIEN, " +
                  "CASE cb.LOAICB WHEN N'QuaHan' THEN N'Khẩn cấp' WHEN N'NhietDo' THEN N'Nguy hiểm' WHEN N'ChuaKham' THEN N'Cần xử lý' ELSE N'Thông báo' END AS MUC_DO_HIEN_THI " +
                  "FROM CANH_BAO cb LEFT JOIN THIHAI th ON cb.MATH = th.MATH ORDER BY MUC_DO_UU_TIEN, cb.THOIGIAN DESC";

            DataTable dt = DBConnect.GetData(query);

            int khan = 0, canXuLy = 0;
            foreach (DataRow row in dt.Rows)
            {
                int uuTien = row["MUC_DO_UU_TIEN"] != DBNull.Value ? Convert.ToInt32(row["MUC_DO_UU_TIEN"]) : 3;
                bool daoc = dt.Columns.Contains("DAOC") && row["DAOC"] != DBNull.Value ? Convert.ToBoolean(row["DAOC"]) : false;
                var cb = new CanhBaoModel
                {
                    MACB          = Convert.ToInt32(row["MACB"]),
                    THOIGIAN      = row["THOIGIAN"] != DBNull.Value
                                    ? Convert.ToDateTime(row["THOIGIAN"]).ToString("dd/MM/yyyy HH:mm")
                                    : "",
                    LOAICB        = row["LOAICB"].ToString(),
                    MATH          = row["MATH"]?.ToString() ?? "",
                    MANGAN        = row["MANGAN"]?.ToString() ?? "",
                    NOIDUNG       = row["NOIDUNG"].ToString(),
                    DAOC          = daoc,
                    HOTEN_TH      = row["HOTEN_TH"]?.ToString() ?? "",
                    MUC_DO_UU_TIEN   = uuTien,
                    MUC_DO_HIEN_THI  = row["MUC_DO_HIEN_THI"].ToString()
                };

                DanhSachCanhBao.Add(cb);

                if (!daoc)
                {
                    if (uuTien == 1) khan++;
                    else if (uuTien == 2) canXuLy++;
                }
            }

            TongChuaDoc = khan + canXuLy;
            SoKhanCap   = khan;
            SoCanXuLy   = canXuLy;
        }

        // ===================== QUÉT MỚI =====================
        private void ExecuteQuetMoi()
        {
            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;
            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    using (var cmd = new SqlCommand("SP_QuetCanhBao", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        object result = cmd.ExecuteScalar();
                        int soMoi = result != null && result != DBNull.Value ? Convert.ToInt32(result) : 0;

                        LoadData();

                        if (soMoi > 0)
                            MessageBox.Show($"Đã phát hiện {soMoi} cảnh báo mới!", "Cảnh báo mới", MessageBoxButton.OK, MessageBoxImage.Warning);
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi khi quét cảnh báo: " + ex.Message);
            }
        }

        // ===================== ĐỌC MỘT CẢNH BÁO =====================
        private void ExecuteDocMot()
        {
            if (SelectedCanhBao == null) return;
            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;

            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    var cmd = new SqlCommand("EXEC SP_DocCanhBao @MACB", conn);
                    cmd.Parameters.AddWithValue("@MACB", SelectedCanhBao.MACB);
                    cmd.ExecuteNonQuery();
                }
                LoadData();
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi: " + ex.Message);
            }
        }

        // ===================== ĐỌC TẤT CẢ =====================
        private void ExecuteDocTatCa()
        {
            if (TongChuaDoc == 0)
            {
                MessageBox.Show("Không có cảnh báo nào chưa đọc.", "Thông báo");
                return;
            }

            var confirm = MessageBox.Show(
                $"Đánh dấu đã đọc tất cả {TongChuaDoc} cảnh báo?",
                "Xác nhận", MessageBoxButton.YesNo, MessageBoxImage.Question);

            if (confirm != MessageBoxResult.Yes) return;

            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;

            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    var cmd = new SqlCommand("EXEC SP_DocHetCanhBao", conn);
                    cmd.ExecuteNonQuery();
                }
                LoadData();
                MessageBox.Show("Đã đánh dấu đọc tất cả cảnh báo!", "Hoàn tất");
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi: " + ex.Message);
            }
        }

        // ===================== XEM THI HÀI LIÊN QUAN =====================
        private void ExecuteXemThiHai()
        {
            if (SelectedCanhBao == null || string.IsNullOrEmpty(SelectedCanhBao.MATH)) return;

            // Navigate sang ThiHaiViewModel và truyền MATH để filter
            // (Thực hiện qua MainViewModel nếu cần; hiện tại thông báo tạm)
            MessageBox.Show(
                $"Mã thi hài: {SelectedCanhBao.MATH}\nHọ tên: {SelectedCanhBao.TenThiHaiHienThi}\n\nVui lòng chuyển sang tab Quản Lý Thi Hài để xem chi tiết.",
                "Thi Hài Liên Quan", MessageBoxButton.OK, MessageBoxImage.Information);
        }

        // Dừng timer khi ViewModel bị hủy
        public void Cleanup()
        {
            _timer?.Stop();
        }
    }
}
