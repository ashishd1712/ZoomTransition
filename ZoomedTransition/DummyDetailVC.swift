//
//  DummyDetailVC.swift
//  ZoomedTransition
//
//  Created by Ashish Dutt on 31/08/25.
//

import UIKit

class DummyDetailVC: UIViewController {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    private lazy var panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    private var interactionController: SharedZoomInteractionController?
    
    var originView: UIView?
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGestureRecognizers()
        //        transitioningDelegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        self.transitioningDelegate = self
//        self.navigationController?.delegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
//        if isMovingToParent {
//            self.navigationController?.delegate = nil
//        }
    }
    
    private func setupGestureRecognizers() {
        // Configure pan gesture for edge-based interaction
        view.addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.delegate = self
    }
    
    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
            switch recognizer.state {
            case .began:
                let originCell = getOriginCell()
                interactionController = SharedZoomInteractionController(
                    originView: originCell,
                    viewController: self
                )
            default:
                break
            }
            
            interactionController?.handlePanGesture(recognizer)
            
            if recognizer.state == .ended || recognizer.state == .cancelled {
                interactionController = nil
            }
        }
        
        private func getOriginCell() -> UIView? {
            // Your existing implementation
            if self.presentingViewController != nil {
                return originView
            } else if let navController = navigationController,
               navController.viewControllers.count > 1 {
                let previousVC = navController.viewControllers[navController.viewControllers.count - 2]
                if let listVC = previousVC as? ViewController {
                    return listVC.getSelectedCell()
                }
            }
            return nil
        }
}

//extension DummyDetailVC: UINavigationControllerDelegate {
//    
//    func navigationController(
//        _ navigationController: UINavigationController,
//        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
//    ) -> UIViewControllerInteractiveTransitioning? {
//        // Return interaction controller only when we have an active interactive transition
//        return interactionController?.isInteractive == true ? interactionController : nil
//    }
//    
//    func navigationController(
//        _ navigationController: UINavigationController,
//        animationControllerFor operation: UINavigationController.Operation,
//        from fromVC: UIViewController,
//        to toVC: UIViewController
//    ) -> UIViewControllerAnimatedTransitioning? {
//        guard operation == .pop, toVC is ViewController, fromVC == self, let originView = originView else { return nil }
//        return SharedZoomTransitionAnimator(type: .pop, originView: originView)
//    }
//}
//
//extension DummyDetailVC: UIViewControllerTransitioningDelegate {
//    
//    func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
//        guard let originView = originView else { return nil}
//        return SharedZoomTransitionAnimator(type: .dismiss, originView: originView)
//    }
//    
////    func interactionControllerForDismissal(using animator: any UIViewControllerAnimatedTransitioning) -> (any UIViewControllerInteractiveTransitioning)? {
////        return interactionController
////    }
//    
//}

extension DummyDetailVC: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // Allow simultaneous recognition with scroll views if needed
        return otherGestureRecognizer.view is UIScrollView
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Only start gesture from the left edge of the screen (like iOS back gesture)
        let touchLocation = touch.location(in: view)
        return touchLocation.x < 50 // 50 points from left edge
    }
}

extension DummyDetailVC: SharedZoomTransitioning {
    var sharedFrame: CGRect {
        guard let inner = view.viewWithTag(100)?.superview else { return .zero }
        return inner.frameInWindow ?? .zero
    }
    
    func sharedViewForTransition() -> UIView? {
        return view.viewWithTag(100)?.superview
    }
}
