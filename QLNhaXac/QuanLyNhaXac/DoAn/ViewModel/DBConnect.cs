using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Data.SqlClient;

namespace DoAn.ViewModel
{
    public static class DBConnect
    {
        // Biến tĩnh lưu chuỗi kết nối (Thay đổi khi đăng nhập)
        public static string ConnectionString = "";
        public static string QuyenHan = "";

        // Hàm tạo chuỗi kết nối động
        public static void SetConnection(string user, string pass)
        {
            SqlConnectionStringBuilder builder = new SqlConnectionStringBuilder();
            builder.DataSource = "26.79.168.121,1433";
            builder.InitialCatalog = "QuanLyNhaXac";
            builder.UserID = user;
            builder.Password = pass;
            builder.IntegratedSecurity = false;
            builder.TrustServerCertificate = true;
            builder.ConnectTimeout = 5;

            ConnectionString = builder.ToString();

            // Kiểm tra thử kết nối xem có được không?
            if (!CheckConnection(ConnectionString))
            {
                builder.DataSource = "."; // Dấu chấm (.) đại diện cho Localhost
                ConnectionString = builder.ToString();
            }
            CheckUserRole();
        }

        // Hàm phụ để kiểm tra kết nối
        private static bool CheckConnection(string connString)
        {
            try
            {
                using (SqlConnection conn = new SqlConnection(connString))
                {
                    conn.Open();
                    return true;
                }
            }
            catch
            {
                return false;
            }
        }

        // Hàm lấy dữ liệu chung (Select)
        public static DataTable GetData(string query)
        {
            DataTable dt = new DataTable();
            try
            {
                using (SqlConnection conn = new SqlConnection(ConnectionString))
                {
                    conn.Open();
                    SqlDataAdapter da = new SqlDataAdapter(query, conn);
                    da.Fill(dt);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi truy vấn: " + ex.Message);
            }
            return dt;
        }

        private static string CheckUserRole()
        {
            try
            {
                using (SqlConnection conn = new SqlConnection(ConnectionString))
                {
                    conn.Open();

                    // Chỉ cần gọi tên thủ tục
                    using (SqlCommand cmd = new SqlCommand("SP_KiemTraQuyenHan", conn))
                    {
                        // Nhớ set CommandType là StoredProcedure
                        cmd.CommandType = CommandType.StoredProcedure;

                        // ExecuteScalar sẽ lấy giá trị 'WriteAccess' hoặc 'ReadOnly' từ dòng SELECT của thủ tục
                        object result = cmd.ExecuteScalar();

                        // Gán kết quả vào biến QuyenHan của DBConnect
                        QuyenHan = result?.ToString() ?? "ReadOnly";
                    }
                }
                return QuyenHan;
            }
            catch (Exception ex)
            {
                QuyenHan = "Error";
                MessageBox.Show("Không thể xác minh quyền hạn: " + ex.Message, "Lỗi kết nối");
                return QuyenHan;
            }
        }
    }
}
