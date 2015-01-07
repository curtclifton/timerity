footer: Curt Clifton—The Omni Group. Jan 8, 2015, Seattle Xcoders
slidenumbers: true

^ Sample presenter notes.

^ Are we good?

![fit](testImage.png)

---

# [fit] Developing with
# [fit] WatchKit 1.0

^ [transition to introduce yourself]

---

# Developing with WatchKit 1.0

## Curt Clifton

### The Omni Group

#### Twitter: @curtclifton

#### Web: curtclifton.net

---

**Outline**

^ [Discuss in terms of your goals for them leaving the talk]

---

# Outline

- Conceptual model

---

# Outline

- Conceptual model

- Sample app

--- 

# Outline

- Conceptual model

- Sample app

- Syncing data with Watch

--- 

# Outline

- Conceptual model

- Sample app

- Syncing data with Watch

- Debugging Watch apps

--- 

# Outline

- Conceptual model

- Sample app

- Syncing data with Watch

- Debugging Watch apps

- Some challenges

--- 

# Outline

- Conceptual model

- Sample app

- Syncing data with Watch

- Debugging Watch apps

- Some challenges

- Other resources

---

# [fit] Conceptual
# [fit] Model

---

## In WatchKit 1.0 your code runs in an extension on the iPhone.

---

## In WatchKit 1.0 your code runs in an extension on the iPhone.

![original](PhoneAndWatch.png)

^ [[[add callouts to the figure noting what code runs where and how it's written]]]

^ WatchKit extension and Watch app resources are bundled with your iPhone app (like Today and Sharing extensions and custom keyboards)

---

## All UI elements on the Watch are accessed through proxy objects.

^ [[[Need an image here]]]

^ Some important conceptual bits on WKInterfaceObjects as proxies: https://developer.apple.com/library/prerelease/ios/documentation/General/Conceptual/WatchKitProgrammingGuide/InterfaceObjects.html#//apple_ref/doc/uid/TP40014969-CH13-SW1

---

## All the WatchKit classes fit on one slide that you can read.

### Enjoy it while it lasts

^ [[[Need an image here]]]

---

# [fit] Sample
# [fit] App

---

# [fit] Syncing 
# [fit] Data with 
# [fit] Watch

^ Tom Harrington’s’s file coordination notes: http://www.atomicbird.com/blog/sharing-with-app-extensions
^ File coordination is a no no: https://developer.apple.com/library/ios/technotes/tn2408/_index.html
^ 	File coordination may be OK: https://devforums.apple.com/message/1074447#1074447
^ 	But probably not, since we still don’t get a chance to deregister.
^ Using Darwin notifications to send notifications: https://devforums.apple.com/message/1078581#1078581
^ Using a shared CoreData database: http://stackoverflow.com/questions/24641768/accessing-core-data-sql-database-in-ios-8-extension-sharing-data-between-app-an


---

# [fit] Debugging 
# [fit] Watch 
# [fit] Apps

^ SimPholders2 for finding which simulator is active
^ System Log in Console: show logging
^ Launch iPhone app first to get the simulator rolling.
^ Open Watch display
^ Kill the app
^ Launch the WatchKit app
^ In the simulator, tap the iPhone app
^ In Xcode, connect to the iPhone app (now you can switch between the apps with the drop-down in Xcode’s debug console header
^ Note that log messages don’t seem to appear in the console this way, but breakpoints work. You can open the simulator log file in Console to see the log messages.

---

# [fit] Challenges

^ Send UI commands when the corresponding element is not active doesn't update the UI.
^ Using shared frameworks.
^ Selecting watch menu items crashes the simulator eventually

---

# [fit] Useful
# [fit] Resources

---

# From Apple

- [Marketing site](http://www.apple.com/watch/)

- [Dev and design resources](http://developer.apple.com/watchkit/)

^ Links will be in posted slides on curtclifton.net

---

# From Others

- [“A Day with Watch”](http://furbo.org/2014/11/20/a-day-with-apple-watch/)
Craig Hockenberry

- [“As I Learn WatchKit”](http://david-smith.org/watchkit/)
David Smith

- [To-scale Watch Mockup PDF](http://files.iconfactory.net/craig/twitter/Apple_Watch_1-1_v2.pdf)
Thibaut Sailly

![right](WatchBlueprint.png)

---

# Bezel

- [Free from Troy Gaul](http://infinitapps.com/bezel/)

- Combine with [Xscope Mirror](http://furbo.org/2015/01/06/bezel-and-xscope/)

![right](bezelApp.png)
