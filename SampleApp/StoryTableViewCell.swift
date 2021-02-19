//
//  StoryTableViewCell.swift
//  SampleApp
//
//  Created by Philip Fryklund on 2019-01-21.
//  Copyright © 2019 Philip Fryklund. All rights reserved.
//

import UIKit



/// Shared cell
class HighlightableTableViewCell: UITableViewCell {
	
	// Custom implementation is selection
	override func setSelected(_ selected: Bool, animated: Bool) {
		func uiChanges() {
			self.contentView.backgroundColor = selected ? UIColor(white: 0.9, alpha: 1.0) : .white
		}
		
		if animated {
			UIView.animate(withDuration: 0.2, animations: uiChanges)
		}
		else {
			uiChanges()
		}
    }

	// Have same look when highlighted (touch down) as selected and if already selected then dont reset its look
	override func setHighlighted(_ highlighted: Bool, animated: Bool) {
		setSelected(highlighted || self.isSelected, animated: animated)
	}
}



final class StoryTableViewCell: HighlightableTableViewCell, TableViewCellLoadable {
	
	@IBOutlet var scoreLabel: UILabel!
	@IBOutlet var numberOfCommentsLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var authorLabel: UILabel!
	@IBOutlet var dateLabel: UILabel!
	
	weak var story: Story? {
		didSet {
			scoreLabel.text = story?.score.map { "\($0)" } ?? "_"
			numberOfCommentsLabel.text = story?.numberOfComments.map { "\($0)" } ?? "_"
			titleLabel.text = story?.title ?? "..."
			authorLabel.text = story?.author ?? "..."
			dateLabel.text = story?.date?.format(date: .medium, time: .short)
		}
	}
	
	
    override func awakeFromNib() {
        super.awakeFromNib()
        
		scoreLabel.text = nil
		numberOfCommentsLabel.text = nil
		titleLabel.text = nil
		authorLabel.text = nil
		dateLabel.text = nil
    }
}
