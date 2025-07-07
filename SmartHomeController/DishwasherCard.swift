import SwiftUI

struct DishwasherCard: View {
    var status: String
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    Image("Dishwasher_Smarthome")
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
struct DishwasherCard_Previews: PreviewProvider {
    static var previews: some View {
        DishwasherCard(status: "Idle")
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif 