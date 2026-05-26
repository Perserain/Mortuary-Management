using System;
using System.Collections.ObjectModel;
using System.Data;
using Microsoft.Data.SqlClient;
using System.IO;
using System.Text;
using System.Windows;
using System.Windows.Input;
using DoAn.Model;
using DoAn.Views.Shared;
using DoAn.Core;

namespace DoAn.ViewModel
{
    public class NganKeoViewModel : BaseViewModel
    {
        public ObservableCollection<NganKeoModel> DanhSachNganKeo { get; set; }

        private NganKeoModel _newNganKeo;
        public NganKeoModel NewNganKeo
        {
            get => _newNganKeo;
            set { _newNganKeo = value; OnPropertyChanged(); }
        }

        private NganKeoModel _selectedNganKeo;
        public NganKeoModel SelectedNganKeo
        {
            get => _selectedNganKeo;
            set
            {
                _selectedNganKeo = value;
                OnPropertyChanged();

                if (_selectedNganKeo != null)
                {
                    NewNganKeo = new NganKeoModel
                    {
                        MaNgan = _selectedNganKeo.MaNgan,
                        ViTri = _selectedNganKeo.ViTri,
                        NhietDo = _selectedNganKeo.NhietDo,
                        MaTH = _selectedNganKeo.MaTH
                    };
                }
                else
                {
                    ResetForm();
                }
            }
        }

        public ICommand LoadCommand { get; set; }
        public ICommand ThemCommand { get; set; }
        public ICommand SuaCommand { get; set; }
        public ICommand XoaCommand { get; set; }
        public ICommand XuatExcelCommand { get; set; }
        public ICommand NhapTuFileCommand { get; set; }
        public ICommand XemChiTietCommand { get; set; }

        public NganKeoViewModel()
        {
            DanhSachNganKeo = new ObservableCollection<NganKeoModel>();

            LoadCommand = new RelayCommand(p => LoadData());
            ThemCommand = new RelayCommand(p => ThemNgan(), p => NewNganKeo != null && !string.IsNullOrWhiteSpace(NewNganKeo.MaNgan));
            SuaCommand = new RelayCommand(p => SuaNgan(), p => NewNganKeo != null && !string.IsNullOrWhiteSpace(NewNganKeo.MaNgan));
            XoaCommand = new RelayCommand(p => XoaNgan(), p => NewNganKeo != null && !string.IsNullOrWhiteSpace(NewNganKeo.MaNgan));
            XuatExcelCommand = new RelayCommand(p => XuatExcel());
            NhapTuFileCommand = new RelayCommand(p => NhapTuFile());
            XemChiTietCommand = new RelayCommand(p => XemChiTiet(), p => NewNganKeo != null && !string.IsNullOrEmpty(NewNganKeo.MaNgan));

            LoadData();
            ResetForm();
        }

        private void LoadData()
        {
            if (string.IsNullOrEmpty(DBConnect.ConnectionString)) return;
            DanhSachNganKeo.Clear();
            string sql = @"EXEC SP_DSNganKeo";
            DataTable dt = DBConnect.GetData(sql);

            foreach (DataRow row in dt.Rows)
            {
                DanhSachNganKeo.Add(new NganKeoModel
                {
                    MaNgan = row["MANGAN"].ToString(),
                    ViTri = row["VITRI"].ToString(),
                    NhietDo = row["NHIETDO"] != DBNull.Value ? Convert.ToDouble(row["NHIETDO"]) : 0,
                    MaTH = row["MATH"].ToString()
                });
            }
        }

        private void XemChiTiet()
        {
            DetailWindow f = new DetailWindow(NewNganKeo, "CHI TIẾT NGĂN KÉO");
            f.ShowDialog();
        }

        private string TaoMaNgan()
        {
            if (DanhSachNganKeo == null || DanhSachNganKeo.Count == 0) return "NK001";

            var maxId = DanhSachNganKeo
                .Select(n => {
                    if (n.MaNgan != null && n.MaNgan.StartsWith("NK") && int.TryParse(n.MaNgan.Substring(2), out int num))
                        return num;
                    return 0;
                })
                .DefaultIfEmpty(0)
                .Max();

            return $"NK{(maxId + 1):D3}";
        }
        private void ResetForm()
        {
            NewNganKeo = new NganKeoModel();
            NewNganKeo.MaNgan = TaoMaNgan();
        }

        private void ThemNgan()
        {
            if (!DBConnect.RequireAdmin("Thêm ngăn kéo")) return;
            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    string sql = "EXEC SP_ThemNganKeo @ma, @vt, @nd, @math";
                    var cmd = new SqlCommand(sql, conn);

                    cmd.Parameters.AddWithValue("@ma", NewNganKeo.MaNgan);
                    cmd.Parameters.AddWithValue("@vt", NewNganKeo.ViTri ?? (object)DBNull.Value);
                    cmd.Parameters.AddWithValue("@nd", NewNganKeo.NhietDo);
                    cmd.Parameters.AddWithValue("@math", string.IsNullOrWhiteSpace(NewNganKeo.MaTH) ? DBNull.Value : (object)NewNganKeo.MaTH);

                    cmd.ExecuteNonQuery();
                    MessageBox.Show("Thêm ngăn kéo thành công!");
                    LoadData();
                    ResetForm();
                }
            }
            catch (SqlException ex)
            {
                if (ex.Number == 2627) MessageBox.Show("Trùng mã ngăn!");
                else if (ex.Number == 2601) MessageBox.Show("Mã thi hài này đã nằm ở ngăn khác rồi!");
                else if (ex.Number == 547) MessageBox.Show("Mã thi hài không tồn tại!");
                else MessageBox.Show("Lỗi SQL: " + ex.Message);
            }
        }

        private void SuaNgan()
        {
            if (!DBConnect.RequireAdmin("Sửa ngăn kéo")) return;
            try
            {
                using (var conn = new SqlConnection(DBConnect.ConnectionString))
                {
                    conn.Open();
                    string sqlUpdate = "EXEC SP_SuaNganKeo @ma, @vt, @nd, @math";
                    var cmdUpdate = new SqlCommand(sqlUpdate, conn);

                    cmdUpdate.Parameters.AddWithValue("@ma", NewNganKeo.MaNgan);
                    cmdUpdate.Parameters.AddWithValue("@vt", string.IsNullOrWhiteSpace(NewNganKeo.ViTri) ? DBNull.Value : (object)NewNganKeo.ViTri);
                    cmdUpdate.Parameters.AddWithValue("@nd", NewNganKeo.NhietDo);
                    cmdUpdate.Parameters.AddWithValue("@math", string.IsNullOrWhiteSpace(NewNganKeo.MaTH) ? DBNull.Value : (object)NewNganKeo.MaTH);

                    if (cmdUpdate.ExecuteNonQuery() > 0)
                    {
                        MessageBox.Show("Cập nhật ngăn kéo thành công!");
                        LoadData();
                        ResetForm();
                    }
                }
            }
            catch (SqlException ex)
            {
                if (ex.Number == 547) MessageBox.Show("Mã Thi Hài không tồn tại!");
                else MessageBox.Show("Lỗi SQL: " + ex.Message);
            }
        }

        private void XoaNgan()
        {
            if (!DBConnect.RequireAdmin("Xóa ngăn kéo")) return;
            if (MessageBox.Show("Xóa ngăn kéo này?", "Xác nhận", MessageBoxButton.YesNo) == MessageBoxResult.Yes)
            {
                try
                {
                    using (var conn = new SqlConnection(DBConnect.ConnectionString))
                    {
                        conn.Open();
                        var cmd = new SqlCommand("EXEC SP_XoaNganKeo @ma", conn);
                        cmd.Parameters.AddWithValue("@ma", NewNganKeo.MaNgan);
                        cmd.ExecuteNonQuery();

                        MessageBox.Show("Đã xóa ngăn kéo!");
                        LoadData();
                        ResetForm();
                    }
                }
                catch (Exception ex) { MessageBox.Show("Lỗi: " + ex.Message); }
            }
        }

        private void XuatExcel()
        {
            if (!DBConnect.RequireAdmin("Xuất dữ liệu ngăn kéo")) return;

            if (DanhSachNganKeo == null || DanhSachNganKeo.Count == 0) return;

            Microsoft.Win32.SaveFileDialog saveFileDialog = new Microsoft.Win32.SaveFileDialog();
            saveFileDialog.Filter = "CSV Documents (*.csv)|*.csv";
            saveFileDialog.FileName = "TrangThai_NganKeo.csv";

            if (saveFileDialog.ShowDialog() == true)
            {
                try
                {
                    using (StreamWriter sw = new StreamWriter(saveFileDialog.FileName, false, Encoding.UTF8))
                    {
                        sw.WriteLine("Mã Ngăn,Vị Trí,Nhiệt Độ,Mã Thi Hài,Tên Người Nằm");
                        foreach (var nk in DanhSachNganKeo)
                        {
                            string vt = nk.ViTri?.Contains(",") == true ? $"\"{nk.ViTri}\"" : nk.ViTri;
                            string ten = nk.HoTenTH?.Contains(",") == true ? $"\"{nk.HoTenTH}\"" : nk.HoTenTH;
                            sw.WriteLine($"{nk.MaNgan},{vt},{nk.NhietDo},{nk.MaTH},{ten}");
                        }
                    }
                    MessageBox.Show("Xuất file thành công!");
                }
                catch (Exception ex) { MessageBox.Show("Lỗi: " + ex.Message); }
            }
        }
        private DataTable ReadFileNganKeo(string path)
        {
            DataTable dt = new DataTable();
            dt.Columns.Add("MANGAN", typeof(string));
            dt.Columns.Add("VITRI", typeof(string));
            dt.Columns.Add("NHIETDO", typeof(double));
            dt.Columns.Add("MATH", typeof(string)); // Mã TH có thể để trống

            string[] lines = File.ReadAllLines(path, Encoding.UTF8);
            foreach (string line in lines)
            {
                if (!string.IsNullOrWhiteSpace(line))
                {
                    string[] parts = line.Split(',');
                    if (parts.Length >= 3)
                    {
                        string math = (parts.Length >= 4 && !string.IsNullOrWhiteSpace(parts[3])) ? parts[3].Trim() : null;
                        double nd = 0;
                        double.TryParse(parts[2].Trim(), out nd);

                        if (math == null) dt.Rows.Add(parts[0].Trim(), parts[1].Trim(), nd, DBNull.Value);
                        else dt.Rows.Add(parts[0].Trim(), parts[1].Trim(), nd, math);
                    }
                }
            }
            return dt;
        }

        private void NhapTuFile()
        {
            if (!DBConnect.RequireAdmin("Nhập dữ liệu ngăn kéo")) return;

            Microsoft.Win32.OpenFileDialog dlg = new Microsoft.Win32.OpenFileDialog();
            dlg.Filter = "Text files (*.txt)|*.txt|CSV files (*.csv)|*.csv|All files (*.*)|*.*";
            dlg.Title = "Chọn file dữ liệu Ngăn Kéo";

            if (dlg.ShowDialog() == true)
            {
                try
                {
                    DataTable bangDuLieu = ReadFileNganKeo(dlg.FileName);
                    if (bangDuLieu.Rows.Count == 0) { MessageBox.Show("File rỗng hoặc sai định dạng!"); return; }

                    using (SqlConnection conn = new SqlConnection(DBConnect.ConnectionString))
                    {
                        conn.Open();
                        using (SqlBulkCopy bulkCopy = new SqlBulkCopy(conn))
                        {
                            bulkCopy.DestinationTableName = "NGANKEO";
                            // Map đúng tên cột để không bị lỗi nếu thứ tự trong CSDL khác
                            bulkCopy.ColumnMappings.Add("MANGAN", "MANGAN");
                            bulkCopy.ColumnMappings.Add("VITRI", "VITRI");
                            bulkCopy.ColumnMappings.Add("NHIETDO", "NHIETDO");
                            bulkCopy.ColumnMappings.Add("MATH", "MATH");

                            bulkCopy.WriteToServer(bangDuLieu);
                            MessageBox.Show($"Đã nhập thành công {bangDuLieu.Rows.Count} dòng!", "Thành công");
                            LoadData();
                        }
                    }
                }
                catch (Exception ex) { MessageBox.Show("Lỗi nhập từ file: " + ex.Message); }
            }
        }
    }
}

