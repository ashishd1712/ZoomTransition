//
//  SharedTransitionAnimator.swift
//  ZoomedTransition
//
//  Created by Ashish Dutt on 27/08/25.
//

import UIKit

protocol SharedTransitioning {
    var sharedFrame: CGRect { get }
}

class SharedTransitionAnimator: NSObject {
    enum Transition {
        case push
        case pop
        case present
        case dismiss
    }
    
    var transition: Transition = .push
    
}

extension SharedTransitionAnimator: UIViewControllerAnimatedTransitioning {
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        switch transition {
        case .push, .present:
            pushAnimation(context: transitionContext)
        case .pop, .dismiss:
            popAnimation(context: transitionContext)
        }
    }
    
    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        return 3
    }
}

extension SharedTransitionAnimator {
    private func setup(with context: UIViewControllerContextTransitioning) -> (UIView, CGRect, UIView, CGRect)? {
        guard let toView = context.view(forKey: .to),
              let fromView = context.view(forKey: .from) else {
            return nil
        }
        if transition == .push {
            context.containerView.addSubview(toView)
        } else {
            context.containerView.insertSubview(toView, belowSubview: fromView)
        }
        guard let toFrame = context.sharedFrame(forKey: .to),
              let fromFrame = context.sharedFrame(forKey: .from) else {
            return nil
        }
        return (fromView, fromFrame, toView, toFrame)
    }
    
    private func pushAnimation(context: UIViewControllerContextTransitioning) {
        guard let (fromView, fromFrame, toView, toFrame) = setup(with: context) else {
            context.completeTransition(false)
            return
        }
        
        // Use exact match transform only for positioning the entire view
        let positionTransform: CGAffineTransform = .transformExactMatch(
            parent: toView.frame,
            soChild: toFrame,
            toMatch: fromFrame
        )
        
        // Create mask that will animate from cell size to full screen
        let maskFrame = fromFrame
        let mask = UIView(frame: maskFrame).then {
            $0.layer.cornerCurve = .continuous
            $0.backgroundColor = .black
            $0.layer.cornerRadius = 12 // Match your cell corner radius
        }
        
        // Overlay for dimming effect
        let overlay = UIView().then {
            $0.backgroundColor = .black
            $0.layer.opacity = 0
            $0.frame = fromView.frame
        }
        
        // Placeholder in the cell
        let placeholder = UIView().then {
            $0.backgroundColor = .white
            $0.layer.cornerRadius = 10
            $0.frame = fromFrame
        }
        
        // Set initial state
        toView.mask = mask
        toView.transform = positionTransform
        fromView.addSubview(placeholder)
        fromView.addSubview(overlay)
        
        // No need for separate content image handling if not required
        
        UIView.animate(withDuration: 3) {
            // Animate view back to identity (natural size and position)
            toView.transform = .identity
            
            // Animate mask to full screen
            mask.frame = toView.frame
            mask.layer.cornerRadius = 0 // Remove corner radius for full screen
            
            // Dim the background
            overlay.layer.opacity = 0.5
            
            // No content image transform needed
            
        } completion: { _ in
            toView.mask = nil
            overlay.removeFromSuperview()
            placeholder.removeFromSuperview()
            context.completeTransition(true)
        }
    }
    
    private func popAnimation(context: UIViewControllerContextTransitioning) {
        guard let (fromView, fromFrame, toView, toFrame) = setup(with: context) else {
            context.completeTransition(false)
            return
        }
        
        // Transform to shrink detail view to cell position
        let transform: CGAffineTransform = .transformExactMatch(
            parent: fromView.frame,
            soChild: fromFrame,
            toMatch: toFrame
        )
        
        // Create mask starting at full screen
        let mask = UIView(frame: fromView.frame).then {
            $0.layer.cornerCurve = .continuous
            $0.backgroundColor = .black
            $0.layer.cornerRadius = 0
        }
        
        let overlay = UIView().then {
            $0.backgroundColor = .black
            $0.layer.opacity = 0.5
            $0.frame = toView.frame
        }
        
        let placeholder = UIView().then {
            $0.backgroundColor = .white
            $0.layer.cornerRadius = toView.layer.cornerRadius
            $0.frame = toFrame
        }
        
        // Set initial state
        fromView.mask = mask
        toView.addSubview(placeholder)
        toView.addSubview(overlay)
        
        // Calculate final mask frame (where the cell will be)
        let finalMaskFrame = toFrame
        
        // No separate content handling needed
        
        UIView.animate(withDuration: 3) {
            // Shrink the detail view to cell position
            fromView.transform = transform
            
            // Shrink mask to cell size
            mask.frame = finalMaskFrame
            mask.layer.cornerRadius = 12 // Match cell corner radius
            
            // Fade out overlay
            overlay.layer.opacity = 0
            
            // No content image scaling needed
            
        } completion: { _ in
            overlay.removeFromSuperview()
            placeholder.removeFromSuperview()
            let isCancelled = context.transitionWasCancelled
            context.completeTransition(!isCancelled)
        }
    }
    
}
