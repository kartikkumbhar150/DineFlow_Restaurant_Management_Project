# 🏨 DineFlow – Restaurant & Hotel Management System

DineFlow is a robust restaurant management software designed to digitize order handling, table allocation, billing, inventory tracking, and staff management.  
The system enables restaurants to manage operations efficiently and transparently with minimal manual effort.

---

## 🌟 Key Outcomes
- 🚀 Faster order processing  
- 🎯 Zero manual billing errors  
- 🪑 Smart real-time table tracking  
- 📄 Automated invoice generation  
- 👨‍🍳 Live KOT updates from kitchen  
- 📊 Sales analytics for decision-making  

---

---

# 🔐 Authentication & Access Management

### 💡 Features
- OTP-based signup & login  
- Password reset using OTP  
- Role-based authentication (Admin, Waiter, Staff)  
- Secure onboarding  

### 🔗 Authentication APIs

| Action | Method | Endpoint |
|--------|---------|----------|
| Send OTP | POST | `/api/v1/auth/otp/send` |
| Verify OTP | POST | `/api/v1/auth/otp/verify` |
| Register Business Admin | POST | `/api/v1/auth/register` |
| Login | POST | `/api/v1/auth/login` |
| Forgot-Password (Send OTP) | POST | `/api/v1/auth/forgot-password/otp/send` |
| Verify Forgot Password OTP | POST | `/api/v1/auth/forgot-password/otp/verify` |
| Change Password | PUT | `/api/v1/auth/change-password` |

---

---

# 🏢 Business Setup & Profile

### 💡 Features
- Register restaurant and owner details  
- Add GST number, FSSAI number, license number  
- Upload business logo  
- Define table count  
- Fetch profile dashboard  

### 🔗 Business APIs

| Action | Method | Endpoint |
|--------|---------|----------|
| Register Business | POST | `/api/v1/business` |
| Get Business Info | GET | `/api/v1/business` |
| Fetch Business Dashboard | GET | `/api/v1/business/dashboard/showMe` |

### ⭐ Why Important?
- Eliminates offline registration paperwork  
- Standardized restaurant identity  
- Easier expansion to multiple branches  

---

---

# 🍽 Menu & Product Management

### 💡 Features
- Create & categorize menu items  
- Update & delete items anytime  
- Add item images  
- Bulk upload from scanned product sheet  

### 🔗 Product APIs

| Action | Method | Endpoint |
|--------|---------|----------|
| Add Product | POST | `/api/v1/products` |
| Get All Products | GET | `/api/v1/products` |
| Get Product by ID | GET | `/api/v1/products/{id}` |
| Update Product | PUT | `/api/v1/products/{id}` |
| Delete Product | DELETE | `/api/v1/products/{id}` |
| Upload Bulk Product Sheet | POST | `/api/v1/products/bulk/upload` |
| Save Bulk Items | POST | `/api/v1/products/bulk/save` |

### ⭐ Business Benefits
- No printed menu required  
- Seasonal changes in 1 click  
- Faster onboarding for large menus  

---

---

# 🧾 Orders & Table-Wise Management

### 💡 Features
- Create order linked with table  
- Modify ongoing orders  
- Add/remove products anytime  
- Delete incorrect orders  

### 🔗 Order APIs

| Action | Method | Endpoint |
|--------|---------|----------|
| Create Order | POST | `/api/v1/orders` |
| Update Existing Order | PUT | `/api/v1/orders/{id}` |
| View Order | GET | `/api/v1/orders/{id}` |
| Delete Order | DELETE | `/api/v1/orders/{id}` |

### ⭐ Operational Impact
- Replaces handwritten orders  
- Avoids miscommunication  
- Supports multiple tables simultaneously  

---

---

# 🪑 Live Table Status Management

### 💡 Features
- Track each table’s status
- Live streaming for dashboard  
- Auto-release table when invoice is generated  

### 🔗 Table APIs

| Action | Method | Endpoint |
|--------|---------|----------|
| Get All Status | GET | `/api/v1/table-status` |
| Get Status By Table | GET | `/api/v1/table-status/{id}` |
| Live Status Stream (All) | GET | `/api/v1/table-status/stream` |
| Live Status Stream (Single) | GET | `/api/v1/table-status/stream/{id}` |

---

---

# 👨‍🍳 KOT – Kitchen Order Ticket

### 💡 Features
- Live updates for kitchen staff  
- Mark items as completed  
- Pending vs Completed queues  

### 🔗 KOT APIs

| Action | Method | Endpoint |
|--------|---------|----------|
| Live KOT Stream | GET | `/api/v1/kot/stream` |
| Mark Order Completed | POST | `/api/v1/kot/mark-complete` |
| View Pending Items | GET | `/api/v1/kot/pending` |
| View Completed Items | GET | `/api/v1/kot/completed` |

---

---

# 🧾 Invoice & Billing Management

### 💡 Features
- Auto-calculate total amount  
- Free table once invoice is generated  
- View invoice history  

### 🔗 Invoice APIs

| Action | Method | Endpoint |
|--------|---------|----------|
| Generate Invoice | POST | `/api/v1/invoices` |
| Get Invoice by Number | GET | `/api/v1/invoices/{invoiceNumber}` |
| Get All Invoices | GET | `/api/v1/invoices` |

### ⭐ Real-World Advantage
- No calculation errors  
- Faster bill clearance  
- Reduced customer waiting  

---

---

# 🧑‍🤝‍🧑 Staff Management

### 💡 Features
- Add staff users  
- Modify profile & roles  
- Remove access anytime  

### 🔗 Staff APIs

| Action | Method | Endpoint |
|--------|---------|----------|
| Add Staff | POST | `/api/v1/staff` |
| View All Staff | GET | `/api/v1/staff` |
| Get Staff By ID | GET | `/api/v1/staff/{id}` |
| Update Staff | PUT | `/api/v1/staff/{id}` |
| Delete Staff | DELETE | `/api/v1/staff/{id}` |

---

---

# 📦 Inventory Management

### 💡 Features
- Item name, quantity, unit, and price  
- Bulk upload purchasing  
- Maintain kitchen stock history  

### 🔗 Inventory APIs

| Action | Method | Endpoint |
|--------|---------|----------|
| View Inventory | GET | `/api/v1/inventory` |
| Add Item | POST | `/api/v1/inventory/add` |
| Bulk Add Items | POST | `/api/v1/inventory/add-bulk` |

---

---

# 📊 Reporting & Sales Analytics

### 🔗 Reporting APIs

| Report Type | Method | Endpoint |
|-------------|---------|----------|
| Most Selling Items | GET | `/api/v1/report/most-selling-items` |
| Date Range Summary | POST | `/api/v1/report/summary-range` |
| Last 7 Days Revenue | GET | `/api/v1/report/last7days-sales` |
| Time Slot Sales (24 hrs) | GET | `/api/v1/report/last7days-timeslots` |
| Live Sales Amount | GET | `/api/v1/sales/live` |

### 💡 Usage
- Report-based business planning  
- Identifying low-performing dishes  
- Taxation-ready transaction data  

---

---

# 🎯 Why Restaurants Prefer DineFlow

### ⚡ Operational Benefits
✔ Real live tracking  
✔ No manual errors  
✔ Faster service delivery  

### 💰 Business Insights
✔ Revenue visibility  
✔ Inventory optimization  
✔ Peak hour analytics  

### 😀 Customer Experience Benefits
✔ Faster checkouts  
✔ Accurate billing  
✔ Quick table allotment  

---

✨ DineFlow ultimately improves restaurant efficiency, transparency, and profitability through modern digital operations.
