<%@ Page Language="C#" AutoEventWireup="true" ResponseEncoding="UTF-8" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Web.UI.WebControls" %>

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
            LoadEmployees();
        }
    }

    private void LoadEmployees()
    {
        string role = Session["Role"].ToString();
        string sql;
        int userID = Convert.ToInt32(Session["UserID"]);

        if (role == "Admin")
        {
            // Admin: 顯示所有員工
            lblUserMessage.Text = "您是 <strong>管理者</strong>，可以看到所有員工列表。";
            lblUserMessage.CssClass = "alert alert-info";
            sql = "SELECT EmployeeID, Name, Title FROM Employees";
        }
        else
        {
            // 普通 User: 僅顯示自己（但我們故意讓列表為空，逼使用者去猜 IDOR 參數）
            lblUserMessage.Text = "您是 <strong>普通使用者</strong>。列表對您隱藏。";
            lblUserMessage.CssClass = "alert alert-warning";
            EmployeeGrid.Visible = false; 
            // 為了讓 User 知道自己的 ID，可以提示
            // 查詢自己的 EmployeeID
            sql = "SELECT EmployeeID, Name, Title FROM Employees WHERE UserID = " + userID;
            // 即使查到，也故意不顯示 GridView，強制走 IDOR 攻擊路徑
        }

        try
        {
            using (SqlConnection conn = new SqlConnection(DBHelper.ConnectionString))
            {
                SqlCommand cmd = new SqlCommand(sql, conn);
                conn.Open();
                EmployeeGrid.DataSource = cmd.ExecuteReader();
                EmployeeGrid.DataBind();
            }
        }
        catch (Exception ex)
        {
            lblUserMessage.Text = "載入員工列表時發生錯誤: " + ex.Message;
            lblUserMessage.CssClass = "alert alert-danger";
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
    <title>員工列表</title>
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
        .table {
            background: white;
            border-radius: 10px;
            overflow: hidden;
        }
        .table thead {
            background: #f8f9fa;
        }
        .btn-info {
            border-radius: 6px;
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
            <div class="card">
                <div class="card-header">
                    <h4 class="mb-0"><i class="bi bi-people-fill"></i> 員工管理 (Admin 可查看所有人)</h4>
                </div>
                <div class="card-body p-4">
                    <asp:Label ID="lblUserMessage" runat="server" CssClass="alert d-block mb-3"></asp:Label>
                    
                    <div class="table-responsive">
                        <asp:GridView ID="EmployeeGrid" runat="server" AutoGenerateColumns="False" 
                            EmptyDataText="您沒有權限查看此列表。" CssClass="table table-hover">
                            <Columns>
                                <asp:BoundField DataField="EmployeeID" HeaderText="ID" ItemStyle-CssClass="fw-bold" />
                                <asp:BoundField DataField="Name" HeaderText="姓名" />
                                <asp:BoundField DataField="Title" HeaderText="職位" />
                                <asp:TemplateField HeaderText="操作">
                                    <ItemTemplate>
                                        <a href='EmployeeDetail.aspx?id=<%# Eval("EmployeeID") %>' class="btn btn-sm btn-info">
                                            <i class="bi bi-eye"></i> 查看詳情
                                        </a>
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                            <EmptyDataTemplate>
                                <div class="text-center text-muted py-4">
                                    <i class="bi bi-inbox" style="font-size: 3rem;"></i>
                                    <p class="mt-3">您沒有權限查看此列表</p>
                                </div>
                            </EmptyDataTemplate>
                        </asp:GridView>
                    </div>
                </div>
            </div>
        </div>

        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    </form>
</body>
</html>
