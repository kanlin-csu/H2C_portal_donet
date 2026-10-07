<%-- ValidateRequest="false"：ASP.NET 預設的 Request Validation 會在程式碼執行前，
     直接擋掉任何看起來像 HTML 標籤的 POST 內容（包含這一題故意要讓學生送出的 XSS
     payload），不關掉的話連 Page_Load/btnPost_Click 都進不去，XSS 這題等於打不穿。
     只關這一頁，不要動 web.config 影響全站。 --%>
<%@ Page Language="C#" AutoEventWireup="true" ResponseEncoding="UTF-8" ValidateRequest="false" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Web.UI.WebControls" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>

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

    // 要求真正的標籤或事件屬性語法（例如 <script>、<img onerror=...>、<svg onload=...>、
    // javascript: 偽協定），而不是單純字串裡出現 "onload" 這幾個字就算數。
    private static readonly Regex XssPayloadPattern = new Regex(
        @"<\s*script[^>]*>|on\w+\s*=\s*[""']|javascript\s*:",
        RegexOptions.IgnoreCase);

    protected void Page_Load(object sender, EventArgs e)
    {
        if (Session["Role"] == null)
        {
            Response.Redirect("Default.aspx");
        }
        if (!IsPostBack)
        {
            LoadAdminNewsList();
        }
    }

    // 🚨 這是 Stored XSS 的漏洞點 🚨
    protected void btnPost_Click(object sender, EventArgs e)
    {
        string title = txtTitle.Text;
        string content = txtContent.Text; // ❌ 內容未進行任何編碼或過濾
        int authorId = Convert.ToInt32(Session["UserID"]);

        string sql = "INSERT INTO News (Title, Content, AuthorID) VALUES (@Title, @Content, @AuthorID)";

        try
        {
            using (SqlConnection conn = new SqlConnection(DBHelper.ConnectionString))
            {
                SqlCommand cmd = new SqlCommand(sql, conn);
                cmd.Parameters.AddWithValue("@Title", title);
                cmd.Parameters.AddWithValue("@Content", content); // 參數化只防 SQLi，不防 XSS
                cmd.Parameters.AddWithValue("@AuthorID", authorId);

                conn.Open();
                cmd.ExecuteNonQuery();

                // ⚠️ 原本只看輸入裡有沒有出現 "<script"/"onerror"/"onload" 這幾個「字串」，
                // 連一句純文字「請勿使用 onload 事件」都會被誤判成功，沒有真的驗證利用是否成立。
                // 這裡改成要求「真正的標籤/事件屬性語法」，而且因為 Default.aspx 是用
                // <%# Eval("Content") %>（未做 HtmlEncode）直接輸出，只要存進去的內容符合
                // 這個語法，就必然會在首頁以未編碼的形式原樣渲染、真正觸發執行。
                bool containsXssPayload = XssPayloadPattern.IsMatch(content);
                lblPostMessage.Text = containsXssPayload
                    ? "消息發布成功！Flag: H2C{stored_xss_news}"
                    : "消息發布成功！(請至主頁查看 XSS 效果)";
                lblPostMessage.CssClass = "alert alert-success";
                txtTitle.Text = string.Empty;
                txtContent.Text = string.Empty;
                LoadAdminNewsList();
            }
        }
        catch (Exception ex)
        {
            lblPostMessage.Text = "發布失敗: " + ex.Message;
            lblPostMessage.CssClass = "alert alert-danger";
        }
    }

    private void LoadAdminNewsList()
    {
        string sql;
        string role = Session["Role"].ToString();
        int userId = Convert.ToInt32(Session["UserID"]);

        if (role == "Admin")
        {
            // Admin: 查看所有人的消息
            sql = "SELECT NewsID, Title, AuthorID FROM News ORDER BY NewsID DESC";
        }
        else
        {
            // User: 只能查看自己的消息
            sql = "SELECT NewsID, Title, AuthorID FROM News WHERE AuthorID = " + userId + " ORDER BY NewsID DESC";
        }

        using (SqlConnection conn = new SqlConnection(DBHelper.ConnectionString))
        {
            SqlCommand cmd = new SqlCommand(sql, conn);
            conn.Open();
            newsAdminGrid.DataSource = cmd.ExecuteReader();
            newsAdminGrid.DataBind();
        }
    }

    // 🚨 這是 IDOR 刪除的漏洞點 🚨
    protected void newsAdminGrid_RowCommand(object sender, GridViewCommandEventArgs e)
    {
        if (e.CommandName == "DeleteNews")
        {
            int newsIdToDelete = Convert.ToInt32(e.CommandArgument);
            
            string sql = "DELETE FROM News WHERE NewsID = @NewsID"; 

            try
            {
                using (SqlConnection conn = new SqlConnection(DBHelper.ConnectionString))
                {
                    SqlCommand cmd = new SqlCommand(sql, conn);
                    cmd.Parameters.AddWithValue("@NewsID", newsIdToDelete);

                    conn.Open();
                    int rowsAffected = cmd.ExecuteNonQuery();

                    if (rowsAffected > 0)
                    {
                        lblPostMessage.Text = "NewsID " + newsIdToDelete + " 刪除成功！ (請檢查 IDOR 是否成功)";
                        lblPostMessage.CssClass = "alert alert-success";
                    }
                    else
                    {
                        lblPostMessage.Text = "NewsID " + newsIdToDelete + " 刪除失敗或找不到。";
                        lblPostMessage.CssClass = "alert alert-warning";
                    }

                    LoadAdminNewsList();
                }
            }
            catch (Exception ex)
            {
                lblPostMessage.Text = "刪除時發生錯誤: " + ex.Message;
                lblPostMessage.CssClass = "alert alert-danger";
            }
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
    <title>消息管理</title>
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
                            <a class="nav-link active" href="NewsPost.aspx">
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
                            <a class="nav-link" href="Challenges.aspx">
                                <i class="bi bi-flag"></i> 挑戰中心
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
            <!-- 發布新消息 -->
            <div class="card">
                <div class="card-header">
                    <h4 class="mb-0"><i class="bi bi-pencil-square"></i> 發布新消息</h4>
                </div>
                <div class="card-body p-4">
                    <asp:Label ID="lblPostMessage" runat="server" CssClass="alert d-block" Visible="false"></asp:Label>
                    
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label"><i class="bi bi-type"></i> 標題</label>
                            <asp:TextBox ID="txtTitle" runat="server" CssClass="form-control" placeholder="請輸入消息標題"></asp:TextBox>
                        </div>
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label"><i class="bi bi-file-text"></i> 內容</label>
                        <asp:TextBox ID="txtContent" runat="server" TextMode="MultiLine" Rows="5" CssClass="form-control" placeholder="請輸入消息內容"></asp:TextBox>
                    </div>
                    
                    <asp:Button ID="btnPost" runat="server" Text="發布消息" OnClick="btnPost_Click" CssClass="btn btn-primary" />
                </div>
            </div>

            <!-- 管理消息列表 -->
            <div class="card">
                <div class="card-header">
                    <h4 class="mb-0"><i class="bi bi-list-ul"></i> 管理我的/所有消息</h4>
                </div>
                <div class="card-body p-4">
                    <div class="table-responsive">
                        <asp:GridView ID="newsAdminGrid" runat="server" AutoGenerateColumns="False" 
                            OnRowCommand="newsAdminGrid_RowCommand" CssClass="table table-hover">
                            <Columns>
                                <asp:BoundField DataField="NewsID" HeaderText="ID" ItemStyle-CssClass="fw-bold" />
                                <asp:BoundField DataField="Title" HeaderText="標題" />
                                <asp:BoundField DataField="AuthorID" HeaderText="作者 ID" />
                                <asp:TemplateField HeaderText="操作">
                                    <ItemTemplate>
                                        <asp:LinkButton ID="btnDelete" runat="server" CommandName="DeleteNews" 
                                            CommandArgument='<%# Eval("NewsID") %>' 
                                            CssClass="btn btn-sm btn-danger"
                                            OnClientClick="return confirm('確定要刪除這則消息嗎？');">
                                            <i class="bi bi-trash"></i> 刪除 
                                        </asp:LinkButton>
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                            <EmptyDataTemplate>
                                <div class="text-center text-muted py-4">
                                    <i class="bi bi-inbox" style="font-size: 3rem;"></i>
                                    <p class="mt-3">目前尚無消息</p>
                                </div>
                            </EmptyDataTemplate>
                        </asp:GridView>
                    </div>
                </div>
            </div>
        </div>

        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
        <script>
            var lblMessage = document.getElementById('<%= lblPostMessage.ClientID %>');
            if (lblMessage && lblMessage.textContent.trim() !== '') {
                lblMessage.style.display = 'block';
            }
        </script>
    </form>
</body>
</html>
