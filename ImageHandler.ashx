<%@ WebHandler Language="C#" Class="ImageHandler" %>

<script runat="server">
    public class ImageHandler : System.Web.IHttpHandler
    {
        public void ProcessRequest(System.Web.HttpContext context)
        {
            // 設定 UTF-8 編碼
            context.Response.ContentEncoding = System.Text.Encoding.UTF8;
            
            // 🚨 這是 LFI/Path Traversal 的漏洞點 🚨
            string relativePath = context.Request.QueryString["path"];

            if (string.IsNullOrEmpty(relativePath))
            {
                context.Response.ContentType = "text/plain; charset=UTF-8";
                context.Response.Write("錯誤: 未指定檔案路徑。請在 path 參數中提供檔案。");
                return;
            }

            try
            {
                // ❌ 未對路徑進行淨化或限制。允許 ../../ 等路徑遍歷。
                string fullPath = context.Server.MapPath(relativePath);

                if (System.IO.File.Exists(fullPath))
                {
                    string extension = System.IO.Path.GetExtension(fullPath).ToLower();
                    string contentType = "application/octet-stream"; // 預設

                    if (extension == ".jpg" || extension == ".jpeg")
                        contentType = "image/jpeg";
                    else if (extension == ".png")
                        contentType = "image/png";
                    else if (extension == ".gif")
                        contentType = "image/gif";
                    // 攻擊者可以嘗試讀取 web.config, machine.config, 或 Windows 系統檔案

                    context.Response.ContentType = contentType;
                    context.Response.WriteFile(fullPath);
                }
                else
                {
                    context.Response.ContentType = "text/plain; charset=UTF-8";
                    context.Response.Write("檔案不存在: " + fullPath);
                }
            }
            catch (System.Exception ex)
            {
                // 為了 CTF 提示，輸出錯誤信息
                context.Response.ContentType = "text/plain; charset=UTF-8";
                context.Response.Write("處理錯誤: " + ex.Message);
            }
        }

        public bool IsReusable
        {
            get
            {
                return false;
            }
        }
    }
</script>