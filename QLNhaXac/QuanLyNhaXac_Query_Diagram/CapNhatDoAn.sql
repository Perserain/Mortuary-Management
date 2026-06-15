-- =============================================
-- FILE NÂNG CẤP DATABASE - QuanLyNhaXac
-- Tác giả: Bổ sung các chức năng còn thiếu
-- Chạy file này SAU KHI đã chạy QL_NhaXac.sql gốc
-- =============================================

USE QuanLyNhaXac
GO

SET DATEFORMAT DMY
GO

PRINT N'====================================================';
PRINT N'BẮT ĐẦU NÂNG CẤP DATABASE QuanLyNhaXac';
PRINT N'====================================================';

-- =============================================
-- PHẦN 1: BỔ SUNG CẤU TRÚC BẢNG
-- =============================================
PRINT N'[1/7] Bổ sung cấu trúc bảng...';

-- ── 1.1 Thêm cột TRANGTHAI vào THIHAI ──────────────────────────────
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('THIHAI') AND name = 'TRANGTHAI'
)
BEGIN
    ALTER TABLE THIHAI
    ADD TRANGTHAI NVARCHAR(30) NOT NULL
        CONSTRAINT DF_THIHAI_TRANGTHAI DEFAULT N'Đang bảo quản';

    ALTER TABLE THIHAI
    ADD CONSTRAINT CK_THIHAI_TRANGTHAI
    CHECK (TRANGTHAI IN (
        N'Đang bảo quản',
        N'Đang khám nghiệm',
        N'Chờ bàn giao',
        N'Đã bàn giao',
        N'Đã mai táng'
    ));

    PRINT N'  >> Đã thêm cột TRANGTHAI vào THIHAI';
END
ELSE
    PRINT N'  >> TRANGTHAI đã tồn tại, bỏ qua.';
GO

-- ── 1.2 Mở rộng HOSOKHAMBENH ────────────────────────────────────────
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('HOSOKHAMBENH') AND name = 'MACAUTU'
)
BEGIN
    ALTER TABLE HOSOKHAMBENH
    ADD MACAUTU        NVARCHAR(10),                -- Mã ICD-10
        LOAICAUTU      NVARCHAR(50),                -- Tai nạn / Bệnh lý / Chưa rõ / Khác
        SOBIENBAN      NVARCHAR(30),                -- Số biên bản pháp y
        NGAYBIENBAN    DATE,                        -- Ngày ký biên bản
        COQUANYEUCAU   NVARCHAR(150),               -- Cơ quan yêu cầu (Công an, Viện kiểm sát…)
        GHICHUPHAY     NVARCHAR(500);               -- Ghi chú mở rộng pháp y

    ALTER TABLE HOSOKHAMBENH
    ADD CONSTRAINT CK_HS_LOAICAUTU
    CHECK (LOAICAUTU IN (
        N'Tai nạn giao thông', N'Tai nạn lao động',
        N'Bệnh lý', N'Tự tử', N'Án mạng', N'Chưa rõ', N'Khác'
    ) OR LOAICAUTU IS NULL);

    PRINT N'  >> Đã mở rộng HOSOKHAMBENH (ICD-10, biên bản, cơ quan yêu cầu)';
END
ELSE
    PRINT N'  >> HOSOKHAMBENH đã được mở rộng, bỏ qua.';
GO

-- ── 1.3 Tạo bảng THAN_NHAN ─────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'THAN_NHAN')
BEGIN
    CREATE TABLE THAN_NHAN
    (
        MATN        VARCHAR(15)     NOT NULL,
        MATH        VARCHAR(15)     NOT NULL,           -- FK → THIHAI
        HOTEN_TN    NVARCHAR(100)   NOT NULL,
        QUANHE      NVARCHAR(50),                       -- Vợ/Chồng, Con, Cha/Mẹ…
        DIENTHOAI   VARCHAR(15),
        DIACHI      NVARCHAR(200),
        LALIENDHE   BIT NOT NULL                        -- 1 = người liên hệ chính
                    CONSTRAINT DF_TN_LALIENDHE DEFAULT 0,
        GHICHU      NVARCHAR(200),
        CONSTRAINT PK_TN    PRIMARY KEY (MATN),
        CONSTRAINT FK_TN_TH FOREIGN KEY (MATH) REFERENCES THIHAI(MATH)
    );

    PRINT N'  >> Đã tạo bảng THAN_NHAN';
END
ELSE
    PRINT N'  >> THAN_NHAN đã tồn tại, bỏ qua.';
GO

-- ── 1.4 Tạo bảng HOADON ────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'HOADON')
BEGIN
    CREATE TABLE HOADON
    (
        MAHD            VARCHAR(15)     NOT NULL,
        MATH            VARCHAR(15)     NOT NULL,           -- FK → THIHAI
        NGAYLAP         DATE            NOT NULL,
        TONGTIEN        MONEY           NOT NULL,
        TRANGTHAITT     NVARCHAR(20)    NOT NULL
                        CONSTRAINT DF_HD_TRANGTHAITT DEFAULT N'Chưa thanh toán',
        PHUONGTHUCTT    NVARCHAR(30),                       -- Tiền mặt / Chuyển khoản
        NGAYTHANHTOAN   DATE,
        NGUOILAP        NVARCHAR(100),                      -- Tên nhân viên lập hóa đơn
        GHICHU          NVARCHAR(200),
        CONSTRAINT PK_HD       PRIMARY KEY (MAHD),
        CONSTRAINT FK_HD_TH    FOREIGN KEY (MATH) REFERENCES THIHAI(MATH),
        CONSTRAINT CK_HD_TT    CHECK (TRANGTHAITT IN (
            N'Chưa thanh toán', N'Đã thanh toán', N'Miễn phí', N'Nợ'
        )),
        CONSTRAINT CK_HD_PT    CHECK (PHUONGTHUCTT IN (
            N'Tiền mặt', N'Chuyển khoản', N'Thẻ ngân hàng', N'Khác'
        ) OR PHUONGTHUCTT IS NULL),
        CONSTRAINT CK_HD_TIEN  CHECK (TONGTIEN >= 0)
    );

    PRINT N'  >> Đã tạo bảng HOADON';
END
ELSE
    PRINT N'  >> HOADON đã tồn tại, bỏ qua.';
GO

-- ── 1.5 Tạo bảng AUDIT_LOG (nhật ký thao tác) ─────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'AUDIT_LOG')
BEGIN
    CREATE TABLE AUDIT_LOG
    (
        MALOG       BIGINT          NOT NULL IDENTITY(1,1),
        THOIGIAN    DATETIME        NOT NULL DEFAULT GETDATE(),
        TENUSER     NVARCHAR(128)   NOT NULL DEFAULT SUSER_SNAME(),
        TENTABLE    NVARCHAR(50)    NOT NULL,
        HANHdong    NVARCHAR(10)    NOT NULL,           -- INSERT / UPDATE / DELETE
        MABANGHI    NVARCHAR(50),                       -- Khóa chính bản ghi bị tác động
        NOIDUNG     NVARCHAR(1000),                     -- Mô tả ngắn thay đổi
        CONSTRAINT PK_AUDIT PRIMARY KEY (MALOG),
        CONSTRAINT CK_AUDIT_HD CHECK (HANHDOG IN ('INSERT','UPDATE','DELETE') OR HANHDOG IS NULL)
    );

    -- Index để truy vấn nhanh theo thời gian / bảng
    CREATE INDEX IX_AUDIT_THOIGIAN ON AUDIT_LOG(THOIGIAN DESC);
    CREATE INDEX IX_AUDIT_TABLE    ON AUDIT_LOG(TENTABLE, THOIGIAN DESC);

    PRINT N'  >> Đã tạo bảng AUDIT_LOG';
END
ELSE
    PRINT N'  >> AUDIT_LOG đã tồn tại, bỏ qua.';
GO

-- ── 1.6 Tạo bảng CANH_BAO (hàng đợi cảnh báo) ─────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CANH_BAO')
BEGIN
    CREATE TABLE CANH_BAO
    (
        MACB        INT             NOT NULL IDENTITY(1,1),
        THOIGIAN    DATETIME        NOT NULL DEFAULT GETDATE(),
        LOAICB      NVARCHAR(50)    NOT NULL,           -- QuaHan / NhietDo / ChuaKham
        MATH        VARCHAR(15),
        MANGAN      VARCHAR(15),
        NOIDUNG     NVARCHAR(300)   NOT NULL,
        DAOC        BIT             NOT NULL DEFAULT 0, -- 0=chưa đọc, 1=đã đọc
        CONSTRAINT PK_CB PRIMARY KEY (MACB)
    );

    PRINT N'  >> Đã tạo bảng CANH_BAO';
END
ELSE
    PRINT N'  >> CANH_BAO đã tồn tại, bỏ qua.';
GO


-- =============================================
-- PHẦN 2: TRIGGER BỔ SUNG
-- =============================================
PRINT N'[2/7] Tạo trigger bổ sung...';

-- ── 2.1 Audit log thi hài ──────────────────────────────────────────
IF OBJECT_ID('TRG_Audit_ThiHai', 'TR') IS NOT NULL
    DROP TRIGGER TRG_Audit_ThiHai;
GO

CREATE TRIGGER TRG_Audit_ThiHai
ON THIHAI
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @action NVARCHAR(10);

    IF EXISTS(SELECT 1 FROM inserted) AND EXISTS(SELECT 1 FROM deleted)
        SET @action = 'UPDATE';
    ELSE IF EXISTS(SELECT 1 FROM inserted)
        SET @action = 'INSERT';
    ELSE
        SET @action = 'DELETE';

    IF @action IN ('INSERT','UPDATE')
        INSERT INTO AUDIT_LOG (TENTABLE, HANHDOG, MABANGHI, NOIDUNG)
        SELECT 'THIHAI', @action, i.MATH,
               N'[' + @action + N'] Thi hài: ' + ISNULL(i.HOTEN_TH, N'?')
               + N' | Trạng thái: ' + ISNULL(i.TRANGTHAI, N'?')
        FROM inserted i;
    ELSE
        INSERT INTO AUDIT_LOG (TENTABLE, HANHDOG, MABANGHI, NOIDUNG)
        SELECT 'THIHAI', @action, d.MATH,
               N'[DELETE] Đã xóa thi hài: ' + ISNULL(d.HOTEN_TH, N'?')
        FROM deleted d;
END
GO
PRINT N'  >> TRG_Audit_ThiHai OK';

-- ── 2.2 Audit log hồ sơ khám nghiệm ──────────────────────────────
IF OBJECT_ID('TRG_Audit_HoSo', 'TR') IS NOT NULL
    DROP TRIGGER TRG_Audit_HoSo;
GO

CREATE TRIGGER TRG_Audit_HoSo
ON HOSOKHAMBENH
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @action NVARCHAR(10) =
        CASE WHEN EXISTS(SELECT 1 FROM deleted) THEN 'UPDATE' ELSE 'INSERT' END;

    INSERT INTO AUDIT_LOG (TENTABLE, HANHDOG, MABANGHI, NOIDUNG)
    SELECT 'HOSOKHAMBENH', @action, i.MAHS,
           N'[' + @action + N'] Hồ sơ ' + i.MAHS
           + N' | Thi hài: ' + i.MATH
           + N' | Bác sĩ: ' + i.MABS
           + N' | Kết luận: ' + ISNULL(i.KETLUAN, N'?')
    FROM inserted i;
END
GO
PRINT N'  >> TRG_Audit_HoSo OK';

-- ── 2.3 Audit log ngăn kéo ────────────────────────────────────────
IF OBJECT_ID('TRG_Audit_NganKeo', 'TR') IS NOT NULL
    DROP TRIGGER TRG_Audit_NganKeo;
GO

CREATE TRIGGER TRG_Audit_NganKeo
ON NGANKEO
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @action NVARCHAR(10) =
        CASE WHEN EXISTS(SELECT 1 FROM deleted) THEN 'UPDATE' ELSE 'INSERT' END;

    INSERT INTO AUDIT_LOG (TENTABLE, HANHDOG, MABANGHI, NOIDUNG)
    SELECT 'NGANKEO', @action, i.MANGAN,
           N'[' + @action + N'] Ngăn ' + i.MANGAN
           + N' | Nhiệt độ: ' + CAST(i.NHIETDO AS NVARCHAR(10)) + N'°C'
           + N' | Thi hài: ' + ISNULL(i.MATH, N'Trống')
    FROM inserted i;
END
GO
PRINT N'  >> TRG_Audit_NganKeo OK';

-- ── 2.4 Cập nhật trạng thái thi hài tự động khi vào ngăn kéo ──────
-- Khi thi hài được xếp vào ngăn → TRANGTHAI = 'Đang bảo quản'
-- Khi lấy ra khỏi ngăn (MATH về NULL) → TRANGTHAI = 'Chờ bàn giao'
IF OBJECT_ID('TRG_CapNhatTrangThaiThiHai', 'TR') IS NOT NULL
    DROP TRIGGER TRG_CapNhatTrangThaiThiHai;
GO

CREATE TRIGGER TRG_CapNhatTrangThaiThiHai
ON NGANKEO
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(MATH)
    BEGIN
        -- Thi hài vừa được xếp vào ngăn → Đang bảo quản
        UPDATE THIHAI
        SET TRANGTHAI = N'Đang bảo quản'
        FROM THIHAI th
        INNER JOIN inserted i ON th.MATH = i.MATH
        INNER JOIN deleted  d ON d.MANGAN = i.MANGAN
        WHERE i.MATH IS NOT NULL AND d.MATH IS NULL;

        -- Thi hài vừa được lấy ra khỏi ngăn → Chờ bàn giao
        UPDATE THIHAI
        SET TRANGTHAI = N'Chờ bàn giao'
        FROM THIHAI th
        INNER JOIN deleted d ON th.MATH = d.MATH
        INNER JOIN inserted i ON i.MANGAN = d.MANGAN
        WHERE i.MATH IS NULL AND d.MATH IS NOT NULL;
    END
END
GO
PRINT N'  >> TRG_CapNhatTrangThaiThiHai OK';

-- ── 2.5 Cảnh báo thi hài sắp quá hạn (còn 3 ngày) ────────────────
IF OBJECT_ID('TRG_CanhBaoSapQuaHan', 'TR') IS NOT NULL
    DROP TRIGGER TRG_CanhBaoSapQuaHan;
GO

CREATE TRIGGER TRG_CanhBaoSapQuaHan
ON THIHAI
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- Thi hài chưa có trong ngăn kéo và sắp quá 15 ngày (còn 0-3 ngày)
    INSERT INTO CANH_BAO (LOAICB, MATH, NOIDUNG)
    SELECT
        N'QuaHan',
        i.MATH,
        N'Thi hài ' + ISNULL(i.HOTEN_TH, i.MATH)
        + N' sắp quá hạn lưu trữ! Còn '
        + CAST(15 - DATEDIFF(DAY, i.NGAYMAT, GETDATE()) AS NVARCHAR(5))
        + N' ngày.'
    FROM inserted i
    WHERE
        DATEDIFF(DAY, i.NGAYMAT, GETDATE()) BETWEEN 12 AND 15
        AND i.MATH NOT IN (
            SELECT MATH FROM NGANKEO WHERE MATH IS NOT NULL
        )
        AND NOT EXISTS (
            SELECT 1 FROM CANH_BAO cb
            WHERE cb.MATH = i.MATH
              AND cb.LOAICB = N'QuaHan'
              AND cb.DAOC = 0
        );
END
GO
PRINT N'  >> TRG_CanhBaoSapQuaHan OK';

-- ── 2.6 Cảnh báo chưa có bác sĩ khám sau 3 ngày nhập viện ────────
IF OBJECT_ID('TRG_CanhBaoChuaKham', 'TR') IS NOT NULL
    DROP TRIGGER TRG_CanhBaoChuaKham;
GO

CREATE TRIGGER TRG_CanhBaoChuaKham
ON THIHAI
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    -- Khi thêm thi hài mới, ghi nhận cảnh báo chờ bác sĩ phân công
    INSERT INTO CANH_BAO (LOAICB, MATH, NOIDUNG)
    SELECT
        N'ChuaKham',
        i.MATH,
        N'Thi hài ' + ISNULL(i.HOTEN_TH, i.MATH)
        + N' vừa nhập - chưa có bác sĩ được phân công khám nghiệm.'
    FROM inserted i;
END
GO
PRINT N'  >> TRG_CanhBaoChuaKham OK';

-- ── 2.7 Tự động tạo hóa đơn khi thi hài bàn giao ─────────────────
IF OBJECT_ID('TRG_TaoHoaDonKhiBanGiao', 'TR') IS NOT NULL
    DROP TRIGGER TRG_TaoHoaDonKhiBanGiao;
GO

CREATE TRIGGER TRG_TaoHoaDonKhiBanGiao
ON THIHAI
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(TRANGTHAI)
    BEGIN
        -- Khi chuyển sang "Đã bàn giao" và chưa có hóa đơn → tự tạo
        INSERT INTO HOADON (MAHD, MATH, NGAYLAP, TONGTIEN, TRANGTHAITT, NGUOILAP)
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
        INNER JOIN deleted d ON i.MATH = d.MATH
        WHERE i.TRANGTHAI = N'Đã bàn giao'
          AND d.TRANGTHAI <> N'Đã bàn giao'
          AND NOT EXISTS (
                SELECT 1 FROM HOADON h WHERE h.MATH = i.MATH
          );
    END
END
GO
PRINT N'  >> TRG_TaoHoaDonKhiBanGiao OK';


-- =============================================
-- PHẦN 3: VIEW BỔ SUNG
-- =============================================
PRINT N'[3/7] Tạo view bổ sung...';

-- ── 3.1 Dashboard tổng quan ───────────────────────────────────────
IF OBJECT_ID('VIEW_Dashboard', 'V') IS NOT NULL
    DROP VIEW VIEW_Dashboard;
GO

CREATE VIEW VIEW_Dashboard AS
SELECT
    (SELECT COUNT(*) FROM THIHAI) AS TongThiHai,
    (SELECT COUNT(*) FROM THIHAI WHERE TRANGTHAI = N'Đang bảo quản') AS DangBaoQuan,
    (SELECT COUNT(*) FROM THIHAI WHERE TRANGTHAI = N'Chờ bàn giao')  AS ChoThanhLy,
    (SELECT COUNT(*) FROM NGANKEO WHERE MATH IS NULL) AS NganKeoTrong,
    (SELECT COUNT(*) FROM NGANKEO WHERE MATH IS NOT NULL) AS NganKeoDang,
    (SELECT COUNT(*) FROM NGANKEO) AS TongNganKeo,
    (SELECT ISNULL(SUM(TONGTIEN),0) FROM HOADON
     WHERE TRANGTHAITT = N'Đã thanh toán'
       AND NGAYTHANHTOAN = CAST(GETDATE() AS DATE)) AS DoanhThuHomNay,
    (SELECT ISNULL(SUM(TONGTIEN),0) FROM HOADON
     WHERE TRANGTHAITT = N'Đã thanh toán'
       AND MONTH(NGAYTHANHTOAN) = MONTH(GETDATE())
       AND YEAR(NGAYTHANHTOAN)  = YEAR(GETDATE()))  AS DoanhThuThang,
    (SELECT COUNT(*) FROM CANH_BAO WHERE DAOC = 0)  AS SoCanhBaoChuaDoc,
    (SELECT COUNT(*) FROM HOADON WHERE TRANGTHAITT = N'Chưa thanh toán') AS HoaDonChuaTT;
GO
PRINT N'  >> VIEW_Dashboard OK';

-- ── 3.2 Thi hài sắp/đã quá hạn (chưa vào ngăn) ──────────────────
IF OBJECT_ID('VIEW_ThiHaiQuaHan', 'V') IS NOT NULL
    DROP VIEW VIEW_ThiHaiQuaHan;
GO

CREATE VIEW VIEW_ThiHaiQuaHan AS
SELECT
    th.MATH,
    th.HOTEN_TH,
    th.NGAYMAT,
    th.TRANGTHAI,
    DATEDIFF(DAY, th.NGAYMAT, GETDATE()) AS SoNgayKe,
    15 - DATEDIFF(DAY, th.NGAYMAT, GETDATE()) AS ConLaiNgay,
    CASE
        WHEN DATEDIFF(DAY, th.NGAYMAT, GETDATE()) > 15 THEN N'Quá hạn'
        WHEN DATEDIFF(DAY, th.NGAYMAT, GETDATE()) BETWEEN 12 AND 15 THEN N'Sắp quá hạn'
        ELSE N'Bình thường'
    END AS TinhTrang
FROM THIHAI th
WHERE th.MATH NOT IN (
    SELECT MATH FROM NGANKEO WHERE MATH IS NOT NULL
)
AND DATEDIFF(DAY, th.NGAYMAT, GETDATE()) >= 12;
GO
PRINT N'  >> VIEW_ThiHaiQuaHan OK';

-- ── 3.3 Hóa đơn chi tiết ─────────────────────────────────────────
IF OBJECT_ID('VIEW_HoaDonChiTiet', 'V') IS NOT NULL
    DROP VIEW VIEW_HoaDonChiTiet;
GO

CREATE VIEW VIEW_HoaDonChiTiet AS
SELECT
    hd.MAHD,
    th.MATH,
    th.HOTEN_TH,
    tn.HOTEN_TN AS NGUOI_NHAN,
    tn.DIENTHOAI AS SDT_NGUOI_NHAN,
    hd.NGAYLAP,
    hd.TONGTIEN,
    hd.TRANGTHAITT,
    hd.PHUONGTHUCTT,
    hd.NGAYTHANHTOAN,
    hd.NGUOILAP,
    hd.GHICHU
FROM HOADON hd
INNER JOIN THIHAI th ON hd.MATH = th.MATH
LEFT JOIN THAN_NHAN tn ON tn.MATH = th.MATH AND tn.LALIENDHE = 1;
GO
PRINT N'  >> VIEW_HoaDonChiTiet OK';

-- ── 3.4 Thân nhân theo thi hài ────────────────────────────────────
IF OBJECT_ID('VIEW_ThanNhanThiHai', 'V') IS NOT NULL
    DROP VIEW VIEW_ThanNhanThiHai;
GO

CREATE VIEW VIEW_ThanNhanThiHai AS
SELECT
    tn.MATN, tn.QUANHE, tn.HOTEN_TN, tn.DIENTHOAI, tn.DIACHI, tn.LALIENDHE, tn.GHICHU,
    th.MATH, th.HOTEN_TH, th.TRANGTHAI
FROM THAN_NHAN tn
INNER JOIN THIHAI th ON tn.MATH = th.MATH;
GO
PRINT N'  >> VIEW_ThanNhanThiHai OK';

-- ── 3.5 Cảnh báo chưa đọc ─────────────────────────────────────────
IF OBJECT_ID('VIEW_CanhBaoChuaDoc', 'V') IS NOT NULL
    DROP VIEW VIEW_CanhBaoChuaDoc;
GO

CREATE VIEW VIEW_CanhBaoChuaDoc AS
SELECT
    cb.MACB, cb.THOIGIAN, cb.LOAICB, cb.MATH, cb.MANGAN, cb.NOIDUNG,
    th.HOTEN_TH
FROM CANH_BAO cb
LEFT JOIN THIHAI th ON cb.MATH = th.MATH
WHERE cb.DAOC = 0
-- Mới nhất lên đầu (ORDER BY không dùng trong VIEW, dùng khi gọi)
;
GO
PRINT N'  >> VIEW_CanhBaoChuaDoc OK';

-- ── 3.6 Báo cáo thống kê thi hài theo tháng ──────────────────────
IF OBJECT_ID('VIEW_ThongKe_TheoThang', 'V') IS NOT NULL
    DROP VIEW VIEW_ThongKe_TheoThang;
GO

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
GROUP BY YEAR(NGAYMAT), MONTH(NGAYMAT);
GO
PRINT N'  >> VIEW_ThongKe_TheoThang OK';

-- ── 3.7 Báo cáo doanh thu dịch vụ theo tháng ─────────────────────
IF OBJECT_ID('VIEW_ThongKe_DoanhThu', 'V') IS NOT NULL
    DROP VIEW VIEW_ThongKe_DoanhThu;
GO

CREATE VIEW VIEW_ThongKe_DoanhThu AS
SELECT
    YEAR(hd.NGAYTHANHTOAN)  AS Nam,
    MONTH(hd.NGAYTHANHTOAN) AS Thang,
    COUNT(hd.MAHD)           AS SoHoaDon,
    SUM(hd.TONGTIEN)         AS TongDoanhThu,
    SUM(CASE WHEN hd.TRANGTHAITT = N'Đã thanh toán' THEN hd.TONGTIEN ELSE 0 END) AS DaThanhToan,
    SUM(CASE WHEN hd.TRANGTHAITT = N'Chưa thanh toán' THEN hd.TONGTIEN ELSE 0 END) AS ChuaThanhToan
FROM HOADON hd
WHERE hd.NGAYTHANHTOAN IS NOT NULL
GROUP BY YEAR(hd.NGAYTHANHTOAN), MONTH(hd.NGAYTHANHTOAN);
GO
PRINT N'  >> VIEW_ThongKe_DoanhThu OK';


-- =============================================
-- PHẦN 4: STORED PROCEDURE BỔ SUNG
-- =============================================
PRINT N'[4/7] Tạo stored procedure bổ sung...';

-- ──────────────────────────────────────────────────────────────────
-- 4.A THÂN NHÂN
-- ──────────────────────────────────────────────────────────────────
IF OBJECT_ID('SP_DSThanNhan','P') IS NOT NULL DROP PROCEDURE SP_DSThanNhan;
GO
CREATE PROCEDURE SP_DSThanNhan @MATH VARCHAR(15) AS
BEGIN
    SELECT * FROM VIEW_ThanNhanThiHai WHERE MATH = @MATH ORDER BY LALIENDHE DESC;
END
GO

IF OBJECT_ID('SP_ThemThanNhan','P') IS NOT NULL DROP PROCEDURE SP_ThemThanNhan;
GO
CREATE PROCEDURE SP_ThemThanNhan
    @MATN       VARCHAR(15),
    @MATH       VARCHAR(15),
    @HOTEN_TN   NVARCHAR(100),
    @QUANHE     NVARCHAR(50),
    @DIENTHOAI  VARCHAR(15),
    @DIACHI     NVARCHAR(200),
    @LALIENDHE  BIT,
    @GHICHU     NVARCHAR(200)
AS
BEGIN
    -- Nếu đánh dấu là người liên hệ chính thì bỏ cờ cũ
    IF @LALIENDHE = 1
        UPDATE THAN_NHAN SET LALIENDHE = 0 WHERE MATH = @MATH;

    INSERT INTO THAN_NHAN(MATN,MATH,HOTEN_TN,QUANHE,DIENTHOAI,DIACHI,LALIENDHE,GHICHU)
    VALUES (@MATN,@MATH,@HOTEN_TN,@QUANHE,@DIENTHOAI,@DIACHI,@LALIENDHE,@GHICHU);
END
GO

IF OBJECT_ID('SP_SuaThanNhan','P') IS NOT NULL DROP PROCEDURE SP_SuaThanNhan;
GO
CREATE PROCEDURE SP_SuaThanNhan
    @MATN       VARCHAR(15),
    @HOTEN_TN   NVARCHAR(100),
    @QUANHE     NVARCHAR(50),
    @DIENTHOAI  VARCHAR(15),
    @DIACHI     NVARCHAR(200),
    @LALIENDHE  BIT,
    @GHICHU     NVARCHAR(200)
AS
BEGIN
    DECLARE @MATH VARCHAR(15);
    SELECT @MATH = MATH FROM THAN_NHAN WHERE MATN = @MATN;

    IF @LALIENDHE = 1
        UPDATE THAN_NHAN SET LALIENDHE = 0 WHERE MATH = @MATH AND MATN <> @MATN;

    UPDATE THAN_NHAN
    SET HOTEN_TN  = @HOTEN_TN,
        QUANHE    = @QUANHE,
        DIENTHOAI = @DIENTHOAI,
        DIACHI    = @DIACHI,
        LALIENDHE = @LALIENDHE,
        GHICHU    = @GHICHU
    WHERE MATN = @MATN;
END
GO

IF OBJECT_ID('SP_XoaThanNhan','P') IS NOT NULL DROP PROCEDURE SP_XoaThanNhan;
GO
CREATE PROCEDURE SP_XoaThanNhan @MATN VARCHAR(15) AS
BEGIN
    DELETE FROM THAN_NHAN WHERE MATN = @MATN;
END
GO
PRINT N'  >> SP Thân Nhân OK';

-- ──────────────────────────────────────────────────────────────────
-- 4.B HÓA ĐƠN
-- ──────────────────────────────────────────────────────────────────
IF OBJECT_ID('SP_DSHoaDon','P') IS NOT NULL DROP PROCEDURE SP_DSHoaDon;
GO
CREATE PROCEDURE SP_DSHoaDon AS
BEGIN
    SELECT * FROM VIEW_HoaDonChiTiet ORDER BY NGAYLAP DESC;
END
GO

IF OBJECT_ID('SP_ThemHoaDon','P') IS NOT NULL DROP PROCEDURE SP_ThemHoaDon;
GO
CREATE PROCEDURE SP_ThemHoaDon
    @MAHD           VARCHAR(15),
    @MATH           VARCHAR(15),
    @NGAYLAP        DATE,
    @PHUONGTHUCTT   NVARCHAR(30),
    @GHICHU         NVARCHAR(200)
AS
BEGIN
    DECLARE @TongTien MONEY;
    EXEC sp_TinhTongTienDichVu @MATH, @TongTien OUTPUT;

    INSERT INTO HOADON(MAHD,MATH,NGAYLAP,TONGTIEN,TRANGTHAITT,PHUONGTHUCTT,NGUOILAP,GHICHU)
    VALUES (@MAHD, @MATH, @NGAYLAP, @TongTien, N'Chưa thanh toán', @PHUONGTHUCTT, SUSER_SNAME(), @GHICHU);
END
GO

IF OBJECT_ID('SP_ThanhToanHoaDon','P') IS NOT NULL DROP PROCEDURE SP_ThanhToanHoaDon;
GO
CREATE PROCEDURE SP_ThanhToanHoaDon
    @MAHD           VARCHAR(15),
    @PHUONGTHUCTT   NVARCHAR(30)
AS
BEGIN
    UPDATE HOADON
    SET TRANGTHAITT   = N'Đã thanh toán',
        PHUONGTHUCTT  = @PHUONGTHUCTT,
        NGAYTHANHTOAN = CAST(GETDATE() AS DATE)
    WHERE MAHD = @MAHD;
END
GO

IF OBJECT_ID('SP_HoaDonTheoThiHai','P') IS NOT NULL DROP PROCEDURE SP_HoaDonTheoThiHai;
GO
CREATE PROCEDURE SP_HoaDonTheoThiHai @MATH VARCHAR(15) AS
BEGIN
    SELECT * FROM VIEW_HoaDonChiTiet WHERE MATH = @MATH;
END
GO
PRINT N'  >> SP Hóa Đơn OK';

-- ──────────────────────────────────────────────────────────────────
-- 4.C TRẠNG THÁI THI HÀI
-- ──────────────────────────────────────────────────────────────────
IF OBJECT_ID('SP_CapNhatTrangThaiThiHai','P') IS NOT NULL
    DROP PROCEDURE SP_CapNhatTrangThaiThiHai;
GO
CREATE PROCEDURE SP_CapNhatTrangThaiThiHai
    @MATH       VARCHAR(15),
    @TRANGTHAI  NVARCHAR(30)
AS
BEGIN
    IF @TRANGTHAI NOT IN (
        N'Đang bảo quản', N'Đang khám nghiệm',
        N'Chờ bàn giao', N'Đã bàn giao', N'Đã mai táng'
    )
    BEGIN
        RAISERROR(N'Trạng thái không hợp lệ.', 16, 1);
        RETURN;
    END

    UPDATE THIHAI SET TRANGTHAI = @TRANGTHAI WHERE MATH = @MATH;
END
GO
PRINT N'  >> SP Trạng Thái OK';

-- ──────────────────────────────────────────────────────────────────
-- 4.D CẢNH BÁO
-- ──────────────────────────────────────────────────────────────────
IF OBJECT_ID('SP_DSCanhBao','P') IS NOT NULL DROP PROCEDURE SP_DSCanhBao;
GO
CREATE PROCEDURE SP_DSCanhBao AS
BEGIN
    SELECT * FROM VIEW_CanhBaoChuaDoc ORDER BY THOIGIAN DESC;
END
GO

IF OBJECT_ID('SP_DocCanhBao','P') IS NOT NULL DROP PROCEDURE SP_DocCanhBao;
GO
CREATE PROCEDURE SP_DocCanhBao @MACB INT AS
BEGIN
    UPDATE CANH_BAO SET DAOC = 1 WHERE MACB = @MACB;
END
GO

IF OBJECT_ID('SP_DocHetCanhBao','P') IS NOT NULL DROP PROCEDURE SP_DocHetCanhBao;
GO
CREATE PROCEDURE SP_DocHetCanhBao AS
BEGIN
    UPDATE CANH_BAO SET DAOC = 1 WHERE DAOC = 0;
END
GO

-- SP quét thủ công phát sinh cảnh báo (dùng khi mở app / bấm refresh)
IF OBJECT_ID('SP_QuetCanhBao','P') IS NOT NULL DROP PROCEDURE SP_QuetCanhBao;
GO
CREATE PROCEDURE SP_QuetCanhBao AS
BEGIN
    SET NOCOUNT ON;

    -- Cảnh báo sắp quá hạn (12-15 ngày, chưa vào ngăn)
    INSERT INTO CANH_BAO (LOAICB, MATH, NOIDUNG)
    SELECT
        N'QuaHan',
        th.MATH,
        N'Thi hài ' + ISNULL(th.HOTEN_TH, th.MATH)
        + N' sắp quá hạn! Còn '
        + CAST(15 - DATEDIFF(DAY, th.NGAYMAT, GETDATE()) AS NVARCHAR(5))
        + N' ngày.'
    FROM THIHAI th
    WHERE
        DATEDIFF(DAY, th.NGAYMAT, GETDATE()) BETWEEN 12 AND 15
        AND th.MATH NOT IN (SELECT MATH FROM NGANKEO WHERE MATH IS NOT NULL)
        AND NOT EXISTS (
            SELECT 1 FROM CANH_BAO cb
            WHERE cb.MATH = th.MATH AND cb.LOAICB = N'QuaHan' AND cb.DAOC = 0
        );

    -- Cảnh báo chưa được khám nghiệm sau 3 ngày
    INSERT INTO CANH_BAO (LOAICB, MATH, NOIDUNG)
    SELECT
        N'ChuaKham',
        th.MATH,
        N'Thi hài ' + ISNULL(th.HOTEN_TH, th.MATH)
        + N' chưa được khám nghiệm sau '
        + CAST(DATEDIFF(DAY, th.NGAYMAT, GETDATE()) AS NVARCHAR(5))
        + N' ngày kể từ ngày mất.'
    FROM THIHAI th
    WHERE
        DATEDIFF(DAY, th.NGAYMAT, GETDATE()) > 3
        AND th.MATH NOT IN (SELECT MATH FROM HOSOKHAMBENH)
        AND NOT EXISTS (
            SELECT 1 FROM CANH_BAO cb
            WHERE cb.MATH = th.MATH AND cb.LOAICB = N'ChuaKham' AND cb.DAOC = 0
        );

    SELECT COUNT(*) AS SoCanhBaoMoi FROM CANH_BAO WHERE DAOC = 0;
END
GO
PRINT N'  >> SP Cảnh Báo OK';

-- ──────────────────────────────────────────────────────────────────
-- 4.E HỒ SƠ KHÁM NGHIỆM - SỬA lại SP để nhận thêm trường pháp y
-- ──────────────────────────────────────────────────────────────────
IF OBJECT_ID('SP_ThemHoSoKhamBenh_V2','P') IS NOT NULL
    DROP PROCEDURE SP_ThemHoSoKhamBenh_V2;
GO
CREATE PROCEDURE SP_ThemHoSoKhamBenh_V2
    @MAHS           VARCHAR(15),
    @THOIGIANKHAM   DATE,
    @KETLUAN        NVARCHAR(50),
    @MATH           VARCHAR(15),
    @MABS           VARCHAR(15),
    @MACAUTU        NVARCHAR(10)    = NULL,
    @LOAICAUTU      NVARCHAR(50)    = NULL,
    @SOBIENBAN      NVARCHAR(30)    = NULL,
    @NGAYBIENBAN    DATE            = NULL,
    @COQUANYEUCAU   NVARCHAR(150)   = NULL,
    @GHICHUPHAY     NVARCHAR(500)   = NULL
AS
BEGIN
    INSERT INTO HOSOKHAMBENH
    (MAHS, THOIGIANKHAM, KETLUAN, MATH, MABS,
     MACAUTU, LOAICAUTU, SOBIENBAN, NGAYBIENBAN, COQUANYEUCAU, GHICHUPHAY)
    VALUES
    (@MAHS, @THOIGIANKHAM, @KETLUAN, @MATH, @MABS,
     @MACAUTU, @LOAICAUTU, @SOBIENBAN, @NGAYBIENBAN, @COQUANYEUCAU, @GHICHUPHAY);

    -- Cập nhật trạng thái thi hài → Đang khám nghiệm
    UPDATE THIHAI SET TRANGTHAI = N'Đang khám nghiệm' WHERE MATH = @MATH;

    -- Đánh dấu đã xử lý cảnh báo ChuaKham
    UPDATE CANH_BAO SET DAOC = 1
    WHERE MATH = @MATH AND LOAICB = N'ChuaKham' AND DAOC = 0;
END
GO

IF OBJECT_ID('SP_SuaHoSoKhamBenh_V2','P') IS NOT NULL
    DROP PROCEDURE SP_SuaHoSoKhamBenh_V2;
GO
CREATE PROCEDURE SP_SuaHoSoKhamBenh_V2
    @MAHS           VARCHAR(15),
    @THOIGIANKHAM   DATE,
    @KETLUAN        NVARCHAR(50),
    @MATH           VARCHAR(15),
    @MABS           VARCHAR(15),
    @MACAUTU        NVARCHAR(10)    = NULL,
    @LOAICAUTU      NVARCHAR(50)    = NULL,
    @SOBIENBAN      NVARCHAR(30)    = NULL,
    @NGAYBIENBAN    DATE            = NULL,
    @COQUANYEUCAU   NVARCHAR(150)   = NULL,
    @GHICHUPHAY     NVARCHAR(500)   = NULL
AS
BEGIN
    UPDATE HOSOKHAMBENH
    SET THOIGIANKHAM = @THOIGIANKHAM,
        KETLUAN      = @KETLUAN,
        MATH         = @MATH,
        MABS         = @MABS,
        MACAUTU      = @MACAUTU,
        LOAICAUTU    = @LOAICAUTU,
        SOBIENBAN    = @SOBIENBAN,
        NGAYBIENBAN  = @NGAYBIENBAN,
        COQUANYEUCAU = @COQUANYEUCAU,
        GHICHUPHAY   = @GHICHUPHAY
    WHERE MAHS = @MAHS;
END
GO
PRINT N'  >> SP Hồ Sơ V2 OK';

-- ──────────────────────────────────────────────────────────────────
-- 4.F BÁO CÁO THỐNG KÊ
-- ──────────────────────────────────────────────────────────────────
IF OBJECT_ID('SP_BaoCao_ThiHaiTheoThang','P') IS NOT NULL
    DROP PROCEDURE SP_BaoCao_ThiHaiTheoThang;
GO
CREATE PROCEDURE SP_BaoCao_ThiHaiTheoThang
    @Nam INT = NULL     -- NULL = năm hiện tại
AS
BEGIN
    SET @Nam = ISNULL(@Nam, YEAR(GETDATE()));
    SELECT * FROM VIEW_ThongKe_TheoThang WHERE Nam = @Nam ORDER BY Thang;
END
GO

IF OBJECT_ID('SP_BaoCao_DoanhThuTheoThang','P') IS NOT NULL
    DROP PROCEDURE SP_BaoCao_DoanhThuTheoThang;
GO
CREATE PROCEDURE SP_BaoCao_DoanhThuTheoThang
    @Nam INT = NULL
AS
BEGIN
    SET @Nam = ISNULL(@Nam, YEAR(GETDATE()));
    SELECT * FROM VIEW_ThongKe_DoanhThu WHERE Nam = @Nam ORDER BY Thang;
END
GO

IF OBJECT_ID('SP_Dashboard','P') IS NOT NULL DROP PROCEDURE SP_Dashboard;
GO
CREATE PROCEDURE SP_Dashboard AS
BEGIN
    SELECT * FROM VIEW_Dashboard;
END
GO
PRINT N'  >> SP Báo Cáo OK';

-- ──────────────────────────────────────────────────────────────────
-- 4.G AUDIT LOG
-- ──────────────────────────────────────────────────────────────────
IF OBJECT_ID('SP_XemAuditLog','P') IS NOT NULL DROP PROCEDURE SP_XemAuditLog;
GO
CREATE PROCEDURE SP_XemAuditLog
    @TENTABLE   NVARCHAR(50) = NULL,
    @TuNgay     DATE         = NULL,
    @DenNgay    DATE         = NULL,
    @SoLuong    INT          = 200
AS
BEGIN
    SELECT TOP (@SoLuong)
        MALOG, THOIGIAN, TENUSER, TENTABLE, HANHDOG, MABANGHI, NOIDUNG
    FROM AUDIT_LOG
    WHERE
        (@TENTABLE IS NULL OR TENTABLE = @TENTABLE)
        AND (@TuNgay IS NULL OR CAST(THOIGIAN AS DATE) >= @TuNgay)
        AND (@DenNgay IS NULL OR CAST(THOIGIAN AS DATE) <= @DenNgay)
    ORDER BY THOIGIAN DESC;
END
GO
PRINT N'  >> SP Audit Log OK';

-- ──────────────────────────────────────────────────────────────────
-- 4.H TÌM KIẾM NÂNG CAO
-- ──────────────────────────────────────────────────────────────────
IF OBJECT_ID('SP_TimKiemThiHai','P') IS NOT NULL DROP PROCEDURE SP_TimKiemThiHai;
GO
CREATE PROCEDURE SP_TimKiemThiHai
    @TuKhoa     NVARCHAR(100) = NULL,   -- Tìm theo tên
    @TRANGTHAI  NVARCHAR(30)  = NULL,
    @GIOITINH   NVARCHAR(10)  = NULL,
    @TuNgayMat  DATE          = NULL,
    @DenNgayMat DATE          = NULL
AS
BEGIN
    SELECT *
    FROM VIEW_DanhSachThiHai
    WHERE
        (@TuKhoa   IS NULL OR HOTEN_TH LIKE N'%' + @TuKhoa + N'%')
        AND (@TRANGTHAI IS NULL OR EXISTS (
            SELECT 1 FROM THIHAI t2
            WHERE t2.MATH = MATH AND t2.TRANGTHAI = @TRANGTHAI
        ))
        AND (@GIOITINH  IS NULL OR GIOITINH = @GIOITINH)
        AND (@TuNgayMat IS NULL OR NGAYMAT >= @TuNgayMat)
        AND (@DenNgayMat IS NULL OR NGAYMAT <= @DenNgayMat)
    ORDER BY NGAYMAT DESC;
END
GO
PRINT N'  >> SP Tìm Kiếm Nâng Cao OK';


-- =============================================
-- PHẦN 5: HÀM BỔ SUNG
-- =============================================
PRINT N'[5/7] Tạo hàm bổ sung...';

-- ── 5.1 Tạo mã tự động cho từng bảng ─────────────────────────────
IF OBJECT_ID('FN_TaoMaTuDong','FN') IS NOT NULL
    DROP FUNCTION FN_TaoMaTuDong;
GO
CREATE FUNCTION FN_TaoMaTuDong(@Prefix VARCHAR(5), @TenBang NVARCHAR(50), @CotMa NVARCHAR(50))
RETURNS VARCHAR(15)
AS
BEGIN
    DECLARE @Sql    NVARCHAR(500);
    DECLARE @MaxNum INT = 0;

    -- Trả về mã kế tiếp dạng PREFIX + 3 chữ số (TH001, BS001, HD001…)
    -- Logic tính MaxNum được xử lý trong application vì EXEC không dùng được trong UDF
    -- Hàm này trả về prefix + timestamp millisecond để đảm bảo unique khi gọi nhanh
    RETURN @Prefix + RIGHT('000' + CAST(ABS(CHECKSUM(NEWID())) % 900 + 100 AS VARCHAR(5)), 3);
END
GO

-- ── 5.2 Hàm tính số ngày còn lại trước khi quá hạn ───────────────
IF OBJECT_ID('FN_NgayConLai','FN') IS NOT NULL
    DROP FUNCTION FN_NgayConLai;
GO
CREATE FUNCTION FN_NgayConLai(@MATH VARCHAR(15))
RETURNS INT
AS
BEGIN
    DECLARE @NgayMat DATE;
    DECLARE @TrongNgan BIT = 0;

    SELECT @NgayMat = NGAYMAT FROM THIHAI WHERE MATH = @MATH;
    IF EXISTS (SELECT 1 FROM NGANKEO WHERE MATH = @MATH)
        SET @TrongNgan = 1;

    IF @TrongNgan = 1 RETURN 9999;  -- Trong ngăn lạnh: không tính quá hạn
    RETURN 15 - DATEDIFF(DAY, @NgayMat, GETDATE());
END
GO

-- ── 5.3 Hàm lấy tên người liên hệ chính của thi hài ──────────────
IF OBJECT_ID('FN_NguoiLienHe','FN') IS NOT NULL
    DROP FUNCTION FN_NguoiLienHe;
GO
CREATE FUNCTION FN_NguoiLienHe(@MATH VARCHAR(15))
RETURNS NVARCHAR(150)
AS
BEGIN
    DECLARE @KetQua NVARCHAR(150);
    SELECT TOP 1
        @KetQua = HOTEN_TN + N' (' + ISNULL(QUANHE,N'?') + N') - ' + ISNULL(DIENTHOAI,N'Chưa có SĐT')
    FROM THAN_NHAN
    WHERE MATH = @MATH AND LALIENDHE = 1;

    RETURN ISNULL(@KetQua, N'Chưa có thân nhân');
END
GO
PRINT N'  >> Hàm bổ sung OK';


-- =============================================
-- PHẦN 6: PHÂN QUYỀN CHO CÁC ĐỐI TƯỢNG MỚI
-- =============================================
PRINT N'[6/7] Cấp quyền...';

-- QL_ADMIN: toàn quyền mọi thứ mới
GRANT SELECT, INSERT, UPDATE, DELETE ON THAN_NHAN TO [QL_ADMIN] WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON HOADON    TO [QL_ADMIN] WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON CANH_BAO  TO [QL_ADMIN] WITH GRANT OPTION;
GRANT SELECT ON AUDIT_LOG TO [QL_ADMIN];

GRANT EXECUTE ON SP_DSThanNhan               TO [QL_ADMIN];
GRANT EXECUTE ON SP_ThemThanNhan             TO [QL_ADMIN];
GRANT EXECUTE ON SP_SuaThanNhan              TO [QL_ADMIN];
GRANT EXECUTE ON SP_XoaThanNhan              TO [QL_ADMIN];
GRANT EXECUTE ON SP_DSHoaDon                 TO [QL_ADMIN];
GRANT EXECUTE ON SP_ThemHoaDon               TO [QL_ADMIN];
GRANT EXECUTE ON SP_ThanhToanHoaDon          TO [QL_ADMIN];
GRANT EXECUTE ON SP_HoaDonTheoThiHai         TO [QL_ADMIN];
GRANT EXECUTE ON SP_CapNhatTrangThaiThiHai   TO [QL_ADMIN];
GRANT EXECUTE ON SP_DSCanhBao                TO [QL_ADMIN];
GRANT EXECUTE ON SP_DocCanhBao               TO [QL_ADMIN];
GRANT EXECUTE ON SP_DocHetCanhBao            TO [QL_ADMIN];
GRANT EXECUTE ON SP_QuetCanhBao              TO [QL_ADMIN];
GRANT EXECUTE ON SP_ThemHoSoKhamBenh_V2      TO [QL_ADMIN];
GRANT EXECUTE ON SP_SuaHoSoKhamBenh_V2       TO [QL_ADMIN];
GRANT EXECUTE ON SP_BaoCao_ThiHaiTheoThang   TO [QL_ADMIN];
GRANT EXECUTE ON SP_BaoCao_DoanhThuTheoThang TO [QL_ADMIN];
GRANT EXECUTE ON SP_Dashboard                TO [QL_ADMIN];
GRANT EXECUTE ON SP_XemAuditLog              TO [QL_ADMIN];
GRANT EXECUTE ON SP_TimKiemThiHai            TO [QL_ADMIN];
GO

-- QL_NHANVIEN: xem thân nhân, hóa đơn, cảnh báo; thêm/sửa thân nhân
GRANT SELECT, INSERT, UPDATE ON THAN_NHAN TO [QL_NHANVIEN];
GRANT SELECT, INSERT, UPDATE ON HOADON    TO [QL_NHANVIEN];
GRANT SELECT, INSERT, UPDATE ON CANH_BAO  TO [QL_NHANVIEN];

GRANT EXECUTE ON SP_DSThanNhan             TO [QL_NHANVIEN];
GRANT EXECUTE ON SP_ThemThanNhan           TO [QL_NHANVIEN];
GRANT EXECUTE ON SP_SuaThanNhan            TO [QL_NHANVIEN];
GRANT EXECUTE ON SP_DSHoaDon               TO [QL_NHANVIEN];
GRANT EXECUTE ON SP_ThemHoaDon             TO [QL_NHANVIEN];
GRANT EXECUTE ON SP_ThanhToanHoaDon        TO [QL_NHANVIEN];
GRANT EXECUTE ON SP_HoaDonTheoThiHai       TO [QL_NHANVIEN];
GRANT EXECUTE ON SP_DSCanhBao              TO [QL_NHANVIEN];
GRANT EXECUTE ON SP_DocCanhBao             TO [QL_NHANVIEN];
GRANT EXECUTE ON SP_DocHetCanhBao          TO [QL_NHANVIEN];
GRANT EXECUTE ON SP_QuetCanhBao            TO [QL_NHANVIEN];
GRANT EXECUTE ON SP_Dashboard              TO [QL_NHANVIEN];
GRANT EXECUTE ON SP_TimKiemThiHai          TO [QL_NHANVIEN];
GRANT EXECUTE ON SP_CapNhatTrangThaiThiHai TO [QL_NHANVIEN];
GO

-- QL_BACSI: xem hóa đơn, thân nhân (chỉ đọc), cảnh báo, thêm hồ sơ V2
GRANT SELECT ON THAN_NHAN TO [QL_BACSI];
GRANT SELECT ON HOADON    TO [QL_BACSI];
GRANT SELECT ON CANH_BAO  TO [QL_BACSI];

GRANT EXECUTE ON SP_DSThanNhan           TO [QL_BACSI];
GRANT EXECUTE ON SP_HoaDonTheoThiHai     TO [QL_BACSI];
GRANT EXECUTE ON SP_DSCanhBao            TO [QL_BACSI];
GRANT EXECUTE ON SP_DocCanhBao           TO [QL_BACSI];
GRANT EXECUTE ON SP_ThemHoSoKhamBenh_V2  TO [QL_BACSI];
GRANT EXECUTE ON SP_SuaHoSoKhamBenh_V2   TO [QL_BACSI];
GRANT EXECUTE ON SP_Dashboard            TO [QL_BACSI];
GRANT EXECUTE ON SP_TimKiemThiHai        TO [QL_BACSI];
GO
PRINT N'  >> Phân quyền OK';


-- =============================================
-- PHẦN 7: DỮ LIỆU MẪU CHO CÁC BẢNG MỚI
-- =============================================
PRINT N'[7/7] Chèn dữ liệu mẫu...';

-- Thân nhân mẫu
IF NOT EXISTS (SELECT 1 FROM THAN_NHAN WHERE MATN = 'TN001')
    INSERT INTO THAN_NHAN VALUES
    ('TN001','TH001',N'Nguyễn Thị Hà',  N'Vợ',    '0901234567', N'12 Lê Lợi, Q.1, TP.HCM', 1, NULL),
    ('TN002','TH001',N'Nguyễn Văn Bình',N'Con trai','0912345678', N'12 Lê Lợi, Q.1, TP.HCM', 0, NULL),
    ('TN003','TH002',N'Trần Văn Quang', N'Chồng',  '0923456789', N'45 Đinh Tiên Hoàng, Q.Bình Thạnh', 1, NULL);

-- Hóa đơn mẫu (thi hài TH001 đã thanh toán)
IF NOT EXISTS (SELECT 1 FROM HOADON WHERE MAHD = 'HD001')
    INSERT INTO HOADON(MAHD,MATH,NGAYLAP,TONGTIEN,TRANGTHAITT,PHUONGTHUCTT,NGAYTHANHTOAN,NGUOILAP)
    VALUES
    ('HD001','TH001','21-01-2026', 2500000, N'Đã thanh toán', N'Tiền mặt', '22-01-2026', N'NhaXacAdmin'),
    ('HD002','TH002','22-01-2026',  150000, N'Chưa thanh toán', NULL, NULL, N'NhaXacAdmin');

-- Cập nhật trạng thái thi hài mẫu
UPDATE THIHAI SET TRANGTHAI = N'Đã bàn giao' WHERE MATH = 'TH001';
UPDATE THIHAI SET TRANGTHAI = N'Đang bảo quản' WHERE MATH IN ('TH002','TH003');

PRINT N'  >> Dữ liệu mẫu OK';

GO

-- =============================================
-- TỔNG KẾT
-- =============================================
PRINT N'';
PRINT N'====================================================';
PRINT N'NÂNG CẤP HOÀN TẤT! Tóm tắt những gì đã thêm:';
PRINT N'  Bảng mới   : THAN_NHAN, HOADON, AUDIT_LOG, CANH_BAO';
PRINT N'  Cột mới    : THIHAI.TRANGTHAI, HOSOKHAMBENH (ICD-10, biên bản…)';
PRINT N'  View mới   : Dashboard, QuaHan, HoaDonChiTiet, ThongKe x2, CanhBao';
PRINT N'  Trigger mới: Audit x3, TrangThai, CanhBao x2, TaoHoaDon';
PRINT N'  SP mới     : Thân nhân x4, Hóa đơn x4, Cảnh báo x4,';
PRINT N'               Báo cáo x3, HoSo_V2 x2, TimKiem, AuditLog';
PRINT N'  Hàm mới    : FN_NgayConLai, FN_NguoiLienHe';
PRINT N'====================================================';
GO
