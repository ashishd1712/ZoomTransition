//
//  UIView+Extension.swift
//  ZoomedTransition
//
//  Created by Ashish Dutt on 31/08/25.
//

import UIKit

extension UIView {
    var frameInWindow: CGRect? {
        superview?.convert(frame, to: nil)
    }
}
