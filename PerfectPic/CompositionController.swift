//
//  CompositionController.swift
//  PerfectPic
//
//  Created by Jonathan Ligh on 4/25/18.
//  Copyright © 2018 JonathanLigh. All rights reserved.
//

import UIKit
//  This class is responsible for controlling the functioning of all the photographic composition guideline types
//  Class variables
class CompositionController: NSObject {
    let compositions: [Composition] = [.Default, .CentralSquare, .Quandrants, .GoldenSpiral, .GoldenTriangles, .BalancedSquares]
    var currentComposition: Composition = .GoldenSpiral
    var compositionLineWidth: CGFloat = 2
    private var reversed = false
    let layer = CAShapeLayer()
    
}

// Class functions
extension CompositionController {
    func currentBezierPath(view: UIView) -> UIBezierPath {
        switch self.currentComposition {
        case .Default: return drawDefault(view: view)
        case .Quandrants: return drawQuadrants(view: view)
        case .CentralSquare: return drawCentralSquare(view: view)
        case .GoldenSpiral: return drawGoldenSpiral(view: view)
        case .GoldenTriangles: return drawGoldenTriangles(view: view)
        case .BalancedSquares: return drawBalancedSquares(view: view)
        }
    }
    
    func drawCurrentBezierPath(view: UIView) {
        self.layer.path = currentBezierPath(view: view).cgPath
        self.layer.strokeColor = UIColor.gray.cgColor
        self.layer.lineWidth = self.compositionLineWidth
        view.layer.addSublayer(layer)
    }
    
    func setCurrentComposition(comp: Composition) {
        self.currentComposition = comp
    }
    
    func removeComposition(view: UIView) {
        self.layer.path = nil
    }
    
    func reverseComposition(view: UIView) {
        if self.reversed {
            removeComposition(view: view)
            drawCurrentBezierPath(view: view)
            self.reversed = false
        } else {
            removeComposition(view: view)
            self.layer.path = currentBezierPath(view: view).reversing().cgPath
            self.layer.strokeColor = UIColor.gray.cgColor
            self.layer.lineWidth = self.compositionLineWidth
            view.layer.addSublayer(layer)
            self.reversed = true
        }
    }
    
    private func drawDefault(view: UIView) -> UIBezierPath {
        let path = UIBezierPath()
        
        path.move(to: CGPoint(x: view.frame.width / 3, y: 0.0))
        path.addLine(to: CGPoint(x: view.frame.width / 3, y: view.frame.height))
        
        path.move(to: CGPoint(x: view.frame.width * 2 / 3, y: 0.0))
        path.addLine(to: CGPoint(x: view.frame.width * 2 / 3, y: view.frame.height))
        
        path.move(to: CGPoint(x: 0.0, y: view.frame.height / 3))
        path.addLine(to: CGPoint(x: view.frame.width, y: view.frame.height / 3))
        
        path.move(to: CGPoint(x: 0.0, y: view.frame.height * 2 / 3))
        path.addLine(to: CGPoint(x: view.frame.width, y: view.frame.height * 2 / 3))
        
        path.lineWidth = self.compositionLineWidth
        return path
    }
    
    private func drawQuadrants(view: UIView) -> UIBezierPath {
        let path = UIBezierPath()
        
        path.move(to: CGPoint(x: view.frame.width / 2, y: 0.0))
        path.addLine(to: CGPoint(x: view.frame.width / 2, y: view.frame.height))
        
        path.move(to: CGPoint(x: 0.0, y: view.frame.height / 2))
        path.addLine(to: CGPoint(x: view.frame.width, y: view.frame.height / 2))
        
        path.lineWidth = self.compositionLineWidth
        return path
    }
    
    private func drawCentralSquare(view: UIView) -> UIBezierPath {
        let path = UIBezierPath()
        
        path.move(to: CGPoint(x: view.frame.width / 3, y: view.frame.width / 3))
        path.addLine(to: CGPoint(x: view.frame.width * 2 / 3, y: view.frame.width / 3))
        path.addLine(to: CGPoint(x: view.frame.width * 2 / 3, y: view.frame.width * 2 / 3))
        path.addLine(to: CGPoint(x: view.frame.width / 3, y: view.frame.width * 2 / 3))
        path.close()
        
        return path
    }
    
    private func drawGoldenSpiral (view: UIView) -> UIBezierPath {
        let path = UIBezierPath()
        
        let phi = (1 + sqrt(5)) / 2 as CGFloat
        var height = view.frame.width
        var center = CGPoint(x: view.frame.width / phi, y: view.frame.height)

        path.addArc(withCenter: center, radius: view.frame.height, startAngle: CGFloat(180), endAngle: CGFloat(270), clockwise: true)
//
//
        center = CGPoint(x: view.frame.width / phi, y: view.frame.height / phi)
//
        path.addArc(withCenter: center, radius: view.frame.height, startAngle: CGFloat(270), endAngle: CGFloat(0), clockwise: true)
        
        path.move(to: CGPoint(x: 0.0, y: height))
        path.addLine(to: CGPoint(x: height, y: height))
        
        path.move(to: CGPoint(x: view.frame.height - height, y: height))
        path.addLine(to: CGPoint(x: view.frame.height - height, y: view.frame.height))
        
        path.move(to: CGPoint(x: view.frame.height - height, y: height))
        path.addLine(to: CGPoint(x: view.frame.height - height, y: view.frame.height))
        
        return path
    }
    
    //  in order to simplify the drawing of spirals,
    private func drawGoldenTilesRecursive(path: UIBezierPath, view: UIView, tile: CGRect, maxDepth: Int, currentDepth: Int) -> UIBezierPath {
        if currentDepth <= maxDepth {
            let phi = (1 + sqrt(5)) / 2 as CGFloat
            var center = CGPoint(x: tile.width / phi, y: tile.height)

            path.addArc(withCenter: center, radius: tile.height, startAngle: CGFloat(180 + 180 * currentDepth + 180 * currentDepth), endAngle: CGFloat(270), clockwise: true)


            center = CGPoint(x: tile.width / phi, y: tile.height / phi)

            path.addArc(withCenter: center, radius: tile.height, startAngle: CGFloat(270 + 180 * currentDepth), endAngle: CGFloat(0 + 180 * currentDepth), clockwise: true)
            
            path.move(to: CGPoint(x: tile.width / phi, y: 0.0))
            path.addLine(to: CGPoint(x: tile.width / phi, y: tile.height))
            
            path.move(to: CGPoint(x: tile.width / phi, y: tile.height / phi))
            path.addLine(to: CGPoint(x: tile.width, y: tile.height / phi))
            
            return drawGoldenTilesRecursive(path: path, view: view, tile: CGRect(x: tile.height / phi, y: tile.width / phi, width: tile.width - (tile.width / phi), height: tile.height - (tile.height / phi)), maxDepth: maxDepth, currentDepth: currentDepth + 1)
        } else {
            return path
        }
    }
    
    private func drawGoldenTriangles (view: UIView) -> UIBezierPath {
        let path = UIBezierPath()
        
        //  some trig to make the drawing of intersecting parallel lines easier
        let y = ((view.frame.width * view.frame.height) / sqrt(pow(view.frame.width, 2) + pow(view.frame.height, 2))) * (view.frame.width / view.frame.height)
        let x = y * view.frame.height / view.frame.width
        
        path.move(to: CGPoint(x: 0.0, y: 0.0))
        path.addLine(to: CGPoint(x: x, y: y))

        path.move(to: CGPoint(x: view.frame.width, y: view.frame.height))
        path.addLine(to: CGPoint(x: view.frame.width  - x, y: view.frame.height  - y))
        
        path.move(to: CGPoint(x: 0.0, y: view.frame.height))
        path.addLine(to: CGPoint(x: view.frame.width, y: 0))
        
        return path
    }
    
    private func drawBalancedSquares (view: UIView) -> UIBezierPath {
        let path = UIBezierPath()
        // smaller box:
        path.move(to: CGPoint(x: view.frame.width * 3 / 10, y: view.frame.height * 3 / 10))
        path.addLine(to: CGPoint(x: view.frame.width * 4 / 10, y: view.frame.height * 3 / 10))
        path.addLine(to: CGPoint(x: view.frame.width * 4 / 10, y: view.frame.height * 7 / 10))
        path.addLine(to: CGPoint(x: view.frame.width * 3 / 10, y: view.frame.height * 7 / 10))
        path.close()
        
        //  larger box: needs to be 4x scale
        path.addLine(to: CGPoint(x: view.frame.width * 12 / 20, y: view.frame.height * 2 / 20))
        path.addLine(to: CGPoint(x: view.frame.width * 18 / 20, y: view.frame.height * 2 / 20))
        path.addLine(to: CGPoint(x: view.frame.width * 18 / 20, y: view.frame.height * 18 / 20))
        path.addLine(to: CGPoint(x: view.frame.width * 12 / 20, y: view.frame.height * 18 / 20))
        path.close()
        
        path.move(to: CGPoint(x: view.frame.width * 4 / 10, y: view.frame.height * 3 / 10))
        path.addLine(to: CGPoint(x: view.frame.width * 18 / 20, y: view.frame.height * 2 / 20))
        
        path.move(to: CGPoint(x: view.frame.width * 4 / 10, y: view.frame.height * 7 / 10))
        path.addLine(to: CGPoint(x: view.frame.width * 18 / 20, y: view.frame.height * 18 / 20))
        
        path.move(to: CGPoint(x: view.frame.width * 3 / 10, y: view.frame.height * 7 / 10))
        path.addLine(to: CGPoint(x: view.frame.width * 12 / 20, y: view.frame.height * 18 / 20))
        
        return path
    }
}

enum Composition {
    // Default - cut into 9 equal square sections, CentralSquare - a box in the center third of the screen, Quadrents - 4 equal square sections, GoldenSpiral - Golden ratio spiral, GoldenTriangles - an expression of the golden ratio rule but with triangles, BalancedSquares - a 3-d elongated box (helps for depth framing)
    case Default, CentralSquare, Quandrants, GoldenSpiral, GoldenTriangles, BalancedSquares
    
    func getName () -> String {
        switch self {
        case .Default:
            return "Default"
        case .CentralSquare:
            return "Central Square"
        case .Quandrants:
            return "Quandrants"
        case .GoldenSpiral:
            return "Golden Spiral"
        case .GoldenTriangles:
            return "Golden Triangles"
        case .BalancedSquares:
            return "Balanced Squares"
        }
    }
    
    // coordinate range representation of perfect picture range
    func getGoldenRegions (frame: CGRect) -> [CGRect] {
        let phi = (1 + sqrt(5)) / 2 as CGFloat
        let y = ((frame.width * frame.height) / sqrt(pow(frame.width, 2) + pow(frame.height, 2))) * (frame.width / frame.height)
        let x = y * frame.height / frame.width
        switch self {
        case .Default:
            return [CGRect(x: frame.width / 3, y: frame.height / 3, width: frame.width / 3, height: frame.height / 3)]
        case .CentralSquare:
            return [CGRect(x: frame.width / 3, y: frame.height / 3, width: frame.width / 3, height: frame.height / 3)]
        case .Quandrants:
            return [CGRect(x: frame.width * 2 / 5, y: frame.height * 2 / 5, width: frame.width / 5, height: frame.height / 5)]
        case .GoldenSpiral:
            return [CGRect(x: 0.0, y: 0.0, width: frame.width - frame.width * phi, height: frame.height - frame.height * phi), CGRect(x: frame.width / phi, y: frame.height / phi, width: frame.width - frame.width * phi, height: frame.height - frame.height * phi), CGRect(x: frame.width / phi, y: 0.0, width: frame.width - frame.width * phi, height: frame.height - frame.height * phi), CGRect(x: 0.0, y: frame.height / phi, width: frame.width - frame.width * phi, height: frame.height - frame.height * phi)]
        case .GoldenTriangles:
            return [CGRect(x: x, y: frame.height - y, width: frame.width - 2 * x, height: frame.height - 2 * y)]
        case .BalancedSquares:
            return [CGRect(x: frame.width * 3 / 10, y: frame.height * 3 / 10, width: frame.width / 10, height: frame.height * 4 / 10), CGRect(x: frame.width * 12 / 20, y: frame.height * 2 / 20, width: frame.width * 4 / 20, height: frame.height * 16 / 20)]
        }
    }
}

