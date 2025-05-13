import SwiftUI
import Foundation

struct SalesCardView: View {
    @State private var showAllItems = false
    
    let sale: Sales
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pesanan \(index + 1)")
                    .font(.headline)
                    .foregroundColor(.black)

                Spacer()

                Text("Rp\(Int(sale.totalPrice).formattedWithSeparator())")
                    .font(.headline)
                    .foregroundColor(.black)
            }
                
            ForEach(showAllItems ? sale.items : Array(sale.items.prefix(3)), id: \.id) { item in
                HStack {
                    Text(item.product.name)
                        .foregroundColor(.black)
                    Spacer()
                    Text("\(item.quantity)x")
                        .foregroundColor(.black)
                }
            }

            if sale.items.count > 3 {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showAllItems.toggle()
                    }
                }) {
                    HStack() {
                        Spacer()
                        Text(showAllItems ? "Lihat lebih sedikit" : "Lihat lebih banyak")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Image(systemName: showAllItems ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.green)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(Color(.white))
        .cornerRadius(12)
        .padding(.horizontal, 0)
    }
}
