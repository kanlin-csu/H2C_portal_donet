<%@ WebHandler Language="C#" Class="ImageHandler" %>

using System;
using System.Web;
using System.IO;

public class ImageHandler : IHttpHandler
{
    public void ProcessRequest(HttpContext context)
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

        // 只允許存取 uploads/ 跟 image/ 底下的檔案——
        // 但這是字串前綴檢查，不是真正的路徑正規化比對，
        // relativePath 用 "uploads/../web.config" 這種字串一樣能通過這關，
        // 之後 Server.MapPath 還是會把 ".." 解析掉，真正讀到的是 uploads/ 外面的檔案。
        if (!relativePath.StartsWith("uploads/") && !relativePath.StartsWith("image/"))
        {
            context.Response.ContentType = "text/plain; charset=UTF-8";
            context.Response.Write("禁止存取此路徑。");
            return;
        }

        try
        {
            // ❌ 未對路徑進行淨化或限制。允許 ../../ 等路徑遍歷。
            string fullPath = context.Server.MapPath(relativePath);

            if (File.Exists(fullPath))
            {
                string extension = Path.GetExtension(fullPath).ToLower();
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
        catch (Exception ex)
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