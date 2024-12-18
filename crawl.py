import requests
import time
import pandas as pd
import pyodbc
from io import StringIO

# Cấu hình thông tin kết nối tới SQL Server
server = '...'  # Địa chỉ SQL Server của bạn
database = 'DiemThi'  # Tên cơ sở dữ liệu
username = '...'  # Tên đăng nhập
password = '...'  # Mật khẩu
driver = '{ODBC Driver 17 for SQL Server}'

# Tạo kết nối tới SQL Server
conn = pyodbc.connect(f'DRIVER={driver};SERVER={server};DATABASE={database};UID={username};PWD={password}')
cursor = conn.cursor()

# Tạo bảng nếu chưa tồn tại
create_table_query = """
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='DiemThiTHPT' AND xtype='U')
CREATE TABLE DiemThiTHPT (
    SBD NVARCHAR(50) PRIMARY KEY,
    Toan FLOAT,
    Van FLOAT,
    NgoaiNgu FLOAT,
    VatLy FLOAT,
    HoaHoc FLOAT,
    SinhHoc FLOAT,
    DTB_TuNhien FLOAT,
    LichSu FLOAT,
    DiaLy FLOAT,
    GDCD FLOAT,
    DTB_XaHoi FLOAT
)
"""
cursor.execute(create_table_query)
conn.commit()

# Tạo DataFrame trống với cấu trúc mong muốn
columns = [
    'SBD', 'Toan', 'Van', 'Ngoai Ngu', 'Vat Ly', 'Hoa Hoc', 'Sinh Hoc',
    'DTB Tu Nhien', 'Lich Su', 'Dia Ly', 'GDCD', 'DTB Xa Hoi'
]
existing_df = pd.DataFrame(columns=columns)


for x in range(34012000, 34012005):
    scraping_url = f"https://dantri.com.vn/thpt/1/0/99/{x}/2024/0.2/search-gradle.htm"

    try:
        response = requests.get(scraping_url)

        if response.status_code == 200:
            # Chuyển đổi phản hồi sang JSON và lấy dữ liệu 'student'
            info = response.json().get('student', {})

            # Kiểm tra SBD trước khi thêm vào dữ liệu
            sbd_value = info.get('sbd', None)
            if sbd_value is not None:
                # Tạo từ điển dữ liệu với giá trị None nếu không có
                diem = {
                    'SBD':          sbd_value,  # Nếu không có SBD, không thêm dữ liệu
                    'Toan':         info.get('toan',         None),
                    'Van':          info.get('van',          None),
                    'Ngoai Ngu':    info.get('ngoaiNgu',     None),
                    'Vat Ly':       info.get('vatLy',        None),
                    'Hoa Hoc':      info.get('hoaHoc',       None),
                    'Sinh Hoc':     info.get('sinhHoc',      None),
                    'DTB Tu Nhien': info.get('diemTBTuNhien',None),
                    'Lich Su':      info.get('lichSu',       None),
                    'Dia Ly':       info.get('diaLy',        None),
                    'GDCD':         info.get('gdcd',         None),
                    'DTB Xa Hoi':   info.get('diemTBXaHoi',  None)}

                # Chuyển từ điển thành DataFrame
                new_row_df = pd.DataFrame([diem], columns=columns)

                # Kết hợp dữ liệu hiện tại và dòng mới
                combined_df = pd.concat([existing_df, new_row_df], ignore_index=True).drop_duplicates(subset='SBD')

                # Loại bỏ các dòng trống hoàn toàn (nếu có)
                combined_df = combined_df[combined_df.notna().any(axis=1)]

                # Chèn từng dòng vào bảng SQL Server
                for index, row in new_row_df.iterrows():
                    insert_query = """
                    INSERT INTO DiemThiTHPT (SBD, Toan, Van, NgoaiNgu, 
                                            VatLy, HoaHoc, SinhHoc, DTB_TuNhien, 
                                            LichSu, DiaLy, GDCD, DTB_XaHoi)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """
                    cursor.execute(insert_query, row['SBD'], row['Toan'], row['Van'], row['Ngoai Ngu'],
                                   row['Vat Ly'], row['Hoa Hoc'], row['Sinh Hoc'], row['DTB Tu Nhien'],
                                   row['Lich Su'], row['Dia Ly'], row['GDCD'], row['DTB Xa Hoi'])

                conn.commit()  # Lưu thay đổi vào SQL Server
                print(f"Đã thêm và cập nhật dữ liệu cho SBD: {sbd_value}")
            else:
                print(f"Không có SBD cho URL: {scraping_url}. Dữ liệu không được thêm.")
        else:
            print(f"Lỗi {response.status_code} khi truy cập URL: {scraping_url}")

    except requests.exceptions.RequestException as e:
        print(f"Lỗi khi gửi yêu cầu: {e}")
    except ValueError:
        print(f"Phản hồi không phải là JSON hợp lệ cho URL: {scraping_url}")
    except KeyError as e:
        print(f"Lỗi: không tìm thấy trường {e} trong dữ liệu phản hồi cho URL: {scraping_url}")

    # Đợi 1 giây giữa các yêu cầu để tránh bị chặn (có thể điều chỉnh theo nhu cầu)
    time.sleep(1)

# Đóng kết nối sau khi hoàn thành
cursor.close()
conn.close()
print(f"Dữ liệu đã được cập nhật vào bảng DiemThiTHPT trong SQL Server.")
