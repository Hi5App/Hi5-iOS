//
//  MetalViewController.swift
//  metalLearning
//
//  Created by 李凯翔 on 2022/3/9.
//

import UIKit
import Metal

protocol MetalViewControllerDelegate : AnyObject{
  func updateLogic(timeSinceLastUpdate: CFTimeInterval)
  func renderObjects(drawable: CAMetalDrawable)
}

class MetalViewController: UIViewController {

      var device: MTLDevice!
      var metalLayer: CAMetalLayer!
      var metalview: UIView!
      var pipelineState: MTLRenderPipelineState!
      var commandQueue: MTLCommandQueue!
      var timer: CADisplayLink!
      var projectionMatrix: Matrix4!
      var lastFrameTimestamp: CFTimeInterval = 0.0
      
      weak var metalViewControllerDelegate: MetalViewControllerDelegate?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
      device = MTLCreateSystemDefaultDevice()
    
      projectionMatrix = Matrix4.makePerspectiveView(angle:85, aspectRatio: Float(self.view.bounds.size.width / self.view.bounds.size.height), nearZ: 0.01, farZ: 100.0)
    
      metalLayer = CAMetalLayer()          // 1
      metalLayer.device = device           // 2
      metalLayer.pixelFormat = .bgra8Unorm // 3
      metalLayer.framebufferOnly = true    // 4
      metalLayer.frame = view.layer.frame  // 5
      metalview = UIView() // move the metal logic to a subview
      metalview.layer.addSublayer(metalLayer)
      view.addSubview(metalview)
//        view.layer.addSublayer(metalLayer)   // 6
    
    // 1
    let defaultLibrary = device.makeDefaultLibrary()!
    let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")
    let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
    
    // 2
    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.vertexFunction = vertexProgram
    pipelineStateDescriptor.fragmentFunction = fragmentProgram
      pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm //control the output type
    
    // 3
    pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    
    commandQueue = device.makeCommandQueue()
    
    timer = CADisplayLink(target: self, selector: #selector(MetalViewController.newFrame(displayLink:)))
    timer.add(to: RunLoop.main, forMode:.default)
  }
  
  func render() {
    guard let drawable = metalLayer?.nextDrawable() else { return }
    self.metalViewControllerDelegate?.renderObjects(drawable: drawable)
  }
  
  // 1
  @objc func newFrame(displayLink: CADisplayLink){
    
    if lastFrameTimestamp == 0.0
    {
      lastFrameTimestamp = displayLink.timestamp
    }
    
    // 2
    let elapsed: CFTimeInterval = displayLink.timestamp - lastFrameTimestamp
    lastFrameTimestamp = displayLink.timestamp
    
    // 3
    gameloop(timeSinceLastUpdate: elapsed)
  }
  
  func gameloop(timeSinceLastUpdate: CFTimeInterval) {
    
    // 4
    self.metalViewControllerDelegate?.updateLogic(timeSinceLastUpdate: timeSinceLastUpdate)
    
    // 5
    autoreleasepool {
      self.render()
    }
  }

}
