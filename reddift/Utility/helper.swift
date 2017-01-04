//
//  helper.swift
//  reddift
//
//  Created by sonson on 2015/04/27.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

/// Shared color class
#if os(iOS) || os(tvOS)
    public typealias ReddiftColor = UIColor
#elseif os(macOS)
    public typealias ReddiftColor = NSColor
#endif
