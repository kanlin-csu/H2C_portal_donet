-- 1. 建立資料庫 (如果不存在)
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'H2C_Portal')
BEGIN
    CREATE DATABASE [H2C_Portal];
END
GO

USE [H2C_Portal];
GO

-- 2. 刪除舊表
IF OBJECT_ID('Salaries') IS NOT NULL DROP TABLE Salaries;
IF OBJECT_ID('News') IS NOT NULL DROP TABLE News;
IF OBJECT_ID('Employees') IS NOT NULL DROP TABLE Employees;
IF OBJECT_ID('Users') IS NOT NULL DROP TABLE Users;
GO

-- 3. 建立 Users 表 (UserID: 1001, 1002, ...)
CREATE TABLE Users (
    UserID INT IDENTITY(1001, 1) PRIMARY KEY,
    Username NVARCHAR(50) UNIQUE NOT NULL,
    PasswordHash NVARCHAR(128) NOT NULL,
    Role NVARCHAR(10) NOT NULL 
);
GO

-- 4. 建立 Employees 表 (EmployeeID: 2001, 2002, ...)
CREATE TABLE Employees (
    EmployeeID INT IDENTITY(2001, 1) PRIMARY KEY,
    UserID INT UNIQUE NOT NULL, -- 邏輯關聯欄位 (UserID)
    Name NVARCHAR(50) NOT NULL,
    Title NVARCHAR(50) NOT NULL,
    PhotoPath NVARCHAR(255) NULL
);
GO

-- 5. 建立 News 表 (AuthorID 關聯 UserID)
CREATE TABLE News (
    NewsID INT IDENTITY(3001, 1) PRIMARY KEY,
    Title NVARCHAR(100) NOT NULL,
    Content NVARCHAR(MAX) NOT NULL, 
    AuthorID INT NOT NULL, -- 邏輯關聯欄位 (UserID)
    PostDate DATETIME DEFAULT GETDATE()
);
GO

-- 6. 建立 Salaries 表 (EmployeeID 關聯 EmployeeID)
CREATE TABLE Salaries (
    SalaryID INT IDENTITY(4001, 1) PRIMARY KEY,
    EmployeeID INT UNIQUE NOT NULL, -- 邏輯關聯欄位 (EmployeeID/UserID)
    MonthlySalary DECIMAL(10, 2) NOT NULL,
    Bonus DECIMAL(10, 2) NOT NULL,
    LastUpdated DATE DEFAULT GETDATE()
);
GO

-- 7. 插入使用者資料 (UserID: 1001 ~ 1007)
INSERT INTO Users (Username, PasswordHash, Role) VALUES
(N'sysadmin', N'H2C2025', N'Admin'),     -- 1001
(N'sales.wang', N'H2C2025', N'User'),    -- 1002
(N'rd.li', N'H2C2025', N'User'),         -- 1003
(N'hr.chen', N'H2C2025', N'User'),        -- 1004
(N'finance.lin', N'H2C2025', N'User'),   -- 1005
(N'dev.zhao', N'H2C2025', N'User'),      -- 1006
(N'testacc', N'H2C2025', N'User');       -- 1007

-- 8. 插入員工資料 (手動確保 UserID 欄位與 EmployeeID 欄位一致)
SET IDENTITY_INSERT Employees ON; 
INSERT INTO Employees (EmployeeID, UserID, Name, Title, PhotoPath) VALUES
(1001, 1001, N'林大維', N'系統架構師', N'uploads/david_lin.jpg'),
(1002, 1002, N'王明華', N'業務經理', N'uploads/minghua_wang.png'),
(1003, 1003, N'李思遠', N'資深工程師', N'uploads/siyuan_li.jpg'),
(1004, 1004, N'陳芳儀', N'人資專員', N'uploads/fangyi_chen.png'),
(1005, 1005, N'林雅惠', N'會計主管', N'uploads/yahui_lin.jpg'),
(1006, 1006, N'趙小開', N'初級開發', N'uploads/xiaokai_zhao.jpg');
SET IDENTITY_INSERT Employees OFF;

-- 9. 插入薪資資料 (EmployeeID: 1001 ~ 1006)
INSERT INTO Salaries (EmployeeID, MonthlySalary, Bonus, LastUpdated) VALUES
(1001, 180000.00, 300000.00, GETDATE()), 
(1002, 75000.00, 150000.00, GETDATE()),  
(1003, 85000.00, 180000.00, GETDATE()),  
(1004, 45000.00, 50000.00, GETDATE()),   
(1005, 120000.00, 250000.00, GETDATE()), 
(1006, 38000.00, 30000.00, GETDATE());   

-- 10. 插入消息資料 (AuthorID/UserID: 1001 ~ 1006)
INSERT INTO News (Title, Content, AuthorID, PostDate) VALUES
(N'【重要】2025年度系統維護通知', N'伺服器將於本週六凌晨進行硬體升級。屆時 Portal 服務將暫停約 4 小時。', 1001, DATEADD(hour, -10, GETDATE())),
(N'業務部 Q3 績效報告會議', N'所有業務同仁請注意，本季績效總結會議將於 11/20 (三) 下午兩點舉行，請準備好您的資料。', 1002, DATEADD(day, -2, GETDATE())),
(N'研發部門技術分享：資安基礎', N'本週五下午三點，李思遠工程師將分享 Web 安全開發的基礎知識。歡迎報名參加。', 1003, DATEADD(hour, -3, GETDATE())),
(N'**部門專用：內部備忘**', N'這個公告只供研發部門內部查閱。請測試人員注意：該欄位未經過濾，請勿輸入惡意腳本。', 1003, DATEADD(hour, -2, GETDATE())),
(N'財務報銷流程調整', N'自下個月起，所有報銷請透過新版電子表單系統提交。詳情請參閱附件。', 1005, DATEADD(day, -5, GETDATE())),
(N'新人訓練營報名截止', N'人資部提醒：所有新進同仁的職前訓練課程將於明日截止報名。逾期者請洽詢人資陳專員。', 1004, DATEADD(day, -1, GETDATE())),
(N'【公告】新版使用者手冊發布', N'新版 H2C Portal 使用者手冊已上線，您可以嘗試使用 LFI 技巧來讀取它。', 1001, DATEADD(hour, -1, GETDATE())),
(N'開發日誌 #01：程式碼審查', N'今天審查了 IDOR 相關的程式碼，看起來還沒修好。請大家注意保護數據。', 1006, DATEADD(hour, -4, GETDATE()));

-- 11. 驗證資料
SELECT * FROM Users;
SELECT * FROM Employees;
SELECT * FROM Salaries;
SELECT * FROM News;