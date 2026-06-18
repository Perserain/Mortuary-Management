using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using DoAn.ViewModel;
namespace DoAn.Model
{
    public class ThiHaiModel : BaseViewModel
    {
        private string _maTH;
        private string _hoTen_TH;
        private DateTime? _ngaySinh;
        private DateTime? _ngayMat;
        private string _gioiTinh;
        private string _nhomTuoi;
        // ── S3-02: Trường pháp y bổ sung ──
        private string _noiTimThay;
        private string _coCuaNhan;

        public string MaTH
        {
            get => _maTH;
            set
            {
                _maTH = value;
                OnPropertyChanged();
            }
        }
        public string HoTenTH 
        { 
            get => _hoTen_TH;
            set
            {
                _hoTen_TH = value;
                OnPropertyChanged();
            }
        }
        public DateTime? NgaySinh
        {
            get => _ngaySinh;
            set
            {
                _ngaySinh = value;
                OnPropertyChanged();
            }
        }
        public DateTime? NgayMat
        {
            get => _ngayMat;
            set
            {
                _ngayMat = value;
                OnPropertyChanged();
            }
        }
        public string GioiTinh
        {
            get => _gioiTinh;
            set
            {
                _gioiTinh = value;
                OnPropertyChanged();
            }
        }

        public string NhomTuoi
        {
            get => _nhomTuoi;
            set
            {
                _nhomTuoi = value;
                OnPropertyChanged();
            }
        }

        // ── S3-02: Trường pháp y ──
        public string NoiTimThay
        {
            get => _noiTimThay;
            set { _noiTimThay = value; OnPropertyChanged(); }
        }

        public string CoCuaNhan
        {
            get => _coCuaNhan;
            set { _coCuaNhan = value; OnPropertyChanged(); }
        }
    }
}
