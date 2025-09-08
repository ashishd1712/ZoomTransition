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
        guard let inner = view.viewWithTag(100)?.superview else { return .zero }
        return inner.frameInWindow ?? .zero
    }
    
    func sharedViewForTransition() -> UIView? {
        return view.viewWithTag(100)?.superview
    }
}
