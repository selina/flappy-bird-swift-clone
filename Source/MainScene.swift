import Foundation

class MainScene: CCNode, CCPhysicsCollisionDelegate {
    var _scrollSpeed: CGFloat = 80
    var _hero: CCSprite!
    var _physicsNode: CCPhysicsNode!
    var _ground1: CCSprite!
    var _ground2: CCSprite!
    var grounds: [CCSprite] = []
    var sinceTouch: CCTime = 0
    var obstacles: [CCNode] = []
    let firstObstaclePosition : CGFloat = 280
    let _distanceBetweenObstacles: CGFloat = 160
    var _obstaclesLayer: CCNode!
    var _restartButton: CCButton!
    var _gameOver = false
    
    var points:NSInteger = 0
    var _scoreLabel:CCLabelTTF!
    
    func didLoadFromCCB() {
        _physicsNode.collisionDelegate = self

        self.userInteractionEnabled = true
        grounds.append(_ground1)
        grounds.append(_ground2)
        
        self.spawnNewObstacle()
        self.spawnNewObstacle()
        self.spawnNewObstacle()
        
        _scoreLabel.string = "0"
        
    }
    
    override func update(delta: CCTime) {
        //move the fly
        _hero.position = ccp(_hero.position.x + _scrollSpeed * CGFloat(delta), _hero.position.y)
        
        //update physics node position
        _physicsNode.position = ccp(_physicsNode.position.x - _scrollSpeed * CGFloat(delta), _physicsNode.position.y)
        
        //handle ground scrolling so that the fly doesn't fall off the screen
        for ground in grounds {
            let groundWorldPosition = _physicsNode.convertToWorldSpace(ground.position)
            let groundScreenPosition = self.convertToNodeSpace(groundWorldPosition)
            if groundScreenPosition.x <= (-ground.contentSize.width) {
                ground.position = ccp(ground.position.x + ground.contentSize.width * 2, ground.position.y)
            }
        }
        
        //limit fly's velocity
        let velocityY = clampf(Float(_hero.physicsBody.velocity.y), -Float(CGFloat.max), 200)
        _hero.physicsBody.velocity = ccp(0, CGFloat(velocityY))
        
        //rotate the fly down
        sinceTouch += delta
        _hero.rotation = clampf(_hero.rotation, -30,90)
        
        if (_hero.physicsBody.allowsRotation) {
            let angularVelocity = clampf(Float(_hero.physicsBody.angularVelocity),-2,1)
            _hero.physicsBody.angularVelocity = CGFloat(angularVelocity)
        }
        if (sinceTouch > 0.5) {
            let impulse  = -20000.0 * delta
            _hero.physicsBody.applyAngularImpulse(CGFloat(impulse))
        }
        
        for obstacle in obstacles.reverse() {
            let obstacleWorldPosition = _physicsNode.convertToWorldSpace(obstacle.position)
            let obstacleScreenPosition = self.convertToNodeSpace(obstacleWorldPosition)
            
            if obstacleScreenPosition.x < -obstacle.contentSize.width {
                obstacle.removeFromParent()
                obstacles.removeAtIndex(find(obstacles, obstacle)!)
                
                self.spawnNewObstacle()
            }
        }
    }
    
    override func touchBegan(touch: CCTouch!, withEvent event:CCTouchEvent!) {
            if(_gameOver == false) {
            _hero.physicsBody.applyImpulse(ccp(0,400))
            _hero.physicsBody.applyAngularImpulse(10000)
            sinceTouch = 0
        }
    }
    
    func spawnNewObstacle() {
        var prevObstaclePos = firstObstaclePosition
        if obstacles.count > 0 {
            prevObstaclePos = obstacles.last!.position.x
        }
        
        let obstacle = CCBReader.load("Obstacle") as! Obstacle
        obstacle.position = ccp(prevObstaclePos + _distanceBetweenObstacles, 0)
        obstacle.setupRandomPosition()
        _obstaclesLayer.addChild(obstacle)
        obstacles.append(obstacle)
    }
    
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero: CCNode!, level: CCNode!) -> Bool {
        self.gameOver()
        return true
    }
    
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero: CCNode!, goal: CCNode!) -> Bool {
        goal.removeFromParent()
        points++
        _scoreLabel.string = String(points)
        return true
    }
    
    func restart() {
        var scene = CCBReader.loadAsScene("MainScene")
        CCDirector.sharedDirector().replaceScene(scene)
    }
    
    func gameOver() {
        if (_gameOver == false) {
            _gameOver = true
            _restartButton.visible = true
            _scrollSpeed = 0
            _hero.rotation = 90
            _hero.physicsBody.allowsRotation = false
            
            _hero.stopAllActions()
            
            var move = CCActionEaseBounceOut(action:CCActionMoveBy(duration: 0.2, position:ccp(0,4)))
            var moveBack = CCActionEaseBounceOut(action:move.reverse())
            var shakeSequence = CCActionSequence(array: [move, moveBack])
            self.runAction(shakeSequence)
        }
    }
}
