using DoAn.ViewModel;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
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

namespace DoAn.QuanLy
{
    public partial class ThiHai : UserControl
    {
        public ThiHai()
        {
            InitializeComponent();
            if (DBConnect.QuyenHan != "WriteAccess") //Nếu quyền hạn không phải db_datawriter hay db_dataowner thì ẩn các nút đi
            {
                StPanelNut.Visibility = Visibility.Collapsed;
                StPanelChucNang.Visibility = Visibility.Collapsed;
            }
        }
    }
}
