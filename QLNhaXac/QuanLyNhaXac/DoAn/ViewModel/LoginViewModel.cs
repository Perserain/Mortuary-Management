using DoAn.Core;
using DoAn.Views.Auth;
using DoAn.Views.Layouts;
using DoAn.Views.Staff;
using System;
using System.Collections.Generic;
using Microsoft.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using DoAn.Views.Doctor;

namespace DoAn.ViewModel
{
    public class LoginViewModel : BaseViewModel
    {
        private string _username;
        public string Username
        {
            get => _username;
            set { _username = value; OnPropertyChanged(); }
        }

        private bool _useLocalDb;
        public bool UseLocalDb
        {
            get => _useLocalDb;
            set { _useLocalDb = value; OnPropertyChanged(); }
        }

        public ICommand LoginCommand { get; set; }
        public ICommand NavigateRegisterCommand { get; set; }

        public LoginViewModel()
        {
            LoginCommand = new RelayCommand(p => ExecuteLogin(p));
            NavigateRegisterCommand = new RelayCommand(p => ExecuteNavigateRegister());
        }

        private void ExecuteLogin(object parameter)
        {
            var window = parameter as Window;
            if (window == null) return;

            // Tìm PasswordBox nằm trong Window thông qua Name định nghĩa ở XAML
            var passwordBox = window.FindName("txtPassword") as PasswordBox;
            string u = Username?.Trim();
            string p = passwordBox?.Password;

            if (!UseLocalDb && (string.IsNullOrEmpty(u) || string.IsNullOrEmpty(p)))
            {
                MessageBox.Show("Vui lòng nhập tài khoản và mật khẩu!");
                return;
            }

            try
            {
                DBConnect.SetConnection(u, p, UseLocalDb);
                using (SqlConnection conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                }

                if (DBConnect.IsAdmin)
                {
                    MainWindow main = new MainWindow();
                    main.Show();
                    window.Close();
                    return;
                }

                if (DBConnect.IsStaff)
                {
                    StaffWindow staff = new StaffWindow();
                    staff.Show();
                    window.Close();
                    return;
                }

                if (DBConnect.IsDoctor)
                {
                    DoctorWindow doctor = new DoctorWindow();
                    doctor.Show();
                    window.Close();
                    return;
                }

                MessageBox.Show("Tài khoản hiện tại chỉ có quyền đọc. Vui lòng đăng nhập tài khoản khác.", "Thông báo");
            }
            catch (Exception ex)
            {
                MessageBox.Show("Đăng nhập thất bại. Sai tài khoản hoặc mật khẩu!\nChi tiết: " + ex.Message, "Lỗi");
            }
        }

        private void ExecuteNavigateRegister()
        {
            Register reg = new Register();
            reg.ShowDialog();
        }
    }
}
