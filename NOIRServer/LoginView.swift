import SwiftUI

struct LoginView: View {
    @EnvironmentObject var store: ServerStore
    @State private var pinInput: String = ""
    @State private var showError: Bool = false
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.04, green: 0.06, blue: 0.12), Color(red: 0.08, green: 0.05, blue: 0.16)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(LinearGradient(colors: [.electricCyan.opacity(0.25), .neonViolet.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 100, height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 28).stroke(LinearGradient(colors: [.electricCyan, .neonViolet], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2))
                    Text("N")
                        .font(.system(size: 50, weight: .black))
                        .foregroundStyle(LinearGradient(colors: [.electricCyan, .white], startPoint: .top, endPoint: .bottom))
                }
                
                VStack(spacing: 8) {
                    Text("NOIR SERVER")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    Text(store.isArabic ? "سجل الدخول برمز المالك أو رمز الدعوة الخاص بك" : "Sign in with Owner PIN or Access Code")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 14) {
                    SecureField(store.isArabic ? "أدخل الرمز (المالك: 0000)" : "Enter PIN", text: $pinInput)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.title3.monospaced().bold())
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(showError ? Color.red : Color.electricCyan.opacity(0.5), lineWidth: 1.5))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    if showError {
                        Text(store.isArabic ? "رمز الدخول غير صحيح!" : "Invalid PIN!")
                            .font(.caption.bold())
                            .foregroundColor(.red)
                    }
                    
                    Button {
                        if store.login(with: pinInput) {
                            showError = false
                            pinInput = ""
                        } else {
                            showError = true
                        }
                    } label: {
                        Text(store.isArabic ? "تسجيل الدخول" : "Sign In")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [.electricCyan, .neonViolet], startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 28)
                
                Spacer()
                
                Button {
                    store.isArabic.toggle()
                } label: {
                    Text(store.isArabic ? "English" : "العربية")
                        .font(.caption.bold())
                        .foregroundColor(.electricCyan)
                }
                .padding(.bottom, 20)
            }
        }
        .environment(\.layoutDirection, store.isArabic ? .rightToLeft : .leftToRight)
    }
}
