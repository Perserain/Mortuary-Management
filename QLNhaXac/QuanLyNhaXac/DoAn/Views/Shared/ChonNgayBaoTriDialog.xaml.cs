using System;
using System.Windows;

namespace DoAn.Views.Shared
{
    public partial class ChonNgayBaoTriDialog : Window
    {
        public DateTime NgayChon { get; private set; }

        public ChonNgayBaoTriDialog(string maNgan, DateTime? ngayHienTai)
        {
            InitializeComponent();
            TieuDe.Text = $"🔧 Ghi nhận bảo trì ngăn [{maNgan}]";
            NgayBaoTriPicker.SelectedDate = ngayHienTai ?? DateTime.Today;
        }

        private void XacNhan_Click(object sender, RoutedEventArgs e)
        {
            if (NgayBaoTriPicker.SelectedDate == null)
            {
                MessageBox.Show("Vui lòng chọn ngày bảo trì!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            NgayChon = NgayBaoTriPicker.SelectedDate.Value;
            DialogResult = true;
        }

        private void Huy_Click(object sender, RoutedEventArgs e)
        {
            DialogResult = false;
        }
    }
}
