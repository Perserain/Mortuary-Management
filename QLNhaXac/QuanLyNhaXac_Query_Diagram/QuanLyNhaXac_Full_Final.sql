-- ============================================================
-- HỆ THỐNG QUẢN LÝ NHÀ XÁC — QuanLyNhaXac
-- FILE SQL DUY NHẤT — BÔI ĐEN VÀ EXECUTE TOÀN BỘ
-- Thứ tự:
--   0. Tạo / Tái tạo Database
--   1. Tạo Bảng + Ràng buộc (PK, FK, CHECK, DEFAULT, UNIQUE)
--   2. Nhập Liệu Mẫu (phong phú)
--   3. View
--   4. Function
--   5. Stored Procedure
--   6. Trigger
--   7. Cursor
--   8. Backup & Restore
--   9. Phân Quyền & Login
-- Chạy trên: SQL Server 2016+
-- ============================================================

USE master
GO
SET DATEFORMAT DMY
GO

-- ============================================================
-- 0. TẠO / TÁI TẠO DATABASE
-- ============================================================
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'QuanLyNhaXac')
BEGIN
    ALTER DATABASE QuanLyNhaXac SET SINGLE_USER WITH ROLLBACK IMMEDIATE
    DROP DATABASE QuanLyNhaXac
END
GO

CREATE DATABASE QuanLyNhaXac
GO

ALTER DATABASE QuanLyNhaXac SET RECOVERY FULL
GO

USE QuanLyNhaXac
GO
SET DATEFORMAT DMY
GO

-- ============================================================
-- 1. TẠO BẢNG + RÀNG BUỘC
-- ============================================================

-- ── 1.1 THIHAI — Bảng trung tâm ─────────────────────────────
CREATE TABLE THIHAI
(
    MATH        VARCHAR(15)   NOT NULL,
    HOTEN_TH    NVARCHAR(100),
    NGAYSINH    DATE,
    NGAYMAT     DATE,
    GIOITINH    NVARCHAR(10),
    TRANGTHAI   NVARCHAR(30)  NOT NULL  CONSTRAINT DF_THIHAI_TRANGTHAI DEFAULT N'Đang bảo quản',
    NOITIMTHAY  NVARCHAR(200),
    COCUANHAN   NVARCHAR(100),
    NGAYNHAP    DATE          DEFAULT CAST(GETDATE() AS DATE),
    CONSTRAINT PK_THIHAI              PRIMARY KEY (MATH),
    CONSTRAINT CK_THIHAI_NGAY         CHECK (NGAYMAT > NGAYSINH),
    CONSTRAINT CK_THIHAI_TRANGTHAI    CHECK (TRANGTHAI IN (
        N'Đang bảo quản', N'Đang khám nghiệm',
        N'Chờ bàn giao',  N'Đã bàn giao', N'Đã mai táng'
    ))
)
GO

-- ── 1.2 BACSI ────────────────────────────────────────────────
CREATE TABLE BACSI
(
    MABS            VARCHAR(15)   NOT NULL,
    HOTEN_BS        NVARCHAR(100),
    CHUYENKHOA      NVARCHAR(100),
    NAMKINHNGHIEM   INT,
    MA_TRUONGKHOA   VARCHAR(15),
    CONSTRAINT PK_BACSI           PRIMARY KEY (MABS),
    CONSTRAINT CK_BACSI_NAMKN     CHECK (NAMKINHNGHIEM > 1)
)
GO

ALTER TABLE BACSI
    ADD CONSTRAINT FK_BACSI_TRUONGKHOA
        FOREIGN KEY (MA_TRUONGKHOA) REFERENCES BACSI(MABS)
GO

-- ── 1.3 DICHVU ───────────────────────────────────────────────
CREATE TABLE DICHVU
(
    MADV    VARCHAR(15)   NOT NULL,
    TENDV   NVARCHAR(100),
    GIATIEN MONEY,
    CONSTRAINT PK_DICHVU           PRIMARY KEY (MADV),
    CONSTRAINT CK_DICHVU_GIATIEN   CHECK (GIATIEN >= 0)
)
GO

-- ── 1.4 NGANKEO (1-1 với THIHAI) ────────────────────────────
CREATE TABLE NGANKEO
(
    MANGAN           VARCHAR(15)   NOT NULL,
    VITRI            NVARCHAR(50),
    NHIETDO          FLOAT,
    NHIETDO_CANH_BAO FLOAT         DEFAULT -2.0,
    NGAY_BAO_TRI     DATE,
    MATH             VARCHAR(15),
    CONSTRAINT PK_NGANKEO          PRIMARY KEY (MANGAN),
    CONSTRAINT CK_NGANKEO_NHIETDO  CHECK (NHIETDO < 10)
)
GO

CREATE UNIQUE INDEX UQ_NGANKEO_MATH ON NGANKEO(MATH) WHERE MATH IS NOT NULL;

ALTER TABLE NGANKEO
    ADD CONSTRAINT FK_NGANKEO_THIHAI
        FOREIGN KEY (MATH) REFERENCES THIHAI(MATH)
GO

-- ── 1.5 HOSOKHAMBENH ─────────────────────────────────────────
CREATE TABLE HOSOKHAMBENH
(
    MAHS            VARCHAR(15)   NOT NULL,
    THOIGIANKHAM    DATE,
    KETLUAN         NVARCHAR(50),
    MATH            VARCHAR(15),
    MABS            VARCHAR(15),
    MACAUTU         NVARCHAR(10),
    LOAICAUTU       NVARCHAR(50),
    SOBIENBAN       NVARCHAR(30),
    NGAYBIENBAN     DATE,
    COQUANYEUCAU    NVARCHAR(150),
    GHICHUPHAY      NVARCHAR(500),
    CONSTRAINT PK_HOSOKHAMBENH     PRIMARY KEY (MAHS),
    CONSTRAINT CK_HS_LOAICAUTU    CHECK (LOAICAUTU IN (
        N'Tai nạn giao thông', N'Tai nạn lao động',
        N'Bệnh lý', N'Tự tử', N'Án mạng', N'Chưa rõ', N'Khác'
    ) OR LOAICAUTU IS NULL)
)
GO

ALTER TABLE HOSOKHAMBENH
    ADD CONSTRAINT FK_HOSOKHAMBENH_THIHAI FOREIGN KEY (MATH) REFERENCES THIHAI(MATH),
        CONSTRAINT FK_HOSOKHAMBENH_BACSI  FOREIGN KEY (MABS) REFERENCES BACSI(MABS)
GO

-- ── 1.6 HOADON ───────────────────────────────────────────────
CREATE TABLE HOADON
(
    MAHD          VARCHAR(15)   NOT NULL,
    MATH          VARCHAR(15)   NOT NULL,
    NGAYLAP       DATE          NOT NULL,
    TONGTIEN      MONEY         NOT NULL,
    TRANGTHAITT   NVARCHAR(20)  NOT NULL  CONSTRAINT DF_HD_TRANGTHAITT DEFAULT N'Chưa thanh toán',
    PHUONGTHUCTT  NVARCHAR(30),
    NGAYTHANHTOAN DATE,
    NGUOILAP      NVARCHAR(100),
    GHICHU        NVARCHAR(200),
    CONSTRAINT PK_HOADON        PRIMARY KEY (MAHD),
    CONSTRAINT FK_HD_THIHAI     FOREIGN KEY (MATH) REFERENCES THIHAI(MATH),
    CONSTRAINT CK_HD_TT         CHECK (TRANGTHAITT IN (
        N'Chưa thanh toán', N'Đã thanh toán', N'Miễn phí', N'Nợ'
    )),
    CONSTRAINT CK_HD_PT         CHECK (PHUONGTHUCTT IN (
        N'Tiền mặt', N'Chuyển khoản', N'Thẻ ngân hàng', N'Khác'
    ) OR PHUONGTHUCTT IS NULL),
    CONSTRAINT CK_HD_TIEN       CHECK (TONGTIEN >= 0)
)
GO

-- ── 1.7 SUDUNG (n-n: THIHAI × DICHVU) ───────────────────────
CREATE TABLE SUDUNG
(
    MATH       VARCHAR(15)   NOT NULL,
    MADV       VARCHAR(15)   NOT NULL,
    NGAYSUDUNG DATE,
    SOLUONG    INT           NOT NULL  DEFAULT 1,
    GHICHU     NVARCHAR(200),
    MAHD       VARCHAR(15)   NULL,
    CONSTRAINT PK_SUDUNG     PRIMARY KEY (MATH, MADV, NGAYSUDUNG),
    CONSTRAINT FK_SUDUNG_TH  FOREIGN KEY (MATH) REFERENCES THIHAI(MATH),
    CONSTRAINT FK_SUDUNG_DV  FOREIGN KEY (MADV) REFERENCES DICHVU(MADV),
    CONSTRAINT FK_SUDUNG_HD  FOREIGN KEY (MAHD) REFERENCES HOADON(MAHD)
)
GO

-- ── 1.8 NHANVIEN ─────────────────────────────────────────────
CREATE TABLE NHANVIEN
(
    MANV       VARCHAR(15)   NOT NULL,
    HOTEN_NV   NVARCHAR(100),
    CHUCVU     NVARCHAR(100),
    DIENTHOAI  VARCHAR(15),
    CONSTRAINT PK_NHANVIEN   PRIMARY KEY (MANV)
)
GO

-- ── 1.9 THAN_NHAN ────────────────────────────────────────────
CREATE TABLE THAN_NHAN
(
    MATN       VARCHAR(15)   NOT NULL,
    MATH       VARCHAR(15)   NOT NULL,
    HOTEN_TN   NVARCHAR(100) NOT NULL,
    QUANHE     NVARCHAR(50),
    DIENTHOAI  VARCHAR(15),
    DIACHI     NVARCHAR(200),
    LALIENDHE  BIT           NOT NULL  CONSTRAINT DF_TN_LALIENDHE DEFAULT 0,
    GHICHU     NVARCHAR(200),
    CONSTRAINT PK_THAN_NHAN  PRIMARY KEY (MATN),
    CONSTRAINT FK_TN_THIHAI  FOREIGN KEY (MATH) REFERENCES THIHAI(MATH)
)
GO

-- ── 1.10 AUDIT_LOG ───────────────────────────────────────────
CREATE TABLE AUDIT_LOG
(
    MALOG    BIGINT         NOT NULL IDENTITY(1,1),
    THOIGIAN DATETIME       NOT NULL DEFAULT GETDATE(),
    TENUSER  NVARCHAR(128)  NOT NULL DEFAULT SUSER_SNAME(),
    TENTABLE NVARCHAR(50)   NOT NULL,
    HANHDOG  NVARCHAR(10)   NOT NULL,
    MABANGHI NVARCHAR(50),
    NOIDUNG  NVARCHAR(1000),
    CONSTRAINT PK_AUDIT     PRIMARY KEY (MALOG),
    CONSTRAINT CK_AUDIT_HD  CHECK (HANHDOG IN ('INSERT','UPDATE','DELETE') OR HANHDOG IS NULL)
)
GO

CREATE INDEX IX_AUDIT_THOIGIAN ON AUDIT_LOG(THOIGIAN DESC)
CREATE INDEX IX_AUDIT_TABLE    ON AUDIT_LOG(TENTABLE, THOIGIAN DESC)
GO

-- ── 1.11 CANH_BAO ────────────────────────────────────────────
CREATE TABLE CANH_BAO
(
    MACB     INT           NOT NULL IDENTITY(1,1),
    THOIGIAN DATETIME      NOT NULL DEFAULT GETDATE(),
    LOAICB   NVARCHAR(50)  NOT NULL,
    MATH     VARCHAR(15),
    MANGAN   VARCHAR(15),
    NOIDUNG  NVARCHAR(300) NOT NULL,
    DAOC     BIT           NOT NULL DEFAULT 0,
    CONSTRAINT PK_CANH_BAO  PRIMARY KEY (MACB)
)
GO

-- ============================================================
-- 2. NHẬP LIỆU MẪU
-- ============================================================

-- ── 2.1 Bác Sĩ ───────────────────────────────────────────────
INSERT INTO BACSI (MABS, HOTEN_BS, CHUYENKHOA, NAMKINHNGHIEM, MA_TRUONGKHOA) VALUES
('BS001', N'Phạm Nhật Vượng',    N'Pháp y',          10, NULL),
('BS002', N'Đặng Lê Nguyên Vũ',  N'Đa khoa',         15, NULL),
('BS003', N'Phạm Minh Đức',       N'Pháp y',          10, NULL),
('BS004', N'Nguyễn Thị Hoa',      N'Giải phẫu bệnh', 12, NULL),
('BS005', N'Trần Quang Huy',      N'Pháp y',          11, NULL),
('BS006', N'Lê Văn Nam',          N'Đa khoa',          8, NULL),
('BS007', N'Nguyễn Minh Tuấn',   N'Pháp y',           6, NULL),
('BS008', N'Trịnh Thị Lan',       N'Giải phẫu bệnh',  3, NULL),
('BS009', N'Cao Xuân Hùng',       N'Pháp y',          20, NULL),
('BS010', N'Vũ Thị Thanh',        N'Đa khoa',          5, NULL)
GO

-- Cập nhật trưởng khoa sau khi đã có dữ liệu
UPDATE BACSI SET MA_TRUONGKHOA = 'BS009' WHERE MABS IN ('BS001','BS003','BS005','BS007')
UPDATE BACSI SET MA_TRUONGKHOA = 'BS002' WHERE MABS IN ('BS006','BS010')
UPDATE BACSI SET MA_TRUONGKHOA = 'BS004' WHERE MABS IN ('BS008')
GO

-- ── 2.2 Dịch Vụ ─────────────────────────────────────────────
INSERT INTO DICHVU (MADV, TENDV, GIATIEN) VALUES
('DV001', N'Trang điểm tử thi',    500000),
('DV002', N'Khâm liệm',           2000000),
('DV003', N'Bảo quản lạnh',        150000),
('DV004', N'Vận chuyển thi hài',   800000),
('DV005', N'Hỗ trợ mai táng',     3000000),
('DV006', N'Chụp ảnh lưu niệm',   300000),
('DV007', N'Nhang đèn lễ tang',    200000),
('DV008', N'Đọc kinh - cầu nguyện',400000),
('DV009', N'Thiết kế áo quan',    1500000),
('DV010', N'Tắm rửa thi hài',     600000)
GO

-- ── 2.3 Thi Hài ──────────────────────────────────────────────
INSERT INTO THIHAI (MATH, HOTEN_TH, NGAYSINH, NGAYMAT, GIOITINH, TRANGTHAI, NOITIMTHAY, COCUANHAN) VALUES
('TH001', N'Nguyễn Văn An',       '01-01-1980', '20-01-2026', N'Nam',  N'Đang bảo quản',  N'Quận 1 - TP.HCM',          N'Công an Quận 1'),
('TH002', N'Trần Thị Bích',       '15-05-1995', '21-01-2026', N'Nữ',  N'Đang bảo quản',  N'Quận 3 - TP.HCM',          N'Bệnh viện Chợ Rẫy'),
('TH003', N'Lê Văn Cường',        '12-12-1960', '22-01-2026', N'Nam',  N'Đang khám nghiệm',N'Bình Dương',              N'Công an Bình Dương'),
('TH004', N'Nguyễn Văn Khải',     '02-02-2000', '02-12-2025', N'Nam',  N'Chờ bàn giao',   N'Đồng Nai',                N'Bệnh viện Đồng Nai'),
('TH005', N'Nguyễn Khả Ái',       '03-05-2010', '12-01-2026', N'Nữ',  N'Đang bảo quản',  N'Quận 7 - TP.HCM',         N'Bệnh viện Nhi Đồng'),
('TH006', N'Cao Tử Khai',         '09-03-1969', '04-04-2025', N'Nam',  N'Đã bàn giao',    N'Quận Bình Thạnh',         N'Gia đình tự báo'),
('TH007', N'Nguyễn Hoài Anh',     '09-03-1975', '04-04-2026', N'Nam',  N'Đang bảo quản',  N'Long An',                 N'Công an Long An'),
('TH008', N'Phạm Thị Dung',       '20-07-1988', '10-04-2026', N'Nữ',  N'Đang bảo quản',  N'Quận Gò Vấp',             N'Bệnh viện Gia Định'),
('TH009', N'Trần Minh Hoàng',     '05-11-1972', '15-04-2026', N'Nam',  N'Đang khám nghiệm',N'Quận Tân Phú',           N'Công an Tân Phú'),
('TH010', N'Võ Thị Lan',          '30-08-1955', '18-04-2026', N'Nữ',  N'Đang bảo quản',  N'Quận 12',                 N'Bệnh viện Nhân Dân 115'),
('TH011', N'Đinh Quốc Toản',      '14-06-1990', '20-04-2026', N'Nam',  N'Chờ bàn giao',   N'Hóc Môn',                N'Công an Hóc Môn'),
('TH012', N'Bùi Thị Hường',       '22-09-1963', '22-04-2026', N'Nữ',  N'Đang bảo quản',  N'Quận 8',                 N'Bệnh viện Quận 8'),
('TH013', N'Lý Văn Phúc',         '17-03-1945', '25-04-2026', N'Nam',  N'Đã mai táng',    N'Quận 5',                 N'Gia đình tự báo'),
('TH014', N'Ngô Thị Mai',         '08-12-2005', '28-04-2026', N'Nữ',  N'Đang bảo quản',  N'Bình Chánh',             N'Bệnh viện Bình Chánh'),
('TH015', N'Huỳnh Văn Sơn',       '25-04-1978', '01-05-2026', N'Nam',  N'Đang khám nghiệm',N'Nhà Bè',                N'Công an Nhà Bè'),
('TH016', N'Dương Thị Tuyết',     '11-02-1967', '05-05-2026', N'Nữ',  N'Đang bảo quản',  N'Cần Thơ',               N'Bệnh viện Cần Thơ'),
('TH017', N'Trương Văn Hiển',     '03-07-1982', '10-05-2026', N'Nam',  N'Chờ bàn giao',   N'Tiền Giang',            N'Công an Tiền Giang'),
('TH018', N'Lâm Thị Thu',         '19-10-1970', '12-05-2026', N'Nữ',  N'Đang bảo quản',  N'Vĩnh Long',             N'Bệnh viện Vĩnh Long'),
('TH019', N'Phan Văn Tùng',       '07-01-1958', '15-05-2026', N'Nam',  N'Đang khám nghiệm',N'An Giang',             N'Công an An Giang'),
('TH020', N'Mai Thị Nhung',       '26-06-1993', '18-05-2026', N'Nữ',  N'Đang bảo quản',  N'Kiên Giang',            N'Bệnh viện Kiên Giang')
GO

-- ── 2.4 Ngăn Kéo ─────────────────────────────────────────────
INSERT INTO NGANKEO (MANGAN, VITRI, NHIETDO, NHIETDO_CANH_BAO, MATH) VALUES
('NK001', N'Khu A - Hộc 1',  -5.5, -2.0, 'TH001'),
('NK002', N'Khu A - Hộc 2',  -5.0, -2.0, 'TH002'),
('NK003', N'Khu A - Hộc 3',  -6.0, -2.0, 'TH003'),
('NK004', N'Khu A - Hộc 4',  -4.8, -2.0, 'TH005'),
('NK005', N'Khu A - Hộc 5',  -5.2, -2.0, 'TH007'),
('NK006', N'Khu B - Hộc 1',  -5.7, -2.0, 'TH008'),
('NK007', N'Khu B - Hộc 2',  -6.1, -2.0, 'TH009'),
('NK008', N'Khu B - Hộc 3',  -4.9, -2.0, 'TH010'),
('NK009', N'Khu B - Hộc 4',  -5.3, -2.0, 'TH012'),
('NK010', N'Khu B - Hộc 5',  -5.8, -2.0, 'TH014'),
('NK011', N'Khu C - Hộc 1',  -6.2, -2.0, 'TH015'),
('NK012', N'Khu C - Hộc 2',  -5.1, -2.0, 'TH016'),
('NK013', N'Khu C - Hộc 3',  -5.4, -2.0, 'TH018'),
('NK014', N'Khu C - Hộc 4',  -5.9, -2.0, 'TH019'),
('NK015', N'Khu C - Hộc 5',  -5.6, -2.0, 'TH020'),
('NK016', N'Khu D - Hộc 1',  -5.0, -2.0, NULL),
('NK017', N'Khu D - Hộc 2',  -5.5, -2.0, NULL),
('NK018', N'Khu D - Hộc 3',  -6.0, -2.0, NULL),
('NK019', N'Khu D - Hộc 4',  -4.8, -2.0, NULL),
('NK020', N'Khu D - Hộc 5',  -5.2, -2.0, NULL)
GO

-- ── 2.5 Hồ Sơ Khám Nghiệm ───────────────────────────────────
INSERT INTO HOSOKHAMBENH (MAHS, THOIGIANKHAM, KETLUAN, MATH, MABS, MACAUTU, LOAICAUTU, SOBIENBAN, NGAYBIENBAN, COQUANYEUCAU, GHICHUPHAY) VALUES
('HS001', '20-01-2026', N'Tử vong do tai nạn giao thông',      'TH001', 'BS001', 'V89', N'Tai nạn giao thông', 'BB001/2026', '20-01-2026', N'Công an Quận 1',          N'Va chạm xe máy tốc độ cao'),
('HS002', '21-01-2026', N'Tử vong do bệnh tim mạch',           'TH002', 'BS002', 'I21', N'Bệnh lý',           'BB002/2026', '21-01-2026', N'Bệnh viện Chợ Rẫy',       N'Nhồi máu cơ tim cấp'),
('HS003', '22-01-2026', N'Nghi ngờ án mạng, cần điều tra',     'TH003', 'BS001', 'X99', N'Án mạng',           'BB003/2026', '22-01-2026', N'Công an Bình Dương',      N'Phát hiện vết thương lạ vùng đầu'),
('HS004', '03-12-2025', N'Tử vong do tai nạn lao động',        'TH004', 'BS003', 'W09', N'Tai nạn lao động',  'BB004/2025', '03-12-2025', N'Sở Lao động Đồng Nai',   N'Té từ giàn giáo công trình'),
('HS005', '12-01-2026', N'Tử vong, nguyên nhân chưa rõ',       'TH005', 'BS004', NULL,  N'Chưa rõ',           'BB005/2026', '13-01-2026', N'Công an Quận 7',          NULL),
('HS006', '10-04-2026', N'Tử vong do tai nạn giao thông',      'TH008', 'BS005', 'V89', N'Tai nạn giao thông','BB006/2026', '10-04-2026', N'Công an Gò Vấp',          N'Tai nạn xe máy ban đêm'),
('HS007', '15-04-2026', N'Nghi án mạng, đang điều tra',        'TH009', 'BS001', 'X99', N'Án mạng',           'BB007/2026', '16-04-2026', N'Công an Tân Phú',         N'Phát hiện nhiều vết đâm'),
('HS008', '18-04-2026', N'Tử vong do bệnh lý cao tuổi',        'TH010', 'BS002', 'I50', N'Bệnh lý',           'BB008/2026', '18-04-2026', N'BV Nhân Dân 115',         N'Suy tim giai đoạn cuối'),
('HS009', '20-04-2026', N'Chưa xác định nguyên nhân',          'TH011', 'BS003', NULL,  N'Chưa rõ',           'BB009/2026', '21-04-2026', N'Công an Hóc Môn',         NULL),
('HS010', '22-04-2026', N'Tử vong do bệnh lý',                 'TH012', 'BS004', 'J18', N'Bệnh lý',           'BB010/2026', '22-04-2026', N'BV Quận 8',               N'Viêm phổi nặng'),
('HS011', '26-04-2026', N'Tử vong tự nhiên, tuổi cao',         'TH013', 'BS005', 'R54', N'Bệnh lý',           'BB011/2026', '26-04-2026', N'Gia đình',                N'Mất tại nhà ban đêm'),
('HS012', '28-04-2026', N'Tử vong do tai nạn giao thông',      'TH014', 'BS007', 'V89', N'Tai nạn giao thông','BB012/2026', '28-04-2026', N'Công an Bình Chánh',      N'Lật xe trên đường cao tốc'),
('HS013', '01-05-2026', N'Nghi án mạng',                       'TH015', 'BS001', 'X99', N'Án mạng',           'BB013/2026', '02-05-2026', N'Công an Nhà Bè',          N'Thi thể trôi trên sông'),
('HS014', '05-05-2026', N'Tử vong do bệnh tim',                'TH016', 'BS002', 'I21', N'Bệnh lý',           'BB014/2026', '05-05-2026', N'BV Cần Thơ',              N'Đột quỵ khi ngủ'),
('HS015', '12-05-2026', N'Tử vong do bệnh lý',                 'TH018', 'BS004', 'K70', N'Bệnh lý',           'BB015/2026', '13-05-2026', N'BV Vĩnh Long',            N'Xơ gan giai đoạn cuối'),
('HS016', '15-05-2026', N'Đang điều tra nguyên nhân',          'TH019', 'BS001', NULL,  N'Chưa rõ',           'BB016/2026', '16-05-2026', N'Công an An Giang',        NULL),
('HS017', '18-05-2026', N'Tử vong do tai nạn lao động',        'TH020', 'BS003', 'W09', N'Tai nạn lao động',  'BB017/2026', '19-05-2026', N'Sở Lao động Kiên Giang',  N'Điện giật tại công trình')
GO

-- ── 2.6 Hóa Đơn ─────────────────────────────────────────────
INSERT INTO HOADON (MAHD, MATH, NGAYLAP, TONGTIEN, TRANGTHAITT, PHUONGTHUCTT, NGAYTHANHTOAN, NGUOILAP) VALUES
('HD001', 'TH001', '21-01-2026', 2500000, N'Đã thanh toán',   N'Tiền mặt',      '22-01-2026', N'NhaXacAdmin'),
('HD002', 'TH002', '22-01-2026',  150000, N'Chưa thanh toán', NULL,              NULL,         N'NhaXacAdmin'),
('HD003', 'TH004', '05-12-2025', 3800000, N'Đã thanh toán',   N'Chuyển khoản',  '06-12-2025', N'NhaXacAdmin'),
('HD004', 'TH006', '05-04-2025', 5200000, N'Đã thanh toán',   N'Tiền mặt',      '05-04-2025', N'NhaXacAdmin'),
('HD005', 'TH008', '12-04-2026', 1300000, N'Chưa thanh toán', NULL,              NULL,         N'NhaXacAdmin'),
('HD006', 'TH010', '20-04-2026', 2650000, N'Đã thanh toán',   N'Thẻ ngân hàng', '21-04-2026', N'NhaXacAdmin'),
('HD007', 'TH012', '24-04-2026',  650000, N'Nợ',              NULL,              NULL,         N'NhaXacAdmin'),
('HD008', 'TH013', '26-04-2026', 4500000, N'Đã thanh toán',   N'Chuyển khoản',  '27-04-2026', N'NhaXacAdmin'),
('HD009', 'TH016', '07-05-2026', 3150000, N'Chưa thanh toán', NULL,              NULL,         N'NhaXacAdmin'),
('HD010', 'TH020', '20-05-2026', 1950000, N'Đã thanh toán',   N'Tiền mặt',      '20-05-2026', N'NhaXacAdmin')
GO

-- ── 2.7 Sử Dụng Dịch Vụ ─────────────────────────────────────
INSERT INTO SUDUNG (MATH, MADV, NGAYSUDUNG, SOLUONG, GHICHU, MAHD) VALUES
('TH001','DV001','20-01-2026', 1, N'Trang điểm nhẹ theo yêu cầu gia đình',           'HD001'),
('TH001','DV002','20-01-2026', 1, N'Khâm liệm theo nghi lễ truyền thống',            'HD001'),
('TH001','DV010','20-01-2026', 1, N'Tắm rửa thi hài',                                'HD001'),
('TH002','DV003','21-01-2026', 3, N'Bảo quản 3 ngày chờ gia đình từ xa về',          NULL),
('TH003','DV003','22-01-2026', 2, N'Bảo quản chờ kết quả điều tra',                  NULL),
('TH004','DV001','03-12-2025', 1, N'Trang điểm cơ bản',                              'HD003'),
('TH004','DV002','03-12-2025', 1, N'Khâm liệm',                                      'HD003'),
('TH004','DV004','04-12-2025', 1, N'Vận chuyển về quê Đồng Nai',                     'HD003'),
('TH006','DV001','04-04-2025', 1, N'Trang điểm kỹ lưỡng',                            'HD004'),
('TH006','DV002','04-04-2025', 1, N'Khâm liệm',                                      'HD004'),
('TH006','DV005','05-04-2025', 1, N'Hỗ trợ tổ chức lễ tang',                        'HD004'),
('TH006','DV007','05-04-2025', 2, N'Nhang đèn 2 ngày',                               'HD004'),
('TH008','DV003','10-04-2026', 2, N'Bảo quản chờ gia đình',                          'HD005'),
('TH008','DV010','10-04-2026', 1, N'Tắm rửa thi hài',                                'HD005'),
('TH010','DV001','18-04-2026', 1, N'Trang điểm',                                     'HD006'),
('TH010','DV002','18-04-2026', 1, N'Khâm liệm',                                      'HD006'),
('TH010','DV003','18-04-2026', 5, N'Bảo quản 5 ngày',                                'HD006'),
('TH012','DV003','22-04-2026', 3, N'Bảo quản chờ thân nhân ở tỉnh',                  'HD007'),
('TH013','DV001','25-04-2026', 1, N'Trang điểm',                                     'HD008'),
('TH013','DV002','25-04-2026', 1, N'Khâm liệm',                                     'HD008'),
('TH013','DV005','26-04-2026', 1, N'Hỗ trợ mai táng',                               'HD008'),
('TH013','DV008','26-04-2026', 1, N'Đọc kinh theo đạo Phật',                        'HD008'),
('TH016','DV003','05-05-2026', 5, N'Bảo quản 5 ngày',                               'HD009'),
('TH016','DV001','05-05-2026', 1, N'Trang điểm',                                    'HD009'),
('TH016','DV009','06-05-2026', 1, N'Thiết kế áo quan cao cấp',                      'HD009'),
('TH020','DV003','18-05-2026', 2, N'Bảo quản 2 ngày',                               'HD010'),
('TH020','DV010','18-05-2026', 1, N'Tắm rửa thi hài',                               'HD010'),
('TH020','DV001','19-05-2026', 1, N'Trang điểm',                                    'HD010'),
-- Dịch vụ chưa lập hóa đơn (MAHD = NULL)
('TH007','DV003','04-04-2026', 3, N'Bảo quản 3 ngày',                               NULL),
('TH009','DV003','15-04-2026', 2, N'Bảo quản chờ điều tra',                         NULL),
('TH011','DV003','20-04-2026', 1, N'Bảo quản',                                      NULL),
('TH014','DV003','28-04-2026', 2, N'Bảo quản chờ gia đình',                         NULL),
('TH015','DV003','01-05-2026', 3, N'Bảo quản chờ điều tra',                         NULL),
('TH017','DV003','10-05-2026', 2, N'Bảo quản chờ bàn giao',                         NULL),
('TH018','DV003','12-05-2026', 1, N'Bảo quản',                                      NULL),
('TH019','DV003','15-05-2026', 2, N'Bảo quản chờ điều tra',                         NULL)
GO

-- ── 2.8 Nhân Viên ────────────────────────────────────────────
INSERT INTO NHANVIEN (MANV, HOTEN_NV, CHUCVU, DIENTHOAI) VALUES
('NV001', N'Nguyễn Thị Lan',    N'Lễ tân',              '0901111111'),
('NV002', N'Trần Văn Bình',     N'Chăm sóc thi hài',    '0902222222'),
('NV003', N'Lê Thị Hoa',        N'Kế toán',             '0903333333'),
('NV004', N'Phạm Quốc Dũng',    N'Vận chuyển',          '0904444444'),
('NV005', N'Võ Thị Thu',        N'Bảo vệ',              '0905555555'),
('NV006', N'Đinh Văn Hải',      N'Kỹ thuật viên',       '0906666666'),
('NV007', N'Ngô Thị Cúc',       N'Chăm sóc thi hài',   '0907777777'),
('NV008', N'Bùi Minh Khoa',     N'Hành chính',          '0908888888')
GO

-- ── 2.9 Thân Nhân ────────────────────────────────────────────
INSERT INTO THAN_NHAN (MATN, MATH, HOTEN_TN, QUANHE, DIENTHOAI, DIACHI, LALIENDHE, GHICHU) VALUES
('TN001','TH001',N'Nguyễn Thị Hà',    N'Vợ',        '0901234567', N'12 Lê Lợi, Q.1, TP.HCM',               1, NULL),
('TN002','TH001',N'Nguyễn Văn Bình',  N'Con trai',  '0912345678', N'12 Lê Lợi, Q.1, TP.HCM',               0, NULL),
('TN003','TH002',N'Trần Văn Quang',   N'Chồng',     '0923456789', N'45 Đinh Tiên Hoàng, Q.Bình Thạnh',      1, NULL),
('TN004','TH003',N'Lê Thị Tâm',       N'Vợ',        '0934567890', N'22 Nguyễn Văn Linh, Bình Dương',        1, NULL),
('TN005','TH004',N'Nguyễn Văn Thắng', N'Cha',       '0945678901', N'88 Trần Hưng Đạo, Biên Hòa',           1, NULL),
('TN006','TH005',N'Nguyễn Thị Mai',   N'Mẹ',        '0956789012', N'15 Hoàng Diệu, Q.7, TP.HCM',           1, NULL),
('TN007','TH006',N'Cao Văn Lợi',      N'Con trai',  '0967890123', N'99 Xô Viết Nghệ Tĩnh, Bình Thạnh',     1, NULL),
('TN008','TH007',N'Nguyễn Thị Nga',   N'Vợ',        '0978901234', N'100 Quốc Lộ 1A, Long An',              1, NULL),
('TN009','TH008',N'Phạm Văn Hùng',    N'Chồng',     '0989012345', N'56 Quang Trung, Gò Vấp, TP.HCM',       1, NULL),
('TN010','TH009',N'Trần Thị Yến',     N'Vợ',        '0990123456', N'78 Âu Cơ, Tân Phú, TP.HCM',            1, NULL),
('TN011','TH010',N'Võ Minh Tuấn',     N'Con trai',  '0901230001', N'11 Lê Văn Việt, Q.12, TP.HCM',         1, NULL),
('TN012','TH010',N'Võ Thị Hiền',      N'Con gái',   '0912340002', N'11 Lê Văn Việt, Q.12, TP.HCM',         0, NULL),
('TN013','TH011',N'Đinh Văn Nam',     N'Anh ruột',  '0923450003', N'33 Phan Văn Hớn, Hóc Môn',             1, NULL),
('TN014','TH012',N'Bùi Văn Khoa',     N'Chồng',     '0934560004', N'65 Tùng Thiện Vương, Q.8',              1, NULL),
('TN015','TH013',N'Lý Thị Loan',      N'Con gái',   '0945670005', N'20 Trần Bình Trọng, Q.5',              1, NULL),
('TN016','TH014',N'Ngô Văn Sửu',      N'Cha',       '0956780006', N'77 Quốc Lộ 50, Bình Chánh',            1, NULL),
('TN017','TH015',N'Huỳnh Thị Bạch',   N'Mẹ',        '0967890007', N'44 Lê Văn Lương, Nhà Bè',              1, NULL),
('TN018','TH016',N'Dương Văn Hải',    N'Chồng',     '0978900008', N'111 Trần Phú, Cần Thơ',                1, NULL),
('TN019','TH017',N'Trương Thị Lan',   N'Vợ',        '0989010009', N'55 Hùng Vương, Mỹ Tho, Tiền Giang',   1, NULL),
('TN020','TH018',N'Lâm Văn Thịnh',    N'Chồng',     '0990120010', N'22 Đinh Tiên Hoàng, Vĩnh Long',        1, NULL),
('TN021','TH019',N'Phan Thị Nhanh',   N'Vợ',        '0901230011', N'88 Trần Hưng Đạo, Long Xuyên',         1, NULL),
('TN022','TH020',N'Mai Văn Tám',      N'Chồng',     '0912340012', N'33 Nguyễn Trung Trực, Rạch Giá',       1, NULL)
GO

-- ============================================================
-- 3. VIEW
-- ============================================================

-- ── 3.1 Bác sĩ kèm trưởng khoa và cấp bậc ──────────────────
CREATE VIEW VIEW_DanhSachBacSi AS
SELECT
    bs.MABS, bs.HOTEN_BS, bs.CHUYENKHOA, bs.NAMKINHNGHIEM,
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

-- ── 3.2 Bác sĩ trên mức TB kinh nghiệm ─────────────────────
CREATE VIEW VIEW_BSLaoLang AS
SELECT * FROM VIEW_DanhSachBacSi
WHERE NAMKINHNGHIEM > (SELECT AVG(NAMKINHNGHIEM) FROM VIEW_DanhSachBacSi)
GO

-- ── 3.3 Khối lượng khám của bác sĩ ─────────────────────────
CREATE VIEW VIEW_BacSi_KhoiLuongKhamNghiem AS
SELECT
    bs.MABS, bs.HOTEN_BS, bs.CHUYENKHOA,
    COUNT(hs.MAHS) AS TongCaKham,
    SUM(CASE WHEN MONTH(hs.THOIGIANKHAM) = MONTH(GETDATE())
                  AND YEAR(hs.THOIGIANKHAM)  = YEAR(GETDATE())
             THEN 1 ELSE 0 END) AS CaKhamThangNay
FROM BACSI bs
LEFT JOIN HOSOKHAMBENH hs ON bs.MABS = hs.MABS
GROUP BY bs.MABS, bs.HOTEN_BS, bs.CHUYENKHOA
GO

-- ── 3.4 Hồ sơ chi tiết ──────────────────────────────────────
CREATE VIEW VIEW_HoSo_ChiTiet AS
SELECT
    hs.MAHS, hs.THOIGIANKHAM,
    th.MATH, th.HOTEN_TH, th.TRANGTHAI AS TRANGTHAI_THIHAI,
    bs.MABS, bs.HOTEN_BS, bs.CHUYENKHOA,
    hs.KETLUAN, hs.MACAUTU, hs.LOAICAUTU,
    hs.SOBIENBAN, hs.NGAYBIENBAN, hs.COQUANYEUCAU, hs.GHICHUPHAY
FROM HOSOKHAMBENH hs
JOIN THIHAI th ON hs.MATH = th.MATH
JOIN BACSI  bs ON hs.MABS = bs.MABS
GO

-- ── 3.5 Danh sách thi hài đầy đủ ───────────────────────────
CREATE VIEW VIEW_DanhSachThiHai AS
SELECT
    th.MATH, th.HOTEN_TH, th.NGAYSINH, th.NGAYMAT, th.GIOITINH,
    th.TRANGTHAI, th.NGAYNHAP, th.NOITIMTHAY, th.COCUANHAN,
    DATEDIFF(YEAR, th.NGAYSINH, th.NGAYMAT) AS TUOI_KHI_MAT,
    CASE
        WHEN DATEDIFF(YEAR, th.NGAYSINH, th.NGAYMAT) < 18              THEN N'Vị thành niên'
        WHEN DATEDIFF(YEAR, th.NGAYSINH, th.NGAYMAT) BETWEEN 18 AND 59 THEN N'Trưởng thành'
        ELSE N'Cao tuổi'
    END AS NHOMTUOI,
    nk.MANGAN, nk.VITRI, nk.NHIETDO
FROM THIHAI th
LEFT JOIN NGANKEO nk ON nk.MATH = th.MATH
GO

-- ── 3.6 Thi hài chưa có ngăn kéo ───────────────────────────
CREATE VIEW VIEW_ThiHaiChuaCoNganKeo AS
SELECT th.*
FROM THIHAI th
WHERE th.MATH NOT IN (SELECT MATH FROM NGANKEO WHERE MATH IS NOT NULL)
GO

-- ── 3.7 Thi hài sắp / đã quá hạn ───────────────────────────
CREATE VIEW VIEW_ThiHaiQuaHan AS
SELECT
    th.MATH, th.HOTEN_TH, th.NGAYMAT, th.TRANGTHAI,
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

-- ── 3.8 Ngăn kéo toàn bộ ────────────────────────────────────
CREATE VIEW VIEW_DanhSachNganKeo AS
SELECT
    nk.MANGAN, nk.VITRI, nk.NHIETDO, nk.NHIETDO_CANH_BAO, nk.NGAY_BAO_TRI,
    nk.MATH, th.HOTEN_TH, th.TRANGTHAI,
    CASE WHEN nk.MATH IS NULL THEN N'Trống' ELSE N'Đang sử dụng' END AS TRANGTHAI_NGAN
FROM NGANKEO nk
LEFT JOIN THIHAI th ON nk.MATH = th.MATH
GO

-- ── 3.9 Dịch vụ danh mục ────────────────────────────────────
CREATE VIEW VIEW_DichVu AS SELECT * FROM DICHVU
GO

-- ── 3.10 Dịch vụ chưa ai dùng ───────────────────────────────
CREATE VIEW VIEW_DichVuE AS
SELECT * FROM DICHVU
WHERE MADV NOT IN (SELECT DISTINCT MADV FROM SUDUNG)
GO

-- ── 3.11 Thống kê dịch vụ ───────────────────────────────────
CREATE VIEW VIEW_DichVu_ThongKe AS
SELECT
    dv.MADV, dv.TENDV, dv.GIATIEN,
    COUNT(sd.MATH) AS SO_LAN_SU_DUNG,
    ISNULL(SUM(dv.GIATIEN * sd.SOLUONG), 0) AS TONG_DOANH_THU,
    MAX(sd.NGAYSUDUNG) AS LAN_SU_DUNG_CUOI
FROM DICHVU dv
LEFT JOIN SUDUNG sd ON dv.MADV = sd.MADV
GROUP BY dv.MADV, dv.TENDV, dv.GIATIEN
GO

-- ── 3.12 Dịch vụ sử dụng chi tiết ──────────────────────────
CREATE VIEW VIEW_DichVuSuDung AS
SELECT
    th.MATH, th.HOTEN_TH, th.TRANGTHAI,
    dv.MADV, dv.TENDV, dv.GIATIEN,
    sd.SOLUONG,
    dv.GIATIEN * sd.SOLUONG AS THANHTIEN,
    sd.NGAYSUDUNG, sd.GHICHU, sd.MAHD,
    CASE WHEN sd.MAHD IS NULL THEN N'Chưa lập HĐ' ELSE N'Đã lập HĐ' END AS TRANGTHAI_HD
FROM THIHAI  th
JOIN SUDUNG  sd ON th.MATH = sd.MATH
JOIN DICHVU  dv ON sd.MADV = dv.MADV
GO

-- ── 3.13 Thân nhân kèm thi hài ──────────────────────────────
CREATE VIEW VIEW_ThanNhanThiHai AS
SELECT
    tn.MATN, tn.QUANHE, tn.HOTEN_TN, tn.DIENTHOAI, tn.DIACHI,
    tn.LALIENDHE, tn.GHICHU,
    th.MATH, th.HOTEN_TH, th.TRANGTHAI
FROM THAN_NHAN tn
JOIN THIHAI th ON tn.MATH = th.MATH
GO

-- ── 3.14 Hóa đơn chi tiết ───────────────────────────────────
CREATE VIEW VIEW_HoaDonChiTiet AS
SELECT
    hd.MAHD, th.MATH, th.HOTEN_TH,
    tn.HOTEN_TN   AS NGUOI_NHAN,
    tn.DIENTHOAI  AS SDT_NGUOI_NHAN,
    hd.NGAYLAP, hd.TONGTIEN, hd.TRANGTHAITT,
    hd.PHUONGTHUCTT, hd.NGAYTHANHTOAN, hd.NGUOILAP, hd.GHICHU
FROM HOADON hd
JOIN THIHAI th ON hd.MATH = th.MATH
LEFT JOIN THAN_NHAN tn ON tn.MATH = th.MATH AND tn.LALIENDHE = 1
GO

-- ── 3.15 Hóa đơn chưa thanh toán ───────────────────────────
CREATE VIEW VIEW_HoaDon_ChuaThanhToan AS
SELECT
    hd.MAHD, th.MATH, th.HOTEN_TH, th.TRANGTHAI AS TRANGTHAI_THIHAI,
    hd.NGAYLAP, hd.TONGTIEN, hd.TRANGTHAITT, hd.NGUOILAP,
    tn.HOTEN_TN AS NGUOI_LIEN_HE, tn.DIENTHOAI, tn.QUANHE,
    DATEDIFF(DAY, hd.NGAYLAP, GETDATE()) AS SO_NGAY_NO
FROM HOADON hd
JOIN THIHAI th ON hd.MATH = th.MATH
LEFT JOIN THAN_NHAN tn ON tn.MATH = th.MATH AND tn.LALIENDHE = 1
WHERE hd.TRANGTHAITT IN (N'Chưa thanh toán', N'Nợ')
GO

-- ── 3.16 Cảnh báo chưa đọc ──────────────────────────────────
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

-- ── 3.17 Dashboard tổng quan ─────────────────────────────────
CREATE VIEW VIEW_Dashboard AS
SELECT
    (SELECT COUNT(*) FROM THIHAI)                                            AS TongThiHai,
    (SELECT COUNT(*) FROM THIHAI WHERE TRANGTHAI = N'Đang bảo quản')        AS DangBaoQuan,
    (SELECT COUNT(*) FROM THIHAI WHERE TRANGTHAI = N'Chờ bàn giao')         AS ChoThanhLy,
    (SELECT COUNT(*) FROM NGANKEO WHERE MATH IS NULL)                        AS NganKeoTrong,
    (SELECT COUNT(*) FROM NGANKEO WHERE MATH IS NOT NULL)                    AS NganKeoDang,
    (SELECT COUNT(*) FROM NGANKEO)                                           AS TongNganKeo,
    (SELECT ISNULL(SUM(TONGTIEN),0) FROM HOADON
     WHERE TRANGTHAITT = N'Đã thanh toán'
       AND NGAYTHANHTOAN = CAST(GETDATE() AS DATE))                          AS DoanhThuHomNay,
    (SELECT ISNULL(SUM(TONGTIEN),0) FROM HOADON
     WHERE TRANGTHAITT = N'Đã thanh toán'
       AND MONTH(NGAYTHANHTOAN) = MONTH(GETDATE())
       AND YEAR(NGAYTHANHTOAN)  = YEAR(GETDATE()))                           AS DoanhThuThang,
    (SELECT COUNT(*) FROM CANH_BAO WHERE DAOC = 0)                          AS SoCanhBaoChuaDoc,
    (SELECT COUNT(*) FROM HOADON WHERE TRANGTHAITT = N'Chưa thanh toán')    AS HoaDonChuaTT
GO

-- ── 3.18 Thống kê theo tháng ────────────────────────────────
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

-- ── 3.19 Thống kê doanh thu theo tháng ─────────────────────
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

-- ── 3.20 Thống kê nguyên nhân tử vong ──────────────────────
CREATE VIEW VIEW_ThongKe_LoaiCauTu AS
SELECT
    YEAR(THOIGIANKHAM)  AS Nam,
    MONTH(THOIGIANKHAM) AS Thang,
    LOAICAUTU,
    COUNT(*) AS SoLuong,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (
        PARTITION BY YEAR(THOIGIANKHAM), MONTH(THOIGIANKHAM)
    ) AS DECIMAL(5,2)) AS TiLePhanTram
FROM HOSOKHAMBENH
WHERE LOAICAUTU IS NOT NULL
GROUP BY YEAR(THOIGIANKHAM), MONTH(THOIGIANKHAM), LOAICAUTU
GO

-- ── 3.21 Tóm tắt Audit Log ──────────────────────────────────
CREATE VIEW VIEW_AuditLog_TomTat AS
SELECT
    CAST(THOIGIAN AS DATE) AS Ngay,
    TENTABLE, HANHDOG,
    COUNT(*)               AS SoThaotac,
    COUNT(DISTINCT TENUSER) AS SoUser
FROM AUDIT_LOG
GROUP BY CAST(THOIGIAN AS DATE), TENTABLE, HANHDOG
GO

-- ── 3.22 KPI nhân viên theo hóa đơn ────────────────────────
CREATE VIEW VIEW_ThongKe_NhanVien_HoaDon AS
SELECT
    NGUOILAP AS TenNhanVien,
    COUNT(MAHD)                                                              AS TongHoaDon,
    SUM(CASE WHEN TRANGTHAITT = N'Đã thanh toán'   THEN 1 ELSE 0 END)      AS DaThanhToan,
    SUM(CASE WHEN TRANGTHAITT = N'Chưa thanh toán' THEN 1 ELSE 0 END)      AS ChuaThanhToan,
    ISNULL(SUM(CASE WHEN TRANGTHAITT = N'Đã thanh toán' THEN TONGTIEN ELSE 0 END), 0) AS DoanhThuThuDuoc
FROM HOADON
GROUP BY NGUOILAP
GO

-- ============================================================
-- 4. FUNCTION
-- ============================================================

-- ── 4.1 Tổng tiền dịch vụ chưa lập HĐ ──────────────────────
CREATE FUNCTION FN_TinhTongTienDichVu(@MATH VARCHAR(15))
RETURNS MONEY
AS
BEGIN
    DECLARE @TongTien MONEY
    SELECT @TongTien = ISNULL(SUM(dv.GIATIEN * sd.SOLUONG), 0)
    FROM SUDUNG sd
    JOIN DICHVU dv ON sd.MADV = dv.MADV
    WHERE sd.MATH = @MATH AND sd.MAHD IS NULL
    RETURN @TongTien
END
GO

-- ── 4.2 Trạng thái ngăn kéo ─────────────────────────────────
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

-- ── 4.3 Ngăn kéo trống (TVF) ────────────────────────────────
CREATE FUNCTION fn_DanhSachNganKeoTrong()
RETURNS TABLE
AS
RETURN (SELECT MANGAN, VITRI, NHIETDO FROM NGANKEO WHERE MATH IS NULL)
GO

-- ── 4.4 Lịch sử dịch vụ của tử thi (TVF) ───────────────────
CREATE FUNCTION fn_LichSuDichVuCuaTuThi(@MATH VARCHAR(15))
RETURNS TABLE
AS
RETURN (
    SELECT dv.TENDV, dv.GIATIEN, sd.SOLUONG,
           dv.GIATIEN * sd.SOLUONG AS THANHTIEN,
           sd.NGAYSUDUNG, sd.GHICHU
    FROM SUDUNG sd
    JOIN DICHVU dv ON sd.MADV = dv.MADV
    WHERE sd.MATH = @MATH
)
GO

-- ── 4.5 Tìm thi hài theo ngày ───────────────────────────────
CREATE FUNCTION fn_TimKiemThiHaiTheoNgay(@NgayTimKiem DATE)
RETURNS TABLE
AS
RETURN (SELECT * FROM THIHAI WHERE NGAYMAT = @NgayTimKiem OR NGAYSINH = @NgayTimKiem)
GO

-- ── 4.6 Khám nghiệm theo bác sĩ (TVF) ──────────────────────
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

-- ── 4.7 Khám nghiệm theo tử thi (TVF) ──────────────────────
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

-- ── 4.8 Số ngày còn lại (9999 = trong tủ lạnh) ──────────────
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

-- ── 4.9 Thông tin người liên hệ chính ───────────────────────
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

-- ── 4.10 Kiểm tra hóa đơn đã thanh toán ────────────────────
CREATE FUNCTION FN_KiemTraHoaDonDuocThanhToan(@MATH VARCHAR(15))
RETURNS BIT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM HOADON WHERE MATH = @MATH AND TRANGTHAITT = N'Đã thanh toán')
        RETURN 1
    RETURN 0
END
GO

-- ============================================================
-- 5. STORED PROCEDURE
-- ============================================================

-- ── 5.A BÁC SĨ ──────────────────────────────────────────────
CREATE PROC SP_DSBacSi AS BEGIN SELECT * FROM VIEW_DanhSachBacSi END
GO

CREATE PROC SP_ThemBacSi
    @MABS VARCHAR(15), @HOTEN_BS NVARCHAR(100),
    @CHUYENKHOA NVARCHAR(100), @NAMKINHNGHIEM INT, @MA_TRUONGKHOA VARCHAR(15)
AS BEGIN
    INSERT INTO BACSI VALUES(@MABS,@HOTEN_BS,@CHUYENKHOA,@NAMKINHNGHIEM,@MA_TRUONGKHOA)
END
GO

CREATE PROC SP_SuaBacSi
    @MABS VARCHAR(15), @HOTEN_BS NVARCHAR(100),
    @CHUYENKHOA NVARCHAR(100), @NAMKINHNGHIEM INT, @MA_TRUONGKHOA VARCHAR(15)
AS BEGIN
    UPDATE BACSI SET HOTEN_BS=@HOTEN_BS, CHUYENKHOA=@CHUYENKHOA,
        NAMKINHNGHIEM=@NAMKINHNGHIEM, MA_TRUONGKHOA=@MA_TRUONGKHOA
    WHERE MABS=@MABS
END
GO

CREATE PROC SP_XoaBacSi @MABS VARCHAR(15) AS
BEGIN DELETE FROM BACSI WHERE MABS=@MABS END
GO

CREATE PROC SP_BSLaoLang AS BEGIN SELECT * FROM VIEW_BSLaoLang END
GO

CREATE PROC SP_TimKiemBacSi
    @TuKhoa NVARCHAR(100) = NULL, @CHUYENKHOA NVARCHAR(100) = NULL
AS BEGIN
    SELECT * FROM VIEW_DanhSachBacSi
    WHERE (@TuKhoa IS NULL OR HOTEN_BS LIKE N'%' + @TuKhoa + N'%')
      AND (@CHUYENKHOA IS NULL OR CHUYENKHOA = @CHUYENKHOA)
END
GO

-- ── 5.B THI HÀI ─────────────────────────────────────────────
CREATE PROC SP_DSThiHai AS BEGIN SELECT * FROM VIEW_DanhSachThiHai END
GO

CREATE PROC SP_ThemThiHai
    @MATH VARCHAR(15), @HOTEN_TH NVARCHAR(100), @NGAYSINH DATE,
    @NGAYMAT DATE, @GIOITINH NVARCHAR(10)
AS BEGIN
    INSERT INTO THIHAI(MATH,HOTEN_TH,NGAYSINH,NGAYMAT,GIOITINH)
    VALUES(@MATH,@HOTEN_TH,@NGAYSINH,@NGAYMAT,@GIOITINH)
END
GO

CREATE PROC SP_SuaThiHai
    @MATH VARCHAR(15), @HOTEN_TH NVARCHAR(100), @NGAYSINH DATE,
    @NGAYMAT DATE, @GIOITINH NVARCHAR(10)
AS BEGIN
    UPDATE THIHAI SET HOTEN_TH=@HOTEN_TH, NGAYSINH=@NGAYSINH,
        NGAYMAT=@NGAYMAT, GIOITINH=@GIOITINH
    WHERE MATH=@MATH
END
GO

CREATE PROC SP_XoaThiHai @MATH VARCHAR(15) AS
BEGIN DELETE FROM THIHAI WHERE MATH=@MATH END
GO

CREATE PROC SP_CapNhatTrangThaiThiHai @MATH VARCHAR(15), @TRANGTHAI NVARCHAR(30)
AS BEGIN
    IF @TRANGTHAI NOT IN (
        N'Đang bảo quản',N'Đang khám nghiệm',N'Chờ bàn giao',N'Đã bàn giao',N'Đã mai táng')
    BEGIN RAISERROR(N'Trạng thái không hợp lệ.', 16, 1); RETURN END
    UPDATE THIHAI SET TRANGTHAI=@TRANGTHAI WHERE MATH=@MATH
END
GO

CREATE PROC SP_DemThiHai AS BEGIN SELECT COUNT(MATH) AS SoLuong FROM THIHAI END
GO

CREATE PROC SP_ThiHaiSot AS BEGIN
    SELECT * FROM VIEW_DanhSachThiHai
    WHERE MATH NOT IN (SELECT MATH FROM NGANKEO WHERE MATH IS NOT NULL)
END
GO

CREATE PROC SP_TimKiemThiHai
    @TuKhoa NVARCHAR(100) = NULL, @TRANGTHAI NVARCHAR(30) = NULL,
    @GIOITINH NVARCHAR(10) = NULL, @TuNgayMat DATE = NULL, @DenNgayMat DATE = NULL
AS BEGIN
    SELECT * FROM VIEW_DanhSachThiHai
    WHERE (@TuKhoa    IS NULL OR HOTEN_TH LIKE N'%' + @TuKhoa + N'%')
      AND (@TRANGTHAI IS NULL OR TRANGTHAI = @TRANGTHAI)
      AND (@GIOITINH  IS NULL OR GIOITINH  = @GIOITINH)
      AND (@TuNgayMat IS NULL OR NGAYMAT  >= @TuNgayMat)
      AND (@DenNgayMat IS NULL OR NGAYMAT  <= @DenNgayMat)
    ORDER BY NGAYMAT DESC
END
GO

CREATE PROC SP_TimKiem_ThiHai @keyword NVARCHAR(100) AS BEGIN
    SELECT * FROM VIEW_DanhSachThiHai
    WHERE HOTEN_TH LIKE N'%' + @keyword + N'%' OR MATH LIKE N'%' + @keyword + N'%'
    ORDER BY HOTEN_TH
END
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
        SELECT TOP 1 @MATH_XULY = MATH FROM THIHAI
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

-- ── 5.C NGĂN KÉO ────────────────────────────────────────────
CREATE PROC SP_DSNganKeo AS BEGIN SELECT * FROM VIEW_DanhSachNganKeo END
GO

CREATE PROC SP_ThemNganKeo
    @MANGAN VARCHAR(15), @VITRI NVARCHAR(50), @NHIETDO FLOAT, @MATH VARCHAR(15)
AS BEGIN
    INSERT INTO NGANKEO(MANGAN,VITRI,NHIETDO,MATH) VALUES(@MANGAN,@VITRI,@NHIETDO,@MATH)
END
GO

CREATE PROC SP_SuaNganKeo
    @ma VARCHAR(10), @vt NVARCHAR(100) = NULL,
    @nd FLOAT = NULL, @math VARCHAR(15) = NULL, @nhietDoCanhBao FLOAT = NULL
AS BEGIN
    SET NOCOUNT ON
    UPDATE NGANKEO SET
        VITRI            = ISNULL(@vt, VITRI),
        NHIETDO          = ISNULL(@nd, NHIETDO),
        MATH             = @math,
        NHIETDO_CANH_BAO = ISNULL(@nhietDoCanhBao, NHIETDO_CANH_BAO)
    WHERE MANGAN = @ma
END
GO

CREATE PROC SP_XoaNganKeo @MANGAN VARCHAR(15) AS BEGIN
    BEGIN TRANSACTION DELETE FROM NGANKEO WHERE MANGAN=@MANGAN COMMIT TRANSACTION
END
GO

CREATE PROC SP_XepNganKeo @MATH VARCHAR(15) AS
BEGIN
    DECLARE @MANGAN VARCHAR(15)
    SELECT TOP 1 @MANGAN = MANGAN FROM NGANKEO WHERE MATH IS NULL ORDER BY MANGAN
    IF @MANGAN IS NULL BEGIN PRINT N'Không còn ngăn kéo trống!'; RETURN END
    IF EXISTS (SELECT 1 FROM NGANKEO WHERE MATH = @MATH)
    BEGIN PRINT N'Thi hài đã được xếp vào ngăn kéo!'; RETURN END
    UPDATE NGANKEO SET MATH = @MATH WHERE MANGAN = @MANGAN
    PRINT N'Đã xếp thi hài vào ngăn: ' + @MANGAN
END
GO

CREATE PROC SP_ThongKeNganKeo AS BEGIN
    SELECT
        (SELECT COUNT(*) FROM NGANKEO) AS TongNgan,
        (SELECT COUNT(*) FROM NGANKEO WHERE MATH IS NOT NULL) AS DangDung,
        (SELECT COUNT(*) FROM NGANKEO WHERE MATH IS NULL) AS ConTrong,
        CAST((SELECT COUNT(*) FROM NGANKEO WHERE MATH IS NOT NULL) * 100.0
             / NULLIF((SELECT COUNT(*) FROM NGANKEO),0) AS DECIMAL(5,2)) AS PhanTramLapDay,
        (SELECT AVG(NHIETDO) FROM NGANKEO WHERE MATH IS NOT NULL) AS NhietDoTB
END
GO

-- ── 5.D HỒ SƠ KHÁM NGHIỆM ───────────────────────────────────
CREATE PROC SP_DSHoSoKhamNghiem AS BEGIN SELECT * FROM VIEW_HoSo_ChiTiet END
GO

CREATE PROC SP_ThemHoSoKhamBenh_V2
    @MAHS VARCHAR(15), @THOIGIANKHAM DATE, @KETLUAN NVARCHAR(50),
    @MATH VARCHAR(15), @MABS VARCHAR(15),
    @MACAUTU NVARCHAR(10) = NULL, @LOAICAUTU NVARCHAR(50) = NULL,
    @SOBIENBAN NVARCHAR(30) = NULL, @NGAYBIENBAN DATE = NULL,
    @COQUANYEUCAU NVARCHAR(150) = NULL, @GHICHUPHAY NVARCHAR(500) = NULL
AS BEGIN
    INSERT INTO HOSOKHAMBENH
    (MAHS,THOIGIANKHAM,KETLUAN,MATH,MABS,MACAUTU,LOAICAUTU,SOBIENBAN,NGAYBIENBAN,COQUANYEUCAU,GHICHUPHAY)
    VALUES(@MAHS,@THOIGIANKHAM,@KETLUAN,@MATH,@MABS,@MACAUTU,@LOAICAUTU,@SOBIENBAN,@NGAYBIENBAN,@COQUANYEUCAU,@GHICHUPHAY)
    UPDATE THIHAI SET TRANGTHAI = N'Đang khám nghiệm' WHERE MATH = @MATH
    UPDATE CANH_BAO SET DAOC = 1 WHERE MATH = @MATH AND LOAICB = N'ChuaKham' AND DAOC = 0
END
GO

CREATE PROC SP_SuaHoSoKhamBenh_V2
    @MAHS VARCHAR(15), @THOIGIANKHAM DATE, @KETLUAN NVARCHAR(50),
    @MATH VARCHAR(15), @MABS VARCHAR(15),
    @MACAUTU NVARCHAR(10) = NULL, @LOAICAUTU NVARCHAR(50) = NULL,
    @SOBIENBAN NVARCHAR(30) = NULL, @NGAYBIENBAN DATE = NULL,
    @COQUANYEUCAU NVARCHAR(150) = NULL, @GHICHUPHAY NVARCHAR(500) = NULL
AS BEGIN
    UPDATE HOSOKHAMBENH
    SET THOIGIANKHAM=@THOIGIANKHAM,KETLUAN=@KETLUAN,MATH=@MATH,MABS=@MABS,
        MACAUTU=@MACAUTU,LOAICAUTU=@LOAICAUTU,SOBIENBAN=@SOBIENBAN,
        NGAYBIENBAN=@NGAYBIENBAN,COQUANYEUCAU=@COQUANYEUCAU,GHICHUPHAY=@GHICHUPHAY
    WHERE MAHS=@MAHS
END
GO

CREATE PROC SP_XoaHoSoKhamBenh @MAHS VARCHAR(15) AS BEGIN
    BEGIN TRANSACTION
        DELETE FROM HOSOKHAMBENH WHERE MAHS=@MAHS
    COMMIT TRANSACTION
END
GO

CREATE PROC SP_PhanCongBacSi
    @MATH VARCHAR(15), @MABS VARCHAR(15), @MAHS VARCHAR(15), @THOIGIANKHAM DATE
AS BEGIN
    IF (SELECT COUNT(*) FROM HOSOKHAMBENH WHERE MABS = @MABS AND THOIGIANKHAM = @THOIGIANKHAM) >= 3
    BEGIN PRINT N'Bác sĩ đã đủ 3 ca hôm nay!'; RETURN END
    EXEC SP_ThemHoSoKhamBenh_V2
        @MAHS=@MAHS,@THOIGIANKHAM=@THOIGIANKHAM,@KETLUAN=NULL,@MATH=@MATH,@MABS=@MABS
END
GO

-- ── 5.E DỊCH VỤ ─────────────────────────────────────────────
CREATE PROC SP_DSDichVu AS BEGIN SELECT * FROM VIEW_DichVu END
GO

CREATE PROC SP_ThemDichVu @MADV VARCHAR(15), @TENDV NVARCHAR(100), @GIA MONEY
AS BEGIN INSERT INTO DICHVU VALUES(@MADV,@TENDV,@GIA) END
GO

CREATE PROC SP_SuaDichVu @MADV VARCHAR(15), @TENDV NVARCHAR(100), @GIA MONEY
AS BEGIN UPDATE DICHVU SET TENDV=@TENDV, GIATIEN=@GIA WHERE MADV=@MADV END
GO

CREATE PROC SP_XoaDichVu @MADV VARCHAR(15) AS BEGIN
    BEGIN TRANSACTION DELETE FROM DICHVU WHERE MADV=@MADV COMMIT TRANSACTION
END
GO

CREATE PROC SP_DichVuE AS BEGIN SELECT * FROM VIEW_DichVuE END
GO

-- ── 5.F SỬ DỤNG DỊCH VỤ ────────────────────────────────────
CREATE PROC SP_DSDichVuSuDung @MATH VARCHAR(15) = NULL AS BEGIN
    IF @MATH IS NULL SELECT * FROM VIEW_DichVuSuDung
    ELSE SELECT * FROM VIEW_DichVuSuDung WHERE MATH = @MATH
END
GO

CREATE PROC SP_ThemDichVuSuDung
    @MATH VARCHAR(15), @MADV VARCHAR(15), @NGAYSD DATE,
    @GHICHU NVARCHAR(200), @SOLUONG INT = 1
AS BEGIN
    IF EXISTS (SELECT 1 FROM SUDUNG WHERE MATH=@MATH AND MADV=@MADV AND NGAYSUDUNG=@NGAYSD)
        UPDATE SUDUNG SET SOLUONG=SOLUONG+@SOLUONG, GHICHU=ISNULL(@GHICHU,GHICHU)
        WHERE MATH=@MATH AND MADV=@MADV AND NGAYSUDUNG=@NGAYSD
    ELSE
        INSERT INTO SUDUNG(MATH,MADV,NGAYSUDUNG,SOLUONG,GHICHU,MAHD)
        VALUES(@MATH,@MADV,@NGAYSD,@SOLUONG,@GHICHU,NULL)
END
GO

CREATE PROC SP_SuaDichVuSudung
    @MATH VARCHAR(15), @MADV VARCHAR(15), @NGAYSD DATE, @GHICHU NVARCHAR(200)
AS BEGIN
    UPDATE SUDUNG SET GHICHU=@GHICHU WHERE MATH=@MATH AND MADV=@MADV AND NGAYSUDUNG=@NGAYSD
END
GO

CREATE PROC SP_XoaDichVuSuDung
    @MATH VARCHAR(15), @MADV VARCHAR(15), @NGAYSD DATE
AS BEGIN
    BEGIN TRANSACTION
        DELETE FROM SUDUNG WHERE MATH=@MATH AND MADV=@MADV AND NGAYSUDUNG=@NGAYSD
    COMMIT TRANSACTION
END
GO

CREATE PROC SP_DichVuTheoHoaDon @MAHD VARCHAR(15) AS BEGIN
    SELECT sd.MATH,th.HOTEN_TH,sd.MADV,dv.TENDV,dv.GIATIEN,sd.SOLUONG,
           dv.GIATIEN*sd.SOLUONG AS THANHTIEN,sd.NGAYSUDUNG,sd.GHICHU,sd.MAHD
    FROM SUDUNG sd
    JOIN DICHVU dv ON sd.MADV=dv.MADV
    JOIN THIHAI th ON sd.MATH=th.MATH
    WHERE sd.MAHD=@MAHD ORDER BY sd.NGAYSUDUNG
END
GO

CREATE PROC SP_DichVuChuaLapHD @MATH VARCHAR(15) AS BEGIN
    SELECT sd.MATH,th.HOTEN_TH,sd.MADV,dv.TENDV,dv.GIATIEN,sd.SOLUONG,
           dv.GIATIEN*sd.SOLUONG AS THANHTIEN,sd.NGAYSUDUNG,sd.GHICHU
    FROM SUDUNG sd
    JOIN DICHVU dv ON sd.MADV=dv.MADV
    JOIN THIHAI th ON sd.MATH=th.MATH
    WHERE sd.MATH=@MATH AND sd.MAHD IS NULL ORDER BY sd.NGAYSUDUNG
END
GO

CREATE PROCEDURE sp_TinhTongTienDichVu
    @MaTH VARCHAR(15), @TongTien MONEY OUTPUT
AS BEGIN
    SELECT @TongTien = ISNULL(SUM(DV.GIATIEN * SD.SOLUONG), 0)
    FROM SUDUNG SD JOIN DICHVU DV ON SD.MADV=DV.MADV
    WHERE SD.MATH=@MaTH AND SD.MAHD IS NULL
END
GO

-- ── 5.G THÂN NHÂN ───────────────────────────────────────────
CREATE PROC SP_DSThanNhan @MATH VARCHAR(15) AS BEGIN
    SELECT * FROM VIEW_ThanNhanThiHai WHERE MATH=@MATH ORDER BY LALIENDHE DESC
END
GO

CREATE PROC SP_ThemThanNhan
    @MATN VARCHAR(15), @MATH VARCHAR(15), @HOTEN_TN NVARCHAR(100),
    @QUANHE NVARCHAR(50), @DIENTHOAI VARCHAR(15), @DIACHI NVARCHAR(200),
    @LALIENDHE BIT, @GHICHU NVARCHAR(200)
AS BEGIN
    IF @LALIENDHE = 1 UPDATE THAN_NHAN SET LALIENDHE=0 WHERE MATH=@MATH
    INSERT INTO THAN_NHAN(MATN,MATH,HOTEN_TN,QUANHE,DIENTHOAI,DIACHI,LALIENDHE,GHICHU)
    VALUES(@MATN,@MATH,@HOTEN_TN,@QUANHE,@DIENTHOAI,@DIACHI,@LALIENDHE,@GHICHU)
END
GO

CREATE PROC SP_SuaThanNhan
    @MATN VARCHAR(15), @HOTEN_TN NVARCHAR(100), @QUANHE NVARCHAR(50),
    @DIENTHOAI VARCHAR(15), @DIACHI NVARCHAR(200), @LALIENDHE BIT, @GHICHU NVARCHAR(200)
AS BEGIN
    DECLARE @MATH VARCHAR(15)
    SELECT @MATH=MATH FROM THAN_NHAN WHERE MATN=@MATN
    IF @LALIENDHE=1 UPDATE THAN_NHAN SET LALIENDHE=0 WHERE MATH=@MATH AND MATN<>@MATN
    UPDATE THAN_NHAN SET HOTEN_TN=@HOTEN_TN,QUANHE=@QUANHE,DIENTHOAI=@DIENTHOAI,
        DIACHI=@DIACHI,LALIENDHE=@LALIENDHE,GHICHU=@GHICHU WHERE MATN=@MATN
END
GO

CREATE PROC SP_XoaThanNhan @MATN VARCHAR(15) AS
BEGIN DELETE FROM THAN_NHAN WHERE MATN=@MATN END
GO

CREATE PROC SP_TimKiem_ThanNhan @keyword NVARCHAR(100) AS BEGIN
    SELECT tn.MATN,tn.MATH,tn.HOTEN_TN,tn.DIENTHOAI,th.HOTEN_TH
    FROM THAN_NHAN tn JOIN THIHAI th ON tn.MATH=th.MATH
    WHERE tn.HOTEN_TN LIKE N'%'+@keyword+N'%'
       OR tn.DIENTHOAI LIKE N'%'+@keyword+N'%'
       OR tn.MATH LIKE N'%'+@keyword+N'%'
       OR th.HOTEN_TH LIKE N'%'+@keyword+N'%'
    ORDER BY tn.HOTEN_TN
END
GO

-- ── 5.H HÓA ĐƠN ─────────────────────────────────────────────
CREATE PROC SP_DSHoaDon AS BEGIN SELECT * FROM VIEW_HoaDonChiTiet ORDER BY NGAYLAP DESC END
GO

CREATE PROC SP_ThemHoaDon
    @MAHD VARCHAR(15), @MATH VARCHAR(15), @NGAYLAP DATE,
    @PHUONGTHUCTT NVARCHAR(30), @GHICHU NVARCHAR(200)
AS BEGIN
    DECLARE @TongTien MONEY
    EXEC sp_TinhTongTienDichVu @MATH, @TongTien OUTPUT
    IF @TongTien = 0
    BEGIN RAISERROR(N'Không có dịch vụ nào chưa lập hóa đơn.', 16, 1); RETURN END
    INSERT INTO HOADON(MAHD,MATH,NGAYLAP,TONGTIEN,TRANGTHAITT,PHUONGTHUCTT,NGUOILAP,GHICHU)
    VALUES(@MAHD,@MATH,@NGAYLAP,@TongTien,N'Chưa thanh toán',@PHUONGTHUCTT,SUSER_SNAME(),@GHICHU)
    UPDATE SUDUNG SET MAHD=@MAHD WHERE MATH=@MATH AND MAHD IS NULL
END
GO

CREATE PROC SP_ThanhToanHoaDon @MAHD VARCHAR(15), @PHUONGTHUCTT NVARCHAR(30) AS BEGIN
    UPDATE HOADON SET TRANGTHAITT=N'Đã thanh toán',
        PHUONGTHUCTT=@PHUONGTHUCTT,NGAYTHANHTOAN=CAST(GETDATE() AS DATE)
    WHERE MAHD=@MAHD
END
GO

CREATE PROC SP_HoaDonTheoThiHai @MATH VARCHAR(15) AS
BEGIN SELECT * FROM VIEW_HoaDonChiTiet WHERE MATH=@MATH END
GO

CREATE PROC SP_TimKiem_HoaDon @keyword NVARCHAR(100) AS BEGIN
    SELECT hd.MAHD,hd.MATH,hd.NGAYLAP,hd.TONGTIEN,hd.TRANGTHAITT,th.HOTEN_TH
    FROM HOADON hd JOIN THIHAI th ON hd.MATH=th.MATH
    WHERE hd.MAHD LIKE N'%'+@keyword+N'%'
       OR th.HOTEN_TH LIKE N'%'+@keyword+N'%'
       OR hd.MATH LIKE N'%'+@keyword+N'%'
END
GO

-- ── 5.I BÀN GIAO THI HÀI ────────────────────────────────────
CREATE PROC SP_BanGiaoThiHai @MATH VARCHAR(15) AS BEGIN
    IF dbo.FN_KiemTraHoaDonDuocThanhToan(@MATH) = 0
    BEGIN PRINT N'Hóa đơn chưa thanh toán!'; RETURN END
    EXEC SP_CapNhatTrangThaiThiHai @MATH, N'Đã bàn giao'
    UPDATE NGANKEO SET MATH=NULL WHERE MATH=@MATH
    PRINT N'Đã bàn giao thi hài ' + @MATH
END
GO

-- ── 5.J CẢNH BÁO ────────────────────────────────────────────
CREATE PROC SP_DSCanhBao AS
BEGIN SELECT * FROM VIEW_CanhBaoChuaDoc ORDER BY MUC_DO_UU_TIEN, THOIGIAN DESC END
GO

CREATE PROC SP_DocCanhBao @MACB INT AS
BEGIN UPDATE CANH_BAO SET DAOC=1 WHERE MACB=@MACB END
GO

CREATE PROC SP_DocHetCanhBao AS BEGIN UPDATE CANH_BAO SET DAOC=1 WHERE DAOC=0 END
GO

CREATE PROC SP_QuetCanhBao AS BEGIN
    SET NOCOUNT ON
    INSERT INTO CANH_BAO(LOAICB,MATH,NOIDUNG)
    SELECT N'QuaHan',th.MATH,
           N'Thi hài '+ISNULL(th.HOTEN_TH,th.MATH)+N' sắp quá hạn! Còn '
           +CAST(15-DATEDIFF(DAY,th.NGAYMAT,GETDATE()) AS NVARCHAR(5))+N' ngày.'
    FROM THIHAI th
    WHERE DATEDIFF(DAY,th.NGAYMAT,GETDATE()) BETWEEN 12 AND 15
      AND th.MATH NOT IN (SELECT MATH FROM NGANKEO WHERE MATH IS NOT NULL)
      AND NOT EXISTS (SELECT 1 FROM CANH_BAO cb WHERE cb.MATH=th.MATH AND cb.LOAICB=N'QuaHan' AND cb.DAOC=0)

    INSERT INTO CANH_BAO(LOAICB,MATH,NOIDUNG)
    SELECT N'ChuaKham',th.MATH,
           N'Thi hài '+ISNULL(th.HOTEN_TH,th.MATH)+N' chưa khám sau '
           +CAST(DATEDIFF(DAY,th.NGAYMAT,GETDATE()) AS NVARCHAR(5))+N' ngày.'
    FROM THIHAI th
    WHERE DATEDIFF(DAY,th.NGAYMAT,GETDATE()) > 3
      AND th.MATH NOT IN (SELECT MATH FROM HOSOKHAMBENH)
      AND NOT EXISTS (SELECT 1 FROM CANH_BAO cb WHERE cb.MATH=th.MATH AND cb.LOAICB=N'ChuaKham' AND cb.DAOC=0)

    SELECT COUNT(*) AS SoCanhBaoMoi FROM CANH_BAO WHERE DAOC=0
END
GO

-- ── 5.K NHÂN VIÊN ───────────────────────────────────────────
CREATE PROC SP_DSNhanVien AS BEGIN
    SELECT MANV,HOTEN_NV,CHUCVU,DIENTHOAI FROM NHANVIEN ORDER BY HOTEN_NV
END
GO

CREATE PROC SP_ThemNhanVien
    @MANV VARCHAR(15), @HOTEN_NV NVARCHAR(100), @CHUCVU NVARCHAR(100), @DIENTHOAI VARCHAR(15)
AS BEGIN
    INSERT INTO NHANVIEN(MANV,HOTEN_NV,CHUCVU,DIENTHOAI)
    VALUES(@MANV,@HOTEN_NV,@CHUCVU,@DIENTHOAI)
END
GO

CREATE PROC SP_SuaNhanVien
    @MANV VARCHAR(15), @HOTEN_NV NVARCHAR(100), @CHUCVU NVARCHAR(100), @DIENTHOAI VARCHAR(15)
AS BEGIN
    UPDATE NHANVIEN SET HOTEN_NV=@HOTEN_NV,CHUCVU=@CHUCVU,DIENTHOAI=@DIENTHOAI WHERE MANV=@MANV
END
GO

CREATE PROC SP_XoaNhanVien @MANV VARCHAR(15) AS
BEGIN DELETE FROM NHANVIEN WHERE MANV=@MANV END
GO

-- ── 5.L BÁO CÁO & DASHBOARD ─────────────────────────────────
CREATE PROC SP_Dashboard AS BEGIN SELECT * FROM VIEW_Dashboard END
GO

CREATE PROC SP_BaoCao_ThiHaiTheoThang @Nam INT = NULL AS BEGIN
    SET @Nam=ISNULL(@Nam,YEAR(GETDATE()))
    SELECT * FROM VIEW_ThongKe_TheoThang WHERE Nam=@Nam ORDER BY Thang
END
GO

CREATE PROC SP_BaoCao_DoanhThuTheoThang @Nam INT = NULL AS BEGIN
    SET @Nam=ISNULL(@Nam,YEAR(GETDATE()))
    SELECT * FROM VIEW_ThongKe_DoanhThu WHERE Nam=@Nam ORDER BY Thang
END
GO

-- ── 5.M AUDIT LOG ───────────────────────────────────────────
CREATE PROC SP_XemAuditLog
    @TENTABLE NVARCHAR(50)=NULL, @TuNgay DATE=NULL, @DenNgay DATE=NULL, @SoLuong INT=200
AS BEGIN
    SELECT TOP (@SoLuong)
        MALOG,THOIGIAN,TENUSER,TENTABLE,HANHDOG,MABANGHI,NOIDUNG
    FROM AUDIT_LOG
    WHERE (@TENTABLE IS NULL OR TENTABLE=@TENTABLE)
      AND (@TuNgay IS NULL OR CAST(THOIGIAN AS DATE)>=@TuNgay)
      AND (@DenNgay IS NULL OR CAST(THOIGIAN AS DATE)<=@DenNgay)
    ORDER BY THOIGIAN DESC
END
GO

CREATE PROC SP_XoaAuditLogCu @SoNgayGiu INT=90 AS BEGIN
    DELETE FROM AUDIT_LOG WHERE DATEDIFF(DAY,THOIGIAN,GETDATE())>@SoNgayGiu
    PRINT N'Đã xóa log cũ hơn '+CAST(@SoNgayGiu AS NVARCHAR(5))+N' ngày.'
END
GO

-- ── 5.N PHÂN QUYỀN ĐỘNG ─────────────────────────────────────
CREATE PROC SP_KiemTraQuyenHan AS BEGIN
    IF (IS_ROLEMEMBER('QL_ADMIN')=1 OR IS_ROLEMEMBER('db_owner')=1)
        SELECT 'Admin' AS QuyenHan
    ELSE IF (IS_ROLEMEMBER('QL_BACSI')=1 OR IS_ROLEMEMBER('QL_NHANVIEN')=1)
        SELECT 'Staff' AS QuyenHan
    ELSE SELECT 'ReadOnly' AS QuyenHan
END
GO

CREATE PROCEDURE SP_DanhSachUser AS BEGIN
    SELECT dp.name AS TenUser, dp.type_desc AS LoaiUser,
           ISNULL(sp.name,'(No Login)') AS TenLogin, dp.create_date AS NgayTao
    FROM sys.database_principals dp
    LEFT JOIN sys.server_principals sp ON dp.sid=sp.sid
    WHERE dp.type IN ('S','U','G')
      AND dp.name NOT IN ('dbo','guest','INFORMATION_SCHEMA','sys')
      AND dp.name NOT LIKE '##%'
    ORDER BY dp.name
END
GO

CREATE PROCEDURE SP_DanhSachRole AS BEGIN
    SELECT name AS TenRole, type_desc AS LoaiRole, create_date AS NgayTao
    FROM sys.database_principals
    WHERE type='R' AND is_fixed_role=0 AND name NOT IN ('public')
    ORDER BY name
END
GO

CREATE PROCEDURE SP_UserTrongRole @TenRole NVARCHAR(128) AS BEGIN
    SELECT u.name AS TenUser, u.type_desc AS LoaiUser
    FROM sys.database_role_members rm
    JOIN sys.database_principals r ON rm.role_principal_id=r.principal_id
    JOIN sys.database_principals u ON rm.member_principal_id=u.principal_id
    WHERE r.name=@TenRole ORDER BY u.name
END
GO

CREATE PROCEDURE SP_GrantUserVaoRole @TenUser NVARCHAR(128), @TenRole NVARCHAR(128) AS BEGIN
    DECLARE @sql NVARCHAR(MAX)=N'ALTER ROLE ['+@TenRole+N'] ADD MEMBER ['+@TenUser+N']'
    EXEC sp_executesql @sql
END
GO

CREATE PROCEDURE SP_RevokeUserKhoiRole @TenUser NVARCHAR(128), @TenRole NVARCHAR(128) AS BEGIN
    DECLARE @sql NVARCHAR(MAX)=N'ALTER ROLE ['+@TenRole+N'] DROP MEMBER ['+@TenUser+N']'
    EXEC sp_executesql @sql
END
GO

-- ============================================================
-- 6. TRIGGER
-- ============================================================

-- ── 6.1 Kiểm tra ngày khám >= ngày mất ──────────────────────
CREATE TRIGGER TRG_KiemTraNgayKham
ON HOSOKHAMBENH FOR INSERT, UPDATE
AS BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN THIHAI th ON i.MATH=th.MATH
        WHERE i.THOIGIANKHAM < th.NGAYMAT
    ) BEGIN PRINT N'Lỗi: Ngày khám không được trước ngày mất!'; ROLLBACK TRANSACTION END
END
GO

-- ── 6.2 Kiểm tra ngày dịch vụ >= ngày mất ──────────────────
CREATE TRIGGER TRG_KiemTraNgayDichVu
ON SUDUNG FOR INSERT, UPDATE
AS BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN THIHAI th ON i.MATH=th.MATH
        WHERE i.NGAYSUDUNG < th.NGAYMAT
    ) BEGIN PRINT N'Lỗi: Ngày sử dụng dịch vụ sớm hơn ngày mất!'; ROLLBACK TRANSACTION END
END
GO

-- ── 6.3 Bác sĩ không tự làm trưởng khoa ────────────────────
CREATE TRIGGER TRG_KiemTraTruongKhoa
ON BACSI FOR INSERT, UPDATE
AS BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE MABS=MA_TRUONGKHOA)
    BEGIN PRINT N'Lỗi: Bác sĩ không thể tự nhận mình là trưởng khoa!'; ROLLBACK TRANSACTION END
END
GO

-- ── 6.4 Cascade delete thi hài ──────────────────────────────
CREATE TRIGGER TRG_CascadeDelete_ThiHai
ON THIHAI INSTEAD OF DELETE
AS BEGIN
    DELETE FROM HOSOKHAMBENH WHERE MATH IN (SELECT MATH FROM deleted)
    DELETE FROM SUDUNG       WHERE MATH IN (SELECT MATH FROM deleted)
    DELETE FROM THAN_NHAN    WHERE MATH IN (SELECT MATH FROM deleted)
    DELETE FROM HOADON       WHERE MATH IN (SELECT MATH FROM deleted)
    UPDATE NGANKEO SET MATH=NULL WHERE MATH IN (SELECT MATH FROM deleted)
    DELETE FROM THIHAI       WHERE MATH IN (SELECT MATH FROM deleted)
    PRINT N'Đã xóa thi hài thành công'
END
GO

-- ── 6.5 Tự động đăng ký bảo quản lạnh khi xếp vào ngăn ─────
CREATE TRIGGER TRG_TuDongBaoQuanLanh
ON NGANKEO AFTER UPDATE
AS BEGIN
    SET NOCOUNT ON
    IF UPDATE(MATH)
    BEGIN
        INSERT INTO SUDUNG(MATH,MADV,NGAYSUDUNG,SOLUONG,GHICHU,MAHD)
        SELECT i.MATH,'DV003',CAST(GETDATE() AS DATE),1,N'Tự động - nhập tủ lạnh',NULL
        FROM inserted i
        JOIN deleted d ON i.MANGAN=d.MANGAN
        WHERE i.MATH IS NOT NULL AND d.MATH IS NULL
          AND NOT EXISTS (SELECT 1 FROM SUDUNG s WHERE s.MATH=i.MATH AND s.MADV='DV003'
                          AND s.NGAYSUDUNG=CAST(GETDATE() AS DATE))
    END
END
GO

-- ── 6.6 Cảnh báo nhiệt độ ───────────────────────────────────
CREATE TRIGGER TRG_CanhBaoNhietDoNganKeo
ON NGANKEO FOR UPDATE
AS BEGIN
    SET NOCOUNT ON
    IF UPDATE(NHIETDO)
    BEGIN
        INSERT INTO CANH_BAO(LOAICB,MANGAN,NOIDUNG)
        SELECT N'NhietDo',i.MANGAN,
               N'Cảnh báo: Ngăn '+i.MANGAN+N' nhiệt độ '
               +CAST(i.NHIETDO AS NVARCHAR(10))+N'°C vượt ngưỡng!'
        FROM inserted i WHERE i.MATH IS NOT NULL AND i.NHIETDO > 0
        IF EXISTS (SELECT 1 FROM inserted WHERE MATH IS NOT NULL AND NHIETDO > 0)
        BEGIN PRINT N'Cảnh báo nghiêm trọng: Nhiệt độ > 0°C!'; ROLLBACK TRANSACTION END
    END
END
GO

-- ── 6.7 Cấm xóa hồ sơ pháp y ───────────────────────────────
CREATE TRIGGER TRG_BaoVeHoSoPhapY
ON HOSOKHAMBENH FOR DELETE
AS BEGIN PRINT N'Hồ sơ pháp y không được phép xóa!'; ROLLBACK TRANSACTION END
GO

-- ── 6.8 Giới hạn 3 ca khám/bác sĩ/ngày ─────────────────────
CREATE TRIGGER TRG_GioiHanCaKhamBacSi
ON HOSOKHAMBENH FOR INSERT, UPDATE
AS BEGIN
    IF EXISTS (
        SELECT i.MABS, i.THOIGIANKHAM FROM inserted i
        JOIN HOSOKHAMBENH hs ON i.MABS=hs.MABS AND i.THOIGIANKHAM=hs.THOIGIANKHAM
        GROUP BY i.MABS, i.THOIGIANKHAM HAVING COUNT(*) > 3
    ) BEGIN PRINT N'Lỗi: Bác sĩ không thể quá 3 ca/ngày!'; ROLLBACK TRANSACTION END
END
GO

-- ── 6.9 Kiểm soát luồng trạng thái ─────────────────────────
CREATE TRIGGER TRG_ValidateTrangThai
ON THIHAI INSTEAD OF UPDATE
AS BEGIN
    SET NOCOUNT ON
    IF EXISTS (
        SELECT 1 FROM inserted i JOIN deleted d ON i.MATH=d.MATH
        WHERE d.TRANGTHAI=N'Đã mai táng' AND i.TRANGTHAI<>N'Đã mai táng'
    ) BEGIN PRINT N'Lỗi: Không thể thay đổi trạng thái thi hài đã mai táng!'; ROLLBACK TRANSACTION; RETURN END

    UPDATE THIHAI SET
        HOTEN_TH=i.HOTEN_TH, NGAYSINH=i.NGAYSINH, NGAYMAT=i.NGAYMAT,
        GIOITINH=i.GIOITINH, TRANGTHAI=i.TRANGTHAI,
        NOITIMTHAY=i.NOITIMTHAY, COCUANHAN=i.COCUANHAN, NGAYNHAP=i.NGAYNHAP
    FROM THIHAI th JOIN inserted i ON th.MATH=i.MATH
END
GO

-- ── 6.10 Tự động cập nhật trạng thái khi đổi ngăn ──────────
CREATE TRIGGER TRG_CapNhatTrangThaiThiHai
ON NGANKEO AFTER UPDATE
AS BEGIN
    SET NOCOUNT ON
    IF UPDATE(MATH)
    BEGIN
        -- Xếp vào ngăn → Đang bảo quản
        UPDATE THIHAI SET TRANGTHAI=N'Đang bảo quản'
        FROM THIHAI th JOIN inserted i ON th.MATH=i.MATH JOIN deleted d ON d.MANGAN=i.MANGAN
        WHERE i.MATH IS NOT NULL AND d.MATH IS NULL

        -- Lấy ra khỏi ngăn → Chờ bàn giao
        UPDATE THIHAI SET TRANGTHAI=N'Chờ bàn giao'
        FROM THIHAI th JOIN deleted d ON th.MATH=d.MATH JOIN inserted i ON i.MANGAN=d.MANGAN
        WHERE i.MATH IS NULL AND d.MATH IS NOT NULL
    END
END
GO

-- ── 6.11 Cảnh báo thi hài mới chưa khám ────────────────────
CREATE TRIGGER TRG_CanhBaoChuaKham
ON THIHAI AFTER INSERT
AS BEGIN
    SET NOCOUNT ON
    INSERT INTO CANH_BAO(LOAICB,MATH,NOIDUNG)
    SELECT N'ChuaKham',i.MATH,
           N'Thi hài '+ISNULL(i.HOTEN_TH,i.MATH)+N' vừa nhập - chưa phân công bác sĩ.'
    FROM inserted i
END
GO

-- ── 6.12 Audit log: thi hài ─────────────────────────────────
CREATE TRIGGER TRG_Audit_ThiHai
ON THIHAI AFTER INSERT, UPDATE, DELETE
AS BEGIN
    SET NOCOUNT ON
    DECLARE @action NVARCHAR(10)
    IF EXISTS(SELECT 1 FROM inserted) AND EXISTS(SELECT 1 FROM deleted) SET @action='UPDATE'
    ELSE IF EXISTS(SELECT 1 FROM inserted) SET @action='INSERT'
    ELSE SET @action='DELETE'
    IF @action IN ('INSERT','UPDATE')
        INSERT INTO AUDIT_LOG(TENTABLE,HANHDOG,MABANGHI,NOIDUNG)
        SELECT 'THIHAI',@action,i.MATH,
               N'['+@action+N'] '+ISNULL(i.HOTEN_TH,N'?')+N' | TT: '+ISNULL(i.TRANGTHAI,N'?')
        FROM inserted i
    ELSE
        INSERT INTO AUDIT_LOG(TENTABLE,HANHDOG,MABANGHI,NOIDUNG)
        SELECT 'THIHAI',@action,d.MATH,N'[DELETE] '+ISNULL(d.HOTEN_TH,N'?') FROM deleted d
END
GO

-- ── 6.13 Audit log: hồ sơ ───────────────────────────────────
CREATE TRIGGER TRG_Audit_HoSo
ON HOSOKHAMBENH AFTER INSERT, UPDATE
AS BEGIN
    SET NOCOUNT ON
    DECLARE @action NVARCHAR(10)=CASE WHEN EXISTS(SELECT 1 FROM deleted) THEN 'UPDATE' ELSE 'INSERT' END
    INSERT INTO AUDIT_LOG(TENTABLE,HANHDOG,MABANGHI,NOIDUNG)
    SELECT 'HOSOKHAMBENH',@action,i.MAHS,
           N'['+@action+N'] HS:'+i.MAHS+N'|TH:'+i.MATH+N'|BS:'+i.MABS
    FROM inserted i
END
GO

-- ── 6.14 Audit log: ngăn kéo ────────────────────────────────
CREATE TRIGGER TRG_Audit_NganKeo
ON NGANKEO AFTER INSERT, UPDATE
AS BEGIN
    SET NOCOUNT ON
    DECLARE @action NVARCHAR(10)=CASE WHEN EXISTS(SELECT 1 FROM deleted) THEN 'UPDATE' ELSE 'INSERT' END
    INSERT INTO AUDIT_LOG(TENTABLE,HANHDOG,MABANGHI,NOIDUNG)
    SELECT 'NGANKEO',@action,i.MANGAN,
           N'['+@action+N'] '+i.MANGAN+N' | '+CAST(i.NHIETDO AS NVARCHAR(10))+N'°C | '+ISNULL(i.MATH,N'Trống')
    FROM inserted i
END
GO

-- ── 6.15 Audit log: dịch vụ ─────────────────────────────────
CREATE TRIGGER TRG_Audit_SuDung
ON SUDUNG AFTER INSERT, UPDATE, DELETE
AS BEGIN
    SET NOCOUNT ON
    DECLARE @action NVARCHAR(10)
    IF EXISTS(SELECT 1 FROM inserted) AND EXISTS(SELECT 1 FROM deleted) SET @action='UPDATE'
    ELSE IF EXISTS(SELECT 1 FROM inserted) SET @action='INSERT'
    ELSE SET @action='DELETE'
    IF @action IN ('INSERT','UPDATE')
        INSERT INTO AUDIT_LOG(TENTABLE,HANHDOG,MABANGHI,NOIDUNG)
        SELECT 'SUDUNG',@action,i.MATH+'-'+i.MADV,N'['+@action+N'] TH:'+i.MATH+N' DV:'+i.MADV FROM inserted i
    ELSE
        INSERT INTO AUDIT_LOG(TENTABLE,HANHDOG,MABANGHI,NOIDUNG)
        SELECT 'SUDUNG',@action,d.MATH+'-'+d.MADV,N'[DELETE] TH:'+d.MATH+N' DV:'+d.MADV FROM deleted d
END
GO

-- ── 6.16 Audit log: hóa đơn ─────────────────────────────────
CREATE TRIGGER TRG_Audit_HoaDon
ON HOADON AFTER INSERT, UPDATE
AS BEGIN
    SET NOCOUNT ON
    DECLARE @action NVARCHAR(10)=CASE WHEN EXISTS(SELECT 1 FROM deleted) THEN 'UPDATE' ELSE 'INSERT' END
    INSERT INTO AUDIT_LOG(TENTABLE,HANHDOG,MABANGHI,NOIDUNG)
    SELECT 'HOADON',@action,i.MAHD,
           N'['+@action+N'] HD:'+i.MAHD+N' TH:'+i.MATH+N' '+CAST(i.TONGTIEN AS NVARCHAR(20))+N'đ|'+i.TRANGTHAITT
    FROM inserted i
END
GO

-- ── 6.17 Audit log: nhân viên ───────────────────────────────
CREATE TRIGGER TRG_Audit_NhanVien
ON NHANVIEN AFTER INSERT, UPDATE, DELETE
AS BEGIN
    SET NOCOUNT ON
    DECLARE @action NVARCHAR(10)
    IF EXISTS(SELECT 1 FROM inserted) AND EXISTS(SELECT 1 FROM deleted) SET @action='UPDATE'
    ELSE IF EXISTS(SELECT 1 FROM inserted) SET @action='INSERT'
    ELSE SET @action='DELETE'
    IF @action IN ('INSERT','UPDATE')
        INSERT INTO AUDIT_LOG(TENTABLE,HANHDOG,MABANGHI,NOIDUNG)
        SELECT 'NHANVIEN',@action,i.MANV,N'['+@action+N'] '+ISNULL(i.HOTEN_NV,N'?') FROM inserted i
    ELSE
        INSERT INTO AUDIT_LOG(TENTABLE,HANHDOG,MABANGHI,NOIDUNG)
        SELECT 'NHANVIEN',@action,d.MANV,N'[DELETE] '+ISNULL(d.HOTEN_NV,N'?') FROM deleted d
END
GO

-- ── 6.18 Tự động tạo hóa đơn khi bàn giao ──────────────────
CREATE TRIGGER TRG_TaoHoaDonKhiBanGiao
ON THIHAI AFTER UPDATE
AS BEGIN
    SET NOCOUNT ON
    IF UPDATE(TRANGTHAI)
    BEGIN
        INSERT INTO HOADON(MAHD,MATH,NGAYLAP,TONGTIEN,TRANGTHAITT,NGUOILAP)
        SELECT
            'HD'+RIGHT('0000'+CAST(
                ISNULL((SELECT MAX(CAST(SUBSTRING(MAHD,3,10) AS INT)) FROM HOADON),0)+1
            AS NVARCHAR(10)),4),
            i.MATH, CAST(GETDATE() AS DATE),
            ISNULL(dbo.FN_TinhTongTienDichVu(i.MATH),0),
            N'Chưa thanh toán', SUSER_SNAME()
        FROM inserted i JOIN deleted d ON i.MATH=d.MATH
        WHERE i.TRANGTHAI=N'Đã bàn giao' AND d.TRANGTHAI<>N'Đã bàn giao'
          AND NOT EXISTS (SELECT 1 FROM HOADON h WHERE h.MATH=i.MATH)
    END
END
GO

-- ============================================================
-- 7. CURSOR
-- ============================================================

-- ── 7.1 SP dùng CURSOR: Báo cáo tổng hợp thi hài ───────────
CREATE PROCEDURE SP_BaoCao_TongHopThiHai
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @MATH VARCHAR(15), @HOTEN NVARCHAR(100), @TRANGTHAI NVARCHAR(30)
    DECLARE @SoNgay INT, @TongTien MONEY, @NguoiLH NVARCHAR(150)

    PRINT N'======================================================='
    PRINT N'        BÁO CÁO TỔNG HỢP THI HÀI - ' + CONVERT(NVARCHAR(20),GETDATE(),103)
    PRINT N'======================================================='

    DECLARE cur_BaoCao CURSOR LOCAL FAST_FORWARD FOR
        SELECT MATH, HOTEN_TH, TRANGTHAI FROM THIHAI
        WHERE TRANGTHAI NOT IN (N'Đã bàn giao', N'Đã mai táng')
        ORDER BY NGAYMAT DESC

    OPEN cur_BaoCao
    FETCH NEXT FROM cur_BaoCao INTO @MATH, @HOTEN, @TRANGTHAI
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @SoNgay  = DATEDIFF(DAY, (SELECT NGAYMAT FROM THIHAI WHERE MATH=@MATH), GETDATE())
        SET @TongTien = ISNULL((SELECT SUM(dv.GIATIEN*sd.SOLUONG)
                                 FROM SUDUNG sd JOIN DICHVU dv ON sd.MADV=dv.MADV
                                 WHERE sd.MATH=@MATH), 0)
        SET @NguoiLH = dbo.FN_NguoiLienHe(@MATH)

        PRINT N'→ ['+@MATH+N'] '+@HOTEN+N' | TT: '+@TRANGTHAI
            +N' | '+CAST(@SoNgay AS NVARCHAR(5))+N' ngày | '
            +FORMAT(@TongTien,'N0')+N'đ | '+@NguoiLH

        FETCH NEXT FROM cur_BaoCao INTO @MATH, @HOTEN, @TRANGTHAI
    END
    CLOSE cur_BaoCao
    DEALLOCATE cur_BaoCao

    PRINT N'======================================================='
END
GO

-- ── 7.2 SP dùng CURSOR: Tự động gia hạn bảo quản ───────────
CREATE PROCEDURE SP_GiaHanBaoQuan_TatCa @SoNgayThem INT = 1
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @MATH VARCHAR(15), @MANGAN VARCHAR(15), @Dem INT = 0

    DECLARE cur_GiaHan CURSOR LOCAL FAST_FORWARD FOR
        SELECT th.MATH, nk.MANGAN FROM THIHAI th
        JOIN NGANKEO nk ON nk.MATH = th.MATH
        WHERE th.TRANGTHAI = N'Đang bảo quản'

    OPEN cur_GiaHan
    FETCH NEXT FROM cur_GiaHan INTO @MATH, @MANGAN
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Thêm/cập nhật dịch vụ bảo quản lạnh
        IF EXISTS (SELECT 1 FROM SUDUNG WHERE MATH=@MATH AND MADV='DV003'
                   AND NGAYSUDUNG=CAST(GETDATE() AS DATE))
            UPDATE SUDUNG SET SOLUONG=SOLUONG+@SoNgayThem
            WHERE MATH=@MATH AND MADV='DV003' AND NGAYSUDUNG=CAST(GETDATE() AS DATE)
        ELSE
            INSERT INTO SUDUNG(MATH,MADV,NGAYSUDUNG,SOLUONG,GHICHU)
            VALUES(@MATH,'DV003',CAST(GETDATE() AS DATE),@SoNgayThem,N'Gia hạn bảo quản tự động')

        SET @Dem = @Dem + 1
        FETCH NEXT FROM cur_GiaHan INTO @MATH, @MANGAN
    END
    CLOSE cur_GiaHan
    DEALLOCATE cur_GiaHan

    PRINT N'Đã gia hạn bảo quản cho ' + CAST(@Dem AS NVARCHAR(5)) + N' thi hài.'
END
GO

-- ── 7.3 SP dùng CURSOR: Gửi thông báo quá hạn ──────────────
CREATE PROCEDURE SP_KiemTraVaThongBaoQuaHan
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @MATH VARCHAR(15), @HOTEN NVARCHAR(100)
    DECLARE @SoNgay INT, @NguoiLH NVARCHAR(150)
    DECLARE @SoLuong INT = 0

    DECLARE cur_QuaHan CURSOR LOCAL FAST_FORWARD FOR
        SELECT th.MATH, th.HOTEN_TH, DATEDIFF(DAY,th.NGAYMAT,GETDATE()) AS SoNgay
        FROM THIHAI th
        WHERE th.TRANGTHAI NOT IN (N'Đã bàn giao',N'Đã mai táng')
          AND th.MATH NOT IN (SELECT MATH FROM NGANKEO WHERE MATH IS NOT NULL)
          AND DATEDIFF(DAY,th.NGAYMAT,GETDATE()) > 10
        ORDER BY SoNgay DESC

    OPEN cur_QuaHan
    FETCH NEXT FROM cur_QuaHan INTO @MATH, @HOTEN, @SoNgay
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @NguoiLH = dbo.FN_NguoiLienHe(@MATH)
        -- Ghi cảnh báo nếu chưa có
        IF NOT EXISTS (SELECT 1 FROM CANH_BAO WHERE MATH=@MATH AND LOAICB=N'QuaHan' AND DAOC=0)
            INSERT INTO CANH_BAO(LOAICB,MATH,NOIDUNG)
            VALUES(N'QuaHan',@MATH,
                   N'Thi hài '+@HOTEN+N' đã '+CAST(@SoNgay AS NVARCHAR(5))
                   +N' ngày chưa bàn giao. LH: '+@NguoiLH)
        SET @SoLuong = @SoLuong + 1
        FETCH NEXT FROM cur_QuaHan INTO @MATH, @HOTEN, @SoNgay
    END
    CLOSE cur_QuaHan
    DEALLOCATE cur_QuaHan

    PRINT N'Đã xử lý ' + CAST(@SoLuong AS NVARCHAR(5)) + N' trường hợp quá hạn.'
END
GO

-- ── 7.4 SP dùng CURSOR: Tổng hợp doanh thu nhân viên ───────
CREATE PROCEDURE SP_TongHopDoanhThuNhanVien
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @TenNV NVARCHAR(100), @TongHD INT, @TongTien MONEY

    PRINT N'=== DOANH THU THEO NHÂN VIÊN LẬP HÓA ĐƠN ==='
    DECLARE cur_NV CURSOR LOCAL FAST_FORWARD FOR
        SELECT NGUOILAP, COUNT(*), SUM(CASE WHEN TRANGTHAITT=N'Đã thanh toán' THEN TONGTIEN ELSE 0 END)
        FROM HOADON GROUP BY NGUOILAP ORDER BY SUM(TONGTIEN) DESC

    OPEN cur_NV
    FETCH NEXT FROM cur_NV INTO @TenNV, @TongHD, @TongTien
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT N'  ' + @TenNV + N': ' + CAST(@TongHD AS NVARCHAR(5))
            + N' HĐ | Thu được: ' + FORMAT(@TongTien,'N0') + N'đ'
        FETCH NEXT FROM cur_NV INTO @TenNV, @TongHD, @TongTien
    END
    CLOSE cur_NV
    DEALLOCATE cur_NV
END
GO

-- ============================================================
-- 8. BACKUP & RESTORE
-- ============================================================

CREATE PROCEDURE SP_FullBackup
    @BackupFolder NVARCHAR(500) = N'C:\QuanLyNhaXac_Backup\Full'
AS BEGIN
    SET NOCOUNT ON
    IF (IS_ROLEMEMBER('db_owner')=0 AND IS_ROLEMEMBER('QL_ADMIN')=0)
    BEGIN RAISERROR(N'Chỉ Admin mới có thể Backup.',16,1); RETURN END
    DECLARE @FileName NVARCHAR(600), @TS NVARCHAR(20)
    SET @TS=CONVERT(NVARCHAR,GETDATE(),112)+'_'+REPLACE(CONVERT(NVARCHAR(8),GETDATE(),108),':','')
    SET @FileName=@BackupFolder+N'\QuanLyNhaXac_Full_'+@TS+N'.bak'
    BEGIN TRY
        BACKUP DATABASE QuanLyNhaXac TO DISK=@FileName
        WITH NAME=N'FULL Backup',COMPRESSION,CHECKSUM,STATS=10
        PRINT N'FULL BACKUP thành công: '+@FileName
        SELECT N'FULL' AS LoaiBackup,@FileName AS DuongDan,GETDATE() AS ThoiGian
    END TRY
    BEGIN CATCH
        DECLARE @ErrFull NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(N'LỖI FULL BACKUP: %s',16,1,@ErrFull)
    END CATCH
END
GO

CREATE PROCEDURE SP_DiffBackup
    @BackupFolder NVARCHAR(500) = N'C:\QuanLyNhaXac_Backup\Diff'
AS BEGIN
    SET NOCOUNT ON
    IF (IS_ROLEMEMBER('db_owner')=0 AND IS_ROLEMEMBER('QL_ADMIN')=0)
    BEGIN RAISERROR(N'Chỉ Admin mới có thể Backup.',16,1); RETURN END
    IF NOT EXISTS (SELECT 1 FROM msdb.dbo.backupset WHERE database_name=N'QuanLyNhaXac' AND type='D')
    BEGIN RAISERROR(N'Chưa có FULL BACKUP.',16,1); RETURN END
    DECLARE @FileName NVARCHAR(600), @TS NVARCHAR(20)
    SET @TS=CONVERT(NVARCHAR,GETDATE(),112)+'_'+REPLACE(CONVERT(NVARCHAR(8),GETDATE(),108),':','')
    SET @FileName=@BackupFolder+N'\QuanLyNhaXac_Diff_'+@TS+N'.bak'
    BEGIN TRY
        BACKUP DATABASE QuanLyNhaXac TO DISK=@FileName
        WITH DIFFERENTIAL,NAME=N'DIFF Backup',COMPRESSION,CHECKSUM,STATS=10
        PRINT N'DIFF BACKUP thành công: '+@FileName
    END TRY
    BEGIN CATCH 
        DECLARE @ErrDiff NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(N'LỖI DIFF: %s',16,1,@ErrDiff) 
    END CATCH
    end
GO

CREATE PROCEDURE SP_LogBackup
    @BackupFolder NVARCHAR(500) = N'C:\QuanLyNhaXac_Backup\Log'
AS BEGIN
    SET NOCOUNT ON
    IF (IS_ROLEMEMBER('db_owner')=0 AND IS_ROLEMEMBER('QL_ADMIN')=0)
    BEGIN RAISERROR(N'Chỉ Admin mới có thể Backup.',16,1); RETURN END
    DECLARE @RM NVARCHAR(20)
    SELECT @RM=recovery_model_desc FROM sys.databases WHERE name=N'QuanLyNhaXac'
    IF @RM=N'SIMPLE' BEGIN RAISERROR(N'Cần FULL recovery model.',16,1); RETURN END
    IF NOT EXISTS (SELECT 1 FROM msdb.dbo.backupset WHERE database_name=N'QuanLyNhaXac' AND type='D')
    BEGIN RAISERROR(N'Chưa có FULL BACKUP.',16,1); RETURN END
    DECLARE @FileName NVARCHAR(600), @TS NVARCHAR(20)
    SET @TS=CONVERT(NVARCHAR,GETDATE(),112)+'_'+REPLACE(CONVERT(NVARCHAR(8),GETDATE(),108),':','')
    SET @FileName=@BackupFolder+N'\QuanLyNhaXac_Log_'+@TS+N'.trn'
    BEGIN TRY
        BACKUP LOG QuanLyNhaXac TO DISK=@FileName WITH NAME=N'LOG Backup',COMPRESSION,CHECKSUM,STATS=10
        PRINT N'LOG BACKUP thành công: '+@FileName
    END TRY
    BEGIN CATCH 
        DECLARE @ErrLog NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(N'LỖI LOG: %s',16,1,@ErrLog) 
    END CATCH
    END
GO

CREATE PROCEDURE SP_RestoreDatabase @BackupFile NVARCHAR(600), @WithRecovery BIT=1
AS BEGIN
    SET NOCOUNT ON
    IF IS_SRVROLEMEMBER('sysadmin')=0 AND IS_SRVROLEMEMBER('dbcreator')=0
    BEGIN RAISERROR(N'Cần quyền sysadmin/dbcreator để Restore.',16,1); RETURN END
    DECLARE @FE INT=0
    EXEC master.dbo.xp_fileexist @BackupFile,@FE OUTPUT
    IF @FE=0 BEGIN RAISERROR(N'Không tìm thấy file: %s',16,1,@BackupFile); RETURN END
    DECLARE @Opt NVARCHAR(20)=CASE WHEN @WithRecovery=1 THEN 'RECOVERY' ELSE 'NORECOVERY' END
    DECLARE @Sql NVARCHAR(MAX)
    BEGIN TRY
        EXEC sp_executesql N'ALTER DATABASE QuanLyNhaXac SET SINGLE_USER WITH ROLLBACK IMMEDIATE'
        IF @BackupFile LIKE N'%.trn'
            SET @Sql=N'RESTORE LOG QuanLyNhaXac FROM DISK=N'''+@BackupFile+N''' WITH '+@Opt+N',CHECKSUM'
        ELSE
            SET @Sql=N'RESTORE DATABASE QuanLyNhaXac FROM DISK=N'''+@BackupFile+N''' WITH '+@Opt+N',REPLACE,CHECKSUM'
        EXEC sp_executesql @Sql
        IF @WithRecovery=1 EXEC sp_executesql N'ALTER DATABASE QuanLyNhaXac SET MULTI_USER'
        PRINT N'RESTORE thành công từ: '+@BackupFile
    END TRY
    BEGIN CATCH
        DECLARE @ErrLog NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(N'LỖI LOG: %s',16,1,@ErrLog) 
    END CATCH   
END
GO

CREATE PROCEDURE SP_KiemTraTinhToanVenBackup @BackupFile NVARCHAR(600) AS
BEGIN
    BEGIN TRY
        RESTORE VERIFYONLY FROM DISK=@BackupFile WITH CHECKSUM
        PRINT N'File hợp lệ: '+@BackupFile; SELECT N'Hợp lệ' AS TrangThai,@BackupFile AS [File]
    END TRY
    BEGIN CATCH
        PRINT N'File lỗi: '+@BackupFile; SELECT N'Lỗi: '+ERROR_MESSAGE() AS TrangThai,@BackupFile AS [File]
    END CATCH
END
GO

CREATE PROCEDURE SP_LichSuBackup @SoLuong INT=50 AS BEGIN
    SET NOCOUNT ON
    IF (IS_ROLEMEMBER('db_owner')=0 AND IS_ROLEMEMBER('QL_ADMIN')=0)
    BEGIN RAISERROR(N'Chỉ Admin mới được xem lịch sử Backup.',16,1); RETURN END
    SELECT TOP (@SoLuong)
        bs.backup_finish_date AS ThoiGianBackup,
        CASE bs.type WHEN 'D' THEN N'FULL' WHEN 'I' THEN N'DIFFERENTIAL'
                     WHEN 'L' THEN N'LOG' ELSE bs.type END AS LoaiBackup,
        bmf.physical_device_name AS DuongDanFile,
        CAST(bs.backup_size/1024.0/1024.0 AS DECIMAL(10,2)) AS KichThuoc_MB,
        bs.user_name AS NguoiThucHien
    FROM msdb.dbo.backupset bs
    JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id=bmf.media_set_id
    WHERE bs.database_name=N'QuanLyNhaXac'
    ORDER BY bs.backup_finish_date DESC
END
GO

-- ============================================================
-- 9. PHÂN QUYỀN & LOGIN
-- ============================================================

-- ── 9.1 Tạo 3 Role ──────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name='QL_ADMIN'    AND type='R') CREATE ROLE [QL_ADMIN]
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name='QL_NHANVIEN' AND type='R') CREATE ROLE [QL_NHANVIEN]
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name='QL_BACSI'    AND type='R') CREATE ROLE [QL_BACSI]
GO

-- ── 9.2 QL_ADMIN — toàn quyền ───────────────────────────────
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
GRANT SELECT                       ON AUDIT_LOG   TO [QL_ADMIN]
GO

GRANT EXECUTE ON SP_DSBacSi                   TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThemBacSi                 TO [QL_ADMIN]
GRANT EXECUTE ON SP_SuaBacSi                  TO [QL_ADMIN]
GRANT EXECUTE ON SP_XoaBacSi                  TO [QL_ADMIN]
GRANT EXECUTE ON SP_BSLaoLang                 TO [QL_ADMIN]
GRANT EXECUTE ON SP_TimKiemBacSi              TO [QL_ADMIN]
GRANT EXECUTE ON SP_DSThiHai                  TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThemThiHai                TO [QL_ADMIN]
GRANT EXECUTE ON SP_SuaThiHai                 TO [QL_ADMIN]
GRANT EXECUTE ON SP_XoaThiHai                 TO [QL_ADMIN]
GRANT EXECUTE ON SP_CapNhatTrangThaiThiHai    TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThiHaiSot                 TO [QL_ADMIN]
GRANT EXECUTE ON SP_DemThiHai                 TO [QL_ADMIN]
GRANT EXECUTE ON SP_DonDepThiHaiQuaHan        TO [QL_ADMIN]
GRANT EXECUTE ON SP_TimKiemThiHai             TO [QL_ADMIN]
GRANT EXECUTE ON SP_TimKiem_ThiHai            TO [QL_ADMIN]
GRANT EXECUTE ON SP_BanGiaoThiHai             TO [QL_ADMIN]
GRANT EXECUTE ON SP_DSNganKeo                 TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThemNganKeo               TO [QL_ADMIN]
GRANT EXECUTE ON SP_SuaNganKeo                TO [QL_ADMIN]
GRANT EXECUTE ON SP_XoaNganKeo                TO [QL_ADMIN]
GRANT EXECUTE ON SP_XepNganKeo                TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThongKeNganKeo            TO [QL_ADMIN]
GRANT EXECUTE ON SP_DSHoSoKhamNghiem          TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThemHoSoKhamBenh_V2       TO [QL_ADMIN]
GRANT EXECUTE ON SP_SuaHoSoKhamBenh_V2        TO [QL_ADMIN]
GRANT EXECUTE ON SP_XoaHoSoKhamBenh           TO [QL_ADMIN]
GRANT EXECUTE ON SP_PhanCongBacSi             TO [QL_ADMIN]
GRANT EXECUTE ON SP_DSDichVu                  TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThemDichVu                TO [QL_ADMIN]
GRANT EXECUTE ON SP_SuaDichVu                 TO [QL_ADMIN]
GRANT EXECUTE ON SP_XoaDichVu                 TO [QL_ADMIN]
GRANT EXECUTE ON SP_DichVuE                   TO [QL_ADMIN]
GRANT EXECUTE ON SP_DSDichVuSuDung            TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThemDichVuSudung          TO [QL_ADMIN]
GRANT EXECUTE ON SP_SuaDichVuSudung           TO [QL_ADMIN]
GRANT EXECUTE ON SP_XoaDichVuSuDung           TO [QL_ADMIN]
GRANT EXECUTE ON SP_DichVuTheoHoaDon          TO [QL_ADMIN]
GRANT EXECUTE ON SP_DichVuChuaLapHD           TO [QL_ADMIN]
GRANT EXECUTE ON sp_TinhTongTienDichVu        TO [QL_ADMIN]
GRANT EXECUTE ON SP_DSThanNhan                TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThemThanNhan              TO [QL_ADMIN]
GRANT EXECUTE ON SP_SuaThanNhan               TO [QL_ADMIN]
GRANT EXECUTE ON SP_XoaThanNhan               TO [QL_ADMIN]
GRANT EXECUTE ON SP_TimKiem_ThanNhan          TO [QL_ADMIN]
GRANT EXECUTE ON SP_DSHoaDon                  TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThemHoaDon                TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThanhToanHoaDon           TO [QL_ADMIN]
GRANT EXECUTE ON SP_HoaDonTheoThiHai          TO [QL_ADMIN]
GRANT EXECUTE ON SP_TimKiem_HoaDon            TO [QL_ADMIN]
GRANT EXECUTE ON SP_DSCanhBao                 TO [QL_ADMIN]
GRANT EXECUTE ON SP_DocCanhBao                TO [QL_ADMIN]
GRANT EXECUTE ON SP_DocHetCanhBao             TO [QL_ADMIN]
GRANT EXECUTE ON SP_QuetCanhBao               TO [QL_ADMIN]
GRANT EXECUTE ON SP_DSNhanVien                TO [QL_ADMIN]
GRANT EXECUTE ON SP_ThemNhanVien              TO [QL_ADMIN]
GRANT EXECUTE ON SP_SuaNhanVien               TO [QL_ADMIN]
GRANT EXECUTE ON SP_XoaNhanVien               TO [QL_ADMIN]
GRANT EXECUTE ON SP_Dashboard                 TO [QL_ADMIN]
GRANT EXECUTE ON SP_BaoCao_ThiHaiTheoThang    TO [QL_ADMIN]
GRANT EXECUTE ON SP_BaoCao_DoanhThuTheoThang  TO [QL_ADMIN]
GRANT EXECUTE ON SP_XemAuditLog               TO [QL_ADMIN]
GRANT EXECUTE ON SP_XoaAuditLogCu             TO [QL_ADMIN]
GRANT EXECUTE ON SP_DanhSachUser              TO [QL_ADMIN]
GRANT EXECUTE ON SP_DanhSachRole              TO [QL_ADMIN]
GRANT EXECUTE ON SP_UserTrongRole             TO [QL_ADMIN]
GRANT EXECUTE ON SP_GrantUserVaoRole          TO [QL_ADMIN]
GRANT EXECUTE ON SP_RevokeUserKhoiRole        TO [QL_ADMIN]
GRANT EXECUTE ON SP_KiemTraQuyenHan           TO [QL_ADMIN]
GRANT EXECUTE ON SP_BaoCao_TongHopThiHai      TO [QL_ADMIN]
GRANT EXECUTE ON SP_GiaHanBaoQuan_TatCa       TO [QL_ADMIN]
GRANT EXECUTE ON SP_KiemTraVaThongBaoQuaHan   TO [QL_ADMIN]
GRANT EXECUTE ON SP_TongHopDoanhThuNhanVien   TO [QL_ADMIN]
GRANT EXECUTE ON SP_FullBackup                TO [QL_ADMIN]
GRANT EXECUTE ON SP_DiffBackup                TO [QL_ADMIN]
GRANT EXECUTE ON SP_LogBackup                 TO [QL_ADMIN]
GRANT EXECUTE ON SP_KiemTraTinhToanVenBackup  TO [QL_ADMIN]
GRANT EXECUTE ON SP_LichSuBackup              TO [QL_ADMIN]
GO

-- ── 9.3 QL_NHANVIEN ─────────────────────────────────────────
GRANT SELECT ON THIHAI         TO [QL_NHANVIEN]
GRANT SELECT,INSERT,UPDATE,DELETE ON DICHVU    TO [QL_NHANVIEN]
GRANT SELECT,INSERT,UPDATE,DELETE ON SUDUNG    TO [QL_NHANVIEN]
GRANT SELECT,INSERT,UPDATE ON THAN_NHAN        TO [QL_NHANVIEN]
GRANT SELECT,INSERT,UPDATE ON HOADON           TO [QL_NHANVIEN]
GRANT SELECT,INSERT,UPDATE ON CANH_BAO         TO [QL_NHANVIEN]
GO
GRANT EXECUTE ON SP_DSThiHai               TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_ThemThiHai             TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_SuaThiHai              TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_XoaThiHai              TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_CapNhatTrangThaiThiHai TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_TimKiemThiHai          TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_TimKiem_ThiHai         TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_BanGiaoThiHai          TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_DSNganKeo              TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_XepNganKeo             TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_DSDichVu               TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_ThemDichVu             TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_SuaDichVu              TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_XoaDichVu              TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_DSDichVuSuDung         TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_ThemDichVuSuDung       TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_ThemDichVuSudung       TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_SuaDichVuSudung        TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_XoaDichVuSuDung        TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_DichVuTheoHoaDon       TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_DichVuChuaLapHD        TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_DSThanNhan             TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_ThemThanNhan           TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_SuaThanNhan            TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_TimKiem_ThanNhan       TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_DSHoaDon               TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_ThemHoaDon             TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_ThanhToanHoaDon        TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_HoaDonTheoThiHai       TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_TimKiem_HoaDon         TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_DSCanhBao              TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_DocCanhBao             TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_DocHetCanhBao          TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_QuetCanhBao            TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_DSNhanVien             TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_Dashboard              TO [QL_NHANVIEN]
GRANT EXECUTE ON SP_KiemTraQuyenHan        TO [QL_NHANVIEN]
GO

-- ── 9.4 QL_BACSI ────────────────────────────────────────────
GRANT SELECT,INSERT,UPDATE,DELETE ON THIHAI       TO [QL_BACSI]
GRANT SELECT,INSERT,UPDATE,DELETE ON NGANKEO      TO [QL_BACSI]
GRANT SELECT,INSERT,UPDATE,DELETE ON HOSOKHAMBENH TO [QL_BACSI]
GRANT SELECT ON DICHVU                             TO [QL_BACSI]
GRANT SELECT ON THAN_NHAN                          TO [QL_BACSI]
GRANT SELECT ON HOADON                             TO [QL_BACSI]
GRANT SELECT ON CANH_BAO                           TO [QL_BACSI]
GO
GRANT EXECUTE ON SP_DSThiHai             TO [QL_BACSI]
GRANT EXECUTE ON SP_TimKiemThiHai        TO [QL_BACSI]
GRANT EXECUTE ON SP_TimKiem_ThiHai       TO [QL_BACSI]
GRANT EXECUTE ON SP_DSHoSoKhamNghiem     TO [QL_BACSI]
GRANT EXECUTE ON SP_ThemHoSoKhamBenh_V2  TO [QL_BACSI]
GRANT EXECUTE ON SP_SuaHoSoKhamBenh_V2   TO [QL_BACSI]
GRANT EXECUTE ON SP_PhanCongBacSi        TO [QL_BACSI]
GRANT EXECUTE ON SP_DSNganKeo            TO [QL_BACSI]
GRANT EXECUTE ON SP_DSThanNhan           TO [QL_BACSI]
GRANT EXECUTE ON SP_HoaDonTheoThiHai     TO [QL_BACSI]
GRANT EXECUTE ON SP_DSCanhBao            TO [QL_BACSI]
GRANT EXECUTE ON SP_DocCanhBao           TO [QL_BACSI]
GRANT EXECUTE ON SP_Dashboard            TO [QL_BACSI]
GRANT EXECUTE ON SP_KiemTraQuyenHan      TO [QL_BACSI]
GO

-- ── 9.5 Tạo Login & User ────────────────────────────────────
USE master
GO
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name='NhaXacAdmin') DROP LOGIN [NhaXacAdmin]
GO
CREATE LOGIN [NhaXacAdmin] WITH PASSWORD=N'NhaXac@2026',
    DEFAULT_DATABASE=[QuanLyNhaXac], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

USE QuanLyNhaXac
GO
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name='NhaXacAdmin') DROP USER [NhaXacAdmin]
GO
CREATE USER [NhaXacAdmin] FOR LOGIN [NhaXacAdmin]
GO
ALTER ROLE [db_owner] ADD MEMBER [NhaXacAdmin]
ALTER ROLE [QL_ADMIN] ADD MEMBER [NhaXacAdmin]
GO

-- ============================================================
-- KIỂM TRA TỔNG QUAN SAU KHI CHẠY
-- ============================================================
SELECT N'=== KIỂM TRA DATABASE ===' AS Info
SELECT 'Bảng'     AS LoaiDT, COUNT(*) AS SoLuong FROM sys.tables  WHERE type='U' UNION ALL
SELECT 'View',                COUNT(*)             FROM sys.views                 UNION ALL
SELECT 'Function',            COUNT(*)             FROM sys.objects WHERE type IN ('FN','TF','IF') UNION ALL
SELECT 'Procedure',           COUNT(*)             FROM sys.procedures            UNION ALL
SELECT 'Trigger',             COUNT(*)             FROM sys.triggers WHERE parent_class=1
ORDER BY LoaiDT

SELECT N'=== DỮ LIỆU MẪU ===' AS Info
SELECT 'THIHAI'       AS Bang, COUNT(*) AS SoLuong FROM THIHAI       UNION ALL
SELECT 'BACSI',                COUNT(*)             FROM BACSI         UNION ALL
SELECT 'DICHVU',               COUNT(*)             FROM DICHVU        UNION ALL
SELECT 'NGANKEO',              COUNT(*)             FROM NGANKEO       UNION ALL
SELECT 'HOSOKHAMBENH',         COUNT(*)             FROM HOSOKHAMBENH  UNION ALL
SELECT 'SUDUNG',               COUNT(*)             FROM SUDUNG        UNION ALL
SELECT 'NHANVIEN',             COUNT(*)             FROM NHANVIEN      UNION ALL
SELECT 'THAN_NHAN',            COUNT(*)             FROM THAN_NHAN     UNION ALL
SELECT 'HOADON',               COUNT(*)             FROM HOADON        UNION ALL
SELECT 'AUDIT_LOG',            COUNT(*)             FROM AUDIT_LOG     UNION ALL
SELECT 'CANH_BAO',             COUNT(*)             FROM CANH_BAO
ORDER BY Bang

SELECT * FROM VIEW_Dashboard

PRINT N''
PRINT N'============================================================'
PRINT N'QuanLyNhaXac — TRIỂN KHAI THÀNH CÔNG!'
PRINT N'  11 Bảng | 22 View | 10 Function | 18 Trigger'
PRINT N'  60+ Stored Procedure | 4 Cursor | 3 Role | 1 Login'
PRINT N'============================================================'
GO

-- Cập nhật SP Thêm Thi Hài
CREATE OR ALTER PROC SP_ThemThiHai
    @MATH VARCHAR(15), 
    @HOTEN_TH NVARCHAR(100), 
    @NGAYSINH DATE,
    @NGAYMAT DATE, 
    @GIOITINH NVARCHAR(10),
    @NOITIMTHAY NVARCHAR(200) = NULL,   -- Thêm mới
    @COCUANHAN NVARCHAR(100) = NULL     -- Thêm mới
AS 
BEGIN
    INSERT INTO THIHAI(MATH, HOTEN_TH, NGAYSINH, NGAYMAT, GIOITINH, NOITIMTHAY, COCUANHAN)
    VALUES(@MATH, @HOTEN_TH, @NGAYSINH, @NGAYMAT, @GIOITINH, @NOITIMTHAY, @COCUANHAN)
END
GO

-- Cập nhật SP Sửa Thi Hài
CREATE OR ALTER PROC SP_SuaThiHai
    @MATH VARCHAR(15), 
    @HOTEN_TH NVARCHAR(100), 
    @NGAYSINH DATE,
    @NGAYMAT DATE, 
    @GIOITINH NVARCHAR(10),
    @NOITIMTHAY NVARCHAR(200) = NULL,   -- Thêm mới
    @COCUANHAN NVARCHAR(100) = NULL     -- Thêm mới
AS 
BEGIN
    UPDATE THIHAI 
    SET HOTEN_TH = @HOTEN_TH, 
        NGAYSINH = @NGAYSINH,
        NGAYMAT = @NGAYMAT, 
        GIOITINH = @GIOITINH,
        NOITIMTHAY = @NOITIMTHAY,
        COCUANHAN = @COCUANHAN
    WHERE MATH = @MATH
END
GO

-- Cập nhật SP Thêm Thi Hài
CREATE OR ALTER PROC SP_ThemThiHai
    @MATH VARCHAR(15), 
    @HOTEN_TH NVARCHAR(100), 
    @NGAYSINH DATE,
    @NGAYMAT DATE, 
    @GIOITINH NVARCHAR(10),
    @NOITIMTHAY NVARCHAR(200) = NULL,   -- Thêm mới
    @COCUANHAN NVARCHAR(100) = NULL     -- Thêm mới
AS 
BEGIN
    INSERT INTO THIHAI(MATH, HOTEN_TH, NGAYSINH, NGAYMAT, GIOITINH, NOITIMTHAY, COCUANHAN)
    VALUES(@MATH, @HOTEN_TH, @NGAYSINH, @NGAYMAT, @GIOITINH, @NOITIMTHAY, @COCUANHAN)
END
GO

-- Cập nhật SP Sửa Thi Hài
CREATE OR ALTER PROC SP_SuaThiHai
    @MATH VARCHAR(15), 
    @HOTEN_TH NVARCHAR(100), 
    @NGAYSINH DATE,
    @NGAYMAT DATE, 
    @GIOITINH NVARCHAR(10),
    @NOITIMTHAY NVARCHAR(200) = NULL,   -- Thêm mới
    @COCUANHAN NVARCHAR(100) = NULL     -- Thêm mới
AS 
BEGIN
    UPDATE THIHAI 
    SET HOTEN_TH = @HOTEN_TH, 
        NGAYSINH = @NGAYSINH,
        NGAYMAT = @NGAYMAT, 
        GIOITINH = @GIOITINH,
        NOITIMTHAY = @NOITIMTHAY,
        COCUANHAN = @COCUANHAN
    WHERE MATH = @MATH
END
GO

-- ============================================================
-- PATCH SQL: Thêm role Doctor vào stored procedure SP_KiemTraQuyenHan
-- (Nếu SP đang trả về 'Admin' / 'Staff' / 'ReadOnly')
--
-- Mở SP_KiemTraQuyenHan và thêm điều kiện Doctor, ví dụ:
-- ============================================================

ALTER PROCEDURE SP_KiemTraQuyenHan
AS
BEGIN
    -- Lấy tên role của login hiện tại
    DECLARE @role NVARCHAR(50);

    SELECT @role = r.name
    FROM sys.database_role_members rm
    JOIN sys.database_principals r ON r.principal_id = rm.role_principal_id
    JOIN sys.database_principals u ON u.principal_id = rm.member_principal_id
    WHERE u.name = USER_NAME()
    ORDER BY r.name;

    -- Map role SQL → role ứng dụng
    SELECT CASE
        WHEN @role = 'db_owner'     THEN 'Admin'
        WHEN @role = 'StaffRole'    THEN 'Staff'
        WHEN @role = 'DoctorRole'   THEN 'Doctor'   -- <-- Thêm dòng này
        ELSE 'ReadOnly'
    END AS QuyenHan;
END

-- ============================================================
-- Tạo SQL login + user + role cho bác sĩ:
-- ============================================================

-- 1. Tạo login
CREATE LOGIN bacsi01 WITH PASSWORD = 'BacSi@2025';

-- 2. Tạo user trong database
USE QuanLyNhaXac;
CREATE USER bacsi01 FOR LOGIN bacsi01;

-- 3. Tạo role DoctorRole (nếu chưa có)
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'DoctorRole' AND type = 'R')
    CREATE ROLE DoctorRole;

-- 4. Gán user vào role
ALTER ROLE DoctorRole ADD MEMBER bacsi01;

-- 5. Cấp quyền theo đặc tả:
--    BacSi: SELECT ThiHai, SELECT CanhBao, INSERT+UPDATE HoSoKhamBenh

GRANT SELECT ON ThiHai        TO DoctorRole;
GRANT SELECT ON CanhBao        TO DoctorRole;
GRANT SELECT, INSERT, UPDATE   ON HoSoKhamBenh TO DoctorRole;

-- (Không cấp DELETE trên HoSoKhamBenh cho DoctorRole)
