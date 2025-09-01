//
//  UIViewControllerContextTransitioning+Extension.swift
//  ZoomedTransition
//
//  Created by Ashish Dutt on 31/08/25.
//

import UIKit

extension UIViewControllerContextTransitioning {
    func sharedFrame(forKey key: UITransitionContextViewControllerKey) -> CGRect? {
        let viewController = viewController(forKey: key)
        viewController?.view.layoutIfNeeded()
        return (viewController as? SharedTransitioning)?.sharedFrame
    }
}
