using DoAn.Core;
using DoAn.Model;
using Microsoft.Data.SqlClient;
using System;
using System.Collections.ObjectModel;
using System.Data;
using System.Windows;
using System.Windows.Input;

namespace DoAn.ViewModel
{
    public class TimKiemViewModel : BaseViewModel
    {
        // ── Từ khóa ──
        private string _tuKhoaTimKiem;
        public string TuKhoaTimKiem
        {
            get => _tuKhoaTimKiem;
            set { _tuKhoaTimKiem = value; OnPropertyChanged(); }
        }

        // ── Kết quả 3 loại ──
        public ObservableCollection<ThiHaiModel> KetQuaThiHai { get; set; } = new ObservableCollection<ThiHaiModel>();
        public ObservableCollection<ThanNhanModel> KetQuaThanNhan { get; set; } = new ObservableCollection<ThanNhanModel>();
        public ObservableCollection<HoaDonModel> KetQuaHoaDon { get; set; } = new ObservableCollection<HoaDonModel>();

        // ── Thông báo kết quả ──
        private string _thongBaoKetQua = "Nhập từ khóa và bấm Tìm Kiếm";
        public string ThongBaoKetQua
        {
            get => _thongBaoKetQua;
            set { _thongBaoKetQua = value; OnPropertyChanged(); }
        }

        private bool _dangTimKiem;
        public bool DangTimKiem
        {
            get => _dangTimKiem;
            set { _dangTimKiem = value; OnPropertyChanged(); }
        }

        // ── Commands ──
        public ICommand TimKiemCommand { get; set; }
        public ICommand XoaTimKiemCommand { get; set; }

        public TimKiemViewModel()
        {
            TimKiemCommand = new RelayCommand(
                p => ThucHienTimKiem(),
                p => !string.IsNullOrWhiteSpace(TuKhoaTimKiem) && !DangTimKiem
            );
            XoaTimKiemCommand = new RelayCommand(p => XoaKetQua());
        }

        private void ThucHienTimKiem()
        {
            if (string.IsNullOrWhiteSpace(TuKhoaTimKiem)) return;
            if (string.IsNullOrEmpty(DBConnect.ConnectionString))
            {
                MessageBox.Show("Chưa kết nối cơ sở dữ liệu!", "Lỗi", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            DangTimKiem = true;
            KetQuaThiHai.Clear();
            KetQuaThanNhan.Clear();
            KetQuaHoaDon.Clear();

            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    string keyword = TuKhoaTimKiem.Trim();

                    // ── Tìm Thi Hài ──
                    using (var cmd = new SqlCommand("EXEC SP_TimKiem_ThiHai @keyword", conn))
                    {
                        cmd.Parameters.AddWithValue("@keyword", keyword);
                        using (var da = new SqlDataAdapter(cmd))
                        {
                            var dt = new DataTable();
                            da.Fill(dt);
                            foreach (DataRow row in dt.Rows)
                            {
                                KetQuaThiHai.Add(new ThiHaiModel
                                {
                                    MaTH = row["MATH"].ToString(),
                                    HoTenTH = row["HOTEN_TH"].ToString(),
                                    GioiTinh = row["GIOITINH"].ToString(),
                                    NgaySinh = row["NGAYSINH"] != DBNull.Value ? (DateTime?)row["NGAYSINH"] : null,
                                    NgayMat = row["NGAYMAT"] != DBNull.Value ? (DateTime?)row["NGAYMAT"] : null
                                });
                            }
                        }
                    }

                    // ── Tìm Thân Nhân ──
                    using (var cmd = new SqlCommand("EXEC SP_TimKiem_ThanNhan @keyword", conn))
                    {
                        cmd.Parameters.AddWithValue("@keyword", keyword);
                        using (var da = new SqlDataAdapter(cmd))
                        {
                            var dt = new DataTable();
                            da.Fill(dt);
                            foreach (DataRow row in dt.Rows)
                            {
                                KetQuaThanNhan.Add(new ThanNhanModel
                                {
                                    MATN = row["MATN"].ToString(),
                                    HOTEN_TN = row["HOTEN_TN"].ToString(),
                                    DIENTHOAI = row["DIENTHOAI"].ToString(),
                                    MATH = row["MATH"].ToString(),
                                    HOTEN_TH = row["HOTEN_TH"].ToString()
                                });
                            }
                        }
                    }

                    // ── Tìm Hóa Đơn ──
                    using (var cmd = new SqlCommand("EXEC SP_TimKiem_HoaDon @keyword", conn))
                    {
                        cmd.Parameters.AddWithValue("@keyword", keyword);
                        using (var da = new SqlDataAdapter(cmd))
                        {
                            var dt = new DataTable();
                            da.Fill(dt);
                            foreach (DataRow row in dt.Rows)
                            {
                                KetQuaHoaDon.Add(new HoaDonModel
                                {
                                    MAHD = row["MAHD"].ToString(),
                                    MATH = row["MATH"].ToString(),
                                    NGAYLAP = row["NGAYLAP"] != DBNull.Value ? (DateTime?)row["NGAYLAP"] : null,
                                    TONGTIEN = row["TONGTIEN"] != DBNull.Value ? Convert.ToDecimal(row["TONGTIEN"]) : 0,
                                    TRANGTHAITT = row["TRANGTHAI"].ToString()
                                });
                            }
                        }
                    }
                }

                int tongKetQua = KetQuaThiHai.Count + KetQuaThanNhan.Count + KetQuaHoaDon.Count;
                if (tongKetQua == 0)
                    ThongBaoKetQua = $"Không tìm thấy kết quả nào cho \"{TuKhoaTimKiem}\"";
                else
                    ThongBaoKetQua = $"Tìm thấy {tongKetQua} kết quả — Thi hài: {KetQuaThiHai.Count} | Thân nhân: {KetQuaThanNhan.Count} | Hóa đơn: {KetQuaHoaDon.Count}";
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi tìm kiếm: " + ex.Message, "Lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
                ThongBaoKetQua = "Có lỗi xảy ra khi tìm kiếm";
            }
            finally
            {
                DangTimKiem = false;
            }
        }

        private void XoaKetQua()
        {
            TuKhoaTimKiem = string.Empty;
            KetQuaThiHai.Clear();
            KetQuaThanNhan.Clear();
            KetQuaHoaDon.Clear();
            ThongBaoKetQua = "Nhập từ khóa và bấm Tìm Kiếm";
        }
    }
}
