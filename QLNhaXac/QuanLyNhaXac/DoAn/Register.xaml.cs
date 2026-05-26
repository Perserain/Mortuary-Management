using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;
using System.Data.SqlClient;
using DoAn.ViewModel;

namespace DoAn.QuanLy
{
    /// <summary>
    /// Interaction logic for Register.xaml
    /// </summary>
    public partial class Register : Window
    {
        public Register()
        {
            InitializeComponent();
        }

        private void btnDangKy_Click(object sender, RoutedEventArgs e)
        {
            string u = TxtUsername_Re.Text.Trim();
            string p = TxtPassword_Re.Password.Trim();

            // 1. Kiểm tra input
            if (u == "" || p == "") { MessageBox.Show("Vui lòng nhập đủ thông tin!"); return; }
            if (u.Contains(" ") || u.Contains("'") || u.Contains(";")) { MessageBox.Show("Tài khoản không hợp lệ!"); return; }

            try
            {
                // 2. TẠO CHUỖI KẾT NỐI DÀNH RIÊNG CHO ADMIN (SA)
                // Mục đích: Luôn dùng quyền cao nhất để tạo user, tránh lỗi quyền hạn.

                DBConnect.SetConnection("sa", "123");
                using (SqlConnection conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();

                    // 3. Kiểm tra trùng lặp
                    string checkSql = "SELECT count(*) FROM master.sys.server_principals WHERE name = @u";
                    SqlCommand checkCmd = new SqlCommand(checkSql, conn);
                    checkCmd.Parameters.AddWithValue("@u", u);

                    if ((int)checkCmd.ExecuteScalar() > 0)
                    {
                        MessageBox.Show($"Tài khoản '{u}' đã tồn tại!");
                        return;
                    }

                    // 4. Tạo tài khoản
                    // Role: db_datareader để user này chỉ có thể đọc dữ liệu
                    string createSql = $@"
                CREATE LOGIN [{u}] WITH PASSWORD = '{p}', CHECK_POLICY = OFF, CHECK_EXPIRATION=OFF
                CREATE USER [{u}] FOR LOGIN [{u}];
                ALTER ROLE [db_datareader] ADD MEMBER [{u}];
            ";

                    SqlCommand cmd = new SqlCommand(createSql, conn);
                    cmd.ExecuteNonQuery();

                    MessageBox.Show($"Đăng ký thành công User: {u}\nBạn có thể đăng nhập ngay!");
                    this.Close();
                }
            }
            catch (SqlException ex)
            {
                // Lỗi 18456: Sai mật khẩu SA
                if (ex.Number == 18456)
                    MessageBox.Show("Lỗi quyền Admin: Mật khẩu tài khoản 'sa' trong code không đúng với trong SQL Server.");
                // Lỗi 0 hoặc 2, 53: Không tìm thấy server (Do sai IP hoặc tên DB)
                else if (ex.Number == 0 || ex.Number == 2 || ex.Number == 53)
                    MessageBox.Show($"Không kết nối được tới Server/Database.\nIP: {DBConnect.ConnectionString}\nDB: QuanLyXacChet\nLỗi chi tiết: {ex.Message}");
                else
                    MessageBox.Show("Lỗi SQL: " + ex.Message);
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi hệ thống: " + ex.Message);
            }
        }
    }
}
