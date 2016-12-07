//
//  ChatUserCellTableViewCell.swift
//  HotLikeMe
//
//  Created by developer on 07/12/16.
//  Copyright © 2016 MezcalDev. All rights reserved.
//

import UIKit

class ChatUserCellTableViewCell: UITableViewCell {
    
    @IBOutlet weak var chat_userImage: UIImageView!
    @IBOutlet weak var chat_userName: UILabel!
    @IBOutlet weak var chat_lastMessage: UITextView!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
