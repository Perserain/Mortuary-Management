using DoAn.QuanLy;
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

namespace DoAn
{
    /// <summary>
    /// Interaction logic for KhachHangWindow.xaml
    /// </summary>
    public partial class KhachHangWindow : Window
    {
        public KhachHangWindow()
        {
            InitializeComponent();
            MainContent.Content = new ThiHai();
        }

        void ResetMenuColors()
        {
            string color = "#34495E";
            var converter = new BrushConverter();
            Brush defaultBrush = (Brush)converter.ConvertFromString(color);
            btnTraCuu.Background = defaultBrush;
            btnDichVu.Background = defaultBrush;
        }

        void ActiveMenu(Button activebtn)
        {
            string color = "#1ABC9C";
            var converter = new BrushConverter();
            Brush changedBrush = (Brush)converter.ConvertFromString(color);
            ResetMenuColors();
            activebtn.Background = changedBrush;
        }

        private void BtnTraCuu_Click(object sender, RoutedEventArgs e)
        {
            MainContent.Content = new ThiHai();
            ActiveMenu(btnTraCuu);
        }

        private void BtnDichVu_Click(object sender, RoutedEventArgs e)
        {
            MainContent.Content = new DichVu();
            ActiveMenu(btnDichVu);
        }

        private void BtnLogOut_Click(object sender, RoutedEventArgs e)
        {
            if (MessageBox.Show("Bạn muốn kết thúc phiên tra cứu?", "Đăng xuất", MessageBoxButton.YesNo, MessageBoxImage.Question) == MessageBoxResult.Yes)
            {
                LoginWindow login = new LoginWindow();
                login.Show();
                this.Close();
            }
        }
    }
}
