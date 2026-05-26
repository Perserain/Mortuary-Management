use master
IF EXISTS(SELECT 1 FROM sys.databases WHERE NAME = 'QuanLyNhaXac')
	DROP DATABASE QuanLyNhaXac

GO

CREATE DATABASE QuanLyNhaXac
--1. FILE DỮ LIỆU CHÍNH
ON PRIMARY
(
    NAME = 'QuanLyNhaXac_Main',
    FILENAME = 'C:\QLNhaXac\QuanLyNhaXac_Main\QuanLyNhaXac_Main.mdf',
    SIZE = 10MB,          -- Kích thước ban đầu
    MAXSIZE = 30MB,      -- Kích thước tối đa
    FILEGROWTH = 5MB      -- Tốc độ tăng trưởng
),
--2. FILE DỮ LIỆU PHỤ
FILEGROUP SecondaryGroup
(
    NAME = 'QuanLyNhaXac_Sub',
    FILENAME = 'C:\QLNhaXac\QuanLyNhaXac_Sub\QuanLyNhaXac_Sub.ndf',
    SIZE = 10MB,          -- Kích thước ban đầu
    MAXSIZE = 30MB,      -- Kích thước tối đa
    FILEGROWTH = 5MB      -- Tốc độ tăng trưởng
)
-- 3. File nhật ký (.ldf) - Log file
LOG ON
(
    NAME = 'QuanLyNhaXac_Log',
    FILENAME = 'C:\QLNhaXac\QuanLyNhaXac_Log\QuanLyNhaXac_Log.ldf',
    SIZE = 5MB,
    MAXSIZE = 20MB,
    FILEGROWTH = 1MB
)

GO

use QuanLyNhaXac

GO

SET DATEFORMAT DMY

GO
-- =============================================
-- 1. TẠO CÁC BẢNG (TABLES)
-- =============================================

-- Bảng 1: Thông tin Tử Thi (Gốc)
CREATE TABLE THIHAI 
(
    MATH CHAR(15) NOT NULL,       
    HOTEN_TH NVARCHAR(100) ,    
    NGAYSINH DATE,
    NGAYMAT DATE,
    GIOITINH NVARCHAR(10),            -- Nam/Nữ/Chưa rõ
    -- KHÓA CHÍNH
    CONSTRAINT PK_TH PRIMARY KEY(MATH)
)

-- Bảng 2: Bác Sĩ
CREATE TABLE BACSI 
(
    MABS CHAR(15) NOT NULL,
    HOTEN_BS NVARCHAR(100),
    CHUYENKHOA NVARCHAR(100),
    NAMKINHNGHIEM INT,
    -- KHÓA CHÍNH
    CONSTRAINT PK_BS PRIMARY KEY(MABS)
)

-- Bảng 3: Dịch Vụ (Ví dụ: Khâm liệm, Trang điểm...)
CREATE TABLE DICHVU 
(
    MADV CHAR(15) NOT NULL,
    TENDV NVARCHAR(100),
    GIATIEN MONEY,
    -- KHÓA CHÍNH
    CONSTRAINT PK_DV PRIMARY KEY(MADV)
)

-- Bảng 4: Ngăn Kéo (Quan hệ 1-1 với Tử Thi)
CREATE TABLE NGANKEO 
(
    MANGAN CHAR(15) NOT NULL,
    VITRI NVARCHAR(50),              -- Ví dụ: Khu A, Tầng 2
    NHIETDO FLOAT,                   -- Nhiệt độ bảo quản
    MATH CHAR(15),     
    -- KHÓA CHÍNH
    CONSTRAINT PK_NK PRIMARY KEY(MANGAN)
)

-- Bảng 5: Hồ Sơ Khám Nghiệm (Quan hệ 1-n: Bác sĩ khám cho Tử thi)
CREATE TABLE HOSOKHAMBENH
(
    MAHS CHAR(15) NOT NULL,
    THOIGIANKHAM DATE,
    KETLUAN NVARCHAR(50),           
    MATH CHAR(15),
    MABS CHAR(15),
    -- KHÓA CHÍNH
    CONSTRAINT PK_HS PRIMARY KEY(MAHS)
)

-- Bảng 6: Sử Dụng Dịch Vụ (Quan hệ n-n: Tử thi dùng Dịch vụ)
CREATE TABLE SUDUNG 
(
    MATH CHAR(15) NOT NULL,
    MADV CHAR(15) NOT NULL,
    NGAYSUDUNG DATE,
    GHICHU NVARCHAR(200),
    -- Khóa chính là cặp (MATH, MADV)
    PRIMARY KEY (MATH, MADV)
)

GO

-- 1. Thêm cột MA_TRUONGKHOA vào bảng BACSI
ALTER TABLE BACSI
ADD MA_TRUONGKHOA CHAR(15); 

GO

-- 2. Tạo ràng buộc khóa ngoại (Trưởng khoa cũng phải là một Bác sĩ trong bảng này)
ALTER TABLE BACSI
ADD CONSTRAINT FK_BACSI_TRUONGKHOA 
FOREIGN KEY (MA_TRUONGKHOA) REFERENCES BACSI(MABS);

GO

---- 3. (Tùy chọn) Cập nhật thử một vài bác sĩ có sếp
---- Ví dụ: Bác sĩ BS002 là sếp của BS001
--UPDATE BACSI SET MA_TRUONGKHOA = 'BS002' WHERE MABS = 'BS001';

--EXEC sp_help 'BACSI'

--SELECT * FROM master.sys.server_principals

--SELECT * FROM QuanLyNhaXac.sys.server_principals
--SELECT * FROM sys.server_principals

-- =============================================
-- 1.1. BỔ SUNG KHÓA NGOẠI 
-- =============================================

-- Liên kết Ngăn Kéo -> Thi Hài
ALTER TABLE NGANKEO
ADD CONSTRAINT FK_NGANKEO_THIHAI 
FOREIGN KEY (MATH) REFERENCES THIHAI(MATH);

GO
-- Liên kết Hồ Sơ -> Thi Hài, Bác sĩ
ALTER TABLE HOSOKHAMBENH
ADD CONSTRAINT FK_HOSOKHAMBENH_THIHAI FOREIGN KEY (MATH) REFERENCES THIHAI(MATH),
	CONSTRAINT FK_HOSOKHAMBENH_BACSI FOREIGN KEY (MABS) REFERENCES BACSI(MABS)

GO
-- Liên kết Sử Dụng -> Dịch Vụ, Thi hài
ALTER TABLE SUDUNG
ADD CONSTRAINT FK_SUDUNG_DICHVU FOREIGN KEY (MADV) REFERENCES DICHVU(MADV),
    CONSTRAINT FK_SUDUNG_THIHAI FOREIGN KEY (MATH) REFERENCES THIHAI(MATH)

GO
-- =============================================
-- 2. RÀNG BUỘC 
-- =============================================

-- 1. RÀNG BUỘC CHO THI HÀI--
-- CHECK ngày mất > ngày sinh 
ALTER TABLE THIHAI
ADD CONSTRAINT CK_THIHAI_NGAY
CHECK (NGAYMAT > NGAYSINH)

GO
-- CHECK ngày sinh < ngày hiện tại
ALTER TABLE THIHAI
ADD CONSTRAINT CK_THIHAI_NGAYHT
CHECK (NGAYSINH <= GETDATE())

GO
-- 2. RÀNG BUỘC CHO BÁC SĨ --
-- CHECK năm kinh nghiệm 
ALTER TABLE BACSI
ADD CONSTRAINT CK_BACSI_NAMKN
CHECK (NAMKINHNGHIEM > 1)

GO
-- 3. RÀNG BUỘC CHO HỒ SƠ KHÁM NGHIỆM --
-- DEFAULT
ALTER TABLE HOSOKHAMBENH
ADD CONSTRAINT DF_HS_KETLUAN
DEFAULT N'Đang điều tra' FOR KETLUAN

GO
-- CHECK Ngày khám không được lớn hơn ngày hiện tại
ALTER TABLE HOSOKHAMBENH
ADD CONSTRAINT CK_HS_NGAY
CHECK(THOIGIANKHAM <= GETDATE()) --!

GO
-- 4. RÀNG BUỘC NGĂN KÉO --
-- Unique MATH (Mỗi xác 1 ngăn - Quan hệ 1-1)
ALTER TABLE NGANKEO
ADD CONSTRAINT UQ_NGANKEO_MATH UNIQUE (MATH);

GO
-- DEFAULT nhiệt độ
ALTER TABLE NGANKEO
ADD CONSTRAINT DF_NGANKEO_NHIETDO
DEFAULT 4.0 FOR NHIETDO

GO
-- CHECK nhiệt độ
ALTER TABLE NGANKEO
ADD CONSTRAINT CK_NGANKEO_NHIETDO
CHECK (NHIETDO < 10)

GO

-- 5. RÀNG BUỘC DỊCH VỤ --
-- Giá tiền không được âm
ALTER TABLE DICHVU
ADD CONSTRAINT CK_DICHVU_GIATIEN
CHECK (GIATIEN >= 0);

GO
-- 6. RÀNG BUỘC SỬ DỤNG DỊCH VỤ --
--CHECK ngày đăng ký sử dụng dịch vụ <= ngày hiện tại
ALTER TABLE SUDUNG
ADD CONSTRAINT CK_SUDUNG_NGAY
CHECK(NGAYSUDUNG <=GETDATE())

GO
-- =============================================
-- 3. CHÈN DỮ LIỆU MẪU (INSERT DATA)
-- =============================================

-- Thêm dữ liệu Tử Thi
INSERT INTO THIHAI VALUES 
('TH001', N'Nguyễn Văn A', '1980-01-01', '2026-01-20', N'Nam'),
('TH002', N'Trần Thị B', '1995-05-15', '2026-01-21', N'Nữ'),
('TH003', N'Lê Văn C', '1960-12-12', '2026-01-22', N'Nam'),
('TH004',N'Nguyễn Văn Khải','2000-2-2','2021-12-2','Nam'),
('TH005',N'Nguyễn Khả Ái','2010-5-3','2025-1-12',N'Nữ'),
('TH006',N'Cao Tử Khai','1969-3-9','2024-4-4','Nam'),
('TH007',N'Nguyễn Hoài Anh','1969-3-9','2026-4-4','Nam')

-- Thêm dữ liệu Bác Sĩ
INSERT INTO BACSI VALUES 
('BS001', N'Phạm Nhật Vượng', N'Pháp y', 10, NULL),
('BS002', N'Đặng Lê Nguyên Vũ', N'Đa khoa', 15, NULL),
('BS003', N'Phạm Minh Đức', N'Pháp y', 10, NULL),
('BS004', N'Nguyễn Thị Hoa', N'Giải phẫu bệnh', 12, NULL),
('BS005', N'Trần Quang Huy', N'Pháp y', 11, NULL)

-- Thêm dữ liệu Dịch Vụ
INSERT INTO DICHVU VALUES 
('DV001', N'Trang điểm tử thi', 500000),
('DV002', N'Khâm liệm', 2000000),
('DV003', N'Bảo quản lạnh', 150000)

-- Thêm dữ liệu Ngăn Kéo (Xếp người vào ngăn)
INSERT INTO NGANKEO VALUES 
('NK001', N'Khu A - Hộc 1', -5.5, 'TH001'), -- Ông A nằm ngăn 1
('NK002', N'Khu A - Hộc 2', -5.0, 'TH002'), -- Bà B nằm ngăn 2
('NK003', N'Khu B - Hộc 1', -6.0, NULL)   -- Ngăn 3 đang trống

-- Thêm dữ liệu Hồ Sơ Khám
INSERT INTO HOSOKHAMBENH VALUES 
('HS001', '20-01-2026', N'Tử vong do tai nạn giao thông', 'TH001', 'BS001'),
('HS002', '21-01-2026', N'Tử vong do bệnh tim', 'TH002', 'BS002')

-- Thêm dữ liệu Sử Dụng Dịch Vụ (Ông A dùng DV gì, Bà B dùng DV gì)
INSERT INTO SUDUNG VALUES 
('TH001', 'DV001', '2026-01-20', N'Yêu cầu trang điểm nhẹ'),
('TH001', 'DV002', '2026-01-20', N'Khâm liệm theo giờ tốt'),
('TH002', 'DV003', '2026-01-21', N'Bảo quản 3 ngày')
	
SELECT * FROM BACSI
SELECT * FROM DICHVU
SELECT * FROM HOSOKHAMBENH
SELECT * FROM NGANKEO
SELECT * FROM SUDUNG
SELECT * FROM THIHAI

--delete FROM BACSI
--delete FROM DICHVU
--delete FROM HOSOKHAMBENH
--delete FROM NGANKEO
--delete FROM SUDUNG
--delete FROM THIHAI

GO
-- =============================================
-- 4. TẠO BẢNG ẢO
-- =============================================
--1. Bác sĩ
--Kết hợp IF phân cấp bậc bác sĩ
CREATE VIEW VIEW_DanhSachBacSi AS
SELECT 
    MABS, 
    HOTEN_BS, 
    CHUYENKHOA, 
    NAMKINHNGHIEM, 
    MA_TRUONGKHOA,
    CASE 
        WHEN NAMKINHNGHIEM < 2 THEN N'Thực tập sinh'
        WHEN NAMKINHNGHIEM BETWEEN 2 AND 5 THEN N'Bác sĩ tiêu chuẩn'
        WHEN NAMKINHNGHIEM BETWEEN 6 AND 9 THEN N'Chuyên môn cao'
        ELSE N'Chuyên gia/Lão làng'
    END AS CAPBAC
FROM BACSI;

GO
--truy vấn lồng
CREATE VIEW VIEW_BSLaoLang AS
(
SELECT * FROM VIEW_DanhSachBACSI 
WHERE NAMKINHNGHIEM > (SELECT AVG(NAMKINHNGHIEM) FROM VIEW_DANHSACHBACSI)
)

GO
--2. Thi Hài
--Kết hợp IF/CASE phân nhóm tuổi thi hài
CREATE VIEW VIEW_DanhSachThiHai AS
SELECT 
    MATH, 
    HOTEN_TH, 
    NGAYSINH, 
    NGAYMAT, 
    GIOITINH,
    CASE 
        WHEN DATEDIFF(YEAR, NGAYSINH, NGAYMAT) < 18 THEN N'Vị thành niên'
        WHEN DATEDIFF(YEAR, NGAYSINH, NGAYMAT) BETWEEN 18 AND 59 THEN N'Trưởng thành'
        WHEN DATEDIFF(YEAR, NGAYSINH, NGAYMAT) >= 60 THEN N'Cao tuổi'
        ELSE N'Chưa rõ'
    END AS NHOMTUOI
FROM THIHAI;

GO
--3. Ngăn kéo
CREATE VIEW VIEW_DanhSachNganKeo AS
(
SELECT MANGAN, VITRI, NHIETDO, th.MATH, th.HOTEN_TH
FROM NGANKEO, THIHAI th
WHERE th.MATH = NGANKEO.MATH
)

GO
--4. Hồ sơ khám bệnh
CREATE VIEW VIEW_HoSoKhamBenh AS
(
SELECT * FROM HOSOKHAMBENH
)

GO
--5. Dịch vụ
CREATE VIEW VIEW_DichVu AS
(
SELECT * FROM DichVu
)

GO

CREATE VIEW VIEW_DichVuE AS
(
SELECT * FROM DICHVU 
WHERE MADV NOT IN (SELECT DISTINCT MADV FROM SUDUNG)
)

GO
--6. Sử dụng
CREATE VIEW VIEW_DichVuSuDung AS
(
SELECT th.MATH, HOTEN_TH, dv.MADV, TENDV, NGAYSUDUNG, GIATIEN, GHICHU 
FROM THIHAI th, DICHVU dv, SUDUNG sd
WHERE th.MATH = sd.MATH AND dv.MADV = sd.MADV
)

GO
-- =============================================
-- 5. THỦ TỤC
-- =============================================
-- 5.1 BÁC SĨ
-- THỦ TỤC DANH SÁCH BÁC SĨ
CREATE PROC SP_DSBacSi
AS
BEGIN
	SELECT * FROM VIEW_DanhSachBacSi
END

GO

-- THỦ TỤC THÊM

CREATE PROC SP_ThemBacSi
    @MABS CHAR(15),
    @HOTEN_BS NVARCHAR(100),
    @CHUYENKHOA NVARCHAR(100),
    @NAMKINHNGHIEM INT,
    @MA_TRUONGKHOA CHAR(15)
AS
BEGIN
    INSERT INTO BacSi
    (MABS, HOTEN_BS, CHUYENKHOA, NAMKINHNGHIEM, MA_TRUONGKHOA)
    VALUES
    (@MABS, @HOTEN_BS, @CHUYENKHOA, @NAMKINHNGHIEM, @MA_TRUONGKHOA)
END

GO
-- THỦ TỤC XÓA
CREATE PROC SP_XoaBacSi
    @MABS CHAR(15)
AS
BEGIN

	DELETE FROM BACSI WHERE MABS=@MABS
END

GO


-- THỦ TỤC SỬA
CREATE PROC SP_SuaBacSi
	@MABS CHAR(15),
    @HOTEN_BS NVARCHAR(100),
    @CHUYENKHOA NVARCHAR(100),
    @NAMKINHNGHIEM INT,
    @MA_TRUONGKHOA CHAR(15)
AS
BEGIN
	UPDATE BACSI
	SET HOTEN_BS = @HOTEN_BS,
		CHUYENKHOA = @CHUYENKHOA,
		NAMKINHNGHIEM = @NAMKINHNGHIEM,
		MA_TRUONGKHOA = @MA_TRUONGKHOA
	WHERE MABS = @MABS
END

GO

-- THỦ TỤC TÌM BÁC SĨ LÃO LUYỆN (>15 NĂM KN)
CREATE PROC SP_BSLaoLang
AS
BEGIN
	SELECT * FROM View_BSLaoLang
END

GO
-- =============================================
-- 5.2 THI HÀI
-- THỦ TỤC DANH SÁCH THI HÀI
CREATE PROC SP_DSThiHai
AS
BEGIN
	SELECT * FROM VIEW_DanhSachThiHai
END

GO
-- THỦ TỤC THÊM
CREATE PROC SP_ThemThiHai
    @MATH CHAR(15),
    @HOTEN_TH NVARCHAR(100),
    @NGAYSINH DATE,
    @NGAYMAT DATE,
    @GIOITINH NVARCHAR(10)
AS
BEGIN
    INSERT INTO THIHAI
    (MATH, HOTEN_TH, NGAYSINH, NGAYMAT, GIOITINH)
    VALUES
    (@MATH, @HOTEN_TH, @NGAYSINH, @NGAYMAT, @GIOITINH)
END

GO
-- THỦ TỤC SỬA
CREATE PROC SP_SuaThiHai
    @MATH CHAR(15),
    @HOTEN_TH NVARCHAR(100),
    @NGAYSINH DATE,
    @NGAYMAT DATE,
    @GIOITINH NVARCHAR(10)
AS
BEGIN
	UPDATE THIHAI
	SET HOTEN_TH = @HOTEN_TH,
		NGAYSINH = @NGAYSINH,
		NGAYMAT = @NGAYMAT,
		GIOITINH = @GIOITINH
	WHERE MATH = @MATH
END

GO
-- THỦ TỤC XÓA

CREATE PROC SP_XoaThiHai
    @MATH CHAR(15)
AS
BEGIN
	BEGIN TRANSACTION
		DELETE FROM SUDUNG WHERE MATH = @MATH

		DELETE FROM NGANKEO WHERE MATH = @MATH

		DELETE FROM THIHAI WHERE MATH = @MATH
	COMMIT TRANSACTION
END

GO
-- THỦ TỤC TÌM THI HÀI CÒN SÓT (CHƯA ĐƯỢC CHO VÀO NGĂN KÉO)
CREATE PROC SP_ThiHaiSot
AS
BEGIN
	SELECT * FROM VIEW_DANHSACHTHIHAI WHERE MATH NOT IN (SELECT MATH FROM NGANKEO WHERE MATH IS NOT NULL)
END

GO
-- THỦ TỤC ĐẾM THI HÀI
CREATE PROCEDURE SP_DemThiHai
AS
BEGIN
	SELECT COUNT(MATH) FROM VIEW_DANHSACHTHIHAI
END;
GO

-- Procedure kiểm tra thi hài quá hạn sử dụng
CREATE PROC SP_DonDepThiHaiQuaHan
AS
BEGIN
    -- Khai báo biến chứa mã thi hài đang được xử lý trong mỗi vòng lặp
    DECLARE @MATH_XULY CHAR(15);

    -- ĐIỀU KIỆN LẶP:
    -- 1. DATEDIFF tính từ NGAYMAT đến hiện tại > 15 ngày
    -- 2. MATH không tồn tại trong bảng NGANKEO (nghĩa là không nằm trong tủ)
    WHILE EXISTS (
        SELECT 1
        FROM THIHAI 
        WHERE DATEDIFF(DAY, NGAYMAT, GETDATE()) > 15
          AND MATH NOT IN (SELECT MATH FROM NGANKEO WHERE MATH IS NOT NULL)
    )
    BEGIN
        -- Lấy ra mã thi hài đầu tiên thỏa mãn điều kiện trên
        SELECT TOP 1 @MATH_XULY = MATH
        FROM THIHAI
        WHERE DATEDIFF(DAY, NGAYMAT, GETDATE()) > 15
          AND MATH NOT IN (SELECT MATH FROM NGANKEO WHERE MATH IS NOT NULL);

        -- Bắt đầu Transaction để đảm bảo xóa sạch sẽ, không bị kẹt dữ liệu rác
        BEGIN TRANSACTION;

        -- BƯỚC 1: Xóa các dữ liệu liên quan ở bảng con (Dựa theo cấu trúc bạn đã cung cấp)
        DELETE FROM SUDUNG WHERE MATH = @MATH_XULY;
        DELETE FROM HOSOKHAMBENH WHERE MATH = @MATH_XULY;
        
        -- Lưu ý: Không cần DELETE FROM NGANKEO vì điều kiện của chúng ta là nó KHÔNG có trong ngăn kéo rồi

        -- BƯỚC 2: Xóa thông tin thi hài ở bảng chính
        DELETE FROM THIHAI WHERE MATH = @MATH_XULY;

        COMMIT TRANSACTION;
    END

    -- Thông báo khi vòng lặp dọn dẹp kết thúc
    PRINT N'Đã hoàn tất dọn dẹp các thi hài mất quá 15 ngày và không còn nằm trong ngăn kéo!';
END
GO

-- =============================================
-- 5.3 NGĂN KÉO
-- THỦ TỤC DANH SÁCH NGĂN KÉO
CREATE PROC SP_DSNganKeo
AS
BEGIN
	SELECT * FROM NGANKEO
END

GO
-- THỦ TỤC THÊM
CREATE PROC SP_ThemNganKeo
    @MANGAN CHAR(15),
    @VITRI NVARCHAR(50),
    @NHIETDO FLOAT,
    @MATH CHAR(15)
AS
BEGIN
    INSERT INTO NGANKEO
    (MANGAN, VITRI, NHIETDO, MATH)
    VALUES
    (@MANGAN, @VITRI, @NHIETDO, @MATH)
END

GO
-- THỦ TỤC SỬA
CREATE PROC SP_SuaNganKeo
	@MANGAN CHAR(15),
    @VITRI NVARCHAR(50),
    @NHIETDO FLOAT,
    @MATH CHAR(15)
AS
BEGIN
	UPDATE NGANKEO
	SET VITRI = @VITRI,
		 NHIETDO = @NHIETDO,
		MATH = @MATH
	WHERE MANGAN = @MANGAN
END

GO
-- THỦ TỤC XÓA
CREATE PROC SP_XoaNganKeo
    @MANGAN CHAR(15)
AS
BEGIN
	BEGIN TRANSACTION

		DELETE FROM NGANKEO WHERE MANGAN = @MANGAN

	COMMIT TRANSACTION
END

GO

-- =============================================
-- 5.4 HỒ SƠ KHÁM NGHIỆM
-- THỦ TỤC DANH SÁCH HỒ SƠ KHÁM NGHIỆM
CREATE PROC SP_DSHoSoKhamNghiem
AS
BEGIN
	SELECT * FROM VIEW_HoSoKhamBenh
END

GO
-- THỦ TỤC THÊM
CREATE PROC SP_ThemHoSoKhamBenh
    @MAHS CHAR(15),
    @THOIGIANKHAM DATE,
    @KETLUAN NVARCHAR(50),
    @MATH CHAR(15),
    @MABS CHAR(15)
AS
BEGIN
    INSERT INTO HOSOKHAMBENH
    VALUES (@MAHS, @THOIGIANKHAM, @KETLUAN, @MATH, @MABS)
END

GO
-- THỦ TỤC SỬA
CREATE PROC SP_SuaHoSoKhamBenh
    @MAHS CHAR(15),
    @THOIGIANKHAM DATE,
    @KETLUAN NVARCHAR(50),
    @MATH CHAR(15),
    @MABS CHAR(15)
AS
BEGIN
    UPDATE HOSOKHAMBENH
    SET THOIGIANKHAM = @THOIGIANKHAM,
        KETLUAN = @KETLUAN,
        MATH = @MATH,
        MABS = @MABS
    WHERE MAHS = @MAHS
END

GO

-- THỦ TỤC XÓA
CREATE PROC SP_XoaHoSoKhamBenh
    @MAHS CHAR(15)
AS
BEGIN
	BEGIN TRANSACTION

		DELETE FROM HOSOKHAMBENH WHERE MAHS = @MAHS

	COMMIT TRANSACTION
END

GO
-- =============================================
-- 5.5 DỊCH VỤ
-- THỦ TỤC DANH SÁCH DỊCH VỤ
CREATE PROC SP_DSDichVu
AS
BEGIN
	SELECT * FROM VIEW_DichVu
END

GO
-- THỦ TỤC THÊM
CREATE PROC SP_ThemDichVu
    @MADV CHAR(15),
	@TENDV NVARCHAR(100),
	@GIA MONEY
AS
BEGIN
	INSERT INTO DICHVU
	VALUES(@MADV, @TENDV, @GIA)
END

GO
-- THỦ TỤC SỬA
CREATE PROC SP_SuaDichVu
    @MADV CHAR(15),
    @TENDV NVARCHAR(100),
    @GIA MONEY
AS
BEGIN
    UPDATE DICHVU
    SET TENDV = @TENDV,
        GIATIEN = @GIA
    WHERE MADV = @MADV
END

GO
-- THỦ TỤC XÓA
CREATE PROC SP_XoaDichVu
    @MADV CHAR(15)
AS
BEGIN
	BEGIN TRANSACTION

		DELETE FROM DICHVU WHERE MADV = @MADV

	COMMIT TRANSACTION
END

GO
-- THỦ TỤC lỌC DANH SÁCH DỊCH VỤ KHÔNG CÓ NGƯỜI ĐẶT (DỊCH VỤ Ế)
CREATE PROC SP_DichVuE
AS
BEGIN
	SELECT * FROM VIEW_DichVuE
END

GO
-- =============================================
-- 5.6 SỬ DUNG
-- THỦ TỤC DANH SÁCH DỊCH VỤ SỬ DỤNG
CREATE PROC SP_DSDichVuSuDung
AS
BEGIN
	SELECT * FROM VIEW_DichVuSuDung
END

GO
-- THỦ TỤC THÊM
CREATE PROC SP_ThemDichVuSudung
	@MATH CHAR(15),
    @MADV CHAR(15),
	@NGAYSD DATE,
	@GHICHU NVARCHAR(200)
AS
BEGIN
	INSERT INTO SUDUNG
	VALUES(@MATH, @MADV, @NGAYSD, @GHICHU)
END

GO
--Xóa
CREATE PROC SP_XoaDichVuSuDung
	@MATH CHAR(15),
    @MADV CHAR(15),
	@NGAYSD DATE
AS
BEGIN
	BEGIN TRANSACTION

		DELETE FROM SUDUNG WHERE MATH = @MATH AND MADV = @MADV AND NGAYSUDUNG = @NGAYSD

	COMMIT TRANSACTION
END

GO
-- THỦ TỤC SỬA
CREATE PROC SP_SuaDichVuSudung
    @MATH CHAR(15),
    @MADV CHAR(15),
    @NGAYSD DATE,
    @GHICHU NVARCHAR(200)
AS
BEGIN
    UPDATE SUDUNG
    SET NGAYSUDUNG = @NGAYSD,
        GHICHU = @GHICHU
    WHERE MATH = @MATH AND MADV = @MADV
END

GO
-- THỦ TỤC TÍNH TỔNG TIỀN DỊCH VỤ CỦA THI HÀI
CREATE PROCEDURE sp_TinhTongTienDichVu
    @MaTH CHAR(15),           -- Tham số Input: Mã thi hài
    @TongTien MONEY OUTPUT    -- Tham số Output: Tổng tiền trả về
AS
BEGIN
    -- Sử dụng ISNULL để nếu thi hài chưa dùng dịch vụ nào thì trả về 0 thay vì NULL
    SELECT @TongTien = ISNULL(SUM(DV.GIATIEN), 0)
    FROM SUDUNG SD
    INNER JOIN DICHVU DV ON SD.MADV = DV.MADV
    WHERE SD.MATH = @MaTH;
END;

GO
-- =============================================
-- 6. HÀM
-- =============================================
-- 1. Hàm tính tổng tiền dịch vụ của mã thi hài đó
CREATE FUNCTION FN_TinhTongTienDichVu(@MATH CHAR(15))
RETURNS MONEY
AS
BEGIN
	DECLARE @TongTien MONEY;
	
	SELECT @TongTien = ISNULL(SUM(dv.GIATIEN), 0)
	FROM SUDUNG sd, DICHVU dv
	WHERE sd.MADV = dv.MADV
	AND sd.MATH = @MATH

	RETURN @TongTien
END

GO

-- 2. Hàm cập nhật trạng thái ngăn kéo
CREATE FUNCTION FN_CapNhatTrangThaiNganKeo(@MANGAN CHAR(15))
RETURNS NVARCHAR(50)
AS
BEGIN
	DECLARE @TrangThai NVARCHAR(50)
	DECLARE @MATH CHAR(15)

	SELECT @MATH = MATH FROM NGANKEO WHERE MANGAN=@MANGAN

	IF @MATH IS NULL
		SET @TrangThai = N'Trống'
	ELSe
		SET @TrangTHai = N'Đang sử dụng'

	RETURN @TrangThai
END

GO

-- 3. Hàm tìm ngăn kéo trống
CREATE FUNCTION fn_DanhSachNganKeoTrong ()
RETURNS TABLE
AS
RETURN 
(
    SELECT MANGAN, VITRI, NHIETDO
    FROM NGANKEO
    WHERE MATH IS NULL
)

GO

-- 4. Hàm tìm kiếm dịch vụ của tử thi
CREATE FUNCTION fn_LichSuDichVuCuaTuThi (@MATH CHAR(15))
RETURNS TABLE
AS
RETURN
(
    SELECT dv.TENDV, dv.GIATIEN, sd.NGAYSUDUNG, sd.GHICHU
    FROM SUDUNG sd
    JOIN DICHVU dv ON sd.MADV = dv.MADV
    WHERE sd.MATH = @MATH
)

GO

-- 5. Hàm tìm kiếm thi hài dựa trên ngày (có thể là ngày mất hoặc ngày sinh)
CREATE FUNCTION fn_TimKiemThiHaiTheoNgay (@NgayTimKiem DATE)
RETURNS TABLE
AS
RETURN
(
    SELECT THIHAI.*
    FROM THIHAI
    WHERE NGAYMAT = @NgayTimKiem OR NGAYSINH = @NgayTimKiem
)

GO

-- 6. Hàm liệt kê hồ sơ khám nghiệm của bác sĩ ...
CREATE FUNCTION fn_DanhSachKhamNghiemTheoBacSi (@MABS CHAR(15))
RETURNS TABLE
AS
RETURN
(
    SELECT th.MATH, th.HOTEN_TH, th.GIOITINH, hs.THOIGIANKHAM, hs.KETLUAN
    FROM HOSOKHAMBENH hs
    JOIN THIHAI th ON hs.MATH = th.MATH
    WHERE hs.MABS = @MABS
)

GO

-- 7. Hàm liệt kê hô sơ khàm nghiệm theo tử thi
CREATE FUNCTION fn_DanhSachKhamNghiemTheoTuThi (@MATH CHAR(15))
RETURNS TABLE
AS
RETURN
(
    SELECT hs.MAHS, hs.MATH, hs.MABS, bs.HOTEN_BS, hs.THOIGIANKHAM, hs.KETLUAN
    FROM HOSOKHAMBENH hs
    JOIN BACSI bs ON hs.MABS = bs.MABS
    WHERE hs.MATH = @MATH
);
GO

-- =============================================

-- =============================================
-- Trigger thêm
-- =============================================
-- 1. Trigger kiểm tra ngày khám nghiệm (HOSOKHAMBENH)
-- Ý nghĩa: Bác sĩ không thể khám nghiệm tử thi trước khi người đó mất. Ngày khám (THOIGIANKHAM) phải lớn hơn hoặc bằng ngày mất (NGAYMAT).
GO
CREATE TRIGGER TRG_KiemTraNgayKham
ON HOSOKHAMBENH
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS 
    (
        SELECT *
        FROM inserted i, THIHAI th 
        WHERE i.MATH = th.MATH
        AND i.THOIGIANKHAM < th.NGAYMAT
    )
    BEGIN
        PRINT N'Lỗi: Ngày khám nghiệm không được trước ngày mất của thi hài!' 
        ROLLBACK TRANSACTION
    END
END
GO

-- 2. Trigger kiểm tra ngày sử dụng dịch vụ (SUDUNG)
-- Ý nghĩa: Tương tự như trên, thi hài chỉ có thể bắt đầu sử dụng dịch vụ (khâm liệm, trang điểm, bảo quản) từ ngày mất trở đi.
GO
CREATE TRIGGER TRG_KiemTraNgayDichVu
ON SUDUNG
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS 
    (
        SELECT *
        FROM inserted i, THIHAI th
        WHERE i.MATH = th.MATH
        AND i.NGAYSUDUNG < th.NGAYMAT
    )
    BEGIN
        PRINT N'Lỗi: Ngày sử dụng dịch vụ không hợp lý (Sớm hơn ngày mất)!'
        ROLLBACK TRANSACTION
    END
END
GO

-- 3. Trigger kiểm tra cấu trúc phân cấp Bác sĩ (BACSI)
-- Ý nghĩa: Một bác sĩ không thể tự làm trưởng khoa của chính mình (MABS và MA_TRUONGKHOA không được trùng nhau) để tránh lỗi đệ quy vòng lặp.
GO
CREATE TRIGGER TRG_KiemTraTruongKhoa
ON BACSI
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS 
    (
        SELECT *
        FROM inserted 
        WHERE MABS = MA_TRUONGKHOA
    )
    BEGIN
        PRINT N'Lỗi: Bác sĩ không thể tự nhận mình là trưởng khoa của chính mình!'
        ROLLBACK TRANSACTION
    END
END
GO

-- 4. Trigger tự động dọn dẹp khi xóa Thi hài (Thay thế SP_XoaThiHai)
-- Ý nghĩa: Thay vì phải viết Transaction dài dòng trong Stored Procedure, ta dùng INSTEAD OF DELETE để tự động xóa hồ sơ, dịch vụ, và đặc biệt là giải phóng ngăn kéo (chỉ Update MATH = NULL chứ không xóa cái ngăn kéo vật lý đó).
GO
CREATE TRIGGER TRG_CascadeDelete_ThiHai
ON THIHAI
INSTEAD OF DELETE
AS
BEGIN
    -- 1. Xóa hồ sơ khám bệnh liên quan
    DELETE FROM HOSOKHAMBENH WHERE MATH IN (SELECT MATH FROM deleted)
    
    -- 2. Xóa các dịch vụ đã sử dụng
    DELETE FROM SUDUNG WHERE MATH IN (SELECT MATH FROM deleted)
    
    -- 3. Giải phóng ngăn kéo (Set null chứ không xóa tủ)
    UPDATE NGANKEO SET MATH = NULL WHERE MATH IN (SELECT MATH FROM deleted)
    
    -- 4. Xóa thi hài
    DELETE FROM THIHAI WHERE MATH IN (SELECT MATH FROM deleted)

    -- 5. In thông tin thông báo thành công
    PRINT N'Đã xóa thông tin thi hài thành công'
END
GO

-- 5. Trigger tự động đăng ký dịch vụ "Bảo quản lạnh"
-- Ý nghĩa: Khi một thi hài được phân vào Ngăn kéo (Cột MATH trong bảng NGANKEO được UPDATE từ NULL thành có mã), hệ thống tự động chèn một dòng vào bảng SUDUNG với dịch vụ DV003 (Bảo quản lạnh).
GO
CREATE TRIGGER TRG_TuDongBaoQuanLanh
ON NGANKEO
AFTER UPDATE
AS
BEGIN
    -- Nếu cột MATH được cập nhật từ NULL thành một mã thi hài nào đó
    IF UPDATE(MATH)
    BEGIN
        INSERT INTO SUDUNG (MATH, MADV, NGAYSUDUNG, GHICHU)
        SELECT i.MATH, 'DV003', GETDATE(), N'Tự động kích hoạt do nhập tủ lạnh'
        FROM inserted i, deleted d 
        WHERE i.MANGAN = d.MANGAN
        AND i.MATH IS NOT NULL AND d.MATH IS NULL
        -- Kiểm tra tránh insert trùng nếu đã có
        AND NOT EXISTS (SELECT * FROM SUDUNG s WHERE s.MATH = i.MATH AND s.MADV = 'DV003')
    END
END
GO

-- 6. Trigger kiểm soát nhiệt độ ngăn kéo đang có thi hài
-- Ý nghĩa: Giả sử quy định nhà xác là nếu tủ đang chứa xác (MATH IS NOT NULL) thì nhiệt độ không bao giờ được phép điều chỉnh vượt quá 0 độ C để tránh phân hủy.
GO
CREATE TRIGGER TRG_CanhBaoNhietDoNganKeo
ON NGANKEO
FOR UPDATE
AS
BEGIN
    IF UPDATE(NHIETDO)
    BEGIN
        IF EXISTS 
        (
            SELECT *
            FROM inserted 
            WHERE MATH IS NOT NULL AND NHIETDO > 0
        )
        BEGIN
            PRINT N'Cảnh báo nghiêm trọng: Không được chỉnh nhiệt độ > 0°C khi tủ đang có thi hài!'
            ROLLBACK TRANSACTION
        END
    END
END
GO

-- 7. Trigger cấm xóa Hồ sơ khám nghiệm (HOSOKHAMBENH)
-- Ý nghĩa: Hồ sơ khám nghiệm/pháp y là tài liệu mang tính pháp lý cao. Nghiêm cấm mọi hành vi dùng lệnh DELETE xóa hồ sơ này.
GO
CREATE TRIGGER TRG_BaoVeHoSoPhapY
ON HOSOKHAMBENH
FOR DELETE
AS
BEGIN
    PRINT N'Cảnh báo an ninh: Hồ sơ pháp y là tài liệu vĩnh viễn, không được phép xóa khỏi cơ sở dữ liệu!'
    ROLLBACK TRANSACTION
END
GO
-- =============================================
-- 8. Trigger giới hạn năng suất làm việc của Bác sĩ
-- Ý nghĩa: Để đảm bảo chất lượng pháp y, một bác sĩ không được phân công khám nghiệm quá 3 thi hài trong cùng 1 ngày.
GO
CREATE TRIGGER TRG_GioiHanCaKhamBacSi
ON HOSOKHAMBENH
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS 
    (
        SELECT i.MABS, i.THOIGIANKHAM
        FROM inserted i, HOSOKHAMBENH hs
        WHERE i.MABS = hs.MABS AND i.THOIGIANKHAM = hs.THOIGIANKHAM
        GROUP BY i.MABS, i.THOIGIANKHAM
        HAVING COUNT(*) > 3
    )
    BEGIN
        PRINT N'Lỗi phân công: Một bác sĩ không thể thực hiện quá 3 ca khám nghiệm trong cùng 1 ngày!'
        ROLLBACK TRANSACTION
    END
END
GO
-- =============================================
-- PHÂN QUYỀN
-- =============================================
CREATE PROC SP_KiemTraQuyenHan
AS
BEGIN
    -- Kiểm tra quyền và trả về chuỗi tương ứng
    IF (IS_ROLEMEMBER('db_owner') = 1 OR IS_ROLEMEMBER('db_datawriter') = 1)
        SELECT 'WriteAccess' AS QuyenHan;
    ELSE
        SELECT 'ReadOnly' AS QuyenHan;
END;

GO

GRANT EXECUTE ON sp_KiemTraQuyenHan TO public;

GO

GRANT EXECUTE ON SP_DSThiHai TO public;

GO

GRANT EXECUTE ON SP_DemThiHai TO public;

GO

GRANT EXECUTE ON SP_DSDichVu TO public;

GO
-- =============================================

-- =============================================

-- =============================================
use master

GO
-- 1. Tạo Login (Chìa khóa vào Server)
-- Nếu đã có rồi thì xóa đi tạo lại cho chắc
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'NhaXacAdmin')
    DROP LOGIN [NhaXacAdmin]
GO

CREATE LOGIN [NhaXacAdmin] WITH PASSWORD=N'123456', DEFAULT_DATABASE=[QuanLyNhaXac], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF

GO
-- 2. Tạo User (Quyền trong Database)
-- Nếu đã có user này trong DB rồi thì xóa đi
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'NhaXacAdmin')
    DROP USER [NhaXacAdmin]
GO
--CREATE LOGIN [aaa] WITH PASSWORD=N'aaa', DEFAULT_DATABASE=[QuanLyNhaXac], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
--GO

--CREATE USER[aaa] FOR LOGIN [aaa]

CREATE USER [NhaXacAdmin] FOR LOGIN [NhaXacAdmin]
GO

-- 3. Cấp quyền "Tối thượng" (db_owner) để App thoải mái Thêm/Sửa/Xóa
ALTER ROLE [db_owner] ADD MEMBER [NhaXacAdmin]
GO

USE QuanLyNhaXac
GO


