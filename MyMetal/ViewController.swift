import UIKit
import MetalKit

class ViewController: UIViewController {
    private var renderView: WaveDanceMLView!
    private let moveSpeed: Float = 0.1 // 单次移动步长（调小更顺滑）
    private let rotateSpeed: Float = 0.5 // 单次旋转步长
    private let scrollSpeed: Float = 0.5 // 单次缩放步长
    
    // 记录按钮按下状态
    private var pressedBtnTags: Set<Int> = []
    // 持续更新的定时器（和屏幕刷新率同步）
    private var displayLink: CADisplayLink!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. 创建渲染视图
        renderView = WaveDanceMLView(frame: view.bounds)
        view.addSubview(renderView)
        renderView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            renderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            renderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            renderView.topAnchor.constraint(equalTo: view.topAnchor),
            renderView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 2. 添加控制按钮
        setupCameraButtons()
        
        // 3. 初始化持续更新的定时器
        setupDisplayLink()
    }
    
    // MARK: - 初始化屏幕刷新率定时器
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateCameraContinuously))
        displayLink.add(to: .main, forMode: .common)
        displayLink.isPaused = true // 初始暂停，有按钮按下时再启动
    }
    
    // MARK: - 持续更新相机状态（每帧调用）
    @objc private func updateCameraContinuously() {
        guard !pressedBtnTags.isEmpty else {
            displayLink.isPaused = true // 没有按钮按下时暂停
            return
        }
        
        let camera = renderView.camera
        
        // 遍历所有按下的按钮，持续更新相机
        for tag in pressedBtnTags {
            switch tag {
            case 1001: camera.processKeyboard(.forward, deltaTime: moveSpeed)
            case 1002: camera.processKeyboard(.backward, deltaTime: moveSpeed)
            case 1003: camera.processKeyboard(.left, deltaTime: moveSpeed)
            case 1004: camera.processKeyboard(.right, deltaTime: moveSpeed)
            case 1005: camera.processMouseMovement(xOffset: -rotateSpeed, yOffset: 0)
            case 1006: camera.processMouseMovement(xOffset: rotateSpeed, yOffset: 0)
            case 1007: camera.processMouseScroll(scrollSpeed)
            case 1008: camera.processMouseScroll(-scrollSpeed)
            default: break
            }
        }
        
        // 实时刷新渲染
        renderView.refreshRender()
    }
    
    // MARK: - 创建按钮（适配所有屏幕）
    private func setupCameraButtons() {
        let btnTitles = ["前进", "后退", "左移", "右移", "左转", "右转", "放大", "缩小"]
        let btnTags = [1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008]
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        // 创建按钮（添加按下/抬起事件）
        for (index, title) in btnTitles.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(title, for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.backgroundColor = .white.withAlphaComponent(0.2)
            btn.layer.cornerRadius = 8
            btn.clipsToBounds = true
            btn.tag = btnTags[index]
            
            // 按钮按下事件（touchDown）
            btn.addTarget(self, action: #selector(btnPressDown(_:)), for: .touchDown)
            // 按钮抬起事件（包含松手、离开按钮、取消）
            btn.addTarget(self, action: #selector(btnPressUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
            
            btn.widthAnchor.constraint(equalToConstant: 60).isActive = true
            btn.heightAnchor.constraint(equalToConstant: 40).isActive = true
            stack.addArrangedSubview(btn)
        }
        
        // 按钮约束：右侧+垂直居中
        NSLayoutConstraint.activate([
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        view.bringSubviewToFront(stack)
    }
    
    // MARK: - 按钮按下：记录状态+启动定时器
    @objc private func btnPressDown(_ sender: UIButton) {
        pressedBtnTags.insert(sender.tag)
        displayLink.isPaused = false // 启动持续更新
    }
    
    // MARK: - 按钮抬起：移除状态+无按钮时暂停定时器
    @objc private func btnPressUp(_ sender: UIButton) {
        pressedBtnTags.remove(sender.tag)
        if pressedBtnTags.isEmpty {
            displayLink.isPaused = true // 没有按钮按下时暂停
        }
    }
    
    // 页面销毁时释放定时器
    deinit {
        displayLink.invalidate()
    }
}
