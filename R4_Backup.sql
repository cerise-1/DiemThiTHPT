--Backup Device
USE DiemThi
Go
Sp_addumpdevice 'disk' , 'SQL' , 'D:\SQL\SQLBackups\DiemThiFull.bak'

EXEC sp_helpdevice

--Backup DB
--Full
BACKUP DATABASE DiemThi
TO DISK = 'D:\SQL\DiemThiFull.bak'
WITH INIT,		-- Khởi tạo tập tin backup.
	NOFORMAT,	-- Không định dạng tập tin backup.
	NOUNLOAD,	-- Không tải tập tin backup khỏi bộ nhớ.
	NAME = 'DiemThi_FullBackup',
	STATS = 10;	-- Hiển thị thông tin thống kê sau mỗi 10% quá trình backup.

--Differental
BACKUP DATABASE DiemThi
TO DISK = 'D:\SQL\DiemThi_Diff.bak'
WITH DIFFERENTIAL,
MEDIANAME = 'DiemThiDiffBackup',
NAME = 'DiemThi_DiffBackup';

RESTORE HEADERONLY FROM DISK = 'D:\SQL\DiemThiFull.bak';
RESTORE HEADERONLY FROM DISK = 'D:\SQL\DiemThi_Diff.bak';

--Transactional log backup
BACKUP LOG DiemThi --thực hiện một bản sao lưu nhật ký giao dịch.
   To DISK='D:\SQL\DiemThi_Log.trn'
   WITH
   MEDIANAME = 'DiemThiTransBackup',
    NAME = 'DiemThi_TransBackup';
GO

--Quản lý Backup
-- Tạo một job mới để quản lý việc backup Full
EXEC msdb.dbo.sp_add_job
    @job_name = N'DiemThi_Full',			--Đặt tên cho job.
    @description = N'Backup DiemThi Full',	--Mô tả ngắn gọn về job
    @enabled = 1;							--Chỉ định xem job có được bật để chạy tự động hay không (1: bật, 0: tắt)

-- Tạo một step trong job để thực hiện backup full hàng ngày
EXEC msdb.dbo.sp_add_jobstep 
    @job_name = N'DiemThi_Full', 
    @step_name = N'BackupFull',		--Đặt tên cho bước này là "BackupFull"
    @subsystem = N'TSQL',		--Chỉ định rằng bước này sẽ thực hiện một lệnh T-SQL
    @command = N'BACKUP DATABASE DiemThi TO DISK = ''D:\SQL\BackupDiemThi_Full'' + CONVERT(varchar(10), GETDATE(), 112) + ''.bak'' WITH FULL', 
    @retry_attempts = 2,	--Chỉ định số lần thử lại nếu bước này gặp lỗi
    @retry_interval = 5;	--Chỉ định khoảng thời gian (giây) giữa các lần thử lại

-- Lên lịch chạy job hàng ngày lúc 2 giờ sáng
EXEC msdb.dbo.sp_add_schedule 
    @schedule_name = N'ScheduleFullBackup', 
    @freq_type = 4, -- Daily
    @active_start_date = 20241101, 
    @active_end_date = 99991231, 
    @freq_interval = 1,
	@active_start_time = 020000; -- 2:00 AM;

EXEC msdb.dbo.sp_attach_schedule @job_name = N'DiemThi_Full', @schedule_name = N'ScheduleFullBackup';

-- Tạo job backup differential hàng ngày
EXEC msdb.dbo.sp_add_job
    @job_name = N'DiemThi_Differential',
    @description = N'Backup DiemThi Differential',
    @enabled = 1;

EXEC msdb.dbo.sp_add_jobstep 
    @job_name = N'DiemThi_Differential', 
    @step_name = N'BackupDifferential', 
    @subsystem = N'TSQL', 
    @command = N'BACKUP DATABASE DiemThi TO DISK = ''D:\SQL\BackupDiemThi_Differential'' + CONVERT(varchar(10), GETDATE(), 112) + ''.bak'' WITH DIFFERENTIAL',
    @retry_attempts = 2,
    @retry_interval = 5;

-- Lên lịch chạy job hàng ngày lúc 3 giờ sáng
EXEC msdb.dbo.sp_add_schedule 
    @schedule_name = N'ScheduleDifferentialBackup',
    @freq_type = 4, -- Daily
    @active_start_date = 20241101,
    @active_end_date = 99991231,
    @freq_interval = 1,
	@active_start_time = 030000; -- 3:00 AM

EXEC msdb.dbo.sp_attach_schedule @job_name = N'DiemThi_Differential', @schedule_name = 'ScheduleDifferentialBackup';

-- Tạo job backup transaction log hàng giờ
EXEC msdb.dbo.sp_add_job
    @job_name = N'DiemThi_TransactionLog',
    @description = N'Backup DiemThi Transaction Log',
    @enabled = 1;

EXEC msdb.dbo.sp_add_jobstep 
    @job_name = N'DiemThi_TransactionLog', 
    @step_name = N'BackupTransactionLog', 
    @subsystem = N'TSQL', 
    @command = N'BACKUP LOG DiemThi TO DISK = ''D:\SQL\BackupDiemThi_Log'' + CONVERT(varchar(10), GETDATE(), 112) + ''.trn''',
    @retry_attempts = 2,
    @retry_interval = 5;

-- Lên lịch chạy job hàng giờ
EXEC msdb.dbo.sp_add_schedule 
    @schedule_name = N'ScheduleTransactionLogBackup',
    @freq_type = 4, -- Daily
	@freq_interval = 1,
	@freq_subday_type = 4,
    @freq_subday_interval = 4, -- Hourly
    @active_start_date = 20241101,
    @active_end_date = 99991231;

EXEC msdb.dbo.sp_attach_schedule @job_name = N'DiemThi_TransactionLog', @schedule_name = 'ScheduleTransactionLogBackup';

SELECT * FROM msdb.dbo.sysjobs;	--Liệt kê tất cả các job

EXEC msdb.dbo.sp_delete_job @job_name = N'Monitor_DiemThi_Backup';

--Giám Sát Backup cho DiemThi
--Đoạn code này sẽ quét qua các Job backup có tên bắt đầu bằng DiemThi_, 
--kiểm tra trạng thái chạy gần nhất của chúng. 
--Nếu Job backup thất bại, nó sẽ thông báo lỗi với các chi tiết về lỗi.
EXEC msdb.dbo.sp_add_job 
    @job_name=N'Monitor_DiemThi_Backup', 
    @enabled=1, 
    @description=N'Giam sat trang thai backup cua DiemThi';

EXEC msdb.dbo.sp_add_jobstep 
    @job_name=N'Monitor_DiemThi_Backup', 
    @step_name=N'Check_Backup_Status', 
    @subsystem=N'TSQL', 
    @command=N'
        DECLARE @JobName sysname;
        DECLARE @LastRunDate datetime;	--Biến kiểu datetime để lưu trữ ngày chạy gần nhất của Job backup.
        DECLARE @RunStatus int;			--Biến kiểu int để lưu trữ trạng thái chạy (thành công/thất bại) của Job backup.
        DECLARE @Duration int;			--Biến kiểu int để lưu trữ thời gian thực hiện backup (tính bằng giây).

        DECLARE backup_jobs CURSOR FOR	--cursor này sẽ lặp qua các Job backup có tên bắt đầu bằng DiemThi_Backup_%.
        SELECT name
        FROM msdb.dbo.sysjobs
        WHERE name LIKE ''DiemThi_%''

        OPEN backup_jobs;

        FETCH NEXT FROM backup_jobs INTO @JobName;

        WHILE @@FETCH_STATUS = 0	--Sử dụng vòng lặp WHILE để lặp qua các Job backup được tìm thấy bởi cursor.	
        BEGIN
            SELECT @LastRunDate = max(run_date),	--Lấy ngày chạy gần nhất
                   @RunStatus = max(run_status),	--Lấy trạng thái chạy gần nhất 
                   @Duration = MAX(DATEDIFF(SECOND, start_run_date, end_run_date)),		--Tính thời gian thực hiện backup
            FROM msdb.dbo.sysjobhistory			--Truy vấn bảng sysjobhistory để lấy thông tin về lần chạy gần nhất của Job backup hiện tại).
            WHERE job_id = (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = @JobName);

            IF @RunStatus <> 1	--Nếu @RunStatus khác 1 (thành công), gửi email thông báo lỗi
            BEGIN
                EXEC msdb.dbo.sp_send_dbmail
                    @recipients = ''cerise1501@gmail.com'',
                    @subject = ''Backup Job Failed - '' + @JobName,
                    @body = ''Backup job '' + @JobName + '' failed on '' + CONVERT(varchar, @LastRunDate, 120) + ''. 
                              Details: Duration: '' + CAST(@Duration AS VARCHAR(10)) + '' seconds. Backup size: '' + @BackupSize;	--Thông tin chi tiết về lỗi
            END;

            FETCH NEXT FROM backup_jobs INTO @JobName;
        END;

        CLOSE backup_jobs;		--Sau khi lặp qua tất cả các Job backup, đóng cursor
        DEALLOCATE backup_jobs;	--Giải phóng bộ nhớ được sử dụng bởi cursor
    ';