import SwiftUI

struct ContentView: View {
    let model: ChartScreenModel

    init(model: ChartScreenModel = ChartScreenModel()) {
        self.model = model
    }

    var body: some View {
        ChartScreen(model: model)
            .frame(
                minWidth: DesignSize.chartMinimumWidth,
                minHeight: DesignSize.chartMinimumHeight
            )
    }
}

#Preview {
    ContentView()
}
