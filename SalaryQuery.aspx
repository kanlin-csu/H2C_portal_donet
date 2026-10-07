<%@ Page Language="C#" AutoEventWireup="true" ResponseEncoding="UTF-8" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>
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

    protected void Page_Load(object sender, EventArgs e)
    {
        if (Session["Role"] == null)
        {
            Response.Redirect("Default.aspx");
        }

        if (!IsPostBack)
        {
            string role = Session["Role"].ToString();
            
            // 如果不是管理者，自動查詢自己的薪資
            if (role == "User")
            {
                int userId = Convert.ToInt32(Session["UserID"]);
                int employeeId = GetEmployeeIdByUserId(userId);
                
                if (employeeId > 0)
                {
                    txtEmployeeID.Text = employeeId.ToString();
                    // 自動執行查詢
                    QuerySalary(employeeId.ToString());
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
    
    private void QuerySalary(string employeeId)
    {
        string role = Session["Role"].ToString();
        int userId = Convert.ToInt32(Session["UserID"]);
        
        // 如果是一般使用者，強制使用自己的 EmployeeID，忽略輸入值
        if (role == "User")
        {
            int myEmployeeId = GetEmployeeIdByUserId(userId);
            if (myEmployeeId > 0)
            {
                employeeId = myEmployeeId.ToString();
            }
            else
            {
                lblMessage.Text = "找不到您的員工資料。";
                lblMessage.CssClass = "alert alert-danger";
                lblMessage.Visible = true;
                divSalaryInfo.Visible = false;
                return;
            }
        }
        
        // ❌ 故意使用字串拼接來建構 SQL 查詢 (SQLi 漏洞)
        // 攻擊者可以使用 UNION SELECT 來查詢其他員工的薪資
        // 但一般使用者已被強制限制為只能查詢自己的 EmployeeID
        string sql = "SELECT s.EmployeeID, s.MonthlySalary, s.Bonus, s.LastUpdated, e.Name, e.Title " +
                     "FROM Salaries s " +
                     "INNER JOIN Employees e ON s.EmployeeID = e.EmployeeID " +
                     "WHERE s.EmployeeID = " + employeeId;

        try
        {
            using (SqlConnection conn = new SqlConnection(DBHelper.ConnectionString))
            {
                SqlCommand cmd = new SqlCommand(sql, conn);
                conn.Open();

                using (SqlDataReader reader = cmd.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        // ⚠️ 原本只看送出的 employeeId 字串裡有沒有出現 "union" 這個字，
                        // 不管查詢語法對不對、有沒有真的多撈到資料都會給 flag。
                        // 改成檢查「輸入不是單純數字，但查詢依然成功執行並回傳資料列」——
                        // 一個正常的員工編號查詢不需要靠任何非數字語法就能成功，
                        // 如果用了非數字輸入還能跑成功，代表真的有語法被資料庫解讀/注入成功。
                        if (!Regex.IsMatch(employeeId, @"^\d+$"))
                        {
                            Response.Headers["X-H2C-Flag"] = "H2C{sqli_salary_union}";
                        }

                        // 再次驗證：一般使用者查詢到的 EmployeeID 必須是自己的
                        if (role == "User")
                        {
                            int queriedEmployeeId = Convert.ToInt32(reader["EmployeeID"]);
                            int myEmployeeId = GetEmployeeIdByUserId(userId);
                            
                            if (queriedEmployeeId != myEmployeeId)
                            {
                                lblMessage.Text = "您只能查詢自己的薪資資訊。";
                                lblMessage.CssClass = "alert alert-danger";
                                lblMessage.Visible = true;
                                divSalaryInfo.Visible = false;
                                return;
                            }
                        }
                        
                        lblEmployeeID.Text = reader["EmployeeID"].ToString();
                        lblEmployeeName.Text = reader["Name"].ToString();
                        lblEmployeeTitle.Text = reader["Title"].ToString();
                        lblMonthlySalary.Text = Convert.ToDecimal(reader["MonthlySalary"]).ToString("N0");
                        lblBonus.Text = Convert.ToDecimal(reader["Bonus"]).ToString("N0");
                        lblTotal.Text = (Convert.ToDecimal(reader["MonthlySalary"]) + Convert.ToDecimal(reader["Bonus"])).ToString("N0");
                        lblLastUpdated.Text = Convert.ToDateTime(reader["LastUpdated"]).ToString("yyyy-MM-dd");
                        
                        divSalaryInfo.Visible = true;
                        lblMessage.Visible = false;
                    }
                    else
                    {
                        lblMessage.Text = "找不到員工編號 " + employeeId + " 的薪資資料。";
                        lblMessage.CssClass = "alert alert-warning";
                        lblMessage.Visible = true;
                        divSalaryInfo.Visible = false;
                    }
                }
            }
        }
        catch (Exception ex)
        {
            lblMessage.Text = "查詢時發生錯誤: " + ex.Message;
            lblMessage.CssClass = "alert alert-danger";
            lblMessage.Visible = true;
            divSalaryInfo.Visible = false;
        }
    }

    // 🚨 這是 SQL Injection 的漏洞點 🚨
    // 但一般使用者已被強制限制為只能查詢自己的 EmployeeID
    protected void btnQuery_Click(object sender, EventArgs e)
    {
        string employeeId = txtEmployeeID.Text.Trim();
        string role = Session["Role"].ToString();
        
        // 管理者需要輸入員工編號
        if (role == "Admin")
        {
            if (string.IsNullOrEmpty(employeeId))
            {
                lblMessage.Text = "請輸入員工編號。";
                lblMessage.CssClass = "alert alert-warning";
                lblMessage.Visible = true;
                divSalaryInfo.Visible = false;
                return;
            }
        }
        // 一般使用者不需要輸入，會自動使用自己的 EmployeeID
        else if (role == "User")
        {
            // 一般使用者輸入的員工編號會被忽略，強制使用自己的 EmployeeID
            // 這裡保留輸入框是為了 UI 一致性，但實際查詢時會使用自己的 EmployeeID
        }

        QuerySalary(employeeId);
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
    <title>薪資查詢</title>
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
        .salary-card {
            background: white;
            border-radius: 10px;
            padding: 2rem;
        }
        .salary-item {
            padding: 1rem 0;
            border-bottom: 1px solid #e9ecef;
        }
        .salary-item:last-child {
            border-bottom: none;
        }
        .salary-label {
            font-weight: bold;
            color: #667eea;
            margin-bottom: 0.5rem;
        }
        .salary-amount {
            font-size: 1.5rem;
            color: #28a745;
            font-weight: bold;
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
                            <a class="nav-link active" href="SalaryQuery.aspx">
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
            <div class="row justify-content-center">
                <div class="col-lg-8">
                    <div class="card">
                        <div class="card-header">
                            <h4 class="mb-0"><i class="bi bi-cash-stack"></i> 薪資查詢</h4>
                        </div>
                        <div class="card-body p-4">
                            <asp:Label ID="lblMessage" runat="server" CssClass="alert d-block" Visible="false"></asp:Label>
                            
                            <div class="mb-4">
                                <label class="form-label"><i class="bi bi-hash"></i> 員工編號</label>
                                <div class="input-group">
                                    <asp:TextBox ID="txtEmployeeID" runat="server" CssClass="form-control" placeholder="請輸入員工編號"></asp:TextBox>
                                    <asp:Button ID="btnQuery" runat="server" Text="查詢" OnClick="btnQuery_Click" CssClass="btn btn-primary" />
                                </div>
                                <small class="text-muted">輸入員工編號即可查詢該員工的薪資資訊</small>
                            </div>

                            <div id="divSalaryInfo" runat="server" visible="false" class="salary-card">
                                <h5 class="mb-4"><i class="bi bi-person-badge"></i> 員工資訊</h5>
                                <div class="salary-item">
                                    <div class="salary-label">員工編號</div>
                                    <div><asp:Label ID="lblEmployeeID" runat="server" CssClass="fs-5 fw-bold" /></div>
                                </div>
                                <div class="salary-item">
                                    <div class="salary-label">姓名</div>
                                    <div><asp:Label ID="lblEmployeeName" runat="server" CssClass="fs-5" /></div>
                                </div>
                                <div class="salary-item">
                                    <div class="salary-label">職位</div>
                                    <div><asp:Label ID="lblEmployeeTitle" runat="server" CssClass="fs-5" /></div>
                                </div>
                                <hr />
                                <h5 class="mb-4"><i class="bi bi-wallet2"></i> 薪資資訊</h5>
                                <div class="salary-item">
                                    <div class="salary-label">月薪</div>
                                    <div class="salary-amount">NT$ <asp:Label ID="lblMonthlySalary" runat="server" /></div>
                                </div>
                                <div class="salary-item">
                                    <div class="salary-label">獎金</div>
                                    <div class="salary-amount">NT$ <asp:Label ID="lblBonus" runat="server" /></div>
                                </div>
                                <div class="salary-item">
                                    <div class="salary-label">總計</div>
                                    <div class="salary-amount text-primary">NT$ <asp:Label ID="lblTotal" runat="server" /></div>
                                </div>
                                <div class="salary-item">
                                    <div class="salary-label">最後更新日期</div>
                                    <div><asp:Label ID="lblLastUpdated" runat="server" /></div>
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
