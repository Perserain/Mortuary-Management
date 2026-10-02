using DoAn.ViewModel;
using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Shapes;

namespace DoAn.Views.UserControls
{
    public partial class DashboardView : UserControl
    {
        public DashboardView()
        {
            InitializeComponent();
            Loaded += DashboardView_Loaded;
        }

        private void DashboardView_Loaded(object sender, RoutedEventArgs e)
        {
            if (DataContext is DashboardViewModel vm)
            {
                vm.ChartDataUpdated += () =>
                {
                    Dispatcher.Invoke(() =>
                    {
                        DrawThiHaiChart(vm);
                        DrawDoanhThuChart(vm);
                        DrawPieChart(vm);
                    });
                };

                // Vẽ ngay lần đầu nếu đã có data
                DrawThiHaiChart(vm);
                DrawDoanhThuChart(vm);
                DrawPieChart(vm);
            }
        }

        private void DrawThiHaiChart(DashboardViewModel vm)
        {
            CanvasThiHai.Children.Clear();
            var data = vm.ThiHaiTheoThang;
            if (data == null || data.Count == 0) return;

            CanvasThiHai.UpdateLayout();
            double canvasH = CanvasThiHai.ActualHeight - 20;
            double barW = Math.Max((CanvasThiHai.ActualWidth / data.Count) - 10, 10);

            for (int i = 0; i < data.Count; i++)
            {
                double barH = data[i].ChieuCaoChuanHoa * canvasH;

                var rect = new Rectangle
                {
                    Width = barW,
                    Height = Math.Max(barH, 2),
                    Fill = new SolidColorBrush(Color.FromRgb(16, 185, 129)),
                    ToolTip = $"Tháng: {data[i].Thang}\nSố lượng: {data[i].SoLuong} thi hài"
                };

                Canvas.SetLeft(rect, i * (barW + 5) + 5);
                Canvas.SetTop(rect, canvasH - barH);
                CanvasThiHai.Children.Add(rect);

                var valueLabel = new TextBlock
                {
                    Text = data[i].SoLuong.ToString(),
                    Foreground = Brushes.Black,
                    FontSize = 10,
                    TextAlignment = TextAlignment.Center,
                    Width = barW
                };
                Canvas.SetLeft(valueLabel, i * (barW + 5) + 5);
                Canvas.SetTop(valueLabel, Math.Max(canvasH - barH - 15, 0));
                CanvasThiHai.Children.Add(valueLabel);

                var monthLabel = new TextBlock
                {
                    Text = data[i].Thang,
                    Foreground = Brushes.Gray,
                    FontSize = 10,
                    TextAlignment = TextAlignment.Center,
                    Width = barW
                };
                Canvas.SetLeft(monthLabel, i * (barW + 5) + 5);
                Canvas.SetTop(monthLabel, canvasH + 2);
                CanvasThiHai.Children.Add(monthLabel);
            }
        }

        // ── Biểu đồ cột: Doanh thu theo tháng ─────────────────────────────
        private void DrawDoanhThuChart(DashboardViewModel vm)
        {
            CanvasDoanhThu.Children.Clear();
            var data = vm.DoanhThuTheoThang;
            if (data == null || data.Count == 0) return;

            CanvasDoanhThu.UpdateLayout();
            double canvasH = CanvasDoanhThu.ActualHeight - 20;
            double barW = Math.Max((CanvasDoanhThu.ActualWidth / data.Count) - 10, 10);

            for (int i = 0; i < data.Count; i++)
            {
                double barH = data[i].ChieuCaoChuanHoa * canvasH;

                var rect = new Rectangle
                {
                    Width = barW,
                    Height = Math.Max(barH, 2),
                    Fill = new SolidColorBrush(Color.FromRgb(59, 130, 246)),
                    ToolTip = $"Tháng: {data[i].Thang}\nDoanh thu: {data[i].DoanhThu:N0}đ"
                };

                Canvas.SetLeft(rect, i * (barW + 5) + 5);
                Canvas.SetTop(rect, canvasH - barH);
                CanvasDoanhThu.Children.Add(rect);

                string formattedValue = data[i].DoanhThu >= 1000000
                    ? (data[i].DoanhThu / 1000000m).ToString("0.#") + "M"
                    : (data[i].DoanhThu / 1000m).ToString("0.#") + "K";

                var valueLabel = new TextBlock
                {
                    Text = formattedValue,
                    Foreground = Brushes.Black,
                    FontSize = 10,
                    TextAlignment = TextAlignment.Center,
                    Width = barW
                };
                Canvas.SetLeft(valueLabel, i * (barW + 5) + 5);
                Canvas.SetTop(valueLabel, Math.Max(canvasH - barH - 15, 0));
                CanvasDoanhThu.Children.Add(valueLabel);

                var monthLabel = new TextBlock
                {
                    Text = data[i].Thang,
                    Foreground = Brushes.Gray,
                    FontSize = 10,
                    TextAlignment = TextAlignment.Center,
                    Width = barW
                };
                Canvas.SetLeft(monthLabel, i * (barW + 5) + 5);
                Canvas.SetTop(monthLabel, canvasH + 2);
                CanvasDoanhThu.Children.Add(monthLabel);
            }
        }

        // ── Biểu đồ tròn: Nguyên nhân tử vong ─────────────────────────────
        private void DrawPieChart(DashboardViewModel vm)
        {
            CanvasPie.Children.Clear();
            var data = vm.LoaiCauTu;
            if (data == null || data.Count == 0)
            {
                AddEmptyLabel(CanvasPie, "Chưa có dữ liệu");
                return;
            }

            CanvasPie.UpdateLayout();
            double size = Math.Min(CanvasPie.ActualWidth, CanvasPie.ActualHeight);
            if (size < 10) size = 110;
            double cx = size / 2;
            double cy = size / 2;
            double r = size / 2 - 4;

            foreach (var item in data)
            {
                double startAngle = item.GocBatDau - Math.PI / 2;
                double endAngle = startAngle + item.GocRad;

                double x1 = cx + r * Math.Cos(startAngle);
                double y1 = cy + r * Math.Sin(startAngle);
                double x2 = cx + r * Math.Cos(endAngle);
                double y2 = cy + r * Math.Sin(endAngle);
                bool isLarge = item.GocRad > Math.PI;

                var geo = new PathGeometry();
                var fig = new PathFigure { StartPoint = new Point(cx, cy), IsClosed = true };
                fig.Segments.Add(new LineSegment(new Point(x1, y1), true));
                fig.Segments.Add(new ArcSegment(
                    new Point(x2, y2), new Size(r, r), 0,
                    isLarge, SweepDirection.Clockwise, true));
                geo.Figures.Add(fig);

                Color color = (Color)ColorConverter.ConvertFromString(item.MauSac);
                var path = new Path
                {
                    Data = geo,
                    Fill = new SolidColorBrush(color),
                    Stroke = Brushes.White,
                    StrokeThickness = 1.5
                };
                CanvasPie.Children.Add(path);
            }
        }

        private void AddEmptyLabel(Canvas canvas, string text)
        {
            var lbl = new TextBlock
            {
                Text = text,
                FontSize = 11,
                Foreground = new SolidColorBrush(Color.FromRgb(148, 163, 184)),
                HorizontalAlignment = HorizontalAlignment.Center
            };
            Canvas.SetLeft(lbl, 20);
            Canvas.SetTop(lbl, 40);
            canvas.Children.Add(lbl);
        }
    }
}
