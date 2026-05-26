using System;
using System.Data;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

namespace DoAn.QuanLy
{
    /// <summary>
    /// Interaction logic for BacSi.xaml
    /// </summary>

    public partial class DetailWindow : Window
    {
        private void LoadData(DataRowView row)
        {
            foreach (DataColumn col in row.Row.Table.Columns)
            {
                CreateUIElements(col.ColumnName, row[col.ColumnName]?.ToString());
            }
        }
        public DetailWindow(object model, string title)
        {
            InitializeComponent();
            txtTitle.Text = title.ToUpper();
            LoadDataFromModel(model);
        }

        private void LoadDataFromModel(object model)
        {
            if (model == null) return;

            PropertyInfo[] properties = model.GetType().GetProperties();

            foreach (PropertyInfo prop in properties)
            {
                string propName = prop.Name;
                object propValue = prop.GetValue(model);

                if (propName == "PropertyChanged") continue;

                CreateUIElements(propName, propValue?.ToString());
            }
        }

        // Hàm chung tạo UI
        private void CreateUIElements(string headerText, string contentText)
        {
            TextBlock lblHeader = new TextBlock();
            lblHeader.Text = headerText + ":";
            lblHeader.FontWeight = FontWeights.Bold;
            lblHeader.FontSize = 14;
            lblHeader.Foreground = Brushes.Gray;
            lblHeader.Margin = new Thickness(0, 10, 0, 0);

            TextBox txtContent = new TextBox();
            txtContent.Text = contentText;
            txtContent.FontSize = 16;
            txtContent.IsReadOnly = true;
            txtContent.BorderThickness = new Thickness(0);
            txtContent.Background = Brushes.Transparent;
            txtContent.TextWrapping = TextWrapping.Wrap;

            pnlContent.Children.Add(lblHeader);
            pnlContent.Children.Add(txtContent);
        }

        private void Button_Click(object sender, RoutedEventArgs e)
        {
            this.Close();
        }
    }
}