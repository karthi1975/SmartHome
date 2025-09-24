import SwiftUI

struct ToasterCard: View {
    var isOn: Bool
    var onToggle: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    Image("Toaster_Smarthome")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                    Text(isOn ? "Toasting" : "Ready")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                    Text("Status")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Button(action: { onToggle?() }) {
                        Image("Power_Smarthome")
                            .resizable()
                            .frame(width: 36, height: 36)
                    }
                    Text(isOn ? "On" : "Off")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
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
struct ToasterCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ToasterCard(isOn: false, onToggle: {})
            ToasterCard(isOn: true, onToggle: {})
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif 