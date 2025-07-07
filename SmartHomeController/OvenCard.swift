import SwiftUI

struct OvenCard: View {
    var status: String
    var temperature: String
    var isOn: Bool
    var onPowerToggle: (() -> Void)?
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Image("Oven_Smarthome")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                    Text(status)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                    Text("Current Status")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                VStack(spacing: 4) {
                    Text(temperature)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                    Text("Current Temp")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                Button(action: { onPowerToggle?() }) {
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray4), lineWidth: 2)
                            .frame(width: 40, height: 40)
                        Image(systemName: isOn ? "power" : "power")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(isOn ? .red : .gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(isOn ? "Turn oven off" : "Turn oven on")
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
struct OvenCard_Previews: PreviewProvider {
    static var previews: some View {
        OvenCard(status: "On", temperature: "375 °F", isOn: true, onPowerToggle: nil)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif 