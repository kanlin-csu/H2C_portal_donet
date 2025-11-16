<%@ Page Language="C#" AutoEventWireup="true" ResponseEncoding="UTF-8" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.IO" %>

<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            string path = Request.QueryString["path"];
            if (string.IsNullOrEmpty(path))
            {
                path = Server.MapPath("~/");
            }
            else
            {
                // 處理相對路徑和絕對路徑
                if (Path.IsPathRooted(path))
                {
                    // 絕對路徑
                }
                else
                {
                    // 相對路徑
                    path = Server.MapPath("~/" + path);
                }
            }
            
            LoadDirectory(path);
        }
    }

    private void LoadDirectory(string dirPath)
    {
        try
        {
            // 儲存當前路徑到 ViewState
            ViewState["CurrentPath"] = dirPath;
            lblCurrentPath.Text = dirPath;

            // 取得父目錄
            DirectoryInfo parentDir = Directory.GetParent(dirPath);
            if (parentDir != null)
            {
                lnkParentDir.NavigateUrl = "files.aspx?path=" + Server.UrlEncode(parentDir.FullName);
                lnkParentDir.Visible = true;
            }
            else
            {
                lnkParentDir.Visible = false;
            }

            // 載入目錄和檔案
            List<FileSystemItem> items = new List<FileSystemItem>();

            // 載入子目錄
            if (Directory.Exists(dirPath))
            {
                string[] dirs = Directory.GetDirectories(dirPath);
                foreach (string dir in dirs)
                {
                    DirectoryInfo di = new DirectoryInfo(dir);
                    items.Add(new FileSystemItem
                    {
                        Name = di.Name,
                        Type = "Directory",
                        Size = "",
                        LastModified = di.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss"),
                        Path = dir
                    });
                }

                // 載入檔案
                string[] files = Directory.GetFiles(dirPath);
                foreach (string file in files)
                {
                    FileInfo fi = new FileInfo(file);
                    items.Add(new FileSystemItem
                    {
                        Name = fi.Name,
                        Type = "File",
                        Size = FormatFileSize(fi.Length),
                        LastModified = fi.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss"),
                        Path = file
                    });
                }
            }

            fileGrid.DataSource = items;
            fileGrid.DataBind();
        }
        catch (Exception ex)
        {
            lblMessage.Text = "載入目錄時發生錯誤: " + ex.Message;
            lblMessage.CssClass = "alert alert-danger";
            lblMessage.Visible = true;
        }
    }

    private string FormatFileSize(long bytes)
    {
        string[] sizes = { "B", "KB", "MB", "GB" };
        double len = bytes;
        int order = 0;
        while (len >= 1024 && order < sizes.Length - 1)
        {
            order++;
            len = len / 1024;
        }
        return string.Format("{0:0.##} {1}", len, sizes[order]);
    }

    protected void btnUpload_Click(object sender, EventArgs e)
    {
        if (fileUploader.HasFile)
        {
            string currentPath = ViewState["CurrentPath"] as string;
            if (string.IsNullOrEmpty(currentPath))
            {
                currentPath = Server.MapPath("~/");
            }

            string fileName = fileUploader.FileName;
            string fullPath = Path.Combine(currentPath, fileName);

            try
            {
                fileUploader.SaveAs(fullPath);
                lblMessage.Text = "檔案上傳成功: " + fileName;
                lblMessage.CssClass = "alert alert-success";
                lblMessage.Visible = true;
                LoadDirectory(currentPath);
            }
            catch (Exception ex)
            {
                lblMessage.Text = "上傳失敗: " + ex.Message;
                lblMessage.CssClass = "alert alert-danger";
                lblMessage.Visible = true;
            }
        }
        else
        {
            lblMessage.Text = "請選擇要上傳的檔案。";
            lblMessage.CssClass = "alert alert-warning";
            lblMessage.Visible = true;
        }
    }

    protected void btnCreateFolder_Click(object sender, EventArgs e)
    {
        string folderName = txtFolderName.Text.Trim();
        if (string.IsNullOrEmpty(folderName))
        {
            lblMessage.Text = "請輸入資料夾名稱。";
            lblMessage.CssClass = "alert alert-warning";
            lblMessage.Visible = true;
            return;
        }

        string currentPath = ViewState["CurrentPath"] as string;
        if (string.IsNullOrEmpty(currentPath))
        {
            currentPath = Server.MapPath("~/");
        }

        string fullPath = Path.Combine(currentPath, folderName);

        try
        {
            Directory.CreateDirectory(fullPath);
            lblMessage.Text = "資料夾建立成功: " + folderName;
            lblMessage.CssClass = "alert alert-success";
            lblMessage.Visible = true;
            txtFolderName.Text = "";
            LoadDirectory(currentPath);
        }
        catch (Exception ex)
        {
            lblMessage.Text = "建立資料夾失敗: " + ex.Message;
            lblMessage.CssClass = "alert alert-danger";
            lblMessage.Visible = true;
        }
    }

    protected void fileGrid_RowCommand(object sender, GridViewCommandEventArgs e)
    {
        if (e.CommandName == "Download")
        {
            string filePath = e.CommandArgument.ToString();
            
            if (File.Exists(filePath))
            {
                FileInfo fi = new FileInfo(filePath);
                Response.Clear();
                Response.ContentType = "application/octet-stream";
                Response.AddHeader("Content-Disposition", "attachment; filename=\"" + fi.Name + "\"");
                Response.AddHeader("Content-Length", fi.Length.ToString());
                Response.TransmitFile(filePath);
                Response.End();
            }
        }
        else if (e.CommandName == "Delete")
        {
            string itemPath = e.CommandArgument.ToString();
            string currentPath = ViewState["CurrentPath"] as string;

            try
            {
                if (Directory.Exists(itemPath))
                {
                    Directory.Delete(itemPath, true);
                    lblMessage.Text = "資料夾刪除成功。";
                }
                else if (File.Exists(itemPath))
                {
                    File.Delete(itemPath);
                    lblMessage.Text = "檔案刪除成功。";
                }
                else
                {
                    lblMessage.Text = "找不到指定的項目。";
                }
                lblMessage.CssClass = "alert alert-success";
                lblMessage.Visible = true;
                LoadDirectory(currentPath);
            }
            catch (Exception ex)
            {
                lblMessage.Text = "刪除失敗: " + ex.Message;
                lblMessage.CssClass = "alert alert-danger";
                lblMessage.Visible = true;
            }
        }
    }

    public class FileSystemItem
    {
        public string Name { get; set; }
        public string Type { get; set; }
        public string Size { get; set; }
        public string LastModified { get; set; }
        public string Path { get; set; }
    }
</script>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>檔案管理工具</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet" />
    <style>
        body {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            font-family: 'Microsoft JhengHei', '微軟正黑體', Arial, sans-serif;
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
        .path-display {
            background: #f8f9fa;
            padding: 0.75rem;
            border-radius: 5px;
            font-family: monospace;
            word-break: break-all;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server" enctype="multipart/form-data">
        <div class="container main-container">
            <div class="card">
                <div class="card-header">
                    <h4 class="mb-0"><i class="bi bi-folder-fill"></i> 檔案管理工具</h4>
                </div>
                <div class="card-body p-4">
                    <asp:Label ID="lblMessage" runat="server" CssClass="alert d-block" Visible="false"></asp:Label>
                    
                    <!-- 當前路徑 -->
                    <div class="mb-3">
                        <label class="form-label"><i class="bi bi-folder"></i> 當前路徑</label>
                        <div class="path-display">
                            <asp:Label ID="lblCurrentPath" runat="server"></asp:Label>
                        </div>
                        <asp:HyperLink ID="lnkParentDir" runat="server" CssClass="btn btn-sm btn-outline-secondary mt-2">
                            <i class="bi bi-arrow-up"></i> 上一層
                        </asp:HyperLink>
                    </div>

                    <!-- 上傳檔案 -->
                    <div class="card mb-4" style="background: #f8f9fa;">
                        <div class="card-body">
                            <h5 class="mb-3"><i class="bi bi-cloud-upload"></i> 上傳檔案</h5>
                            <div class="row">
                                <div class="col-md-8">
                                    <asp:FileUpload ID="fileUploader" runat="server" CssClass="form-control" />
                                </div>
                                <div class="col-md-4">
                                    <asp:Button ID="btnUpload" runat="server" Text="上傳" OnClick="btnUpload_Click" CssClass="btn btn-primary w-100" />
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 建立資料夾 -->
                    <div class="card mb-4" style="background: #f8f9fa;">
                        <div class="card-body">
                            <h5 class="mb-3"><i class="bi bi-folder-plus"></i> 建立資料夾</h5>
                            <div class="row">
                                <div class="col-md-8">
                                    <asp:TextBox ID="txtFolderName" runat="server" CssClass="form-control" placeholder="輸入資料夾名稱"></asp:TextBox>
                                </div>
                                <div class="col-md-4">
                                    <asp:Button ID="btnCreateFolder" runat="server" Text="建立" OnClick="btnCreateFolder_Click" CssClass="btn btn-primary w-100" />
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 檔案列表 -->
                    <div class="table-responsive">
                        <asp:GridView ID="fileGrid" runat="server" AutoGenerateColumns="False" 
                            OnRowCommand="fileGrid_RowCommand" CssClass="table table-hover">
                            <Columns>
                                <asp:TemplateField HeaderText="類型">
                                    <ItemTemplate>
                                        <%# Eval("Type").ToString() == "Directory" ? 
                                            "<i class='bi bi-folder-fill text-warning'></i> 資料夾" : 
                                            "<i class='bi bi-file-earmark text-primary'></i> 檔案" %>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:BoundField DataField="Name" HeaderText="名稱" />
                                <asp:BoundField DataField="Size" HeaderText="大小" />
                                <asp:BoundField DataField="LastModified" HeaderText="修改時間" />
                                <asp:TemplateField HeaderText="操作">
                                    <ItemTemplate>
                                        <asp:PlaceHolder ID="phDirectory" runat="server" Visible='<%# Eval("Type").ToString() == "Directory" %>'>
                                            <a href='files.aspx?path=<%# Server.UrlEncode(Eval("Path").ToString()) %>' class="btn btn-sm btn-info">
                                                <i class="bi bi-folder-open"></i> 開啟
                                            </a>
                                        </asp:PlaceHolder>
                                        <asp:PlaceHolder ID="phFile" runat="server" Visible='<%# Eval("Type").ToString() == "File" %>'>
                                            <asp:LinkButton ID="btnDownload" runat="server" CommandName="Download" 
                                                CommandArgument='<%# Eval("Path") %>' 
                                                CssClass="btn btn-sm btn-success">
                                                <i class="bi bi-download"></i> 下載
                                            </asp:LinkButton>
                                        </asp:PlaceHolder>
                                        <asp:LinkButton ID="btnDelete" runat="server" CommandName="Delete" 
                                            CommandArgument='<%# Eval("Path") %>' 
                                            CssClass="btn btn-sm btn-danger"
                                            OnClientClick="return confirm('確定要刪除這個項目嗎？');">
                                            <i class="bi bi-trash"></i> 刪除
                                        </asp:LinkButton>
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                            <EmptyDataTemplate>
                                <div class="text-center text-muted py-4">
                                    <i class="bi bi-inbox" style="font-size: 3rem;"></i>
                                    <p class="mt-3">目前目錄為空</p>
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

