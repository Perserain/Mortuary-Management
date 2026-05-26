using System;
using System.Collections.Generic;
using Microsoft.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;

namespace DoAn.ViewModel
{
    public class RegisterViewModel : BaseViewModel
    {
        private string _usernameReg;
        public string UsernameReg
        {
            get => _usernameReg;
            set { _usernameReg = value; OnPropertyChanged(); }
        }

        public ICommand RegisterCommand { get; set; }

        public RegisterViewModel()
        {
            RegisterCommand = new RelayCommand(p => ExecuteRegister(p));
        }

        private void ExecuteRegister(object parameter)
        {
            var window = parameter as Window;
            if (window == null) return;

            var passwordBox = window.FindName("TxtPassword_Re") as PasswordBox;
            string u = UsernameReg?.Trim();
            string p = passwordBox?.Password;

            if (string.IsNullOrEmpty(u) || string.IsNullOrEmpty(p))
            {
                MessageBox.Show("Vui lòng nhập đầy đủ thông tin!");
                return;
            }

            try
            {
                string connStr = "Data Source=26.79.168.121,1433;Initial Catalog=QuanLyNhaXac;User ID=NhaXacAdmin;Password=123456;TrustServerCertificate=True";
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    string sqlLogin = $"CREATE LOGIN [{u}] WITH PASSWORD=N'{p}', DEFAULT_DATABASE=[QuanLyNhaXac], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF";
                    using (SqlCommand cmd = new SqlCommand(sqlLogin, conn)) { cmd.ExecuteNonQuery(); }

                    string sqlUser = $"CREATE USER [{u}] FOR LOGIN [{u}]";
                    using (SqlCommand cmd = new SqlCommand(sqlUser, conn)) { cmd.ExecuteNonQuery(); }

                        string sqlRole = $"ALTER ROLE [db_datareader] ADD MEMBER [{u}]; ALTER ROLE [app_staff] ADD MEMBER [{u}];";
                    using (SqlCommand cmd = new SqlCommand(sqlRole, conn)) { cmd.ExecuteNonQuery(); }

                    MessageBox.Show("Đăng ký thành công! Vui lòng dùng tài khoản này để đăng nhập.", "Thành công");
                    window.Close();
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi đăng ký (Có thể tài khoản đã tồn tại):\n" + ex.Message, "Lỗi");
            }
        }
    }
}
