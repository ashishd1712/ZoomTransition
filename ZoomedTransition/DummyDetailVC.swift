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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
}

extension DummyDetailVC: SharedZoomTransitioning {
    var sharedFrame: CGRect {
        // We used a view with `tag = 100` and its superview before.
        // Make sure this returns the *frame in window coordinates*.
        guard let inner = view.viewWithTag(100)?.superview else { return .zero }
        return inner.frameInWindow ?? .zero
    }
    
    func sharedViewForTransition() -> UIView? {
        // return the exact view to snapshot (same view you used in sharedFrame computation)
        return view.viewWithTag(100)?.superview
    }
}
