//
//  LoopCompletionHUDView.swift
//  Naterade
//
//  Created by Nathan Racklyeft on 5/1/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import UIKit
import LoopKit
import LoopKitUI

public final class LoopCompletionHUDView: BaseHUDView {

    @IBOutlet private weak var loopStateView: LoopStateView!
    
    override public var orderPriority: HUDViewOrderPriority {
        return 2
    }

    private(set) var freshness = LoopCompletionFreshness.stale {
        didSet {
            loopStateView.freshness = freshness
        }
    }

    override public func awakeFromNib() {
        super.awakeFromNib()

        updateDisplay(nil)
    }

    public var loopStatusColors: StateColorPalette = StateColorPalette(unknown: .black, normal: .black, warning: .black, error: .black) {
        didSet {
            loopStateView.loopStatusColors = loopStatusColors
        }
    }
    
    public var loopIconClosed = false {
        didSet {
            loopStateView.open = !loopIconClosed
        }
    }

    public var lastLoopCompleted: Date? {
        didSet {
            if lastLoopCompleted != oldValue {
                loopInProgress = false
            }
        }
    }
    
    public var lastCGMComm: Date?
    public var lastPumpComm: Date?

    public var loopInProgress = false {
        didSet {
            loopStateView.animated = loopInProgress

            if !loopInProgress {
                updateTimer = nil
                assertTimer()
            }
        }
    }

    public var closedLoopDisallowedLocalizedDescription: String?

    public func assertTimer(_ active: Bool = true) {
        if active && window != nil, let date = lastLoopCompleted {
            initTimer(date)
        } else {
            updateTimer = nil
        }
    }

    private func initTimer(_ startDate: Date) {
        let updateInterval = TimeInterval(minutes: 1)

        let timer = Timer(
            fireAt: startDate.addingTimeInterval(2),
            interval: updateInterval,
            target: self,
            selector: #selector(updateDisplay(_:)),
            userInfo: nil,
            repeats: true
        )
        updateTimer = timer

        RunLoop.main.add(timer, forMode: .default)
    }

    private var updateTimer: Timer? {
        willSet {
            if let timer = updateTimer {
                timer.invalidate()
            }
        }
    }

    private lazy var formatterFull: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()

        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.maximumUnitCount = 1
        formatter.unitsStyle = .full

        return formatter
    }()

    private var lastLoopMessage: String = ""

    private lazy var timeAgoFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()

        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.maximumUnitCount = 1
        formatter.unitsStyle = .short

        return formatter
    }()

    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private lazy var timeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter
    }()

    @objc private func updateDisplay(_: Timer?) {
        lastLoopMessage = ""
        let timeAgoToIncludeTimeStamp: TimeInterval = .minutes(20)
        let timeAgoToIncludeDate: TimeInterval = .hours(4)
        if loopIconClosed, let date = lastLoopCompleted {
            let ago = abs(min(0, date.timeIntervalSinceNow))

            freshness = LoopCompletionFreshness(age: ago)

            if let timeString = timeAgoFormatter.string(from: ago) {
                switch traitCollection.preferredContentSizeCategory {
                case UIContentSizeCategory.extraSmall,
                     UIContentSizeCategory.small,
                     UIContentSizeCategory.medium,
                     UIContentSizeCategory.large:
                    // Use a longer form only for smaller text sizes
                    caption?.text = String(format: LocalizedString("%@ ago", comment: "Format string describing the time interval since the last completion date. (1: The localized date components"), timeString)
                default:
                    caption?.text = timeString
                }

                accessibilityLabel = String(format: LocalizedString("Loop ran %@ ago", comment: "Accessbility format label describing the time interval since the last completion date. (1: The localized date components)"), timeString)

                var fullTimeStr: String = ""
                if ago >= timeAgoToIncludeDate {
                    fullTimeStr = String(format: LocalizedString("was at %1$@", comment: "Format string describing last completion. (1: the date"), timeDateFormatter.string(from: date))
                } else if ago >= timeAgoToIncludeTimeStamp {
                    fullTimeStr = String(format: LocalizedString("%1$@ ago at %2$@", comment: "Format string describing last completion. (1: time ago, (2: the date"), timeAgoFormatter.string(from: ago)!, timeFormatter.string(from: date))
                } else if ago < .minutes(1) {
                    fullTimeStr = String(format: LocalizedString("<1 min ago", comment: "Format string describing last completion"))
                } else {
                    fullTimeStr = String(format: LocalizedString("%1$@ ago", comment: "Format string describing last completion. (1: time ago"), timeAgoFormatter.string(from: ago)!)
                }
                lastLoopMessage = String(format: LocalizedString("Last completed loop %1$@.", comment: "Last loop time completed message (1: last loop time string)"), fullTimeStr)
            } else {
                caption?.text = "–"
                accessibilityLabel = nil
            }
        } else if let lastPumpComm, let lastCGMComm {
            let ago = abs(max(min(0, lastPumpComm.timeIntervalSinceNow), min(0, lastCGMComm.timeIntervalSinceNow)))

            freshness = LoopCompletionFreshness(age: ago)
            
            if let timeString = timeAgoFormatter.string(from: ago) {
                switch traitCollection.preferredContentSizeCategory {
                case UIContentSizeCategory.extraSmall,
                    UIContentSizeCategory.small,
                    UIContentSizeCategory.medium,
                    UIContentSizeCategory.large:
                    // Use a longer form only for smaller text sizes
                    caption?.text = String(format: LocalizedString("%@ ago", comment: "Format string describing the time interval since the last cgm or pump communication date. (1: The localized date components"), timeString)
                default:
                    caption?.text = timeString
                }
                
                accessibilityLabel = String(format: LocalizedString("Last device communication ran %@ ago", comment: "Accessbility format label describing the time interval since the last device communication date. (1: The localized date components)"), timeString)
            } else {
                caption?.text = "–"
                accessibilityLabel = nil
            }
        } else {
            caption?.text = "–"
            accessibilityLabel = LocalizedString("Waiting for first run", comment: "Accessibility label describing completion HUD waiting for first run")
        }

        if loopIconClosed {
            accessibilityHint = LocalizedString("Closed loop", comment: "Accessibility hint describing completion HUD for a closed loop")
            accessibilityIdentifier = "loopCompletionHUDLoopStatusClosed"
        } else {
            accessibilityHint = LocalizedString("Open loop", comment: "Accessbility hint describing completion HUD for an open loop")
            accessibilityIdentifier = "loopCompletionHUDLoopStatusOpen"
        }
    }

    override public func didMoveToWindow() {
        super.didMoveToWindow()

        assertTimer()
    }
}

extension LoopCompletionHUDView {
    public var loopCompletionMessage: (title: String, message: String) {
        switch freshness {
        case .fresh:
            if loopStateView.open {
                let reason = closedLoopDisallowedLocalizedDescription ?? LocalizedString(
                    "Tap Settings to toggle Closed Loop ON if you wish for the app to automate your insulin.",
                    comment: "Instructions for user to close loop if it is allowed."
                )
                
                return (
                    title: LocalizedString(
                        "Closed Loop OFF",
                        comment: "Title of fresh loop OFF message"
                    ),
                    message: String(
                        format: LocalizedString(
                            "\n%1$@ is operating with Closed Loop in the OFF position. Your pump and CGM will continue operating, but the app will not adjust dosing automatically.\n\n%2$@",
                            comment: "Fresh closed loop OFF message (1: app name)(2: reason for open loop)"
                        ),
                        Bundle.main.bundleDisplayName,
                        reason
                    )
                )
            } else {
                return (
                    title: LocalizedString(
                        "Closed Loop ON",
                        comment: "Title of fresh closed loop ON message"
                    ),
                    message: String(
                        format: LocalizedString(
                            "\n%1$@\n\n%2$@ is operating with Closed Loop in the ON position.",
                            comment: "Fresh closed loop ON message (1: last loop string) (2: app name)"
                        ),
                        lastLoopMessage,
                        Bundle.main.bundleDisplayName
                    )
                )
            }
        case .aging:
            if loopStateView.open {
                return (
                    title: LocalizedString(
                        "Caution",
                        comment: "Title of aging open loop message"
                    ),
                    message: LocalizedString(
                        "Tap your CGM and insulin pump status icons for more information. Check for potential communication issues with your pump and CGM.",
                        comment: "Aging open loop message"
                    )
                )
            } else {
                return (
                    title: LocalizedString(
                        "Loop Warning",
                        comment: "Title of aging closed loop message"
                    ),
                    message: String(
                        format: LocalizedString(
                            "\n%1$@\n\nTap your CGM and insulin pump status icons for more information. %2$@ will continue trying to complete a loop, but watch for potential communication issues with your pump and CGM.",
                            comment: "Aging loop message (1: last loop string) (2: app name)"
                        ),
                        lastLoopMessage,
                        Bundle.main.bundleDisplayName
                    )
                )
            }
        case .stale:
            if loopStateView.open {
                return (
                    title: LocalizedString(
                        "Device Error",
                        comment: "Title of stale loop message"
                    ),
                    message: LocalizedString(
                        "Tap your CGM and insulin pump status icons for more information. Check for potential communication issues with your pump and CGM.",
                        comment: "Stale open loop message"
                    )
                )
            } else {
                return (
                    title: LocalizedString(
                        "Loop Failure",
                        comment: "Title of red loop message"
                    ),
                    message: String(
                        format: LocalizedString(
                            "\n%1$@\n\nTap your CGM and insulin pump status icons for more information. %2$@ will continue trying to complete a loop, but check for potential communication issues with your pump and CGM.",
                            comment: "Red loop message (1: last loop  string) (2: app name)"
                        ),
                        lastLoopMessage,
                        Bundle.main.bundleDisplayName
                    )
                )
            }
        }
    }
}
