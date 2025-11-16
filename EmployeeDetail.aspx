<%@ Page Language="C#" AutoEventWireup="true" ResponseEncoding="UTF-8" %>
<%@ Import Namespace="System" %>
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
        // 檢查登入狀態
        if (Session["Role"] == null)
        {
            Response.Redirect("Default.aspx");
        }

        if (!IsPostBack)
        {
            string employeeId = Request.QueryString["id"];
            string role = Session["Role"].ToString();
            int currentUserId = Convert.ToInt32(Session["UserID"]);
            
            // 如果是普通用戶，只顯示自己的資料
            if (role == "User")
            {
                // 根據 UserID 查詢對應的 EmployeeID
                int myEmployeeId = GetEmployeeIdByUserId(currentUserId);
                if (myEmployeeId > 0)
                {
                    LoadEmployeeDetail(myEmployeeId.ToString());
                    // 設定查詢輸入框的值（前端 disabled，但可以修改）
                    txtQueryEmployeeID.Value = myEmployeeId.ToString();
                }
                else
                {
                    lblMessage.Text = "找不到您的員工資料。";
                    lblMessage.CssClass = "alert alert-warning";
                }
            }
            else
            {
                // Admin 可以查詢任何員工
                if (string.IsNullOrEmpty(employeeId))
                {
                    // 如果沒有指定 ID，顯示查詢表單
                    divQueryForm.Visible = true;
                }
                else
                {
                    LoadEmployeeDetail(employeeId);
                    txtQueryEmployeeID.Value = employeeId;
                }
            }
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
    
    protected void btnQuery_Click(object sender, EventArgs e)
    {
        string employeeId = txtQueryEmployeeID.Value;
        if (!string.IsNullOrEmpty(employeeId))
        {
            LoadEmployeeDetail(employeeId);
        }
        else
        {
            lblMessage.Text = "請輸入員工編號。";
            lblMessage.CssClass = "alert alert-warning";
        }
    }

    // 🚨 這是 IDOR 的漏洞點 🚨
    private void LoadEmployeeDetail(string employeeId)
    {
        // ❌ 這裡沒有進行任何授權檢查 (IDOR)
        // 管理者可以看，普通使用者也可以透過修改 URL 參數看到任何人。
        string sql = "SELECT EmployeeID, Name, Title, PhotoPath FROM Employees WHERE EmployeeID = @id";
        
        try
        {
            using (SqlConnection conn = new SqlConnection(DBHelper.ConnectionString))
            {
                SqlCommand cmd = new SqlCommand(sql, conn);
                cmd.Parameters.AddWithValue("@id", employeeId); // 使用參數化查詢，這裡沒有 SQLi

                conn.Open();
                using (SqlDataReader reader = cmd.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        lblEmployeeID.Text = reader["EmployeeID"].ToString();
                        lblName.Text = reader["Name"].ToString();
                        lblTitle.Text = reader["Title"].ToString();
                        
                        // 設置照片路徑供 LFI 靶場使用
                        string photoPath = reader["PhotoPath"].ToString();
                        lblPhotoPath.Text = photoPath;
                        
                        // 將照片路徑傳遞給 ImageHandler，作為 LFI 練習點
                        imgEmployee.Attributes["src"] = "ImageHandler.ashx?path=" + photoPath;
                        
                        divEmployeeDetail.Visible = true;
                        divQueryForm.Visible = false;
                    }
                    else
                    {
                        lblMessage.Text = "找不到 EmployeeID: " + employeeId + " 的資料。";
                        lblMessage.CssClass = "alert alert-warning";
                    }
                }
            }
        }
        catch (Exception ex)
        {
            lblMessage.Text = "載入資料時發生錯誤: " + ex.Message;
            lblMessage.CssClass = "alert alert-danger";
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
    <title>員工詳細資料</title>
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
        .info-card {
            background: white;
            border-radius: 10px;
            padding: 2rem;
        }
        .info-item {
            padding: 1rem 0;
            border-bottom: 1px solid #e9ecef;
        }
        .info-item:last-child {
            border-bottom: none;
        }
        .info-label {
            font-weight: bold;
            color: #667eea;
            margin-bottom: 0.5rem;
        }
        .employee-photo {
            max-width: 100%;
            border-radius: 10px;
            box-shadow: 0 3px 15px rgba(0,0,0,0.2);
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
                            <a class="nav-link active" href="EmployeeList.aspx">
                                <i class="bi bi-people"></i> 員工管理
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="NewsPost.aspx">
                                <i class="bi bi-newspaper"></i> 消息管理
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="FileUpload.aspx">
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
            <asp:Label ID="lblMessage" runat="server" CssClass="alert d-block" Visible="false"></asp:Label>
            
            <!-- 查詢表單 -->
            <div id="divQueryForm" runat="server" visible="false" class="card mb-4">
                <div class="card-header">
                    <h4 class="mb-0"><i class="bi bi-search"></i> 查詢員工資料</h4>
                </div>
                <div class="card-body p-4">
                    <div class="row">
                        <div class="col-md-8">
                            <label class="form-label">員工編號</label>
                            <input type="text" id="txtQueryEmployeeID" runat="server" class="form-control" disabled />
                            <small class="text-muted">（前端 disabled，但可透過開發者工具修改）</small>
                        </div>
                        <div class="col-md-4 d-flex align-items-end">
                            <asp:Button ID="btnQuery" runat="server" Text="查詢" OnClick="btnQuery_Click" CssClass="btn btn-primary w-100" />
                        </div>
                    </div>
                </div>
            </div>
            
            <div id="divEmployeeDetail" runat="server" visible="false">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h4 class="mb-0"><i class="bi bi-person-badge"></i> 員工詳細資料 (IDOR 靶場)</h4>
                        <a href="FileUpload.aspx" class="btn btn-light btn-sm">
                            <i class="bi bi-upload"></i> 上傳照片
                        </a>
                    </div>
                    <div class="card-body p-4">
                        <div class="row">
                            <div class="col-md-6">
                                <div class="info-card">
                                    <div class="info-item">
                                        <div class="info-label"><i class="bi bi-hash"></i> Employee ID</div>
                                        <div><asp:Label ID="lblEmployeeID" runat="server" CssClass="fs-5" /></div>
                                    </div>
                                    <div class="info-item">
                                        <div class="info-label"><i class="bi bi-person"></i> 姓名</div>
                                        <div><asp:Label ID="lblName" runat="server" CssClass="fs-5" /></div>
                                    </div>
                                    <div class="info-item">
                                        <div class="info-label"><i class="bi bi-briefcase"></i> 職位</div>
                                        <div><asp:Label ID="lblTitle" runat="server" CssClass="fs-5" /></div>
                                    </div>
                                    <div class="info-item">
                                        <div class="info-label"><i class="bi bi-folder"></i> 照片路徑</div>
                                        <div><asp:Label ID="lblPhotoPath" runat="server" CssClass="text-muted small" /></div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="info-card">
                                    <div class="info-label mb-3"><i class="bi bi-image"></i> 員工照片 (LFI 靶場)</div>
                                    <img id="imgEmployee" runat="server" alt="員工照片" class="employee-photo" />
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
        <script>
            var lblMessage = document.getElementById('<%= lblMessage.ClientID %>');
            if (lblMessage && lblMessage.textContent.trim() !== '') {
                lblMessage.style.display = 'block';
            }
        </script>
    </form>
</body>
</html>
