using DoAn.ViewModel;
using DoAn.Views.Auth;
using System.Windows;
using System.Windows.Input;

namespace DoAn.ViewModel.Doctor
{
    public class DoctorMainViewModel : BaseViewModel
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

        public ICommand ShowThiHaiCommand { get; }
        public ICommand ShowCanhBaoCommand { get; }
        public ICommand ShowHoSoCommand { get; }
        public ICommand LogOutCommand { get; }

        public DoctorMainViewModel()
        {
            // Mặc định mở Hồ Sơ Khám Nghiệm
            CurrentView = new HoSoKBViewModel();

            // Bác sĩ: Select ThiHai, Select CanhBao, Add+Update HoSoKhamNghiem
            ShowThiHaiCommand  = new RelayCommand(p => CurrentView = new ThiHaiViewModel());
            ShowCanhBaoCommand = new RelayCommand(p => CurrentView = new CanhBaoViewModel());
            ShowHoSoCommand    = new RelayCommand(p => CurrentView = new HoSoKBViewModel());
            LogOutCommand      = new RelayCommand(p => ExecuteLogOut(p));
        }

        private void ExecuteLogOut(object parameter)
        {
            var window = parameter as Window;
            if (window == null) return;

            LoginWindow login = new LoginWindow();
            login.Show();
            window.Close();
        }
    }
}
