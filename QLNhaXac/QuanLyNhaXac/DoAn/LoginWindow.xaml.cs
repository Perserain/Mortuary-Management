using System;
using System.Collections.Generic;
using System.Data;
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
    public partial class LoginWindow : Window
    {
        public LoginWindow()
        {
            InitializeComponent();
        }

        private void btnLogin_Click(object sender, RoutedEventArgs e)
        {
            // 1. Lấy thông tin từ giao diện
            string u = txtUser.Text.Trim();      // User của SQL (VD: sa, qlnx...)
            string p = txtPassword.Password;     // Pass của SQL

            if (u == "" || p == "")
            {
                MessageBox.Show("Vui lòng nhập tài khoản và mật khẩu SQL!");
                return;
            }

            try
            {  
                // 2. Cấu hình chuỗi kết nối bằng chính User/Pass vừa nhập
                DBConnect.SetConnection(u, p);

                // 3. THỬ MỞ KẾT NỐI (Đây chính là bước kiểm tra User/Pass)
                using (SqlConnection conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open(); 

                    MessageBox.Show($"Đăng nhập thành công với tài khoản: {u}");
                    if (DBConnect.QuyenHan!="WriteAccess") // Nếu không phải tài khoản admin thì mở form khách hàng
                    {
                        KhachHangWindow main = new KhachHangWindow();
                        main.Show();
                        this.Close();
                    }
                    else // Mở form chính
                    {
                        MainWindow main = new MainWindow();
                        main.Show();
                        this.Close();
                    }
                }
            }
            catch (SqlException ex)
            {
                // Bắt lỗi cụ thể của SQL Server
                // Mã lỗi 18456: Login failed for user (Sai mật khẩu hoặc User không tồn tại)
                // Bắt lỗi cụ thể
                if (ex.Number == 18456)
                {
                    MessageBox.Show("Tài khoản hoặc Mật khẩu không đúng!", "Đăng nhập thất bại", MessageBoxButton.OK, MessageBoxImage.Error);
                }
                else if (ex.Number == 53 || ex.Number == -1 || ex.Number == 2)
                {
                    MessageBox.Show("Không tìm thấy Máy Chủ SQL!\nHãy kiểm tra lại IP hoặc dây mạng.", "Lỗi Kết Nối", MessageBoxButton.OK, MessageBoxImage.Warning);
                }
                else
                {
                    MessageBox.Show("Lỗi khác: " + ex.Message);
                }
            }
        }

        private void btnRegister_Click(object sender, RoutedEventArgs e)
        {
            // Mở form đăng ký
            Register reg = new Register();
            reg.ShowDialog();
        }
    }
}
