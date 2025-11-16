<%@ Page Language="C#" AutoEventWireup="true" ResponseEncoding="UTF-8" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>

<script runat="server">
    // DBHelper 靜態類別
    public static class DBHelper
    {
        public static string ConnectionString
        {
            get
            {
                return ConfigurationManager.ConnectionStrings["H2C_Portal_DB"].ConnectionString;
            }
        }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        if (Session["Role"] == null)
        {
            Response.Redirect("Default.aspx");
        }
    }

    private int GetEmployeeIdByUserId(int userId)
    {
        string sql = "SELECT EmployeeID FROM Employees WHERE UserID = @userId";
        using (SqlConnection conn = new SqlConnection(DBHelper.ConnectionString))
        {
            SqlCommand cmd = new SqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@userId", userId);
            conn.Open();
            object result = cmd.ExecuteScalar();
            if (result != null)
            {
                return Convert.ToInt32(result);
            }
        }
        return 0;
    }

    // 🚨 這是任意檔案上傳的漏洞點 🚨
    protected void btnUpload_Click(object sender, EventArgs e)
    {
        if (fileUploader.HasFile)
        {
            string originalFileName = fileUploader.FileName;
            string extension = Path.GetExtension(originalFileName).ToLower();
            string savePath = Server.MapPath("~/uploads/");

            // 檢查目錄是否存在
            if (!Directory.Exists(savePath))
            {
                Directory.CreateDirectory(savePath);
            }

            // ❌ 僅禁止上傳 .aspx 檔案，其餘檔案類型皆允許
            // 攻擊者仍可上傳其他可執行檔案（如 .php, .jsp, .asp 等）
            if (extension == ".aspx")
            {
                lblUploadMessage.Text = "上傳失敗：禁止上傳 .aspx 檔案！";
                lblUploadMessage.CssClass = "alert alert-danger";
                return;
            }

            // 取得當前登入用戶的員工編號
            int userId = Convert.ToInt32(Session["UserID"]);
            int employeeId = GetEmployeeIdByUserId(userId);

            if (employeeId <= 0)
            {
                lblUploadMessage.Text = "上傳失敗：找不到您的員工資料。";
                lblUploadMessage.CssClass = "alert alert-danger";
                return;
            }

            // 將檔名改為員工編號，保留副檔名
            string newFileName = employeeId.ToString() + extension;
            string fullPath = Path.Combine(savePath, newFileName);

            try
            {
                fileUploader.SaveAs(fullPath);
                
                // 更新資料庫中的照片路徑
                UpdateEmployeePhotoPath(employeeId, "uploads/" + newFileName);
                
                lblUploadMessage.Text = "檔案上傳成功！檔名: " + newFileName;
                lblUploadMessage.CssClass = "alert alert-success";
            }
            catch (Exception ex)
            {
                lblUploadMessage.Text = "檔案上傳失敗: " + ex.Message;
                lblUploadMessage.CssClass = "alert alert-danger";
            }
        }
        else
        {
            lblUploadMessage.Text = "請選擇一個檔案。";
            lblUploadMessage.CssClass = "alert alert-warning";
        }
    }

    private void UpdateEmployeePhotoPath(int employeeId, string photoPath)
    {
        string sql = "UPDATE Employees SET PhotoPath = @PhotoPath WHERE EmployeeID = @EmployeeID";
        using (SqlConnection conn = new SqlConnection(DBHelper.ConnectionString))
        {
            SqlCommand cmd = new SqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@PhotoPath", photoPath);
            cmd.Parameters.AddWithValue("@EmployeeID", employeeId);
            conn.Open();
            cmd.ExecuteNonQuery();
        }
    }

    protected void btnLogout_Click(object sender, EventArgs e)
    {
        Session.Clear();
        Session.Abandon();
        Response.Redirect("Default.aspx");
    }
</script>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>檔案上傳</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet" />
    <style>
        body {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            font-family: 'Microsoft JhengHei', '微軟正黑體', Arial, sans-serif;
        }
        .navbar {
            background: rgba(255, 255, 255, 0.95) !important;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .main-container {
            margin-top: 2rem;
        }
        .card {
            border: none;
            border-radius: 15px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.1);
            margin-bottom: 2rem;
        }
        .card-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 15px 15px 0 0 !important;
            padding: 1.5rem;
        }
        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border: none;
            border-radius: 8px;
        }
        .upload-area {
            border: 2px dashed #667eea;
            border-radius: 10px;
            padding: 3rem;
            text-align: center;
            background: #f8f9fa;
            transition: all 0.3s;
        }
        .upload-area:hover {
            background: #e9ecef;
            border-color: #764ba2;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <!-- 導航選單 -->
        <nav class="navbar navbar-expand-lg navbar-light">
            <div class="container">
                <a class="navbar-brand fw-bold" href="Default.aspx">
                    <i class="bi bi-shield-check"></i> H2C 練習平台
                </a>
                <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                    <span class="navbar-toggler-icon"></span>
                </button>
                <div class="collapse navbar-collapse" id="navbarNav">
                    <ul class="navbar-nav ms-auto">
                        <li class="nav-item">
                            <a class="nav-link" href="Default.aspx">
                                <i class="bi bi-house-door"></i> 首頁
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="EmployeeList.aspx">
                                <i class="bi bi-people"></i> 員工管理
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="NewsPost.aspx">
                                <i class="bi bi-newspaper"></i> 消息管理
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link active" href="FileUpload.aspx">
                                <i class="bi bi-upload"></i> 檔案上傳
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="SalaryQuery.aspx">
                                <i class="bi bi-cash-coin"></i> 薪資查詢
                            </a>
                        </li>
                        <% if (Session["Role"] != null && Session["Role"].ToString() == "Admin") { %>
                        <li class="nav-item">
                            <a class="nav-link" href="UserManagement.aspx">
                                <i class="bi bi-person-gear"></i> 帳號管理
                            </a>
                        </li>
                        <% } %>
                        <li class="nav-item">
                            <span class="nav-link text-muted">
                                <i class="bi bi-person-circle"></i> 
                                <%= Session["Username"] %> (<%= Session["Role"] %>)
                            </span>
                        </li>
                        <li class="nav-item">
                            <asp:LinkButton ID="btnLogout" runat="server" OnClick="btnLogout_Click" CssClass="nav-link text-danger">
                                <i class="bi bi-box-arrow-right"></i> 登出
                            </asp:LinkButton>
                        </li>
                    </ul>
                </div>
            </div>
        </nav>

        <div class="container main-container">
            <div class="row justify-content-center">
                <div class="col-lg-8">
                    <div class="card">
                        <div class="card-header">
                            <h4 class="mb-0"><i class="bi bi-cloud-upload"></i> 員工照片上傳 (任意檔案上傳靶場)</h4>
                        </div>
                        <div class="card-body p-4">
                            <asp:Label ID="lblUploadMessage" runat="server" CssClass="alert d-block mb-3" Visible="false"></asp:Label>
                            
                            <div class="upload-area mb-4">
                                <i class="bi bi-cloud-upload" style="font-size: 4rem; color: #667eea;"></i>
                                <h5 class="mt-3 mb-3">選擇檔案上傳</h5>
                                <asp:FileUpload ID="fileUploader" runat="server" CssClass="form-control" />
                                <p class="text-muted mt-3 small">
                                    <i class="bi bi-info-circle"></i> 禁止上傳: .aspx 檔案，檔名會自動改為您的員工編號
                                </p>
                            </div>
                            
                            <div class="d-grid">
                                <asp:Button ID="btnUpload" runat="server" Text="上傳檔案" OnClick="btnUpload_Click" 
                                    CssClass="btn btn-primary btn-lg" />
                            </div>
                            
                            <div class="alert alert-info mt-4">
                                <i class="bi bi-folder"></i> <strong>上傳目錄:</strong> ~/uploads/ (請先手動創建此資料夾)
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
        <script>
            var lblMessage = document.getElementById('<%= lblUploadMessage.ClientID %>');
            if (lblMessage && lblMessage.textContent.trim() !== '') {
                lblMessage.style.display = 'block';
            }
        </script>
    </form>
</body>
</html>
