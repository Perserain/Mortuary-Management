using DoAn.ViewModel;
using System.Windows.Controls;

namespace DoAn.Views.UserControls
{
    public partial class BaoCao : UserControl
    {
        public BaoCao()
        {
            InitializeComponent();
        }

        // Đồng bộ TabDangChon trong ViewModel khi tab thay đổi (để XuatExcel biết tab nào)
        private void MainTabControl_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (DataContext is BaoCaoViewModel vm)
                vm.TabDangChon = MainTabControl.SelectedIndex;
        }

        private void TabThiHai_Click(object sender, System.Windows.RoutedEventArgs e)
            => MainTabControl.SelectedIndex = 0;

        private void TabDoanhThu_Click(object sender, System.Windows.RoutedEventArgs e)
            => MainTabControl.SelectedIndex = 1;

        private void TabNhanVien_Click(object sender, System.Windows.RoutedEventArgs e)
            => MainTabControl.SelectedIndex = 2;
    }
}
