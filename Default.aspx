<%@ Page Language="C#" AutoEventWireup="true" ResponseEncoding="UTF-8" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Data" %>
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
        if (!IsPostBack)
        {
            LoadNews();
        }
    }

    private void LoadNews()
    {
        using (SqlConnection conn = new SqlConnection(DBHelper.ConnectionString))
        {
            // SQL 查詢，用於顯示消息（內容直接從 DB 讀取，沒有輸出編碼，即 XSS 靶場）
            string sql = "SELECT Title, Content, PostDate FROM News ORDER BY PostDate DESC";
            SqlCommand cmd = new SqlCommand(sql, conn);
            
            conn.Open();
            SqlDataReader reader = cmd.ExecuteReader();
            
            if (reader.HasRows)
            {
                newsRepeater.DataSource = reader;
                newsRepeater.DataBind();
                newsRepeater.Visible = true;
                lblNoNews.Visible = false;
            }
            else
            {
                newsRepeater.Visible = false;
                lblNoNews.Visible = true;
            }
            
            reader.Close();
        }
    }

    // ✅ 已修補 SQL Injection 漏洞，使用參數化查詢
    protected void btnLogin_Click(object sender, EventArgs e)
    {
        string username = txtUsername.Text;
        string password = txtPassword.Text;

        try
        {
            using (SqlConnection conn = new SqlConnection(DBHelper.ConnectionString))
            {
                conn.Open();
                
                // 先檢查帳號是否存在（使用參數化查詢）
                string checkUserSql = "SELECT UserID, Role FROM Users WHERE Username = @Username";
                SqlCommand checkCmd = new SqlCommand(checkUserSql, conn);
                checkCmd.Parameters.AddWithValue("@Username", username);
                SqlDataReader userReader = checkCmd.ExecuteReader();
                
                if (!userReader.Read())
                {
                    // 帳號不存在
                    lblLoginMessage.Text = "帳號不存在";
                    lblLoginMessage.CssClass = "alert alert-danger";
                    lblLoginMessage.Visible = true;
                    userReader.Close();
                    return;
                }
                
                int userId = Convert.ToInt32(userReader["UserID"]);
                string role = userReader["Role"].ToString();
                userReader.Close();
                
                // 檢查密碼（使用參數化查詢）
                // ✅ 使用參數化查詢防止 SQL Injection
                string sql = "SELECT UserID, Role FROM Users WHERE Username = @Username AND PasswordHash = @Password";
                SqlCommand cmd = new SqlCommand(sql, conn);
                cmd.Parameters.AddWithValue("@Username", username);
                cmd.Parameters.AddWithValue("@Password", password);

                using (SqlDataReader reader = cmd.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        // 登入成功，設定 Session
                        Session["UserID"] = reader["UserID"].ToString();
                        Session["Role"] = reader["Role"].ToString();
                        Session["Username"] = username;
                        
                        Response.Redirect("EmployeeList.aspx");
                    }
                    else
                    {
                        lblLoginMessage.Text = "登入失敗：密碼錯誤。";
                        lblLoginMessage.CssClass = "alert alert-danger";
                        lblLoginMessage.Visible = true;
                    }
                }
            }
        }
        catch (Exception ex)
        {
            // 實務上不應該顯示錯誤細節，但為了 CTF 提示，可以這樣做
            lblLoginMessage.Text = "登入時發生錯誤: " + ex.Message;
            lblLoginMessage.CssClass = "alert alert-danger";
            lblLoginMessage.Visible = true;
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
    <title>H2C Portal - 登入與公告</title>
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
            padding: 0.6rem 2rem;
        }
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }
        .news-card {
            background: white;
            border-radius: 10px;
            padding: 1.5rem;
            margin-bottom: 1rem;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            transition: transform 0.3s;
        }
        .news-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 5px 20px rgba(0,0,0,0.1);
        }
        .news-title {
            color: #667eea;
            font-weight: bold;
            margin-bottom: 0.5rem;
        }
        .news-date {
            color: #6c757d;
            font-size: 0.9rem;
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
                            <a class="nav-link active" href="Default.aspx">
                                <i class="bi bi-house-door"></i> 首頁
                            </a>
                        </li>
                        <% if (Session["Role"] != null) { %>
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
                        <% if (Session["Role"].ToString() == "Admin") { %>
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
                        <% } %>
                    </ul>
                </div>
            </div>
        </nav>

        <div class="container main-container">
            <div class="row">
                <!-- 登入區塊 -->
                <div class="col-lg-5 mb-4">
                    <div class="card">
                        <div class="card-header">
                            <h4 class="mb-0"><i class="bi bi-box-arrow-in-right"></i> 用戶登入</h4>
                        </div>
                        <div class="card-body p-4">
                            <asp:Label ID="lblLoginMessage" runat="server" CssClass="alert alert-danger d-block" Visible="false"></asp:Label>
                            
                            <div class="mb-3">
                                <label class="form-label"><i class="bi bi-person"></i> 帳號</label>
                                <asp:TextBox ID="txtUsername" runat="server" CssClass="form-control" placeholder="請輸入帳號"></asp:TextBox>
                            </div>
                            
                            <div class="mb-3">
                                <label class="form-label"><i class="bi bi-lock"></i> 密碼</label>
                                <asp:TextBox ID="txtPassword" runat="server" TextMode="Password" CssClass="form-control" placeholder="請輸入密碼"></asp:TextBox>
                            </div>
                            
                            <asp:Button ID="btnLogin" runat="server" Text="登入" OnClick="btnLogin_Click" CssClass="btn btn-primary w-100" />
                        </div>
                    </div>
                </div>

                <!-- 最新消息區塊 -->
                <div class="col-lg-7">
                    <div class="card">
                        <div class="card-header">
                            <h4 class="mb-0"><i class="bi bi-bell"></i> 最新消息 (Stored XSS 靶場)</h4>
                        </div>
                        <div class="card-body p-4">
                            <asp:Repeater ID="newsRepeater" runat="server">
                                <ItemTemplate>
                                    <div class="news-card">
                                        <h5 class="news-title"><%# Eval("Title") %></h5>
                                        <p class="news-date"><i class="bi bi-calendar"></i> 發布於: <%# Eval("PostDate") %></p>
                                        <div class="news-content"><%# Eval("Content") %></div>
                                    </div>
                                </ItemTemplate>
                            </asp:Repeater>
                            <asp:Label ID="lblNoNews" runat="server" Visible="false">
                                <div class="text-center text-muted py-4">
                                    <i class="bi bi-inbox" style="font-size: 3rem;"></i>
                                    <p class="mt-3">目前尚無消息</p>
                                </div>
                            </asp:Label>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
        <script>
            // 顯示錯誤訊息
            var lblMessage = document.getElementById('<%= lblLoginMessage.ClientID %>');
            if (lblMessage && lblMessage.textContent.trim() !== '') {
                lblMessage.style.display = 'block';
                lblMessage.classList.add('alert', 'alert-danger');
            }
        </script>
    </form>
</body>
</html>
