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
            return ngayMat.Value >= ngaySinh.Value;
        }
    }
}
