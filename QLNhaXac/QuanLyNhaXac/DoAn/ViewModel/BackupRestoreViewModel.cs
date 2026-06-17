using DoAn.Core;
using Microsoft.Data.SqlClient;
using Microsoft.Win32;
using System;
using System.Collections.ObjectModel;
using System.Data;
using System.IO;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Input;

namespace DoAn.ViewModel
{
    // ═══════════════════════════════════════════════════════════════════
    // Model cho 1 dòng lịch sử backup
    // ═══════════════════════════════════════════════════════════════════
    public class LichSuBackupModel
    {
        public DateTime ThoiGianBackup { get; set; }
        public string LoaiBackup { get; set; }   // FULL / DIFFERENTIAL / TRANSACTION LOG
        public string DuongDanFile { get; set; }
        public decimal KichThuoc_MB { get; set; }
        public string NguoiThucHien { get; set; }
        public string CoChecksum { get; set; }
    }

    // ═══════════════════════════════════════════════════════════════════
    // ViewModel chính
    // ═══════════════════════════════════════════════════════════════════
    public class BackupRestoreViewModel : BaseViewModel
    {
        // ── Thư mục backup mặc định ─────────────────────────────────
        private string _backupFolder = @"D:\QuanLyNhaXac_Backup";
        public string BackupFolder
        {
            get => _backupFolder;
            set { _backupFolder = value; OnPropertyChanged(); }
        }

        // ── File restore được chọn ──────────────────────────────────
        private string _restoreFile = string.Empty;
        public string RestoreFile
        {
            get => _restoreFile;
            set { _restoreFile = value; OnPropertyChanged(); }
        }

        // ── Tùy chọn WITH RECOVERY khi restore ─────────────────────
        private bool _withRecovery = true;
        public bool WithRecovery
        {
            get => _withRecovery;
            set { _withRecovery = value; OnPropertyChanged(); }
        }

        // ── Trạng thái đang xử lý (disable UI) ─────────────────────
        private bool _isBusy = false;
        public bool IsBusy
        {
            get => _isBusy;
            set
            {
                _isBusy = value;
                OnPropertyChanged();
                OnPropertyChanged(nameof(IsNotBusy));
            }
        }
        public bool IsNotBusy => !_isBusy;

        // ── Text hiển thị trong loading overlay ─────────────────────
        private string _busyText = "Đang xử lý...";
        public string BusyText
        {
            get => _busyText;
            set { _busyText = value; OnPropertyChanged(); }
        }

        // ── Thông báo kết quả ────────────────────────────────────────
        private string _thongBaoText = string.Empty;
        public string ThongBaoText
        {
            get => _thongBaoText;
            set { _thongBaoText = value; OnPropertyChanged(); }
        }

        private bool _isThanhCong = true;
        public bool IsThanhCong
        {
            get => _isThanhCong;
            set { _isThanhCong = value; OnPropertyChanged(); }
        }

        private Visibility _thongBaoVisible = Visibility.Collapsed;
        public Visibility ThongBaoVisible
        {
            get => _thongBaoVisible;
            set { _thongBaoVisible = value; OnPropertyChanged(); }
        }

        // ── Lịch sử backup ──────────────────────────────────────────
        public ObservableCollection<LichSuBackupModel> DanhSachLichSu { get; set; } = new();

        private LichSuBackupModel _selectedLichSu;
        public LichSuBackupModel SelectedLichSu
        {
            get => _selectedLichSu;
            set { _selectedLichSu = value; OnPropertyChanged(); }
        }

        // ── Commands ─────────────────────────────────────────────────
        public ICommand FullBackupCommand { get; }
        public ICommand DiffBackupCommand { get; }
        public ICommand LogBackupCommand { get; }
        public ICommand RestoreCommand { get; }
        public ICommand ChonThuMucCommand { get; }
        public ICommand ChonFileRestoreCommand { get; }
        public ICommand TaiLaiBangCommand { get; }


        // ════════════════════════════════════════════════════════════
        // Constructor
        // ════════════════════════════════════════════════════════════
        public BackupRestoreViewModel()
        {
            FullBackupCommand = new RelayCommand(_ => ExecuteAsync(RunFullBackup), _ => IsNotBusy);
            DiffBackupCommand = new RelayCommand(_ => ExecuteAsync(RunDiffBackup), _ => IsNotBusy);
            LogBackupCommand = new RelayCommand(_ => ExecuteAsync(RunLogBackup), _ => IsNotBusy);
            RestoreCommand = new RelayCommand(_ => ExecuteAsync(RunRestore), _ => IsNotBusy);
            ChonThuMucCommand = new RelayCommand(_ => ChonThuMuc());
            ChonFileRestoreCommand = new RelayCommand(_ => ChonFileRestore());
            TaiLaiBangCommand = new RelayCommand(_ => ExecuteAsync(LoadLichSu));

            // Tải lịch sử ngay khi mở
            ExecuteAsync(LoadLichSu);
        }


        // ════════════════════════════════════════════════════════════
        // Helper: Tự động tạo thư mục nếu chưa tồn tại
        // SQL Server không tự tạo thư mục -> phải tạo trước từ phía app
        // ════════════════════════════════════════════════════════════
        private bool EnsureFolder(string folderPath)
        {
            try
            {
                if (!System.IO.Directory.Exists(folderPath))
                    System.IO.Directory.CreateDirectory(folderPath);
                return true;
            }
            catch (Exception ex)
            {
                HienThongBao(false,
                    $"Khong the tao thu muc:\n{folderPath}\n\nLy do: {ex.Message}");
                return false;
            }
        }

        private static bool IsLocalSqlServer(string dataSource)
        {
            if (string.IsNullOrWhiteSpace(dataSource))
                return true;

            var normalized = dataSource.Trim();
            return normalized.Equals(".", StringComparison.OrdinalIgnoreCase)
                || normalized.Equals("(local)", StringComparison.OrdinalIgnoreCase)
                || normalized.Equals("localhost", StringComparison.OrdinalIgnoreCase)
                || normalized.StartsWith("(localdb)\\", StringComparison.OrdinalIgnoreCase)
                || normalized.StartsWith("127.0.0.1", StringComparison.OrdinalIgnoreCase);
        }

        private bool CanSqlServerAccessPath(string path)
        {
            if (string.IsNullOrWhiteSpace(path))
                return false;

            try
            {
                var builder = new SqlConnectionStringBuilder(DBConnect.ConnectionString);
                if (IsLocalSqlServer(builder.DataSource))
                    return true;
            }
            catch
            {
                return true;
            }

            return path.StartsWith(@"\\", StringComparison.OrdinalIgnoreCase);
        }

        private bool ValidateBackupFolderForSqlServer(string folderPath, string actionName)
        {
            if (CanSqlServerAccessPath(folderPath))
                return true;

            HienThongBao(false,
                $"{actionName} không thể dùng đường dẫn local khi SQL Server đang chạy trên máy khác.\n" +
                "Hãy dùng thư mục share/UNC mà SQL Server truy cập được, hoặc chạy SQL Server trên cùng máy với ứng dụng.");
            return false;
        }

        private bool ValidateRestoreFileForSqlServer(string filePath)
        {
            if (!File.Exists(filePath))
            {
                HienThongBao(false, $"Không tìm thấy file backup:\n{filePath}");
                return false;
            }

            var extension = Path.GetExtension(filePath);
            if (!extension.Equals(".bak", StringComparison.OrdinalIgnoreCase) &&
                !extension.Equals(".trn", StringComparison.OrdinalIgnoreCase))
            {
                HienThongBao(false, "Chỉ hỗ trợ file .bak hoặc .trn để Restore.");
                return false;
            }

            if (!CanSqlServerAccessPath(filePath))
            {
                HienThongBao(false,
                    "SQL Server đang chạy trên máy khác nên không thể đọc đường dẫn local này.\n" +
                    "Hãy dùng đường dẫn UNC/share mà máy SQL Server truy cập được, hoặc đặt file backup trên chính máy SQL Server.");
                return false;
            }

            return true;
        }

        private static string GetRestoreHint(string filePath)
        {
            var extension = Path.GetExtension(filePath);

            if (extension.Equals(".trn", StringComparison.OrdinalIgnoreCase))
            {
                return "Lưu ý: file .trn chỉ restore được sau khi đã restore FULL/DIFF với NORECOVERY và đang tiếp tục chuỗi log.";
            }

            if (filePath.IndexOf("_Diff_", StringComparison.OrdinalIgnoreCase) >= 0)
            {
                return "Lưu ý: file Differential .bak cần restore FULL gốc với NORECOVERY trước khi áp dụng.";
            }

            return string.Empty;
        }


        // ════════════════════════════════════════════════════════════
        // Kiểm tra quyền Admin phía client (double check, server cũng check)
        // ════════════════════════════════════════════════════════════
        private bool KiemTraAdmin()
        {
            if (!DBConnect.IsAdmin)
            {
                HienThongBao(false,
                    "⛔ Bạn không có quyền thực hiện thao tác này. Chỉ Admin mới có thể Backup / Restore.");
                return false;
            }
            return true;
        }


        // ════════════════════════════════════════════════════════════
        // Helper: chạy task async, wrap exception
        // ════════════════════════════════════════════════════════════
        private async void ExecuteAsync(Func<Task> action)
        {
            try
            {
                await action();
            }
            catch (SqlException ex)
            {
                // Bắt lỗi Windows chặn quyền ghi file của SQL Server
                if (ex.Message.Contains("Operating system error 5") || ex.Message.Contains("Access is denied") || ex.Message.Contains("terminating abnormally"))
                {
                    HienThongBao(false, "❌ Lỗi quyền ghi file: SQL Server bị Windows chặn không cho phép lưu file Backup vào thư mục này (đặc biệt là ổ C).\n\n👉 GIẢI PHÁP: Hãy chọn thư mục ở ổ đĩa khác (Ví dụ: Ổ D:\\).");
                }
                else
                {
                    HienThongBao(false, "Lỗi SQL Server: " + ex.Message);
                }
                IsBusy = false;
            }
            catch (Exception ex)
            {
                HienThongBao(false, "Lỗi hệ thống: " + ex.Message);
                IsBusy = false;
            }
        }


        // ════════════════════════════════════════════════════════════
        // FULL BACKUP
        // ════════════════════════════════════════════════════════════
        private async Task RunFullBackup()
        {
            if (!KiemTraAdmin()) return;
            ThongBaoVisible = Visibility.Collapsed;
            BusyText = "Đang thực hiện Full Backup...";
            IsBusy = true;

            try
            {
                var folder = BackupFolder.TrimEnd('\\') + @"\Full";
                if (!ValidateBackupFolderForSqlServer(folder, "Full Backup")) return;
                if (!EnsureFolder(folder)) return;
                var result = await Task.Run(() => CallStoredProc("SP_FullBackup",
                    new SqlParameter("@BackupFolder", folder)));

                PhanTichKetQua(result, "Full Backup");
                await LoadLichSu();
            }
            finally
            {
                IsBusy = false;
            }
        }


        // ════════════════════════════════════════════════════════════
        // DIFFERENTIAL BACKUP
        // ════════════════════════════════════════════════════════════
        private async Task RunDiffBackup()
        {
            if (!KiemTraAdmin()) return;
            ThongBaoVisible = Visibility.Collapsed;
            BusyText = "Đang thực hiện Differential Backup...";
            IsBusy = true;

            try
            {
                var folder = BackupFolder.TrimEnd('\\') + @"\Diff";
                if (!ValidateBackupFolderForSqlServer(folder, "Differential Backup")) return;
                if (!EnsureFolder(folder)) return;
                var result = await Task.Run(() => CallStoredProc("SP_DiffBackup",
                    new SqlParameter("@BackupFolder", folder)));

                PhanTichKetQua(result, "Differential Backup");
                await LoadLichSu();
            }
            finally
            {
                IsBusy = false;
            }
        }


        // ════════════════════════════════════════════════════════════
        // TRANSACTION LOG BACKUP
        // ════════════════════════════════════════════════════════════
        private async Task RunLogBackup()
        {
            if (!KiemTraAdmin()) return;
            ThongBaoVisible = Visibility.Collapsed;
            BusyText = "Đang thực hiện Transaction Log Backup...";
            IsBusy = true;

            try
            {
                var folder = BackupFolder.TrimEnd('\\') + @"\Log";
                if (!ValidateBackupFolderForSqlServer(folder, "Transaction Log Backup")) return;
                if (!EnsureFolder(folder)) return;
                var result = await Task.Run(() => CallStoredProc("SP_LogBackup",
                    new SqlParameter("@BackupFolder", folder)));

                PhanTichKetQua(result, "Transaction Log Backup");
                await LoadLichSu();
            }
            finally
            {
                IsBusy = false;
            }
        }


        // ════════════════════════════════════════════════════════════
        // RESTORE
        // ════════════════════════════════════════════════════════════
        private async Task RunRestore()
        {
            if (!KiemTraAdmin()) return;

            if (string.IsNullOrWhiteSpace(RestoreFile))
            {
                HienThongBao(false, "Vui lòng chọn file backup để Restore.");
                return;
            }

            if (!ValidateRestoreFileForSqlServer(RestoreFile))
                return;

            var restoreHint = GetRestoreHint(RestoreFile);

            // Xác nhận trước khi restore (thao tác nguy hiểm)
            var confirmMessage =
                $"⚠ CẢNH BÁO: Thao tác Restore sẽ GHI ĐÈ toàn bộ dữ liệu hiện tại!\n\n" +
                $"File: {RestoreFile}\n" +
                $"Tùy chọn: {(WithRecovery ? "WITH RECOVERY (hoàn thành)" : "WITH NORECOVERY (chờ apply thêm)")}";

            if (!string.IsNullOrWhiteSpace(restoreHint))
                confirmMessage += "\n\n" + restoreHint;

            confirmMessage += "\n\nBạn chắc chắn muốn tiếp tục?";

            var confirm = MessageBox.Show(
                confirmMessage,
                "Xác nhận Restore",
                MessageBoxButton.YesNo,
                MessageBoxImage.Warning);

            if (confirm != MessageBoxResult.Yes) return;

            ThongBaoVisible = Visibility.Collapsed;
            BusyText = "Đang thực hiện Restore... Vui lòng không tắt ứng dụng.";
            IsBusy = true;

            try
            {
                var result = await Task.Run(() => CallStoredProc("SP_RestoreDatabase", true,
                    new SqlParameter("@BackupFile", RestoreFile),
                    new SqlParameter("@WithRecovery", WithRecovery ? 1 : 0)));

                PhanTichKetQua(result, "Restore");

                if (WithRecovery)
                    await LoadLichSu();
            }
            finally
            {
                IsBusy = false;
            }
        }


        // ════════════════════════════════════════════════════════════
        // TẢI LỊCH SỬ BACKUP
        // ════════════════════════════════════════════════════════════
        private async Task LoadLichSu()
        {
            try
            {
                var dt = await Task.Run(() => CallStoredProc("SP_LichSuBackup",
                    new SqlParameter("@SoLuong", 30)));

                Application.Current.Dispatcher.Invoke(() =>
                {
                    DanhSachLichSu.Clear();
                    if (dt == null) return;

                    foreach (DataRow row in dt.Rows)
                    {
                        DanhSachLichSu.Add(new LichSuBackupModel
                        {
                            ThoiGianBackup = row["ThoiGianBackup"] as DateTime? ?? DateTime.MinValue,
                            LoaiBackup = row["LoaiBackup"]?.ToString() ?? "",
                            DuongDanFile = row["DuongDanFile"]?.ToString() ?? "",
                            KichThuoc_MB = row["KichThuoc_MB"] is DBNull ? 0
                                             : Convert.ToDecimal(row["KichThuoc_MB"]),
                            NguoiThucHien = row["NguoiThucHien"]?.ToString() ?? "",
                            CoChecksum = row["CoChecksum"]?.ToString() ?? ""
                        });
                    }
                });
            }
            catch
            {
                // Lịch sử chưa có hoặc chưa có quyền - bỏ qua lỗi khi load lần đầu
            }
        }


        // ════════════════════════════════════════════════════════════
        // Helper: gọi Stored Procedure, trả về DataTable
        // ════════════════════════════════════════════════════════════
        private DataTable CallStoredProc(string spName, params SqlParameter[] parameters)
        {
            // Chuyển tiếp công việc sang hàm số 2 và mặc định gán false
            return CallStoredProc(spName, false, parameters);
        }

        // 2. Hàm mở rộng: Dành riêng cho tác vụ cần đổi Database (như Restore)
        private DataTable CallStoredProc(string spName, bool useMasterDb, params SqlParameter[] parameters)
        {
            DataTable dt = new DataTable();

            // Xây dựng lại chuỗi kết nối dựa trên DBConnect gốc
            SqlConnectionStringBuilder builder = new SqlConnectionStringBuilder(DBConnect.ConnectionString);

            // Nếu yêu cầu dùng master, ta đổi InitialCatalog
            if (useMasterDb)
            {
                builder.InitialCatalog = "master";
            }

            using (var conn = new SqlConnection(builder.ConnectionString))
            {
                conn.Open();
                using (var cmd = new SqlCommand(spName, conn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandTimeout = 300; // 5 phút

                    if (parameters != null)
                    {
                        foreach (var p in parameters)
                            cmd.Parameters.Add(p);
                    }

                    using (var da = new SqlDataAdapter(cmd))
                        da.Fill(dt);
                }
            }
            return dt;
        }


        // ════════════════════════════════════════════════════════════
        // Helper: phân tích DataTable kết quả từ SP
        // ════════════════════════════════════════════════════════════
        private void PhanTichKetQua(DataTable dt, string tenThaoTac)
        {
            // Trong C#, nếu lệnh SQL chạy bị lỗi thì nó đã văng thẳng ra SqlException.
            // Do đó, nếu code chạy lọt được xuống tới dòng này => SQL đã thực thi thành công!

            if (dt == null || dt.Rows.Count == 0)
            {
                // SQL SP thực thi Backup/Restore xong nhưng không trả về bảng dữ liệu
                HienThongBao(true, $"✅ {tenThaoTac} hoàn tất thành công!");
                return;
            }

            var row = dt.Rows[0];

            // Tránh lỗi crash "Column doesn't belong to table" bằng cách kiểm tra cột trước khi đọc
            string trangThai = "Thành công";
            if (dt.Columns.Contains("TrangThai") && row["TrangThai"] != DBNull.Value)
            {
                trangThai = row["TrangThai"].ToString();
            }

            bool ok = trangThai.Contains("Thành công") || trangThai.ToLower().Contains("ok");

            // Lấy đường dẫn file nếu SP có trả về
            var filePath = dt.Columns.Contains("DuongDan") ? row["DuongDan"]?.ToString()
                         : dt.Columns.Contains("FileNguon") ? row["FileNguon"]?.ToString()
                         : dt.Columns.Contains("BackupFile") ? row["BackupFile"]?.ToString() : "";

            string msgFile = string.IsNullOrWhiteSpace(filePath) ? "" : $"\nFile: {filePath}";

            if (ok)
                HienThongBao(true, $"✅ {tenThaoTac} thành công!{msgFile}");
            else
                HienThongBao(false, $"❌ {tenThaoTac} có thể chưa hoàn thiện.\nChi tiết: {trangThai}");
        }


        // ════════════════════════════════════════════════════════════
        // Helper: hiển thị thông báo
        // ════════════════════════════════════════════════════════════
        private void HienThongBao(bool thanhCong, string msg)
        {
            Application.Current.Dispatcher.Invoke(() =>
            {
                IsThanhCong = thanhCong;
                ThongBaoText = msg;
                ThongBaoVisible = Visibility.Visible;
            });
        }


        // ════════════════════════════════════════════════════════════
        // Chọn thư mục backup (dùng WPF FolderBrowserDialog tương đương)
        // ════════════════════════════════════════════════════════════
        private void ChonThuMuc()
        {
            // WPF không có FolderBrowserDialog chuẩn, dùng hack qua OpenFileDialog
            var dlg = new OpenFileDialog
            {
                Title = "Chọn thư mục lưu Backup",
                Filter = "Thư mục|*.none",  // trick để chọn folder
                CheckFileExists = false,
                CheckPathExists = true,
                FileName = "Chọn thư mục này"
            };

            if (dlg.ShowDialog() == true)
            {
                BackupFolder = System.IO.Path.GetDirectoryName(dlg.FileName);
            }
        }


        // ════════════════════════════════════════════════════════════
        // Chọn file để Restore
        // ════════════════════════════════════════════════════════════
        private void ChonFileRestore()
        {
            var dlg = new OpenFileDialog
            {
                Title = "Chọn file Backup để Restore",
                Filter = "SQL Server Backup|*.bak;*.trn|Full/Diff Backup (*.bak)|*.bak|Log Backup (*.trn)|*.trn"
            };

            if (dlg.ShowDialog() == true)
                RestoreFile = dlg.FileName;
        }
    }
}