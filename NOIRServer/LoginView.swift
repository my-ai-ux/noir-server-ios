import SwiftUI

struct LoginView: View {
    @EnvironmentObject var store: ServerStore
    @State private var pinInput: String = ""
    @State private var showError: Bool = false
    
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()
            
            VStack(spacing: 28) {
                Spacer()
                
                // شعار N الذهبي
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(red: 0.10, green: 0.10, blue: 0.13))
                        .frame(width: 96, height: 96)
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.amberGold, lineWidth: 2))
                    Text("N")
                        .font(.system(size: 48, weight: .black))
                        .foregroundColor(.amberGold)
                }
                
                VStack(spacing: 8) {
                    Text("NOIR SERVER")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    Text(store.isArabic ? "أدخل رمز الدخول الخاص بك (المالك أو رمز الدعوة)" : "Enter your Owner PIN or Friend Access Code")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 14) {
                    SecureField(store.isArabic ? "رمز الدخول (مثال: 0000)" : "Access Code", text: $pinInput)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.title3.monospaced().bold())
                        .padding()
                        .background(Color(red: 0.10, green: 0.10, blue: 0.13))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(showError ? Color.red : Color.amberGold.opacity(0.4), lineWidth: 1.5))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    
                    if showError {
                        Text(store.isArabic ? "رمز الدخول غير صحيح!" : "Invalid Access Code!")
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
                        Text(store.isArabic ? "دخول إلى لوحة التحكم" : "Unlock Panel")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.amberGold)
                            .foregroundColor(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 28)
                
                Spacer()
                
                Button {
                    store.isArabic.toggle()
                } label: {
                    Text(store.isArabic ? "Switch to English" : "التبديل إلى العربية")
                        .font(.caption.bold())
                        .foregroundColor(.amberGold)
                }
                .padding(.bottom, 20)
            }
        }
        .environment(\.layoutDirection, store.isArabic ? .rightToLeft : .leftToRight)
    }
}
