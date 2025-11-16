# H2C Portal CTF 靶場

這是一個 ASP.NET Web Forms 的 CTF 練習平台，包含多種常見的 Web 安全漏洞。

## 功能特色

- **SQL Injection (SQLi)** - 登入功能中的 SQL 注入漏洞
- **Cross-Site Scripting (XSS)** - 消息發布功能中的儲存型 XSS 漏洞
- **Insecure Direct Object Reference (IDOR)** - 員工詳情和消息刪除功能中的 IDOR 漏洞
- **Local File Inclusion (LFI)** - 圖片處理功能中的路徑遍歷漏洞
- **Arbitrary File Upload** - 檔案上傳功能中的任意檔案上傳漏洞

## 技術架構

- **框架**: ASP.NET Web Forms (.NET Framework 4.8)
- **資料庫**: SQL Server
- **前端**: Bootstrap 5.3.0
- **編碼**: UTF-8

## 資料庫結構

請參考專案中的 SQL 腳本建立資料庫和表結構。

## 安裝說明

1. 確保已安裝 .NET Framework 4.8
2. 建立 SQL Server 資料庫並執行初始化腳本
3. 修改 `web.config` 中的資料庫連接字串
4. 部署到 IIS 或使用 Visual Studio 運行

## 注意事項

- 此專案僅供 CTF 練習使用
- 所有漏洞均為故意設計，請勿用於生產環境
- 文件編碼為 UTF-8，請確保編輯器正確識別

