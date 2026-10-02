using DoAn.ViewModel;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DoAn.Model
{
    public class LichSuBackupModel: BaseViewModel
    {
        private DateTime _ThoiGianBackup;

        public DateTime ThoiGianBackup
        {
            get { return _ThoiGianBackup; }
            set { _ThoiGianBackup = value; OnPropertyChanged(nameof(ThoiGianBackup)); }
        }

        private string _LoaiBackup;

        public string LoaiBackup
        {
            get { return _LoaiBackup; }
            set { _LoaiBackup = value; OnPropertyChanged(nameof(LoaiBackup)); }// FULL / DIFFERENTIAL / TRANSACTION LOG
        }

        private string _DuongDanFile;

        public string DuongDanFile
        {
            get { return _DuongDanFile; }
            set { _DuongDanFile = value; OnPropertyChanged(nameof(DuongDanFile)); }
        }

        private decimal _KichThuoc_MB;

        public decimal KichThuoc_MB
        {
            get { return _KichThuoc_MB; }
            set { _KichThuoc_MB = value; OnPropertyChanged(nameof(KichThuoc_MB)); }
        }

        private string _NguoiThucHien;

        public string NguoiThucHien
        {
            get { return _NguoiThucHien; }
            set { _NguoiThucHien = value; OnPropertyChanged(nameof(NguoiThucHien)); }
        }

        private string _CoChecksum;

        public string CoChecksum
        {
            get { return _CoChecksum; }
            set { _CoChecksum = value; OnPropertyChanged(nameof(CoChecksum)); }
        }

    }
}
