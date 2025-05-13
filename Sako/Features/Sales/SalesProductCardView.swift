import SwiftUI
import SwiftData

struct SalesProductCardView: View {
    let product: Products
    let quantity: Int
    let onQuantityChange: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(product.name)
                .font(.headline)

            HStack {
                Text("Rp\(Int(product.price).formattedWithSeparator())")
                    .font(.subheadline).bold()
                    .foregroundColor(.gray)

                Spacer()

                if quantity > 0 {
                    HStack(spacing: 12) {
                        Button {
                            onQuantityChange(max(quantity - 1, 0))
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.red)
                        }

                        Text("\(quantity)")
                            .font(.body)
                            .frame(width: 30)

                        Button {
                            onQuantityChange(quantity + 1)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.green)
                        }
                    }
                } else {
                    Button {
                        onQuantityChange(1)
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color(.white))
        .cornerRadius(12)
    }
}
