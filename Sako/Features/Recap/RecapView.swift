import SwiftUI

struct RecapView: View {
    @State private var selectedDate = Date()
    @State private var isPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation {
                    isPresented.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "calendar")
                    Text(formattedDate(selectedDate))
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))
            }
            .background(
                VStack(alignment: .leading, spacing: 0) {
                    Spacer(minLength: 42)
                    
                    if isPresented {
                        MonthYearPicker(selectedDate: $selectedDate)
                            .frame(width: 300, height: 200)
                            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                },
                alignment: .topLeading
            )
        }
        .animation(.easeInOut, value: isPresented)
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date).capitalized
    }
}

#Preview {
    RecapView()
}
