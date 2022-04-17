//
//  MetalViewController.swift
//  metalLearning
//
//  Created by 李凯翔 on 2022/3/9.
//

import UIKit
import MetalKit
import simd

protocol MetalViewControllerDelegate : AnyObject{
  func updateLogic(timeSinceLastUpdate: CFTimeInterval)
  func renderObjects(drawable: CAMetalDrawable)
}

class MetalViewController: UIViewController {

    var device: MTLDevice!
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var projectionMatrix: float4x4!
    @IBOutlet weak var mtkView:MTKView!{
        didSet{
            mtkView.delegate = self
            mtkView.preferredFramesPerSecond = 60
            mtkView.clearColor = MTLClearColor(red: 123.0/255.0, green: 133.0/255.0, blue: 199.0/255.0, alpha: 1.0)
        }
    }
      
    weak var metalViewControllerDelegate: MetalViewControllerDelegate?
  
  override func viewDidLoad() {
      super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
      device = MTLCreateSystemDefaultDevice()
    
      mtkView.device = device
      projectionMatrix = float4x4.makePerspectiveViewAngle(Float(85).radians, aspectRatio: Float(self.view.bounds.size.width / self.view.bounds.size.height), nearZ:0.01, farZ:100.0)

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
  }
  
  func render(_ drawable:CAMetalDrawable?) {
    guard let drawable = drawable else { return }
    self.metalViewControllerDelegate?.renderObjects(drawable: drawable)
  }
}

extension MetalViewController:MTKViewDelegate{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        projectionMatrix = float4x4.makePerspectiveViewAngle(Float(85).radians, aspectRatio: Float(self.view.bounds.size.width/self.view.bounds.size.height), nearZ: 0.01, farZ: 100.0)
    }
    
    func draw(in view: MTKView) {
        render(view.currentDrawable)
    }
}
