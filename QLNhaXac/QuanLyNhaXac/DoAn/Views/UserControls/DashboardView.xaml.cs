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

        // ── Biểu đồ cột: Thi hài theo tháng ───────────────────────────────
        private void DrawThiHaiChart(DashboardViewModel vm)
        {
            CanvasThiHai.Children.Clear();
            var data = vm.ThiHaiTheoThang;
            if (data == null || data.Count == 0)
            {
                AddEmptyLabel(CanvasThiHai, "Chưa có dữ liệu");
                return;
            }

            CanvasThiHai.UpdateLayout();
            double canvasW = Math.Max(CanvasThiHai.ActualWidth, 300);
            double canvasH = Math.Max(CanvasThiHai.ActualHeight, 120);
            double barMaxH = canvasH - 30;
            double barW = Math.Max((canvasW - 20) / data.Count - 4, 8);
            double startX = 10;
            var barColor = new SolidColorBrush(Color.FromRgb(16, 185, 129)); // #10B981

            for (int i = 0; i < data.Count; i++)
            {
                var item = data[i];
                double barH = Math.Max(item.ChieuCaoChuanHoa * barMaxH, 2);
                double x = startX + i * (barW + 4);
                double y = canvasH - barH - 20;

                var rect = new Rectangle
                {
                    Width = barW,
                    Height = barH,
                    Fill = barColor,
                    RadiusX = 3,
                    RadiusY = 3
                };
                Canvas.SetLeft(rect, x);
                Canvas.SetTop(rect, y);
                CanvasThiHai.Children.Add(rect);

                // Số lượng trên cột
                if (item.SoLuong > 0)
                {
                    var lblVal = new TextBlock
                    {
                        Text = item.SoLuong.ToString(),
                        FontSize = 9,
                        Foreground = new SolidColorBrush(Color.FromRgb(30, 41, 59)),
                        FontWeight = FontWeights.SemiBold
                    };
                    Canvas.SetLeft(lblVal, x + barW / 2 - 6);
                    Canvas.SetTop(lblVal, y - 14);
                    CanvasThiHai.Children.Add(lblVal);
                }

                // Label tháng
                var lbl = new TextBlock
                {
                    Text = item.Thang,
                    FontSize = 9,
                    Foreground = new SolidColorBrush(Color.FromRgb(100, 116, 139)),
                    Width = barW + 4,
                    TextAlignment = TextAlignment.Center
                };
                Canvas.SetLeft(lbl, x - 2);
                Canvas.SetTop(lbl, canvasH - 18);
                CanvasThiHai.Children.Add(lbl);
            }
        }

        // ── Biểu đồ cột: Doanh thu theo tháng ─────────────────────────────
        private void DrawDoanhThuChart(DashboardViewModel vm)
        {
            CanvasDoanhThu.Children.Clear();
            var data = vm.DoanhThuTheoThang;
            if (data == null || data.Count == 0)
            {
                AddEmptyLabel(CanvasDoanhThu, "Chưa có dữ liệu");
                return;
            }

            CanvasDoanhThu.UpdateLayout();
            double canvasW = Math.Max(CanvasDoanhThu.ActualWidth, 300);
            double canvasH = Math.Max(CanvasDoanhThu.ActualHeight, 120);
            double barMaxH = canvasH - 30;
            double barW = Math.Max((canvasW - 20) / data.Count - 4, 8);
            double startX = 10;
            var barColor = new SolidColorBrush(Color.FromRgb(59, 130, 246)); // #3B82F6

            for (int i = 0; i < data.Count; i++)
            {
                var item = data[i];
                double barH = Math.Max(item.ChieuCaoChuanHoa * barMaxH, 2);
                double x = startX + i * (barW + 4);
                double y = canvasH - barH - 20;

                var rect = new Rectangle
                {
                    Width = barW,
                    Height = barH,
                    Fill = barColor,
                    RadiusX = 3,
                    RadiusY = 3
                };
                Canvas.SetLeft(rect, x);
                Canvas.SetTop(rect, y);
                CanvasDoanhThu.Children.Add(rect);

                // Số tiền rút gọn (triệu)
                if (item.DoanhThu > 0)
                {
                    string valLabel = item.DoanhThu >= 1_000_000
                        ? (item.DoanhThu / 1_000_000m).ToString("0.#") + "M"
                        : item.DoanhThu.ToString("N0");
                    var lblVal = new TextBlock
                    {
                        Text = valLabel,
                        FontSize = 8,
                        Foreground = new SolidColorBrush(Color.FromRgb(30, 41, 59)),
                        FontWeight = FontWeights.SemiBold
                    };
                    Canvas.SetLeft(lblVal, x + barW / 2 - 10);
                    Canvas.SetTop(lblVal, y - 14);
                    CanvasDoanhThu.Children.Add(lblVal);
                }

                var lbl = new TextBlock
                {
                    Text = item.Thang,
                    FontSize = 9,
                    Foreground = new SolidColorBrush(Color.FromRgb(100, 116, 139)),
                    Width = barW + 4,
                    TextAlignment = TextAlignment.Center
                };
                Canvas.SetLeft(lbl, x - 2);
                Canvas.SetTop(lbl, canvasH - 18);
                CanvasDoanhThu.Children.Add(lbl);
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
