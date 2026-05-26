using DoAn.ViewModel;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;

namespace DoAn.QuanLy
{
    public partial class DichVu : UserControl
    {
        public DichVu()
        {
            InitializeComponent();
            if (DBConnect.QuyenHan != "WriteAccess")
            {
                StPanelNut.Visibility = Visibility.Collapsed;
                StPanelChucNang.Visibility = Visibility.Collapsed;
            }
        }
    }
}