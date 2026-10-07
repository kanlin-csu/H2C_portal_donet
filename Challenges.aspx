<%@ Page Language="C#" AutoEventWireup="true" ResponseEncoding="UTF-8" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>

<script runat="server">
    // ⚠️ Flag 正確答案存在資料庫（Flags 表），不要寫死在任何網站根目錄下的檔案裡。
    // 這裡的任何 .aspx/.ashx 檔案原始碼都可能被 LFI（ImageHandler.ashx?path=）讀到純文字，
    // 如果 5 題的 flag 全部寫死在這支檔案裡，解出 LFI 題就能一次看光其他四題的答案。
    private static readonly int ChallengeCount = 5;

    private string GetFlagFromDb(string challengeId)
    {
        string sql = "SELECT FlagValue FROM Flags WHERE ChallengeID = @id";
        using (SqlConnection conn = new SqlConnection(ConfigurationManager.ConnectionStrings["H2C_Portal_DB"].ConnectionString))
        {
            SqlCommand cmd = new SqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@id", challengeId);
            conn.Open();
            object result = cmd.ExecuteScalar();
            return result == null ? null : result.ToString();
        }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        if (Session["Role"] == null)
        {
            Response.Redirect("Default.aspx");
            return;
        }

        if (!IsPostBack)
        {
            RefreshProgress();
        }
    }

    private HashSet<string> GetCompletedChallenges()
    {
        string value = Convert.ToString(Session["CompletedChallenges"]);
        return new HashSet<string>(
            value.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries),
            StringComparer.OrdinalIgnoreCase);
    }

    private void SaveCompletedChallenges(HashSet<string> completed)
    {
        Session["CompletedChallenges"] = string.Join(",", completed);
    }

    private void SubmitFlag(string challengeId, string submittedFlag)
    {
        string correctFlag = GetFlagFromDb(challengeId);
        if (correctFlag != null &&
            string.Equals(correctFlag, (submittedFlag ?? "").Trim(), StringComparison.OrdinalIgnoreCase))
        {
            HashSet<string> completed = GetCompletedChallenges();
            completed.Add(challengeId);
            SaveCompletedChallenges(completed);
            lblMessage.Text = "Flag 正確，挑戰已完成。";
            lblMessage.CssClass = "alert alert-success d-block";
        }
        else
        {
            lblMessage.Text = "Flag 不正確，請繼續檢查請求、回應與頁面行為。";
            lblMessage.CssClass = "alert alert-danger d-block";
        }

        RefreshProgress();
    }

    protected void btnSubmitIdor_Click(object sender, EventArgs e) { SubmitFlag("idor", txtIdorFlag.Text); }
    protected void btnSubmitSqli_Click(object sender, EventArgs e) { SubmitFlag("sqli", txtSqliFlag.Text); }
    protected void btnSubmitXss_Click(object sender, EventArgs e) { SubmitFlag("xss", txtXssFlag.Text); }
    protected void btnSubmitUpload_Click(object sender, EventArgs e) { SubmitFlag("upload", txtUploadFlag.Text); }
    protected void btnSubmitLfi_Click(object sender, EventArgs e) { SubmitFlag("lfi", txtLfiFlag.Text); }

    private void RefreshProgress()
    {
        HashSet<string> completed = GetCompletedChallenges();
        lblProgress.Text = completed.Count + " / " + ChallengeCount;
        progressBar.Attributes["style"] = "width: " + (completed.Count * 100 / ChallengeCount) + "%";
        progressBar.Attributes["aria-valuenow"] = (completed.Count * 100 / ChallengeCount).ToString();
        SetStatus(lblIdorStatus, completed.Contains("idor"));
        SetStatus(lblSqliStatus, completed.Contains("sqli"));
        SetStatus(lblXssStatus, completed.Contains("xss"));
        SetStatus(lblUploadStatus, completed.Contains("upload"));
        SetStatus(lblLfiStatus, completed.Contains("lfi"));
    }

    private void SetStatus(System.Web.UI.WebControls.Label label, bool completed)
    {
        label.Text = completed ? "已完成" : "未完成";
        label.CssClass = completed ? "badge bg-success" : "badge bg-secondary";
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
    <title>H2C Portal - CTF 挑戰中心</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet" />
    <style>
        body { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; font-family: 'Microsoft JhengHei', '微軟正黑體', Arial, sans-serif; }
        .navbar { background: rgba(255,255,255,.96) !important; box-shadow: 0 2px 10px rgba(0,0,0,.12); }
        .main-container { margin-top: 2rem; padding-bottom: 3rem; }
        .card { border: 0; border-radius: 15px; box-shadow: 0 5px 20px rgba(0,0,0,.12); }
        .challenge-card { height: 100%; }
        .challenge-card .card-header { background: #212529; color: white; }
        .hint { background: #f8f9fa; border-left: 4px solid #ffc107; padding: .75rem; }
        code { color: #7b2cbf; }
    </style>
</head>
<body>
<form id="form1" runat="server">
    <nav class="navbar navbar-expand-lg navbar-light">
        <div class="container">
            <a class="navbar-brand fw-bold" href="Default.aspx"><i class="bi bi-shield-check"></i> H2C 練習平台</a>
            <div class="navbar-nav ms-auto align-items-center">
                <a class="nav-link" href="Default.aspx">首頁</a>
                <a class="nav-link" href="EmployeeList.aspx">員工管理</a>
                <a class="nav-link" href="NewsPost.aspx">消息管理</a>
                <a class="nav-link" href="FileUpload.aspx">檔案上傳</a>
                <a class="nav-link" href="SalaryQuery.aspx">薪資查詢</a>
                <a class="nav-link active" href="Challenges.aspx"><i class="bi bi-flag"></i> 挑戰中心</a>
                <asp:LinkButton ID="btnLogout" runat="server" OnClick="btnLogout_Click" CssClass="nav-link text-danger">登出</asp:LinkButton>
            </div>
        </div>
    </nav>

    <div class="container main-container">
        <div class="card mb-4">
            <div class="card-body p-4">
                <div class="d-flex justify-content-between align-items-center mb-2">
                    <div>
                        <h2 class="mb-1">CTF 挑戰中心</h2>
                        <p class="text-muted mb-0">僅能在授權的 H2C Portal Lab 中操作。完成進度保存在目前登入 Session。</p>
                    </div>
                    <div class="fs-4"><asp:Label ID="lblProgress" runat="server" /></div>
                </div>
                <div class="progress" role="progressbar" aria-label="挑戰進度" aria-valuemin="0" aria-valuemax="100">
                    <div id="progressBar" runat="server" class="progress-bar bg-success" style="width:0%"></div>
                </div>
                <asp:Label ID="lblMessage" runat="server" Visible="true" />
            </div>
        </div>

        <div class="row g-4">
            <div class="col-lg-6"><div class="card challenge-card"><div class="card-header"><b>01 IDOR：員工資料越權</b> <asp:Label ID="lblIdorStatus" runat="server" /></div><div class="card-body"><p>使用一般帳號讀取其他員工的詳細資料，並檢查 HTTP 回應標頭。</p><div class="hint mb-3">提示：前端的 disabled 欄位不等於後端授權。</div><div class="input-group"><asp:TextBox ID="txtIdorFlag" runat="server" CssClass="form-control" placeholder="H2C{...}" /><asp:Button ID="btnSubmitIdor" runat="server" Text="提交" CssClass="btn btn-dark" OnClick="btnSubmitIdor_Click" /></div></div></div></div>
            <div class="col-lg-6"><div class="card challenge-card"><div class="card-header"><b>02 SQL Injection：薪資查詢</b> <asp:Label ID="lblSqliStatus" runat="server" /></div><div class="card-body"><p>以管理者身分找出薪資查詢的注入點，使用 UNION 類型查詢取得 Flag。</p><div class="hint mb-3">提示：比較輸入正常數字、單引號與 UNION 時的回應。</div><div class="input-group"><asp:TextBox ID="txtSqliFlag" runat="server" CssClass="form-control" placeholder="H2C{...}" /><asp:Button ID="btnSubmitSqli" runat="server" Text="提交" CssClass="btn btn-dark" OnClick="btnSubmitSqli_Click" /></div></div></div></div>
            <div class="col-lg-6"><div class="card challenge-card"><div class="card-header"><b>03 Stored XSS：消息公告</b> <asp:Label ID="lblXssStatus" runat="server" /></div><div class="card-body"><p>建立會在首頁執行的消息內容，證明輸出未經適當編碼。</p><div class="hint mb-3">提示：除了 script 標籤，也可觀察 HTML 事件屬性。</div><div class="input-group"><asp:TextBox ID="txtXssFlag" runat="server" CssClass="form-control" placeholder="H2C{...}" /><asp:Button ID="btnSubmitXss" runat="server" Text="提交" CssClass="btn btn-dark" OnClick="btnSubmitXss_Click" /></div></div></div></div>
            <div class="col-lg-6"><div class="card challenge-card"><div class="card-header"><b>04 Upload：副檔名繞過</b> <asp:Label ID="lblUploadStatus" runat="server" /></div><div class="card-body"><p>找出上傳驗證只封鎖單一副檔名的問題，成功上傳非圖片檔案。</p><div class="hint mb-3">提示：應用程式只檢查 <code>.aspx</code>。</div><div class="input-group"><asp:TextBox ID="txtUploadFlag" runat="server" CssClass="form-control" placeholder="H2C{...}" /><asp:Button ID="btnSubmitUpload" runat="server" Text="提交" CssClass="btn btn-dark" OnClick="btnSubmitUpload_Click" /></div></div></div></div>
            <div class="col-lg-6"><div class="card challenge-card"><div class="card-header"><b>05 LFI：內部檔案讀取</b> <asp:Label ID="lblLfiStatus" runat="server" /></div><div class="card-body"><p>操控 ImageHandler 的 path 參數，讀取網站內部的 Flag 檔案。</p><div class="hint mb-3">提示：目標位於網站的 <code>App_Data</code> 資料夾。</div><div class="input-group"><asp:TextBox ID="txtLfiFlag" runat="server" CssClass="form-control" placeholder="H2C{...}" /><asp:Button ID="btnSubmitLfi" runat="server" Text="提交" CssClass="btn btn-dark" OnClick="btnSubmitLfi_Click" /></div></div></div></div>
        </div>
    </div>
</form>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
