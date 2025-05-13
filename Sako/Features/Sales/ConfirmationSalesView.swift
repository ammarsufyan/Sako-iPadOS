import SwiftUI
import SwiftData

struct ConfirmationSalesView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var isSaving = false
    
    let selectedDate: Date
    let selectedItems: [Products: Int]
    let onSave: () -> Void
    
    
    private var totalHarga: Int {
        selectedItems.reduce(0) { result, entry in
            let (product, quantity) = entry
            return result + (product.price * quantity)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Button("Batal") { dismiss() }
                        .foregroundColor(.blue)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)

                Text("Konfirmasi Penjualan")
                    .font(.system(size: 28, weight: .bold))
                    .padding(.horizontal)
                
                List {
                    ForEach(Array(selectedItems.keys), id: \.id) { product in
                        let quantity = selectedItems[product] ?? 0
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(product.name)
                                    .font(.headline)
                                Text("Rp\(Int(product.price).formattedWithSeparator()) × \(quantity)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text("Rp\(Int(product.price * quantity).formattedWithSeparator())")
                                .bold()
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal,0.3)
                .cornerRadius(16)
            
                HStack {
                    Text("Total")
                        .font(.title3)
                        .bold()
                    Spacer()
                    Text("Rp\(totalHarga.formattedWithSeparator())")
                        .font(.title2)
                        .bold()

                }
                .padding(.horizontal)

                Button {
                    saveTransaction()
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Selesai")
                                .font(.title2)
                                .bold()
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .disabled(isSaving)

                Spacer()
            }
        .background(Color(.systemGray6))
        }

    private func saveTransaction() {
        guard !isSaving else { return }
        isSaving = true

        let sale = Sales(date: selectedDate)

        for (product, quantity) in selectedItems where quantity > 0 {
            let item = ProductsOnSales(product: product, quantity: quantity, priceAtSale: product.price)
            sale.items.append(item)
        }

        context.insert(sale)

        do {
            try context.save()
            isSaving = false
            onSave()
            dismiss()
        } catch {
            print("Gagal menyimpan transaksi:", error.localizedDescription)
            isSaving = false
        }
    }
}
