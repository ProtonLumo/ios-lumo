
import Foundation
import ProtonUIFoundations

@MainActor
public class CurrentPlansViewModel: ObservableObject {

    private struct Constants {
        static var bottomPadding: CGFloat {
            return 75
        }
    }

    @Published var filteredPlans: [PlanViewModel] = []
    @Published public var viewState: State = .idle

    @Published var confirmationCompleted: Bool = false
    @Published var updateCompleted: Bool = false
    @Published var showAlert: BannerState = .none
    @Published var currentPlans: [PlanViewModel] = []


    public var hasAvailablePlans: Bool {
        !availablePlansViewModels.isEmpty
    }

    public enum State {
        case loading
        case dataLoaded
        case errorData
        case idle
        case noData
    }

    private var availablePlansViewModels: [PlanViewModel] = []
    public var currentPlan: PlanViewModel?

    public var bottomPadding: CGFloat {
        return Constants.bottomPadding
    }


    public init(plansData: [CurrentSubscriptionResponse]) {
        self.generatePlanViewModels(plansData)
    }

    private func generatePlanViewModels(_ data: [CurrentSubscriptionResponse]) {
        var plans: [PlanViewModel] = []

        for (index, element) in data.enumerated() {
            let planViewModel = index == 0 ? PlanViewModel(currentPlan: element, isExpanded: true) : PlanViewModel(currentPlan: element)
            plans.append(planViewModel)
        }

        DispatchQueue.main.async {
            self.currentPlans = plans
            self.viewState = self.currentPlans.isEmpty ? .noData : .dataLoaded
        }
    }
}

extension CurrentPlansViewModel {
#if DEBUG
    func addPlanViewModels(_ plans: [PlanViewModel]) {
        availablePlansViewModels = plans
    }

    func setCurrentPlans(_ currentPlans: [PlanViewModel]) {
        self.currentPlans = currentPlans
        self.viewState = .dataLoaded
        print(currentPlans.count)
    }

    func showBanner() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self else { return }
            self.showAlert = .error(content: PCBannerContent(message: "Something went wrong!!"))
        }
    }

    func setViewState(_ state: State) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self else { return }
            self.viewState = state
        }
    }
#endif
}
