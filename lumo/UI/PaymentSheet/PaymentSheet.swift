import SwiftUI
import ProtonUIFoundations

// MARK: - Skeleton Loading Views
struct SkeletonPlanCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.2))
            .frame(height: 80)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.white.opacity(0.6),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: isAnimating ? 300 : -300)
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                    .clipped()
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct SkeletonFeatureRow: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon placeholder
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 20, height: 20)
            
            // Text placeholders
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)
                    .frame(maxWidth: .infinity)
            }
            
            Spacer()
            
            // Status placeholders
            HStack(spacing: 20) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 12, height: 12)
                
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 12, height: 12)
            }
        }
        .overlay(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color.white.opacity(0.4),
                    Color.clear
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .rotationEffect(.degrees(30))
            .offset(x: isAnimating ? 300 : -300)
            .animation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .clipped()
        )
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
    }
}

struct SkeletonText: View {
    let width: CGFloat
    let height: CGFloat
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray.opacity(0.2))
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.white.opacity(0.6),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: isAnimating ? width + 50 : -(width + 50))
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                    .clipped()
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct PaymentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PaymentSheetViewModel
    @State private var isLoading = false

    private let brandPurple: Color = Theme.color.iconAccent

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                featuresSection
                planOptionsSection
            }
        }
        .background(Theme.color.white)
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text(String(localized: "app.general.ok"))) {
                    if viewModel.isSuccess {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            dismiss()
                        }
                    }
                }
            )
        }
        .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
        .overlay(
            // Transaction Progress Overlay
            Group {
                if viewModel.showTransactionProgress {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        TransactionProgressView(viewModel: viewModel.transactionProgressViewModel)
                            .onCompletion {
                                viewModel.hideTransactionProgress()
                                viewModel.shouldDismiss = true
                            }
                            .onError {
                                Logger.shared.log("PaymentSheet: onError callback triggered from TransactionProgressView")
                            }
                            .onBackToPayment {
                                viewModel.hideTransactionProgress()
                                viewModel.isLoading = false
                            }
                            .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                    }
                    .zIndex(1000)
                }
            }
        )
    }

    private var headerSection: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: 0xF2EEFF),
                    Color(hex: 0xF2EEFF),
                    Color(hex: 0xF2EEFF),
                    .white
                ]),
                startPoint: UnitPoint(x: 0, y: 1),
                endPoint: UnitPoint(x: 1, y: 0)
            )
            .frame(height: 170)
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                            .padding()
                    }
                }
                VStack(spacing: 8) {
                    Image("LumoUpgradeIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 120)
                        .padding(.bottom, 8)
                    
                    Text(viewModel.hasNoPlansAvailable ? "Plans Not Available" : String(localized: "app.payment.elevateExperience"))
                            .font(.system(size: 24, weight: .bold))
                            .padding(.top, 16)
                            .foregroundColor(.black)
                    Text(viewModel.hasNoPlansAvailable ? "Purchase of Lumo Plus is not yet possible. Please try again later." : String(localized: "app.payment.enjoyPremium"))
                            .font(.system(size: 16))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color(.systemGray))
                    
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 6)
            }
        }
    }

    private var featuresSection: some View {
        VStack {
            if !viewModel.hasNoPlansAvailable {
                ZStack {
                    if !viewModel.isLoadingPlans {
                        HStack {
                            Spacer()
                            Rectangle()
                                .fill(Color(hex: 0xF2EEFF))
                                .frame(width: 80)
                                .cornerRadius(15)
                                .padding(.trailing, 30)
                        }
                    }
                    VStack(spacing: 4) {
                        if !viewModel.isLoadingPlans {
                            HStack {
                                Color.clear
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(String(localized: "app.payment.free"))
                                    .font(.system(size: 14, weight: .semibold))
                                    .frame(width: 75, alignment: .center)
                                    .padding(.top, 4)
                                    .foregroundColor(brandPurple)
                                Text(String(localized: "app.payment.plus"))
                                    .font(.system(size: 14, weight: .semibold))
                                    .frame(width: 75, alignment: .center)
                                    .padding(.top, 4)
                                    .foregroundColor(brandPurple)
                            }
                            .padding(.horizontal, 32)
                        }
                        VStack(spacing: 4) {
                            if viewModel.isLoadingPlans {
                                ForEach(0..<3, id: \.self) { _ in
                                    SkeletonFeatureRow()
                                        .padding(.bottom, 8)
                                }
                            } else {
                                ForEach(viewModel.descriptionEntitlements, id: \.self) { model in
                                    FeatureRow(model: model)
                                        .padding(.bottom, 8)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var planOptionsSection: some View {
        VStack(spacing: 5) {
            VStack(spacing: 5) {
                if viewModel.isLoadingPlans {
                    ForEach(0..<2, id: \.self) { _ in
                        SkeletonPlanCard()
                    }
                } else if !viewModel.hasNoPlansAvailable {
                    ForEach(viewModel.planOptions, id: \.id) { model in
                        PlanOption(model: model)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.planOptionSelected(model.id)
                            }
                    }
                }
            }
            .padding(.horizontal)
            if !viewModel.hasNoPlansAvailable {
                Text(String(localized: "app.payment.renewalinfo"))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Theme.color.textWeak)
                    .padding(.top, 5)
            }
            
            if !viewModel.hasNoPlansAvailable {
                Button(action: {
                    handlePurchase()
                }) {
                    
                    ZStack {
                        if viewModel.isLoadingPlans {
                            Text(String(localized: "app.payment.plans.loading"))
                                .font(.system(size: 17, weight: .semibold))
                                .opacity(0.7)
                        } else {
                            Text(viewModel.planTitle.isEmpty ? String(localized: "app.payment.getPlus") : viewModel.planTitle)
                                .font(.system(size: 17, weight: .semibold))
                                .opacity(viewModel.isLoading ? 0 : 1)
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                        }
                    }
                }
                
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.isLoadingPlans || viewModel.hasNoPlansAvailable ? Color.gray.opacity(0.5) : brandPurple)
                .cornerRadius(25)
                .padding(.horizontal)
                .padding(.top, 10)
                .disabled(viewModel.isLoading || viewModel.isLoadingPlans || viewModel.hasNoPlansAvailable)
            }
            
            Button(viewModel.hasNoPlansAvailable ? "Close" : String(format: String(localized: "app.payment.useFree"), viewModel.planTitle)) {
                dismiss()
            }
            .font(.system(size: 15))
            .foregroundColor(brandPurple)
            .padding(.vertical)
        }
        .padding(.top, 10)
    }

    private func handlePurchase() {
        isLoading = true
        Task {
            do {
                try await viewModel.purchaseProduct()
            } catch {
                Logger.shared.log("Purchase error: \(error)")
            }
        }
    }
}

#Preview {
    do {
        let mockResponse = try Bundle.main.loadJsonDataToDic(from: "plans.json")
        let composer = PlansComposer(payload: mockResponse)
        let viewModel = PaymentSheetViewModel(planComposer: composer)
        
        return PaymentSheet(viewModel: viewModel)
    } catch {
        return PaymentSheet(viewModel: PaymentSheetViewModel(planComposer: PlansComposer(payload: [:])))
    }
}
