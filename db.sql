-- 1. 建立資料庫 (如果不存在)
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'School')
BEGIN
    CREATE DATABASE [School];
END
GO

USE [School];
GO

-- 2. 刪除舊表
IF OBJECT_ID('Students') IS NOT NULL DROP TABLE Students;
IF OBJECT_ID('Employees') IS NOT NULL DROP TABLE Employees;
GO

-- 3. 建立 Employees 表 (教職員工)
CREATE TABLE Employees (
    EmployeeID INT IDENTITY(1001, 1) PRIMARY KEY, -- 教職員工 ID
    Name NVARCHAR(50) NOT NULL,
    Department NVARCHAR(50) NOT NULL, -- 部門 (教務處, 總務處, 資訊中心, 體育組)
    Title NVARCHAR(50) NOT NULL,      -- 職位 (校長, 主任, 老師, 職員)
    Email NVARCHAR(100) UNIQUE NOT NULL,
    HireDate DATE NOT NULL
);
GO

-- 4. 建立 Students 表 (學生)
CREATE TABLE Students (
    StudentID INT IDENTITY(2001, 1) PRIMARY KEY, -- 學生 ID
    Name NVARCHAR(50) NOT NULL,
    Major NVARCHAR(50) NOT NULL,      -- 主修 (科系)
    Grade INT NOT NULL,               -- 年級 (1, 2, 3, 4)
    AdvisorID INT,                    -- 指導教授/導師 ID (邏輯關聯 Employees.EmployeeID)
    EnrollDate DATE NOT NULL,
    BirthDate DATE NOT NULL
);
GO

-- 5. 插入 Employees 測試資料 (20 組)
INSERT INTO Employees (Name, Department, Title, Email, HireDate) VALUES
-- 核心管理層 (1001-1004)
(N'陳大為', N'校長室', N'校長', N'david.chen@school.edu.tw', '2015-08-01'), 
(N'李美華', N'教務處', N'教務主任', N'meihua.li@school.edu.tw', '2018-09-01'), 
(N'王志明', N'總務處', N'總務主任', N'zhiming.wang@school.edu.tw', '2016-03-15'), 
(N'林雅雯', N'資訊中心', N'資訊長', N'it.chief@school.edu.tw', '2019-01-01'), 

-- 教師及行政人員 (1005-1020)
(N'張偉哲', N'資訊工程系', N'教授', N'weizhe.zhang@cs.school.edu.tw', '2012-09-01'), 
(N'黃思婷', N'資訊工程系', N'副教授', N'siting.huang@cs.school.edu.tw', '2020-02-10'), 
(N'劉文傑', N'會計學系', N'副教授', N'wenjie.liu@acc.school.edu.tw', '2017-08-15'), 
(N'周依琳', N'英語學系', N'助理教授', N'yilin.zhou@eng.school.edu.tw', '2021-09-01'), 
(N'吳佳穎', N'體育組', N'體育老師', N'jiaying.wu@sport.school.edu.tw', '2022-03-01'), 
(N'許國強', N'教務處', N'註冊組組長', N'guoqiang.xu@school.edu.tw', '2019-10-20'), 
(N'鄭麗雯', N'總務處', N'採購專員', N'liwen.zheng@school.edu.tw', '2023-01-05'), 
(N'謝宗翰', N'資訊中心', N'網路工程師', N'zonghan.xie@school.edu.tw', '2022-07-01'), 
(N'高小芬', N'學務處', N'生活輔導員', N'xiaofen.gao@school.edu.tw', '2020-09-01'), 
(N'江品萱', N'資訊工程系', N'助理教授', N'pinxuan.jiang@cs.school.edu.tw', '2024-02-01'), 
(N'趙士賢', N'會計學系', N'教授', N'shixian.zhao@acc.school.edu.tw', '2014-08-01'), 
(N'馮俊彥', N'英語學系', N'講師', N'junyan.feng@eng.school.edu.tw', '2023-09-01'), 
(N'羅佩雯', N'體育組', N'職員', N'peiwen.luo@sport.school.edu.tw', '2024-01-01'), 
(N'沈文濤', N'教務處', N'課務組職員', N'wentao.shen@school.edu.tw', '2021-05-01'), 
(N'蔡宜靜', N'總務處', N'出納組職員', N'yijing.cai@school.edu.tw', '2020-04-01'), 
(N'黃志偉', N'圖書館', N'管理員', N'zhiwei.huang@library.school.edu.tw', '2017-03-01');

-- 6. 插入 Students 測試資料 (20 組)
INSERT INTO Students (Name, Major, Grade, AdvisorID, EnrollDate, BirthDate) VALUES
-- 資訊工程系 (AdvisorID: 1005 張偉哲, 1006 黃思婷)
(N'林小光', N'資訊工程', 4, 1005, '2021-09-01', '2003-05-15'), -- 2001
(N'陳雅琳', N'資訊工程', 3, 1005, '2022-09-01', '2004-02-20'),
(N'王大明', N'資訊工程', 2, 1006, '2023-09-01', '2005-11-01'),
(N'李佳蓉', N'資訊工程', 1, 1006, '2024-09-01', '2006-12-05'),
(N'黃思遠', N'資訊工程', 4, 1005, '2021-09-01', '2003-01-01'),

-- 會計學系 (AdvisorID: 1007 劉文傑, 1015 趙士賢)
(N'趙心怡', N'會計學', 3, 1007, '2022-09-01', '2004-08-10'),
(N'吳宗憲', N'會計學', 2, 1015, '2023-09-01', '2005-03-22'),
(N'許美惠', N'會計學', 1, 1007, '2024-09-01', '2006-10-08'),
(N'林俊傑', N'會計學', 4, 1015, '2021-09-01', '2003-07-19'),
(N'周杰倫', N'會計學', 3, 1007, '2022-09-01', '2004-04-16'),

-- 英語學系 (AdvisorID: 1008 周依琳, 1016 馮俊彥)
(N'方文山', N'英語學', 2, 1008, '2023-09-01', '2005-09-28'),
(N'江蕙', N'英語學', 1, 1016, '2024-09-01', '2006-01-30'),
(N'羅志祥', N'英語學', 4, 1008, '2021-09-01', '2003-11-11'),
(N'楊丞琳', N'英語學', 3, 1016, '2022-09-01', '2004-06-04'),

-- 其他學系及混合年級
(N'劉德華', N'電機工程', 4, 1005, '2021-09-01', '2003-09-27'),
(N'蔡依林', N'工業設計', 3, 1007, '2022-09-01', '2004-12-19'),
(N'張惠妹', N'藝術學', 2, 1015, '2023-09-01', '2005-07-03'),
(N'伍佰', N'機械工程', 1, 1008, '2024-09-01', '2006-04-14'),
(N'蘇打綠', N'心理學', 3, 1006, '2022-09-01', '2004-03-03'),
(N'五月天', N'建築學', 4, 1015, '2021-09-01', '2003-10-25'); -- 2020

-- 7. 驗證資料
SELECT * FROM Employees;
SELECT * FROM Students;