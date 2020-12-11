//
//  ActiveLabel.swift
//  ActiveLabel
//
//  Created by Johannes Schickling on 9/4/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit

public protocol ActiveLabelDelegate: class {
    func activeLabel(_ activeLabel: ActiveLabel, didSelectActiveEntity entity: ActiveEntity)
}

public class ActiveLabel: UILabel {
    
    // MARK: - Public Properties
    public weak var delegate: ActiveLabelDelegate?
    public var activeEntities: [ActiveEntity] = [] {
        didSet {
            updateTextStorage()
        }
    }
        
    public var urlMaximumLength: Int?
        
    public var mentionColor: UIColor = .blue
    public var mentionSelectedColor: UIColor?
    public var hashtagColor: UIColor = .blue
    public var hashtagSelectedColor: UIColor?
    public var URLColor: UIColor = .blue
    public var URLSelectedColor: UIColor?

    public var lineSpacing: CGFloat = 0
    public var minimumLineHeight: CGFloat = 0
    public var highlightFontName: String? = nil
    public var highlightFontSize: CGFloat? = nil
    
    // MARK: - Private Properties
    fileprivate var defaultCustomColor: UIColor = .black
    
    fileprivate var mentionFilterPredicate: ((String) -> Bool)?
    fileprivate var hashtagFilterPredicate: ((String) -> Bool)?
    
    fileprivate var selectedEntity: ActiveEntity?
    fileprivate var heightCorrection: CGFloat = 0
    
    private let textStorage = NSTextStorage()
    private let layoutManager = NSLayoutManager()
    private let textContainer = NSTextContainer()
    
    // MARK: - Computed Properties
    private var hightlightFont: UIFont? {
        guard let highlightFontName = highlightFontName, let highlightFontSize = highlightFontSize else { return nil }
        return UIFont(name: highlightFontName, size: highlightFontSize)
    }
    
    // MARK: - init functions
    override public init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _init()
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        updateTextStorage()
    }
}

extension ActiveLabel {
    private func _init() {
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = lineBreakMode
        textContainer.maximumNumberOfLines = numberOfLines
        isUserInteractionEnabled = true
    }
}

// MARK: - override UILabel properties
extension ActiveLabel {

    override public var text: String? {
        didSet { updateTextStorage() }
    }
    
    override public var attributedText: NSAttributedString? {
        didSet { updateTextStorage() }
    }
    
    override public var font: UIFont! {
        didSet { updateTextStorage() }
    }
    
    override public var textColor: UIColor! {
        didSet { updateTextStorage() }
    }
    
    override public var textAlignment: NSTextAlignment {
        didSet { updateTextStorage() }
    }
    
    override public var numberOfLines: Int {
        didSet { textContainer.maximumNumberOfLines = numberOfLines }
    }
    
    override public var lineBreakMode: NSLineBreakMode {
        didSet { textContainer.lineBreakMode = lineBreakMode }
    }

    
    open override func drawText(in rect: CGRect) {
        let range = NSRange(location: 0, length: textStorage.length)
        
        textContainer.size = rect.size
        let newOrigin = textOrigin(inRect: rect)
        
        layoutManager.drawBackground(forGlyphRange: range, at: newOrigin)
        layoutManager.drawGlyphs(forGlyphRange: range, at: newOrigin)
    }
}

// MARK: - Auto Layout
extension ActiveLabel {
        
    open override var intrinsicContentSize: CGSize {
        guard let text = text, !text.isEmpty else {
            return .zero
        }

        textContainer.size = CGSize(width: self.preferredMaxLayoutWidth, height: CGFloat.greatestFiniteMagnitude)
        let size = layoutManager.usedRect(for: textContainer)
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }
    
}

// MARK: - touch events
extension ActiveLabel {
    
    func onTouch(_ touch: UITouch) -> Bool {
        let location = touch.location(in: self)
        var avoidSuperCall = false
        
        switch touch.phase {
        case .began, .moved, .regionEntered, .regionMoved:
            if let entity = entity(at: location) {
                if entity.range.location != selectedEntity?.range.location || entity.range.length != selectedEntity?.range.length {
                    updateAttributesWhenSelected(false)
                    selectedEntity = entity
                    updateAttributesWhenSelected(true)
                }
                avoidSuperCall = true
            } else {
                updateAttributesWhenSelected(false)
                selectedEntity = nil
            }
        case .ended, .regionExited:
            guard let selectedEntity = selectedEntity else { return avoidSuperCall }
            delegate?.activeLabel(self, didSelectActiveEntity: selectedEntity)
            
            let when = DispatchTime.now() + Double(Int64(0.25 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: when) {
                self.updateAttributesWhenSelected(false)
                self.selectedEntity = nil
            }
            avoidSuperCall = true
        case .cancelled:
            updateAttributesWhenSelected(false)
            selectedEntity = nil
        case .stationary:
            break
        @unknown default:
            break
        }
        
        return avoidSuperCall
    }
    
}

//MARK: - Handle UI Responder touches
extension ActiveLabel {
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch) { return }
        super.touchesBegan(touches, with: event)
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch) { return }
        super.touchesMoved(touches, with: event)
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        _ = onTouch(touch)
        super.touchesCancelled(touches, with: event)
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch) { return }
        super.touchesEnded(touches, with: event)
    }
    
}

// MARK: - helper functions
extension ActiveLabel {
    
    private func updateTextStorage() {
        // clean up previous active elements
        guard let attributedText = attributedText, attributedText.length > 0 else {
            clearActiveElements()
            textStorage.setAttributedString(NSAttributedString())
            setNeedsDisplay()
            return
        }

        let mutableAttributedString = addLineBreak(attributedText)
        addLinkAttribute(mutableAttributedString)
        textStorage.setAttributedString(mutableAttributedString)
        
        if text != mutableAttributedString.string {
            text = mutableAttributedString.string
        }
        
        setNeedsDisplay()
    }
    
    private func clearActiveElements() {
        selectedEntity = nil
        if !activeEntities.isEmpty {
            activeEntities.removeAll()
        }
    }
    
    private func textOrigin(inRect rect: CGRect) -> CGPoint {
        let usedRect = layoutManager.usedRect(for: textContainer)
        heightCorrection = (rect.height - usedRect.height)/2
        let glyphOriginY = heightCorrection > 0 ? rect.origin.y + heightCorrection : rect.origin.y
        return CGPoint(x: rect.origin.x, y: glyphOriginY)
    }
    
    /// add link attribute
    private func addLinkAttribute(_ mutableAttributedString: NSMutableAttributedString) {
        var range = NSRange(location: 0, length: 0)
        var attributes = mutableAttributedString.attributes(at: 0, effectiveRange: &range)
        
        attributes[NSAttributedString.Key.font] = font!
        attributes[NSAttributedString.Key.foregroundColor] = textColor
        mutableAttributedString.addAttributes(attributes, range: range)
        
        attributes[NSAttributedString.Key.foregroundColor] = mentionColor
        
        for entity in activeEntities {
            switch entity.type {
            case .mention:  attributes[NSAttributedString.Key.foregroundColor] = mentionColor
            case .hashtag:  attributes[NSAttributedString.Key.foregroundColor] = hashtagColor
            case .email:    attributes[NSAttributedString.Key.foregroundColor] = URLColor
            case .url:      attributes[NSAttributedString.Key.foregroundColor] = URLColor
            }
            
            if let highlightFont = hightlightFont {
                attributes[NSAttributedString.Key.font] = highlightFont
            }
            
            mutableAttributedString.setAttributes(attributes, range: entity.range)
        }
    }
    
    /// add line break mode
    private func addLineBreak(_ attrString: NSAttributedString) -> NSMutableAttributedString {
        let mutAttrString = NSMutableAttributedString(attributedString: attrString)
        
        var range = NSRange(location: 0, length: 0)
        var attributes = mutAttrString.attributes(at: 0, effectiveRange: &range)
        
        let paragraphStyle = attributes[NSAttributedString.Key.paragraphStyle] as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraphStyle.alignment = textAlignment
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.minimumLineHeight = minimumLineHeight > 0 ? minimumLineHeight: self.font.pointSize * 1.14
        attributes[NSAttributedString.Key.paragraphStyle] = paragraphStyle
        mutAttrString.setAttributes(attributes, range: range)
        
        return mutAttrString
    }
    
    fileprivate func updateAttributesWhenSelected(_ isSelected: Bool) {
        guard let selectedEntity = selectedEntity else {
            return
        }
        
        var attributes = textStorage.attributes(at: 0, effectiveRange: nil)
        let type = selectedEntity.type
        
        if isSelected {
            let selectedColor: UIColor
            switch type {
            case .mention: selectedColor = mentionSelectedColor ?? mentionColor
            case .hashtag: selectedColor = hashtagSelectedColor ?? hashtagColor
            case .url: selectedColor = URLSelectedColor ?? URLColor
            case .email: selectedColor = URLSelectedColor ?? URLColor
            }
            attributes[NSAttributedString.Key.foregroundColor] = selectedColor
        } else {
            let unselectedColor: UIColor
            switch type {
            case .mention: unselectedColor = mentionColor
            case .hashtag: unselectedColor = hashtagColor
            case .url: unselectedColor = URLColor
            case .email: unselectedColor = URLColor
            }
            attributes[NSAttributedString.Key.foregroundColor] = unselectedColor
        }
        
        if let highlightFont = hightlightFont {
            attributes[NSAttributedString.Key.font] = highlightFont
        }
        
        textStorage.addAttributes(attributes, range: selectedEntity.range)
        
        setNeedsDisplay()
    }
    
    fileprivate func entity(at location: CGPoint) -> ActiveEntity? {
        guard textStorage.length > 0 else {
            return nil
        }
        
        var correctLocation = location
        correctLocation.y -= heightCorrection
        let boundingRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: 0, length: textStorage.length), in: textContainer)
        guard boundingRect.contains(correctLocation) else {
            return nil
        }
        
        let index = layoutManager.glyphIndex(for: correctLocation, in: textContainer)
        
        for entity in activeEntities {
            if index >= entity.range.location && index <= entity.range.location + entity.range.length {
                return entity
            }
        }
        
        return nil
    }
    
}

// MARK: - UIGestureRecognizerDelegate
extension ActiveLabel: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}
