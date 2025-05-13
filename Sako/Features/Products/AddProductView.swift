import SwiftUI
import SwiftData

struct AddProductView: View {
    @Query private var products: [Products]

    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var name: String = ""
    @State private var priceInput: String = ""
    @State private var formattedPrice: String = ""
    @State private var priceError: String? = nil
    @State private var nameError: String? = nil
    
    private var canSave: Bool {
        !name.isEmpty && !priceInput.isEmpty && nameError == nil && priceError == nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Text("Batal")
                    }
                    .padding(.vertical, 8)
                }
                .foregroundColor(.blue)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 16)

            Text("Tambah Produk")
                .font(.system(size: 28, weight: .bold))
                .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nama Produk")
                            .font(.headline)
                            .padding(.horizontal, 5)
                        TextField("Contoh: Nasi Goreng", text: $name)
                            .autocorrectionDisabled()
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                            .onChange(of: name) {
                                validateName()
                            }
                        
                        if let error = nameError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 5)
                        }
                        Text("Maksimal 25 karakter")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 5)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Harga")
                            .font(.headline)
                            .padding(.horizontal, 5)
                        TextField("Contoh: 15.000", text: $formattedPrice)
                            .autocorrectionDisabled()
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                            .onChange(of: formattedPrice) { oldValue, newValue in
                                let filtered = newValue.filter { $0.isNumber }
                                
                                priceInput = filtered
                                
                                if let number = Int(filtered) {
                                    formattedPrice = number.formattedWithSeparator()
                                } else {
                                    formattedPrice = filtered
                                }
                                
                                validatePrice()
                            }
                        
                        if let error = priceError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 5)
                        }
                        Text("Hanya angka")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 5)
                    }
                }
                .padding()
            }

            Spacer()

            Button {
                if validateName() {
                    simpanProduk()
                }
            } label: {
                Text("Simpan")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSave ? Color.green : Color.gray)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
            .disabled(!canSave)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
    
    @discardableResult
    private func validateName() -> Bool {
        nameError = ProductValidator.validateName(name, existingProducts: products)
        return nameError == nil
    }

    @discardableResult
    private func validatePrice() -> Bool {
        priceError = ProductValidator.validatePrice(priceInput)
        return priceError == nil
    }
    
    private func simpanProduk() {
        guard validateName() else { return }
        
        guard let harga = Int(priceInput) else { return }
        
        let newProduct = Products(name: name, price: harga)
        context.insert(newProduct)
        try? context.save()
        dismiss()
    }
}
