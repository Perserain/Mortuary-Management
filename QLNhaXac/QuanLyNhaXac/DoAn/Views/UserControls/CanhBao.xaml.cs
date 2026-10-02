using DoAn.ViewModel;
using System.Windows.Controls;

namespace DoAn.Views.UserControls
{
    public partial class CanhBao : UserControl
    {
        public CanhBao()
        {
            InitializeComponent();
        }

        // Tab "Chưa đọc" được chọn
        private void TabChuaDoc_Checked(object sender, System.Windows.RoutedEventArgs e)
        {
            if (DataContext is CanhBaoViewModel vm)
                vm.ChiHienChuaDoc = true;
        }

        // Tab "Tất cả" được chọn
        private void TabTatCa_Checked(object sender, System.Windows.RoutedEventArgs e)
        {
            if (DataContext is CanhBaoViewModel vm)
                vm.ChiHienChuaDoc = false;
        }
    }
}
