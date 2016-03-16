import Foundation

/**
    Pausable timer.
*/
class Timer : NSObject
{
    // The last time difference between pausing and unpausing
    // Is resets each time timer fires
    // Is used to handle edge case where instead of the callback firing
    // When it should, it gets skipped because the timer gets invalidated
    // before firing (seems like a same-frame issue within the NS framework)
    // This is used to fire a callback if, when paused, the timer should have
    // fired at least onces before the new timer loop starts
    private var _lastTimeDifference       :Double!
    private var _pausedAt                 :Double?
    private var _startedAt                :Double?
    private var _timerDifference          :Double?
    private var _fireInterval             :Double!
    private var _pauseToResumeTimeInterval:Double!

    private var _timer          :NSTimer!
    // The fractional timer difference timer that
    // Handles time difference between pausing
    // And resuming
    private var _startAfterTimer:NSTimer!

    private var _timerFireCallback:(()->Void)?
    
    private var _repeats:Bool!

    /**
        Creates a timer
    */
    convenience init(interval:Double, callback:(()->Void)?, repeats:Bool)
    {
        self.init()
        _repeats                   = repeats
        _lastTimeDifference        = _fireInterval
        _fireInterval              = interval
        _timerFireCallback         = callback
        _timer                     = NSTimer(timeInterval: _fireInterval, target: self, selector: "timerFired:", userInfo: nil, repeats: repeats)
        _pauseToResumeTimeInterval = 0
    }
    
    /**
        Starts the timer. Client should call this once the first time.
    */
    func start()
    {
        NSRunLoop.currentRunLoop().addTimer(_timer, forMode: NSRunLoopCommonModes)
        _startedAt = CACurrentMediaTime()
    }
    
    /**
        Starts the timer after a timer interval. Client should only call this once the first time.
    */
    func startAfter(time:Double)
    {
        _startAfterTimer = NSTimer(timeInterval: time, target: self, selector: "timerResume:", userInfo: nil, repeats: false)
        NSRunLoop.currentRunLoop().addTimer(_startAfterTimer, forMode: NSRunLoopCommonModes)
    }
    
    /**
        Resumes timer. SHOULD NEVER BE CALLED. Must be public
        for callback to fire.
    */
    func timerResume(sender:AnyObject)
    {
        start()
        fireCallback()
        _lastTimeDifference = _fireInterval
    }
    
    /**
        Pauses the timer.
    */
    func pause()
    {
        _timer.invalidate()
        
        _pausedAt                  = CACurrentMediaTime()
        let diff                   = _pausedAt! - _startedAt!
        _pauseToResumeTimeInterval = _fireInterval - (diff % _fireInterval)
        
        if (_startAfterTimer != nil)
        {
            // There is a chance that the interval of the start
            // After timer is so small that it gets invalidated
            // Before firing, thus negating an entire timer cycle
            // This checks for that and fires the callback if necessary
            
            if (_pauseToResumeTimeInterval > _lastTimeDifference)
            {
                fireCallback()
            }
            
            _startAfterTimer.invalidate()
        }
        
        _lastTimeDifference = _pauseToResumeTimeInterval
    }
    
    /**
        Resumes the timer.
    */
    func resume()
    {
        // Recreate the timer anew
        _timer = NSTimer(timeInterval: _fireInterval, target: self, selector: "timerFired:", userInfo: nil, repeats: _repeats)

        startAfter(_pauseToResumeTimeInterval)
    }
    
    /**
        Callback for timer that calls the fire callback.
    */
    func timerFired(sender:AnyObject)
    {
        fireCallback()
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
        _timer.invalidate()
        _startAfterTimer.invalidate()
    }
}
