# Kiểm tra, chuẩn hóa và mô hình hóa dữ liệu

## 1. Tổng quan dữ liệu

DataCo Global là bộ dữ liệu giả lập về hoạt động bán hàng và giao hàng, bao gồm thông tin đơn hàng, sản phẩm, khách hàng, địa điểm và vận chuyển.

Dữ liệu ban đầu được lưu trong **01 bảng duy nhất với 180.516 dòng và 53 cột**. Mỗi dòng tương ứng với một sản phẩm trong đơn hàng, trong khi thông tin khách hàng, vận chuyển và đơn hàng được lặp lại trên nhiều dòng.

**Mục tiêu xử lý dữ liệu:**

- Kiểm tra chất lượng và chuẩn hóa dữ liệu.
- Xác định cấp độ dữ liệu (grain) của từng nhóm thông tin để tránh tính toán sai.
- Thiết kế mô hình dữ liệu phù hợp cho việc phân tích đơn hàng và hiệu quả giao hàng trên Tableau.

## 2. Kiểm tra và chuẩn hóa dữ liệu

Vì là bộ dữ liệu giả lập, DataCo có chất lượng tương đối tốt, ít vấn đề nghiêm trọng về dữ liệu. Tuy nhiên, với **53 cột ban đầu và 40 cột được giữ lại để phân tích**, việc kiểm tra thủ công từng cột sẽ tốn thời gian và dễ lặp lại thao tác.

Vì vậy, **Dynamic SQL** được sử dụng để tự động tạo các câu lệnh kiểm tra cho nhiều cột, tập trung vào 4 khía cạnh chính:

| Khía cạnh | Nội dung |
|---|---|
| **Completeness** | Kiểm tra `NULL` và giá trị trống |
| **Uniqueness** | Kiểm tra số lượng giá trị khác nhau và tính duy nhất của ID |
| **Validity** | Kiểm tra định dạng số, ngày tháng và phạm vi giá trị |
| **Consistency** | Đối chiếu các cột liên quan, bao gồm số tiền, ngày giao hàng và ID sản phẩm |

### Quyết định xử lý chính: Chuẩn hóa dữ liệu địa lý

Thông tin địa điểm của khách hàng và đơn hàng có chung 03 cấp: `country`, `state` và `city`. Vì vậy, dữ liệu có thể được chuẩn hóa để xây dựng một bảng `locations` dùng chung.

Phần lớn địa điểm đã được ghi nhận thống nhất, tuy nhiên vẫn có một số trường hợp cần chuẩn hóa. Chẳng hạn, Hoa Kỳ được ghi là `EE. UU.` trong địa chỉ khách hàng nhưng là `Estados Unidos` đối với địa chỉ đơn hàng. Tên bang cũng được viết tắt ở dữ liệu khách hàng, trong khi dữ liệu đơn hàng sử dụng tên đầy đủ (`CA` – `California`).

Các trường hợp này cần được chuẩn hóa để thuận tiện cho việc xây dựng và liên kết các bảng trong mô hình dữ liệu ở bước tiếp theo.

## 3. Mô hình hóa dữ liệu

### Thiết kế mô hình dữ liệu

Dữ liệu ban đầu gồm 180.516 dòng trong 01 bảng duy nhất, kết hợp thông tin đơn hàng, sản phẩm, khách hàng và vận chuyển. Để thuận tiện cho việc phân tích trên Tableau, dữ liệu được tổ chức lại thành **05 bảng có quan hệ với nhau**.

Mô hình được thiết kế theo hướng hình sao (**Star Schema**), ưu tiên số lượng bảng và mối quan hệ vừa đủ để đáp ứng nhu cầu phân tích, thay vì tách riêng tất cả các nhóm thuộc tính.

<!-- Khi có ảnh mô hình, thay dòng dưới bằng đường dẫn đúng đến tệp ảnh đã tải lên: -->
<!-- ![Mô hình dữ liệu](resources/assets/data_model.png) -->

### Cấp độ dữ liệu (Grain)

Trước khi xây dựng các bảng, dữ liệu được kiểm tra để xác định mỗi dòng đại diện cho đối tượng nào. Cụ thể, các dòng được nhóm theo mã định danh để kiểm tra liệu những thuộc tính dự kiến thuộc cùng một đối tượng có thống nhất hay không.

Một phát hiện quan trọng là doanh thu và lợi nhuận được ghi nhận theo từng dòng sản phẩm, không phải theo đơn hàng như ghi trong từ điển dữ liệu của DataCo. Vì vậy, các chỉ tiêu tài chính được đưa vào bảng `order_items`, trong khi thông tin đơn hàng và vận chuyển được lưu tại bảng `orders`.

**Mô hình cuối cùng gồm 5 bảng:**

| Bảng | Cấp độ dữ liệu |
|---|---|
| `orders` | Một dòng cho mỗi đơn hàng |
| `order_items` | Một dòng cho mỗi sản phẩm trong đơn hàng |
| `products` | Một dòng cho mỗi sản phẩm |
| `customers` | Một dòng cho mỗi khách hàng |
| `locations` | Một dòng cho mỗi tổ hợp quốc gia, bang và thành phố |

### Quyết định nổi bật

**1. Xây dựng bảng `locations` dùng chung**

Thay vì tạo hai bảng địa điểm riêng cho khách hàng và đơn hàng, mô hình sử dụng một bảng `locations` chứa các địa điểm duy nhất từ cả hai nhóm dữ liệu. Các thông tin `market` và `region` được bổ sung từ dữ liệu đơn hàng thông qua việc đối chiếu quốc gia và bang. Một số trường hợp còn thiếu được xử lý riêng.

Cách thiết kế này giúp đồng bộ thông tin địa lý, đồng thời hỗ trợ phân tích theo cả địa điểm khách hàng và địa điểm giao hàng trên Tableau.

**2. Giữ `Category` và `Department` trong bảng `products`**

Thông tin nhóm hàng và ngành hàng được giữ trong bảng `products`, trong khi các thuộc tính vận chuyển được giữ trong bảng `orders`, thay vì tiếp tục tách thành các bảng riêng.

Với quy mô khoảng 181 nghìn dòng và mục tiêu chủ yếu là phân tích trên Tableau, cách tổ chức này giúp mô hình đơn giản hơn, giảm số lượng mối quan hệ cần quản lý mà vẫn đáp ứng các yêu cầu phân tích.

## 4. Hạn chế

Một số giới hạn cần lưu ý:

- Các chênh lệch trong dữ liệu chiết khấu được giữ nguyên do chưa xác định được cách tính từ nguồn dữ liệu.
- `Market` và `Region` được bổ sung cho một số địa điểm dựa trên quy tắc mapping, không phải từ dữ liệu gốc đầy đủ.
- Mô hình được thiết kế phục vụ phân tích trên Tableau, chưa hướng đến xây dựng một hệ thống dữ liệu vận hành hoặc tự động cập nhật.
