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
    public class DashboardViewModel : BaseViewModel
    {
        // ── KPI ──────────────────────────────────────────────────────────────
        private DashboardModel _kpi = new DashboardModel();
        public DashboardModel Kpi
        {
            get => _kpi;
            set { _kpi = value; OnPropertyChanged(); }
        }

        // ── Biểu đồ cột: Thi hài theo tháng ─────────────────────────────────
        private ObservableCollection<ThiHaiTheoThangModel> _thiHaiTheoThang
            = new ObservableCollection<ThiHaiTheoThangModel>();
        public ObservableCollection<ThiHaiTheoThangModel> ThiHaiTheoThang
        {
            get => _thiHaiTheoThang;
            set { _thiHaiTheoThang = value; OnPropertyChanged(); }
        }

        // ── Biểu đồ cột: Doanh thu theo tháng ───────────────────────────────
        private ObservableCollection<DoanhThuTheoThangModel> _doanhThuTheoThang
            = new ObservableCollection<DoanhThuTheoThangModel>();
        public ObservableCollection<DoanhThuTheoThangModel> DoanhThuTheoThang
        {
            get => _doanhThuTheoThang;
            set { _doanhThuTheoThang = value; OnPropertyChanged(); }
        }

        // ── Biểu đồ tròn: Nguyên nhân tử vong ───────────────────────────────
        private ObservableCollection<LoaiCauTuModel> _loaiCauTu
            = new ObservableCollection<LoaiCauTuModel>();
        public ObservableCollection<LoaiCauTuModel> LoaiCauTu
        {
            get => _loaiCauTu;
            set { _loaiCauTu = value; OnPropertyChanged(); }
        }

        // ── Bảng Top 5 cảnh báo ──────────────────────────────────────────────
        private ObservableCollection<CanhBaoModel> _topCanhBao
            = new ObservableCollection<CanhBaoModel>();
        public ObservableCollection<CanhBaoModel> TopCanhBao
        {
            get => _topCanhBao;
            set { _topCanhBao = value; OnPropertyChanged(); }
        }

        // ── Trạng thái refresh ───────────────────────────────────────────────
        private string _lastRefresh = "—";
        public string LastRefresh
        {
            get => _lastRefresh;
            set { _lastRefresh = value; OnPropertyChanged(); }
        }

        private bool _isLoading = false;
        public bool IsLoading
        {
            get => _isLoading;
            set { _isLoading = value; OnPropertyChanged(); }
        }

        // ── Sự kiện vẽ biểu đồ (View đăng ký lắng nghe) ────────────────────
        public event Action ChartDataUpdated;

        // ── Màu cho pie chart ────────────────────────────────────────────────
        private static readonly string[] _colors = {
            "#10B981","#3B82F6","#F59E0B","#EF4444","#8B5CF6",
            "#06B6D4","#F97316","#84CC16","#EC4899","#64748B"
        };

        // ── Commands ─────────────────────────────────────────────────────────
        public ICommand RefreshCommand { get; set; }

        // ── Timer auto-refresh ───────────────────────────────────────────────
        private DispatcherTimer _timer;

        // ─────────────────────────────────────────────────────────────────────
        public DashboardViewModel()
        {
            RefreshCommand = new RelayCommand(p => LoadAll());

            _timer = new DispatcherTimer
            {
                Interval = TimeSpan.FromMinutes(5)
            };
            _timer.Tick += (s, e) => LoadAll();
            _timer.Start();

            LoadAll();
        }

        // ── Hủy timer khi VM bị dispose ──────────────────────────────────────
        public void Cleanup() => _timer?.Stop();

        // ═════════════════════════════════════════════════════════════════════
        //  LOAD ALL
        // ═════════════════════════════════════════════════════════════════════
        public void LoadAll()
        {
            if (IsLoading) return;
            IsLoading = true;
            try
            {
                QuetCanhBao();      // 1. Quét cảnh báo mới trước
                LoadKpi();          // 2. KPI cards
                LoadThiHaiThang();  // 3. Biểu đồ thi hài
                LoadDoanhThuThang();// 4. Biểu đồ doanh thu
                LoadLoaiCauTu();    // 5. Pie chart
                LoadTopCanhBao();   // 6. Bảng top 5 cảnh báo

                LastRefresh = DateTime.Now.ToString("HH:mm:ss dd/MM/yyyy");
                ChartDataUpdated?.Invoke();  // Báo View vẽ lại chart
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi tải Dashboard: " + ex.Message, "Lỗi", MessageBoxButton.OK, MessageBoxImage.Warning);
            }
            finally
            {
                IsLoading = false;
            }
        }

        // ── Quét cảnh báo mới ────────────────────────────────────────────────
        private void QuetCanhBao()
        {
            try
            {
                using var conn = new SqlConnection(DBConnect.ConnectionString);
                conn.Open();
                using var cmd = new SqlCommand("SP_QuetCanhBao", conn)
                {
                    CommandType = CommandType.StoredProcedure
                };
                cmd.ExecuteNonQuery();
            }
            catch { /* Không block dashboard nếu SP lỗi */ }
        }

        // ── KPI từ SP_Dashboard ───────────────────────────────────────────────
        private void LoadKpi()
        {
            try
            {
                using var conn = new SqlConnection(DBConnect.ConnectionString);
                conn.Open();
                using var cmd = new SqlCommand("SP_Dashboard", conn)
                {
                    CommandType = CommandType.StoredProcedure
                };
                using var reader = cmd.ExecuteReader();
                if (reader.Read())
                {
                    Kpi.TongThiHai = GetInt(reader, "TongThiHai");
                    Kpi.DangBaoQuan = GetInt(reader, "DangBaoQuan");
                    Kpi.ChoThanhLy = GetInt(reader, "ChoThanhLy");
                    Kpi.NganKeoTrong = GetInt(reader, "NganKeoTrong");
                    Kpi.NganKeoDang = GetInt(reader, "NganKeoDang");
                    Kpi.TongNganKeo = GetInt(reader, "TongNganKeo");
                    Kpi.DoanhThuHomNay = GetDecimal(reader, "DoanhThuHomNay");
                    Kpi.DoanhThuThang = GetDecimal(reader, "DoanhThuThang");
                    Kpi.SoCanhBaoChuaDoc = GetInt(reader, "SoCanhBaoChuaDoc");
                    Kpi.HoaDonChuaTT = GetInt(reader, "HoaDonChuaTT");
                }
            }
            catch (Exception ex)
            {
                // Nếu SP chưa sẵn sàng, để KPI = 0 thay vì crash
                System.Diagnostics.Debug.WriteLine("LoadKpi error: " + ex.Message);
            }
        }

        // ── Biểu đồ thi hài theo tháng ───────────────────────────────────────
        private void LoadThiHaiThang()
        {
            ThiHaiTheoThang.Clear();
            try
            {
                using var conn = new SqlConnection(DBConnect.ConnectionString);
                conn.Open();
                using var cmd = new SqlCommand("SP_BaoCao_ThiHaiTheoThang", conn)
                {
                    CommandType = CommandType.StoredProcedure
                };
                cmd.Parameters.AddWithValue("@Nam", DateTime.Now.Year);
                using var reader = cmd.ExecuteReader();

                var list = new System.Collections.Generic.List<ThiHaiTheoThangModel>();
                while (reader.Read())
                {
                    list.Add(new ThiHaiTheoThangModel
                    {
                        Thang = "T" + reader["Thang"].ToString(),
                        SoLuong = GetInt(reader, "SoLuong")
                    });
                }

                // Chuẩn hoá chiều cao 0–1
                int max = 1;
                foreach (var item in list) if (item.SoLuong > max) max = item.SoLuong;
                foreach (var item in list)
                {
                    item.ChieuCaoChuanHoa = (double)item.SoLuong / max;
                    ThiHaiTheoThang.Add(item);
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("LoadThiHaiThang error: " + ex.Message);
            }
        }

        // ── Biểu đồ doanh thu theo tháng ─────────────────────────────────────
        private void LoadDoanhThuThang()
        {
            DoanhThuTheoThang.Clear();
            try
            {
                using var conn = new SqlConnection(DBConnect.ConnectionString);
                conn.Open();
                using var cmd = new SqlCommand("SP_BaoCao_DoanhThuTheoThang", conn)
                {
                    CommandType = CommandType.StoredProcedure
                };
                cmd.Parameters.AddWithValue("@Nam", DateTime.Now.Year);
                using var reader = cmd.ExecuteReader();

                var list = new System.Collections.Generic.List<DoanhThuTheoThangModel>();
                while (reader.Read())
                {
                    list.Add(new DoanhThuTheoThangModel
                    {
                        Thang = "T" + reader["Thang"].ToString(),
                        DoanhThu = GetDecimal(reader, "TongDoanhThu")
                    });
                }

                decimal max = 1;
                foreach (var item in list) if (item.DoanhThu > max) max = item.DoanhThu;
                foreach (var item in list)
                {
                    item.ChieuCaoChuanHoa = (double)(item.DoanhThu / max);
                    DoanhThuTheoThang.Add(item);
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("LoadDoanhThuThang error: " + ex.Message);
            }
        }

        // ── Nguyên nhân tử vong (pie) ─────────────────────────────────────────
        private void LoadLoaiCauTu()
        {
            LoaiCauTu.Clear();
            try
            {
                var dt = DBConnect.GetData("SELECT * FROM VIEW_ThongKe_LoaiCauTu");
                int total = 0;
                foreach (DataRow row in dt.Rows)
                    total += Convert.ToInt32(row["SoLuong"]);
                if (total == 0) total = 1;

                double startAngle = 0;
                int colorIdx = 0;
                foreach (DataRow row in dt.Rows)
                {
                    int sl = Convert.ToInt32(row["SoLuong"]);
                    double angle = (double)sl / total * (2 * Math.PI);
                    LoaiCauTu.Add(new LoaiCauTuModel
                    {
                        LoaiCauTu = row["LoaiCauTu"]?.ToString() ?? "Khác",
                        SoLuong = sl,
                        GocRad = angle,
                        GocBatDau = startAngle,
                        MauSac = _colors[colorIdx % _colors.Length]
                    });
                    startAngle += angle;
                    colorIdx++;
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("LoadLoaiCauTu error: " + ex.Message);
            }
        }

        // ── Top 5 cảnh báo chưa đọc ──────────────────────────────────────────
        private void LoadTopCanhBao()
        {
            TopCanhBao.Clear();
            try
            {
                using var conn = new SqlConnection(DBConnect.ConnectionString);
                conn.Open();
                using var cmd = new SqlCommand("SP_DSCanhBao", conn)
                {
                    CommandType = CommandType.StoredProcedure
                };
                using var reader = cmd.ExecuteReader();
                int count = 0;
                while (reader.Read() && count < 5)
                {
                    TopCanhBao.Add(new CanhBaoModel
                    {
                        // Ép kiểu MACB về int
                        MACB = reader["MACB"] != DBNull.Value ? Convert.ToInt32(reader["MACB"]) : 0,

                        // Ép kiểu THOIGIAN về string (định dạng ngày giờ)
                        THOIGIAN = reader["THOIGIAN"] != DBNull.Value
                                         ? Convert.ToDateTime(reader["THOIGIAN"]).ToString("HH:mm dd/MM")
                                         : "",

                        LOAICB = reader["LOAICB"]?.ToString(),
                        NOIDUNG = reader["NOIDUNG"]?.ToString(),
                        MUC_DO_HIEN_THI = reader.HasColumn("MUC_DO_HIEN_THI")
                                         ? reader["MUC_DO_HIEN_THI"]?.ToString()
                                         : "Thông báo",
                        DAOC = reader.HasColumn("DAOC") && reader["DAOC"] != DBNull.Value ? Convert.ToBoolean(reader["DAOC"]) : false
                    });
                    count++;
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("LoadTopCanhBao error: " + ex.Message);
            }
        }

        // ── Helpers ───────────────────────────────────────────────────────────
        private static int GetInt(SqlDataReader r, string col)
            => r[col] == DBNull.Value ? 0 : Convert.ToInt32(r[col]);

        private static decimal GetDecimal(SqlDataReader r, string col)
            => r[col] == DBNull.Value ? 0m : Convert.ToDecimal(r[col]);
    }

    // Extension method nhỏ để kiểm tra column tồn tại
    internal static class SqlDataReaderExtensions
    {
        public static bool HasColumn(this SqlDataReader reader, string columnName)
        {
            for (int i = 0; i < reader.FieldCount; i++)
                if (reader.GetName(i).Equals(columnName, StringComparison.OrdinalIgnoreCase))
                    return true;
            return false;
        }
    }
}