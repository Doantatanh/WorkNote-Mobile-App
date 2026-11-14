import SwiftUI
import UIKit

public struct AuthView: View {
    @ObservedObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var isSignUpMode: Bool = false
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var fullName: String = ""
    @State private var isPasswordVisible: Bool = false

    public init(authService: AuthService) {
        self.authService = authService
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Top Brand Logo
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color(red: 0.95, green: 0.55, blue: 0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)
                            .shadow(color: Color.orange.opacity(0.4), radius: 12, x: 0, y: 6)

                        Image(systemName: "mic.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 24)

                    VStack(spacing: 4) {
                        Text("WorkNote Cloud")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(.primary)

                        Text(isSignUpMode ? "Tạo tài khoản Supabase miễn phí để đồng bộ đám mây" : "Đăng nhập để đồng bộ công việc & bản ghi âm")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }

                // Mode Segmented Switch (Đăng nhập / Đăng ký)
                HStack(spacing: 0) {
                    Button(action: { isSignUpMode = false }) {
                        Text("Đăng nhập")
                            .font(.system(size: 13, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(!isSignUpMode ? Color.primary : Color.clear)
                            .foregroundColor(!isSignUpMode ? Color(.systemBackground) : .secondary)
                            .cornerRadius(10)
                    }

                    Button(action: { isSignUpMode = true }) {
                        Text("Đăng ký mới")
                            .font(.system(size: 13, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isSignUpMode ? Color.primary : Color.clear)
                            .foregroundColor(isSignUpMode ? Color(.systemBackground) : .secondary)
                            .cornerRadius(10)
                    }
                }
                .padding(4)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(14)
                .padding(.horizontal, 20)

                // Error Banner if any
                if let error = authService.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                }

                // Input Fields
                VStack(spacing: 14) {
                    if isSignUpMode {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Họ và tên")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)

                            TextField("Ví dụ: Nguyễn Hoàng Nam", text: $fullName)
                                .padding(12)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .font(.system(size: 14))
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Địa chỉ Email")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)

                        TextField("email@example.com", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(12)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .font(.system(size: 14))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mật khẩu")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)

                        HStack {
                            if isPasswordVisible {
                                TextField("Tối thiểu 6 ký tự", text: $password)
                            } else {
                                SecureField("Tối thiểu 6 ký tự", text: $password)
                            }

                            Button(action: { isPasswordVisible.toggle() }) {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .font(.system(size: 14))
                    }
                }
                .padding(.horizontal, 20)

                // Submit Button
                Button(action: handleAuthAction) {
                    HStack(spacing: 8) {
                        if authService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isSignUpMode ? "Tạo tài khoản Supabase" : "Đăng nhập ngay")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.indigo, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Color.indigo.opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .disabled(authService.isLoading || email.isEmpty || password.count < 6)
                .opacity((email.isEmpty || password.count < 6) ? 0.6 : 1.0)
                .padding(.horizontal, 20)

                // Apple ID Mockup
                VStack(spacing: 12) {
                    HStack {
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 0.5)
                        Text("HOẶC")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 0.5)
                    }
                    .padding(.horizontal, 30)

                    // Guest mode option (Dùng thử Offline không cần tài khoản)
                    Button(action: {
                        authService.continueAsGuest()
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.right.circle")
                            Text("Dùng thử Offline (Không cần tài khoản)")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.indigo)
                        .padding(.vertical, 8)
                    }
                }
                .padding(.top, 4)
            }
            .padding(.bottom, 30)
        }
    }

    private func handleAuthAction() {
        Task {
            if isSignUpMode {
                let success = await authService.signUp(email: email, password: password, fullName: fullName)
                if success { dismiss() }
            } else {
                let success = await authService.signIn(email: email, password: password)
                if success { dismiss() }
            }
        }
    }
}
