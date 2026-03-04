import AppKit
import SwiftUI

final class MenuHostingItem: NSMenuItem {
    init<V: View>(_ view: V, width: CGFloat) {
        super.init(title: "", action: nil, keyEquivalent: "")
        let wrapped = view
            .frame(width: width)
            .fixedSize(horizontal: false, vertical: true)
        let hostingView = NSHostingView(rootView: wrapped)
        hostingView.frame.size = hostingView.fittingSize
        self.view = hostingView
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
}
