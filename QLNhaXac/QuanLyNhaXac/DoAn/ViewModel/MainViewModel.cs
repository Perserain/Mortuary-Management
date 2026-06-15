using DoAn.Views.Auth;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Input;
using System.Windows.Threading;

namespace DoAn.ViewModel
{
    public class MainViewModel : BaseViewModel
    {
        private BaseViewModel _currentView;
        public BaseViewModel CurrentView
        {
            get => _currentView;
            set
            {
                if (_currentView != value)
                {
                    _currentView = value; 
                    OnPropertyChanged(nameof(CurrentView));
                }
            }
        }

        public bool IsAdmin => DoAn.Core.DBConnect.IsAdmin;

        // --- LOGIC BADGE CẢNH BÁO ---
        private int _soCanhBao;
        public int SoCanhBao
        {
            get => _soCanhBao;
            set { _soCanhBao = value; OnPropertyChanged(); OnPropertyChanged(nameof(HasCanhBao)); }
        }

        public bool HasCanhBao => SoCanhBao > 0;

        private DispatcherTimer _badgeTimer;

        private void RefreshBadge()
        {
            if (string.IsNullOrEmpty(DoAn.Core.DBConnect.ConnectionString)) return;
            try
            {
                var dt = DoAn.Core.DBConnect.GetData("SELECT COUNT(*) AS SoCB FROM CANH_BAO WHERE DAOC = 0");
                if (dt.Rows.Count > 0)
                    SoCanhBao = Convert.ToInt32(dt.Rows[0]["SoCB"]);
            }
            catch { SoCanhBao = 0; }
        }
        public ICommand ShowBacSiCommand { get; set; }
        public ICommand ShowHoSoCommand { get; set; }
        public ICommand ShowThiHaiCommand { get; set; }
        public ICommand ShowDichVuCommand { get; set; }
        public ICommand ShowNganKeoCommand { get; set; }
        public ICommand ShowSuDungCommand { get; set; }
        public ICommand LogOutCommand { get; set; }
        public ICommand ShowQuanLyTaiKhoanCommand { get; set; }
        public ICommand ShowQuanLyNhomQuyenCommand { get; set; }
        public ICommand ShowBackupRestoreCommand { get; set; }
        public ICommand ShowDashboardCommand { get; set; }
        public ICommand ShowThanNhanCommand { get; set; }
        public ICommand ShowHoaDonCommand { get; set; }
        public ICommand ShowCanhBaoCommand { get; set; }

        public MainViewModel()
        {
            CurrentView = new DashboardViewModel();

            ShowDashboardCommand = new RelayCommand(p => CurrentView = new DashboardViewModel());
            ShowBacSiCommand = new RelayCommand(p => CurrentView = new BacSiViewModel());
            ShowHoSoCommand = new RelayCommand(p => CurrentView = new HoSoKBViewModel());
            ShowThiHaiCommand = new RelayCommand(p => CurrentView = new ThiHaiViewModel());
            ShowThanNhanCommand = new RelayCommand(p => CurrentView = new ThanNhanViewModel());
            ShowDichVuCommand = new RelayCommand(p => CurrentView = new DichVuViewModel());
            ShowNganKeoCommand = new RelayCommand(p => CurrentView = new NganKeoViewModel());
            ShowSuDungCommand = new RelayCommand(p => CurrentView = new SuDungViewModel());
            ShowBackupRestoreCommand = new RelayCommand(p => CurrentView = new BackupRestoreViewModel());
            ShowQuanLyTaiKhoanCommand = new RelayCommand(p => CurrentView = new QuanLyTaiKhoanViewModel());
            ShowQuanLyNhomQuyenCommand = new RelayCommand(p => CurrentView = new QuanLyNhomQuyenViewModel());
            ShowHoaDonCommand = new RelayCommand(p => CurrentView = new HoaDonViewModel());
            ShowCanhBaoCommand = new RelayCommand(p => CurrentView = new CanhBaoViewModel());

            // Khởi tạo lệnh Đăng Xuất
            LogOutCommand = new RelayCommand(p => ExecuteLogOut(p));

            // Khởi động bộ đếm badge cảnh báo
            RefreshBadge();
            _badgeTimer = new DispatcherTimer { Interval = TimeSpan.FromMinutes(3) };
            _badgeTimer.Tick += (s, e) => RefreshBadge();
            _badgeTimer.Start();
        }

        private void ExecuteLogOut(object parameter)
        {
            var window = parameter as Window;
            if (window == null) return;

            LoginWindow login = new LoginWindow();
            login.Show();
            window.Close(); // Đóng MainWindow từ ViewModel
        }
    }
}
