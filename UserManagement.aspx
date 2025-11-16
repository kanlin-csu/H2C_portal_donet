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
        // 只有 Admin 可以訪問
        if (Session["Role"] == null || Session["Role"].ToString() != "Admin")
        {
            Response.Redirect("Default.aspx");
        }

        if (!IsPostBack)
        {
            LoadUsers();
        }
    }

    private void LoadUsers()
    {
        string sql = "SELECT UserID, Username, Role FROM Users ORDER BY UserID";
        
        using (SqlConnection conn = new SqlConnection(DBHelper.ConnectionString))
        {
            SqlCommand cmd = new SqlCommand(sql, conn);
            conn.Open();
            userGrid.DataSource = cmd.ExecuteReader();
            userGrid.DataBind();
        }
    }

    protected void btnAdd_Click(object sender, EventArgs e)
    {
        string username = txtNewUsername.Text.Trim();
        string password = txtNewPassword.Text;
        string role = ddlNewRole.SelectedValue;

        if (string.IsNullOrEmpty(username) || string.IsNullOrEmpty(password))
        {
            lblMessage.Text = "請填寫所有欄位。";
            lblMessage.CssClass = "alert alert-warning";
            lblMessage.Visible = true;
            return;
        }

        // ❌ 使用字串拼接建構 SQL (SQLi 漏洞)
        string sql = "INSERT INTO Users (Username, PasswordHash, Role) VALUES ('" + username + "', '" + password + "', '" + role + "')";

        try
        {
            using (SqlConnection conn = new SqlConnection(DBHelper.ConnectionString))
            {
                SqlCommand cmd = new SqlCommand(sql, conn);
                conn.Open();
                cmd.ExecuteNonQuery();

                lblMessage.Text = "帳號新增成功！";
                lblMessage.CssClass = "alert alert-success";
                lblMessage.Visible = true;
                
                txtNewUsername.Text = "";
                txtNewPassword.Text = "";
                LoadUsers();
            }
        }
        catch (Exception ex)
        {
            lblMessage.Text = "新增帳號時發生錯誤: " + ex.Message;
            lblMessage.CssClass = "alert alert-danger";
            lblMessage.Visible = true;
        }
    }

    protected void userGrid_RowCommand(object sender, GridViewCommandEventArgs e)
    {
        if (e.CommandName == "DeleteUser")
        {
            int userId = Convert.ToInt32(e.CommandArgument);
            
            // 檢查是否有員工資料關聯
            string checkSql = "SELECT COUNT(*) FROM Employees WHERE UserID = " + userId;
            using (SqlConnection conn = new SqlConnection(DBHelper.ConnectionString))
            {
                SqlCommand checkCmd = new SqlCommand(checkSql, conn);
                conn.Open();
                int count = Convert.ToInt32(checkCmd.ExecuteScalar());
                
                if (count > 0)
                {
                    lblMessage.Text = "無法刪除：該帳號有關聯的員工資料。";
                    lblMessage.CssClass = "alert alert-warning";
                    lblMessage.Visible = true;
                    return;
                }
            }

            // ❌ 使用字串拼接建構 SQL (SQLi 漏洞)
            string sql = "DELETE FROM Users WHERE UserID = " + userId;

            try
            {
                using (SqlConnection conn = new SqlConnection(DBHelper.ConnectionString))
                {
                    SqlCommand cmd = new SqlCommand(sql, conn);
                    conn.Open();
                    int rowsAffected = cmd.ExecuteNonQuery();

                    if (rowsAffected > 0)
                    {
                        lblMessage.Text = "帳號刪除成功！";
                        lblMessage.CssClass = "alert alert-success";
                    }
                    else
                    {
                        lblMessage.Text = "刪除失敗。";
                        lblMessage.CssClass = "alert alert-warning";
                    }
                    lblMessage.Visible = true;
                    LoadUsers();
                }
            }
            catch (Exception ex)
            {
                lblMessage.Text = "刪除帳號時發生錯誤: " + ex.Message;
                lblMessage.CssClass = "alert alert-danger";
                lblMessage.Visible = true;
            }
        }
    }

    protected void ddlRole_SelectedIndexChanged(object sender, EventArgs e)
    {
        DropDownList ddl = (DropDownList)sender;
        GridViewRow row = (GridViewRow)ddl.NamingContainer;
        HiddenField hidUserID = (HiddenField)row.FindControl("hidUserID");
        
        int userId = Convert.ToInt32(hidUserID.Value);
        string newRole = ddl.SelectedValue;
        
        // ❌ 使用字串拼接建構 SQL (SQLi 漏洞)
        string sql = "UPDATE Users SET Role = '" + newRole + "' WHERE UserID = " + userId;

        try
        {
            using (SqlConnection conn = new SqlConnection(DBHelper.ConnectionString))
            {
                SqlCommand cmd = new SqlCommand(sql, conn);
                conn.Open();
                cmd.ExecuteNonQuery();

                lblMessage.Text = "權限更新成功！";
                lblMessage.CssClass = "alert alert-success";
                lblMessage.Visible = true;
                LoadUsers();
            }
        }
        catch (Exception ex)
        {
            lblMessage.Text = "更新權限時發生錯誤: " + ex.Message;
            lblMessage.CssClass = "alert alert-danger";
            lblMessage.Visible = true;
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
    <title>帳號管理</title>
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
        .btn-danger {
            border-radius: 6px;
        }
        .table {
            background: white;
        }
        .table thead {
            background: #f8f9fa;
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
                            <a class="nav-link" href="FileUpload.aspx">
                                <i class="bi bi-upload"></i> 檔案上傳
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="SalaryQuery.aspx">
                                <i class="bi bi-cash-coin"></i> 薪資查詢
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link active" href="UserManagement.aspx">
                                <i class="bi bi-person-gear"></i> 帳號管理
                            </a>
                        </li>
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
            <!-- 新增帳號 -->
            <div class="card">
                <div class="card-header">
                    <h4 class="mb-0"><i class="bi bi-person-plus"></i> 新增帳號</h4>
                </div>
                <div class="card-body p-4">
                    <asp:Label ID="lblMessage" runat="server" CssClass="alert d-block" Visible="false"></asp:Label>
                    
                    <div class="row">
                        <div class="col-md-4 mb-3">
                            <label class="form-label">帳號名稱</label>
                            <asp:TextBox ID="txtNewUsername" runat="server" CssClass="form-control" placeholder="請輸入帳號"></asp:TextBox>
                        </div>
                        <div class="col-md-4 mb-3">
                            <label class="form-label">密碼</label>
                            <asp:TextBox ID="txtNewPassword" runat="server" TextMode="Password" CssClass="form-control" placeholder="請輸入密碼"></asp:TextBox>
                        </div>
                        <div class="col-md-3 mb-3">
                            <label class="form-label">權限</label>
                            <asp:DropDownList ID="ddlNewRole" runat="server" CssClass="form-select">
                                <asp:ListItem Value="User" Text="User" />
                                <asp:ListItem Value="Admin" Text="Admin" />
                            </asp:DropDownList>
                        </div>
                        <div class="col-md-1 mb-3 d-flex align-items-end">
                            <asp:Button ID="btnAdd" runat="server" Text="新增" OnClick="btnAdd_Click" CssClass="btn btn-primary w-100" />
                        </div>
                    </div>
                </div>
            </div>

            <!-- 帳號列表 -->
            <div class="card">
                <div class="card-header">
                    <h4 class="mb-0"><i class="bi bi-list-ul"></i> 帳號列表</h4>
                </div>
                <div class="card-body p-4">
                    <div class="table-responsive">
                        <asp:GridView ID="userGrid" runat="server" AutoGenerateColumns="False" 
                            OnRowCommand="userGrid_RowCommand" CssClass="table table-hover">
                            <Columns>
                                <asp:BoundField DataField="UserID" HeaderText="User ID" ItemStyle-CssClass="fw-bold" />
                                <asp:BoundField DataField="Username" HeaderText="帳號名稱" />
                                <asp:TemplateField HeaderText="權限">
                                    <ItemTemplate>
                                        <asp:DropDownList ID="ddlRole" runat="server" CssClass="form-select form-select-sm"
                                            SelectedValue='<%# Eval("Role") %>'
                                            OnSelectedIndexChanged="ddlRole_SelectedIndexChanged"
                                            AutoPostBack="true">
                                            <asp:ListItem Value="User" Text="User" />
                                            <asp:ListItem Value="Admin" Text="Admin" />
                                        </asp:DropDownList>
                                        <asp:HiddenField ID="hidUserID" runat="server" Value='<%# Eval("UserID") %>' />
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="操作">
                                    <ItemTemplate>
                                        <asp:LinkButton ID="btnDelete" runat="server" CommandName="DeleteUser" 
                                            CommandArgument='<%# Eval("UserID") %>' 
                                            CssClass="btn btn-sm btn-danger"
                                            OnClientClick="return confirm('確定要刪除這個帳號嗎？');">
                                            <i class="bi bi-trash"></i> 刪除
                                        </asp:LinkButton>
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                            <EmptyDataTemplate>
                                <div class="text-center text-muted py-4">
                                    <i class="bi bi-inbox" style="font-size: 3rem;"></i>
                                    <p class="mt-3">目前尚無帳號</p>
                                </div>
                            </EmptyDataTemplate>
                        </asp:GridView>
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

