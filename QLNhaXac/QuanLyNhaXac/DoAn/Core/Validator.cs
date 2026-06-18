using System;
using System.Text.RegularExpressions;

namespace DoAn.Core
{
    /// <summary>
    /// Lớp validate dữ liệu phía UI — chỉ kiểm tra format và trường bắt buộc.
    /// Logic nghiệp vụ phức tạp (trùng mã, ràng buộc FK...) vẫn để SQL xử lý.
    /// </summary>
    public static class Validator
    {
        // Regex số điện thoại Việt Nam: đầu số 03x, 05x, 07x, 08x, 09x — 10 chữ số
        private static readonly Regex _phoneRegex =
            new Regex(@"^(0[3|5|7|8|9])+([0-9]{8})$", RegexOptions.Compiled);

        /// <summary>Kiểm tra số điện thoại theo chuẩn VN (10 số, đúng đầu số).</summary>
        public static bool IsValidPhone(string sdt)
        {
            if (string.IsNullOrWhiteSpace(sdt)) return false;
            return _phoneRegex.IsMatch(sdt.Trim());
        }

        /// <summary>Kiểm tra ngày không null và không vượt quá hôm nay.</summary>
        public static bool IsValidDate(DateTime? date)
        {
            return date.HasValue && date.Value <= DateTime.Now;
        }

        /// <summary>Kiểm tra chuỗi không rỗng / không chỉ khoảng trắng.</summary>
        public static bool IsNotEmpty(string value)
        {
            return !string.IsNullOrWhiteSpace(value);
        }

        /// <summary>
        /// Kiểm tra ngày mất >= ngày sinh (cả hai phải có giá trị).
        /// </summary>
        public static bool IsNgayMatHopLe(DateTime? ngaySinh, DateTime? ngayMat)
        {
            if (!ngaySinh.HasValue || !ngayMat.HasValue) return true; // Bỏ qua nếu thiếu 1 trong 2
            return ngayMat.Value.Date >= ngaySinh.Value.Date;
        }

        // ====================================================================
        // CÁC HÀM MỚI BỔ SUNG
        // ====================================================================

        /// <summary>
        /// Kiểm tra mã code hợp lệ — không rỗng và có đúng tiền tố.
        /// Ví dụ: IsValidMaCode("TH001", "TH") → true
        /// </summary>
        public static bool IsValidMaCode(string ma, string prefix)
        {
            if (string.IsNullOrWhiteSpace(ma)) return false;
            return ma.Trim().StartsWith(prefix, StringComparison.OrdinalIgnoreCase);
        }

        /// <summary>
        /// Kiểm tra năm kinh nghiệm hợp lệ: phải >= 0.
        /// </summary>
        public static bool IsNamKinhNghiemHopLe(int? nam)
        {
            return nam.HasValue && nam.Value >= 0;
        }

        /// <summary>
        /// Kiểm tra giới tính hợp lệ theo danh sách chấp nhận.
        /// </summary>
        public static bool IsGioiTinhHopLe(string gioiTinh)
        {
            if (string.IsNullOrWhiteSpace(gioiTinh)) return false;
            var valid = new[] { "Nam", "Nữ", "Không xác định", "Chưa rõ" };
            return Array.Exists(valid, v => v.Equals(gioiTinh.Trim(), StringComparison.OrdinalIgnoreCase));
        }

        /// <summary>
        /// Kiểm tra nhiệt độ ngăn kéo: phải nhỏ hơn 10°C.
        /// </summary>
        public static bool IsNhietDoNganKeoHopLe(double? nhietDo)
        {
            return nhietDo.HasValue && nhietDo.Value < 10;
        }

        /// <summary>
        /// Kiểm tra số lượng dịch vụ: phải >= 1.
        /// </summary>
        public static bool IsSoLuongHopLe(int? soLuong)
        {
            return soLuong.HasValue && soLuong.Value >= 1;
        }

        /// <summary>
        /// Kiểm tra số tiền hợp lệ: phải >= 0.
        /// </summary>
        public static bool IsTienHopLe(decimal? tien)
        {
            return tien.HasValue && tien.Value >= 0;
        }

        /// <summary>
        /// Kiểm tra ngày khám không được TRƯỚC ngày mất.
        /// Nếu một trong hai null → trả true (bỏ qua kiểm tra, để SQL xử lý).
        /// </summary>
        public static bool IsNgayKhamHopLe(DateTime? ngayKham, DateTime? ngayMat)
        {
            if (!ngayKham.HasValue || !ngayMat.HasValue) return true;
            return ngayKham.Value.Date >= ngayMat.Value.Date;
        }

        /// <summary>
        /// Kiểm tra ngày sử dụng dịch vụ không được TRƯỚC ngày mất.
        /// </summary>
        public static bool IsNgayDichVuHopLe(DateTime? ngayDV, DateTime? ngayMat)
        {
            if (!ngayDV.HasValue || !ngayMat.HasValue) return true;
            return ngayDV.Value.Date >= ngayMat.Value.Date;
        }
    }
}