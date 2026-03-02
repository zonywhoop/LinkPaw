import SwiftUI

/// A custom SwiftUI view that renders the LinkPaw logo using vector shapes and gradients.
struct LinkPawIcon: View {
    var size: CGFloat = 200
    
    var body: some View {
        ZStack {
            // Background Glow
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.3), Color.blue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 1.2, height: size * 1.2)
                .blur(radius: size * 0.1)

            // Main Paw Pad
            Group {
                // The four toe pads
                ToePad()
                    .offset(x: -size * 0.25, y: -size * 0.25)
                ToePad()
                    .offset(x: -size * 0.08, y: -size * 0.35)
                ToePad()
                    .offset(x: size * 0.08, y: -size * 0.35)
                ToePad()
                    .offset(x: size * 0.25, y: -size * 0.25)
                
                // The main large pad
                MainPad()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size * 0.6, height: size * 0.5)
                    .offset(y: size * 0.1)
                    .overlay(
                        // The Chain Link integrated into the pad
                        ChainLink()
                            .stroke(
                                LinearGradient(
                                    colors: [.white, .blue.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: size * 0.04
                            )
                            .frame(width: size * 0.3, height: size * 0.2)
                            .offset(y: size * 0.1)
                    )
            }
            .shadow(color: .black.opacity(0.2), radius: size * 0.02, x: 0, y: size * 0.02)
        }
        .frame(width: size, height: size)
    }
}

private struct ToePad: View {
    var body: some View {
        Ellipse()
            .fill(LinearGradient(colors: [.orange, .orange.opacity(0.8)], startPoint: .top, endPoint: .bottom))
            .frame(width: 40, height: 55)
            .rotationEffect(.degrees(0))
    }
}

private struct MainPad: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width * 0.5, y: 0))
        path.addCurve(to: CGPoint(x: width, y: height * 0.7),
                      control1: CGPoint(x: width * 0.9, y: 0),
                      control2: CGPoint(x: width, y: height * 0.3))
        path.addCurve(to: CGPoint(x: width * 0.5, y: height),
                      control1: CGPoint(x: width, y: height * 0.9),
                      control2: CGPoint(x: width * 0.7, y: height))
        path.addCurve(to: CGPoint(x: 0, y: height * 0.7),
                      control1: CGPoint(x: width * 0.3, y: height),
                      control2: CGPoint(x: 0, y: height * 0.9))
        path.addCurve(to: CGPoint(x: width * 0.5, y: 0),
                      control1: CGPoint(x: 0, y: height * 0.3),
                      control2: CGPoint(x: width * 0.1, y: 0))
        path.closeSubpath()
        
        return path
    }
}

private struct ChainLink: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Two interlocking circles/ovals
        let linkW = w * 0.6
        path.addRoundedRect(in: CGRect(x: 0, y: 0, width: linkW, height: h), cornerSize: CGSize(width: h/2, height: h/2))
        path.addRoundedRect(in: CGRect(x: w - linkW, y: 0, width: linkW, height: h), cornerSize: CGSize(width: h/2, height: h/2))
        
        return path
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
