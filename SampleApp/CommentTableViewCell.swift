//
//  CommentTableViewCell.swift
//  SampleApp
//
//  Created by Philip Fryklund on 3/Oct/19.
//  Copyright © 2019 Philip Fryklund. All rights reserved.
//

import UIKit


final class CommentTableViewCell: HighlightableTableViewCell, TableViewCellLoadable {
	
	static var nib: UINib? = UINib(nibName: identifier, bundle: .main)
	
	@IBOutlet var commentLabel: UILabel!
	@IBOutlet var authorLabel: UILabel!
	@IBOutlet var dateLabel: UILabel!
	@IBOutlet var numberOfAnsweresLabel: UILabel!
	
	weak var comment: Comment? {
		didSet {
			commentLabel.attributedText = comment?.text.flatMap {
				guard let data = $0.data(using: .utf8) else { return nil }
				guard let attr = try? NSMutableAttributedString.init(data: data, options: [
					.documentType: NSAttributedString.DocumentType.html,
					.characterEncoding: String.Encoding.utf8.rawValue
				], documentAttributes: nil) else { return nil }
				attr.addAttributes([.font: commentLabel.font!], range: NSRange(location: 0, length: attr.string.count))
				return NSAttributedString(attributedString: attr)
			}
			authorLabel.text = comment?.author ?? "..."
			dateLabel.text = comment?.date?.format(date: .medium, time: .short)
			numberOfAnsweresLabel.text = (comment?.numberOfAnsweres).map { "\($0)" } ?? "_"
			
			let hasAnsweres = (comment?.numberOfAnsweres ?? 0) > 0
			self.accessoryType = hasAnsweres ? .disclosureIndicator : .none
			self.isUserInteractionEnabled = hasAnsweres // Dont allow to be selected if sub comments doesnt exist
			numberOfAnsweresLabel.isHidden = !hasAnsweres
		}
	}
    
	
    override func awakeFromNib() {
        super.awakeFromNib()
        
		commentLabel.text = nil
		authorLabel.text = nil
		numberOfAnsweresLabel.text = nil
		dateLabel.text = nil
    }
}
