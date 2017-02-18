//
//  MainTableViewCell.swift
//  BudgetWithProjects
//
//  Created by Jarco Katsalay on 10/13/16.
//  Copyright © 2016 Jarco Katsalay. All rights reserved.
//

import UIKit

protocol MainTableViewCellDelegate {
    func transactionInitiated(cell: MainTableViewCell, plus: Bool)
}

class MainTableViewCell: UITableViewCell {

    var originalCenter = CGPoint()
    var minusOnDragRelease = false
    var plusOnDragRelease = false
    var plusLable: UILabel!
    var minusLable: UILabel!
    
    let kUICuesMargin: CGFloat = 0.0, kUICuesWidth: CGFloat = 500.0
    
    var delegate: MainTableViewCellDelegate?
    var row: Int?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // add a pan recognizer
        
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        recognizer.delegate = self
        addGestureRecognizer(recognizer)
        
        func createCueLabel() -> UILabel {
            let label = UILabel(frame: CGRect())
            label.textColor = UIColor.white
            label.font = UIFont.systemFont(ofSize: 18.0)
            return label
        }
        
        // tick and cross labels for context cues
        plusLable = createCueLabel()
        plusLable.text = "  Income"//"➕"
        plusLable.textAlignment = .left
        plusLable.backgroundColor = SumViewController.plusColor()
        minusLable = createCueLabel()
        
        let minusText = NSMutableAttributedString(string: "Expense")
        minusText.append(NSAttributedString(string: "..", attributes: [NSForegroundColorAttributeName: SumViewController.minusColor()]))
        minusLable.attributedText = minusText //"➖"
        minusLable.textAlignment = .right
        minusLable.backgroundColor = SumViewController.minusColor()
        
        addSubview(plusLable)
        addSubview(minusLable)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        minusLable.frame = CGRect(x: -kUICuesWidth - kUICuesMargin, y: 0,
                                 width: kUICuesWidth, height: bounds.size.height)
        plusLable.frame = CGRect(x: bounds.size.width + kUICuesMargin, y: 0,
                                  width: kUICuesWidth, height: bounds.size.height)
    }

    //MARK: - horizontal pan gesture methods
    func handlePan(recognizer: UIPanGestureRecognizer) {
        // 1
        if recognizer.state == .began {
            // when the gesture begins, record the current center location
            originalCenter = center
        }
        // 2
        if recognizer.state == .changed {
            let translation = recognizer.translation(in: self)
            center = CGPoint(x: originalCenter.x + translation.x, y: originalCenter.y)
            // has the user dragged the item far enough to initiate a delete/complete?
            plusOnDragRelease = frame.origin.x < -frame.size.width / 3.0
            minusOnDragRelease = frame.origin.x > frame.size.width / 3.0
            
        }
        // 3
        if recognizer.state == .ended {
            // the frame this cell had before user dragged it
            let originalFrame = CGRect(x: 0, y: frame.origin.y,
                                       width: bounds.size.width, height: bounds.size.height)
            
            UIView.animate(withDuration: 0.2, animations: {self.frame = originalFrame})
            
            if plusOnDragRelease {
                delegate?.transactionInitiated(cell: self, plus: true)
            } else if minusOnDragRelease {
                delegate?.transactionInitiated(cell: self, plus: false)
            }
        }
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = panGestureRecognizer.translation(in: superview!)
            if fabs(translation.x) > fabs(translation.y) {
                return true
            }
            return false
        }
        return false
    }
}
