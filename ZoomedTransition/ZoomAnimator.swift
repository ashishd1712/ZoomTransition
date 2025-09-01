//
//  ZoomAnimator.swift
//  ZoomedTransition
//
//  Created by Ashish Dutt on 01/09/25.
//

import UIKit

final class ZoomAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let duration: TimeInterval = 3
    var originView: UIView
    var isPresenting: Bool
    
    init(originView: UIView, isPresenting: Bool) {
        self.originView = originView
        self.isPresenting = isPresenting
    }
    
    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        return 3
    }
    
    func animateTransition(using context: UIViewControllerContextTransitioning) {
        let container = context.containerView
        
        guard
            let fromVC = context.viewController(forKey: .from),
            let toVC = context.viewController(forKey: .to)
        else { return }
        
        let fromView = fromVC.view!
        let toView = toVC.view!
        
        if isPresenting {
            container.addSubview(toView)
            toView.layoutIfNeeded()
            
            let originFrame = originView.superview!.convert(originView.frame, to: container)
            let finalFrame = context.finalFrame(for: toVC)
            
            // Start as originView’s frame
            toView.frame = originFrame
            
            // Animate into place
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
                toView.frame = finalFrame
            }, completion: { finished in
                context.completeTransition(finished)
            })
            
        } else {
            let originFrame = originView.superview!.convert(originView.frame, to: container)
            
            // Animate back into place
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
                fromView.frame = originFrame
            }, completion: { finished in
                fromView.removeFromSuperview()
                context.completeTransition(finished)
            })
        }
    }
}

final class ZoomTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    var originView: UIView
    
    init(originView: UIView) {
        self.originView = originView
    }
    
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ZoomAnimator(originView: originView, isPresenting: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ZoomAnimator(originView: originView, isPresenting: false)
    }
    
}
