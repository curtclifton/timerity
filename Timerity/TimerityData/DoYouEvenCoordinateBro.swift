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

/// This is a sample class to experiment with file coodination in watch extensions.
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
    
    // TODO: there's no sensible place to call this from the watch app
    public func invalidate() {
        if isInvalidated {
            return
        }
        NSFileCoordinator.removeFilePresenter(self)
    }
    
    deinit {
    }
    
    public func read() {
        assert(!isInvalidated)
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
            NSLog("Huh");
        }
    }
    
    public func write() {
        assert(!isInvalidated)
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
            NSLog("Huh");
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
        // TODO: implement
        NSLog("relinquishing to reader")
        reader() {
            // anything?
            NSLog("reader is done")
        }
    }
    
    public func relinquishPresentedItemToWriter(writer: ((() -> Void)!) -> Void) {
        // TODO: implement
        NSLog("relinquishing to writer")
        writer() {
            // anything?
            NSLog("writer is done")
        }
    }
}