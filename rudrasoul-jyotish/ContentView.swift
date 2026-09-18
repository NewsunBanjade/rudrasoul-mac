import SwiftUI

struct ContentView: View {
    @State private var model = ChartScreenModel()

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
