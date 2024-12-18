# 1. Tổng quan 

Dự án này tập trung vào việc quản lý, phân tích và khai thác dữ liệu điểm thi THPT quốc gia năm 2024. Bộ dữ liệu này được xây dựng với mục tiêu hỗ trợ học sinh, phụ huynh, và các cơ quan giáo dục trong việc:

- Tính tổng điểm theo từng khối thi (A, A1, B, C, D).
      
- Xếp hạng thí sinh theo tổng điểm các khối thi.
      
- Phân tích dữ liệu điểm thi thuộc khu vực Trung Bộ.
      
- Phân chia lượng thí sinh theo khối tự nhiên và khối xã hội.

# 2. Các module chính trong dự án

- Tính tổng điểm theo khối thi

  - Tính tổng điểm cho từng thí sinh theo các khối A, A1, B, C, D.
            
  - Tách điểm khối tự nhiên (Toán, Lý, Hóa, Sinh) và khối xã hội (Toán, Văn, Ngoại Ngữ, Sử, Địa, GDCD).

- Xếp hạng thí sinh theo điểm thi

  - Xếp hạng top 10 thí sinh có điểm cao nhất theo từng khối thi.
          
  - Xếp hạng thí sinh thuộc khu vực Trung Bộ.

- Thống kê số lượng thí sinh theo khối thi
      
  - Đếm số lượng thí sinh đăng ký theo từng khối.
          
  - Thống kê thí sinh theo khu vực địa lý dựa trên mã vùng trong mã số báo danh.

- Phân tích dữ liệu và hỗ trợ thí sinh
              
  - Đưa ra gợi ý lựa chọn khối thi tối ưu dựa trên điểm số cao nhất.

# 3. Cấu trúc bộ dữ liệu
| Cột | Mô tả |
|--------------|-----------------------------------------------------|
| MaSBD | Mã số báo danh (8 chữ số: 2 chữ số đầu là mã vùng, ví dụ: 04, 33, 34). |
| Toan | Điểm môn Toán. |
| Van | Điểm môn Ngữ Văn. |
| NgoaiNgu | Điểm môn Ngoại Ngữ. |
| VatLy | Điểm môn Vật Lý. |
| HoaHoc | Điểm môn Hóa Học. |
| SinhHoc | Điểm môn Sinh Học. |
| LichSu | Điểm môn Lịch Sử. |
| DiaLy | Điểm môn Địa Lý. |
| GDCD | Điểm môn Giáo Dục Công Dân. |


# 4. Đóng góp

Mọi đóng góp hoặc ý tưởng cải thiện dự án đều được hoan nghênh. 
*Vui lòng gửi pull request hoặc liên hệ qua email: [cerise1501@example.com].*
