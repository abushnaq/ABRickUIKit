//
//  ABMarquee.swift
//  ABRichUIKit
//
//  Created by Ahmad Remote on 7/10/24.
//

import UIKit


/*
 1) Add a headline struct with a callback and use that for adding headlines
 2) Make the callback when tapped
 3) Remvoe all force unwraps X
 4) Make remove work correctly.
 5) Give container the correct size and defaults
 6) What else?
 */

/*
 Cleanup alot of the code X
 touch handling
 More programmatically friendly - dynamic addition and removal of headlines
 custom styling from client side
 make it an SPM
 Try it in a separate app entirely
 
 /*
  add way to tap on headlines and get a method called
  add way to get labels added externally to support more styles
  The container is the one that is moving. Can we get more accurate taps from the container with the animation, THEN check if they match the labels?
  
  */
 
 */

public struct Headline : Hashable {
    public static func == (lhs: Headline, rhs: Headline) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    public let id = UUID().uuidString
    public var title : String = ""
    public var touchCallback : ((String) -> Void)?
    
}

public class ABMarquee: UIView {
    var container : UIView = UIView()
    public var margin : CGFloat = 15.0
    public var animationSpeed : Double = 3.0
    var headlinesToAnimate : [Headline] = [Headline]()
    var labelsForHeadlines : [Headline : UILabel] = [:]
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.clipsToBounds = true
        
        container = UIView(frame: self.bounds)
        
        container.frame = container.frame.offsetBy(dx: self.bounds.width, dy: 0.0)
        container.backgroundColor = .green
        self.addSubview(container)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1
        self.addGestureRecognizer(tapGesture)
    }
    var animator : UIViewPropertyAnimator?
    func start() {
        guard animator?.state != .active else { animator?.continueAnimation(withTimingParameters: nil, durationFactor: 1.0)
            return }
        animator = UIViewPropertyAnimator(duration: animationSpeed, curve: .linear, animations: {
            self.container.layer.position.x -= self.container.layer.bounds.width * 2.0
            
        })
        animator?.isUserInteractionEnabled = true
        animator?.isManualHitTestingEnabled = true
        animator?.startAnimation()
        
        animator?.addCompletion() { position in
            self.container.layer.position.x += self.container.layer.bounds.width * 2.0
            
            self.processPendingHeadlineAdds()
            self.processPendingHeadlineRemoves()
            self.start()
        }
    }
    
    func processPendingHeadlineAdds()
    {
        for pendingHeadlineAdd in pendingHeadlineAdds {
            pendingHeadlineAdd()
        }
        pendingHeadlineAdds.removeAll()
    }
    
    func processPendingHeadlineRemoves()
    {
        for pendingHeadlineRemove in pendingHeadlineRemoves {
            pendingHeadlineRemove()
        }
        pendingHeadlineRemoves.removeAll()
    }
    
    func stop() {
        self.animator?.pauseAnimation()
    }
    
    @objc func tapped( _ gesture : UITapGestureRecognizer) {
        let touchPoint = gesture.location(in: gesture.view)
        
        if let hitLayer = container.layer.presentation()?.hitTest(touchPoint)
        {
            for (headline, labelsForHeadline) in labelsForHeadlines {
                if let labelPresentationLayer = labelsForHeadline.layer.presentation()
                {
                    if labelPresentationLayer == hitLayer
                    {
                        headline.touchCallback?(headline.id)
                        return;
                    }
                }
                
            }
        }
        
        return
    }
 
    fileprivate func createLabel(_ index: Int, _ position : CGFloat) -> UILabel {
        let label = UILabel(frame: CGRect(x: position, y: 0, width: 150, height: 300))
        let headline = headlinesToAnimate[index]
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = headline.title
        label.isUserInteractionEnabled = true
        label.sizeToFit()
        return label
    }
    var marqueeConstraints : [NSLayoutConstraint] = [NSLayoutConstraint]()
    func setupLayoutConstraints(_ label : UILabel, previousLabel: UILabel?)
    {
        var itemToConnectWith : UIView = self
        var constant = self.bounds.size.width
        var attribute = NSLayoutConstraint.Attribute.leading
        
        if let _previousLabel = previousLabel
        {
            itemToConnectWith = _previousLabel
            attribute = NSLayoutConstraint.Attribute.trailing
            constant = 15
        }
        else {
            return
        }
        
        let constraint = NSLayoutConstraint(item: label, attribute: .leading, relatedBy: .equal, toItem: itemToConnectWith, attribute: attribute, multiplier: 1.0, constant: constant)
        marqueeConstraints.append(constraint)
        self.addConstraint(constraint)
    }
    public func removeHeadline(_ headlineID : String)
    {
        let labelForHeadline = labelsForHeadlines.filter() { $0.key.id == headlineID}.map() { return $0.value }
        headlinesToAnimate = headlinesToAnimate.filter() { $0.id != headlineID }
        
        
        
        pendingHeadlineRemoves.append({ [self] in
            labelsForHeadlines.removeAll()
            container.subviews.forEach() { $0.removeFromSuperview() }
            
            addHeadlines()
            
            var size = container.frame.size
            if let _lastLabel = labelForHeadline.last
            {
                size.width = min(size.width, _lastLabel.frame.origin.x +  _lastLabel.frame.size.width + margin)
            }
            
            container.bounds.size = size
        })
    }
    
    var pendingHeadlineAdds : [() -> Void] = [() -> Void]()
    var pendingHeadlineRemoves : [() -> Void] = [() -> Void]()

    
    public func addHeadline(_ headline : Headline)
    {
        headlinesToAnimate.append(headline)
        pendingHeadlineAdds.append(
        { [self] in
            var origin = margin
            var furthestLabel : UILabel? = nil
            var furthestOrigin = 0.0
            for (_, label) in labelsForHeadlines
            {
                if label.frame.origin.x >= furthestOrigin
                {
                    furthestLabel = label
                    furthestOrigin = label.frame.origin.x
                }
            }
            
            if let lastLabel = furthestLabel
            {
                origin += lastLabel.frame.origin.x + lastLabel.frame.size.width
            }
            let label = createLabel(labelsForHeadlines.count, origin)
            self.container.addSubview(label)
            self.container.isUserInteractionEnabled = true
            setupLayoutConstraints(label, previousLabel: furthestLabel)
            labelsForHeadlines[headline] = label
            var size = container.frame.size
            
            if let lastLabel = furthestLabel
            {
                size.width = max(size.width, lastLabel.frame.origin.x +  lastLabel.frame.size.width + margin)
            }
            else
            {
                size.width = max(size.width, label.frame.origin.x +  label.frame.size.width + margin)
            }
            container.bounds.size = size
        })
    }
    func addHeadlines() {
        var xOrigin = 5.0//self.frame.size.width
        
        for index in 0...headlinesToAnimate.count - 1
        {
            let headline = headlinesToAnimate[index]
            let label = createLabel(index, xOrigin)
            self.container.addSubview(label)
            self.container.isUserInteractionEnabled = true
            var furthestLabel : UILabel? = nil
            var furthestOrigin = 0.0
            for (_, label) in labelsForHeadlines
            {
                if label.frame.origin.x >= furthestOrigin
                {
                    furthestLabel = label
                    furthestOrigin = label.frame.origin.x
                }
            }
            
            setupLayoutConstraints(label, previousLabel: furthestLabel)
            
            labelsForHeadlines[headline] = label
            xOrigin += label.frame.size.width + margin
        }
        
    }
}
