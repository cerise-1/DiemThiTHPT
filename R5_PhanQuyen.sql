use DiemThi

-- Bước 1: Tạo Login trong CSDL
CREATE LOGIN AdminLogin WITH PASSWORD = 'MatKhau@123';
CREATE LOGIN DELogin WITH PASSWORD = 'MatKhau!123';
CREATE LOGIN DALogin WITH PASSWORD = 'MatKhauAn123';

-- Bước 2: Tạo User trong CSDL
CREATE USER AdminUser FOR LOGIN AdminLogin;
CREATE USER DEUser FOR LOGIN DELogin;
CREATE USER DAUser FOR LOGIN DALogin;

-- Bước 3: Tạo Role (vai trò) trong CSDL
CREATE ROLE DE;

-- Bước 4: Phân quyền cho từng vai trò
-- Quyền cho Admin
ALTER ROLE db_owner ADD MEMBER AdminUser;  

-- Quyền cho DE
ALTER ROLE db_datareader ADD MEMBER DEUser;
ALTER ROLE db_ddladmin	 ADD MEMBER DEUser;
ALTER ROLE db_datawriter ADD MEMBER DEUser;
ALTER ROLE DE			 ADD MEMBER DEUser;
GRANT EXECUTE TO DE;

-- Quyền cho DA (DA chỉ có quyền xem dữ liệu)
ALTER ROLE db_datareader ADD MEMBER DAUser;       


