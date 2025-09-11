//
//  SharedZoomTransitionInteraction.swift
//  ZoomedTransition
//
//  Created by Ashish Dutt on 09/09/25.
//

import UIKit

final class SharedZoomInteractionController: NSObject {
    
    // MARK: - Properties
    
    private weak var originView: UIView?
    private weak var viewController: UIViewController?
    private var isCurrentlyInteractive = false
    
    // Visual effects during interaction
    private var initialTransform: CGAffineTransform = .identity
    private let minimumScale: CGFloat = 0.6
    
    // Configuration
    private let completionThreshold: CGFloat = 0.3
    private let velocityThreshold: CGFloat = 300
    
    // For pop transition - to show destination VC behind
    private weak var destinationView: UIView?
    private var isNavigationTransition = false
    
    // MARK: - Initialization
    
    init(originView: UIView?, viewController: UIViewController?) {
        self.originView = originView
        self.viewController = viewController
        super.init()
    }
    
    // MARK: - Public Methods
    
    func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            handleGestureBegan(recognizer)
        case .changed:
            handleGestureChanged(recognizer)
        case .ended, .cancelled:
            handleGestureEnded(recognizer)
        default:
            break
        }
    }
    
    // MARK: - Private Methods
    
    private func handleGestureBegan(_ recognizer: UIPanGestureRecognizer) {
        let velocity = recognizer.velocity(in: recognizer.view)
        
        // Only start for horizontal gestures moving right
        guard abs(velocity.x) > abs(velocity.y), velocity.x > 0 else { return }
        
        print("Starting interactive gesture")
        isCurrentlyInteractive = true
        
        // Store initial state
        if let fromView = viewController?.view {
            initialTransform = fromView.transform
        }
        
        // Determine if this is navigation or modal
        isNavigationTransition = viewController?.presentingViewController == nil
        
        if let navController = viewController?.navigationController {
            navController.setNavigationBarHidden(true, animated: false)
        }
        
        // For navigation transitions, set up the destination view to show behind
        if isNavigationTransition {
            setupNavigationTransition()
        }
    }
    
    private func setupNavigationTransition() {
        guard let navController = viewController?.navigationController,
              navController.viewControllers.count > 1 else { return }
        
        let destinationVC = navController.viewControllers[navController.viewControllers.count - 2]
        let destinationView = destinationVC.view!
        let fromView = viewController!.view!
        
        // Add destination view behind the current view
        if let containerView = fromView.superview {
            containerView.insertSubview(destinationView, belowSubview: fromView)
            destinationView.frame = containerView.bounds
        }
        
        self.destinationView = destinationView
        print("Set up navigation transition with destination view")
    }
    
    private func handleGestureChanged(_ recognizer: UIPanGestureRecognizer) {
        guard isCurrentlyInteractive else { return }
        
        let translation = recognizer.translation(in: recognizer.view)
        let screenWidth = recognizer.view?.frame.width ?? UIScreen.main.bounds.width
        
        // Calculate progress (0.0 to 1.0)
        let progress = max(0, min(1, translation.x / screenWidth))
        
        // Apply Instagram-style visual effects
        applyInteractiveEffects(progress: progress, translation: translation)
    }
    
    private func handleGestureEnded(_ recognizer: UIPanGestureRecognizer) {
        guard isCurrentlyInteractive else { return }
        
        let translation = recognizer.translation(in: recognizer.view)
        let velocity = recognizer.velocity(in: recognizer.view)
        let screenWidth = recognizer.view?.frame.width ?? UIScreen.main.bounds.width
        
        let progress = translation.x / screenWidth
        
        // Determine whether to complete or cancel the transition
        let shouldComplete = progress > completionThreshold || velocity.x > velocityThreshold
        
        if shouldComplete {
            print("Gesture completed - starting manual zoom animation")
            completeTransition()
        } else {
            print("Gesture cancelled - animating back")
            cancelTransition()
        }
        
        isCurrentlyInteractive = false
    }
    
    private func applyInteractiveEffects(progress: CGFloat, translation: CGPoint) {
        guard let fromView = viewController?.view else { return }
        
        // Instagram-style scaling and translation
        let scale = 1 - (progress * (1 - minimumScale))
        
        // Apply transform to the main view
        let transform = CGAffineTransform(scaleX: scale, y: scale)
            .translatedBy(x: translation.x, y: translation.y)
        
        fromView.transform = transform
        
        // FIX 2: Don't counter-scale the container - causes stretching
        // Only lightly counter-scale the text label for readability
        if let label = fromView.viewWithTag(100) as? UILabel {
            let counterScale = min(1.0, 1 / scale * 0.9) // Light counter-scale, max 1.0
            label.transform = CGAffineTransform(scaleX: counterScale, y: counterScale)
        }
    }
    
    private func completeTransition() {
        guard let fromView = viewController?.view else {
            print("❌ No fromView in completeTransition")
            triggerNavigation()
            return
        }
        
        guard let originView = originView else {
            print("❌ No originView in completeTransition")
            triggerNavigation()
            return
        }
        
        print("\n=== STARTING COMPLETION TRANSITION ===")
        print("FromView frame: \(fromView.frame)")
        print("FromView transform: \(fromView.transform)")
        
        // Reset any label transforms
        if let label = fromView.viewWithTag(100) as? UILabel {
            label.transform = .identity
        }
        
        // Calculate target frame with extensive logging
        let finalFrame = calculateFinalFrame(originView: originView, fromView: fromView)
        
        // Additional validation
        let screenBounds = UIScreen.main.bounds
        let isFrameValid = finalFrame.size.width > 0 &&
                           finalFrame.size.height > 0 &&
                           finalFrame.origin.x > -screenBounds.width &&
                           finalFrame.origin.x < screenBounds.width * 2 &&
                           finalFrame.origin.y > -screenBounds.height &&
                           finalFrame.origin.y < screenBounds.height * 2
        
        print("Final frame validation - isValid: \(isFrameValid)")
        print("Final frame: \(finalFrame)")
        
        if !isFrameValid {
            print("⚠️ Final frame seems invalid, using fallback")
            // Fallback: animate to a reasonable position
            let fallbackFrame = CGRect(
                x: screenBounds.width / 2 - 50,
                y: screenBounds.height - 200,
                width: 100,
                height: 100
            )
            animateToFrame(fallbackFrame, fromView: fromView)
        } else {
            animateToFrame(finalFrame, fromView: fromView)
        }
    }

    private func animateToFrame(_ targetFrame: CGRect, fromView: UIView) {
        print("🎬 Animating to frame: \(targetFrame)")
        print("Current fromView frame: \(fromView.frame)")
        print("Current fromView transform: \(fromView.transform)")
        
        // FIX: Reset transform BEFORE animation, not during
//        fromView.transform = .identity
        print("After transform reset - fromView frame: \(fromView.frame)")
        
        // Now animate to the target frame (without touching transform)
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.curveEaseOut]
        ) {
            fromView.frame = targetFrame
            // DON'T set transform here - it's already identity
            print("Mid-animation - fromView frame: \(fromView.frame)")
        } completion: { finished in
            print("✅ Animation completed. Final frame: \(fromView.frame)")
            self.triggerNavigation()
        }
    }

    
    private func calculateFinalFrame(originView: UIView, fromView: UIView) -> CGRect {
        print("\n=== CALCULATING FINAL FRAME ===")
        print("isNavigationTransition: \(isNavigationTransition)")
        print("originView: \(originView)")
        print("fromView: \(fromView)")
        
        guard let containerView = fromView.superview else {
            print("❌ No container view found")
            return originView.frame
        }
        print("containerView: \(containerView)")
        
        // Get the origin view's frame in its own coordinate system
        let originBounds = originView.bounds
        print("originView bounds: \(originBounds)")
        
        // Method 1: Try direct conversion (most reliable when it works)
        let directConversion = originView.convert(originBounds, to: containerView)
        print("Direct conversion result: \(directConversion)")
        
        // Validation: Check if the result makes sense (is within reasonable bounds)
        let screenBounds = UIScreen.main.bounds
        
        let isReasonable = directConversion.origin.x >= -screenBounds.width &&
                          directConversion.origin.x <= screenBounds.width * 2 &&
                          directConversion.origin.y >= -screenBounds.height &&
                          directConversion.origin.y <= screenBounds.height * 2 &&
                          directConversion.size.width > 0 &&
                          directConversion.size.height > 0
        
        print("Direct conversion is reasonable: \(isReasonable)")
        
        if isReasonable {
            print("✅ Using direct conversion: \(directConversion)")
            return directConversion
        }
        
        // Method 2: Window-based conversion (fallback)
        print("🔄 Trying window-based conversion...")
        
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            print("❌ Could not find key window, using origin frame")
            return originView.frame
        }
        
        // Convert origin view to window coordinates
        let originInWindow = originView.convert(originBounds, to: window)
        print("Origin in window: \(originInWindow)")
        
        // Convert from window to container
        let windowToContainer = window.convert(originInWindow, to: containerView)
        print("Window to container: \(windowToContainer)")
        
        // Validate window conversion
        let windowConversionIsReasonable = windowToContainer.origin.x >= -screenBounds.width &&
                                           windowToContainer.origin.x <= screenBounds.width * 2 &&
                                           windowToContainer.origin.y >= -screenBounds.height &&
                                           windowToContainer.origin.y <= screenBounds.height * 2 &&
                                           windowToContainer.size.width > 0 &&
                                           windowToContainer.size.height > 0
        
        print("Window conversion is reasonable: \(windowConversionIsReasonable)")
        
        if windowConversionIsReasonable {
            print("✅ Using window conversion: \(windowToContainer)")
            return windowToContainer
        }
        
        // Method 3: Manual calculation (last resort)
        print("🔄 Trying manual calculation...")
        
        // Get origin view's position in window
        let originViewWindowFrame = originView.convert(originBounds, to: nil) // Convert to window
        print("Origin view window frame: \(originViewWindowFrame)")
        
        // Get container view's position in window
        let containerWindowFrame = containerView.convert(containerView.bounds, to: nil)
        print("Container window frame: \(containerWindowFrame)")
        
        // Calculate relative position
        let relativeFrame = CGRect(
            x: originViewWindowFrame.origin.x - containerWindowFrame.origin.x,
            y: originViewWindowFrame.origin.y - containerWindowFrame.origin.y,
            width: originViewWindowFrame.size.width,
            height: originViewWindowFrame.size.height
        )
        
        print("✅ Using manual calculation: \(relativeFrame)")
        return relativeFrame
    }
    
    private func findCommonSuperview(view1: UIView, view2: UIView) -> UIView? {
        var superview1: UIView? = view1.superview
        
        while superview1 != nil {
            var superview2: UIView? = view2.superview
            
            while superview2 != nil {
                if superview1 === superview2 {
                    return superview1
                }
                superview2 = superview2?.superview
            }
            superview1 = superview1?.superview
        }
        
        return nil
    }
    
    private func cancelTransition() {
        guard let fromView = viewController?.view else { return }
        
        // Reset label transform
        if let label = fromView.viewWithTag(100) as? UILabel {
            label.transform = .identity
        }
        
        if let navController = self.viewController?.navigationController {
            navController.setNavigationBarHidden(false, animated: false)
        }
        
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.curveEaseOut]
        ) {
            fromView.transform = self.initialTransform
        } completion: { _ in
            if self.isNavigationTransition {
                self.destinationView?.removeFromSuperview()
            }
        }
    }
    
    private func triggerNavigation() {
        print("Triggering navigation - isNavigationTransition: \(isNavigationTransition)")
        // NOW trigger the navigation after our manual animation
        if viewController?.presentingViewController != nil {
            viewController?.dismiss(animated: false) // No animation since we already did it
        } else if let navController = viewController?.navigationController {
            navController.setNavigationBarHidden(false, animated: false)
            navController.popViewController(animated: false)
        }
    }
    
    // MARK: - Public Properties
    
    var isInteractive: Bool {
        return isCurrentlyInteractive
    }
}
