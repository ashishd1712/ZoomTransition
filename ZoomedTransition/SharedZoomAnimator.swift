//
//  SharedZoomAnimator.swift
//  ZoomedTransition
//
//  Created by Ashish Dutt on 01/09/25.
//

import UIKit
/// Protocol you implement on any view controller that participates in a shared-element transition.
/// - `sharedFrame` should return the frame of the shared item **in window coordinates** (your existing `frameInWindow`).
/// - `sharedViewForTransition()` is optional and should return the actual view to snapshot if available (higher fidelity).
protocol SharedZoomTransitioning {
    /// Frame of the shared element **in window coordinates**. Return `.zero` when not available.
    var sharedFrame: CGRect { get }

    /// Optional: return the UIView that should be snapshotted for the shared animation.
    /// Default implementation returns nil.
    func sharedViewForTransition() -> UIView?
}

extension SharedZoomTransitioning {
    func sharedViewForTransition() -> UIView? { nil }
}

/// Generic animator that uses a snapshot of the shared element and animates it between frames.
/// Works for `.present/.dismiss` and `.push/.pop`.
final class SharedZoomTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    enum TransitionType {
        case present
        case dismiss
        case push
        case pop
    }
    
    private let type: TransitionType
    private weak var originView: UIView?
    private let duration: TimeInterval = 0.2
    
    init(type: TransitionType, originView: UIView?) {
        self.type = type
        self.originView = originView
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let originView = originView,
              let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to),
              let fromView = fromVC.view,
              let toView = toVC.view
        else {
            transitionContext.completeTransition(false)
            return
        }
        
        let containerView = transitionContext.containerView
        let originFrame = originView.convert(originView.bounds, to: containerView)
        
        switch type {
            
            // ---------------------------
            // PRESENT
            // ---------------------------
        case .present:
            containerView.addSubview(toView)
            
            toView.frame = originFrame
            toView.clipsToBounds = true
            
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: [.curveEaseOut]
            ) {
                toView.frame = transitionContext.finalFrame(for: toVC)
            } completion: { finished in
                transitionContext.completeTransition(finished)
            }
            
            // ---------------------------
            // DISMISS
            // ---------------------------
        case .dismiss:
            if toView.superview == nil {
                containerView.insertSubview(toView, belowSubview: fromView)
            } else {
                containerView.bringSubviewToFront(fromView) // keep animation visible
            }
            toView.frame = transitionContext.finalFrame(for: toVC)
            
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: [.curveEaseInOut]
            ) {
                fromView.frame = originFrame
            } completion: { finished in
                // UIKit will remove fromView automatically.
                // We just confirm transition success.
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
            
            // ---------------------------
            // PUSH
            // ---------------------------
        case .push:
            containerView.addSubview(toView)
            toView.frame = originFrame
            toView.clipsToBounds = true
            
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: [.curveEaseInOut]
            ) {
                toView.frame = transitionContext.finalFrame(for: toVC)
                
            } completion: { finished in
                transitionContext.completeTransition(finished)
            }
            
            // ---------------------------
            // POP
            // ---------------------------
        case .pop:
            containerView.insertSubview(toView, belowSubview: fromView)
            toView.frame = transitionContext.finalFrame(for: toVC)
            
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: [.curveEaseInOut]
            ) {
                fromView.frame = originFrame
            } completion: { finished in
                fromView.removeFromSuperview()
                transitionContext.completeTransition(finished)
            }
        }
    }
}
