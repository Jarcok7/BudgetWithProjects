//
//  ProjectsSC.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 8/2/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit

class ProjectsSC: UISegmentedControl {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    var currentSelectedSegmentIndex: Int = UISegmentedControlNoSegment
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        currentSelectedSegmentIndex = self.selectedSegmentIndex
        super.touchesEnded(touches, with: event)
        if currentSelectedSegmentIndex == self.selectedSegmentIndex {
            if let touch = touches.first {
                let touchLocation = touch.location(in: self)
                if bounds.contains(touchLocation) {
                    self.sendActions(for: .valueChanged)
                }
            }
        }
        
        if self.selectedSegmentIndex == self.numberOfSegments - 1 {
            self.selectedSegmentIndex = currentSelectedSegmentIndex
        } else {
            currentSelectedSegmentIndex = self.selectedSegmentIndex
        }
        
    }

}
