import SwiftUI
import os.log
import ProtonUIFoundations


struct LumoNavigationBar: View {
    let currentURL: URL?
    let onBackButtonPress: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBackButtonPress) {
                    HStack(spacing: 8) {
                        Image("LumoIcon")
                            .resizable()
                            .frame(width: 20, height: 20)
                         
                        Text(String(localized: "app.navigation.back"))
                            .font(.system(size: 16, weight: .medium))
                    }
                    .contentShape(Rectangle())
                    .accessibilityLabel(String(localized: "app.navigation.back"))
                }
                .foregroundColor(Theme.color.brandNorm)
                .padding(8)
                
                Spacer()
                
                if let url = currentURL?.absoluteString {
                    Text(getTitleForURL(url: url))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.color.black)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .background(Theme.color.separatorNorm)
        }
        .background(Color.white)
        .zIndex(2)
    }
    
    private func getTitleForURL(url: String) -> String {
        if url.contains("sign-in") || url.contains("login") {
            return String(localized: "app.navigation.signin")
        } else if url.contains("signup") {
            return String(localized: "app.navigation.signup")
        } else if url.contains("reset-password") {
            return String(localized: "app.navigation.reset_password")
        } else if url.contains("account.proton.me") {
            return String(localized: "app.navigation.account")
        } else if url.contains("payment") || url.contains("subscribe") {
            return String(localized: "app.navigation.payment")
        } else {
            return String(localized: "app.navigation.generic")
        }
    }
}

