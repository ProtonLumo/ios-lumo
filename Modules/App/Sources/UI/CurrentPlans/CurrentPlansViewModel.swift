import Foundation
import ProtonUIFoundations

@MainActor
class CurrentPlansViewModel: ObservableObject {
    private struct Constants {
        static var bottomPadding: CGFloat {
            75
        }
    }

    @Published var viewState: State = .idle
    @Published var currentPlans: [PlanViewModel] = []

    enum State {
        case loading
        case dataLoaded
        case errorData
        case idle
        case noData
    }

    private var availablePlansViewModels: [PlanViewModel] = []
    var currentPlan: PlanViewModel?

    var bottomPadding: CGFloat {
        Constants.bottomPadding
    }

    init(plansData: [CurrentSubscriptionResponse]) {
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

        func setViewState(_ state: State) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self else { return }
                self.viewState = state
            }
        }
    #endif
}
