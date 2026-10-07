<#
.SYNOPSIS
    一鍵部署 H2C Portal 到全新的 Windows Server 2022 上。
    以系統管理員身分執行。

.NOTES
    前置條件（SQL Server 請手動安裝好，不在本腳本自動化範圍內）：
      - 執行個體選 Default instance（不要用 SQLEXPRESS 具名執行個體，
        連線字串用的是 127.0.0.1，沒有具名後綴）
      - Authentication Mode 選 Mixed Mode（SQL Server + Windows 驗證）
      - SQL Server 組態管理員 → 網路組態 → TCP/IP 設為「已啟用」，
        改完要重啟 SQL Server 服務生效

    跑完之後站台會在 http://localhost/Default.aspx（IIS 預設網站 port 80）。
    h2c 這個 DB 帳號故意給過大權限（H2C_Portal + School 都能讀寫）——
    這是這個 LAB 的教學設計，不是腳本的 bug，不要「順手」幫它收斂權限。
#>

param(
    [string]$RepoUrl = "https://github.com/kanlin-csu/H2C_portal_donet.git",
    [string]$SitePath = "C:\myweb\H2C_Portal",
    [string]$SqlInstance = "127.0.0.1",
    [string]$DbUser = "h2c",
    [string]$DbPass = "h2c"
)

$ErrorActionPreference = "Stop"

# Windows PowerShell 5.1 預設主控台輸出編碼是系統 OEM 代碼頁（繁中版是 cp950），
# 不是 UTF-8，不設這行的話中文 Write-Host/Write-Warning 會印成亂碼
# （這跟檔案本身的 UTF-8 BOM 是兩回事：BOM 管「怎麼讀檔」，這行管「怎麼印到主控台」）。
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "== 1) 安裝 IIS + 必要角色服務（含 Classic ASP）==" -ForegroundColor Cyan
Install-WindowsFeature -Name Web-Server, Web-Asp-Net45, Web-ASP, Web-CGI, `
    Web-Mgmt-Console, Web-Static-Content, Web-Default-Doc, Web-Http-Errors, `
    Web-Http-Logging -IncludeManagementTools

Write-Host "== 2) 確認 .NET Framework 4.8（Server 2022 通常內建）==" -ForegroundColor Cyan
$release = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue).Release
if ($release -lt 528040) {
    Write-Warning ".NET Framework 4.8 未偵測到，請手動安裝 dotnet-framework-4.8 後重跑本腳本。"
    exit 1
}

Write-Host "== 3) 確認 SQL Server 連得上（請先手動安裝好，見檔案開頭 .NOTES）==" -ForegroundColor Cyan
sqlcmd -S $SqlInstance -Q "SELECT 1"
if ($LASTEXITCODE -ne 0) {
    Write-Warning "連不到 SQL Server（$SqlInstance，結束碼 $LASTEXITCODE）。請確認：已手動安裝、Mixed Mode 驗證、TCP/IP 已啟用且已重啟服務。"
    exit 1
}

Write-Host "== 4) Clone 原始碼 ==" -ForegroundColor Cyan
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Warning "找不到 git，請先安裝 Git for Windows。"
    exit 1
}
if (Test-Path $SitePath) {
    Write-Warning "$SitePath 已存在，略過 clone（如需乾淨重拉，先手動刪除這個資料夾）"
} else {
    git clone $RepoUrl $SitePath
}

Write-Host "== 5) 建立資料庫（H2C_Portal + School）與 h2c 登入帳號 ==" -ForegroundColor Cyan

# sqlcmd 是外部執行檔，$ErrorActionPreference = "Stop" 管不到它——
# 一定要自己檢查 $LASTEXITCODE，不然失敗了腳本還是會往下跑，留下一個看起來「裝完」但資料庫其實是空的爛攤子。
function Invoke-SqlStep {
    param([string]$Description, [scriptblock]$Action)
    & $Action
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "$Description 失敗（sqlcmd 結束碼 $LASTEXITCODE），往上看 sqlcmd 自己印出的錯誤訊息。"
        exit 1
    }
}

Invoke-SqlStep "匯入 db.sql" { sqlcmd -S $SqlInstance -i "$SitePath\db.sql" }
Invoke-SqlStep "匯入 school_db.sql" { sqlcmd -S $SqlInstance -i "$SitePath\school_db.sql" }

$createLoginSql = @"
IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = '$DbUser')
BEGIN
    CREATE LOGIN [$DbUser] WITH PASSWORD = '$DbPass', CHECK_POLICY = OFF;
END
USE [H2C_Portal];
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '$DbUser')
    CREATE USER [$DbUser] FOR LOGIN [$DbUser];
ALTER ROLE db_owner ADD MEMBER [$DbUser];
USE [School];
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '$DbUser')
    CREATE USER [$DbUser] FOR LOGIN [$DbUser];
ALTER ROLE db_owner ADD MEMBER [$DbUser];
"@
Invoke-SqlStep "建立 $DbUser 登入帳號" { $createLoginSql | sqlcmd -S $SqlInstance }

Write-Host "確認 $DbUser 帳號真的建好了..." -ForegroundColor Cyan
$verify = sqlcmd -S $SqlInstance -h -1 -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.sql_logins WHERE name = '$DbUser'"
if (($verify -join "").Trim() -ne "1") {
    Write-Warning "$DbUser 登入帳號驗證失敗，沒有真的建立成功，檢查上面的錯誤訊息。"
    exit 1
}

Write-Host "== 6) 設定 IIS 網站 / 應用程式集區 ==" -ForegroundColor Cyan
Import-Module WebAdministration

if (-not (Test-Path "IIS:\AppPools\H2CPortal")) {
    New-WebAppPool -Name "H2CPortal"
}
Set-ItemProperty "IIS:\AppPools\H2CPortal" -Name managedRuntimeVersion -Value "v4.0"

if (Get-Website -Name "Default Web Site" -ErrorAction SilentlyContinue) {
    Set-ItemProperty "IIS:\Sites\Default Web Site" -Name physicalPath -Value $SitePath
    Set-ItemProperty "IIS:\Sites\Default Web Site" -Name applicationPool -Value "H2CPortal"
} else {
    New-Website -Name "H2CPortal" -PhysicalPath $SitePath -ApplicationPool "H2CPortal" -Port 80 -Force
}

Write-Host "== 7) 確認 web.config 連線字串 ==" -ForegroundColor Cyan
$webConfigPath = Join-Path $SitePath "web.config"
$expected = "Data Source=$SqlInstance;Initial Catalog=H2C_Portal;User ID=$DbUser;Password=$DbPass;Integrated Security=False"
Write-Host "請確認 $webConfigPath 裡的 connectionString 符合：`n  $expected"

Write-Host "`n完成。開瀏覽器測 http://localhost/Default.aspx" -ForegroundColor Green
Write-Host "測試帳密：test / test（一般使用者，README 裡的 sysadmin 密碼已改過，請用資料庫裡實際的 PasswordHash 對應值登入）"
