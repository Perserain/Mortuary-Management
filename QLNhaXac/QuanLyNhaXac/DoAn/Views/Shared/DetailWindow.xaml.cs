using System;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

namespace DoAn.Views.Shared
{
    public partial class DetailWindow : Window
    {
        public DetailWindow(object model, string title)
        {
            InitializeComponent();

            // Cập nhật tiêu đề cửa sổ
            txtTitle.Text = title ?? "CHI TIẾT THÔNG TIN";
            pnlContent.Children.Clear();

            // Nếu không có dữ liệu truyền vào
            if (model == null)
            {
                pnlContent.Children.Add(new TextBlock { Text = "Không có dữ liệu." });
                return;
            }

            // Dùng Reflection để tự động đọc tất cả các property (thuộc tính) public của Model
            var props = model.GetType().GetProperties(BindingFlags.Public | BindingFlags.Instance);
            foreach (var prop in props)
            {
                if (!prop.CanRead) continue;

                object value;
                try { value = prop.GetValue(model); }
                catch { continue; }

                // Tạo một dòng (StackPanel ngang) cho từng thuộc tính
                var row = new StackPanel { Orientation = Orientation.Horizontal, Margin = new Thickness(0, 4, 0, 4) };

                // Tên thuộc tính (Cột trái)
                row.Children.Add(new TextBlock
                {
                    Text = prop.Name + ":",
                    FontWeight = FontWeights.SemiBold,
                    Width = 160,
                    Foreground = Brushes.Black,
                });

                // Giá trị thuộc tính (Cột phải)
                row.Children.Add(new TextBlock
                {
                    Text = value?.ToString() ?? "(trống)",
                    TextWrapping = TextWrapping.Wrap,
                    MaxWidth = 380
                });

                // Đẩy dòng này vào giao diện chính
                pnlContent.Children.Add(row);
            }
        }

        // Sự kiện đóng cửa sổ
        private void Button_Click(object sender, RoutedEventArgs e)
        {
            Close();
        }
    }
}