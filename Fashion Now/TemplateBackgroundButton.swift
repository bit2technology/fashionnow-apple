//
//  TemplateBackgroundButton.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-31.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class TemplateBackgroundButton: UIButton {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        setBackgroundImage(backgroundImageForState(.Normal)?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
    }
}
