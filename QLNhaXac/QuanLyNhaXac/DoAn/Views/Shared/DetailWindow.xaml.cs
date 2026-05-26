using System;
using System.Data;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

namespace DoAn.Views.Shared
{
    /// <summary>
    /// Interaction logic for BacSi.xaml
    /// </summary>

    public partial class DetailWindow : Window
    {
        public DetailWindow(object model, string title)
        {
            InitializeComponent();
        }

        private void Button_Click(object sender, RoutedEventArgs e)
        {
            Close();
        }
    }
}