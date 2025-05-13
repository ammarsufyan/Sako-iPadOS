//
//  DestinationTabs.swift
//  Sako
//
//  Created by Ammar Sufyan on 13/05/25.
//

import SwiftUI

struct DestinationTabs: View {
    var body : some View {
        TabView {
            Tab("Rekapan", systemImage: "chart.bar.xaxis") {
                RecapView()
            }
            Tab("Penjualan", systemImage: "cart.fill") {
                SalesListView()
            }
            Tab("Produk", systemImage: "shippingbox.fill") {
                ProductListView()
            }
        }
    }
}
