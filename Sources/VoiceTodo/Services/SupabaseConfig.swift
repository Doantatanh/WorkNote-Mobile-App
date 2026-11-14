import Foundation

/// Cấu hình kết nối Supabase Cloud (0đ - Miễn phí)
public struct SupabaseConfig {
    /// URL dự án Supabase của bạn
    public static var projectURL = "https://vkxjorgfqnkhazzntgbt.supabase.co"
    
    /// Anon Public API Key từ Dashboard Supabase
    public static var anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZreGpvcmdmcW5raGF6em50Z2J0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQ2NzE3MjIsImV4cCI6MjExMDI0NzcyMn0.y10nuXvueW8AtRE5WfjghDUe5L-FyN33Qx0c-2FAzV4"
    
    /// Tên Storage Bucket để lưu trữ file âm thanh ghi âm .m4a
    public static var audioBucketName = "voice-recordings"
}
