using System;
using DoAn.ViewModel;

namespace DoAn.Model
{
    public class HoaDonModel : BaseViewModel
    {
        private string _mahd;
        private string _math;
        private string _hotenTH;
        private string _nguoiNhan;
        private string _sdtNguoiNhan;
        private DateTime? _ngayLap;
        private decimal _tongTien;
        private string _trangThaiTT;
        private string _phuongThucTT;
        private DateTime? _ngayThanhToan;
        private string _nguoiLap;
        private string _ghiChu;
        private int _soNgayNo;

        public string MAHD
        {
            get => _mahd;
            set { _mahd = value; OnPropertyChanged(); }
        }

        public string MATH
        {
            get => _math;
            set { _math = value; OnPropertyChanged(); }
        }

        public string HOTEN_TH
        {
            get => _hotenTH;
            set { _hotenTH = value; OnPropertyChanged(); }
        }

        // Người nhận / người liên hệ chính
        public string NGUOI_NHAN
        {
            get => _nguoiNhan;
            set { _nguoiNhan = value; OnPropertyChanged(); }
        }

        public string SDT_NGUOI_NHAN
        {
            get => _sdtNguoiNhan;
            set { _sdtNguoiNhan = value; OnPropertyChanged(); }
        }

        public DateTime? NGAYLAP
        {
            get => _ngayLap;
            set { _ngayLap = value; OnPropertyChanged(); }
        }

        public decimal TONGTIEN
        {
            get => _tongTien;
            set { _tongTien = value; OnPropertyChanged(); }
        }

        public string TRANGTHAITT
        {
            get => _trangThaiTT;
            set
            {
                _trangThaiTT = value;
                OnPropertyChanged();
                OnPropertyChanged(nameof(MauTrangThai));
            }
        }

        public string PHUONGTHUCTT
        {
            get => _phuongThucTT;
            set { _phuongThucTT = value; OnPropertyChanged(); }
        }

        public DateTime? NGAYTHANHTOAN
        {
            get => _ngayThanhToan;
            set { _ngayThanhToan = value; OnPropertyChanged(); }
        }

        public string NGUOILAP
        {
            get => _nguoiLap;
            set { _nguoiLap = value; OnPropertyChanged(); }
        }

        public string GHICHU
        {
            get => _ghiChu;
            set { _ghiChu = value; OnPropertyChanged(); }
        }

        // Chỉ có trong VIEW_HoaDon_ChuaThanhToan
        public int SO_NGAY_NO
        {
            get => _soNgayNo;
            set { _soNgayNo = value; OnPropertyChanged(); }
        }

        // Màu badge trạng thái thanh toán (dùng cho UI)
        public string MauTrangThai
        {
            get
            {
                switch (TRANGTHAITT)
                {
                    case "Chưa thanh toán": return "#EF4444"; // đỏ
                    case "Nợ": return "#F59E0B";              // cam
                    case "Đã thanh toán": return "#10B981";   // xanh lá
                    case "Miễn phí": return "#94A3B8";        // xám
                    default: return "#94A3B8";
                }
            }
        }
    }
}