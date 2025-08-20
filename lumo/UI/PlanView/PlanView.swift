import SwiftUI
import ProtonUIFoundations

struct PlanView: View {
    @ObservedObject public var viewModel: PlanViewModel

    public init(viewModel: PlanViewModel) {
        self.viewModel = viewModel
    }

    private struct Constants {
        static let borderWidth: CGFloat = 1

        static var backgroundColor: Color {
            Theme.color.backgroundNorm
        }

        static func borderColor(isExpanded: Bool) -> Color {
            isExpanded ? Theme.color.iconAccent : Theme.color.backgroundSecondary
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing.large) {

            PlanDetailHeaderView(isExpanded: $viewModel.isExpanded,
                                 title: viewModel.title,
                                 description: viewModel.description,
                                 formattedPrice: viewModel.formattedPrice,
                                 formattedPeriod: viewModel.formattedPeriod,
                                 decorationsURLs: nil)

            if viewModel.isExpanded {

                if viewModel.showProgressEntitlements {
                    ForEach(viewModel.progressEntitlements, id: \.self) { progress in
                        ProgressEntitlementView(currentValue: progress.current, maxValue: progress.max, text: progress.text)
                    }
                }

                PlanDetailView(viewModel: viewModel)
                    .padding(.top, Theme.spacing.large)

                if let renewFooter = viewModel.renewFooter {
                    Divider()
                    Text(renewFooter)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Apple subscription management
                if viewModel.showManageSubscriptionButton {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: Theme.spacing.medium) {
                        // Cancellation status indicator
                        if let statusText = viewModel.subscriptionStatusText {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text(statusText)
                                    .font(.caption)
                                    .foregroundColor(Theme.color.textWeak)
                                Spacer()
                            }
                        }
                        
                        // Manage subscription button
                        Button(action: {
                            viewModel.openAppleSubscriptionManagement()
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                    .font(.system(size: 14, weight: .medium))
                                
                                Text(String(localized: "app.payment.managesubscription"))
                                    .font(.system(size: 14, weight: .medium))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(Theme.color.textNorm)
                            .padding(.vertical, Theme.spacing.small)
                            .padding(.horizontal, Theme.spacing.medium)
                            .background(Theme.color.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radius.medium))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .foregroundColor(Theme.color.textNorm)
        .padding(Theme.spacing.large)
        .background(Constants.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radius.large)
                .stroke(Constants.borderColor(isExpanded: viewModel.isExpanded), lineWidth: Constants.borderWidth)
        )
        .onTapGesture {
            withAnimation {
                viewModel.isExpanded.toggle()
            }
        }
    }
}

#if DEBUG
#Preview {
    
    let viewModel = PlanViewModel(currentPlan: PreviewsData.currentSub)
    let viewModel3 = PlanViewModel(currentPlan: PreviewsData.freePlan)

    return PlanView(viewModel: viewModel)
        .padding(12)
}
#endif

