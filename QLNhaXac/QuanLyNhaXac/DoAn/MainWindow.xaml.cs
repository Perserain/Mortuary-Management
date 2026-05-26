using DoAn.ViewModel;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
namespace DoAn.QuanLy
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
            MainContent.Content = new BacSi();
        }

        // --- HÀM CHUYỂN MÀU MENU ---
        void ResetMenuColors()
        {
            string color = "#34495E";
            var converter = new System.Windows.Media.BrushConverter();

            System.Windows.Media.Brush defaultBrush = (System.Windows.Media.Brush)converter.ConvertFromString(color);
            btnBacSi.Background = defaultBrush;
            btnHoSo.Background = defaultBrush;
            btnDichVu.Background = defaultBrush;
            btnThiHai.Background = defaultBrush;
            btnNganKeo.Background = defaultBrush;
            btnSuDung.Background = defaultBrush;
        }

        void ActiveMenu(Button activebtn)
        {
            string color = "#1ABC9C";
            var converter = new System.Windows.Media.BrushConverter();
            System.Windows.Media.Brush changedBrush = (System.Windows.Media.Brush)converter.ConvertFromString(color);

            ResetMenuColors();
            activebtn.Background = changedBrush;
        }

        // --- CÁC HÀM CHUYỂN TRANG ---
        private void BtnBacSi_Click(object sender, RoutedEventArgs e)
        {
            MainContent.Content = new BacSi();
            ActiveMenu(btnBacSi);
        }

        private void BtnHoSo_Click(object sender, RoutedEventArgs e)
        {
            MainContent.Content = new HoSoKB();
            ActiveMenu(btnHoSo);
        }

        private void BtnDichVu_Click(object sender, RoutedEventArgs e)
        {
            MainContent.Content = new DichVu();
            ActiveMenu(btnDichVu);
        }

        private void BtnThiHai_Click(object sender, RoutedEventArgs e)
        {
            MainContent.Content = new ThiHai();
            ActiveMenu(btnThiHai);
        }

        private void BtnNganKeo_Click(object sender, RoutedEventArgs e)
        {
            MainContent.Content = new NganKeo();
            ActiveMenu(btnNganKeo);
        }

        private void BtnSuDung_Click(object sender, RoutedEventArgs e)
        {
            MainContent.Content = new SuDung();
            ActiveMenu(btnSuDung);
        }
        // --- NÚT KIỂM TRA DUNG LƯỢNG DB

        private void BtnCheckSize_Click(object sender, RoutedEventArgs e)
        {
            DataTable dt = DBConnect.GetData("EXEC sp_spaceused");
            if (dt.Rows.Count > 0) MessageBox.Show("Dung lượng DB: " + dt.Rows[0]["database_size"].ToString());
        }

        // --- NÚT ĐĂNG XUẤT ---
        private void BtnLogOut_Click(object sender, RoutedEventArgs e)
        {
            if (MessageBox.Show("Bạn có chắc chắn muốn đăng xuất?", "Xác nhận", MessageBoxButton.YesNo, MessageBoxImage.Question) == MessageBoxResult.Yes)
            {
                // Mở lại cửa sổ đăng nhập
                LoginWindow login = new LoginWindow();
                login.Show();

                // Đóng cửa sổ chính
                this.Close();
            }
        }
    }
}