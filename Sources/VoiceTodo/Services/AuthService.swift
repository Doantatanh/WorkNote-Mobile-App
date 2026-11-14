import Foundation
import Combine

public struct AuthUser: Codable, Identifiable, Equatable {
    public var id: String
    public var email: String
    public var fullName: String?
    public var accessToken: String?
    public var refreshToken: String?

    public init(id: String, email: String, fullName: String? = nil, accessToken: String? = nil, refreshToken: String? = nil) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

public class AuthService: ObservableObject {
    @Published public var currentUser: AuthUser?
    @Published public var isAuthenticated: Bool = false
    @Published public var isGuestMode: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?

    private let userDefaultsKey = "voice_todo_supabase_auth_user"

    public init() {
        loadSavedSession()
    }

    /// Khôi phục phiên đăng nhập đã lưu
    private func loadSavedSession() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(AuthUser.self, from: data) {
            self.currentUser = user
            self.isAuthenticated = true
            self.isGuestMode = false
        }
    }

    /// Lưu phiên đăng nhập
    private func saveSession(user: AuthUser) {
        self.currentUser = user
        self.isAuthenticated = true
        self.isGuestMode = false
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    /// Bật chế độ dùng thử Offline không cần tài khoản
    public func continueAsGuest() {
        self.isGuestMode = true
        self.isAuthenticated = false
        self.currentUser = nil
    }

    /// Đăng ký tài khoản mới bằng Email & Mật khẩu qua Supabase Auth
    public func signUp(email: String, password: String, fullName: String = "") async -> Bool {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        guard let url = URL(string: "\(SupabaseConfig.projectURL)/auth/v1/signup") else {
            await setAuthError("URL Supabase không hợp lệ. Vui lòng kiểm tra SupabaseConfig.")
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")

        var bodyDict: [String: Any] = [
            "email": email,
            "password": password
        ]
        if !fullName.isEmpty {
            bodyDict["data"] = ["full_name": fullName]
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyDict)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                await setAuthError("Không nhận được phản hồi từ máy chủ Supabase.")
                return false
            }

            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                // Parse Supabase Auth response
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let userDict = json["user"] as? [String: Any],
                   let userId = userDict["id"] as? String {
                    
                    let token = json["access_token"] as? String
                    let refreshToken = json["refresh_token"] as? String
                    let user = AuthUser(id: userId, email: email, fullName: fullName.isEmpty ? email : fullName, accessToken: token, refreshToken: refreshToken)
                    
                    await MainActor.run {
                        self.saveSession(user: user)
                        self.isLoading = false
                    }
                    return true
                }
            }

            // Parse error message
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = errorJson["msg"] as? String ?? errorJson["error_description"] as? String ?? errorJson["message"] as? String {
                await setAuthError(msg)
            } else {
                await setAuthError("Đăng ký không thành công (Mã lỗi: \(httpResponse.statusCode))")
            }
            return false

        } catch {
            await setAuthError("Lỗi kết nối mạng: \(error.localizedDescription)")
            return false
        }
    }

    /// Đăng nhập tài khoản bằng Email & Mật khẩu
    public func signIn(email: String, password: String) async -> Bool {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        guard let url = URL(string: "\(SupabaseConfig.projectURL)/auth/v1/token?grant_type=password") else {
            await setAuthError("URL Supabase không hợp lệ.")
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

        let bodyDict: [String: Any] = [
            "email": email,
            "password": password
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyDict)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                await setAuthError("Không thể kết nối đến máy chủ.")
                return false
            }

            if httpResponse.statusCode == 200 {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["access_token"] as? String,
                   let userDict = json["user"] as? [String: Any],
                   let userId = userDict["id"] as? String {
                    
                    let refreshToken = json["refresh_token"] as? String
                    let userMeta = userDict["user_metadata"] as? [String: Any]
                    let fullName = userMeta?["full_name"] as? String

                    let user = AuthUser(
                        id: userId,
                        email: email,
                        fullName: fullName ?? email,
                        accessToken: token,
                        refreshToken: refreshToken
                    )

                    await MainActor.run {
                        self.saveSession(user: user)
                        self.isLoading = false
                    }
                    return true
                }
            }

            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = errorJson["error_description"] as? String ?? errorJson["msg"] as? String {
                await setAuthError(msg)
            } else {
                await setAuthError("Email hoặc mật khẩu không chính xác.")
            }
            return false

        } catch {
            await setAuthError("Lỗi mạng: \(error.localizedDescription)")
            return false
        }
    }

    /// Đăng xuất tài khoản
    public func signOut() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        self.currentUser = nil
        self.isAuthenticated = false
        self.isGuestMode = false
    }

    private func setAuthError(_ msg: String) async {
        await MainActor.run {
            self.errorMessage = msg
            self.isLoading = false
        }
    }
}
