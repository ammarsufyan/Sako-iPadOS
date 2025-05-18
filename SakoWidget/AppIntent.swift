//
//  AppIntent.swift
//  SakoWidget
//
//  Created by Ammar Sufyan on 18/05/25.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "This is a Sako widget." }
}
