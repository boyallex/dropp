import AppKit
import CoreGraphics

final class ShakeDetector {

    private var eventTap: CFMachPort?

    private var isDragging = false

    private var previousPoint: CGPoint?

    private var lastDirection: CGFloat = 0

    private var directionChanges = 0

    private var shakeStartTime: TimeInterval?

    private let onShake: (NSPoint) -> Void

    /// Polls until the user enables Accessibility in System Settings.
    private var permissionPollTimer: Timer?

    init(onShake: @escaping (NSPoint) -> Void) {
        self.onShake = onShake
    }

    func start() {
        // Shows the system Accessibility prompt when the app is not trusted yet.
        // Without this key, AXIsProcessTrusted() only checks and never asks.
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        let isTrusted = AXIsProcessTrustedWithOptions(options)

        if isTrusted {
            installEventTapIfNeeded()
            return
        }

        print(
            """
            DropShake needs Accessibility permission.
            Enable it in the system dialog / System Settings,
            then shake detection will start automatically.
            """
        )

        // Permission is usually toggled in Settings after the prompt;
        // keep checking so the user does not have to relaunch the app.
        startPollingForPermission()
    }

    private func startPollingForPermission() {
        permissionPollTimer?.invalidate()

        permissionPollTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }

            guard AXIsProcessTrusted() else {
                return
            }

            timer.invalidate()
            self.permissionPollTimer = nil
            self.installEventTapIfNeeded()
        }
    }

    private func installEventTapIfNeeded() {
        guard eventTap == nil else {
            return
        }

        let mask =
            (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.leftMouseUp.rawValue)
            | (1 << CGEventType.leftMouseDragged.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: { _, type, event, userInfo in

                guard let userInfo else {
                    return Unmanaged.passUnretained(event)
                }

                let detector =
                    Unmanaged<ShakeDetector>
                    .fromOpaque(userInfo)
                    .takeUnretainedValue()

                detector.handle(
                    type: type,
                    event: event
                )

                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self)
                .toOpaque()
        )

        guard let eventTap else {
            print("Failed to create event tap")
            return
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(
            kCFAllocatorDefault,
            eventTap,
            0
        )

        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            runLoopSource,
            .commonModes
        )

        CGEvent.tapEnable(
            tap: eventTap,
            enable: true
        )
    }

    private func handle(
        type: CGEventType,
        event: CGEvent
    ) {

        switch type {

        case .leftMouseDown:

            isDragging = false
            previousPoint = event.location
            lastDirection = 0
            directionChanges = 0
            shakeStartTime = nil

        case .leftMouseDragged:

            isDragging = true

            handleDrag(
                point: event.location
            )

        case .leftMouseUp:

            reset()

        default:
            break
        }
    }

    private func handleDrag(
        point: CGPoint
    ) {

        guard let previousPoint else {
            self.previousPoint = point
            return
        }

        let dx = point.x - previousPoint.x
        let dy = point.y - previousPoint.y

        self.previousPoint = point

        let dominantDelta =
            abs(dx) > abs(dy)
            ? dx
            : dy

        guard abs(dominantDelta) > 8 else {
            return
        }

        let direction: CGFloat =
            dominantDelta > 0 ? 1 : -1

        if shakeStartTime == nil {
            shakeStartTime =
                ProcessInfo.processInfo.systemUptime
        }

        if lastDirection != 0,
            direction != lastDirection
        {

            directionChanges += 1
        }

        lastDirection = direction

        let now =
            ProcessInfo.processInfo.systemUptime

        guard let start = shakeStartTime else {
            return
        }

        let elapsed = now - start

        if directionChanges >= 3,
            elapsed < 0.8
        {

            let screenPoint = NSPoint(
                x: point.x,
                y: point.y
            )

            reset()

            DispatchQueue.main.async {
                self.onShake(screenPoint)
            }
        }

        if elapsed > 0.8 {
            directionChanges = 0
            shakeStartTime = now
        }
    }

    private func reset() {

        isDragging = false
        previousPoint = nil
        lastDirection = 0
        directionChanges = 0
        shakeStartTime = nil
    }
}
