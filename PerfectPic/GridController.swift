//
//  GridController.swift
//  PerfectPic
//
//  Created by Jonathan Ligh on 4/23/18.
//  Copyright © 2018 JonathanLigh. All rights reserved.
//

import UIKit

class GridController: UIView {
    
    let gridWidth: CGFloat = 0.5
    var columns: Int
    
    init(frame: CGRect, columns: Int) {
        self.columns = columns - 1
        super.init(frame: frame)
        
        self.isOpaque = false
        self.backgroundColor = UIColor(white: 0.0, alpha: 0.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.setLineWidth(gridWidth)
        context.setStrokeColor(UIColor.black.cgColor)
        
        // Calculate basic dimensions
        let columnWidth: CGFloat = self.frame.size.width / (CGFloat(self.columns) + 1.0)
        let rowHeight: CGFloat = columnWidth;
        let numberOfRows: Int = Int(self.frame.size.height)/Int(rowHeight);
        
        for i in 1...self.columns {
            let startPoint: CGPoint = CGPoint(x: columnWidth * CGFloat(i), y: 0.0)
            var _: CGPoint = CGPoint(x: startPoint.x, y: self.frame.size.height)
            context.move(to: startPoint)
            context.addLine(to: startPoint)
            context.strokePath();
        }
        
        for j in 1...numberOfRows {
            let startPoint: CGPoint = CGPoint(x: 0.0, y: rowHeight * CGFloat(j))
            var _: CGPoint = CGPoint(x: self.frame.size.width, y: startPoint.y)
            
            context.move(to: startPoint)
            context.addLine(to: startPoint)
            context.strokePath();
        }
    }
}
