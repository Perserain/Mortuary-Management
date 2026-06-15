-- ============================================================
-- HỆ THỐNG QUẢN LÝ NHÀ XÁC — QuanLyNhaXac
-- FILE SQL DUY NHẤT (TỔNG HỢP TOÀN BỘ)
-- Thứ tự: DB → Bảng → Ràng buộc → Dữ liệu mẫu → View → SP
--         → Hàm → Trigger → Phân quyền → Backup
-- Chạy trên: SQL Server 2016+
-- SET DATEFORMAT DMY trước khi chạy
-- ============================================================

USE master
GO

-- ============================================================
-- 0. TẠO / TÁI TẠO DATABASE
-- ============================================================
IF EXISTS(SELECT 1 FROM sys.databases WHERE name = 'QuanLyNhaXac')
    DROP DATABASE QuanLyNhaXac
GO

CREATE DATABASE QuanLyNhaXac
--ON PRIMARY
--(
--    NAME        = 'QuanLyNhaXac_Main',
--    FILENAME    = 'C:\QuanLyNhaXac\QuanLyNhaXac_Main.mdf',
--    SIZE        = 10MB,
--    MAXSIZE     = 30MB,
--    FILEGROWTH  = 5MB
--),
--FILEGROUP SecondaryGroup
--(
--    NAME        = 'QuanLyNhaXac_Sub',
--    FILENAME    = 'C:\QuanLyNhaXac\QuanLyNhaXac_Sub.ndf',
--    SIZE        = 10MB,
--    MAXSIZE     = 30MB,
--    FILEGROWTH  = 5MB
--)
--LOG ON
--(
--    NAME        = 'QuanLyNhaXac_Log',
--    FILENAME    = 'C:\QuanLyNhaXac\QuanLyNhaXac_Log.ldf',
--    SIZE        = 5MB,
--    MAXSIZE     = 20MB,
--    FILEGROWTH  = 1MB
--)
GO

ALTER DATABASE QuanLyNhaXac SET RECOVERY FULL
GO

USE QuanLyNhaXac
GO

SET DATEFORMAT DMY
GO

-- ============================================================
-- 1. TẠO BẢNG
-- ============================================================

-- 1.1 THIHAI — Bảng trung tâm
CREATE TABLE THIHAI
(
    MATH        VARCHAR(15)     NOT NULL,
    HOTEN_TH    NVARCHAR(100),
    NGAYSINH    DATE,
    NGAYMAT     DATE,
    GIOITINH    NVARCHAR(10),
    TRANGTHAI   NVARCHAR(30)    NOT NULL
                CONSTRAINT DF_THIHAI_TRANGTHAI DEFAULT N'Đang bảo quản',
    NOITIMTHAY  NVARCHAR(200),                  -- Nơi phát hiện / hiện trường
    COCUANHAN   NVARCHAR(100),                  -- Cơ quan bàn giao
    NGAYNHAP    DATE            DEFAULT CAST(GETDATE() AS DATE),
    CONSTRAINT PK_TH           PRIMARY KEY (MATH),
    CONSTRAINT CK_THIHAI_NGAY  CHECK (NGAYMAT > NGAYSINH),
    -- CONSTRAINT CK_THIHAI_NGAYHT CHECK (NGAYSINH <= GETDATE()),
    CONSTRAINT CK_THIHAI_TRANGTHAI CHECK (TRANGTHAI IN (
        N'Đang bảo quản', N'Đang khám nghiệm',
        N'Chờ bàn giao',  N'Đã bàn giao', N'Đã mai táng'
    ))
)
GO

-- 1.2 BACSI
CREATE TABLE BACSI
(
    MABS            VARCHAR(15)     NOT NULL,
    HOTEN_BS        NVARCHAR(100),
    CHUYENKHOA      NVARCHAR(100),
    NAMKINHNGHIEM   INT,
    MA_TRUONGKHOA   VARCHAR(15),
    CONSTRAINT PK_BS            PRIMARY KEY (MABS),
    CONSTRAINT CK_BACSI_NAMKN  CHECK (NAMKINHNGHIEM > 1)
)
GO

ALTER TABLE BACSI
    ADD CONSTRAINT FK_BACSI_TRUONGKHOA
    FOREIGN KEY (MA_TRUONGKHOA) REFERENCES BACSI(MABS)
GO

-- 1.3 DICHVU
CREATE TABLE DICHVU
(
    MADV    VARCHAR(15)     NOT NULL,
    TENDV   NVARCHAR(100),
    GIATIEN MONEY,
    CONSTRAINT PK_DV            PRIMARY KEY (MADV),
    CONSTRAINT CK_DICHVU_GIATIEN CHECK (GIATIEN >= 0)
)
GO

-- 1.4 NGANKEO (1-1 với THIHAI)
CREATE TABLE NGANKEO
(
    MANGAN          VARCHAR(15)     NOT NULL,
    VITRI           NVARCHAR(50),
    NHIETDO         FLOAT,
    NHIETDO_CANH_BAO FLOAT          DEFAULT -2.0,   -- Ngưỡng cảnh báo linh hoạt
    NGAY_BAO_TRI    DATE,                           -- Ngày bảo trì gần nhất
    MATH            VARCHAR(15),
    CONSTRAINT PK_NK                PRIMARY KEY (MANGAN),
    -- CONSTRAINT DF_NGANKEO_NHIETDO   DEFAULT 4.0  FOR NHIETDO,
    CONSTRAINT CK_NGANKEO_NHIETDO   CHECK (NHIETDO < 10),
    CONSTRAINT UQ_NGANKEO_MATH      UNIQUE (MATH)
)
GO

ALTER TABLE NGANKEO
    ADD CONSTRAINT FK_NGANKEO_THIHAI
    FOREIGN KEY (MATH) REFERENCES THIHAI(MATH)
GO

-- 1.5 HOSOKHAMBENH
CREATE TABLE HOSOKHAMBENH
(
    MAHS            VARCHAR(15)     NOT NULL,
    THOIGIANKHAM    DATE,
    KETLUAN         NVARCHAR(50),
    MATH            VARCHAR(15),
    MABS            VARCHAR(15),
    -- Mở rộng pháp y
    MACAUTU         NVARCHAR(10),                   -- Mã ICD-10
    LOAICAUTU       NVARCHAR(50),
    SOBIENBAN       NVARCHAR(30),
    NGAYBIENBAN     DATE,
    COQUANYEUCAU    NVARCHAR(150),
    GHICHUPHAY      NVARCHAR(500),
    CONSTRAINT PK_HS            PRIMARY KEY (MAHS),
    -- CONSTRAINT DF_HS_KETLUAN    DEFAULT N'Đang điều tra' FOR KETLUAN,
    -- CONSTRAINT CK_HS_NGAY       CHECK (THOIGIANKHAM <= GETDATE()),
    CONSTRAINT CK_HS_LOAICAUTU  CHECK (LOAICAUTU IN (
        N'Tai nạn giao thông', N'Tai nạn lao động',
        N'Bệnh lý', N'Tự tử', N'Án mạng', N'Chưa rõ', N'Khác'
    ) OR LOAICAUTU IS NULL)
)
GO

ALTER TABLE HOSOKHAMBENH
    ADD CONSTRAINT FK_HOSOKHAMBENH_THIHAI FOREIGN KEY (MATH) REFERENCES THIHAI(MATH),
        CONSTRAINT FK_HOSOKHAMBENH_BACSI  FOREIGN KEY (MABS) REFERENCES BACSI(MABS)
GO

-- 1.6 SUDUNG (n-n: THIHAI × DICHVU)
CREATE TABLE SUDUNG
(
    MATH        VARCHAR(15)     NOT NULL,
    MADV        VARCHAR(15)     NOT NULL,
    NGAYSUDUNG  DATE,
    GHICHU      NVARCHAR(200),
    PRIMARY KEY (MATH, MADV),
    -- CONSTRAINT CK_SUDUNG_NGAY CHECK (NGAYSUDUNG <= GETDATE())
)
GO

ALTER TABLE SUDUNG
    ADD CONSTRAINT FK_SUDUNG_DICHVU FOREIGN KEY (MADV) REFERENCES DICHVU(MADV),
        CONSTRAINT FK_SUDUNG_THIHAI FOREIGN KEY (MATH) REFERENCES THIHAI(MATH)
GO

-- 1.7 NHANVIEN
CREATE TABLE NHANVIEN
(
    MANV        VARCHAR(15)     NOT NULL,
    HOTEN_NV    NVARCHAR(100),
    CHUCVU      NVARCHAR(100),
    DIENTHOAI   VARCHAR(15),
    CONSTRAINT PK_NV PRIMARY KEY (MANV)
)
GO

-- 1.8 THAN_NHAN
CREATE TABLE THAN_NHAN
(
    MATN        VARCHAR(15)     NOT NULL,
    MATH        VARCHAR(15)     NOT NULL,
    HOTEN_TN    NVARCHAR(100)   NOT NULL,
    QUANHE      NVARCHAR(50),
    DIENTHOAI   VARCHAR(15),
    DIACHI      NVARCHAR(200),
    LALIENDHE   BIT             NOT NULL
                CONSTRAINT DF_TN_LALIENDHE DEFAULT 0,
    GHICHU      NVARCHAR(200),
    CONSTRAINT PK_TN    PRIMARY KEY (MATN),
    CONSTRAINT FK_TN_TH FOREIGN KEY (MATH) REFERENCES THIHAI(MATH)
)
GO

-- 1.9 HOADON
CREATE TABLE HOADON
(
    MAHD            VARCHAR(15)     NOT NULL,
    MATH            VARCHAR(15)     NOT NULL,
    NGAYLAP         DATE            NOT NULL,
    TONGTIEN        MONEY           NOT NULL,
    TRANGTHAITT     NVARCHAR(20)    NOT NULL
                    CONSTRAINT DF_HD_TRANGTHAITT DEFAULT N'Chưa thanh toán',
    PHUONGTHUCTT    NVARCHAR(30),
    NGAYTHANHTOAN   DATE,
    NGUOILAP        NVARCHAR(100),
    GHICHU          NVARCHAR(200),
    CONSTRAINT PK_HD        PRIMARY KEY (MAHD),
    CONSTRAINT FK_HD_TH     FOREIGN KEY (MATH) REFERENCES THIHAI(MATH),
    CONSTRAINT CK_HD_TT     CHECK (TRANGTHAITT IN (
        N'Chưa thanh toán', N'Đã thanh toán', N'Miễn phí', N'Nợ'
    )),
    CONSTRAINT CK_HD_PT     CHECK (PHUONGTHUCTT IN (
        N'Tiền mặt', N'Chuyển khoản', N'Thẻ ngân hàng', N'Khác'
    ) OR PHUONGTHUCTT IS NULL),
    CONSTRAINT CK_HD_TIEN   CHECK (TONGTIEN >= 0)
)
GO

-- 1.10 AUDIT_LOG
CREATE TABLE AUDIT_LOG
(
    MALOG       BIGINT          NOT NULL IDENTITY(1,1),
    THOIGIAN    DATETIME        NOT NULL DEFAULT GETDATE(),
    TENUSER     NVARCHAR(128)   NOT NULL DEFAULT SUSER_SNAME(),
    TENTABLE    NVARCHAR(50)    NOT NULL,
    HANHDOG     NVARCHAR(10)    NOT NULL,   -- Tên cột: HANHDOG (sửa typo CapNhatDoAn)
    MABANGHI    NVARCHAR(50),
    NOIDUNG     NVARCHAR(1000),
    CONSTRAINT PK_AUDIT     PRIMARY KEY (MALOG),
    CONSTRAINT CK_AUDIT_HD  CHECK (HANHDOG IN ('INSERT','UPDATE','DELETE') OR HANHDOG IS NULL)
)
GO

CREATE INDEX IX_AUDIT_THOIGIAN ON AUDIT_LOG(THOIGIAN DESC)
CREATE INDEX IX_AUDIT_TABLE    ON AUDIT_LOG(TENTABLE, THOIGIAN DESC)
GO

-- 1.11 CANH_BAO
CREATE TABLE CANH_BAO
(
    MACB        INT             NOT NULL IDENTITY(1,1),
    THOIGIAN    DATETIME        NOT NULL DEFAULT GETDATE(),
    LOAICB      NVARCHAR(50)    NOT NULL,
    MATH        VARCHAR(15),
    MANGAN      VARCHAR(15),
    NOIDUNG     NVARCHAR(300)   NOT NULL,
    DAOC        BIT             NOT NULL DEFAULT 0,
    CONSTRAINT PK_CB PRIMARY KEY (MACB)
)
GO

-- ============================================================
-- 2. DỮ LIỆU MẪU
-- ============================================================

INSERT INTO THIHAI(MATH, HOTEN_TH, NGAYSINH, NGAYMAT, GIOITINH) VALUES
('TH001', N'Nguyễn Văn A',    '01-01-1980', '20-01-2026', N'Nam'),
('TH002', N'Trần Thị B',      '15-05-1995', '21-01-2026', N'Nữ'),
('TH003', N'Lê Văn C',        '12-12-1960', '22-01-2026', N'Nam'),
('TH004', N'Nguyễn Văn Khải', '02-02-2000', '02-12-2021', N'Nam'),
('TH005', N'Nguyễn Khả Ái',   '03-05-2010', '12-01-2025', N'Nữ'),
('TH006', N'Cao Tử Khai',     '09-03-1969', '04-04-2024', N'Nam'),
('TH007', N'Nguyễn Hoài Anh', '09-03-1969', '04-04-2026', N'Nam')
GO

INSERT INTO BACSI(MABS, HOTEN_BS, CHUYENKHOA, NAMKINHNGHIEM, MA_TRUONGKHOA) VALUES
('BS001', N'Phạm Nhật Vượng',    N'Pháp y',           10, NULL),
('BS002', N'Đặng Lê Nguyên Vũ', N'Đa khoa',           15, NULL),
('BS003', N'Phạm Minh Đức',      N'Pháp y',           10, NULL),
('BS004', N'Nguyễn Thị Hoa',     N'Giải phẫu bệnh',  12, NULL),
('BS005', N'Trần Quang Huy',     N'Pháp y',           11, NULL)
GO

INSERT INTO DICHVU VALUES
('DV001', N'Trang điểm tử thi', 500000),
('DV002', N'Khâm liệm',         2000000),
('DV003', N'Bảo quản lạnh',     150000)
GO

INSERT INTO NGANKEO(MANGAN, VITRI, NHIETDO, MATH) VALUES
('NK001', N'Khu A - Hộc 1', -5.5, 'TH001'),
('NK002', N'Khu A - Hộc 2', -5.0, 'TH002'),
('NK003', N'Khu B - Hộc 1', -6.0, NULL)
GO

INSERT INTO HOSOKHAMBENH(MAHS, THOIGIANKHAM, KETLUAN, MATH, MABS) VALUES
('HS001', '20-01-2026', N'Tử vong do tai nạn giao thông', 'TH001', 'BS001'),
('HS002', '21-01-2026', N'Tử vong do bệnh tim',           'TH002', 'BS002')
GO

INSERT INTO SUDUNG VALUES
('TH001', 'DV001', '20-01-2026', N'Yêu cầu trang điểm nhẹ'),
('TH001', 'DV002', '20-01-2026', N'Khâm liệm theo giờ tốt'),
('TH002', 'DV003', '21-01-2026', N'Bảo quản 3 ngày')
GO

INSERT INTO NHANVIEN VALUES
('NV001', N'Nguyễn Thị Lan',   N'Lễ tân',          '0901111111'),
('NV002', N'Trần Văn Bình',    N'Chăm sóc thi hài', '0902222222'),
('NV003', N'Lê Thị Hoa',       N'Kế toán',          '0903333333')
GO

INSERT INTO THAN_NHAN VALUES
('TN001','TH001', N'Nguyễn Thị Hà',   N'Vợ',    '0901234567', N'12 Lê Lợi, Q.1, TP.HCM',              1, NULL),
('TN002','TH001', N'Nguyễn Văn Bình', N'Con trai','0912345678', N'12 Lê Lợi, Q.1, TP.HCM',             0, NULL),
('TN003','TH002', N'Trần Văn Quang',  N'Chồng',  '0923456789', N'45 Đinh Tiên Hoàng, Q.Bình Thạnh',   1, NULL)
GO

INSERT INTO HOADON(MAHD, MATH, NGAYLAP, TONGTIEN, TRANGTHAITT, PHUONGTHUCTT, NGAYTHANHTOAN, NGUOILAP) VALUES
('HD001','TH001','21-01-2026', 2500000, N'Đã thanh toán',   N'Tiền mặt', '22-01-2026', N'NhaXacAdmin'),
('HD002','TH002','22-01-2026',  150000, N'Chưa thanh toán', NULL,          NULL,         N'NhaXacAdmin')
GO

UPDATE THIHAI SET TRANGTHAI = N'Đã bàn giao'   WHERE MATH = 'TH001'
UPDATE THIHAI SET TRANGTHAI = N'Đang bảo quản' WHERE MATH IN ('TH002','TH003')
GO

-- ============================================================
-- 3. VIEW
-- ============================================================

-- 3.1 Bác sĩ kèm tên trưởng khoa + cấp bậc
CREATE VIEW VIEW_DanhSachBacSi AS
SELECT
    bs.MABS,
    bs.HOTEN_BS,
    bs.CHUYENKHOA,
    bs.NAMKINHNGHIEM,
    bs.MA_TRUONGKHOA,
    tk.HOTEN_BS AS TEN_TRUONGKHOA,
    CASE
        WHEN bs.NAMKINHNGHIEM < 2              THEN N'Thực tập sinh'
        WHEN bs.NAMKINHNGHIEM BETWEEN 2 AND 5  THEN N'Bác sĩ tiêu chuẩn'
        WHEN bs.NAMKINHNGHIEM BETWEEN 6 AND 9  THEN N'Chuyên môn cao'
        ELSE N'Chuyên gia/Lão làng'
    END AS CAPBAC
FROM BACSI bs
LEFT JOIN BACSI tk ON bs.MA_TRUONGKHOA = tk.MABS
GO

-- 3.2 Bác sĩ trên mức TB kinh nghiệm
CREATE VIEW VIEW_BSLaoLang AS
SELECT * FROM VIEW_DanhSachBacSi
WHERE NAMKINHNGHIEM > (SELECT AVG(NAMKINHNGHIEM) FROM VIEW_DanhSachBacSi)
GO

-- 3.3 Khối lượng khám nghiệm của bác sĩ
CREATE VIEW VIEW_BacSi_KhoiLuongKhamNghiem AS
SELECT
    bs.MABS,
    bs.HOTEN_BS,
    bs.CHUYENKHOA,
    COUNT(hs.MAHS) AS TongCaKham,
    SUM(CASE WHEN MONTH(hs.THOIGIANKHAM) = MONTH(GETDATE())
                  AND YEAR(hs.THOIGIANKHAM)  = YEAR(GETDATE())
             THEN 1 ELSE 0 END) AS CaKhamThangNay
FROM BACSI bs
LEFT JOIN HOSOKHAMBENH hs ON bs.MABS = hs.MABS
GROUP BY bs.MABS, bs.HOTEN_BS, bs.CHUYENKHOA
GO

-- 3.4 Hồ sơ khám nghiệm chi tiết (đầy đủ tên + trường pháp y)
CREATE VIEW VIEW_HoSo_ChiTiet AS
SELECT
    hs.MAHS,
    hs.THOIGIANKHAM,
    th.MATH,
    th.HOTEN_TH,
    th.TRANGTHAI AS TRANGTHAI_THIHAI,
    bs.MABS,
    bs.HOTEN_BS,
    bs.CHUYENKHOA,
    hs.KETLUAN,
    hs.MACAUTU,
    hs.LOAICAUTU,
    hs.SOBIENBAN,
    hs.NGAYBIENBAN,
    hs.COQUANYEUCAU,
    hs.GHICHUPHAY
FROM HOSOKHAMBENH hs
JOIN THIHAI th ON hs.MATH = th.MATH
JOIN BACSI  bs ON hs.MABS = bs.MABS
GO

-- 3.5 Thi hài đầy đủ (vị trí, thân nhân, ngày còn lại)
CREATE VIEW VIEW_DanhSachThiHai AS
SELECT
    th.MATH,
    th.HOTEN_TH,
    th.NGAYSINH,
    th.NGAYMAT,
    th.GIOITINH,
    th.TRANGTHAI,
    th.NGAYNHAP,
    DATEDIFF(YEAR, th.NGAYSINH, th.NGAYMAT) AS TUOI_KHI_MAT,
    CASE
        WHEN DATEDIFF(YEAR, th.NGAYSINH, th.NGAYMAT) < 18              THEN N'Vị thành niên'
        WHEN DATEDIFF(YEAR, th.NGAYSINH, th.NGAYMAT) BETWEEN 18 AND 59 THEN N'Trưởng thành'
        ELSE N'Cao tuổi'
    END AS NHOMTUOI,
    nk.MANGAN,
    nk.VITRI,
    nk.NHIETDO
FROM THIHAI th
LEFT JOIN NGANKEO nk ON nk.MATH = th.MATH
GO

-- 3.6 Thi hài còn sót (chưa vào ngăn kéo)
CREATE VIEW VIEW_ThiHaiChuaCoNganKeo AS
SELECT th.*
FROM THIHAI th
WHERE th.MATH NOT IN (SELECT MATH FROM NGANKEO WHERE MATH IS NOT NULL)
GO

-- 3.7 Thi hài sắp/đã quá hạn
CREATE VIEW VIEW_ThiHaiQuaHan AS
SELECT
    th.MATH,
    th.HOTEN_TH,
    th.NGAYMAT,
    th.TRANGTHAI,
    DATEDIFF(DAY, th.NGAYMAT, GETDATE()) AS SoNgayKe,
    15 - DATEDIFF(DAY, th.NGAYMAT, GETDATE()) AS ConLaiNgay,
    CASE
        WHEN DATEDIFF(DAY, th.NGAYMAT, GETDATE()) > 15              THEN N'Quá hạn'
        WHEN DATEDIFF(DAY, th.NGAYMAT, GETDATE()) BETWEEN 12 AND 15 THEN N'Sắp quá hạn'
        ELSE N'Bình thường'
    END AS TinhTrang
FROM THIHAI th
WHERE th.MATH NOT IN (SELECT MATH FROM NGANKEO WHERE MATH IS NOT NULL)
  AND DATEDIFF(DAY, th.NGAYMAT, GETDATE()) >= 12
GO

-- 3.8 Ngăn kéo toàn bộ (kể cả trống)
CREATE VIEW VIEW_DanhSachNganKeo AS
SELECT
    nk.MANGAN,
    nk.VITRI,
    nk.NHIETDO,
    nk.NHIETDO_CANH_BAO,
    nk.NGAY_BAO_TRI,
    nk.MATH,
    th.HOTEN_TH,
    th.TRANGTHAI,
    CASE WHEN nk.MATH IS NULL THEN N'Trống' ELSE N'Đang sử dụng' END AS TRANGTHAI_NGAN
FROM NGANKEO nk
LEFT JOIN THIHAI th ON nk.MATH = th.MATH
GO

-- 3.9 Dịch vụ (danh mục)
CREATE VIEW VIEW_DichVu AS
SELECT * FROM DICHVU
GO

-- 3.10 Dịch vụ chưa có ai dùng (ế)
CREATE VIEW VIEW_DichVuE AS
SELECT * FROM DICHVU
WHERE MADV NOT IN (SELECT DISTINCT MADV FROM SUDUNG)
GO

-- 3.11 Thống kê dịch vụ
CREATE VIEW VIEW_DichVu_ThongKe AS
SELECT
    dv.MADV,
    dv.TENDV,
    dv.GIATIEN,
    COUNT(sd.MATH) AS SO_LAN_SU_DUNG,
    ISNULL(SUM(dv.GIATIEN), 0) AS TONG_DOANH_THU,
    MAX(sd.NGAYSUDUNG) AS LAN_SU_DUNG_CUOI
FROM DICHVU dv
LEFT JOIN SUDUNG sd ON dv.MADV = sd.MADV
GROUP BY dv.MADV, dv.TENDV, dv.GIATIEN
GO

-- 3.12 Dịch vụ sử dụng chi tiết kèm hóa đơn
CREATE VIEW VIEW_DichVuSuDung AS
SELECT
    th.MATH,
    th.HOTEN_TH,
    th.TRANGTHAI,
    dv.MADV,
    dv.TENDV,
    dv.GIATIEN,
    sd.NGAYSUDUNG,
    sd.GHICHU,
    hd.MAHD,
    hd.TRANGTHAITT AS TRANGTHAI_HOADON
FROM THIHAI  th
JOIN SUDUNG  sd ON th.MATH = sd.MATH
JOIN DICHVU  dv ON sd.MADV = dv.MADV
LEFT JOIN HOADON hd ON th.MATH = hd.MATH
GO

-- 3.13 Thân nhân kèm thi hài
CREATE VIEW VIEW_ThanNhanThiHai AS
SELECT
    tn.MATN, tn.QUANHE, tn.HOTEN_TN, tn.DIENTHOAI, tn.DIACHI,
    tn.LALIENDHE, tn.GHICHU,
    th.MATH, th.HOTEN_TH, th.TRANGTHAI
FROM THAN_NHAN tn
JOIN THIHAI th ON tn.MATH = th.MATH
GO

-- 3.14 Hóa đơn chi tiết
CREATE VIEW VIEW_HoaDonChiTiet AS
SELECT
    hd.MAHD,
    th.MATH,
    th.HOTEN_TH,
    tn.HOTEN_TN    AS NGUOI_NHAN,
    tn.DIENTHOAI   AS SDT_NGUOI_NHAN,
    hd.NGAYLAP,
    hd.TONGTIEN,
    hd.TRANGTHAITT,
    hd.PHUONGTHUCTT,
    hd.NGAYTHANHTOAN,
    hd.NGUOILAP,
    hd.GHICHU
FROM HOADON hd
JOIN THIHAI th ON hd.MATH = th.MATH
LEFT JOIN THAN_NHAN tn ON tn.MATH = th.MATH AND tn.LALIENDHE = 1
GO

-- 3.15 Hóa đơn chưa thanh toán (kế toán thu tiền)
CREATE VIEW VIEW_HoaDon_ChuaThanhToan AS
SELECT
    hd.MAHD,
    th.MATH,
    th.HOTEN_TH,
    th.TRANGTHAI AS TRANGTHAI_THIHAI,
    hd.NGAYLAP,
    hd.TONGTIEN,
    hd.TRANGTHAITT,
    hd.NGUOILAP,
    tn.HOTEN_TN   AS NGUOI_LIEN_HE,
    tn.DIENTHOAI,
    tn.QUANHE,
    DATEDIFF(DAY, hd.NGAYLAP, GETDATE()) AS SO_NGAY_NO
FROM HOADON hd
JOIN THIHAI th ON hd.MATH = th.MATH
LEFT JOIN THAN_NHAN tn ON tn.MATH = th.MATH AND tn.LALIENDHE = 1
WHERE hd.TRANGTHAITT IN (N'Chưa thanh toán', N'Nợ')
GO

-- 3.16 Cảnh báo chưa đọc
CREATE VIEW VIEW_CanhBaoChuaDoc AS
SELECT
    cb.MACB, cb.THOIGIAN, cb.LOAICB,
    cb.MATH, cb.MANGAN, cb.NOIDUNG,
    th.HOTEN_TH,
    CASE cb.LOAICB
        WHEN N'QuaHan'   THEN 1
        WHEN N'NhietDo'  THEN 1
        WHEN N'ChuaKham' THEN 2
        ELSE 3
    END AS MUC_DO_UU_TIEN,
    CASE cb.LOAICB
        WHEN N'QuaHan'   THEN N'Khẩn cấp'
        WHEN N'NhietDo'  THEN N'Nguy hiểm'
        WHEN N'ChuaKham' THEN N'Cần xử lý'
        ELSE N'Thông báo'
    END AS MUC_DO_HIEN_THI
FROM CANH_BAO cb
LEFT JOIN THIHAI th ON cb.MATH = th.MATH
WHERE cb.DAOC = 0
GO

-- 3.17 Dashboard tổng quan
CREATE VIEW VIEW_Dashboard AS
SELECT
    (SELECT COUNT(*) FROM THIHAI)                                         AS TongThiHai,
    (SELECT COUNT(*) FROM THIHAI WHERE TRANGTHAI = N'Đang bảo quản')     AS DangBaoQuan,
    (SELECT COUNT(*) FROM THIHAI WHERE TRANGTHAI = N'Chờ bàn giao')      AS ChoThanhLy,
    (SELECT COUNT(*) FROM NGANKEO WHERE MATH IS NULL)                     AS NganKeoTrong,
    (SELECT COUNT(*) FROM NGANKEO WHERE MATH IS NOT NULL)                 AS NganKeoDang,
    (SELECT COUNT(*) FROM NGANKEO)                                        AS TongNganKeo,
    (SELECT ISNULL(SUM(TONGTIEN),0) FROM HOADON
     WHERE TRANGTHAITT = N'Đã thanh toán'
       AND NGAYTHANHTOAN = CAST(GETDATE() AS DATE))                       AS DoanhThuHomNay,
    (SELECT ISNULL(SUM(TONGTIEN),0) FROM HOADON
     WHERE TRANGTHAITT = N'Đã thanh toán'
       AND MONTH(NGAYTHANHTOAN) = MONTH(GETDATE())
       AND YEAR(NGAYTHANHTOAN)  = YEAR(GETDATE()))                        AS DoanhThuThang,
    (SELECT COUNT(*) FROM CANH_BAO WHERE DAOC = 0)                        AS SoCanhBaoChuaDoc,
    (SELECT COUNT(*) FROM HOADON WHERE TRANGTHAITT = N'Chưa thanh toán') AS HoaDonChuaTT
GO

-- 3.18 Thống kê thi hài theo tháng
CREATE VIEW VIEW_ThongKe_TheoThang AS
SELECT
    YEAR(NGAYMAT)  AS Nam,
    MONTH(NGAYMAT) AS Thang,
    COUNT(*)       AS SoLuongThiHai,
    SUM(CASE WHEN GIOITINH = N'Nam' THEN 1 ELSE 0 END) AS SoNam,
    SUM(CASE WHEN GIOITINH = N'Nữ'  THEN 1 ELSE 0 END) AS SoNu,
    SUM(CASE WHEN DATEDIFF(YEAR,NGAYSINH,NGAYMAT) < 18 THEN 1 ELSE 0 END) AS ViThanhNien,
    SUM(CASE WHEN DATEDIFF(YEAR,NGAYSINH,NGAYMAT) BETWEEN 18 AND 59 THEN 1 ELSE 0 END) AS TruongThanh,
    SUM(CASE WHEN DATEDIFF(YEAR,NGAYSINH,NGAYMAT) >= 60 THEN 1 ELSE 0 END) AS CaoTuoi
FROM THIHAI
WHERE NGAYMAT IS NOT NULL
GROUP BY YEAR(NGAYMAT), MONTH(NGAYMAT)
GO

-- 3.19 Thống kê doanh thu theo tháng
CREATE VIEW VIEW_ThongKe_DoanhThu AS
SELECT
    YEAR(NGAYTHANHTOAN)  AS Nam,
    MONTH(NGAYTHANHTOAN) AS Thang,
    COUNT(MAHD)          AS SoHoaDon,
    SUM(TONGTIEN)        AS TongDoanhThu,
    SUM(CASE WHEN TRANGTHAITT = N'Đã thanh toán'   THEN TONGTIEN ELSE 0 END) AS DaThanhToan,
    SUM(CASE WHEN TRANGTHAITT = N'Chưa thanh toán' THEN TONGTIEN ELSE 0 END) AS ChuaThanhToan
FROM HOADON
WHERE NGAYTHANHTOAN IS NOT NULL
GROUP BY YEAR(NGAYTHANHTOAN), MONTH(NGAYTHANHTOAN)
GO

-- 3.20 Thống kê loại nguyên nhân tử vong
CREATE VIEW VIEW_ThongKe_LoaiCauTu AS
SELECT
    YEAR(THOIGIANKHAM)  AS Nam,
    MONTH(THOIGIANKHAM) AS Thang,
    LOAICAUTU,
    COUNT(*)            AS SoLuong,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (
        PARTITION BY YEAR(THOIGIANKHAM), MONTH(THOIGIANKHAM)
    ) AS DECIMAL(5,2))  AS TiLePhanTram
FROM HOSOKHAMBENH
WHERE LOAICAUTU IS NOT NULL
GROUP BY YEAR(THOIGIANKHAM), MONTH(THOIGIANKHAM), LOAICAUTU
GO

-- 3.21 Tóm tắt Audit Log
CREATE VIEW VIEW_AuditLog_TomTat AS
SELECT
    CAST(THOIGIAN AS DATE)  AS Ngay,
    TENTABLE,
    HANHDOG,
    COUNT(*)                AS SoThaotac,
    COUNT(DISTINCT TENUSER) AS SoUser
FROM AUDIT_LOG
GROUP BY CAST(THOIGIAN AS DATE), TENTABLE, HANHDOG
GO

-- 3.22 KPI nhân viên theo hóa đơn
CREATE VIEW VIEW_ThongKe_NhanVien_HoaDon AS
SELECT
    NGUOILAP AS TenNhanVien,
    COUNT(MAHD)                                                                 AS TongHoaDon,
    SUM(CASE WHEN TRANGTHAITT = N'Đã thanh toán'   THEN 1 ELSE 0 END)         AS DaThanhToan,
    SUM(CASE WHEN TRANGTHAITT = N'Chưa thanh toán' THEN 1 ELSE 0 END)         AS ChuaThanhToan,
    ISNULL(SUM(CASE WHEN TRANGTHAITT = N'Đã thanh toán'
                    THEN TONGTIEN ELSE 0 END), 0)                               AS DoanhThuThuDuoc
FROM HOADON
GROUP BY NGUOILAP
GO

-- ============================================================
-- 4. HÀM (FUNCTIONS)
-- ============================================================

-- 4.1 Tính tổng tiền dịch vụ của thi hài
CREATE FUNCTION FN_TinhTongTienDichVu(@MATH VARCHAR(15))
RETURNS MONEY
AS
BEGIN
    DECLARE @TongTien MONEY
    SELECT @TongTien = ISNULL(SUM(dv.GIATIEN), 0)
    FROM SUDUNG sd
    JOIN DICHVU dv ON sd.MADV = dv.MADV
    WHERE sd.MATH = @MATH
    RETURN @TongTien
END
GO

-- 4.2 Trạng thái ngăn kéo (Trống / Đang sử dụng)
CREATE FUNCTION FN_CapNhatTrangThaiNganKeo(@MANGAN VARCHAR(15))
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @TrangThai NVARCHAR(50)
    IF EXISTS (SELECT 1 FROM NGANKEO WHERE MANGAN=@MANGAN AND MATH IS NOT NULL)
        SET @TrangThai = N'Đang sử dụng'
    ELSE
        SET @TrangThai = N'Trống'
    RETURN @TrangThai
END
GO

-- 4.3 Danh sách ngăn kéo trống (TVF)
CREATE FUNCTION fn_DanhSachNganKeoTrong()
RETURNS TABLE
AS
RETURN (
    SELECT MANGAN, VITRI, NHIETDO
    FROM NGANKEO
    WHERE MATH IS NULL
)
GO

-- 4.4 Lịch sử dịch vụ của tử thi (TVF)
CREATE FUNCTION fn_LichSuDichVuCuaTuThi(@MATH VARCHAR(15))
RETURNS TABLE
AS
RETURN (
    SELECT dv.TENDV, dv.GIATIEN, sd.NGAYSUDUNG, sd.GHICHU
    FROM SUDUNG sd
    JOIN DICHVU dv ON sd.MADV = dv.MADV
    WHERE sd.MATH = @MATH
)
GO

-- 4.5 Tìm thi hài theo ngày
CREATE FUNCTION fn_TimKiemThiHaiTheoNgay(@NgayTimKiem DATE)
RETURNS TABLE
AS
RETURN (
    SELECT * FROM THIHAI
    WHERE NGAYMAT = @NgayTimKiem OR NGAYSINH = @NgayTimKiem
)
GO

-- 4.6 Danh sách khám nghiệm theo bác sĩ (TVF)
CREATE FUNCTION fn_DanhSachKhamNghiemTheoBacSi(@MABS VARCHAR(15))
RETURNS TABLE
AS
RETURN (
    SELECT th.MATH, th.HOTEN_TH, th.GIOITINH, hs.THOIGIANKHAM, hs.KETLUAN
    FROM HOSOKHAMBENH hs
    JOIN THIHAI th ON hs.MATH = th.MATH
    WHERE hs.MABS = @MABS
)
GO

-- 4.7 Danh sách khám nghiệm theo tử thi (TVF)
CREATE FUNCTION fn_DanhSachKhamNghiemTheoTuThi(@MATH VARCHAR(15))
RETURNS TABLE
AS
RETURN (
    SELECT hs.MAHS, hs.MATH, hs.MABS, bs.HOTEN_BS, hs.THOIGIANKHAM, hs.KETLUAN
    FROM HOSOKHAMBENH hs
    JOIN BACSI bs ON hs.MABS = bs.MABS
    WHERE hs.MATH = @MATH
)
GO

-- 4.8 Số ngày còn lại lưu trữ (9999 = đang trong ngăn lạnh)
CREATE FUNCTION FN_NgayConLai(@MATH VARCHAR(15))
RETURNS INT
AS
BEGIN
    DECLARE @NgayMat DATE
    SELECT @NgayMat = NGAYMAT FROM THIHAI WHERE MATH = @MATH
    IF EXISTS (SELECT 1 FROM NGANKEO WHERE MATH = @MATH)
        RETURN 9999
    RETURN 15 - DATEDIFF(DAY, @NgayMat, GETDATE())
END
GO

-- 4.9 Thông tin người liên hệ chính
CREATE FUNCTION FN_NguoiLienHe(@MATH VARCHAR(15))
RETURNS NVARCHAR(150)
AS
BEGIN
    DECLARE @KetQua NVARCHAR(150)
    SELECT TOP 1
        @KetQua = HOTEN_TN + N' (' + ISNULL(QUANHE, N'?') + N') - '
                + ISNULL(DIENTHOAI, N'Chưa có SĐT')
    FROM THAN_NHAN
    WHERE MATH = @MATH AND LALIENDHE = 1
    RETURN ISNULL(@KetQua, N'Chưa có thân nhân')
END
GO

-- 4.10 Kiểm tra hóa đơn đã thanh toán
CREATE FUNCTION FN_KiemTraHoaDonDuocThanhToan(@MATH VARCHAR(15))
RETURNS BIT
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM HOADON
        WHERE MATH = @MATH AND TRANGTHAITT = N'Đã thanh toán'
    )
        RETURN 1
    RETURN 0
END
GO

-- ============================================================
-- 5. TRIGGER
-- ============================================================

-- 5.1 Kiểm tra ngày khám nghiệm >= ngày mất
CREATE TRIGGER TRG_KiemTraNgayKham
ON HOSOKHAMBENH
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN THIHAI th ON i.MATH = th.MATH
        WHERE i.THOIGIANKHAM < th.NGAYMAT
    )
    BEGIN
        PRINT N'Lỗi: Ngày khám nghiệm không được trước ngày mất của thi hài!'
        ROLLBACK TRANSACTION
    END
END
GO

-- 5.2 Kiểm tra ngày sử dụng dịch vụ >= ngày mất
CREATE TRIGGER TRG_KiemTraNgayDichVu
ON SUDUNG
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN THIHAI th ON i.MATH = th.MATH
        WHERE i.NGAYSUDUNG < th.NGAYMAT
    )
    BEGIN
        PRINT N'Lỗi: Ngày sử dụng dịch vụ sớm hơn ngày mất!'
        ROLLBACK TRANSACTION
    END
END
GO

-- 5.3 Bác sĩ không tự là trưởng khoa của mình
CREATE TRIGGER TRG_KiemTraTruongKhoa
ON BACSI
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE MABS = MA_TRUONGKHOA)
    BEGIN
        PRINT N'Lỗi: Bác sĩ không thể tự nhận mình là trưởng khoa!'
        ROLLBACK TRANSACTION
    END
END
GO

-- 5.4 Cascade delete khi xóa thi hài (kể cả THAN_NHAN, HOADON)
CREATE TRIGGER TRG_CascadeDelete_ThiHai
ON THIHAI
INSTEAD OF DELETE
AS
BEGIN
    DELETE FROM HOSOKHAMBENH WHERE MATH IN (SELECT MATH FROM deleted)
    DELETE FROM SUDUNG       WHERE MATH IN (SELECT MATH FROM deleted)
    DELETE FROM THAN_NHAN    WHERE MATH IN (SELECT MATH FROM deleted)
    DELETE FROM HOADON       WHERE MATH IN (SELECT MATH FROM deleted)
    UPDATE NGANKEO SET MATH = NULL WHERE MATH IN (SELECT MATH FROM deleted)
    DELETE FROM THIHAI       WHERE MATH IN (SELECT MATH FROM deleted)
    PRINT N'Đã xóa thông tin thi hài thành công'
END
GO

-- 5.5 Tự động đăng ký dịch vụ bảo quản lạnh khi xếp vào ngăn
CREATE TRIGGER TRG_TuDongBaoQuanLanh
ON NGANKEO
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON
    IF UPDATE(MATH)
    BEGIN
        INSERT INTO SUDUNG(MATH, MADV, NGAYSUDUNG, GHICHU)
        SELECT i.MATH, 'DV003', GETDATE(), N'Tự động kích hoạt do nhập tủ lạnh'
        FROM inserted i
        JOIN deleted d ON i.MANGAN = d.MANGAN
        WHERE i.MATH IS NOT NULL AND d.MATH IS NULL
          AND NOT EXISTS (SELECT 1 FROM SUDUNG s WHERE s.MATH = i.MATH AND s.MADV = 'DV003')
    END
END
GO

-- 5.6 Cảnh báo nhiệt độ > 0°C khi tủ đang có thi hài (ghi cảnh báo thay vì ROLLBACK)
CREATE TRIGGER TRG_CanhBaoNhietDoNganKeo
ON NGANKEO
FOR UPDATE
AS
BEGIN
    SET NOCOUNT ON
    IF UPDATE(NHIETDO)
    BEGIN
        -- Ghi cảnh báo vào bảng CANH_BAO thay vì rollback cứng
        INSERT INTO CANH_BAO(LOAICB, MANGAN, NOIDUNG)
        SELECT N'NhietDo', i.MANGAN,
               N'Cảnh báo: Ngăn ' + i.MANGAN + N' có nhiệt độ '
               + CAST(i.NHIETDO AS NVARCHAR(10)) + N'°C vượt ngưỡng an toàn trong khi đang chứa thi hài!'
        FROM inserted i
        WHERE i.MATH IS NOT NULL AND i.NHIETDO > 0

        IF EXISTS (SELECT 1 FROM inserted WHERE MATH IS NOT NULL AND NHIETDO > 0)
        BEGIN
            PRINT N'Cảnh báo nghiêm trọng: Nhiệt độ > 0°C khi tủ đang có thi hài!'
            ROLLBACK TRANSACTION
        END
    END
END
GO

-- 5.7 Cấm xóa hồ sơ pháp y
CREATE TRIGGER TRG_BaoVeHoSoPhapY
ON HOSOKHAMBENH
FOR DELETE
AS
BEGIN
    PRINT N'Cảnh báo: Hồ sơ pháp y là tài liệu vĩnh viễn, không được phép xóa!'
    ROLLBACK TRANSACTION
END
GO

-- 5.8 Giới hạn 3 ca khám/bác sĩ/ngày
CREATE TRIGGER TRG_GioiHanCaKhamBacSi
ON HOSOKHAMBENH
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT i.MABS, i.THOIGIANKHAM
        FROM inserted i
        JOIN HOSOKHAMBENH hs ON i.MABS = hs.MABS AND i.THOIGIANKHAM = hs.THOIGIANKHAM
        GROUP BY i.MABS, i.THOIGIANKHAM
        HAVING COUNT(*) > 3
    )
    BEGIN
        PRINT N'Lỗi phân công: Một bác sĩ không thể thực hiện quá 3 ca khám nghiệm trong ngày!'
        ROLLBACK TRANSACTION
    END
END
GO

-- 5.9 Audit log: thi hài
CREATE TRIGGER TRG_Audit_ThiHai
ON THIHAI
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @action NVARCHAR(10)
    IF EXISTS(SELECT 1 FROM inserted) AND EXISTS(SELECT 1 FROM deleted)
        SET @action = 'UPDATE'
    ELSE IF EXISTS(SELECT 1 FROM inserted)
        SET @action = 'INSERT'
    ELSE
        SET @action = 'DELETE'

    IF @action IN ('INSERT','UPDATE')
        INSERT INTO AUDIT_LOG(TENTABLE, HANHDOG, MABANGHI, NOIDUNG)
        SELECT 'THIHAI', @action, i.MATH,
               N'[' + @action + N'] Thi hài: ' + ISNULL(i.HOTEN_TH, N'?')
               + N' | Trạng thái: ' + ISNULL(i.TRANGTHAI, N'?')
        FROM inserted i
    ELSE
        INSERT INTO AUDIT_LOG(TENTABLE, HANHDOG, MABANGHI, NOIDUNG)
        SELECT 'THIHAI', @action, d.MATH,
               N'[DELETE] Đã xóa thi hài: ' + ISNULL(d.HOTEN_TH, N'?')
        FROM deleted d
END
GO

-- 5.10 Audit log: hồ sơ khám nghiệm
CREATE TRIGGER TRG_Audit_HoSo
ON HOSOKHAMBENH
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @action NVARCHAR(10) =
        CASE WHEN EXISTS(SELECT 1 FROM deleted) THEN 'UPDATE' ELSE 'INSERT' END
    INSERT INTO AUDIT_LOG(TENTABLE, HANHDOG, MABANGHI, NOIDUNG)
    SELECT 'HOSOKHAMBENH', @action, i.MAHS,
           N'[' + @action + N'] Hồ sơ ' + i.MAHS
           + N' | Thi hài: ' + i.MATH
           + N' | Bác sĩ: ' + i.MABS
           + N' | Kết luận: ' + ISNULL(i.KETLUAN, N'?')
    FROM inserted i
END
GO

-- 5.11 Audit log: ngăn kéo
CREATE TRIGGER TRG_Audit_NganKeo
ON NGANKEO
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @action NVARCHAR(10) =
        CASE WHEN EXISTS(SELECT 1 FROM deleted) THEN 'UPDATE' ELSE 'INSERT' END
    INSERT INTO AUDIT_LOG(TENTABLE, HANHDOG, MABANGHI, NOIDUNG)
    SELECT 'NGANKEO', @action, i.MANGAN,
           N'[' + @action + N'] Ngăn ' + i.MANGAN
           + N' | Nhiệt độ: ' + CAST(i.NHIETDO AS NVARCHAR(10)) + N'°C'
           + N' | Thi hài: ' + ISNULL(i.MATH, N'Trống')
    FROM inserted i
END
GO

-- 5.12 Audit log: dịch vụ sử dụng
CREATE TRIGGER TRG_Audit_SuDung
ON SUDUNG
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @action NVARCHAR(10)
    IF EXISTS(SELECT 1 FROM inserted) AND EXISTS(SELECT 1 FROM deleted)
        SET @action = 'UPDATE'
    ELSE IF EXISTS(SELECT 1 FROM inserted)
        SET @action = 'INSERT'
    ELSE
        SET @action = 'DELETE'

    IF @action IN ('INSERT','UPDATE')
        INSERT INTO AUDIT_LOG(TENTABLE, HANHDOG, MABANGHI, NOIDUNG)
        SELECT 'SUDUNG', @action, i.MATH + '-' + i.MADV,
               N'[' + @action + N'] Thi hài ' + i.MATH + N' - Dịch vụ ' + i.MADV
        FROM inserted i
    ELSE
        INSERT INTO AUDIT_LOG(TENTABLE, HANHDOG, MABANGHI, NOIDUNG)
        SELECT 'SUDUNG', @action, d.MATH + '-' + d.MADV,
               N'[DELETE] Xóa SD: Thi hài ' + d.MATH + N' - Dịch vụ ' + d.MADV
        FROM deleted d
END
GO

-- 5.13 Audit log: hóa đơn
CREATE TRIGGER TRG_Audit_HoaDon
ON HOADON
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @action NVARCHAR(10) =
        CASE WHEN EXISTS(SELECT 1 FROM deleted) THEN 'UPDATE' ELSE 'INSERT' END
    INSERT INTO AUDIT_LOG(TENTABLE, HANHDOG, MABANGHI, NOIDUNG)
    SELECT 'HOADON', @action, i.MAHD,
           N'[' + @action + N'] Hóa đơn ' + i.MAHD
           + N' | Thi hài: ' + i.MATH
           + N' | Tổng tiền: ' + CAST(i.TONGTIEN AS NVARCHAR(20))
           + N' | TT: ' + i.TRANGTHAITT
    FROM inserted i
END
GO

-- 5.13b Audit log: nhân viên
CREATE TRIGGER TRG_Audit_NhanVien
ON NHANVIEN
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @action NVARCHAR(10)
    
    IF EXISTS(SELECT 1 FROM inserted) AND EXISTS(SELECT 1 FROM deleted)
        SET @action = 'UPDATE'
    ELSE IF EXISTS(SELECT 1 FROM inserted)
        SET @action = 'INSERT'
    ELSE
        SET @action = 'DELETE'

    IF @action IN ('INSERT','UPDATE')
        INSERT INTO AUDIT_LOG(TENTABLE, HANHDOG, MABANGHI, NOIDUNG)
        SELECT 'NHANVIEN', @action, i.MANV,
               N'[' + @action + N'] Nhân viên: ' + ISNULL(i.HOTEN_NV, N'?') 
               + N' | Chức vụ: ' + ISNULL(i.CHUCVU, N'?')
        FROM inserted i
    ELSE
        INSERT INTO AUDIT_LOG(TENTABLE, HANHDOG, MABANGHI, NOIDUNG)
        SELECT 'NHANVIEN', @action, d.MANV,
               N'[DELETE] Đã xóa nhân viên: ' + ISNULL(d.HOTEN_NV, N'?')
        FROM deleted d
END
GO

-- 5.14 Tự động cập nhật trạng thái thi hài khi thay đổi ngăn kéo
CREATE TRIGGER TRG_CapNhatTrangThaiThiHai
ON NGANKEO
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON
    IF UPDATE(MATH)
    BEGIN
        -- Xếp vào ngăn → Đang bảo quản
        UPDATE THIHAI SET TRANGTHAI = N'Đang bảo quản'
        FROM THIHAI th
        JOIN inserted i ON th.MATH = i.MATH
        JOIN deleted  d ON d.MANGAN = i.MANGAN
        WHERE i.MATH IS NOT NULL AND d.MATH IS NULL

        -- Lấy ra khỏi ngăn → Chờ bàn giao
        UPDATE THIHAI SET TRANGTHAI = N'Chờ bàn giao'
        FROM THIHAI th
        JOIN deleted  d ON th.MATH = d.MATH
        JOIN inserted i ON i.MANGAN = d.MANGAN
        WHERE i.MATH IS NULL AND d.MATH IS NOT NULL
    END
END
GO

-- 5.15 Cảnh báo thi hài sắp quá hạn (12-15 ngày chưa vào ngăn)
CREATE TRIGGER TRG_CanhBaoSapQuaHan
ON THIHAI
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON
    INSERT INTO CANH_BAO(LOAICB, MATH, NOIDUNG)
    SELECT N'QuaHan', i.MATH,
           N'Thi hài ' + ISNULL(i.HOTEN_TH, i.MATH)
           + N' sắp quá hạn! Còn '
           + CAST(15 - DATEDIFF(DAY, i.NGAYMAT, GETDATE()) AS NVARCHAR(5))
           + N' ngày.'
    FROM inserted i
    WHERE DATEDIFF(DAY, i.NGAYMAT, GETDATE()) BETWEEN 12 AND 15
      AND i.MATH NOT IN (SELECT MATH FROM NGANKEO WHERE MATH IS NOT NULL)
      AND NOT EXISTS (
          SELECT 1 FROM CANH_BAO cb
          WHERE cb.MATH = i.MATH AND cb.LOAICB = N'QuaHan' AND cb.DAOC = 0
      )
END
GO

-- 5.16 Cảnh báo khi thêm thi hài mới (chưa có bác sĩ phân công)
CREATE TRIGGER TRG_CanhBaoChuaKham
ON THIHAI
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON
    INSERT INTO CANH_BAO(LOAICB, MATH, NOIDUNG)
    SELECT N'ChuaKham', i.MATH,
           N'Thi hài ' + ISNULL(i.HOTEN_TH, i.MATH)
           + N' vừa nhập - chưa có bác sĩ phân công khám nghiệm.'
    FROM inserted i
END
GO

-- 5.17 Tự động tạo hóa đơn khi thi hài chuyển sang "Đã bàn giao"
CREATE TRIGGER TRG_TaoHoaDonKhiBanGiao
ON THIHAI
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON
    IF UPDATE(TRANGTHAI)
    BEGIN
        INSERT INTO HOADON(MAHD, MATH, NGAYLAP, TONGTIEN, TRANGTHAITT, NGUOILAP)
        SELECT
            'HD' + RIGHT('000' + CAST(
                ISNULL((SELECT MAX(CAST(SUBSTRING(MAHD,3,10) AS INT)) FROM HOADON), 0) + 1
            AS NVARCHAR(10)), 4),
            i.MATH,
            CAST(GETDATE() AS DATE),
            ISNULL(dbo.FN_TinhTongTienDichVu(i.MATH), 0),
            N'Chưa thanh toán',
            SUSER_SNAME()
        FROM inserted i
        JOIN deleted d ON i.MATH = d.MATH
        WHERE i.TRANGTHAI = N'Đã bàn giao'
          AND d.TRANGTHAI <> N'Đã bàn giao'
          AND NOT EXISTS (SELECT 1 FROM HOADON h WHERE h.MATH = i.MATH)
    END
END
GO

-- 5.18 Kiểm soát luồng trạng thái thi hài hợp lệ
CREATE TRIGGER TRG_ValidateTrangThai
ON THIHAI
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON
    -- Các chuyển đổi không hợp lệ
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN deleted d ON i.MATH = d.MATH
        WHERE d.TRANGTHAI = N'Đã mai táng'
          AND i.TRANGTHAI <> N'Đã mai táng'
    )
    BEGIN
        PRINT N'Lỗi: Không thể thay đổi trạng thái của thi hài đã mai táng!'
        ROLLBACK TRANSACTION
        RETURN
    END

    -- Thực hiện update nếu hợp lệ
    UPDATE THIHAI
    SET HOTEN_TH   = i.HOTEN_TH,
        NGAYSINH   = i.NGAYSINH,
        NGAYMAT    = i.NGAYMAT,
        GIOITINH   = i.GIOITINH,
        TRANGTHAI  = i.TRANGTHAI,
        NOITIMTHAY = i.NOITIMTHAY,
        COCUANHAN  = i.COCUANHAN,
        NGAYNHAP   = i.NGAYNHAP
    FROM THIHAI th
    JOIN inserted i ON th.MATH = i.MATH
END
GO

-- ============================================================
-- 6. STORED PROCEDURE
-- ============================================================

-- ── 6.A BÁC SĨ ──────────────────────────────────────────────
CREATE PROC SP_DSBacSi AS
BEGIN SELECT * FROM VIEW_DanhSachBacSi END
GO

CREATE PROC SP_ThemBacSi
    @MABS VARCHAR(15), @HOTEN_BS NVARCHAR(100),
    @CHUYENKHOA NVARCHAR(100), @NAMKINHNGHIEM INT, @MA_TRUONGKHOA VARCHAR(15)
AS
BEGIN
    INSERT INTO BACSI VALUES(@MABS,@HOTEN_BS,@CHUYENKHOA,@NAMKINHNGHIEM,@MA_TRUONGKHOA)
END
GO

CREATE PROC SP_SuaBacSi
    @MABS VARCHAR(15), @HOTEN_BS NVARCHAR(100),
    @CHUYENKHOA NVARCHAR(100), @NAMKINHNGHIEM INT, @MA_TRUONGKHOA VARCHAR(15)
AS
BEGIN
    UPDATE BACSI
    SET HOTEN_BS=@HOTEN_BS, CHUYENKHOA=@CHUYENKHOA,
        NAMKINHNGHIEM=@NAMKINHNGHIEM, MA_TRUONGKHOA=@MA_TRUONGKHOA
    WHERE MABS=@MABS
END
GO

CREATE PROC SP_XoaBacSi @MABS VARCHAR(15) AS
BEGIN DELETE FROM BACSI WHERE MABS=@MABS END
GO

CREATE PROC SP_BSLaoLang AS
BEGIN SELECT * FROM VIEW_BSLaoLang END
GO

CREATE PROC SP_TimKiemBacSi
    @TuKhoa NVARCHAR(100) = NULL, @CHUYENKHOA NVARCHAR(100) = NULL
AS
BEGIN
    SELECT * FROM VIEW_DanhSachBacSi
    WHERE (@TuKhoa IS NULL OR HOTEN_BS LIKE N'%' + @TuKhoa + N'%')
      AND (@CHUYENKHOA IS NULL OR CHUYENKHOA = @CHUYENKHOA)
END
GO

-- ── 6.B THI HÀI ─────────────────────────────────────────────
CREATE PROC SP_DSThiHai AS
BEGIN SELECT * FROM VIEW_DanhSachThiHai END
GO

CREATE PROC SP_ThemThiHai
    @MATH VARCHAR(15), @HOTEN_TH NVARCHAR(100), @NGAYSINH DATE,
    @NGAYMAT DATE, @GIOITINH NVARCHAR(10)
AS
BEGIN
    INSERT INTO THIHAI(MATH,HOTEN_TH,NGAYSINH,NGAYMAT,GIOITINH)
    VALUES(@MATH,@HOTEN_TH,@NGAYSINH,@NGAYMAT,@GIOITINH)
END
GO

CREATE PROC SP_SuaThiHai
    @MATH VARCHAR(15), @HOTEN_TH NVARCHAR(100), @NGAYSINH DATE,
    @NGAYMAT DATE, @GIOITINH NVARCHAR(10)
AS
BEGIN
    UPDATE THIHAI
    SET HOTEN_TH=@HOTEN_TH, NGAYSINH=@NGAYSINH,
        NGAYMAT=@NGAYMAT, GIOITINH=@GIOITINH
    WHERE MATH=@MATH
END
GO

CREATE PROC SP_XoaThiHai @MATH VARCHAR(15) AS
BEGIN
    -- TRG_CascadeDelete_ThiHai sẽ xử lý cascade tự động
    DELETE FROM THIHAI WHERE MATH=@MATH
END
GO

CREATE PROC SP_CapNhatTrangThaiThiHai
    @MATH VARCHAR(15), @TRANGTHAI NVARCHAR(30)
AS
BEGIN
    IF @TRANGTHAI NOT IN (
        N'Đang bảo quản',N'Đang khám nghiệm',
        N'Chờ bàn giao',N'Đã bàn giao',N'Đã mai táng'
    )
    BEGIN
        RAISERROR(N'Trạng thái không hợp lệ.', 16, 1); RETURN
    END
    UPDATE THIHAI SET TRANGTHAI=@TRANGTHAI WHERE MATH=@MATH
END
GO

CREATE PROC SP_ThiHaiSot AS
BEGIN
    SELECT * FROM VIEW_DanhSachThiHai
    WHERE MATH NOT IN (SELECT MATH FROM NGANKEO WHERE MATH IS NOT NULL)
END
GO

CREATE PROCEDURE SP_DemThiHai AS
BEGIN SELECT COUNT(MATH) AS SoLuong FROM THIHAI END
GO

CREATE PROC SP_DonDepThiHaiQuaHan AS
BEGIN
    DECLARE @MATH_XULY VARCHAR(15)
    WHILE EXISTS (
        SELECT 1 FROM THIHAI
        WHERE DATEDIFF(DAY, NGAYMAT, GETDATE()) > 15
          AND MATH NOT IN (SELECT MATH FROM NGANKEO WHERE MATH IS NOT NULL)
    )
    BEGIN
        SELECT TOP 1 @MATH_XULY = MATH
        FROM THIHAI
        WHERE DATEDIFF(DAY, NGAYMAT, GETDATE()) > 15
          AND MATH NOT IN (SELECT MATH FROM NGANKEO WHERE MATH IS NOT NULL)

        BEGIN TRANSACTION
            DELETE FROM SUDUNG       WHERE MATH = @MATH_XULY
            DELETE FROM HOSOKHAMBENH WHERE MATH = @MATH_XULY
            DELETE FROM THIHAI       WHERE MATH = @MATH_XULY
        COMMIT TRANSACTION
    END
    PRINT N'Đã hoàn tất dọn dẹp thi hài quá hạn!'
END
GO

CREATE PROC SP_TimKiemThiHai
    @TuKhoa     NVARCHAR(100) = NULL,
    @TRANGTHAI  NVARCHAR(30)  = NULL,
    @GIOITINH   NVARCHAR(10)  = NULL,
    @TuNgayMat  DATE          = NULL,
    @DenNgayMat DATE          = NULL
AS
BEGIN
    SELECT * FROM VIEW_DanhSachThiHai
    WHERE (@TuKhoa    IS NULL OR HOTEN_TH LIKE N'%' + @TuKhoa + N'%')
      AND (@TRANGTHAI IS NULL OR TRANGTHAI = @TRANGTHAI)
      AND (@GIOITINH  IS NULL OR GIOITINH  = @GIOITINH)
      AND (@TuNgayMat IS NULL OR NGAYMAT  >= @TuNgayMat)
      AND (@DenNgayMat IS NULL OR NGAYMAT  <= @DenNgayMat)
    ORDER BY NGAYMAT DESC
END
GO

-- ── 6.C NGĂN KÉO ────────────────────────────────────────────
CREATE PROC SP_DSNganKeo AS
BEGIN SELECT * FROM VIEW_DanhSachNganKeo END
GO

CREATE PROC SP_ThemNganKeo
    @MANGAN VARCHAR(15), @VITRI NVARCHAR(50), @NHIETDO FLOAT, @MATH VARCHAR(15)
AS
BEGIN
    INSERT INTO NGANKEO(MANGAN,VITRI,NHIETDO,MATH)
    VALUES(@MANGAN,@VITRI,@NHIETDO,@MATH)
END
GO

CREATE PROC SP_SuaNganKeo
    @MANGAN VARCHAR(15), @VITRI NVARCHAR(50), @NHIETDO FLOAT, @MATH VARCHAR(15)
AS
BEGIN
    UPDATE NGANKEO SET VITRI=@VITRI, NHIETDO=@NHIETDO, MATH=@MATH
    WHERE MANGAN=@MANGAN
END
GO

CREATE PROC SP_XoaNganKeo @MANGAN VARCHAR(15) AS
BEGIN
    BEGIN TRANSACTION
        DELETE FROM NGANKEO WHERE MANGAN=@MANGAN
    COMMIT TRANSACTION
END
GO

CREATE PROC SP_XepNganKeo @MATH VARCHAR(15) AS
BEGIN
    -- Tự tìm ngăn trống và xếp thi hài vào
    DECLARE @MANGAN VARCHAR(15)
    SELECT TOP 1 @MANGAN = MANGAN
    FROM NGANKEO WHERE MATH IS NULL
    ORDER BY MANGAN

    IF @MANGAN IS NULL
    BEGIN
        PRINT N'Không còn ngăn kéo trống!'
        RETURN
    END

    -- Kiểm tra thi hài chưa có ngăn kéo
    IF EXISTS (SELECT 1 FROM NGANKEO WHERE MATH = @MATH)
    BEGIN
        PRINT N'Thi hài đã được xếp vào ngăn kéo trước đó!'
        RETURN
    END

    UPDATE NGANKEO SET MATH = @MATH WHERE MANGAN = @MANGAN
    PRINT N'Đã xếp thi hài vào ngăn: ' + @MANGAN
END
GO

-- ── 6.D HỒ SƠ KHÁM NGHIỆM ───────────────────────────────────
CREATE PROC SP_DSHoSoKhamNghiem AS
BEGIN SELECT * FROM VIEW_HoSo_ChiTiet END
GO

CREATE PROC SP_ThemHoSoKhamBenh
    @MAHS VARCHAR(15), @THOIGIANKHAM DATE, @KETLUAN NVARCHAR(50),
    @MATH VARCHAR(15), @MABS VARCHAR(15)
AS
BEGIN
    INSERT INTO HOSOKHAMBENH(MAHS,THOIGIANKHAM,KETLUAN,MATH,MABS)
    VALUES(@MAHS,@THOIGIANKHAM,@KETLUAN,@MATH,@MABS)
END
GO

CREATE PROC SP_ThemHoSoKhamBenh_V2
    @MAHS VARCHAR(15), @THOIGIANKHAM DATE, @KETLUAN NVARCHAR(50),
    @MATH VARCHAR(15), @MABS VARCHAR(15),
    @MACAUTU NVARCHAR(10) = NULL, @LOAICAUTU NVARCHAR(50) = NULL,
    @SOBIENBAN NVARCHAR(30) = NULL, @NGAYBIENBAN DATE = NULL,
    @COQUANYEUCAU NVARCHAR(150) = NULL, @GHICHUPHAY NVARCHAR(500) = NULL
AS
BEGIN
    INSERT INTO HOSOKHAMBENH
    (MAHS,THOIGIANKHAM,KETLUAN,MATH,MABS,MACAUTU,LOAICAUTU,SOBIENBAN,NGAYBIENBAN,COQUANYEUCAU,GHICHUPHAY)
    VALUES(@MAHS,@THOIGIANKHAM,@KETLUAN,@MATH,@MABS,@MACAUTU,@LOAICAUTU,@SOBIENBAN,@NGAYBIENBAN,@COQUANYEUCAU,@GHICHUPHAY)

    UPDATE THIHAI SET TRANGTHAI = N'Đang khám nghiệm' WHERE MATH = @MATH
    UPDATE CANH_BAO SET DAOC = 1 WHERE MATH = @MATH AND LOAICB = N'ChuaKham' AND DAOC = 0
END
GO

CREATE PROC SP_SuaHoSoKhamBenh
    @MAHS VARCHAR(15), @THOIGIANKHAM DATE, @KETLUAN NVARCHAR(50),
    @MATH VARCHAR(15), @MABS VARCHAR(15)
AS
BEGIN
    UPDATE HOSOKHAMBENH
    SET THOIGIANKHAM=@THOIGIANKHAM,KETLUAN=@KETLUAN,MATH=@MATH,MABS=@MABS
    WHERE MAHS=@MAHS
END
GO

CREATE PROC SP_SuaHoSoKhamBenh_V2
    @MAHS VARCHAR(15), @THOIGIANKHAM DATE, @KETLUAN NVARCHAR(50),
    @MATH VARCHAR(15), @MABS VARCHAR(15),
    @MACAUTU NVARCHAR(10) = NULL, @LOAICAUTU NVARCHAR(50) = NULL,
    @SOBIENBAN NVARCHAR(30) = NULL, @NGAYBIENBAN DATE = NULL,
    @COQUANYEUCAU NVARCHAR(150) = NULL, @GHICHUPHAY NVARCHAR(500) = NULL
AS
BEGIN
    UPDATE HOSOKHAMBENH
    SET THOIGIANKHAM=@THOIGIANKHAM,KETLUAN=@KETLUAN,MATH=@MATH,MABS=@MABS,
        MACAUTU=@MACAUTU,LOAICAUTU=@LOAICAUTU,SOBIENBAN=@SOBIENBAN,
        NGAYBIENBAN=@NGAYBIENBAN,COQUANYEUCAU=@COQUANYEUCAU,GHICHUPHAY=@GHICHUPHAY
    WHERE MAHS=@MAHS
END
GO

CREATE PROC SP_XoaHoSoKhamBenh @MAHS VARCHAR(15) AS
BEGIN
    BEGIN TRANSACTION
        -- TRG_BaoVeHoSoPhapY sẽ bảo vệ, nhưng SP vẫn cần tồn tại cho phân quyền
        DELETE FROM HOSOKHAMBENH WHERE MAHS=@MAHS
    COMMIT TRANSACTION
END
GO

CREATE PROC SP_PhanCongBacSi
    @MATH VARCHAR(15), @MABS VARCHAR(15), @MAHS VARCHAR(15), @THOIGIANKHAM DATE
AS
BEGIN
    -- Kiểm tra bác sĩ đã đủ 3 ca hôm nay chưa
    IF (SELECT COUNT(*) FROM HOSOKHAMBENH
        WHERE MABS = @MABS AND THOIGIANKHAM = @THOIGIANKHAM) >= 3
    BEGIN
        PRINT N'Bác sĩ đã đủ 3 ca hôm nay, không thể phân công thêm!'
        RETURN
    END
    EXEC SP_ThemHoSoKhamBenh_V2
        @MAHS=@MAHS, @THOIGIANKHAM=@THOIGIANKHAM,
        @KETLUAN=NULL, @MATH=@MATH, @MABS=@MABS
END
GO

-- ── 6.E DỊCH VỤ ─────────────────────────────────────────────
CREATE PROC SP_DSDichVu AS
BEGIN SELECT * FROM VIEW_DichVu END
GO

CREATE PROC SP_ThemDichVu
    @MADV VARCHAR(15), @TENDV NVARCHAR(100), @GIA MONEY
AS
BEGIN INSERT INTO DICHVU VALUES(@MADV,@TENDV,@GIA) END
GO

CREATE PROC SP_SuaDichVu
    @MADV VARCHAR(15), @TENDV NVARCHAR(100), @GIA MONEY
AS
BEGIN
    UPDATE DICHVU SET TENDV=@TENDV, GIATIEN=@GIA WHERE MADV=@MADV
END
GO

CREATE PROC SP_XoaDichVu @MADV VARCHAR(15) AS
BEGIN
    BEGIN TRANSACTION DELETE FROM DICHVU WHERE MADV=@MADV COMMIT TRANSACTION
END
GO

CREATE PROC SP_DichVuE AS BEGIN SELECT * FROM VIEW_DichVuE END
GO

-- ── 6.F SỬ DỤNG DỊCH VỤ ────────────────────────────────────
CREATE PROC SP_DSDichVuSuDung AS BEGIN SELECT * FROM VIEW_DichVuSuDung END
GO

CREATE PROC SP_ThemDichVuSudung
    @MATH VARCHAR(15), @MADV VARCHAR(15), @NGAYSD DATE, @GHICHU NVARCHAR(200)
AS
BEGIN INSERT INTO SUDUNG VALUES(@MATH,@MADV,@NGAYSD,@GHICHU) END
GO

CREATE PROC SP_SuaDichVuSudung
    @MATH VARCHAR(15), @MADV VARCHAR(15), @NGAYSD DATE, @GHICHU NVARCHAR(200)
AS
BEGIN
    UPDATE SUDUNG SET NGAYSUDUNG=@NGAYSD, GHICHU=@GHICHU
    WHERE MATH=@MATH AND MADV=@MADV
END
GO

CREATE PROC SP_XoaDichVuSuDung
    @MATH VARCHAR(15), @MADV VARCHAR(15), @NGAYSD DATE
AS
BEGIN
    BEGIN TRANSACTION
        DELETE FROM SUDUNG WHERE MATH=@MATH AND MADV=@MADV AND NGAYSUDUNG=@NGAYSD
    COMMIT TRANSACTION
END
GO

CREATE PROCEDURE sp_TinhTongTienDichVu
    @MaTH VARCHAR(15), @TongTien MONEY OUTPUT
AS
BEGIN
    SELECT @TongTien = ISNULL(SUM(DV.GIATIEN), 0)
    FROM SUDUNG SD
    JOIN DICHVU DV ON SD.MADV = DV.MADV
    WHERE SD.MATH = @MaTH
END
GO

-- ── 6.G THÂN NHÂN ───────────────────────────────────────────
CREATE PROC SP_DSThanNhan @MATH VARCHAR(15) AS
BEGIN
    SELECT * FROM VIEW_ThanNhanThiHai WHERE MATH = @MATH ORDER BY LALIENDHE DESC
END
GO

CREATE PROC SP_ThemThanNhan
    @MATN VARCHAR(15), @MATH VARCHAR(15), @HOTEN_TN NVARCHAR(100),
    @QUANHE NVARCHAR(50), @DIENTHOAI VARCHAR(15), @DIACHI NVARCHAR(200),
    @LALIENDHE BIT, @GHICHU NVARCHAR(200)
AS
BEGIN
    IF @LALIENDHE = 1
        UPDATE THAN_NHAN SET LALIENDHE = 0 WHERE MATH = @MATH
    INSERT INTO THAN_NHAN(MATN,MATH,HOTEN_TN,QUANHE,DIENTHOAI,DIACHI,LALIENDHE,GHICHU)
    VALUES(@MATN,@MATH,@HOTEN_TN,@QUANHE,@DIENTHOAI,@DIACHI,@LALIENDHE,@GHICHU)
END
GO

CREATE PROC SP_SuaThanNhan
    @MATN VARCHAR(15), @HOTEN_TN NVARCHAR(100), @QUANHE NVARCHAR(50),
    @DIENTHOAI VARCHAR(15), @DIACHI NVARCHAR(200), @LALIENDHE BIT, @GHICHU NVARCHAR(200)
AS
BEGIN
    DECLARE @MATH VARCHAR(15)
    SELECT @MATH = MATH FROM THAN_NHAN WHERE MATN = @MATN
    IF @LALIENDHE = 1
        UPDATE THAN_NHAN SET LALIENDHE = 0 WHERE MATH = @MATH AND MATN <> @MATN
    UPDATE THAN_NHAN
    SET HOTEN_TN=@HOTEN_TN, QUANHE=@QUANHE, DIENTHOAI=@DIENTHOAI,
        DIACHI=@DIACHI, LALIENDHE=@LALIENDHE, GHICHU=@GHICHU
    WHERE MATN=@MATN
END
GO

CREATE PROC SP_XoaThanNhan @MATN VARCHAR(15) AS
BEGIN DELETE FROM THAN_NHAN WHERE MATN=@MATN END
GO

-- ── 6.H HÓA ĐƠN ─────────────────────────────────────────────
CREATE PROC SP_DSHoaDon AS
BEGIN SELECT * FROM VIEW_HoaDonChiTiet ORDER BY NGAYLAP DESC END
GO

CREATE PROC SP_ThemHoaDon
    @MAHD VARCHAR(15), @MATH VARCHAR(15), @NGAYLAP DATE,
    @PHUONGTHUCTT NVARCHAR(30), @GHICHU NVARCHAR(200)
AS
BEGIN
    DECLARE @TongTien MONEY
    EXEC sp_TinhTongTienDichVu @MATH, @TongTien OUTPUT
    INSERT INTO HOADON(MAHD,MATH,NGAYLAP,TONGTIEN,TRANGTHAITT,PHUONGTHUCTT,NGUOILAP,GHICHU)
    VALUES(@MAHD,@MATH,@NGAYLAP,@TongTien,N'Chưa thanh toán',@PHUONGTHUCTT,SUSER_SNAME(),@GHICHU)
END
GO

CREATE PROC SP_ThanhToanHoaDon
    @MAHD VARCHAR(15), @PHUONGTHUCTT NVARCHAR(30)
AS
BEGIN
    UPDATE HOADON
    SET TRANGTHAITT=N'Đã thanh toán', PHUONGTHUCTT=@PHUONGTHUCTT,
        NGAYTHANHTOAN=CAST(GETDATE() AS DATE)
    WHERE MAHD=@MAHD
END
GO

CREATE PROC SP_HoaDonTheoThiHai @MATH VARCHAR(15) AS
BEGIN SELECT * FROM VIEW_HoaDonChiTiet WHERE MATH=@MATH END
GO

-- ── 6.I BÀN GIAO THI HÀI (QUY TRÌNH TỔNG THỂ) ──────────────
CREATE PROC SP_BanGiaoThiHai @MATH VARCHAR(15) AS
BEGIN
    -- 1. Kiểm tra hóa đơn đã thanh toán
    IF dbo.FN_KiemTraHoaDonDuocThanhToan(@MATH) = 0
    BEGIN
        PRINT N'Chưa thể bàn giao: Hóa đơn chưa được thanh toán!'
        RETURN
    END
    -- 2. Cập nhật trạng thái thi hài
    EXEC SP_CapNhatTrangThaiThiHai @MATH, N'Đã bàn giao'
    -- 3. Giải phóng ngăn kéo (trigger TRG_CapNhatTrangThaiThiHai sẽ set NULL)
    UPDATE NGANKEO SET MATH = NULL WHERE MATH = @MATH
    PRINT N'Đã bàn giao thi hài ' + @MATH + N' thành công.'
END
GO

-- ── 6.J CẢNH BÁO ────────────────────────────────────────────
CREATE PROC SP_DSCanhBao AS
BEGIN SELECT * FROM VIEW_CanhBaoChuaDoc ORDER BY MUC_DO_UU_TIEN, THOIGIAN DESC END
GO

CREATE PROC SP_DocCanhBao @MACB INT AS
BEGIN UPDATE CANH_BAO SET DAOC = 1 WHERE MACB=@MACB END
GO

CREATE PROC SP_DocHetCanhBao AS
BEGIN UPDATE CANH_BAO SET DAOC = 1 WHERE DAOC = 0 END
GO

CREATE PROC SP_QuetCanhBao AS
BEGIN
    SET NOCOUNT ON
    -- Cảnh báo sắp quá hạn
    INSERT INTO CANH_BAO(LOAICB, MATH, NOIDUNG)
    SELECT N'QuaHan', th.MATH,
           N'Thi hài ' + ISNULL(th.HOTEN_TH,th.MATH)
           + N' sắp quá hạn! Còn '
           + CAST(15 - DATEDIFF(DAY,th.NGAYMAT,GETDATE()) AS NVARCHAR(5)) + N' ngày.'
    FROM THIHAI th
    WHERE DATEDIFF(DAY,th.NGAYMAT,GETDATE()) BETWEEN 12 AND 15
      AND th.MATH NOT IN (SELECT MATH FROM NGANKEO WHERE MATH IS NOT NULL)
      AND NOT EXISTS (SELECT 1 FROM CANH_BAO cb WHERE cb.MATH=th.MATH AND cb.LOAICB=N'QuaHan' AND cb.DAOC=0)

    -- Cảnh báo chưa khám sau 3 ngày
    INSERT INTO CANH_BAO(LOAICB, MATH, NOIDUNG)
    SELECT N'ChuaKham', th.MATH,
           N'Thi hài ' + ISNULL(th.HOTEN_TH,th.MATH)
           + N' chưa được khám nghiệm sau '
           + CAST(DATEDIFF(DAY,th.NGAYMAT,GETDATE()) AS NVARCHAR(5)) + N' ngày.'
    FROM THIHAI th
    WHERE DATEDIFF(DAY,th.NGAYMAT,GETDATE()) > 3
      AND th.MATH NOT IN (SELECT MATH FROM HOSOKHAMBENH)
      AND NOT EXISTS (SELECT 1 FROM CANH_BAO cb WHERE cb.MATH=th.MATH AND cb.LOAICB=N'ChuaKham' AND cb.DAOC=0)

    SELECT COUNT(*) AS SoCanhBaoMoi FROM CANH_BAO WHERE DAOC=0
END
GO

-- ── 6.K BÁO CÁO & DASHBOARD ─────────────────────────────────
CREATE PROC SP_Dashboard AS BEGIN SELECT * FROM VIEW_Dashboard END
GO

CREATE PROC SP_BaoCao_ThiHaiTheoThang @Nam INT = NULL AS
BEGIN
    SET @Nam = ISNULL(@Nam, YEAR(GETDATE()))
    SELECT * FROM VIEW_ThongKe_TheoThang WHERE Nam=@Nam ORDER BY Thang
END
GO

CREATE PROC SP_BaoCao_DoanhThuTheoThang @Nam INT = NULL AS
BEGIN
    SET @Nam = ISNULL(@Nam, YEAR(GETDATE()))
    SELECT * FROM VIEW_ThongKe_DoanhThu WHERE Nam=@Nam ORDER BY Thang
END
GO

CREATE PROC SP_ThongKeNganKeo AS
BEGIN
    SELECT
        (SELECT COUNT(*) FROM NGANKEO) AS TongNgan,
        (SELECT COUNT(*) FROM NGANKEO WHERE MATH IS NOT NULL) AS DangDung,
        (SELECT COUNT(*) FROM NGANKEO WHERE MATH IS NULL) AS ConTrong,
        CAST((SELECT COUNT(*) FROM NGANKEO WHERE MATH IS NOT NULL) * 100.0
             / NULLIF((SELECT COUNT(*) FROM NGANKEO),0) AS DECIMAL(5,2)) AS PhanTramLapDay,
        (SELECT AVG(NHIETDO) FROM NGANKEO WHERE MATH IS NOT NULL) AS NhietDoTB
END
GO

-- ── 6.L AUDIT LOG ───────────────────────────────────────────
CREATE PROC SP_XemAuditLog
    @TENTABLE NVARCHAR(50) = NULL,
    @TuNgay DATE = NULL, @DenNgay DATE = NULL, @SoLuong INT = 200
AS
BEGIN
    SELECT TOP (@SoLuong)
        MALOG, THOIGIAN, TENUSER, TENTABLE, HANHDOG, MABANGHI, NOIDUNG
    FROM AUDIT_LOG
    WHERE (@TENTABLE IS NULL OR TENTABLE=@TENTABLE)
      AND (@TuNgay IS NULL OR CAST(THOIGIAN AS DATE) >= @TuNgay)
      AND (@DenNgay IS NULL OR CAST(THOIGIAN AS DATE) <= @DenNgay)
    ORDER BY THOIGIAN DESC
END
GO

CREATE PROC SP_XoaAuditLogCu @SoNgayGiu INT = 90 AS
BEGIN
    DELETE FROM AUDIT_LOG
    WHERE DATEDIFF(DAY, THOIGIAN, GETDATE()) > @SoNgayGiu
    PRINT N'Đã xóa log cũ hơn ' + CAST(@SoNgayGiu AS NVARCHAR(5)) + N' ngày.'
END
GO

-- ── 6.M PHÂN QUYỀN ĐỘNG ─────────────────────────────────────
CREATE PROC SP_KiemTraQuyenHan AS
BEGIN
    IF (IS_ROLEMEMBER('QL_ADMIN') = 1 OR IS_ROLEMEMBER('db_owner') = 1)
        SELECT 'Admin' AS QuyenHan
    ELSE IF (IS_ROLEMEMBER('QL_BACSI') = 1 OR IS_ROLEMEMBER('QL_NHANVIEN') = 1)
        SELECT 'Staff' AS QuyenHan
    ELSE
        SELECT 'ReadOnly' AS QuyenHan
END
GO

CREATE PROCEDURE SP_DanhSachUser AS
BEGIN
    SELECT dp.name AS TenUser, dp.type_desc AS LoaiUser,
           ISNULL(sp.name,'(No Login)') AS TenLogin, dp.create_date AS NgayTao
    FROM sys.database_principals dp
    LEFT JOIN sys.server_principals sp ON dp.sid = sp.sid
    WHERE dp.type IN ('S','U','G')
      AND dp.name NOT IN ('dbo','guest','INFORMATION_SCHEMA','sys')
      AND dp.name NOT LIKE '##%'
    ORDER BY dp.name
END
GO

CREATE PROCEDURE SP_DanhSachRole AS
BEGIN
    SELECT name AS TenRole, type_desc AS LoaiRole, create_date AS NgayTao
    FROM sys.database_principals
    WHERE type = 'R' AND is_fixed_role = 0 AND name NOT IN ('public')
    ORDER BY name
END
GO

CREATE PROCEDURE SP_UserTrongRole @TenRole NVARCHAR(128) AS
BEGIN
    SELECT u.name AS TenUser, u.type_desc AS LoaiUser
    FROM sys.database_role_members rm
    JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
    JOIN sys.database_principals u ON rm.member_principal_id = u.principal_id
    WHERE r.name = @TenRole ORDER BY u.name
END
GO

CREATE PROCEDURE SP_GrantUserVaoRole
    @TenUser NVARCHAR(128), @TenRole NVARCHAR(128)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX) = N'ALTER ROLE [' + @TenRole + N'] ADD MEMBER [' + @TenUser + N']'
    EXEC sp_executesql @sql
END
GO

CREATE PROCEDURE SP_RevokeUserKhoiRole
    @TenUser NVARCHAR(128), @TenRole NVARCHAR(128)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX) = N'ALTER ROLE [' + @TenRole + N'] DROP MEMBER [' + @TenUser + N']'
    EXEC sp_executesql @sql
END
GO

-- ============================================================
-- 7. PHÂN QUYỀN
-- ============================================================

-- 7.1 Tạo 3 role
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name='QL_ADMIN'    AND type='R') CREATE ROLE [QL_ADMIN]
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name='QL_NHANVIEN' AND type='R') CREATE ROLE [QL_NHANVIEN]
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name='QL_BACSI'    AND type='R') CREATE ROLE [QL_BACSI]
GO

-- 7.2 QL_ADMIN — toàn quyền tất cả bảng
GRANT SELECT,INSERT,UPDATE,DELETE ON THIHAI      TO [QL_ADMIN] WITH GRANT OPTION
GRANT SELECT,INSERT,UPDATE,DELETE ON BACSI        TO [QL_ADMIN] WITH GRANT OPTION
GRANT SELECT,INSERT,UPDATE,DELETE ON DICHVU       TO [QL_ADMIN] WITH GRANT OPTION
GRANT SELECT,INSERT,UPDATE,DELETE ON NGANKEO      TO [QL_ADMIN] WITH GRANT OPTION
GRANT SELECT,INSERT,UPDATE,DELETE ON HOSOKHAMBENH TO [QL_ADMIN] WITH GRANT OPTION
GRANT SELECT,INSERT,UPDATE,DELETE ON SUDUNG       TO [QL_ADMIN] WITH GRANT OPTION
GRANT SELECT,INSERT,UPDATE,DELETE ON NHANVIEN     TO [QL_ADMIN] WITH GRANT OPTION
GRANT SELECT,INSERT,UPDATE,DELETE ON THAN_NHAN    TO [QL_ADMIN] WITH GRANT OPTION
GRANT SELECT,INSERT,UPDATE,DELETE ON HOADON       TO [QL_ADMIN] WITH GRANT OPTION
GRANT SELECT,INSERT,UPDATE,DELETE ON CANH_BAO     TO [QL_ADMIN] WITH GRANT OPTION
GRANT SELECT ON AUDIT_LOG                         TO [QL_ADMIN]
GO

-- QL_ADMIN — execute tất cả SP
GRANT EXECUTE ON SP_DSBacSi                  TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThemBacSi                TO [QL_ADMIN]
GRANT EXECUTE ON SP_SuaBacSi                 TO [QL_ADMIN]
GRANT EXECUTE ON SP_XoaBacSi                 TO [QL_ADMIN]
GRANT EXECUTE ON SP_BSLaoLang                TO [QL_ADMIN]
GRANT EXECUTE ON SP_TimKiemBacSi             TO [QL_ADMIN]
GRANT EXECUTE ON SP_DSThiHai                 TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThemThiHai               TO [QL_ADMIN]
GRANT EXECUTE ON SP_SuaThiHai                TO [QL_ADMIN]
GRANT EXECUTE ON SP_XoaThiHai                TO [QL_ADMIN]
GRANT EXECUTE ON SP_CapNhatTrangThaiThiHai   TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThiHaiSot                TO [QL_ADMIN]
GRANT EXECUTE ON SP_DemThiHai                TO [QL_ADMIN]
GRANT EXECUTE ON SP_DonDepThiHaiQuaHan       TO [QL_ADMIN]
GRANT EXECUTE ON SP_TimKiemThiHai            TO [QL_ADMIN]
GRANT EXECUTE ON SP_BanGiaoThiHai            TO [QL_ADMIN]
GRANT EXECUTE ON SP_DSNganKeo                TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThemNganKeo              TO [QL_ADMIN]
GRANT EXECUTE ON SP_SuaNganKeo               TO [QL_ADMIN]
GRANT EXECUTE ON SP_XoaNganKeo               TO [QL_ADMIN]
GRANT EXECUTE ON SP_XepNganKeo               TO [QL_ADMIN]
GRANT EXECUTE ON SP_DSHoSoKhamNghiem         TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThemHoSoKhamBenh         TO [QL_ADMIN]
GRANT EXECUTE ON SP_SuaHoSoKhamBenh          TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThemHoSoKhamBenh_V2      TO [QL_ADMIN]
GRANT EXECUTE ON SP_SuaHoSoKhamBenh_V2       TO [QL_ADMIN]
GRANT EXECUTE ON SP_XoaHoSoKhamBenh          TO [QL_ADMIN]
GRANT EXECUTE ON SP_PhanCongBacSi            TO [QL_ADMIN]
GRANT EXECUTE ON SP_DSDichVu                 TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThemDichVu               TO [QL_ADMIN]
GRANT EXECUTE ON SP_SuaDichVu                TO [QL_ADMIN]
GRANT EXECUTE ON SP_XoaDichVu                TO [QL_ADMIN]
GRANT EXECUTE ON SP_DichVuE                  TO [QL_ADMIN]
GRANT EXECUTE ON SP_DSDichVuSuDung           TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThemDichVuSudung         TO [QL_ADMIN]
GRANT EXECUTE ON SP_SuaDichVuSudung          TO [QL_ADMIN]
GRANT EXECUTE ON SP_XoaDichVuSuDung          TO [QL_ADMIN]
GRANT EXECUTE ON sp_TinhTongTienDichVu       TO [QL_ADMIN]
GRANT EXECUTE ON SP_DSThanNhan               TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThemThanNhan             TO [QL_ADMIN]
GRANT EXECUTE ON SP_SuaThanNhan              TO [QL_ADMIN]
GRANT EXECUTE ON SP_XoaThanNhan              TO [QL_ADMIN]
GRANT EXECUTE ON SP_DSHoaDon                 TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThemHoaDon               TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThanhToanHoaDon          TO [QL_ADMIN]
GRANT EXECUTE ON SP_HoaDonTheoThiHai         TO [QL_ADMIN]
GRANT EXECUTE ON SP_DSCanhBao                TO [QL_ADMIN]
GRANT EXECUTE ON SP_DocCanhBao               TO [QL_ADMIN]
GRANT EXECUTE ON SP_DocHetCanhBao            TO [QL_ADMIN]
GRANT EXECUTE ON SP_QuetCanhBao              TO [QL_ADMIN]
GRANT EXECUTE ON SP_Dashboard                TO [QL_ADMIN]
GRANT EXECUTE ON SP_BaoCao_ThiHaiTheoThang   TO [QL_ADMIN]
GRANT EXECUTE ON SP_BaoCao_DoanhThuTheoThang TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThongKeNganKeo           TO [QL_ADMIN]
GRANT EXECUTE ON SP_XemAuditLog              TO [QL_ADMIN]
GRANT EXECUTE ON SP_XoaAuditLogCu            TO [QL_ADMIN]
GRANT EXECUTE ON SP_DanhSachUser             TO [QL_ADMIN]
GRANT EXECUTE ON SP_DanhSachRole             TO [QL_ADMIN]
GRANT EXECUTE ON SP_UserTrongRole            TO [QL_ADMIN]
GRANT EXECUTE ON SP_GrantUserVaoRole         TO [QL_ADMIN]
GRANT EXECUTE ON SP_RevokeUserKhoiRole       TO [QL_ADMIN]
GRANT EXECUTE ON SP_KiemTraQuyenHan          TO [QL_ADMIN]
GO

-- 7.3 QL_NHANVIEN
GRANT SELECT ON THIHAI          TO [QL_NHANVIEN]
GRANT SELECT,INSERT,UPDATE,DELETE ON DICHVU       TO [QL_NHANVIEN]
GRANT SELECT,INSERT,UPDATE,DELETE ON SUDUNG       TO [QL_NHANVIEN]
GRANT SELECT,INSERT,UPDATE ON THAN_NHAN    TO [QL_NHANVIEN]
GRANT SELECT,INSERT,UPDATE ON HOADON       TO [QL_NHANVIEN]
GRANT SELECT,INSERT,UPDATE ON CANH_BAO     TO [QL_NHANVIEN]
GO
GRANT EXECUTE ON SP_DSThiHai               TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_ThemThiHai             TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_SuaThiHai              TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_XoaThiHai              TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_CapNhatTrangThaiThiHai TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_TimKiemThiHai          TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_BanGiaoThiHai          TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_XepNganKeo             TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_DSNganKeo              TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_DSDichVu               TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_ThemDichVu             TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_SuaDichVu              TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_XoaDichVu              TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_DSDichVuSuDung         TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_ThemDichVuSudung       TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_SuaDichVuSudung        TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_XoaDichVuSuDung        TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_DSThanNhan             TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_ThemThanNhan           TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_SuaThanNhan            TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_DSHoaDon               TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_ThemHoaDon             TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_ThanhToanHoaDon        TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_HoaDonTheoThiHai       TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_DSCanhBao              TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_DocCanhBao             TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_DocHetCanhBao          TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_QuetCanhBao            TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_Dashboard              TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_KiemTraQuyenHan        TO [QL_NHANVIEN]
GO

-- 7.4 QL_BACSI
GRANT SELECT,INSERT,UPDATE,DELETE ON THIHAI       TO [QL_BACSI]
GRANT SELECT,INSERT,UPDATE,DELETE ON NGANKEO      TO [QL_BACSI]
GRANT SELECT,INSERT,UPDATE,DELETE ON HOSOKHAMBENH TO [QL_BACSI]
GRANT SELECT ON DICHVU                             TO [QL_BACSI]
GRANT SELECT ON THAN_NHAN                          TO [QL_BACSI]
GRANT SELECT ON HOADON                             TO [QL_BACSI]
GRANT SELECT ON CANH_BAO                           TO [QL_BACSI]
GO
GRANT EXECUTE ON SP_DSThiHai                  TO [QL_BACSI]
GRANT EXECUTE ON SP_TimKiemThiHai             TO [QL_BACSI]
GRANT EXECUTE ON SP_DSHoSoKhamNghiem          TO [QL_BACSI]
GRANT EXECUTE ON SP_ThemHoSoKhamBenh_V2       TO [QL_BACSI]
GRANT EXECUTE ON SP_SuaHoSoKhamBenh_V2        TO [QL_BACSI]
GRANT EXECUTE ON SP_PhanCongBacSi             TO [QL_BACSI]
GRANT EXECUTE ON SP_DSNganKeo                 TO [QL_BACSI]
GRANT EXECUTE ON SP_DSThanNhan                TO [QL_BACSI]
GRANT EXECUTE ON SP_HoaDonTheoThiHai          TO [QL_BACSI]
GRANT EXECUTE ON SP_DSCanhBao                 TO [QL_BACSI]
GRANT EXECUTE ON SP_DocCanhBao                TO [QL_BACSI]
GRANT EXECUTE ON SP_Dashboard                 TO [QL_BACSI]
GRANT EXECUTE ON SP_KiemTraQuyenHan           TO [QL_BACSI]
GO

-- ============================================================
-- 8. BACKUP & RESTORE
-- ============================================================

USE QuanLyNhaXac
GO

-- 8.1 FULL BACKUP
IF OBJECT_ID('SP_FullBackup','P') IS NOT NULL DROP PROCEDURE SP_FullBackup
GO
CREATE PROCEDURE SP_FullBackup
    @BackupFolder NVARCHAR(500) = N'C:\QuanLyNhaXac_Backup\Full'
AS
BEGIN
    SET NOCOUNT ON
    IF (IS_ROLEMEMBER('db_owner') = 0 AND IS_ROLEMEMBER('QL_ADMIN') = 0)
    BEGIN RAISERROR(N'Chỉ Admin mới có thể thực hiện Backup.',16,1); RETURN END

    DECLARE @FileName NVARCHAR(600), @TimeStamp NVARCHAR(20)
    SET @TimeStamp = CONVERT(NVARCHAR(20),GETDATE(),112) + '_'
                   + REPLACE(CONVERT(NVARCHAR(8),GETDATE(),108),':','')
    SET @FileName  = @BackupFolder + N'\QuanLyNhaXac_Full_' + @TimeStamp + N'.bak'

    BEGIN TRY
        BACKUP DATABASE QuanLyNhaXac TO DISK = @FileName
        WITH NAME=N'FULL Backup - QuanLyNhaXac', COMPRESSION, CHECKSUM, STATS=10
        PRINT N'FULL BACKUP thành công: ' + @FileName
        SELECT N'FULL' AS LoaiBackup, @FileName AS DuongDan, GETDATE() AS ThoiGian,
               SUSER_SNAME() AS NguoiThucHien, N'Thành công' AS TrangThai
    END TRY
    BEGIN CATCH
        DECLARE @Err NVARCHAR(2048) = ERROR_MESSAGE()
        RAISERROR(N'LỖI FULL BACKUP: %s',16,1,@Err)
    END CATCH
END
GO

-- 8.2 DIFFERENTIAL BACKUP
IF OBJECT_ID('SP_DiffBackup','P') IS NOT NULL DROP PROCEDURE SP_DiffBackup
GO
CREATE PROCEDURE SP_DiffBackup
    @BackupFolder NVARCHAR(500) = N'C:\QuanLyNhaXac_Backup\Diff'
AS
BEGIN
    SET NOCOUNT ON
    IF (IS_ROLEMEMBER('db_owner')=0 AND IS_ROLEMEMBER('QL_ADMIN')=0)
    BEGIN RAISERROR(N'Chỉ Admin mới có thể thực hiện Backup.',16,1); RETURN END
    IF NOT EXISTS (SELECT 1 FROM msdb.dbo.backupset WHERE database_name=N'QuanLyNhaXac' AND type='D')
    BEGIN RAISERROR(N'Chưa có FULL BACKUP. Hãy chạy SP_FullBackup trước.',16,1); RETURN END

    DECLARE @FileName NVARCHAR(600), @TimeStamp NVARCHAR(20)
    SET @TimeStamp = CONVERT(NVARCHAR(20),GETDATE(),112) + '_'
                   + REPLACE(CONVERT(NVARCHAR(8),GETDATE(),108),':','')
    SET @FileName  = @BackupFolder + N'\QuanLyNhaXac_Diff_' + @TimeStamp + N'.bak'

    BEGIN TRY
        BACKUP DATABASE QuanLyNhaXac TO DISK = @FileName
        WITH DIFFERENTIAL, NAME=N'DIFF Backup - QuanLyNhaXac', COMPRESSION, CHECKSUM, STATS=10
        PRINT N'DIFFERENTIAL BACKUP thành công: ' + @FileName
        SELECT N'DIFFERENTIAL' AS LoaiBackup, @FileName AS DuongDan, GETDATE() AS ThoiGian,
               SUSER_SNAME() AS NguoiThucHien, N'Thành công' AS TrangThai
    END TRY
    BEGIN CATCH
        DECLARE @Err NVARCHAR(2048) = ERROR_MESSAGE()
        RAISERROR(N'LỖI DIFF BACKUP: %s',16,1,@Err)
    END CATCH
END
GO

-- 8.3 TRANSACTION LOG BACKUP
IF OBJECT_ID('SP_LogBackup','P') IS NOT NULL DROP PROCEDURE SP_LogBackup
GO
CREATE PROCEDURE SP_LogBackup
    @BackupFolder NVARCHAR(500) = N'C:\QuanLyNhaXac_Backup\Log'
AS
BEGIN
    SET NOCOUNT ON
    IF (IS_ROLEMEMBER('db_owner')=0 AND IS_ROLEMEMBER('QL_ADMIN')=0)
    BEGIN RAISERROR(N'Chỉ Admin mới có thể thực hiện Backup.',16,1); RETURN END

    DECLARE @RecoveryModel NVARCHAR(20)
    SELECT @RecoveryModel = recovery_model_desc FROM sys.databases WHERE name=N'QuanLyNhaXac'
    IF @RecoveryModel = N'SIMPLE'
    BEGIN RAISERROR(N'Database dùng SIMPLE model. Hãy chuyển sang FULL recovery model.',16,1); RETURN END
    IF NOT EXISTS (SELECT 1 FROM msdb.dbo.backupset WHERE database_name=N'QuanLyNhaXac' AND type='D')
    BEGIN RAISERROR(N'Chưa có FULL BACKUP. Hãy chạy SP_FullBackup trước.',16,1); RETURN END

    DECLARE @FileName NVARCHAR(600), @TimeStamp NVARCHAR(20)
    SET @TimeStamp = CONVERT(NVARCHAR(20),GETDATE(),112) + '_'
                   + REPLACE(CONVERT(NVARCHAR(8),GETDATE(),108),':','')
    SET @FileName  = @BackupFolder + N'\QuanLyNhaXac_Log_' + @TimeStamp + N'.trn'

    BEGIN TRY
        BACKUP LOG QuanLyNhaXac TO DISK = @FileName
        WITH NAME=N'LOG Backup - QuanLyNhaXac', COMPRESSION, CHECKSUM, STATS=10
        PRINT N'LOG BACKUP thành công: ' + @FileName
        SELECT N'TRANSACTION LOG' AS LoaiBackup, @FileName AS DuongDan, GETDATE() AS ThoiGian,
               SUSER_SNAME() AS NguoiThucHien, N'Thành công' AS TrangThai
    END TRY
    BEGIN CATCH
        DECLARE @Err NVARCHAR(2048) = ERROR_MESSAGE()
        RAISERROR(N'LỖI LOG BACKUP: %s',16,1,@Err)
    END CATCH
END
GO

-- 8.4 RESTORE DATABASE
IF OBJECT_ID('SP_RestoreDatabase','P') IS NOT NULL DROP PROCEDURE SP_RestoreDatabase
GO
CREATE PROCEDURE SP_RestoreDatabase
    @BackupFile  NVARCHAR(600),
    @WithRecovery BIT = 1
AS
BEGIN
    SET NOCOUNT ON
    IF IS_SRVROLEMEMBER('sysadmin')=0 AND IS_SRVROLEMEMBER('dbcreator')=0
    BEGIN RAISERROR(N'Cần quyền sysadmin hoặc dbcreator để Restore.',16,1); RETURN END

    DECLARE @FileExists INT = 0
    EXEC master.dbo.xp_fileexist @BackupFile, @FileExists OUTPUT
    IF @FileExists = 0
    BEGIN RAISERROR(N'Không tìm thấy file: %s',16,1,@BackupFile); RETURN END

    DECLARE @RecoveryOpt NVARCHAR(20) = CASE WHEN @WithRecovery=1 THEN 'RECOVERY' ELSE 'NORECOVERY' END
    DECLARE @Sql NVARCHAR(MAX)

    BEGIN TRY
        SET @Sql = N'ALTER DATABASE QuanLyNhaXac SET SINGLE_USER WITH ROLLBACK IMMEDIATE'
        EXEC sp_executesql @Sql

        IF @BackupFile LIKE N'%.trn'
            SET @Sql = N'RESTORE LOG QuanLyNhaXac FROM DISK=N''' + @BackupFile
                      + N''' WITH ' + @RecoveryOpt + N', CHECKSUM, STATS=10'
        ELSE
            SET @Sql = N'RESTORE DATABASE QuanLyNhaXac FROM DISK=N''' + @BackupFile
                      + N''' WITH ' + @RecoveryOpt + N', REPLACE, CHECKSUM, STATS=10'
        EXEC sp_executesql @Sql

        IF @WithRecovery = 1
        BEGIN
            SET @Sql = N'ALTER DATABASE QuanLyNhaXac SET MULTI_USER'
            EXEC sp_executesql @Sql
        END
        PRINT N'RESTORE thành công từ: ' + @BackupFile
        SELECT N'RESTORE' AS LoaiRestore, @BackupFile AS FileNguon, GETDATE() AS ThoiGian,
               SUSER_SNAME() AS NguoiThucHien, @RecoveryOpt AS TuyChon, N'Thành công' AS TrangThai
    END TRY
    BEGIN CATCH
        BEGIN TRY EXEC sp_executesql N'ALTER DATABASE QuanLyNhaXac SET MULTI_USER' END TRY BEGIN CATCH END CATCH
        DECLARE @Err NVARCHAR(2048) = ERROR_MESSAGE()
        RAISERROR(N'LỖI RESTORE: %s',16,1,@Err)
    END CATCH
END
GO

-- 8.5 KIỂM TRA TÍNH TOÀN VẸN FILE BACKUP
IF OBJECT_ID('SP_KiemTraTinhToanVenBackup','P') IS NOT NULL DROP PROCEDURE SP_KiemTraTinhToanVenBackup
GO
CREATE PROCEDURE SP_KiemTraTinhToanVenBackup @BackupFile NVARCHAR(600) AS
BEGIN
    BEGIN TRY
        RESTORE VERIFYONLY FROM DISK = @BackupFile WITH CHECKSUM
        PRINT N'File backup hợp lệ: ' + @BackupFile
        SELECT N'Hợp lệ' AS TrangThai, @BackupFile AS [File]
    END TRY
    BEGIN CATCH
        PRINT N'File backup bị lỗi: ' + @BackupFile
        SELECT N'Lỗi: ' + ERROR_MESSAGE() AS TrangThai, @BackupFile AS [File]
    END CATCH
END
GO

-- 8.6 LỊCH SỬ BACKUP
IF OBJECT_ID('SP_LichSuBackup','P') IS NOT NULL DROP PROCEDURE SP_LichSuBackup
GO
CREATE PROCEDURE SP_LichSuBackup @SoLuong INT = 50 AS
BEGIN
    SET NOCOUNT ON
    IF (IS_ROLEMEMBER('db_owner')=0 AND IS_ROLEMEMBER('QL_ADMIN')=0)
    BEGIN RAISERROR(N'Chỉ Admin mới có thể xem lịch sử Backup.',16,1); RETURN END

    SELECT TOP (@SoLuong)
        bs.backup_finish_date AS ThoiGianBackup,
        CASE bs.type WHEN 'D' THEN N'FULL' WHEN 'I' THEN N'DIFFERENTIAL'
                     WHEN 'L' THEN N'TRANSACTION LOG' ELSE bs.type END AS LoaiBackup,
        bmf.physical_device_name AS DuongDanFile,
        CAST(bs.backup_size/1024.0/1024.0 AS DECIMAL(10,2)) AS KichThuoc_MB,
        bs.user_name AS NguoiThucHien,
        CASE bs.has_backup_checksums WHEN 1 THEN N'Có' ELSE N'Không' END AS CoChecksum
    FROM msdb.dbo.backupset bs
    JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
    WHERE bs.database_name = N'QuanLyNhaXac'
    ORDER BY bs.backup_finish_date DESC
END
GO

-- 8.7 Cấp quyền Backup SP cho QL_ADMIN
USE QuanLyNhaXac
GO
GRANT EXECUTE ON SP_KiemTraTinhToanVenBackup TO [QL_ADMIN]
GRANT EXECUTE ON SP_LichSuBackup             TO [QL_ADMIN]
GO

-- ============================================================
-- 9. TẠO LOGIN & USER
-- ============================================================
USE master
GO

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name='NhaXacAdmin') DROP LOGIN [NhaXacAdmin]
GO
CREATE LOGIN [NhaXacAdmin] WITH PASSWORD=N'123456',
    DEFAULT_DATABASE=[QuanLyNhaXac], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

USE QuanLyNhaXac
GO
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name='NhaXacAdmin') DROP USER [NhaXacAdmin]
GO
CREATE USER [NhaXacAdmin] FOR LOGIN [NhaXacAdmin]
GO
ALTER ROLE [db_owner]  ADD MEMBER [NhaXacAdmin]
ALTER ROLE [QL_ADMIN]  ADD MEMBER [NhaXacAdmin]
GO

-- ============================================================
-- HOÀN THÀNH
-- ============================================================
PRINT N''
PRINT N'============================================================'
PRINT N'QuanLyNhaXac — SQL duy nhất đã triển khai thành công!'
PRINT N'  11 Bảng | 22 View | 10 Hàm | 18 Trigger | 60+ SP'
PRINT N'  3 Role  | 1 Login | Backup & Restore đầy đủ'
PRINT N'============================================================'
GO


-- =====================================================
-- SP_DSNhanVien — Danh sách tất cả nhân viên
-- =====================================================
CREATE PROC SP_DSNhanVien AS
BEGIN
    SELECT MANV, HOTEN_NV, CHUCVU, DIENTHOAI
    FROM NHANVIEN
    ORDER BY HOTEN_NV
END
GO

-- =====================================================
-- SP_ThemNhanVien — Thêm nhân viên mới
-- =====================================================
CREATE PROC SP_ThemNhanVien
    @MANV      VARCHAR(15),
    @HOTEN_NV  NVARCHAR(100),
    @CHUCVU    NVARCHAR(100),
    @DIENTHOAI VARCHAR(15)
AS
BEGIN
    INSERT INTO NHANVIEN (MANV, HOTEN_NV, CHUCVU, DIENTHOAI)
    VALUES (@MANV, @HOTEN_NV, @CHUCVU, @DIENTHOAI)
END
GO

-- =====================================================
-- SP_SuaNhanVien — Cập nhật thông tin nhân viên
-- =====================================================
CREATE PROC SP_SuaNhanVien
    @MANV      VARCHAR(15),
    @HOTEN_NV  NVARCHAR(100),
    @CHUCVU    NVARCHAR(100),
    @DIENTHOAI VARCHAR(15)
AS
BEGIN
    UPDATE NHANVIEN
    SET HOTEN_NV  = @HOTEN_NV,
        CHUCVU    = @CHUCVU,
        DIENTHOAI = @DIENTHOAI
    WHERE MANV = @MANV
END
GO

-- =====================================================
-- SP_XoaNhanVien — Xóa nhân viên theo mã
-- =====================================================
CREATE PROC SP_XoaNhanVien @MANV VARCHAR(15) AS
BEGIN
    DELETE FROM NHANVIEN WHERE MANV = @MANV
END
GO

-- =====================================================
-- Phân quyền (chỉ Admin được thao tác)
-- =====================================================
GRANT EXECUTE ON SP_DSNhanVien   TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThemNhanVien TO [QL_ADMIN]
GRANT EXECUTE ON SP_SuaNhanVien  TO [QL_ADMIN]
GRANT EXECUTE ON SP_XoaNhanVien  TO [QL_ADMIN]
GO

-- Staff chỉ đọc
GRANT EXECUTE ON SP_DSNhanVien   TO [QL_NHANVIEN]
GO

-- ============================================================
-- SPRINT 2 — SQL MIGRATION SCRIPT
-- Ngày: 2026-06-16
-- Mô tả: Các thay đổi DB cần thiết để hỗ trợ các task Sprint 2
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- S2-04: ALTER SP_SuaNganKeo để nhận thêm @nhietDoCanhBao
-- ────────────────────────────────────────────────────────────
-- Kiểm tra SP hiện tại trước khi ALTER
-- (Tham số @nhietDoCanhBao có DEFAULT NULL nên code cũ gọi
--  SP không truyền param này vẫn hoạt động bình thường)

ALTER PROCEDURE SP_SuaNganKeo
    @ma              VARCHAR(10),
    @vt              NVARCHAR(100)  = NULL,
    @nd              FLOAT          = NULL,
    @math            VARCHAR(15)    = NULL,
    @nhietDoCanhBao  FLOAT          = NULL     -- THÊM MỚI: S2-04
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE NGANKEO
    SET
        VITRI            = ISNULL(@vt, VITRI),
        NHIETDO          = ISNULL(@nd, NHIETDO),
        MATH             = @math,                          -- cho phép set NULL (xóa người nằm)
        NHIETDO_CANH_BAO = ISNULL(@nhietDoCanhBao, NHIETDO_CANH_BAO)
    WHERE MANGAN = @ma;
END
GO

-- ────────────────────────────────────────────────────────────
-- Kiểm tra: VIEW_ThongKe_NhanVien_HoaDon phải tồn tại
-- (Đã có trong schema gốc — không cần tạo lại)
-- ────────────────────────────────────────────────────────────
-- SELECT * FROM VIEW_ThongKe_NhanVien_HoaDon   -- test
-- SELECT * FROM VIEW_ThongKe_TheoThang          -- test
-- SELECT * FROM VIEW_ThongKe_DoanhThu           -- test

-- ────────────────────────────────────────────────────────────
-- Kiểm tra: SP_BaoCao_ThiHaiTheoThang và SP_BaoCao_DoanhThuTheoThang
-- (Đã có trong schema gốc — không cần tạo lại)
-- ────────────────────────────────────────────────────────────
-- EXEC SP_BaoCao_ThiHaiTheoThang 2025     -- test
-- EXEC SP_BaoCao_DoanhThuTheoThang 2025   -- test

-- ────────────────────────────────────────────────────────────
-- Xác nhận migration thành công
-- ────────────────────────────────────────────────────────────
PRINT 'Sprint 2 SQL Migration — Hoàn tất!';
PRINT 'SP_SuaNganKeo đã được ALTER thêm param @nhietDoCanhBao (DEFAULT NULL, backward-compatible).';
GO

-- ============================================================
-- SPRINT 3 — SQL Scripts
-- Chạy toàn bộ file này trên SQL Server trước khi build app
-- ============================================================

-- ─────────────────────────────────────────────
-- S3-01: Tìm Kiếm Toàn Hệ Thống (3 SP mới)
-- ─────────────────────────────────────────────

-- Tìm theo Thi Hài
IF OBJECT_ID('SP_TimKiem_ThiHai', 'P') IS NOT NULL DROP PROCEDURE SP_TimKiem_ThiHai;
GO
CREATE PROCEDURE SP_TimKiem_ThiHai
    @keyword NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 50
        MATH, HOTEN_TH, GIOITINH, NGAYSINH, NGAYMAT
    FROM THIHAI
    WHERE 
        HOTEN_TH    LIKE N'%' + @keyword + '%'
        OR MATH     LIKE N'%' + @keyword + '%'
    ORDER BY MATH;
END
GO

-- Tìm theo Thân Nhân
IF OBJECT_ID('SP_TimKiem_ThanNhan', 'P') IS NOT NULL DROP PROCEDURE SP_TimKiem_ThanNhan;
GO
CREATE PROCEDURE SP_TimKiem_ThanNhan
    @keyword NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 50
        TN.MATN,
        TN.HOTEN_TN,
        TN.DIENTHOAI,
        TN.MATH,
        TH.HOTEN_TH
    FROM THANNHAN TN
    LEFT JOIN THIHAI TH ON TN.MATH = TH.MATH
    WHERE
        TN.HOTEN_TN  LIKE N'%' + @keyword + '%'
        OR TN.MATN   LIKE N'%' + @keyword + '%'
        OR TN.DIENTHOAI LIKE N'%' + @keyword + '%'
        OR TN.MATH   LIKE N'%' + @keyword + '%'
    ORDER BY TN.MATN;
END
GO

-- Tìm theo Hóa Đơn
IF OBJECT_ID('SP_TimKiem_HoaDon', 'P') IS NOT NULL DROP PROCEDURE SP_TimKiem_HoaDon;
GO
CREATE PROCEDURE SP_TimKiem_HoaDon
    @keyword NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 50
        HD.MAHD,
        HD.MATH,
        HD.NGAYLAP,
        HD.TONGTIEN,
        HD.TRANGTHAITT  -- Điều chỉnh tên cột trạng thái nếu DB dùng tên khác (vd: TRANGTHAITT)
    FROM HOADON HD
    WHERE
        HD.MAHD  LIKE N'%' + @keyword + '%'
        OR HD.MATH LIKE N'%' + @keyword + '%'
    ORDER BY HD.NGAYLAP DESC;
END
GO


-- ─────────────────────────────────────────────
-- S3-02: Bổ sung NOITIMTHAY & COCUANHAN
-- ALTER SP_ThemThiHai và SP_SuaThiHai
-- ─────────────────────────────────────────────

-- Kiểm tra và thêm cột nếu chưa có
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'THIHAI' AND COLUMN_NAME = 'NOITIMTHAY'
)
BEGIN
    ALTER TABLE THIHAI ADD NOITIMTHAY NVARCHAR(255) NULL;
    PRINT 'Đã thêm cột NOITIMTHAY vào bảng THIHAI';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'THIHAI' AND COLUMN_NAME = 'COCUANHAN'
)
BEGIN
    ALTER TABLE THIHAI ADD COCUANHAN NVARCHAR(255) NULL;
    PRINT 'Đã thêm cột COCUANHAN vào bảng THIHAI';
END
GO

-- ALTER SP_ThemThiHai — thêm 2 param mới (có DEFAULT NULL để tương thích ngược)
IF OBJECT_ID('SP_ThemThiHai', 'P') IS NOT NULL DROP PROCEDURE SP_ThemThiHai;
GO
CREATE PROCEDURE SP_ThemThiHai
    @ma         NVARCHAR(10),
    @ten        NVARCHAR(100)   = NULL,
    @ns         DATE            = NULL,
    @nm         DATE            = NULL,
    @gt         NVARCHAR(10)    = NULL,
    @noiTimThay NVARCHAR(255)   = NULL,   -- S3-02
    @coCuaNhan  NVARCHAR(255)   = NULL    -- S3-02
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO THIHAI (MATH, HOTEN_TH, NGAYSINH, NGAYMAT, GIOITINH, NOITIMTHAY, COCUANHAN)
    VALUES (@ma, @ten, @ns, @nm, @gt, @noiTimThay, @coCuaNhan);
END
GO

-- ALTER SP_SuaThiHai — thêm 2 param mới
IF OBJECT_ID('SP_SuaThiHai', 'P') IS NOT NULL DROP PROCEDURE SP_SuaThiHai;
GO
CREATE PROCEDURE SP_SuaThiHai
    @ma         NVARCHAR(10),
    @ten        NVARCHAR(100)   = NULL,
    @ns         DATE            = NULL,
    @nm         DATE            = NULL,
    @gt         NVARCHAR(10)    = NULL,
    @noiTimThay NVARCHAR(255)   = NULL,   -- S3-02
    @coCuaNhan  NVARCHAR(255)   = NULL    -- S3-02
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE THIHAI
    SET
        HOTEN_TH    = @ten,
        NGAYSINH    = @ns,
        NGAYMAT     = @nm,
        GIOITINH    = @gt,
        NOITIMTHAY  = @noiTimThay,
        COCUANHAN   = @coCuaNhan
    WHERE MATH = @ma;
END
GO

-- Cập nhật SP_DSThiHai để trả về 2 cột mới
-- (Nếu SP này đang dùng SELECT *, bỏ qua bước này)
-- Kiểm tra cấu trúc SP_DSThiHai và thêm NOITIMTHAY, COCUANHAN nếu cần.
-- Ví dụ nếu cần ALTER:
/*
ALTER PROCEDURE SP_DSThiHai AS
BEGIN
    SELECT MATH, HOTEN_TH, NGAYSINH, NGAYMAT, GIOITINH,
           NOITIMTHAY, COCUANHAN,
           CASE
               WHEN DATEDIFF(YEAR, NGAYSINH, NGAYMAT) < 18 THEN N'Vị thành niên'
               WHEN DATEDIFF(YEAR, NGAYSINH, NGAYMAT) <= 59 THEN N'Trưởng thành'
               ELSE N'Cao tuổi'
           END AS NHOMTUOI
    FROM THIHAI
    ORDER BY MATH;
END
*/


-- ─────────────────────────────────────────────
-- S3-03: Lịch Bảo Trì Ngăn Kéo
-- SP_CapNhat_NgayBaoTri (mới)
-- ─────────────────────────────────────────────

-- Kiểm tra cột NGAY_BAO_TRI đã tồn tại chưa
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'NGANKEO' AND COLUMN_NAME = 'NGAY_BAO_TRI'
)
BEGIN
    ALTER TABLE NGANKEO ADD NGAY_BAO_TRI DATE NULL;
    PRINT 'Đã thêm cột NGAY_BAO_TRI vào bảng NGANKEO';
END
GO

-- SP cập nhật ngày bảo trì
IF OBJECT_ID('SP_CapNhat_NgayBaoTri', 'P') IS NOT NULL DROP PROCEDURE SP_CapNhat_NgayBaoTri;
GO
CREATE PROCEDURE SP_CapNhat_NgayBaoTri
    @maNgan NVARCHAR(10),
    @ngay   DATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE NGANKEO
    SET NGAY_BAO_TRI = @ngay
    WHERE MANGAN = @maNgan;

    IF @@ROWCOUNT = 0
        RAISERROR(N'Không tìm thấy ngăn kéo với mã: %s', 16, 1, @maNgan);
END
GO

PRINT '✅ Sprint 3 SQL scripts đã chạy xong!';
GO
