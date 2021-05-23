//
//  File.swift
//  
//
//  Created by Andreas Hausberger on 16.05.21.
//

import Foundation

public enum StorageError: Error {
    case NotFoundError
    case ReadError
    case WriteError
    case DeleteError
}
