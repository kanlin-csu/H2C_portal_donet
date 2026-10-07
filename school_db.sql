-- School 資料庫：用於「資料庫帳號權限過大 → 跨資料庫橫向讀取」教學情境。
-- 跟 H2C_Portal 是同一台 SQL Server 上，完全無關的另一套（虛構）校務系統，
-- 刻意示範 h2c 這個應用程式帳號不該有、卻意外擁有的存取範圍。
-- 所有姓名均為虛構，不對應任何真實存在的人物。

IF DB_ID('School') IS NULL
BEGIN
    CREATE DATABASE [School];
END
GO

USE [School];
GO

IF OBJECT_ID('dbo.Students') IS NOT NULL DROP TABLE dbo.Students;
IF OBJECT_ID('dbo.Employees') IS NOT NULL DROP TABLE dbo.Employees;
GO

CREATE TABLE dbo.Employees (
    EmployeeID  INT PRIMARY KEY,
    Name        NVARCHAR(50)  NOT NULL,
    IDNumber    NVARCHAR(10)  NOT NULL,
    Department  NVARCHAR(50)  NOT NULL,
    Title       NVARCHAR(50)  NOT NULL,
    Email       NVARCHAR(100) NOT NULL,
    Phone       NVARCHAR(20)  NOT NULL,
    Address     NVARCHAR(200) NOT NULL,
    HireDate    DATE          NOT NULL
);
GO

CREATE TABLE dbo.Students (
    StudentID   INT PRIMARY KEY,
    Name        NVARCHAR(50) NOT NULL,
    Major       NVARCHAR(50) NOT NULL,
    Grade       INT          NOT NULL,
    AdvisorID   INT          NULL REFERENCES dbo.Employees(EmployeeID),
    EnrollDate  DATE         NOT NULL,
    BirthDate   DATE         NOT NULL
);
GO

INSERT INTO dbo.Employees (EmployeeID, Name, IDNumber, Department, Title, Email, Phone, Address, HireDate) VALUES
(1001, N'王聖人', N'A198765432', N'校長室',     N'校長',       N'david.chen@school.edu.tw',            N'0910-123-456', N'臺北市信義區市府路1號',          '2015-08-01'),
(1002, N'陳淑芬', N'B287654321', N'教務處',     N'教務主任',    N'meihua.li@school.edu.tw',             N'0920-234-567', N'新北市板橋區中山路一段2號',       '2018-09-01'),
(1003, N'林志遠', N'C376543210', N'總務處',     N'總務主任',    N'zhiming.wang@school.edu.tw',          N'0930-345-678', N'桃園市中壢區中正路3號',          '2016-03-15'),
(1004, N'吳明憲', N'D465432109', N'資訊中心',   N'資訊長',      N'it.chief@school.edu.tw',              N'0940-456-789', N'臺中市西屯區臺灣大道四段4號',      '2019-01-01'),
(1005, N'張家豪', N'E554321098', N'資訊工程系', N'教授',       N'weizhe.zhang@cs.school.edu.tw',       N'0950-567-890', N'臺南市東區大學路5號',            '2012-09-01'),
(1006, N'李宜蓁', N'F643210987', N'資訊工程系', N'副教授',      N'siting.huang@cs.school.edu.tw',       N'0960-678-901', N'高雄市鹽埕區大勇路6號',          '2020-02-10'),
(1007, N'黃柏翰', N'G732109876', N'會計學系',   N'副教授',      N'wenjie.liu@acc.school.edu.tw',        N'0970-789-012', N'新竹市東區光復路7號',            '2017-08-15'),
(1008, N'許雅筑', N'H821098765', N'英語學系',   N'助理教授',    N'yilin.zhou@eng.school.edu.tw',        N'0980-890-123', N'宜蘭縣宜蘭市神農路一段8號',       '2021-09-01'),
(1009, N'蔡明哲', N'I910987654', N'體育組',     N'體育老師',    N'jiaying.wu@sport.school.edu.tw',      N'0911-901-234', N'花蓮縣花蓮市林森路9號',          '2022-03-01'),
(1010, N'鄭文傑', N'J109876543', N'教務處',     N'註冊組組長',  N'guoqiang.xu@school.edu.tw',           N'0922-012-345', N'基隆市中正區義一路10號',         '2019-10-20'),
(1011, N'謝佳玲', N'K298765430', N'總務處',     N'採購專員',    N'liwen.zheng@school.edu.tw',           N'0933-123-456', N'嘉義市西區博愛路11號',           '2023-01-05'),
(1012, N'楊宗翰', N'L387654309', N'資訊中心',   N'網路工程師',  N'zonghan.xie@school.edu.tw',           N'0944-234-567', N'屏東縣屏東市廣東路12號',         '2022-07-01'),
(1013, N'曾淑惠', N'M476543098', N'學務處',     N'生活輔導員',  N'xiaofen.gao@school.edu.tw',           N'0955-345-678', N'彰化縣彰化市中山路一段13號',      '2020-09-01'),
(1014, N'彭俊傑', N'N565432087', N'資訊工程系', N'助理教授',    N'pinxuan.jiang@cs.school.edu.tw',      N'0966-456-789', N'雲林縣斗六市大學路三段14號',      '2024-02-01'),
(1015, N'賴怡君', N'O654321076', N'會計學系',   N'教授',       N'shixian.zhao@acc.school.edu.tw',      N'0977-567-890', N'南投縣南投市中興路15號',         '2014-08-01'),
(1016, N'洪志明', N'P743210965', N'英語學系',   N'講師',       N'junyan.feng@eng.school.edu.tw',       N'0988-678-901', N'苗栗縣苗栗市建華街16號',         '2023-09-01'),
(1017, N'邱雅惠', N'Q832109854', N'體育組',     N'職員',       N'peiwen.luo@sport.school.edu.tw',      N'0919-789-012', N'新北市淡水區英專路17號',         '2024-01-01'),
(1018, N'莊文龍', N'R921098743', N'教務處',     N'課務組職員',  N'wentao.shen@school.edu.tw',           N'0928-890-123', N'臺北市大安區忠孝東路三段18號',     '2021-05-01'),
(1019, N'游淑娟', N'S110987632', N'總務處',     N'出納組職員',  N'yijing.cai@school.edu.tw',            N'0937-901-234', N'桃園市龜山區文化一路19號',        '2020-04-01'),
(1020, N'蕭建宏', N'T209876521', N'圖書館',     N'管理員',      N'zhiwei.huang@library.school.edu.tw',  N'0946-012-345', N'新竹市香山區中華路五段20號',      '2017-03-01');
GO

INSERT INTO dbo.Students (StudentID, Name, Major, Grade, AdvisorID, EnrollDate, BirthDate) VALUES
(2001, N'林柏宇', N'資訊工程', 4, 1005, '2021-09-01', '2003-05-15'),
(2002, N'陳怡婷', N'資訊工程', 3, 1005, '2022-09-01', '2004-02-20'),
(2003, N'王建名', N'資訊工程', 2, 1006, '2023-09-01', '2005-11-01'),
(2004, N'李思涵', N'資訊工程', 1, 1006, '2024-09-01', '2006-12-05'),
(2005, N'黃冠宇', N'資訊工程', 4, 1005, '2021-09-01', '2003-01-01'),
(2006, N'趙欣雨', N'會計學',   3, 1007, '2022-09-01', '2004-08-10'),
(2007, N'吳子軒', N'會計學',   2, 1015, '2023-09-01', '2005-03-22'),
(2008, N'許雨柔', N'會計學',   1, 1007, '2024-09-01', '2006-10-08'),
(2009, N'林宗翰', N'會計學',   4, 1015, '2021-09-01', '2003-07-19'),
(2010, N'周庭宇', N'會計學',   3, 1007, '2022-09-01', '2004-04-16'),
(2011, N'方逸辰', N'英語學',   2, 1008, '2023-09-01', '2005-09-28'),
(2012, N'江佩珊', N'英語學',   1, 1016, '2024-09-01', '2006-01-30'),
(2013, N'羅宇軒', N'英語學',   4, 1008, '2021-09-01', '2003-11-11'),
(2014, N'楊子萱', N'英語學',   3, 1016, '2022-09-01', '2004-06-04'),
(2015, N'劉冠廷', N'電機工程', 4, 1005, '2021-09-01', '2003-09-27'),
(2016, N'蔡佳穎', N'工業設計', 3, 1007, '2022-09-01', '2004-12-19'),
(2017, N'張雅涵', N'藝術學',   2, 1015, '2023-09-01', '2005-07-03'),
(2018, N'伍宗憲', N'機械工程', 1, 1008, '2024-09-01', '2006-04-14'),
(2019, N'蘇柏誠', N'心理學',   3, 1006, '2022-09-01', '2004-03-03'),
(2020, N'吳宗翰', N'建築學',   4, 1015, '2021-09-01', '2003-10-25');
GO
