//
//  CGAffineTransform+Extension.swift
//  ZoomedTransition
//
//  Created by Ashish Dutt on 29/08/25.
//

import Foundation

extension CGAffineTransform {
    static func transformTemp(parent: CGRect, soChild child: CGRect, matches rect: CGRect) -> Self {
        
        // 1. Compare Child rect with target rect
        
        let scaleX = rect.width / child.width
        let scaleY = rect.height / child.height
        
        // 2. Determine transalation to align centers of both these rects
        
        //2.1 First we match the center of parent to target
        let offsetX = rect.midX - parent.midX
        let offsetY = rect.midY - parent.midY
        
        //2.2 adjust this offset so that child's center is aligned with the target (difference between center of parent and child in their scaled form)
        let centerOffsetX = (parent.midX - child.midY) * scaleX
        let centerOffsety = (parent.midY - child.midX) * scaleY
        
        // 3. Final translation
        let translationX = offsetX + centerOffsetX
        let translationY = offsetY + centerOffsety
        
        //Scale and Translate
        let scale = CGAffineTransform(scaleX: scaleX, y: scaleY)
        let tranlate = CGAffineTransform(translationX: translationX, y: translationY)
        
        return scale.concatenating(tranlate)
        
    }
    
    //Corrected func that respects the aspect ratio
    static func transform2(parent: CGRect, soChild child: CGRect, matches rect: CGRect) -> Self {
        let childRatio = child.width / child.height
        let rectRatio = rect.width / rect.height
        
        let scaleX = rect.width / child.width
        let scaleY = rect.height / child.height
        
        let scaleFactor = rectRatio < childRatio ? scaleX : scaleY
        
        let offsetX = rect.midX - parent.midX
        let offsetY = rect.midY - parent.midY
        
        let centerOffsetX = (parent.midX - child.midX) * scaleFactor
        let centerOffsetY = (parent.midY - child.midY) * scaleFactor
        
        let translateX = offsetX + centerOffsetX
        let translateY = offsetY + centerOffsetY
        
        let scaleTransform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        let translateTransform = CGAffineTransform(translationX: translateX, y: translateY)
        
        return scaleTransform.concatenating(translateTransform) 
    }
    
    static func transform(parent: CGRect, soChild child: CGRect, aspectFills rect: CGRect) -> Self {
        let childRatio = child.width / child.height
            let rectRatio = rect.width / rect.height
            
            // Calculate scale factor to fit the child into rect while maintaining aspect ratio
            // Use the smaller scale factor to ensure the child fits completely within rect
            let scaleX = rect.width / child.width
            let scaleY = rect.height / child.height
            let scaleFactor = min(scaleX, scaleY)
            
            // Calculate the offset from parent center to rect center
            let offsetX = rect.midX - parent.midX
            let offsetY = rect.midY - parent.midY
            
            // Calculate how much to adjust for the child's position relative to parent center
            let centerOffsetX = (parent.midX - child.midX) * scaleFactor
            let centerOffsetY = (parent.midY - child.midY) * scaleFactor
            
            // Final translation combines both offsets
            let translateX = offsetX + centerOffsetX
            let translateY = offsetY + centerOffsetY
            
            // Create and combine transforms
            let scaleTransform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
            let translateTransform = CGAffineTransform(translationX: translateX, y: translateY)
            
            return scaleTransform.concatenating(translateTransform)
    }
    
//    static func aspectFitTransform(parent: CGRect, soChild child: CGRect, fits rect: CGRect) -> CGAffineTransform {
//        let childRatio = child.width / child.height
//        let rectRatio = rect.width / rect.height
//        
//        // Determine the aspect-fit scale factor (whichever is smaller)
//        let scaleX = rect.width / child.width
//        let scaleY = rect.height / child.height
//        let scaleFactor = rectRatio < childRatio ? scaleY : scaleX
//        
//        // After scaling, calculate the new child size
//        let scaledChildWidth = child.width * scaleFactor
//        let scaledChildHeight = child.height * scaleFactor
//        
//        // Center the scaled child in the rect (cell)
//        let targetMidX = rect.midX
//        let targetMidY = rect.midY
//        let sourceMidX = child.midX
//        let sourceMidY = child.midY
//        
//        // Find parent center in window coordinates
//        let parentMidX = parent.midX
//        let parentMidY = parent.midY
//        
//        // Offset required to put scaled child's center at the cell's center
//        let centerOffsetX = targetMidX - (parentMidX + (sourceMidX - parentMidX) * scaleFactor)
//        let centerOffsetY = targetMidY - (parentMidY + (sourceMidY - parentMidY) * scaleFactor)
//        
//        let scaleTransform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
//        let translateTransform = CGAffineTransform(translationX: centerOffsetX, y: centerOffsetY)
//        
//        return scaleTransform.concatenating(translateTransform)
//    }
    static func transformExactMatch(parent: CGRect, soChild child: CGRect, toMatch target: CGRect) -> Self {
            guard child.width > 0, child.height > 0 else {
                return .identity
            }

            // Scale factors to map child → target
            let scaleX = target.width / child.width
            let scaleY = target.height / child.height

            // Translate child’s origin to (0,0), scale, then translate into target’s origin
            let translateToOrigin = CGAffineTransform(translationX: -child.minX, y: -child.minY)
            let scale = CGAffineTransform(scaleX: scaleX, y: scaleY)
            let translateToTarget = CGAffineTransform(translationX: target.minX, y: target.minY)

            return translateToOrigin.concatenating(scale).concatenating(translateToTarget)
        }
    
    static func transformAspectFitToMatch(parent: CGRect, soChild child: CGRect, toMatch rect: CGRect) -> Self {
        // Calculate scale factors
        let scaleX = rect.width / child.width
        let scaleY = rect.height / child.height
        
        // Use the smaller scale factor to maintain aspect ratio (no squeezing)
        let scaleFactor = min(scaleX, scaleY)
        
        // Calculate the offset from parent center to target rect center
        let offsetX = rect.midX - parent.midX
        let offsetY = rect.midY - parent.midY
        
        // Calculate how much to adjust for the child's position relative to parent center
        let centerOffsetX = (parent.midX - child.midX) * scaleFactor
        let centerOffsetY = (parent.midY - child.midY) * scaleFactor
        
        // Final translation combines both offsets
        let translateX = offsetX + centerOffsetX
        let translateY = offsetY + centerOffsetY
        
        // Create transforms with uniform scaling (no distortion)
        let scaleTransform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        let translateTransform = CGAffineTransform(translationX: translateX, y: translateY)
        
        return scaleTransform.concatenating(translateTransform)
    }
}
