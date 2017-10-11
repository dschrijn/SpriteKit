//
//  GameScene.swift
//  ZombieConga
//
//  Created by David A. Schrijn on 4/2/17.
//  Copyright © 2017 David A. Schrijn. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    //Variables to keep track of timing.
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    
    //Variables
    let zombie = SKSpriteNode(imageNamed: "zombie1")
    let zombieAnimation: SKAction
    let zombieMovePointsPerSec: CGFloat = 480
    var velocity = CGPoint.zero
    let zombieRotatingRadiansPerSec: CGFloat = 4.0 * 3.14159265359
    let playableRect: CGRect //Remember, need to override init to set this variable.
    var lastTouchLocation: CGPoint?
    let catMovePointsPerSec: CGFloat = 480.0
    var lives = 5
    var gameOver = false
    let livesLabel = SKLabelNode(fontNamed: "Glimstick")
    let catsLabel = SKLabelNode(fontNamed: "Glimstick")
    
    //Sound Wav files
    let catCollisionSound: SKAction = SKAction.playSoundFileNamed(
        "hitCat.wav", waitForCompletion: false)
    let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed(
        "hitCatLady.wav", waitForCompletion: false)
    
    //Override Init function
    override init(size: CGSize) {
        let maxAspectRatio: CGFloat = 16.0/9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height - playableHeight) / 2.0
        
        playableRect = CGRect(x: 0, y:playableMargin, width: size.width, height: playableHeight)
        
        //Animates with textures
        var textures:[SKTexture] = []
        for i in 1...4 {
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        textures.append(textures[2])
        textures.append(textures[1])
        
        zombieAnimation = SKAction.animate(with: textures, timePerFrame: 0.1)
        
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Mark: Functions
    
    //Function to stop playing background music
    override func willMove(from view: SKView) {
        backgroundMusicPlayer.stop()
    }
    
    //Function to setup scene(Background, Zombie postion, & Labels)
    override func didMove(to view: SKView) {
        
        //Calling drawing playable area method.
        debugDrawPlayableArea()
        playBackgroundMusic("backgroundMusic.mp3")
        
        //Code to add background
        let background = SKSpriteNode(imageNamed: "background1")
        //Set background position
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5) //default
        background.zPosition = -1 //Z position allows you to layer your sprites.
        addChild(background) //Adding background to scene.
        
        zombie.position = CGPoint(x: 400, y: 400)
        addChild(zombie)
        
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run(spawnEnemy),
                               SKAction.wait(forDuration: 2.0)])))
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run(spawnCat),
                               SKAction.wait(forDuration: 1.0)])))
        //Setup Lives Label
        livesLabel.text = "Lives: \(lives)"
        livesLabel.fontColor = SKColor.black
        livesLabel.fontSize = 100
        livesLabel.zPosition = 100
        livesLabel.horizontalAlignmentMode = .left
        livesLabel.verticalAlignmentMode = .bottom
        livesLabel.position = CGPoint(x: 20, y: size.height/6)
        addChild(livesLabel)
        //Setup Cat Label
        catsLabel.text = "Cats: X"
        catsLabel.fontColor = SKColor.black
        catsLabel.fontSize = 100
        catsLabel.zPosition = 100
        catsLabel.horizontalAlignmentMode = .right
        catsLabel.verticalAlignmentMode = .bottom
        catsLabel.position = CGPoint(x: size.width - 20, y: size.height/6)
        addChild(catsLabel)
    }
    // Zombie Animations
    func startZombieAnimation() {
        if zombie.action(forKey: "animation") == nil {
            zombie.run(SKAction.repeatForever(zombieAnimation), withKey: "animation")
        }
    }
    func stopZombieAnimation() {
        zombie.removeAction(forKey: "animation")
    }
    // Spawn Enemy function
    func spawnEnemy() {
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = "enemy"
        enemy.position = CGPoint(
            x: size.width + enemy.size.width/2,
            y: CGFloat.random(
                min: playableRect.minY + enemy.size.height/2,
                max: playableRect.maxY + enemy.size.height/2))
        addChild(enemy)
        
        let actionMove = SKAction.moveTo(x: -enemy.size.width/2, duration: 2.0)
        let actionRemove = SKAction.removeFromParent()
        enemy.run(SKAction.sequence([actionMove, actionRemove]))
    }
    // Spawn Cat function
    func spawnCat() {
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.name = "cat"
        cat.position = CGPoint(
            x: CGFloat.random(min: playableRect.minX,
                              max: playableRect.maxX),
            y: CGFloat.random(min: playableRect.minY,
                              max: playableRect.maxY))
        cat.setScale(0)
        addChild(cat)
        
        let appear = SKAction.scale(to: 1.0, duration: 0.5)
        
        cat.zRotation = -3.14159265359  / 16.0
        let leftWiggle = SKAction.rotate(byAngle: 3.14159265359/8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversed()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
        
        let scaleUp = SKAction.scale(by: 1.2, duration: 0.25)
        let scaleDown = scaleUp.reversed()
        let fullScale = SKAction.sequence([scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeat(group, count: 10)
        
        let disappear = SKAction.scale(by: 0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear, groupWait, disappear, removeFromParent]
        cat.run(SKAction.sequence(actions))
    }
    
    // Collusion Function
    // Enumerate through cats & enemys and see if the Rects are hitting.
    func checkCollisions() {
        var hitCats: [SKSpriteNode] = []
        enumerateChildNodes(withName: "cat") { node, _ in
            let cat = node as! SKSpriteNode
            if cat.frame.intersects(self.zombie.frame) {
                hitCats.append(cat)
            }
        }
        
        for cat in hitCats {
            print("Hit Cat")
            zombieHit(cat)
        }
        
        var hitEnemies: [SKSpriteNode] = []
        enumerateChildNodes(withName: "enemy") { node, _ in
            let enemy = node as! SKSpriteNode
            if enemy.frame.insetBy(dx: 20, dy: 20).intersects(self.zombie.frame) {
                hitEnemies.append(enemy)
            }
        }
        
        for enemy in hitEnemies {
            print("Hit Enemy")
            zombieHit(enemy)
        }
    }
    
    // Zombie collusion function
    func zombieHit(_ sprite: SKSpriteNode) {
        print("** ZOMBIE HIT: \(String(describing: sprite.name)) **")
        if sprite.name == "cat" {
            // sprite.removeFromParent()
            // run(catCollisionSound)
            sprite.name = "train"
            sprite.removeAllActions()
            sprite.setScale(1.0)
            sprite.zRotation = 0
            
            let turnRed = SKAction.colorize(with: SKColor.red, colorBlendFactor: 1.0, duration: 0.2)
            
            sprite.run(turnRed)
            run(catCollisionSound)
        } else {
            sprite.removeFromParent()
            run(enemyCollisionSound)
            
            lives -= 1
            livesLabel.text = "Lives: \(lives)"
            //Zombie will blink everytime it is hit.
            let blinkTimes = 10.0
            let duration = 3.0
            let blinkAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
                let slice = duration / blinkTimes
                let remainder = Double(elapsedTime).truncatingRemainder(dividingBy: slice)
                node.isHidden = remainder > slice / 2
            }
            
            let setHidden = SKAction.run() {
                self.zombie.isHidden = false
            }
            
            zombie.run(SKAction.sequence([blinkAction, setHidden]))
            loseCats()
        }
    }
    
    // Function to add train of cats.
    func moveTrain() {
        var trainCount = 0
        var targetPosition = zombie.position
        
        enumerateChildNodes(withName: "train") { node, _ in
            trainCount += 1
            self.catsLabel.text = "Cats: \(trainCount)"
            
            if !node.hasActions() {
                let actionDuration = 0.3
                let offset = targetPosition - node.position
                let direction = offset.normalized()
                let amountToMovePerSec = direction * self.catMovePointsPerSec
                let amountToMove = amountToMovePerSec * CGFloat(actionDuration)
                let moveAction = SKAction.moveBy(x: amountToMove.x, y: amountToMove.y, duration: actionDuration)
                
                node.run(moveAction)
            }
            targetPosition = node.position
        }
        
        if trainCount >= 5 && !gameOver {
            gameOver = true
            print("You Win!")
            
            let gameOverScene = GameOverScene(size: size, won: true)
            gameOverScene.scaleMode = scaleMode
            
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    // Function to lose cats if hit.
    func loseCats() {
        var loseCount = 0
        enumerateChildNodes(withName: "train") { node, stop in
            
            var randomSpot = node.position
            randomSpot.x += CGFloat.random(min: -100, max: 100)
            randomSpot.y += CGFloat.random(min: -100, max: 100)
            
            node.name = ""
            node.run(
                SKAction.sequence([
                    SKAction.group([
                        SKAction.rotate(byAngle: 3.14159265359*4, duration: 1.0),
                        SKAction.move(to: randomSpot, duration: 1.0),
                        SKAction.scale(to: 0, duration: 1.0)
                        ]),
                    SKAction.removeFromParent()
                    ]))
            
            loseCount += 1
            if loseCount >= 2 {
                stop.pointee = true
            }
        }
    }
    
    // Mark: Zombie moving Functions.
    
    //Passing in the touch location, it will figure out where it is and calculate the velocity based on where its location is and where the sprite currently is and that will determine how fast and how far to move sprite.
    func moveZombieToward(_ location: CGPoint) {
        let offset = CGPoint(x: location.x - zombie.position.x, y: location.y - zombie.position.y)
        let length = sqrt(Double(offset.x * offset.x + offset.y * offset.y))
        let direction = CGPoint(x: offset.x / CGFloat(length), y: offset.y / CGFloat(length))
        
        velocity = CGPoint(x: direction.x * zombieMovePointsPerSec, y: direction.y * zombieMovePointsPerSec)
        
        startZombieAnimation()
    }
    //Function to make zombie sprite animate. Velocity is how fast to move the sprite. It uses the deltaTime to determine this.
    func moveSprite(_ sprite: SKSpriteNode, velocity: CGPoint) {
        let amountToMove = CGPoint(x: velocity.x * CGFloat(dt),
                                   y: velocity.y * CGFloat(dt))
        print("Amount tp move: \(amountToMove)")
        sprite.position = CGPoint(x: sprite.position.x + amountToMove.x,
                                  y: sprite.position.y + amountToMove.y)
        
    }
    //Function so that zombie sprite does not move outside boundaries.
    func boundsCheckZombie() {
        let bottomLeft = CGPoint(x: playableRect.minX, y: playableRect.minY)
        let topRight = CGPoint(x: playableRect.maxX, y: playableRect.maxY)
        
        if zombie.position.x <= bottomLeft.x {
            zombie.position.x = bottomLeft.x
            velocity.x = -velocity.x
        }
        
        if zombie.position.x >= topRight.x {
            zombie.position.x = topRight.x
            velocity.x = -velocity.x
        }
        
        if zombie.position.y <= bottomLeft.y {
            zombie.position.y = bottomLeft.y
            velocity.y = -velocity.y
        }
        
        if zombie.position.y >= topRight.y {
            zombie.position.y = topRight.y
            velocity.y = -velocity.y
        }
    }
    
    //Rotate on tap. Zombie will rotate towards position tapped.
    func rotateSprite(_ sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
        let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: velocity.angle)
        let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
        sprite.zRotation += shortest.sign() * amountToRotate
        
    }
    
    //Touch location functions to determine the velocity of sprite.
    func touchesBegin(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        let touchLocation = touch.location(in: self)
        lastTouchLocation = touchLocation
        moveZombieToward(touchLocation)
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        let touchLocation = touch.location(in: self)
        lastTouchLocation = touchLocation
        moveZombieToward(touchLocation)
    }
    
    // Area that Zombie can move in.
    func debugDrawPlayableArea() {
        let shape = SKShapeNode()
        let path = CGMutablePath()
        path.addRect(playableRect)
        shape.path = path
        shape.strokeColor = SKColor.blue
        shape.lineWidth = 4.0
        addChild(shape)
    }
    
    
    //Setting lastUpdateTime, which is the currentTime or the time when this function ran. Also, setting dt(deltaTime), which is the lastUpdateTime - currentTime.
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        print("\(dt*1000) milliseconds since last update")
        
        //moveSprite(zombie, velocity: CGPoint(x: zombieMovePointsPerSec, y: 0))
        if let lastTouchLocation = lastTouchLocation {
            let diff = lastTouchLocation - zombie.position
            if (diff.length() <= zombieMovePointsPerSec * CGFloat (dt)) {
                zombie.position = lastTouchLocation
                velocity = CGPoint.zero
                stopZombieAnimation()
            } else {
                moveSprite(zombie, velocity: velocity)
                rotateSprite(zombie, direction: velocity, rotateRadiansPerSec: zombieRotatingRadiansPerSec)
            }
        }
        boundsCheckZombie()
        moveTrain()
        
        if lives <= 0 && !gameOver {
            gameOver = true
            print("You Lose!")
            
            let gameOverScene = GameOverScene(size: size, won: false)
            gameOverScene.scaleMode = scaleMode
            
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    override func didEvaluateActions() {
        checkCollisions()
    }
    
}

