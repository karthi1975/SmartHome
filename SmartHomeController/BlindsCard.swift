import SwiftUI

struct BlindsCard: View {
    var onClose: (() -> Void)?
    var onDown: (() -> Void)?
    var onUp: (() -> Void)?
    var onOpen: (() -> Void)?
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(0..<5) { idx in
                    Group {
                        if idx == 0 {
                            VStack(spacing: 4) {
                                Button(action: { onClose?() }) {
                                    Image("DownMax_Smarthome")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 48, height: 48)
                                        .background(
                                            Image("ButtonBase_Smarthome")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                                Text("Close")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                        } else if idx == 1 {
                            VStack(spacing: 4) {
                                Button(action: { onDown?() }) {
                                    Image("Down_Smarthome")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 48, height: 48)
                                        .background(
                                            Image("ButtonBase_Smarthome")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                                Text("Down")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                        } else if idx == 2 {
                            VStack(spacing: 4) {
                                Image("BlindsIcon_Smarthome")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 48, height: 48)
                                Spacer().frame(height: 17)
                            }
                        } else if idx == 3 {
                            VStack(spacing: 4) {
                                Button(action: { onUp?() }) {
                                    Image("Up_Smarthome")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 48, height: 48)
                                        .background(
                                            Image("ButtonBase_Smarthome")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                                Text("Up")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                        } else if idx == 4 {
                            VStack(spacing: 4) {
                                Button(action: { onOpen?() }) {
                                    Image("UpMax_Smarthome")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 48, height: 48)
                                        .background(
                                            Image("ButtonBase_Smarthome")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                                Text("Open")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            Divider()
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(.systemGray4), lineWidth: 1)
                .background(Color(.systemGray6).cornerRadius(18))
        )
        .padding(.horizontal, 8)
    }
}

#if DEBUG
struct BlindsCard_Previews: PreviewProvider {
    static var previews: some View {
        BlindsCard()
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif 
