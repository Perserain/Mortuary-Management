using DoAn.ViewModel;
using DoAn.Views.Auth;
using System.Windows;
using System.Windows.Input;

namespace DoAn.ViewModel.Staff
{
    public class StaffMainViewModel : BaseViewModel
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
        public ICommand ShowBacSiCommand { get; }
        public ICommand ShowHoSoCommand { get; }
        public ICommand ShowDichVuCommand { get; }
        public ICommand ShowNganKeoCommand { get; }
        public ICommand ShowSuDungCommand { get; }
        public ICommand LogOutCommand { get; }

        public StaffMainViewModel()
        {
            CurrentView = new ThiHaiViewModel();
            ShowThiHaiCommand = new RelayCommand(p => CurrentView = new ThiHaiViewModel());
            ShowBacSiCommand = new RelayCommand(p => CurrentView = new BacSiViewModel());
            ShowHoSoCommand = new RelayCommand(p => CurrentView = new HoSoKBViewModel());
            ShowDichVuCommand = new RelayCommand(p => CurrentView = new DichVuViewModel());
            ShowNganKeoCommand = new RelayCommand(p => CurrentView = new NganKeoViewModel());
            ShowSuDungCommand = new RelayCommand(p => CurrentView = new SuDungViewModel());
            LogOutCommand = new RelayCommand(p => ExecuteLogOut(p));
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
