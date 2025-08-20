import SwiftUI
import ProtonUIFoundations

public struct CurrentPlansView: View {

    @ObservedObject var viewModel: CurrentPlansViewModel
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var appleSubscriptionManager = AppleSubscriptionManager.shared

    private struct Constants {
        static let titleTextSize: CGFloat = 18
        static let titleFontWeight: Font.Weight = .bold

        static let descriptionTextSize: CGFloat = 15
        static let descriptionFontWeight: Font.Weight = .regular
    }

    public var body: some View {
        ZStack {
            Color(Theme.color.backgroundNorm)
                .ignoresSafeArea()

            VStack {
                //MARK: Modal presentation close button
                
                HStack {
                    // Refresh button for Apple subscription status
                    Button {
                        appleSubscriptionManager.refreshSubscriptionStatuses()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .tint(Theme.color.textNorm)
                            .opacity(appleSubscriptionManager.isLoading ? 0.5 : 1.0)
                    }
                    .disabled(appleSubscriptionManager.isLoading)
                    .padding(Theme.spacing.extraLarge)
                    
                    Spacer()
                    
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(uiImage: Theme.icon.cross)
                            .tint(Theme.color.textNorm)
                    }
                    .padding(Theme.spacing.extraLarge)
                }
                
                
                VStack {
                    Image("LumoUpgradeIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 120)
                        .padding(.bottom, 8)
                        .padding(.top, -30)
                }
                    
                
                Text(String(localized: "current.plans.title"))
                    .font(.system(size: Constants.titleTextSize))
                    .fontWeight(Constants.titleFontWeight)
                    .foregroundColor(Theme.color.textNorm)
                    .padding(.bottom, 10)

                HStack {
                    Text(String(localized: "current.plans.section.title"))
                        .font(.system(size: Constants.descriptionTextSize))
                        .fontWeight(Constants.descriptionFontWeight)
                        .foregroundColor(Theme.color.textWeak)
                        .padding(.horizontal, Theme.spacing.medium)
                    Spacer()
                }

                switch viewModel.viewState {
                case .dataLoaded:
                   CurrentPlansBodyView(viewModel: viewModel)
                case .loading:
                    SubscriptionLoadingView(loadingMessage: String(localized: "current.plans.loading.message"))
                case .errorData, .idle:
                   ErrorView(buttonAction: {})
                case .noData:
                    NoSubscriptionsView()
                }
            }
            .bannerDisplayable(bannerState: $viewModel.showAlert, configuration: .default())
        }
    }
}

#if DEBUG
#Preview {
    // Current plan
    let currentPlan = PlanViewModel(currentPlan: PreviewsData.currentSub)

    let viewModel = CurrentPlansViewModel(plansData: [PreviewsData.currentSub, PreviewsData.currentSub])
    viewModel.showBanner()
    viewModel.setCurrentPlans([currentPlan, currentPlan])

    //viewModel.setViewState(.errorData)

    return CurrentPlansView(viewModel: viewModel)
}
#endif

