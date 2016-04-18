import Foundation

/**
    Pausable timer.
*/
class Timer : NSObject
{
    private var _startedAt       :Double?
    private var _timerTimeElapsed:Double!
    private var _fireInterval    :Double!
    private var _lastElapsedTime  :Double!

    private var _clockTimer :NSTimer!

    private var _timerFireCallback:(()->Void)?
    
    private var _repeats :Bool!
    private var _isPaused:Bool!

    /**
        Creates a timer.
    */
    convenience init(interval:Double, callback:(()->Void)?, repeats:Bool)
    {
        self.init()
        _isPaused                  = true
        _repeats                   = repeats
        _fireInterval              = interval
        _timerFireCallback         = callback
        _lastElapsedTime           = CACurrentMediaTime()
        _timerTimeElapsed          = 0
        _clockTimer                = NSTimer(timeInterval: 0.0001, target: self, selector: "clockCycleUpdate:", userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(_clockTimer, forMode: NSRunLoopCommonModes)
    }
    
    func clockCycleUpdate(sender:AnyObject)
    {
        // If its playing, add time to time elapsed
        if (_isPaused == false)
        {
            var newTimeInterval = CACurrentMediaTime() - _lastElapsedTime
            _timerTimeElapsed = _timerTimeElapsed + newTimeInterval
            
            if (_timerTimeElapsed >= _fireInterval)
            {
                fireCallback()
                
                if _repeats == true{
                    // If repeating, add the remainder time to the new cycle of time elapsed
                    _timerTimeElapsed = _timerTimeElapsed - _fireInterval
                }else{
                    self.invalidate()
                }
            }
        }
        
        _lastElapsedTime = CACurrentMediaTime()
    }
    
    /**
        Starts the timer.
    */
    func play()
    {
        _isPaused       = false
    }

    /**
        Pauses the timer.
    */
    func pause()
    {
        _isPaused     = true
    }
    
    /**
        Fires the callback if set.
    */
    private func fireCallback()
    {
        if (_timerFireCallback != nil)
        {
            _timerFireCallback!()
        }
    }
    
    /**
        Invalidates timer.
    */
    func invalidate()
    {
        _clockTimer.invalidate()
    }
}
