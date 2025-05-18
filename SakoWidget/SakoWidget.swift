//
//  SakoWidget.swift
//  SakoWidget
//
//  Created by Ammar Sufyan on 18/05/25.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = SimpleEntry(date: Date(), configuration: configuration)
        return Timeline(entries: [entry], policy: .never)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

struct SakoWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top row with label and icon
            HStack {
                Text("Total Pendapatan")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Spacer()
                
                Image("WidgetIcon")
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            }

            // Revenue
            Text("Rp100.000.000")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            // Percentage
            HStack(spacing: 0) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
                Text("Rp20.000.000(+46.5%)")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
            }
            .font(.system(size: 16))
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(20)
    }
}

struct SakoWidget: Widget {
    let kind: String = "SakoWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            SakoWidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .supportedFamilies([.systemMedium]) // Only use medium size
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }

    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemMedium) {
    SakoWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley)
}
