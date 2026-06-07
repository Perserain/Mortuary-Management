use master
IF EXISTS(SELECT 1 FROM sys.databases WHERE NAME = 'QuanLyNhaXac')
	DROP DATABASE QuanLyNhaXac

GO

CREATE DATABASE QuanLyNhaXac
--1. FILE DỮ LIỆU CHÍNH
ON PRIMARY
(
    NAME = 'QuanLyNhaXac_Main',
    FILENAME = 'C:\Users\admin\OneDrive\Desktop\Mortuary-Management\QLNhaXac\QuanLyNhaXac_Main\QuanLyNhaXac_Main.mdf',
    SIZE = 10MB,          -- Kích thước ban đầu
    MAXSIZE = 30MB,      -- Kích thước tối đa
    FILEGROWTH = 5MB      -- Tốc độ tăng trưởng
),
--2. FILE DỮ LIỆU PHỤ
FILEGROUP SecondaryGroup
(
    NAME = 'QuanLyNhaXac_Sub',
    FILENAME = 'C:\Users\admin\OneDrive\Desktop\Mortuary-Management\QLNhaXac\QuanLyNhaXac_Sub\QuanLyNhaXac_Sub.ndf',
    SIZE = 10MB,          -- Kích thước ban đầu
    MAXSIZE = 30MB,      -- Kích thước tối đa
    FILEGROWTH = 5MB      -- Tốc độ tăng trưởng
)
-- 3. File nhật ký (.ldf) - Log file
LOG ON
(
    NAME = 'QuanLyNhaXac_Log',
    FILENAME = 'C:\Users\admin\OneDrive\Desktop\Mortuary-Management\QLNhaXac\QuanLyNhaXac_Log\QuanLyNhaXac_Log.ldf',
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
    MATH VARCHAR(15) NOT NULL,       
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
    MABS VARCHAR(15) NOT NULL,
    HOTEN_BS NVARCHAR(100),
    CHUYENKHOA NVARCHAR(100),
    NAMKINHNGHIEM INT,
    -- KHÓA CHÍNH
    CONSTRAINT PK_BS PRIMARY KEY(MABS)
)

-- Bảng 3: Dịch Vụ (Ví dụ: Khâm liệm, Trang điểm...)
CREATE TABLE DICHVU 
(
    MADV VARCHAR(15) NOT NULL,
    TENDV NVARCHAR(100),
    GIATIEN MONEY,
    -- KHÓA CHÍNH
    CONSTRAINT PK_DV PRIMARY KEY(MADV)
)

-- Bảng 4: Ngăn Kéo (Quan hệ 1-1 với Tử Thi)
CREATE TABLE NGANKEO 
(
    MANGAN VARCHAR(15) NOT NULL,
    VITRI NVARCHAR(50),              -- Ví dụ: Khu A, Tầng 2
    NHIETDO FLOAT,                   -- Nhiệt độ bảo quản
    MATH VARCHAR(15),     
    -- KHÓA CHÍNH
    CONSTRAINT PK_NK PRIMARY KEY(MANGAN)
)

-- Bảng 5: Hồ Sơ Khám Nghiệm (Quan hệ 1-n: Bác sĩ khám cho Tử thi)
CREATE TABLE HOSOKHAMBENH
(
    MAHS VARCHAR(15) NOT NULL,
    THOIGIANKHAM DATE,
    KETLUAN NVARCHAR(50),           
    MATH VARCHAR(15),
    MABS VARCHAR(15),
    -- KHÓA CHÍNH
    CONSTRAINT PK_HS PRIMARY KEY(MAHS)
)

-- Bảng 6: Sử Dụng Dịch Vụ (Quan hệ n-n: Tử thi dùng Dịch vụ)
CREATE TABLE SUDUNG 
(
    MATH VARCHAR(15) NOT NULL,
    MADV VARCHAR(15) NOT NULL,
    NGAYSUDUNG DATE,
    GHICHU NVARCHAR(200),
    -- Khóa chính là cặp (MATH, MADV)
    PRIMARY KEY (MATH, MADV)
)

GO

-- 1. Thêm cột MA_TRUONGKHOA vào bảng BACSI
ALTER TABLE BACSI
ADD MA_TRUONGKHOA VARCHAR(15); 

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
    @MA_TRUONGKHOA VARCHAR(15)
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
    @MABS VARCHAR(15)
AS
BEGIN

	DELETE FROM BACSI WHERE MABS=@MABS
END

GO


-- THỦ TỤC SỬA
CREATE PROC SP_SuaBacSi
	@MABS VARCHAR(15),
    @HOTEN_BS NVARCHAR(100),
    @CHUYENKHOA NVARCHAR(100),
    @NAMKINHNGHIEM INT,
    @MA_TRUONGKHOA VARCHAR(15)
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
    @MATH VARCHAR(15),
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
    @MATH VARCHAR(15),
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
    @MATH VARCHAR(15)
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
    DECLARE @MATH_XULY VARCHAR(15);

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
    @MANGAN VARCHAR(15),
    @VITRI NVARCHAR(50),
    @NHIETDO FLOAT,
    @MATH VARCHAR(15)
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
	@MANGAN VARCHAR(15),
    @VITRI NVARCHAR(50),
    @NHIETDO FLOAT,
    @MATH VARCHAR(15)
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
    @MANGAN VARCHAR(15)
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
    @MAHS VARCHAR(15),
    @THOIGIANKHAM DATE,
    @KETLUAN NVARCHAR(50),
    @MATH VARCHAR(15),
    @MABS VARCHAR(15)
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
    @MAHS VARCHAR(15)
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
    @MADV VARCHAR(15),
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
    @MADV VARCHAR(15),
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
    @MADV VARCHAR(15)
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
	@MATH VARCHAR(15),
    @MADV VARCHAR(15),
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
	@MATH VARCHAR(15),
    @MADV VARCHAR(15),
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
    @MATH VARCHAR(15),
    @MADV VARCHAR(15),
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
    @MaTH VARCHAR(15),           -- Tham số Input: Mã thi hài
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
CREATE FUNCTION FN_TinhTongTienDichVu(@MATH VARCHAR(15))
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
CREATE FUNCTION FN_CapNhatTrangThaiNganKeo(@MANGAN VARCHAR(15))
RETURNS NVARCHAR(50)
AS
BEGIN
	DECLARE @TrangThai NVARCHAR(50)
	DECLARE @MATH VARCHAR(15)

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
CREATE FUNCTION fn_LichSuDichVuCuaTuThi (@MATH VARCHAR(15))
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
CREATE FUNCTION fn_DanhSachKhamNghiemTheoBacSi (@MABS VARCHAR(15))
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
CREATE FUNCTION fn_DanhSachKhamNghiemTheoTuThi (@MATH VARCHAR(15))
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
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'app_admin')
    CREATE ROLE [app_admin];
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'app_staff')
    CREATE ROLE [app_staff];

GO

CREATE PROC SP_KiemTraQuyenHan
AS
BEGIN
    -- Kiểm tra quyền và trả về chuỗi tương ứng
    IF (IS_ROLEMEMBER('app_admin') = 1 OR IS_ROLEMEMBER('db_owner') = 1)
        SELECT 'Admin' AS QuyenHan;
    ELSE IF (IS_ROLEMEMBER('app_staff') = 1 OR IS_ROLEMEMBER('db_datareader') = 1)
        SELECT 'Staff' AS QuyenHan;
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

GRANT EXECUTE ON SP_DSThiHai TO app_staff;
GRANT EXECUTE ON SP_DSDichVu TO app_staff;
GRANT EXECUTE ON SP_DSDichVuSuDung TO app_staff;
GRANT EXECUTE ON SP_ThemDichVuSudung TO app_staff;
GRANT EXECUTE ON sp_TinhTongTienDichVu TO app_staff;

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

CREATE LOGIN [bb] WITH PASSWORD='bb', DEFAULT_DATABASE=[QuanLyNhaXac], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
CREATE USER [bb] for LOGIN [bb]
-- 3. Cấp quyền "Tối thượng" (db_owner) để App thoải mái Thêm/Sửa/Xóa
ALTER ROLE [db_owner] ADD MEMBER [NhaXacAdmin]
ALTER ROLE [app_admin] ADD MEMBER [NhaXacAdmin]
GO

USE QuanLyNhaXac
GO

/*
-- DEBUG LocalDB (Windows Auth) - đổi thành Windows login thật rồi bỏ dấu comment ở đầu/cuối
-- Ví dụ: MAYCUA_BAN\TenUser
USE master
GO
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'MAYCUA_BAN\TenUser')
    DROP LOGIN [MAYCUA_BAN\TenUser]
GO
CREATE LOGIN [MAYCUA_BAN\TenUser] FROM WINDOWS
GO
USE QuanLyNhaXac
GO
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'MAYCUA_BAN\TenUser')
    DROP USER [MAYCUA_BAN\TenUser]
GO
CREATE USER [MAYCUA_BAN\TenUser] FOR LOGIN [MAYCUA_BAN\TenUser]
GO
-- Admin debug
ALTER ROLE [db_owner] ADD MEMBER [MAYCUA_BAN\TenUser]
ALTER ROLE [app_admin] ADD MEMBER [MAYCUA_BAN\TenUser]
-- Staff debug (chỉ đọc + cung cấp dịch vụ)
ALTER ROLE [app_staff] ADD MEMBER [MAYCUA_BAN\TenUser]
GO
*/

-- =============================================
-- PHẦN MỞ RỘNG: HỆ THỐNG PHÂN QUYỀN NÂNG CAO
-- Dành cho QuanLyNhaXac
-- =============================================

USE QuanLyNhaXac
GO

-- =============================================
-- BƯỚC 1: TẠO 3 NHÓM QUYỀN (DATABASE ROLES)
-- =============================================

-- Nhóm Admin: Toàn quyền tất cả bảng
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'QL_ADMIN' AND type = 'R')
    CREATE ROLE [QL_ADMIN];
GO

-- Nhóm Nhân Viên: SELECT trên THIHAI + toàn quyền DICHVU, SUDUNG
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'QL_NHANVIEN' AND type = 'R')
    CREATE ROLE [QL_NHANVIEN];
GO

-- Nhóm Bác Sĩ: toàn quyền THIHAI, NGANKEO, HOSOKHAMBENH
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'QL_BACSI' AND type = 'R')
    CREATE ROLE [QL_BACSI];
GO

-- =============================================
-- BƯỚC 2: CẤP QUYỀN CHO TỪNG NHÓM
-- =============================================

-- QL_ADMIN: Toàn quyền 7 bảng
GRANT SELECT, INSERT, UPDATE, DELETE ON THIHAI TO [QL_ADMIN] WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON DICHVU TO [QL_ADMIN] WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON SUDUNG TO [QL_ADMIN] WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON NGANKEO TO [QL_ADMIN] WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON HOSOKHAMBENH TO [QL_ADMIN] WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON NHANVIEN TO [QL_ADMIN] WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON BACSI TO [QL_ADMIN] WITH GRANT OPTION;
GO

-- QL_NHANVIEN: Chỉ SELECT trên THIHAI, toàn quyền DICHVU và SUDUNG
GRANT SELECT ON THIHAI TO [QL_NHANVIEN];
GRANT SELECT, INSERT, UPDATE, DELETE ON DICHVU TO [QL_NHANVIEN];
GRANT SELECT, INSERT, UPDATE, DELETE ON SUDUNG TO [QL_NHANVIEN];
GO

-- QL_BACSI: Toàn quyền THIHAI, NGANKEO, HOSOKHAMBENH
GRANT SELECT, INSERT, UPDATE, DELETE ON THIHAI TO [QL_BACSI];
GRANT SELECT, INSERT, UPDATE, DELETE ON NGANKEO TO [QL_BACSI];
GRANT SELECT, INSERT, UPDATE, DELETE ON HOSOKHAMBENH TO [QL_BACSI];
GO

-- =============================================
-- BƯỚC 3: TẠO BẢNG NHANVIEN (nếu chưa có)
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'NHANVIEN')
BEGIN
    CREATE TABLE NHANVIEN
    (
        MANV VARCHAR(15) NOT NULL,
        HOTEN_NV NVARCHAR(100),
        CHUCVU NVARCHAR(100),
        DIENTHOAI VARCHAR(15),
        CONSTRAINT PK_NV PRIMARY KEY (MANV)
    );

    -- Dữ liệu mẫu
    INSERT INTO NHANVIEN VALUES
    ('NV001', N'Nguyễn Thị Lan', N'Lễ tân', '0901111111'),
    ('NV002', N'Trần Văn Bình', N'Chăm sóc thi hài','0902222222'),
    ('NV003', N'Lê Thị Hoa', N'Kế toán', '0903333333');
END
GO

-- =============================================
-- BƯỚC 4: STORED PROCEDURES HỖ TRỢ PHÂN QUYỀN
-- =============================================

-- SP: Lấy danh sách tất cả Database Users (loại trừ system)
IF OBJECT_ID('SP_DanhSachUser', 'P') IS NOT NULL
    DROP PROCEDURE SP_DanhSachUser;
GO
CREATE PROCEDURE SP_DanhSachUser
AS
BEGIN
    SELECT 
        dp.name AS TenUser,
        dp.type_desc AS LoaiUser,
        ISNULL(sp.name,'(No Login)') AS TenLogin,
        dp.create_date AS NgayTao
    FROM sys.database_principals dp
    LEFT JOIN sys.server_principals sp ON dp.sid = sp.sid
    WHERE dp.type IN ('S','U','G') -- SQL user / Windows user / Windows group
      AND dp.name NOT IN ('dbo','guest','INFORMATION_SCHEMA','sys')
      AND dp.name NOT LIKE '##%'
    ORDER BY dp.name;
END
GO

-- SP: Lấy danh sách tất cả Roles (nhóm quyền)
IF OBJECT_ID('SP_DanhSachRole', 'P') IS NOT NULL
    DROP PROCEDURE SP_DanhSachRole;
GO
CREATE PROCEDURE SP_DanhSachRole
AS
BEGIN
    SELECT 
        name AS TenRole,
        type_desc AS LoaiRole,
        create_date AS NgayTao
    FROM sys.database_principals
    WHERE type = 'R'
      AND is_fixed_role = 0
      AND name NOT IN ('public')
    ORDER BY name;
END
GO

-- SP: Lấy quyền của 1 user trên 1 bảng cụ thể
IF OBJECT_ID('SP_QuyenCuaUser', 'P') IS NOT NULL
    DROP PROCEDURE SP_QuyenCuaUser;
GO
CREATE PROCEDURE SP_QuyenCuaUser
    @TenUser NVARCHAR(128),
    @TenBang NVARCHAR(128)
AS
BEGIN
    -- Kiểm tra quyền trực tiếp
    SELECT 
        p.class_desc AS NguonQuyen,
        p.permission_name AS TenQuyen,
        p.state_desc AS TrangThai,
        @TenUser AS TenUser,
        @TenBang AS TenBang
    FROM sys.database_permissions p
    JOIN sys.objects o ON p.major_id = o.object_id
    JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
    WHERE dp.name = @TenUser
      AND o.name = @TenBang
      AND p.class = 1

    UNION ALL

    -- Kiểm tra quyền qua Role
    SELECT 
        'THROUGH ROLE' AS NguonQuyen,
        p.permission_name AS TenQuyen,
        p.state_desc AS TrangThai,
        @TenUser AS TenUser,
        @TenBang AS TenBang
    FROM sys.database_permissions p
    JOIN sys.objects o ON p.major_id = o.object_id
    JOIN sys.database_principals role_dp ON p.grantee_principal_id = role_dp.principal_id
    JOIN sys.database_role_members rm ON role_dp.principal_id = rm.role_principal_id
    JOIN sys.database_principals user_dp ON rm.member_principal_id = user_dp.principal_id
    WHERE user_dp.name = @TenUser
      AND o.name = @TenBang
      AND p.class = 1;
END
GO

-- SP: Lấy toàn bộ quyền hiện tại của 1 user (tổng hợp tất cả bảng)
IF OBJECT_ID('SP_TatCaQuyenCuaUser', 'P') IS NOT NULL
    DROP PROCEDURE SP_TatCaQuyenCuaUser;
GO
CREATE PROCEDURE SP_TatCaQuyenCuaUser
    @TenUser NVARCHAR(128)
AS
BEGIN
    SELECT DISTINCT
        o.name AS TenBang,
        p.permission_name AS TenQuyen,
        p.state_desc AS TrangThai
    FROM sys.database_permissions p
    JOIN sys.objects o ON p.major_id = o.object_id
    JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
    WHERE dp.name = @TenUser AND p.class = 1

    UNION

    SELECT DISTINCT
        o.name AS TenBang,
        p.permission_name AS TenQuyen,
        p.state_desc AS TrangThai
    FROM sys.database_permissions p
    JOIN sys.objects o ON p.major_id = o.object_id
    JOIN sys.database_principals role_dp ON p.grantee_principal_id = role_dp.principal_id
    JOIN sys.database_role_members rm ON role_dp.principal_id = rm.role_principal_id
    JOIN sys.database_principals user_dp ON rm.member_principal_id = user_dp.principal_id
    WHERE user_dp.name = @TenUser AND p.class = 1
    ORDER BY TenBang, TenQuyen;
END
GO

-- SP: Lấy danh sách User thuộc Role nào
IF OBJECT_ID('SP_UserTrongRole', 'P') IS NOT NULL
    DROP PROCEDURE SP_UserTrongRole;
GO
CREATE PROCEDURE SP_UserTrongRole
    @TenRole NVARCHAR(128)
AS
BEGIN
    SELECT 
        u.name AS TenUser,
        u.type_desc AS LoaiUser
    FROM sys.database_role_members rm
    JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
    JOIN sys.database_principals u ON rm.member_principal_id = u.principal_id
    WHERE r.name = @TenRole
    ORDER BY u.name;
END
GO

-- SP: Lấy danh sách Role mà 1 User thuộc về
IF OBJECT_ID('SP_RoleCuaUser', 'P') IS NOT NULL
    DROP PROCEDURE SP_RoleCuaUser;
GO
CREATE PROCEDURE SP_RoleCuaUser
    @TenUser NVARCHAR(128)
AS
BEGIN
    SELECT 
        r.name AS TenRole,
        r.type_desc AS LoaiRole
    FROM sys.database_role_members rm
    JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
    JOIN sys.database_principals u ON rm.member_principal_id = u.principal_id
    WHERE u.name = @TenUser
    ORDER BY r.name;
END
GO

-- SP: Lấy danh sách User CHƯA thuộc Role (để hiện khi nhấn Grant)
IF OBJECT_ID('SP_UserChuaThuocRole', 'P') IS NOT NULL
    DROP PROCEDURE SP_UserChuaThuocRole;
GO
CREATE PROCEDURE SP_UserChuaThuocRole
    @TenRole NVARCHAR(128)
AS
BEGIN
    SELECT 
        dp.name AS TenUser,
        dp.type_desc AS LoaiUser
    FROM sys.database_principals dp
    WHERE dp.type IN ('S','U','G')
      AND dp.name NOT IN ('dbo','guest','INFORMATION_SCHEMA','sys')
      AND dp.name NOT LIKE '##%'
      AND dp.principal_id NOT IN (
            SELECT rm.member_principal_id
            FROM sys.database_role_members rm
            JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
            WHERE r.name = @TenRole
      )
    ORDER BY dp.name;
END
GO

-- =============================================
-- BƯỚC 5: STORED PROCEDURES THỰC HIỆN GRANT/REVOKE ĐỘNG
-- =============================================

-- SP: GRANT quyền trực tiếp cho User trên bảng
IF OBJECT_ID('SP_GrantQuyenChoUser', 'P') IS NOT NULL
    DROP PROCEDURE SP_GrantQuyenChoUser;
GO
CREATE PROCEDURE SP_GrantQuyenChoUser
    @TenUser NVARCHAR(128),
    @TenBang NVARCHAR(128),
    @CoSelect BIT = 0,
    @CoInsert BIT = 0,
    @CoUpdate BIT = 0,
    @CoDelete BIT = 0,
    @WithGrant BIT = 0
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @option NVARCHAR(50) = CASE WHEN @WithGrant = 1 THEN ' WITH GRANT OPTION' ELSE '' END;

    IF @CoSelect = 1
    BEGIN
        SET @sql = N'GRANT SELECT ON [' + @TenBang + N'] TO [' + @TenUser + N']' + @option;
        EXEC sp_executesql @sql;
    END
    IF @CoInsert = 1
    BEGIN
        SET @sql = N'GRANT INSERT ON [' + @TenBang + N'] TO [' + @TenUser + N']' + @option;
        EXEC sp_executesql @sql;
    END
    IF @CoUpdate = 1
    BEGIN
        SET @sql = N'GRANT UPDATE ON [' + @TenBang + N'] TO [' + @TenUser + N']' + @option;
        EXEC sp_executesql @sql;
    END
    IF @CoDelete = 1
    BEGIN
        SET @sql = N'GRANT DELETE ON [' + @TenBang + N'] TO [' + @TenUser + N']' + @option;
        EXEC sp_executesql @sql;
    END
END
GO

-- SP: REVOKE quyền trực tiếp của User trên bảng
IF OBJECT_ID('SP_RevokeQuyenCuaUser', 'P') IS NOT NULL
    DROP PROCEDURE SP_RevokeQuyenCuaUser;
GO
CREATE PROCEDURE SP_RevokeQuyenCuaUser
    @TenUser NVARCHAR(128),
    @TenBang NVARCHAR(128),
    @CoSelect BIT = 0,
    @CoInsert BIT = 0,
    @CoUpdate BIT = 0,
    @CoDelete BIT = 0,
    @Cascade BIT = 0
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @option NVARCHAR(50) = CASE WHEN @Cascade = 1 THEN ' CASCADE' ELSE '' END;

    IF @CoSelect = 1
    BEGIN
        SET @sql = N'REVOKE SELECT ON [' + @TenBang + N'] FROM [' + @TenUser + N']' + @option;
        EXEC sp_executesql @sql;
    END
    IF @CoInsert = 1
    BEGIN
        SET @sql = N'REVOKE INSERT ON [' + @TenBang + N'] FROM [' + @TenUser + N']' + @option;
        EXEC sp_executesql @sql;
    END
    IF @CoUpdate = 1
    BEGIN
        SET @sql = N'REVOKE UPDATE ON [' + @TenBang + N'] FROM [' + @TenUser + N']' + @option;
        EXEC sp_executesql @sql;
    END
    IF @CoDelete = 1
    BEGIN
        SET @sql = N'REVOKE DELETE ON [' + @TenBang + N'] FROM [' + @TenUser + N']' + @option;
        EXEC sp_executesql @sql;
    END
END
GO

-- SP: GRANT User vào Role
IF OBJECT_ID('SP_GrantUserVaoRole', 'P') IS NOT NULL
    DROP PROCEDURE SP_GrantUserVaoRole;
GO
CREATE PROCEDURE SP_GrantUserVaoRole
    @TenUser NVARCHAR(128),
    @TenRole NVARCHAR(128)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'ALTER ROLE [' + @TenRole + N'] ADD MEMBER [' + @TenUser + N']';
    EXEC sp_executesql @sql;
END
GO

-- SP: REVOKE User khỏi Role
IF OBJECT_ID('SP_RevokeUserKhoiRole', 'P') IS NOT NULL
    DROP PROCEDURE SP_RevokeUserKhoiRole;
GO
CREATE PROCEDURE SP_RevokeUserKhoiRole
    @TenUser NVARCHAR(128),
    @TenRole NVARCHAR(128)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'ALTER ROLE [' + @TenRole + N'] DROP MEMBER [' + @TenUser + N']';
    EXEC sp_executesql @sql;
END
GO

-- SP: Tạo Role mới và cấp quyền cho các bảng
IF OBJECT_ID('SP_TaoRoleMoi', 'P') IS NOT NULL
    DROP PROCEDURE SP_TaoRoleMoi;
GO
CREATE PROCEDURE SP_TaoRoleMoi
    @TenRole NVARCHAR(128),
    -- THIHAI
    @TH_Select BIT = 0, @TH_Insert BIT = 0, @TH_Update BIT = 0, @TH_Delete BIT = 0,
    -- DICHVU
    @DV_Select BIT = 0, @DV_Insert BIT = 0, @DV_Update BIT = 0, @DV_Delete BIT = 0,
    -- SUDUNG
    @SD_Select BIT = 0, @SD_Insert BIT = 0, @SD_Update BIT = 0, @SD_Delete BIT = 0,
    -- NGANKEO
    @NK_Select BIT = 0, @NK_Insert BIT = 0, @NK_Update BIT = 0, @NK_Delete BIT = 0,
    -- HOSOKHAMBENH
    @HS_Select BIT = 0, @HS_Insert BIT = 0, @HS_Update BIT = 0, @HS_Delete BIT = 0,
    -- NHANVIEN
    @NV_Select BIT = 0, @NV_Insert BIT = 0, @NV_Update BIT = 0, @NV_Delete BIT = 0,
    -- BACSI
    @BS_Select BIT = 0, @BS_Insert BIT = 0, @BS_Update BIT = 0, @BS_Delete BIT = 0
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);

    -- Tạo Role nếu chưa tồn tại
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @TenRole AND type = 'R')
    BEGIN
        SET @sql = N'CREATE ROLE [' + @TenRole + N']';
        EXEC sp_executesql @sql;
    END

    -- Helper: cấp quyền theo flag
    DECLARE @Tables TABLE (TenBang NVARCHAR(50), DoS BIT, DoI BIT, DoU BIT, DoD BIT)
    INSERT INTO @Tables VALUES
        ('THIHAI', @TH_Select, @TH_Insert, @TH_Update, @TH_Delete),
        ('DICHVU', @DV_Select, @DV_Insert, @DV_Update, @DV_Delete),
        ('SUDUNG', @SD_Select, @SD_Insert, @SD_Update, @SD_Delete),
        ('NGANKEO', @NK_Select, @NK_Insert, @NK_Update, @NK_Delete),
        ('HOSOKHAMBENH', @HS_Select, @HS_Insert, @HS_Update, @HS_Delete),
        ('NHANVIEN', @NV_Select, @NV_Insert, @NV_Update, @NV_Delete),
        ('BACSI', @BS_Select, @BS_Insert, @BS_Update, @BS_Delete);

    DECLARE @Bang NVARCHAR(50), @S BIT, @I BIT, @U BIT, @D BIT;
    DECLARE cur CURSOR FOR SELECT TenBang, DoS, DoI, DoU, DoD FROM @Tables;
    OPEN cur;
    FETCH NEXT FROM cur INTO @Bang, @S, @I, @U, @D;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Chỉ grant nếu bảng tồn tại
        IF EXISTS (SELECT 1 FROM sys.tables WHERE name = @Bang)
        BEGIN
            IF @S = 1 BEGIN SET @sql = N'GRANT SELECT ON ['+@Bang+N'] TO ['+@TenRole+N']'; EXEC sp_executesql @sql; END
            IF @I = 1 BEGIN SET @sql = N'GRANT INSERT ON ['+@Bang+N'] TO ['+@TenRole+N']'; EXEC sp_executesql @sql; END
            IF @U = 1 BEGIN SET @sql = N'GRANT UPDATE ON ['+@Bang+N'] TO ['+@TenRole+N']'; EXEC sp_executesql @sql; END
            IF @D = 1 BEGIN SET @sql = N'GRANT DELETE ON ['+@Bang+N'] TO ['+@TenRole+N']'; EXEC sp_executesql @sql; END
        END
        FETCH NEXT FROM cur INTO @Bang, @S, @I, @U, @D;
    END
    CLOSE cur; DEALLOCATE cur;

    PRINT N'Đã tạo/cập nhật Role [' + @TenRole + N'] thành công.';
END
GO

-- =============================================
-- BƯỚC 6: CẤP QUYỀN EXECUTE CHO app_admin
-- =============================================
GRANT EXECUTE ON SP_DanhSachUser TO [app_admin];
GRANT EXECUTE ON SP_DanhSachRole TO [app_admin];
GRANT EXECUTE ON SP_QuyenCuaUser TO [app_admin];
GRANT EXECUTE ON SP_TatCaQuyenCuaUser TO [app_admin];
GRANT EXECUTE ON SP_UserTrongRole TO [app_admin];
GRANT EXECUTE ON SP_RoleCuaUser TO [app_admin];
GRANT EXECUTE ON SP_UserChuaThuocRole TO [app_admin];
GRANT EXECUTE ON SP_GrantQuyenChoUser TO [app_admin];
GRANT EXECUTE ON SP_RevokeQuyenCuaUser TO [app_admin];
GRANT EXECUTE ON SP_GrantUserVaoRole TO [app_admin];
GRANT EXECUTE ON SP_RevokeUserKhoiRole TO [app_admin];
GRANT EXECUTE ON SP_TaoRoleMoi TO [app_admin];
GO

