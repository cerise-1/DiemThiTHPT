use DiemThi

-- Xây dựng cơ sở dữ liệu
Create Table ThiSinh (
MaSBD char (8) not null Primary key, 
KhuVuc Nvarchar (50) not null);

Create Table MonThi (
MaMon Varchar (15) not null Primary key, 
TenMon Varchar (50) not null);

Create Table KhoiThi(
MaKhoi Varchar (15) not null Primary key, 
TenKhoi Varchar (50) not null);

Create Table DiemThi (
MaSBD char (8) not null, 
MaMon Varchar (15) not null,
Diem float,
Primary Key (MaSBD, MaMon),
FOREIGN KEY (MaSBD) REFERENCES ThiSinh(MaSBD),
FOREIGN KEY (MaMon) REFERENCES MonThi(MaMon));

Create Table KhoiMonThi(
MaKhoi Varchar (15) not null, 
MaMon Varchar (15) not null,
Primary Key (MaKhoi, MaMon),
FOREIGN KEY (MaKhoi) REFERENCES KhoiThi(MaKhoi),
FOREIGN KEY (MaMon) REFERENCES MonThi(MaMon));


-- Tiền xử lý dữ liệu
-- 1. Kiểm tra các SBD có điểm bị thiếu
CREATE OR ALTER FUNCTION CheckNull(@SBD INT)
RETURNS BIT
AS
BEGIN
    DECLARE @Result BIT;

    SELECT @Result = CASE 
        WHEN	Toan 	IS NULL 
			AND Van 	IS NULL 
			AND NgoaiNgu IS NULL 
			AND VatLy 	IS NULL 
			AND HoaHoc 	IS NULL 
			AND SinhHoc	IS NULL 
			AND LichSu 	IS NULL 
			AND DiaLy 	IS NULL 
			AND GDCD 	IS NULL 
        THEN 1 
        ELSE 0 
    END
    FROM 	DiemThiTHPT
    WHERE 	SBD = @SBD;
    RETURN 	@Result;
END;

SELECT 	SBD
FROM 	DiemThiTHPT
WHERE 	dbo.CheckNull(SBD) = 1
ORDER BY SBD ASC;


-- 2. Tạo bảng và xóa điểm bị thiếu
CREATE OR ALTER PROCEDURE UpdateAndRemoveNullScores
AS
BEGIN
    -- Kiểm tra nếu bảng DiemThiThieu chưa tồn tại thì tạo bảng
    IF OBJECT_ID('DiemThiThieu', 'U') IS NULL
    BEGIN
		SELECT * INTO DiemThiThieu
		FROM DiemThiTHPT
		WHERE dbo.CheckNull(SBD) = 1;
 	END
	ELSE
 	BEGIN
		INSERT INTO DiemThiThieu
		SELECT * 
		FROM DiemThiTHPT
		WHERE dbo.CheckNull(SBD) = 1
		AND SBD NOT IN (SELECT SBD FROM DiemThiThieu);
	END

    -- Xóa các bản ghi từ bảng DiemThiTHPT
    DELETE FROM DiemThiTHPT
    WHERE 
        dbo.CheckNull(SBD) = 1;
END;
EXEC UpdateAndRemoveNullScores;

SELECT *
FROM DiemThiThieu
ORDER BY SBD ASC;



-- INSERT DỮ LIỆU VÀO CƠ SỞ DỮ LIỆU
CREATE or ALTER PROCEDURE InsertDataFromDiemThiTHPT
AS
BEGIN
    -- Khai báo biến
    DECLARE @MaSBD CHAR(8);
    DECLARE @DiemToan FLOAT;
    DECLARE @DiemVan FLOAT;
    DECLARE @DiemNgoaiNgu FLOAT;
    DECLARE @DiemVatLy FLOAT;
    DECLARE @DiemHoaHoc FLOAT;
    DECLARE @DiemSinhHoc FLOAT;
    DECLARE @DTB_TuNhien FLOAT;
    DECLARE @DiemLichSu FLOAT;
    DECLARE @DiemDiaLy FLOAT;
    DECLARE @DiemGDCD FLOAT;
    DECLARE @DTB_XaHoi FLOAT;
    DECLARE @KhuVuc NVARCHAR(50);
    
    -- Con trỏ để duyệt qua các dòng dữ liệu
    DECLARE DataCursor CURSOR FOR
    SELECT SBD, Toan, Van, NgoaiNgu, VatLy, HoaHoc, SinhHoc, DTB_TuNhien, LichSu, DiaLy, GDCD, DTB_XaHoi
    FROM DiemThiTHPT;

    OPEN DataCursor;
    FETCH NEXT FROM DataCursor INTO @MaSBD, @DiemToan, @DiemVan, @DiemNgoaiNgu, @DiemVatLy, 
                                     @DiemHoaHoc, @DiemSinhHoc, @DTB_TuNhien, @DiemLichSu, 
                                     @DiemDiaLy, @DiemGDCD, @DTB_XaHoi;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Xác định khu vực dựa trên MaSBD
        SET @KhuVuc = CASE 
                        WHEN LEFT(@MaSBD, 2) = '04' THEN N'Da Nang'
                        WHEN LEFT(@MaSBD, 2) = '33' THEN N'Hue'
                        WHEN LEFT(@MaSBD, 2) = '34' THEN N'Quang Nam'
						WHEN LEFT(@MaSBD, 2) = '28' THEN N'Thanh Hoa'
						WHEN LEFT(@MaSBD, 2) = '45' THEN N'Ninh Thuan'
						WHEN LEFT(@MaSBD, 2) = '37' THEN N'Binh Dinh'
						WHEN LEFT(@MaSBD, 2) = '29' THEN N'Nghe An'
						WHEN LEFT(@MaSBD, 2) = '32' THEN N'Quang Tri'
						WHEN LEFT(@MaSBD, 2) = '36' THEN N'Kon Tum'
						WHEN LEFT(@MaSBD, 2) = '42' THEN N'Lam Dong'
						WHEN LEFT(@MaSBD, 2) = '40' THEN N'Dak Lak'
						WHEN LEFT(@MaSBD, 2) = '31' THEN N'Quang Binh'
						WHEN LEFT(@MaSBD, 2) = '47' THEN N'Binh Thuan'
						WHEN LEFT(@MaSBD, 2) = '30' THEN N'Ha Tinh'
                        ELSE N'Khac'
                      END;

        -- Chèn vào bảng ThiSinh nếu chưa tồn tại
        IF NOT EXISTS (SELECT 1 FROM ThiSinh WHERE MaSBD = @MaSBD)
        BEGIN
            INSERT INTO ThiSinh (MaSBD, KhuVuc)
            VALUES (@MaSBD, @KhuVuc);
        END

        -- Chèn vào bảng MonThi nếu chưa tồn tại
        IF NOT EXISTS (SELECT 1 FROM MonThi WHERE MaMon IN ('Toan', 'Van', 'NgoaiNgu', 'VatLy', 'HoaHoc', 'SinhHoc', 'LichSu', 'DiaLy', 'GDCD'))
        BEGIN
            INSERT INTO MonThi (MaMon, TenMon)
            VALUES 
                ('Toan', N'Toan'),
                ('Van', N'Van'),
                ('NgoaiNgu', N'Ngoai ngu'),
                ('VatLy', N'Vat ly'),
                ('HoaHoc', N'Hoa hoc'),
                ('SinhHoc', N'Sinh hoc'),
                ('LichSu', N'Lich su'),
                ('DiaLy', N'Dia ly'),
                ('GDCD', N'Giao duc cong dan');
        END

        -- Chèn vào bảng KhoiThi nếu chưa tồn tại
        IF NOT EXISTS (SELECT 1 FROM KhoiThi WHERE MaKhoi IN ('KhoiA', 'KhoiA1', 'KhoiB', 'KhoiC', 'KhoiD'))
        BEGIN
            INSERT INTO KhoiThi (MaKhoi, TenKhoi)
            VALUES 
                ('KhoiA', N'Khoi A'),
                ('KhoiA1', N'Khoi A1'),
                ('KhoiB', N'Khoi B'),
                ('KhoiC', N'Khoi C'),
                ('KhoiD', N'Khoi D');
        END

        -- Chèn vào bảng KhoiMonThi nếu chưa tồn tại
        IF NOT EXISTS (SELECT 1 FROM KhoiMonThi WHERE MaKhoi IN ('KhoiA', 'KhoiA1', 'KhoiB', 'KhoiC', 'KhoiD'))
        BEGIN
            INSERT INTO KhoiMonThi (MaKhoi, MaMon)
            VALUES 
                ('KhoiA', 'Toan'), ('KhoiA', 'VatLy'), ('KhoiA', 'HoaHoc'),
            ('KhoiA1', 'Toan'), ('KhoiA1', 'VatLy'), ('KhoiA1', 'NgoaiNgu'),
            ('KhoiB', 'Toan'), ('KhoiB', 'HoaHoc'), ('KhoiB', 'SinhHoc'),
            ('KhoiC', 'Van'), ('KhoiC', 'LichSu'), ('KhoiC', 'DiaLy'),
            ('KhoiD', 'Toan'), ('KhoiD', 'Van'), ('KhoiD', 'NgoaiNgu')
        END

        -- Chèn điểm vào bảng DiemThi
        -- Kiểm tra xem các môn đã tồn tại trong MonThi trước khi chèn điểm
        DECLARE @MaMon NVARCHAR(15);

        DECLARE MonCursor CURSOR FOR
        SELECT DISTINCT MaMon FROM (VALUES 
            ('Toan', @DiemToan),
            ('Van', @DiemVan),
            ('NgoaiNgu', @DiemNgoaiNgu),
            ('VatLy', @DiemVatLy),
            ('HoaHoc', @DiemHoaHoc),
            ('SinhHoc', @DiemSinhHoc),
            ('DTB_TuNhien', @DTB_TuNhien),
            ('DTB_XaHoi', @DTB_XaHoi),
            ('LichSu', @DiemLichSu),
            ('DiaLy', @DiemDiaLy),
            ('GDCD', @DiemGDCD)
        ) AS Subjects(MaMon, Diem);

        OPEN MonCursor;
        FETCH NEXT FROM MonCursor INTO @MaMon;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Kiểm tra xem môn đã tồn tại trong MonThi trước khi chèn điểm
            IF EXISTS (SELECT 1 FROM MonThi WHERE MaMon = @MaMon)
            BEGIN
                INSERT INTO DiemThi (MaSBD, MaMon, Diem)
                VALUES (@MaSBD, @MaMon, CASE @MaMon
                    WHEN 'Toan' THEN @DiemToan
                    WHEN 'Van' THEN @DiemVan
                    WHEN 'NgoaiNgu' THEN @DiemNgoaiNgu
                    WHEN 'VatLy' THEN @DiemVatLy
                    WHEN 'HoaHoc' THEN @DiemHoaHoc
                    WHEN 'SinhHoc' THEN @DiemSinhHoc
                    WHEN 'DTB_TuNhien' THEN @DTB_TuNhien
                    WHEN 'DTB_XaHoi' THEN @DTB_XaHoi
                    WHEN 'LichSu' THEN @DiemLichSu
                    WHEN 'DiaLy' THEN @DiemDiaLy
                    WHEN 'GDCD' THEN @DiemGDCD
                END);
            END

            FETCH NEXT FROM MonCursor INTO @MaMon;
        END;

        CLOSE MonCursor;
        DEALLOCATE MonCursor;

        FETCH NEXT FROM DataCursor INTO @MaSBD, @DiemToan, @DiemVan, @DiemNgoaiNgu, @DiemVatLy, 
                                         @DiemHoaHoc, @DiemSinhHoc, @DTB_TuNhien, @DiemLichSu, 
                                         @DiemDiaLy, @DiemGDCD, @DTB_XaHoi;
    END;

    CLOSE DataCursor;
    DEALLOCATE DataCursor;
END;

-- Thực thi thủ tục
EXEC InsertDataFromDiemThiTHPT;





-- Module 1: Kiểm tra thí sinh có môn nào bị liệt hay không
CREATE OR ALTER PROCEDURE PrintAndCheckScoresPerSBD
AS
BEGIN
    -- Tạo bảng tạm để lưu trữ học sinh đủ và không đủ điều kiện
    CREATE TABLE #DuyetDiem (
        MaSBD INT,
        Toan FLOAT,
        Van FLOAT,
        NgoaiNgu FLOAT,
        VatLy FLOAT,
        HoaHoc FLOAT,
        SinhHoc FLOAT,
        GDCD FLOAT,
        DiaLy FLOAT,
        LichSu FLOAT,
        KetQua NVARCHAR(50)
    );

    -- Chọn điểm của tất cả thí sinh vào bảng tạm
    INSERT INTO #DuyetDiem (MaSBD, Toan, Van, NgoaiNgu, VatLy, HoaHoc, SinhHoc, GDCD, DiaLy, LichSu, KetQua)
    SELECT
        t.MaSBD,
        MAX(CASE WHEN d.MaMon = 'Toan' THEN d.Diem END) AS Toan,
        MAX(CASE WHEN d.MaMon = 'Van' THEN d.Diem END) AS Van,
        MAX(CASE WHEN d.MaMon = 'NgoaiNgu' THEN d.Diem END) AS NgoaiNgu,
        MAX(CASE WHEN d.MaMon = 'VatLy' THEN d.Diem END) AS VatLy,
        MAX(CASE WHEN d.MaMon = 'HoaHoc' THEN d.Diem END) AS HoaHoc,
        MAX(CASE WHEN d.MaMon = 'SinhHoc' THEN d.Diem END) AS SinhHoc,
        MAX(CASE WHEN d.MaMon = 'GDCD' THEN d.Diem END) AS GDCD,
        MAX(CASE WHEN d.MaMon = 'DiaLy' THEN d.Diem END) AS DiaLy,
        MAX(CASE WHEN d.MaMon = 'LichSu' THEN d.Diem END) AS LichSu,
        CASE 
            WHEN COUNT(CASE WHEN d.MaMon IN ('Toan', 'Van', 'NgoaiNgu') AND d.Diem > 1 THEN 1 END) = 3 AND 
                 (COUNT(CASE WHEN d.MaMon IN ('VatLy', 'HoaHoc', 'SinhHoc') AND d.Diem > 1 THEN 1 END) = 3 OR 
                  COUNT(CASE WHEN d.MaMon IN ('GDCD', 'DiaLy', 'LichSu') AND d.Diem > 1 THEN 1 END) = 3)
            THEN N'Du ĐKTN'
            ELSE N'Khong Du ĐKTN'
        END AS KetQua
    FROM ThiSinh t
    LEFT JOIN DiemThi d ON t.MaSBD = d.MaSBD
    GROUP BY t.MaSBD;
	
    -- Đếm số học sinh đủ và không đủ điều kiện
    SELECT COUNT(*) AS SoHocSinhDuĐKTN 
    FROM #DuyetDiem 
    WHERE KetQua = N'Du ĐKTN';

    SELECT COUNT(*) AS SoHocSinhKhongDuĐKTN 
    FROM #DuyetDiem 
    WHERE KetQua = N'Khong Du ĐKTN';

    -- In ra bảng đủ điều kiện
    PRINT '----- Học sinh đủ điều kiện tốt nghiệp -----';
    SELECT * FROM #DuyetDiem 
    WHERE KetQua = N'Du ĐKTN';

    PRINT '----- Học sinh không đủ điều kiện tốt nghiệp -----';
    SELECT * FROM #DuyetDiem 
    WHERE KetQua = N'Khong Du ĐKTN';

    -- Xóa bảng tạm
    DROP TABLE #DuyetDiem;
END;

EXEC PrintAndCheckScoresPerSBD;



-- Module 2: Tính toán và xếp hạng Top10 thí sinh theo điểm từng khối
CREATE OR ALTER PROCEDURE Top10StudentsByBlock
AS
BEGIN
    -- Khai báo biến
    DECLARE @MaSBD CHAR(8);
    DECLARE @Diem FLOAT;
    DECLARE @TotalScore FLOAT;
    DECLARE @MaKhoi VARCHAR(15);
    DECLARE @TenKhoi NVARCHAR(50);
    
    -- Bảng tạm để lưu trữ kết quả tạm thời
    CREATE TABLE #TopStudents (
        MaSBD CHAR(8),
        MaKhoi VARCHAR(15),
        TotalScore FLOAT
    );

    -- Tính điểm cho từng khối
    DECLARE cur CURSOR FOR
    SELECT TS.MaSBD, KM.MaKhoi, SUM(DT.Diem) AS TotalScore
    FROM ThiSinh TS
    JOIN DiemThi DT 	ON TS.MaSBD 	= DT.MaSBD
    JOIN KhoiMonThi KM 	ON KM.MaMon 	= DT.MaMon
    GROUP BY TS.MaSBD, KM.MaKhoi;

    OPEN cur;
    FETCH NEXT FROM cur INTO @MaSBD, @MaKhoi, @TotalScore;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO #TopStudents (MaSBD, MaKhoi, TotalScore)
        VALUES (@MaSBD, @MaKhoi, @TotalScore);
        FETCH NEXT FROM cur INTO @MaSBD, @MaKhoi, @TotalScore;
    END;

    CLOSE cur;
    DEALLOCATE cur;

    -- In ra top 10 sinh viên theo từng khối
    SELECT MaSBD, MaKhoi, TotalScore
    FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY MaKhoi 
				  ORDER BY TotalScore DESC) 
				  AS RowNum
        	      FROM #TopStudents) 
    AS RankedStudents
    WHERE RowNum <= 10
    ORDER BY MaKhoi, TotalScore DESC;

    -- Xóa bảng tạm
    DROP TABLE #TopStudents;
END;

-- Thực thi thủ tục
EXEC Top10StudentsByBlock;



-- Module 3: Tính tổng điểm theo từng khối giúp thí sinh dễ dàng chọn khối có điểm cao nhất để xét điểm vào đại học.
 CREATE OR ALTER PROCEDURE ShowAllScoresAndHighestBlock
AS
BEGIN
    -- Tạo bảng tạm lưu điểm từng khối và khối có điểm cao nhất cho từng thí sinh
    CREATE TABLE #StudentScores (
        MaSBD CHAR(8),
        DiemKhoiA FLOAT,
        DiemKhoiA1 FLOAT,
        DiemKhoiB FLOAT,
        DiemKhoiC FLOAT,
        DiemKhoiD FLOAT,
        KhoiCaoNhat NVARCHAR(10)
    );

    -- Tính tổng điểm cho từng khối dựa vào tổ hợp môn
    INSERT INTO #StudentScores (MaSBD, DiemKhoiA, DiemKhoiA1, DiemKhoiB, DiemKhoiC, DiemKhoiD)
    SELECT 
        ts.MaSBD,
        SUM(CASE WHEN mt.MaMon IN ('Toan', 'VatLy', 'HoaHoc')	THEN dt.Diem ELSE NULL END) AS DiemKhoiA,
        SUM(CASE WHEN mt.MaMon IN ('Toan', 'VatLy', 'NgoaiNgu') THEN dt.Diem ELSE NULL END) AS DiemKhoiA1,
        SUM(CASE WHEN mt.MaMon IN ('Toan', 'HoaHoc', 'SinhHoc') THEN dt.Diem ELSE NULL END) AS DiemKhoiB,
        SUM(CASE WHEN mt.MaMon IN ('Van', 'LichSu', 'DiaLy')	THEN dt.Diem ELSE NULL END) AS DiemKhoiC,
        SUM(CASE WHEN mt.MaMon IN ('Toan', 'Van', 'NgoaiNgu')	THEN dt.Diem ELSE NULL END) AS DiemKhoiD
    FROM ThiSinh ts
    LEFT JOIN DiemThi dt ON ts.MaSBD = dt.MaSBD
    LEFT JOIN MonThi mt	 ON dt.MaMon = mt.MaMon
    GROUP BY ts.MaSBD;

    -- Xác định khối có điểm cao nhất cho từng thí sinh
    UPDATE #StudentScores
    SET KhoiCaoNhat = 
        CASE 
            WHEN	 DiemKhoiA >= ISNULL(DiemKhoiA1, 0) 
                 AND DiemKhoiA >= ISNULL(DiemKhoiB, 0) 
                 AND DiemKhoiA >= ISNULL(DiemKhoiC, 0) 
                 AND DiemKhoiA >= ISNULL(DiemKhoiD, 0) THEN 'A'

            WHEN	 DiemKhoiA1 >= ISNULL(DiemKhoiA, 0) 
                 AND DiemKhoiA1 >= ISNULL(DiemKhoiB, 0) 
                 AND DiemKhoiA1 >= ISNULL(DiemKhoiC, 0) 
                 AND DiemKhoiA1 >= ISNULL(DiemKhoiD, 0) THEN 'A1'

            WHEN	 DiemKhoiB >= ISNULL(DiemKhoiA, 0) 
                 AND DiemKhoiB >= ISNULL(DiemKhoiA1, 0) 
                 AND DiemKhoiB >= ISNULL(DiemKhoiC, 0) 
                 AND DiemKhoiB >= ISNULL(DiemKhoiD, 0) THEN 'B'

            WHEN	 DiemKhoiC >= ISNULL(DiemKhoiA, 0) 
                 AND DiemKhoiC >= ISNULL(DiemKhoiA1, 0) 
                 AND DiemKhoiC >= ISNULL(DiemKhoiB, 0) 
                 AND DiemKhoiC >= ISNULL(DiemKhoiD, 0) THEN 'C'

            WHEN	 DiemKhoiD >= ISNULL(DiemKhoiA, 0) 
                 AND DiemKhoiD >= ISNULL(DiemKhoiA1, 0) 
                 AND DiemKhoiD >= ISNULL(DiemKhoiB, 0) 
                 AND DiemKhoiD >= ISNULL(DiemKhoiC, 0) THEN 'D'
            ELSE NULL
        END;

    -- Hiển thị kết quả
    SELECT 
        MaSBD, 
        DiemKhoiA, 
        DiemKhoiA1, 
        DiemKhoiB, 
        DiemKhoiC, 
        DiemKhoiD, 
        KhoiCaoNhat
    FROM #StudentScores
    ORDER BY MaSBD;

    -- Xóa bảng tạm
    DROP TABLE #StudentScores;
END;

-- Thực thi thủ tục
EXEC ShowAllScoresAndHighestBlock;


-- Module 4: Đánh giá mức độ khó của từng môn thi trong 3 khu vực 
CREATE or ALTER PROCEDURE DifficultyAssessmentBySubjectAndProvince
AS
BEGIN
    -- Tạo bảng tạm để lưu tỷ lệ điểm cao và thấp cho từng môn thi trong mỗi tỉnh
    SELECT
        ts.KhuVuc,                    -- Tỉnh
        dt.MaMon,                     -- Mã môn thi
        COUNT(CASE WHEN dt.Diem < 5 THEN 1 END) * 1.0 / COUNT(*) * 100 AS TyLeDiemThap,  -- Tỷ lệ điểm thấp (nhân với 100 để ra %)
        COUNT(CASE WHEN dt.Diem >= 7 THEN 1 END) * 1.0 / COUNT(*) * 100 AS TyLeDiemCao   -- Tỷ lệ điểm cao (nhân với 100 để ra %)
    INTO #DifficultyAssessment
    FROM
        DiemThi dt JOIN ThiSinh ts ON dt.MaSBD = ts.MaSBD
    GROUP BY
        ts.KhuVuc, dt.MaMon;

    -- Xác định môn thi khó nhất (môn có tỷ lệ điểm thấp cao hơn)
    SELECT
        KhuVuc, 
        MaMon, 
        TyLeDiemThap, 
        TyLeDiemCao,
        CASE
            WHEN TyLeDiemThap > TyLeDiemCao THEN 'Kho'
            ELSE 'De'
        END AS MucDoKho
    FROM #DifficultyAssessment
    ORDER BY KhuVuc, MaMon;

    -- Xóa bảng tạm sau khi sử dụng
    DROP TABLE #DifficultyAssessment;
END;

EXEC DifficultyAssessmentBySubjectAndProvince;


-- Module 5: Xếp hạng khu vực có điểm trung bình cao nhất cho mỗi môn thi
CREATE OR ALTER PROCEDURE AverageScoreBySubjectAndRegion
AS
BEGIN
    -- Tạo bảng tạm để tính điểm trung bình của các thí sinh theo khu vực và môn thi
    SELECT
        ts.KhuVuc,                     -- Khu vực
        dt.MaMon,                      -- Mã môn thi
        AVG(dt.Diem) AS DiemTrungBinh  -- Điểm thi trung bình
    INTO #SubjectRegionAverageScore
    FROM
        DiemThi dt
    JOIN
        ThiSinh ts ON dt.MaSBD = ts.MaSBD
    GROUP BY
        ts.KhuVuc, dt.MaMon;

    -- Xếp hạng các khu vực theo điểm trung bình từ cao xuống thấp trong mỗi môn thi
    WITH RankedScores AS (
        SELECT
            KhuVuc, 
            MaMon, 
            DiemTrungBinh,
            RANK() OVER (PARTITION BY MaMon ORDER BY DiemTrungBinh DESC) AS Rank
        FROM #SubjectRegionAverageScore
    )

    -- Trả về kết quả thống kê theo môn và các khu vực với điểm trung bình của từng khu vực
    SELECT
        MaMon,
        MAX(CASE WHEN KhuVuc = 'Hue' THEN DiemTrungBinh ELSE NULL END) AS DiemTB_Hue,
        MAX(CASE WHEN KhuVuc = 'Da Nang' THEN DiemTrungBinh ELSE NULL END) AS DiemTB_DaNang,
        MAX(CASE WHEN KhuVuc = 'Quang Nam' THEN DiemTrungBinh ELSE NULL END) AS DiemTB_QuangNam,
        MAX(CASE WHEN Rank = 1 THEN KhuVuc ELSE NULL END) AS HighestRegion
    FROM RankedScores
    GROUP BY MaMon
    ORDER BY MaMon;

    -- Xóa bảng tạm sau khi sử dụng
    DROP TABLE #SubjectRegionAverageScore;
END;

EXEC AverageScoreBySubjectAndRegion;


-- Module 6: Phân tích tỷ lệ thí sinh đạt điểm tuyệt đối (10) theo từng môn trong 3 khu vực 
CREATE OR ALTER PROCEDURE PhanTichTyLeDiem10TheoKhuVuc
AS
BEGIN
    -- Tạo bảng tạm để lưu kết quả
    CREATE TABLE #KetQua (
        MaMon NVARCHAR(15),
        KhuVuc NVARCHAR(50),
        SoLuong INT,
        TyLeDiem10 FLOAT
    );

    -- Chèn dữ liệu vào bảng tạm
    INSERT INTO #KetQua (MaMon, KhuVuc, SoLuong, TyLeDiem10)
    SELECT 
        DiemThi.MaMon,
        ThiSinh.KhuVuc,
        -- Số lượng thí sinh đạt điểm 10 cho từng môn và khu vực
        COUNT(CASE WHEN DiemThi.Diem = 10 THEN 1 END) AS SoLuong,
        -- Tính tỷ lệ thí sinh đạt điểm 10 cho từng môn và khu vực
        ISNULL(CAST(COUNT(CASE WHEN DiemThi.Diem = 10 THEN 1 END) AS FLOAT) / COUNT(DISTINCT DiemThi.MaSBD) * 100, 0) AS TyLeDiem10
    FROM 
        DiemThi
    -- Join với bảng ThiSinh để lấy thông tin khu vực
    INNER JOIN ThiSinh ON DiemThi.MaSBD = ThiSinh.MaSBD
    GROUP BY 
        DiemThi.MaMon, ThiSinh.KhuVuc;

    -- Trả về kết quả
    SELECT * FROM #KetQua
    ORDER BY MaMon, KhuVuc;

    -- Xóa bảng tạm
    DROP TABLE #KetQua;
END;

-- Thực thi thủ tục
EXEC PhanTichTyLeDiem10TheoKhuVuc;



-- Module 7: Xác định điểm thi cao nhất và thấp nhất của mỗi môn.
CREATE OR ALTER PROCEDURE PhanTichDiemThiToiDaToiThieu
AS
BEGIN
    -- Tạo bảng tạm để lưu kết quả phân tích điểm thi tối đa và tối thiểu
    CREATE TABLE #PhanTichDiemThi (
        MaMon NVARCHAR(50),
        MaxScore FLOAT,
        MinScore FLOAT,
        MaxScoreSBD NVARCHAR(MAX),   -- Gom các Mã số bài thi có điểm tối đa thành chuỗi
        MinScoreSBD NVARCHAR(MAX),   -- Gom các Mã số bài thi có điểm tối thiểu thành chuỗi
        MaxScoreCount INT,           -- Số lượng học sinh đạt điểm tối đa
        MinScoreCount INT            -- Số lượng học sinh đạt điểm tối thiểu
    );

    -- Tính toán điểm tối đa và tối thiểu trước, sau đó gom các Mã Số Bài Thi
    WITH DiemMaxMin AS (
        SELECT 
            MaMon,
            MAX(Diem) AS MaxScore,
            MIN(Diem) AS MinScore
        FROM DiemThi
        GROUP BY MaMon
    )
    INSERT INTO #PhanTichDiemThi (MaMon, MaxScore, MinScore, MaxScoreSBD, MinScoreSBD, MaxScoreCount, MinScoreCount)
    SELECT 
        dt.MaMon,
        dmm.MaxScore,
        dmm.MinScore,
        -- Gom các Mã số bài thi có điểm tối đa thành chuỗi
        STRING_AGG(CASE WHEN dt.Diem = dmm.MaxScore THEN dt.MaSBD END, ', ') AS MaxScoreSBD,
        -- Gom các Mã số bài thi có điểm tối thiểu thành chuỗi
        STRING_AGG(CASE WHEN dt.Diem = dmm.MinScore THEN dt.MaSBD END, ', ') AS MinScoreSBD,
        -- Số lượng học sinh đạt điểm tối đa
        COUNT(CASE WHEN dt.Diem = dmm.MaxScore THEN 1 END) AS MaxScoreCount,
        -- Số lượng học sinh đạt điểm tối thiểu
        COUNT(CASE WHEN dt.Diem = dmm.MinScore THEN 1 END) AS MinScoreCount
    FROM DiemThi dt
    INNER JOIN DiemMaxMin dmm ON dt.MaMon = dmm.MaMon
    GROUP BY dt.MaMon, dmm.MaxScore, dmm.MinScore;

    -- Hiển thị kết quả phân tích điểm thi
    SELECT * FROM #PhanTichDiemThi;

    -- Xóa bảng tạm
    DROP TABLE #PhanTichDiemThi;
END;

EXEC PhanTichDiemThiToiDaToiThieu;


-- Module 8: Thống kê số lượng thí sinh theo khối thi
CREATE OR ALTER PROCEDURE SoLuongThiSinhTheoKhoi
AS
BEGIN
    -- Thống kê số lượng thí sinh thi khối Tự nhiên cho từng khu vực
    SELECT 
        ts.KhuVuc,
        'Tu nhien' AS KhoiThi,
        COUNT(DISTINCT ts.MaSBD) AS SoLuongThiSinh
    FROM 
        ThiSinh ts INNER JOIN DiemThi dt ON ts.MaSBD = dt.MaSBD
	WHERE 
        ts.MaSBD IN (
            -- Chọn thí sinh có điểm của các môn khối Tự nhiên hoặc thiếu môn khối Tự nhiên
            SELECT MaSBD 
            FROM DiemThi 
            WHERE MaMon IN ('VatLy', 'HoaHoc', 'SinhHoc') AND Diem IS NOT NULL
            GROUP BY MaSBD
            HAVING COUNT(DISTINCT MaMon) > 0
        )
    GROUP BY 
        ts.KhuVuc;

    -- Thống kê số lượng thí sinh thi khối Xã hội cho từng khu vực
    SELECT 
        ts.KhuVuc,
        'Xa hoi' AS KhoiThi,
        COUNT(DISTINCT ts.MaSBD) AS SoLuongThiSinh
    FROM 
        ThiSinh ts INNER JOIN DiemThi dt ON ts.MaSBD = dt.MaSBD
	WHERE 
        ts.MaSBD IN (
            -- Chọn thí sinh có điểm của các môn khối Xã hội hoặc thiếu môn khối Xã hội
            SELECT MaSBD 
            FROM DiemThi 
            WHERE MaMon IN ('LichSu', 'DiaLy', 'GDCD') AND Diem IS NOT NULL
            GROUP BY MaSBD
            HAVING COUNT(DISTINCT MaMon) > 0
        )
    GROUP BY 
        ts.KhuVuc;
END;

EXEC SoLuongThiSinhTheoKhoi;


-- Module 9: Đánh giá sự phân bố điểm theo từng khối thi và khu vực
CREATE OR ALTER PROCEDURE DanhGiaPhanBoDiemTheoKhoiVaKhuVuc
AS
BEGIN
    -- Đánh giá phân bố điểm khối Tự nhiên trong khu vực Đà Nẵng
    SELECT 
        ts.KhuVuc,
        'Tu nhien' AS KhoiThi,
        CASE 
            WHEN dt.Diem <= 5 THEN '0-5'
            WHEN dt.Diem > 5 AND dt.Diem <= 7 THEN '5-7'
            WHEN dt.Diem > 7 AND dt.Diem <= 9 THEN '7-9'
            ELSE '9-10'
        END AS KhoangDiem,
        COUNT(DISTINCT dt.MaSBD) AS SoLuongThiSinh
    FROM 
        ThiSinh ts
    INNER JOIN DiemThi dt ON ts.MaSBD = dt.MaSBD
    WHERE 
        dt.MaMon IN ('VatLy', 'HoaHoc', 'SinhHoc') AND dt.Diem IS NOT NULL AND ts.KhuVuc = 'Da Nang'
    GROUP BY 
        ts.KhuVuc, 
        CASE 
            WHEN dt.Diem <= 5 THEN '0-5'
            WHEN dt.Diem > 5 AND dt.Diem <= 7 THEN '5-7'
            WHEN dt.Diem > 7 AND dt.Diem <= 9 THEN '7-9'
            ELSE '9-10'
        END;

    -- Đánh giá phân bố điểm khối Xã hội trong khu vực Huế
    SELECT 
        ts.KhuVuc,
        'Xa hoi' AS KhoiThi,
        CASE 
            WHEN dt.Diem <= 5 THEN '0-5'
            WHEN dt.Diem > 5 AND dt.Diem <= 7 THEN '5-7'
            WHEN dt.Diem > 7 AND dt.Diem <= 9 THEN '7-9'
            ELSE '9-10'
        END AS KhoangDiem,
        COUNT(DISTINCT dt.MaSBD) AS SoLuongThiSinh
    FROM 
        ThiSinh ts
    INNER JOIN DiemThi dt ON ts.MaSBD = dt.MaSBD
    WHERE 
        dt.MaMon IN ('LichSu', 'DiaLy', 'GDCD') AND dt.Diem IS NOT NULL AND ts.KhuVuc = 'Hue'
    GROUP BY 
        ts.KhuVuc, 
        CASE 
            WHEN dt.Diem <= 5 THEN '0-5'
            WHEN dt.Diem > 5 AND dt.Diem <= 7 THEN '5-7'
            WHEN dt.Diem > 7 AND dt.Diem <= 9 THEN '7-9'
            ELSE '9-10'
        END;

    -- Đánh giá phân bố điểm khối Xã hội trong khu vực Quảng Nam
    SELECT 
        ts.KhuVuc,
        'Xa hoi' AS KhoiThi,
        CASE 
            WHEN dt.Diem <= 5 THEN '0-5'
            WHEN dt.Diem > 5 AND dt.Diem <= 7 THEN '5-7'
            WHEN dt.Diem > 7 AND dt.Diem <= 9 THEN '7-9'
            ELSE '9-10'
        END AS KhoangDiem,
        COUNT(DISTINCT dt.MaSBD) AS SoLuongThiSinh
    FROM 
        ThiSinh ts
    INNER JOIN DiemThi dt ON ts.MaSBD = dt.MaSBD
    WHERE 
        dt.MaMon IN ('LichSu', 'DiaLy', 'GDCD') AND dt.Diem IS NOT NULL AND ts.KhuVuc = 'Quang Nam'
    GROUP BY 
        ts.KhuVuc, 
        CASE 
            WHEN dt.Diem <= 5 THEN '0-5'
            WHEN dt.Diem > 5 AND dt.Diem <= 7 THEN '5-7'
            WHEN dt.Diem > 7 AND dt.Diem <= 9 THEN '7-9'
            ELSE '9-10'
        END;
END;

EXEC DanhGiaPhanBoDiemTheoKhoiVaKhuVuc;


-- Module 10: Xếp Hạng Thí Sinh Theo Khu Vực và Khối Thi
CREATE OR ALTER PROCEDURE XepHangTheoKhuVucVaKhoi
AS
BEGIN
    -- Khai báo các biến
    DECLARE @KhuVuc NVARCHAR(50);
    DECLARE @KhoiThi NVARCHAR(10);
    DECLARE @MonThi1 NVARCHAR(50);
    DECLARE @MonThi2 NVARCHAR(50);
    DECLARE @MonThi3 NVARCHAR(50);
    
	-- Danh sách các khu vực
	DECLARE @KhuVucList TABLE (KhuVuc NVARCHAR(50));
    
    INSERT INTO @KhuVucList (KhuVuc)
    SELECT DISTINCT KhuVuc FROM ThiSinh WHERE KhuVuc IN ('Da Nang', 'Hue', 'Quang Nam');

    -- Danh sách các khối thi
    DECLARE @Khois TABLE (Khoi NVARCHAR(10), MonThi1 NVARCHAR(50), MonThi2 NVARCHAR(50), MonThi3 NVARCHAR(50));
    
    INSERT INTO @Khois (Khoi, MonThi1, MonThi2, MonThi3)
    VALUES 
        ('A', 'Toan', 'VatLy', 'HoaHoc'),
        ('A1', 'Toan', 'VatLy', 'TiengAnh'),
        ('B', 'Toan', 'HoaHoc', 'SinhHoc'),
        ('C', 'NguVan', 'LichSu', 'DiaLy'),
        ('D', 'Toan', 'NguVan', 'NgoaiNgu');

    -- Lặp qua từng khu vực
    DECLARE khuVuc_cursor CURSOR FOR
    SELECT KhuVuc FROM @KhuVucList;

    OPEN khuVuc_cursor;
    FETCH NEXT FROM khuVuc_cursor INTO @KhuVuc;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Lặp qua từng khối thi
        DECLARE khoi_cursor CURSOR FOR
        SELECT Khoi, MonThi1, MonThi2, MonThi3 FROM @Khois;

        OPEN khoi_cursor;
        FETCH NEXT FROM khoi_cursor INTO @KhoiThi, @MonThi1, @MonThi2, @MonThi3;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Tạo SQL động cho từng khu vực và khối thi
            DECLARE @SQL NVARCHAR(MAX);
            SET @SQL = 
                N'SELECT ts.MaSBD, ts.KhuVuc, ''' + @KhoiThi + ''' AS KhoiThi, ' +
                'SUM(CASE WHEN dt.MaMon = @MonThi1 THEN dt.Diem ELSE 0 END) + ' +
                'SUM(CASE WHEN dt.MaMon = @MonThi2 THEN dt.Diem ELSE 0 END) + ' +
                'SUM(CASE WHEN dt.MaMon = @MonThi3 THEN dt.Diem ELSE 0 END) AS TongDiem, ' +
                'RANK() OVER (PARTITION BY ts.KhuVuc ORDER BY ' + 
                'SUM(CASE WHEN dt.MaMon = @MonThi1 THEN dt.Diem ELSE 0 END) + ' +
                'SUM(CASE WHEN dt.MaMon = @MonThi2 THEN dt.Diem ELSE 0 END) + ' +
                'SUM(CASE WHEN dt.MaMon = @MonThi3 THEN dt.Diem ELSE 0 END) DESC) AS ThuHang ' +
                'FROM ThiSinh ts ' +
                'JOIN DiemThi dt ON ts.MaSBD = dt.MaSBD ' +
                'WHERE ts.KhuVuc = @KhuVuc AND dt.MaMon IN (@MonThi1, @MonThi2, @MonThi3) ' +
                'GROUP BY ts.MaSBD, ts.KhuVuc ' +
                'ORDER BY ThuHang;';

            -- Thực thi SQL động
            EXEC sp_executesql @SQL, 
                N'@KhuVuc NVARCHAR(50), @MonThi1 NVARCHAR(50), @MonThi2 NVARCHAR(50), @MonThi3 NVARCHAR(50)',
                @KhuVuc, @MonThi1, @MonThi2, @MonThi3;

            FETCH NEXT FROM khoi_cursor INTO @KhoiThi, @MonThi1, @MonThi2, @MonThi3;
        END

        CLOSE khoi_cursor;
        DEALLOCATE khoi_cursor;

        FETCH NEXT FROM khuVuc_cursor INTO @KhuVuc;
    END

    CLOSE khuVuc_cursor;
    DEALLOCATE khuVuc_cursor;
END;

EXEC XepHangTheoKhuVucVaKhoi;

