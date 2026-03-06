import SwiftUI

/// A custom SwiftUI view that renders the LinkPaw logo using the AppIcon image asset.
struct LinkPawIcon: View {
    var size: CGFloat = 200
    
    var body: some View {
        Image("AppIcon")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}

struct LinkPawIcon_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(NSColor.windowBackgroundColor)
            LinkPawIcon(size: 300)
        }
    }
}
