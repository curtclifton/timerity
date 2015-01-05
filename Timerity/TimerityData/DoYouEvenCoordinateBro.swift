//
//  DoYouEvenCoordinateBro.swift
//  Timerity
//
//  Created by Curt Clifton on 1/5/15.
//  Copyright (c) 2015 curtclifton.net. All rights reserved.
//

import Foundation

let groupURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.net.curtclifton.Timerity")
let broDatabaseURL = groupURL!.URLByAppendingPathComponent("bro.txt", isDirectory: false)

func spinUpQueue() -> NSOperationQueue {
    let queue = NSOperationQueue()
    queue.maxConcurrentOperationCount = 1
    return queue
}
let processingQueue = spinUpQueue()

public class DoYouEvenCoordinateBro: NSObject {
    public var text: String = ""
    let fileCoordinator: NSFileCoordinator!
    private var isRegistered = false
    private var isInvalidated = false
    
    public override init() {
        super.init()
        fileCoordinator = NSFileCoordinator(filePresenter: self)
        read()
    }
    
    public func invalidate() {
        if isInvalidated {
            return
        }
        
        NSFileCoordinator.removeFilePresenter(self)
    }
    
    deinit {
    }
    
    public func read() {
        var coordinationSuccess = false // assume the worst
        var coordinationError: NSError?
        NSLog("Beginning coordinated read");
        fileCoordinator.coordinateReadingItemAtURL(broDatabaseURL, options: nil, error: &coordinationError) { actualURL in
            assert(actualURL == broDatabaseURL)
            
            if !self.isRegistered {
                NSFileCoordinator.addFilePresenter(self)
                self.isRegistered = true
            }
            
            let maybeText = NSString(contentsOfURL: broDatabaseURL, encoding: NSUnicodeStringEncoding, error: &coordinationError)
            if let text = maybeText {
                self.text = text
                coordinationSuccess = true
            } else {
                NSLog("crap: %@", coordinationError!)
            }
        }
        if coordinationSuccess {
            NSLog("Coordinated read success: %@", text);
        } else if let error = coordinationError {
            NSLog("Coordinated read error: %@", error);
        } else {
            NSLog("WTF?");
        }
    }
    
    public func write() {
        var coordinationSuccess = false // assume the worst
        var coordinationError: NSError?
        NSLog("Beginning coordinated write");
        fileCoordinator.coordinateWritingItemAtURL(broDatabaseURL, options: nil, error: &coordinationError) { actualURL in
            assert(actualURL == broDatabaseURL)
            coordinationSuccess = self.text.writeToURL(broDatabaseURL, atomically: true, encoding: NSUnicodeStringEncoding, error: &coordinationError)
        }
        if coordinationSuccess {
            NSLog("Coordinated write success!");
        } else if let error = coordinationError {
            NSLog("Coordinated write error: %@", error);
        } else {
            NSLog("WTF?");
        }
    }
}

extension DoYouEvenCoordinateBro: NSFilePresenter {
    public var presentedItemURL: NSURL? {
        NSLog("somebody is asking for presentedItemURL")
        NSLog("It's “%@”", broDatabaseURL)
        return broDatabaseURL
    }
    
    public var presentedItemOperationQueue: NSOperationQueue {
        NSLog("somebody is asking for presentedItemOperationQueue")
        return processingQueue
    }
    
    public func relinquishPresentedItemToReader(reader: ((() -> Void)!) -> Void) {
        // CCC, 1/4/2015. implement
        NSLog("relinquishing to reader")
        reader() {
            // anything?
            NSLog("reader is done")
        }
    }
    
    public func relinquishPresentedItemToWriter(writer: ((() -> Void)!) -> Void) {
        // CCC, 1/4/2015. implement
        NSLog("relinquishing to writer")
        writer() {
            // CCC, 1/4/2015. need to reload the contents of the file and send appropriate callbacks. probably should kick over to the main queue to do that
            NSLog("writer is done")
        }
    }
    
    public func presentedItemDidChange() {
        // CCC, 1/4/2015. not sure we need this because we should always get relinquishPresentedItemToWriter (the file is in our sandbox and we're using file coordination in both processes
        NSLog("presentedItemDidChange")
    }
}