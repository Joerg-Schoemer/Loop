//
//  EventualGlucoseView.swift
//  Loop Widget Extension
//
//  Created by Noah Brauner on 8/8/24.
//  Copyright © 2024 LoopKit Authors. All rights reserved.
//

import SwiftUI

struct EventualGlucoseView: View {
    let entry: StatusWidgetTimelimeEntry
    
    var body: some View {
        if let eventualGlucose = entry.eventualGlucose {
            let glucoseFormatter = NumberFormatter.glucoseFormatter(for: eventualGlucose.unit)
            if let glucoseString = glucoseFormatter.string(from: eventualGlucose.quantity.doubleValue(for: eventualGlucose.unit)) {
                VStack {
                    Text("Eventual")
                        .font(.footnote)
                        .foregroundColor(entry.contextIsStale ? Color(UIColor.systemGray3) : Color(UIColor.secondaryLabel))
                    
                    Text("\(glucoseString)")
                        .font(.subheadline)
                        .fontWeight(.heavy)
                    
                    Text(eventualGlucose.unit.shortLocalizedUnitString())
                        .font(.footnote)
                        .foregroundColor(entry.contextIsStale ? Color(UIColor.systemGray3) : Color(UIColor.secondaryLabel))
                }
            }
        }
    }
}
