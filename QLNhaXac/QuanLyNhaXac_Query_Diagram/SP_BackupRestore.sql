-- =============================================
-- HỆ THỐNG BACKUP & RESTORE - QuanLyNhaXac
-- Chỉ Admin (db_owner / app_admin) mới có thể thực thi
-- =============================================

USE master
GO

-- =============================================
-- BƯỚC 0: ĐẢM BẢO DATABASE DÙNG RECOVERY MODEL = FULL
-- (Bắt buộc để Differential và Transaction Log Backup hoạt động)
-- =============================================
ALTER DATABASE QuanLyNhaXac SET RECOVERY FULL;
GO

-- =============================================
-- BƯỚC 1: TẠO THƯ MỤC LƯU BACKUP (chạy 1 lần khi setup)
-- Ghi chú: SQL Server Agent hoặc xp_cmdshell phải được bật.
-- Nếu không dùng được xp_cmdshell, tạo thủ công thư mục này.
-- =============================================
/*
EXEC sp_configure 'show advanced options', 1; RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1; RECONFIGURE;

EXEC xp_cmdshell 'mkdir "C:\QuanLyNhaXac_Backup\Full" 2>nul';
EXEC xp_cmdshell 'mkdir "C:\QuanLyNhaXac_Backup\Diff" 2>nul';
EXEC xp_cmdshell 'mkdir "C:\QuanLyNhaXac_Backup\Log"  2>nul';
*/
GO

USE QuanLyNhaXac
GO

-- =============================================
-- BƯỚC 2: STORED PROCEDURE - FULL BACKUP
-- =============================================
-- Sao lưu toàn bộ database. Đây là điểm gốc cho mọi chuỗi backup.
-- Phải chạy Full Backup trước khi chạy Diff hoặc Log.
-- =============================================
IF OBJECT_ID('SP_FullBackup', 'P') IS NOT NULL
    DROP PROCEDURE SP_FullBackup;
GO

CREATE PROCEDURE SP_FullBackup
    @BackupFolder NVARCHAR(500) = N'C:\QuanLyNhaXac_Backup\Full'
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra quyền Admin
    IF (IS_ROLEMEMBER('db_owner') = 0 AND IS_ROLEMEMBER('QL_ADMIN') = 0)
    BEGIN
        RAISERROR(N'Từ chối truy cập: Chỉ Admin mới có thể thực hiện Backup.', 16, 1);
        RETURN;
    END

    DECLARE @FileName    NVARCHAR(600);
    DECLARE @TimeStamp   NVARCHAR(20);
    DECLARE @BackupName  NVARCHAR(200);
    DECLARE @Msg         NVARCHAR(500);

    -- Tạo tên file theo dạng: QuanLyNhaXac_Full_20250601_143022.bak
    SET @TimeStamp  = CONVERT(NVARCHAR(20), GETDATE(), 112)  -- YYYYMMDD
                    + '_'
                    + REPLACE(CONVERT(NVARCHAR(8), GETDATE(), 108), ':', '');  -- HHMMSS

    SET @FileName   = @BackupFolder + N'\QuanLyNhaXac_Full_' + @TimeStamp + N'.bak';
    SET @BackupName = N'FULL Backup - QuanLyNhaXac - ' + CONVERT(NVARCHAR(30), GETDATE(), 120);

    BEGIN TRY
        BACKUP DATABASE QuanLyNhaXac
        TO DISK = @FileName
        WITH
            NAME        = @BackupName,
            DESCRIPTION = N'Full backup tự động - Hệ thống Quản Lý Nhà Xác',
            COMPRESSION,          -- Nén file để tiết kiệm dung lượng
            CHECKSUM,             -- Ghi checksum để kiểm tra tính toàn vẹn khi restore
            STATS = 10;           -- Hiển thị tiến trình mỗi 10%

        SET @Msg = N'FULL BACKUP thành công: ' + @FileName;
        PRINT @Msg;

        -- Trả về thông tin backup vừa tạo
        SELECT
            N'FULL'                             AS LoaiBackup,
            @FileName                           AS DuongDan,
            GETDATE()                           AS ThoiGianBackup,
            SUSER_SNAME()                       AS NguoiThucHien,
            N'Thành công'                       AS TrangThai;
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(2048) = ERROR_MESSAGE();
        RAISERROR(N'LỖI FULL BACKUP: %s', 16, 1, @ErrMsg);

        SELECT
            N'FULL'         AS LoaiBackup,
            @FileName       AS DuongDan,
            GETDATE()       AS ThoiGianBackup,
            SUSER_SNAME()   AS NguoiThucHien,
            N'Thất bại: ' + @ErrMsg AS TrangThai;
    END CATCH
END
GO


-- =============================================
-- BƯỚC 3: STORED PROCEDURE - DIFFERENTIAL BACKUP
-- =============================================
-- Sao lưu các thay đổi kể từ lần Full Backup gần nhất.
-- Nhỏ hơn Full, phục hồi cần: Full + Diff gần nhất.
-- =============================================
IF OBJECT_ID('SP_DiffBackup', 'P') IS NOT NULL
    DROP PROCEDURE SP_DiffBackup;
GO

CREATE PROCEDURE SP_DiffBackup
    @BackupFolder NVARCHAR(500) = N'C:\QuanLyNhaXac_Backup\Diff'
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra quyền Admin
    IF (IS_ROLEMEMBER('db_owner') = 0 AND IS_ROLEMEMBER('QL_ADMIN') = 0)
    BEGIN
        RAISERROR(N'Từ chối truy cập: Chỉ Admin mới có thể thực hiện Backup.', 16, 1);
        RETURN;
    END

    -- Kiểm tra đã có Full Backup chưa (Differential bắt buộc cần Full trước)
    IF NOT EXISTS (
        SELECT 1 FROM msdb.dbo.backupset
        WHERE database_name = N'QuanLyNhaXac'
          AND type = 'D'  -- D = Database (Full)
    )
    BEGIN
        RAISERROR(N'Chưa có FULL BACKUP nào. Vui lòng chạy SP_FullBackup trước.', 16, 1);
        RETURN;
    END

    DECLARE @FileName    NVARCHAR(600);
    DECLARE @TimeStamp   NVARCHAR(20);
    DECLARE @BackupName  NVARCHAR(200);

    SET @TimeStamp  = CONVERT(NVARCHAR(20), GETDATE(), 112)
                    + '_'
                    + REPLACE(CONVERT(NVARCHAR(8), GETDATE(), 108), ':', '');

    SET @FileName   = @BackupFolder + N'\QuanLyNhaXac_Diff_' + @TimeStamp + N'.bak';
    SET @BackupName = N'DIFF Backup - QuanLyNhaXac - ' + CONVERT(NVARCHAR(30), GETDATE(), 120);

    BEGIN TRY
        BACKUP DATABASE QuanLyNhaXac
        TO DISK = @FileName
        WITH
            DIFFERENTIAL,         -- Chỉ sao lưu phần thay đổi so với Full
            NAME        = @BackupName,
            DESCRIPTION = N'Differential backup - Hệ thống Quản Lý Nhà Xác',
            COMPRESSION,
            CHECKSUM,
            STATS = 10;

        PRINT N'DIFFERENTIAL BACKUP thành công: ' + @FileName;

        SELECT
            N'DIFFERENTIAL'                     AS LoaiBackup,
            @FileName                           AS DuongDan,
            GETDATE()                           AS ThoiGianBackup,
            SUSER_SNAME()                       AS NguoiThucHien,
            N'Thành công'                       AS TrangThai;
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(2048) = ERROR_MESSAGE();
        RAISERROR(N'LỖI DIFFERENTIAL BACKUP: %s', 16, 1, @ErrMsg);

        SELECT
            N'DIFFERENTIAL'  AS LoaiBackup,
            @FileName        AS DuongDan,
            GETDATE()        AS ThoiGianBackup,
            SUSER_SNAME()    AS NguoiThucHien,
            N'Thất bại: ' + @ErrMsg AS TrangThai;
    END CATCH
END
GO


-- =============================================
-- BƯỚC 4: STORED PROCEDURE - TRANSACTION LOG BACKUP
-- =============================================
-- Sao lưu transaction log từ lần Log Backup trước đó.
-- Phục hồi cần: Full + (Diff gần nhất nếu có) + tất cả Log sau đó.
-- Quan trọng: Cắt ngắn log file, giúp log không bị đầy.
-- =============================================
IF OBJECT_ID('SP_LogBackup', 'P') IS NOT NULL
    DROP PROCEDURE SP_LogBackup;
GO

CREATE PROCEDURE SP_LogBackup
    @BackupFolder NVARCHAR(500) = N'C:\QuanLyNhaXac_Backup\Log'
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra quyền Admin
    IF (IS_ROLEMEMBER('db_owner') = 0 AND IS_ROLEMEMBER('QL_ADMIN') = 0)
    BEGIN
        RAISERROR(N'Từ chối truy cập: Chỉ Admin mới có thể thực hiện Backup.', 16, 1);
        RETURN;
    END

    -- Kiểm tra Recovery Model phải là FULL hoặc BULK_LOGGED
    DECLARE @RecoveryModel NVARCHAR(20);
    SELECT @RecoveryModel = recovery_model_desc
    FROM sys.databases
    WHERE name = N'QuanLyNhaXac';

    IF @RecoveryModel = N'SIMPLE'
    BEGIN
        RAISERROR(N'Database đang dùng SIMPLE recovery model. Transaction Log Backup không khả dụng. Hãy chuyển sang FULL recovery model.', 16, 1);
        RETURN;
    END

    -- Kiểm tra đã có Full Backup chưa
    IF NOT EXISTS (
        SELECT 1 FROM msdb.dbo.backupset
        WHERE database_name = N'QuanLyNhaXac'
          AND type = 'D'
    )
    BEGIN
        RAISERROR(N'Chưa có FULL BACKUP nào. Vui lòng chạy SP_FullBackup trước.', 16, 1);
        RETURN;
    END

    DECLARE @FileName    NVARCHAR(600);
    DECLARE @TimeStamp   NVARCHAR(20);
    DECLARE @BackupName  NVARCHAR(200);

    SET @TimeStamp  = CONVERT(NVARCHAR(20), GETDATE(), 112)
                    + '_'
                    + REPLACE(CONVERT(NVARCHAR(8), GETDATE(), 108), ':', '');

    SET @FileName   = @BackupFolder + N'\QuanLyNhaXac_Log_' + @TimeStamp + N'.trn';
    SET @BackupName = N'LOG Backup - QuanLyNhaXac - ' + CONVERT(NVARCHAR(30), GETDATE(), 120);

    BEGIN TRY
        BACKUP LOG QuanLyNhaXac
        TO DISK = @FileName
        WITH
            NAME        = @BackupName,
            DESCRIPTION = N'Transaction log backup - Hệ thống Quản Lý Nhà Xác',
            COMPRESSION,
            CHECKSUM,
            STATS = 10;

        PRINT N'LOG BACKUP thành công: ' + @FileName;

        SELECT
            N'TRANSACTION LOG'                  AS LoaiBackup,
            @FileName                           AS DuongDan,
            GETDATE()                           AS ThoiGianBackup,
            SUSER_SNAME()                       AS NguoiThucHien,
            N'Thành công'                       AS TrangThai;
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(2048) = ERROR_MESSAGE();
        RAISERROR(N'LỖI LOG BACKUP: %s', 16, 1, @ErrMsg);

        SELECT
            N'TRANSACTION LOG'  AS LoaiBackup,
            @FileName           AS DuongDan,
            GETDATE()           AS ThoiGianBackup,
            SUSER_SNAME()       AS NguoiThucHien,
            N'Thất bại: ' + @ErrMsg AS TrangThai;
    END CATCH
END
GO


-- =============================================
-- BƯỚC 5: STORED PROCEDURE - RESTORE DATABASE
-- =============================================
-- Phục hồi từ file .bak (Full hoặc Diff) hoặc .trn (Log).
-- Tự động phát hiện loại backup và thực hiện đúng kiểu Restore.
-- Cần ngắt kết nối user trước khi restore.
-- =============================================
-- Chuyển hướng sang master
USE master;
GO

IF OBJECT_ID('SP_RestoreDatabase', 'P') IS NOT NULL
    DROP PROCEDURE SP_RestoreDatabase;
GO

CREATE PROCEDURE SP_RestoreDatabase
    @BackupFile  NVARCHAR(600),    -- Đường dẫn file backup cần restore
    @WithRecovery BIT = 1          -- 1 = RECOVERY (xong, dùng được ngay), 0 = NORECOVERY (chờ apply thêm Log)
AS
BEGIN
    SET NOCOUNT ON;

    -- Chỉ sysadmin hoặc dbcreator mới có thể restore (cần quyền server-level)
    IF IS_SRVROLEMEMBER('sysadmin') = 0 AND IS_SRVROLEMEMBER('dbcreator') = 0
    BEGIN
        RAISERROR(N'Từ chối truy cập: Cần quyền sysadmin hoặc dbcreator để Restore database.', 16, 1);
        RETURN;
    END

    -- Kiểm tra file tồn tại
    DECLARE @FileExists INT = 0;
    EXEC master.dbo.xp_fileexist @BackupFile, @FileExists OUTPUT;
    IF @FileExists = 0
    BEGIN
        RAISERROR(N'Không tìm thấy file backup trên máy SQL Server: %s. Nếu SQL Server chạy trên máy khác, hãy dùng đường dẫn UNC/share hoặc đặt file backup trên chính máy SQL Server.', 16, 1, @BackupFile);
        RETURN;
    END

    DECLARE @BackupType  NVARCHAR(30);
    DECLARE @RecoveryOpt NVARCHAR(20) = CASE WHEN @WithRecovery = 1 THEN 'RECOVERY' ELSE 'NORECOVERY' END;
    DECLARE @Sql         NVARCHAR(MAX);

    -- Phát hiện loại backup từ extension
    IF @BackupFile LIKE N'%.trn'
        SET @BackupType = 'LOG';
    ELSE
        SET @BackupType = 'DATABASE';  -- sẽ xác định Full hay Diff từ header

    BEGIN TRY
        -- Bước 1: Ngắt tất cả kết nối đang có vào QuanLyNhaXac
        SET @Sql = N'
        ALTER DATABASE QuanLyNhaXac SET SINGLE_USER WITH ROLLBACK IMMEDIATE;';
        EXEC sp_executesql @Sql;

        -- Bước 2: Thực hiện Restore
        IF @BackupType = 'LOG'
        BEGIN
            SET @Sql = N'
            RESTORE LOG QuanLyNhaXac
            FROM DISK = N''' + @BackupFile + N'''
            WITH
                ' + @RecoveryOpt + N',
                CHECKSUM,
                STATS = 10;';
        END
        ELSE
        BEGIN
            SET @Sql = N'
            RESTORE DATABASE QuanLyNhaXac
            FROM DISK = N''' + @BackupFile + N'''
            WITH
                ' + @RecoveryOpt + N',
                REPLACE,
                CHECKSUM,
                STATS = 10;';
        END

        EXEC sp_executesql @Sql;

        -- Bước 3: Mở lại multi-user (chỉ nếu RECOVERY)
        IF @WithRecovery = 1
        BEGIN
            SET @Sql = N'ALTER DATABASE QuanLyNhaXac SET MULTI_USER;';
            EXEC sp_executesql @Sql;
        END

        PRINT N'RESTORE thành công từ: ' + @BackupFile;

        SELECT
            @BackupType         AS LoaiRestore,
            @BackupFile         AS FileNguon,
            GETDATE()           AS ThoiGianRestore,
            SUSER_SNAME()       AS NguoiThucHien,
            @RecoveryOpt        AS TuyChonRecovery,
            N'Thành công'       AS TrangThai;
    END TRY
    BEGIN CATCH
        -- Cố gắng mở lại multi-user dù restore thất bại
        BEGIN TRY
            EXEC sp_executesql N'ALTER DATABASE QuanLyNhaXac SET MULTI_USER;';
        END TRY
        BEGIN CATCH END CATCH

        DECLARE @ErrMsg NVARCHAR(2048) = ERROR_MESSAGE();
        RAISERROR(N'LỖI RESTORE: %s', 16, 1, @ErrMsg);

        SELECT
            @BackupType         AS LoaiRestore,
            @BackupFile         AS FileNguon,
            GETDATE()           AS ThoiGianRestore,
            SUSER_SNAME()       AS NguoiThucHien,
            @RecoveryOpt        AS TuyChonRecovery,
            N'Thất bại: ' + @ErrMsg AS TrangThai;
    END CATCH
END
GO


-- =============================================
-- BƯỚC 6: STORED PROCEDURE - XEM LỊCH SỬ BACKUP
-- =============================================
IF OBJECT_ID('SP_LichSuBackup', 'P') IS NOT NULL
    DROP PROCEDURE SP_LichSuBackup;
GO

CREATE PROCEDURE SP_LichSuBackup
    @SoLuong INT = 50   -- Số bản ghi gần nhất cần xem
AS
BEGIN
    SET NOCOUNT ON;

    IF (IS_ROLEMEMBER('db_owner') = 0 AND IS_ROLEMEMBER('QL_ADMIN') = 0)
    BEGIN
        RAISERROR(N'Từ chối truy cập: Chỉ Admin mới có thể xem lịch sử Backup.', 16, 1);
        RETURN;
    END

    SELECT TOP (@SoLuong)
        bs.backup_finish_date                           AS ThoiGianBackup,
        CASE bs.type
            WHEN 'D' THEN N'FULL'
            WHEN 'I' THEN N'DIFFERENTIAL'
            WHEN 'L' THEN N'TRANSACTION LOG'
            ELSE bs.type
        END                                             AS LoaiBackup,
        bmf.physical_device_name                        AS DuongDanFile,
        CAST(bs.backup_size / 1024.0 / 1024.0 AS DECIMAL(10,2))  AS KichThuoc_MB,
        bs.user_name                                    AS NguoiThucHien,
        CASE bs.has_backup_checksums
            WHEN 1 THEN N'Có'
            ELSE N'Không'
        END                                             AS CoChecksum,
        bs.database_name                                AS TenDatabase
    FROM msdb.dbo.backupset bs
    INNER JOIN msdb.dbo.backupmediafamily bmf
        ON bs.media_set_id = bmf.media_set_id
    WHERE bs.database_name = N'QuanLyNhaXac'
    ORDER BY bs.backup_finish_date DESC;
END
GO


-- =============================================
-- BƯỚC 7: CẤP QUYỀN EXECUTE CHO app_admin
-- (Chỉ app_admin mới GRANT được, users thường không thể gọi trực tiếp)
-- =============================================
GRANT EXECUTE ON SP_FullBackup     TO QL_ADMIN;
GRANT EXECUTE ON SP_DiffBackup     TO QL_ADMIN;
GRANT EXECUTE ON SP_LogBackup      TO QL_ADMIN;
GRANT EXECUTE ON SP_LichSuBackup   TO QL_ADMIN;
-- SP_RestoreDatabase cần quyền sysadmin ở server level, không grant được ở DB level
GO


-- =============================================
-- BƯỚC 8: VÍ DỤ KỊCH BẢN SỬ DỤNG THỰC TẾ
-- =============================================
/*
-- === Kịch bản 1: Backup hàng ngày ===
-- 8:00 SA: Full Backup (Chủ nhật)
EXEC SP_FullBackup @BackupFolder = N'C:\QuanLyNhaXac_Backup\Full';

-- 12:00 - 18:00 (Thứ 2 đến Thứ 7): Diff Backup 2 lần/ngày
EXEC SP_DiffBackup @BackupFolder = N'C:\QuanLyNhaXac_Backup\Diff';

-- Mỗi 1 giờ: Transaction Log Backup
EXEC SP_LogBackup @BackupFolder = N'C:\QuanLyNhaXac_Backup\Log';

-- === Kịch bản 2: Restore Full ===
EXEC SP_RestoreDatabase
    @BackupFile   = N'C:\QuanLyNhaXac_Backup\Full\QuanLyNhaXac_Full_20250601_080000.bak',
    @WithRecovery = 1;  -- Database sẵn sàng dùng ngay

-- === Kịch bản 3: Restore Full + Diff ===
-- Bước 1: Restore Full, giữ NORECOVERY để apply thêm
EXEC SP_RestoreDatabase
    @BackupFile   = N'C:\QuanLyNhaXac_Backup\Full\QuanLyNhaXac_Full_20250601_080000.bak',
    @WithRecovery = 0;

-- Bước 2: Restore Diff, RECOVERY để hoàn thành
EXEC SP_RestoreDatabase
    @BackupFile   = N'C:\QuanLyNhaXac_Backup\Diff\QuanLyNhaXac_Diff_20250601_180000.bak',
    @WithRecovery = 1;

-- === Kịch bản 4: Restore Full + Diff + nhiều Log ===
EXEC SP_RestoreDatabase
    @BackupFile   = N'C:\QuanLyNhaXac_Backup\Full\QuanLyNhaXac_Full_20250601_080000.bak',
    @WithRecovery = 0;

EXEC SP_RestoreDatabase
    @BackupFile   = N'C:\QuanLyNhaXac_Backup\Diff\QuanLyNhaXac_Diff_20250601_120000.bak',
    @WithRecovery = 0;

EXEC SP_RestoreDatabase
    @BackupFile   = N'C:\QuanLyNhaXac_Backup\Log\QuanLyNhaXac_Log_20250601_130000.trn',
    @WithRecovery = 0;

EXEC SP_RestoreDatabase
    @BackupFile   = N'C:\QuanLyNhaXac_Backup\Log\QuanLyNhaXac_Log_20250601_140000.trn',
    @WithRecovery = 1;  -- Bản log cuối: RECOVERY

-- === Xem lịch sử Backup ===
EXEC SP_LichSuBackup @SoLuong = 20;
*/
GO
