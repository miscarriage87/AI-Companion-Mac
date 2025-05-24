
//
//  ARCompanion.swift
//  AI Companion
//
//  Created: May 20, 2025
//

import Foundation
import ARKit
import RealityKit
import Combine

/// ARCompanion provides augmented reality integration for the AI Companion
/// It enables spatial anchoring of conversations, 3D visualization, and gesture interactions
class ARCompanion {
    // MARK: - Properties
    
    // AR session and configuration
    private var arSession: ARSession?
    private var arView: ARView?
    
    // Spatial anchors
    private var conversationAnchors: [UUID: ConversationAnchor] = [:]
    private var visualizationAnchors: [UUID: VisualizationAnchor] = [:]
    
    // Gesture recognizers
    private var tapGestureRecognizer: UITapGestureRecognizer?
    private var panGestureRecognizer: UIPanGestureRecognizer?
    private var pinchGestureRecognizer: UIPinchGestureRecognizer?
    
    // Publishers
    private let anchorUpdateSubject = PassthroughSubject<AnchorUpdate, Never>()
    var anchorUpdates: AnyPublisher<AnchorUpdate, Never> {
        return anchorUpdateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init() {
        setupARSession()
    }
    
    // MARK: - AR Setup
    
    /// Set up the AR session and configuration
    private func setupARSession() {
        arSession = ARSession()
        
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
        // Enable environment texturing for realistic rendering
        if #available(macOS 13.0, *) {
            configuration.environmentTexturing = .automatic
        }
        
        // Start AR session
        arSession?.run(configuration)
    }
    
    /// Set up the AR view for rendering
    /// - Parameter view: The view to use for AR rendering
    func setupARView(_ view: ARView) {
        self.arView = view
        
        // Configure AR view
        view.session = arSession!
        
        // Add gesture recognizers
        setupGestureRecognizers(for: view)
    }
    
    /// Set up gesture recognizers for AR interactions
    /// - Parameter view: The view to add gesture recognizers to
    private func setupGestureRecognizers(for view: ARView) {
        // Tap gesture for selecting anchors
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
        self.tapGestureRecognizer = tapGesture
        
        // Pan gesture for moving anchors
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(panGesture)
        self.panGestureRecognizer = panGesture
        
        // Pinch gesture for scaling visualizations
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view.addGestureRecognizer(pinchGesture)
        self.pinchGestureRecognizer = pinchGesture
    }
    
    // MARK: - Gesture Handling
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let arView = arView else { return }
        
        let location = gesture.location(in: arView)
        
        // Perform hit test to find entities at tap location
        let hitTestResults = arView.hitTest(location, options: nil)
        
        if let firstResult = hitTestResults.first {
            // Check if the hit entity is a conversation anchor
            if let conversationAnchor = getConversationAnchor(for: firstResult.entity) {
                // Activate the conversation
                activateConversation(conversationAnchor)
            }
            // Check if the hit entity is a visualization anchor
            else if let visualizationAnchor = getVisualizationAnchor(for: firstResult.entity) {
                // Interact with the visualization
                interactWithVisualization(visualizationAnchor)
            }
        } else {
            // If no entity was hit, create a new anchor at the tap location
            let raycastResults = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any)
            
            if let firstResult = raycastResults.first {
                // Create a new conversation anchor at the hit location
                createConversationAnchor(at: firstResult.worldTransform)
            }
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let arView = arView else { return }
        
        // Handle pan gesture for moving anchors
        switch gesture.state {
        case .began:
            // Perform hit test to find entity to move
            let location = gesture.location(in: arView)
            let hitTestResults = arView.hitTest(location, options: nil)
            
            if let firstResult = hitTestResults.first {
                // Store the entity to move
                gesture.view?.tag = firstResult.entity.id.hashValue
            }
            
        case .changed:
            // Move the entity
            if let entityHash = gesture.view?.tag,
               let entity = findEntity(withHash: entityHash) {
                let translation = gesture.translation(in: arView)
                
                // Convert screen translation to world translation
                let worldTranslation = simd_float3(Float(translation.x) * 0.01, 0, Float(translation.y) * 0.01)
                
                // Apply translation
                entity.transform.translation += worldTranslation
                
                // Reset translation for next update
                gesture.setTranslation(.zero, in: arView)
            }
            
        case .ended, .cancelled:
            // Clear stored entity
            gesture.view?.tag = 0
            
        default:
            break
        }
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let arView = arView else { return }
        
        // Handle pinch gesture for scaling visualizations
        switch gesture.state {
        case .began:
            // Perform hit test to find entity to scale
            let location = gesture.location(in: arView)
            let hitTestResults = arView.hitTest(location, options: nil)
            
            if let firstResult = hitTestResults.first {
                // Store the entity to scale
                gesture.view?.tag = firstResult.entity.id.hashValue
            }
            
        case .changed:
            // Scale the entity
            if let entityHash = gesture.view?.tag,
               let entity = findEntity(withHash: entityHash) {
                let scale = Float(gesture.scale)
                
                // Apply scale
                entity.transform.scale *= scale
                
                // Reset scale for next update
                gesture.scale = 1.0
            }
            
        case .ended, .cancelled:
            // Clear stored entity
            gesture.view?.tag = 0
            
        default:
            break
        }
    }
    
    // MARK: - Conversation Anchoring
    
    /// Create a new conversation anchor at the specified location
    /// - Parameter transform: World transform for the anchor
    /// - Returns: The created conversation anchor
    @discardableResult
    func createConversationAnchor(at transform: simd_float4x4) -> ConversationAnchor {
        guard let arView = arView else {
            fatalError("AR view not set up")
        }
        
        // Create a unique ID for the anchor
        let anchorID = UUID()
        
        // Create an AR anchor
        let arAnchor = ARAnchor(transform: transform)
        arSession?.add(anchor: arAnchor)
        
        // Create a visual representation of the conversation anchor
        let anchorEntity = AnchorEntity(anchor: arAnchor)
        
        // Add a visual indicator for the anchor
        let sphere = ModelEntity(
            mesh: .generateSphere(radius: 0.05),
            materials: [SimpleMaterial(color: .blue, isMetallic: true)]
        )
        anchorEntity.addChild(sphere)
        
        // Add a text entity for the conversation title
        let textMesh = MeshResource.generateText(
            "New Conversation",
            extrusionDepth: 0.01,
            font: .systemFont(ofSize: 0.05),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )
        let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        textEntity.position = SIMD3<Float>(0, 0.1, 0)
        anchorEntity.addChild(textEntity)
        
        // Add the anchor entity to the scene
        arView.scene.addAnchor(anchorEntity)
        
        // Create a conversation anchor object
        let conversationAnchor = ConversationAnchor(
            id: anchorID,
            arAnchor: arAnchor,
            anchorEntity: anchorEntity,
            textEntity: textEntity,
            title: "New Conversation",
            messages: []
        )
        
        // Store the conversation anchor
        conversationAnchors[anchorID] = conversationAnchor
        
        // Notify listeners
        anchorUpdateSubject.send(AnchorUpdate(
            type: .conversationCreated,
            anchorID: anchorID,
            data: ["title": "New Conversation"]
        ))
        
        return conversationAnchor
    }
    
    /// Add a message to a conversation anchor
    /// - Parameters:
    ///   - message: The message to add
    ///   - anchorID: The ID of the conversation anchor
    func addMessageToConversation(_ message: ConversationMessage, anchorID: UUID) {
        guard let anchor = conversationAnchors[anchorID] else {
            print("Conversation anchor not found: \(anchorID)")
            return
        }
        
        // Add message to the conversation
        var updatedMessages = anchor.messages
        updatedMessages.append(message)
        
        // Update the conversation anchor
        conversationAnchors[anchorID]?.messages = updatedMessages
        
        // Update the visual representation
        updateConversationVisual(for: anchorID)
        
        // Notify listeners
        anchorUpdateSubject.send(AnchorUpdate(
            type: .conversationUpdated,
            anchorID: anchorID,
            data: ["messageCount": updatedMessages.count]
        ))
    }
    
    /// Update the visual representation of a conversation anchor
    /// - Parameter anchorID: The ID of the conversation anchor
    private func updateConversationVisual(for anchorID: UUID) {
        guard let anchor = conversationAnchors[anchorID] else { return }
        
        // Update the text entity with the conversation title
        let textMesh = MeshResource.generateText(
            anchor.title,
            extrusionDepth: 0.01,
            font: .systemFont(ofSize: 0.05),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )
        anchor.textEntity.model?.mesh = textMesh
        
        // Update the sphere color based on message count
        let messageCount = anchor.messages.count
        let sphereColor: UIColor
        
        if messageCount == 0 {
            sphereColor = .blue
        } else if messageCount < 5 {
            sphereColor = .green
        } else if messageCount < 10 {
            sphereColor = .orange
        } else {
            sphereColor = .red
        }
        
        // Find the sphere entity and update its material
        if let sphereEntity = anchor.anchorEntity.children.first as? ModelEntity {
            sphereEntity.model?.materials = [SimpleMaterial(color: sphereColor, isMetallic: true)]
        }
    }
    
    /// Activate a conversation anchor to view its messages
    /// - Parameter anchor: The conversation anchor to activate
    private func activateConversation(_ anchor: ConversationAnchor) {
        // Notify listeners that a conversation was activated
        anchorUpdateSubject.send(AnchorUpdate(
            type: .conversationActivated,
            anchorID: anchor.id,
            data: [
                "title": anchor.title,
                "messages": anchor.messages.map { [
                    "text": $0.text,
                    "isUser": $0.isUser,
                    "timestamp": $0.timestamp
                ] }
            ]
        ))
    }
    
    // MARK: - 3D Visualization
    
    /// Create a 3D visualization anchor for complex AI concepts
    /// - Parameters:
    ///   - transform: World transform for the anchor
    ///   - visualizationType: Type of visualization to create
    ///   - data: Data for the visualization
    /// - Returns: The created visualization anchor
    @discardableResult
    func createVisualization(at transform: simd_float4x4, type visualizationType: VisualizationType, data: [String: Any]) -> VisualizationAnchor {
        guard let arView = arView else {
            fatalError("AR view not set up")
        }
        
        // Create a unique ID for the anchor
        let anchorID = UUID()
        
        // Create an AR anchor
        let arAnchor = ARAnchor(transform: transform)
        arSession?.add(anchor: arAnchor)
        
        // Create an anchor entity
        let anchorEntity = AnchorEntity(anchor: arAnchor)
        
        // Create visualization based on type
        let visualizationEntity: Entity
        
        switch visualizationType {
        case .barChart:
            visualizationEntity = createBarChartVisualization(data: data)
        case .network:
            visualizationEntity = createNetworkVisualization(data: data)
        case .timeline:
            visualizationEntity = createTimelineVisualization(data: data)
        case .model3D:
            visualizationEntity = createModel3DVisualization(data: data)
        }
        
        // Add the visualization to the anchor
        anchorEntity.addChild(visualizationEntity)
        
        // Add a text label
        let title = data["title"] as? String ?? "Visualization"
        let textMesh = MeshResource.generateText(
            title,
            extrusionDepth: 0.01,
            font: .systemFont(ofSize: 0.05),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )
        let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        textEntity.position = SIMD3<Float>(0, 0.2, 0)
        anchorEntity.addChild(textEntity)
        
        // Add the anchor entity to the scene
        arView.scene.addAnchor(anchorEntity)
        
        // Create a visualization anchor object
        let visualizationAnchor = VisualizationAnchor(
            id: anchorID,
            arAnchor: arAnchor,
            anchorEntity: anchorEntity,
            visualizationEntity: visualizationEntity,
            textEntity: textEntity,
            type: visualizationType,
            data: data
        )
        
        // Store the visualization anchor
        visualizationAnchors[anchorID] = visualizationAnchor
        
        // Notify listeners
        anchorUpdateSubject.send(AnchorUpdate(
            type: .visualizationCreated,
            anchorID: anchorID,
            data: ["type": visualizationType.rawValue, "title": title]
        ))
        
        return visualizationAnchor
    }
    
    /// Create a 3D bar chart visualization
    /// - Parameter data: Data for the visualization
    /// - Returns: Entity containing the bar chart
    private func createBarChartVisualization(data: [String: Any]) -> Entity {
        let rootEntity = Entity()
        
        // Extract data for the bar chart
        guard let values = data["values"] as? [Double],
              let labels = data["labels"] as? [String] else {
            return rootEntity
        }
        
        // Create base for the chart
        let baseMesh = MeshResource.generateBox(size: [0.5, 0.01, 0.5])
        let baseMaterial = SimpleMaterial(color: .gray, isMetallic: false)
        let baseEntity = ModelEntity(mesh: baseMesh, materials: [baseMaterial])
        baseEntity.position = [0, 0, 0]
        rootEntity.addChild(baseEntity)
        
        // Create bars
        let maxValue = values.max() ?? 1.0
        let barWidth: Float = 0.5 / Float(values.count)
        let spacing: Float = barWidth * 0.2
        let effectiveWidth = barWidth - spacing
        
        for (index, value) in values.enumerated() {
            let normalizedValue = Float(value / maxValue)
            let barHeight = max(normalizedValue * 0.3, 0.02) // Min height for visibility
            
            // Create bar mesh
            let barMesh = MeshResource.generateBox(size: [effectiveWidth, barHeight, effectiveWidth])
            
            // Create bar material with unique color
            let hue = Float(index) / Float(values.count)
            let barColor = UIColor(hue: CGFloat(hue), saturation: 0.8, brightness: 0.8, alpha: 1.0)
            let barMaterial = SimpleMaterial(color: barColor, isMetallic: true)
            
            // Create bar entity
            let barEntity = ModelEntity(mesh: barMesh, materials: [barMaterial])
            
            // Position the bar
            let xPos = -0.25 + Float(index) * barWidth + barWidth / 2
            let yPos = barHeight / 2 + 0.01 // Half height + base offset
            barEntity.position = [xPos, yPos, 0]
            
            // Add bar to root
            rootEntity.addChild(barEntity)
            
            // Add label if space permits
            if values.count <= 5 {
                let label = labels[index]
                let labelMesh = MeshResource.generateText(
                    label,
                    extrusionDepth: 0.001,
                    font: .systemFont(ofSize: 0.02),
                    containerFrame: .zero,
                    alignment: .center,
                    lineBreakMode: .byTruncatingTail
                )
                let labelMaterial = SimpleMaterial(color: .white, isMetallic: false)
                let labelEntity = ModelEntity(mesh: labelMesh, materials: [labelMaterial])
                
                // Position label below bar
                labelEntity.position = [xPos, -0.02, 0]
                // Rotate to face up
                labelEntity.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
                
                rootEntity.addChild(labelEntity)
            }
        }
        
        return rootEntity
    }
    
    /// Create a 3D network visualization
    /// - Parameter data: Data for the visualization
    /// - Returns: Entity containing the network
    private func createNetworkVisualization(data: [String: Any]) -> Entity {
        let rootEntity = Entity()
        
        // Extract data for the network
        guard let nodes = data["nodes"] as? [[String: Any]],
              let edges = data["edges"] as? [[Int]] else {
            return rootEntity
        }
        
        // Create nodes
        var nodeEntities: [ModelEntity] = []
        
        for (index, nodeData) in nodes.enumerated() {
            let nodeName = nodeData["name"] as? String ?? "Node \(index)"
            let nodeSize = nodeData["size"] as? Double ?? 1.0
            let nodeColor = nodeData["color"] as? UIColor ?? .blue
            
            // Create node mesh
            let nodeMesh = MeshResource.generateSphere(radius: Float(nodeSize) * 0.03)
            let nodeMaterial = SimpleMaterial(color: nodeColor, isMetallic: true)
            let nodeEntity = ModelEntity(mesh: nodeMesh, materials: [nodeMaterial])
            
            // Position node in 3D space (distribute in a sphere)
            let theta = Float.pi * 2 * Float(index) / Float(nodes.count)
            let phi = Float.pi * Float(index % 3) / 3
            let radius: Float = 0.2
            
            let x = radius * sin(phi) * cos(theta)
            let y = radius * cos(phi)
            let z = radius * sin(phi) * sin(theta)
            
            nodeEntity.position = [x, y, z]
            
            // Add node to root
            rootEntity.addChild(nodeEntity)
            nodeEntities.append(nodeEntity)
            
            // Add label for the node
            let labelMesh = MeshResource.generateText(
                nodeName,
                extrusionDepth: 0.001,
                font: .systemFont(ofSize: 0.01),
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byTruncatingTail
            )
            let labelMaterial = SimpleMaterial(color: .white, isMetallic: false)
            let labelEntity = ModelEntity(mesh: labelMesh, materials: [labelMaterial])
            
            // Position label next to node
            labelEntity.position = [x + 0.03, y + 0.03, z]
            // Orient label to face center
            labelEntity.look(at: [0, 0, 0], from: labelEntity.position, relativeTo: rootEntity)
            
            rootEntity.addChild(labelEntity)
        }
        
        // Create edges
        for edge in edges {
            guard edge.count == 2,
                  edge[0] < nodeEntities.count,
                  edge[1] < nodeEntities.count else {
                continue
            }
            
            let startNode = nodeEntities[edge[0]]
            let endNode = nodeEntities[edge[1]]
            
            // Create line between nodes
            let startPos = startNode.position
            let endPos = endNode.position
            
            // Calculate line properties
            let direction = normalize(endPos - startPos)
            let distance = length(endPos - startPos)
            let midpoint = (startPos + endPos) / 2
            
            // Create line mesh (thin box)
            let lineMesh = MeshResource.generateBox(size: [0.005, 0.005, distance])
            let lineMaterial = SimpleMaterial(color: .gray, isMetallic: false)
            let lineEntity = ModelEntity(mesh: lineMesh, materials: [lineMaterial])
            
            // Position and orient line
            lineEntity.position = midpoint
            
            // Orient line to point from start to end
            let rotationAxis = cross([0, 0, 1], direction)
            let rotationAngle = acos(dot([0, 0, 1], direction))
            
            if length(rotationAxis) > 0.001 {
                lineEntity.orientation = simd_quatf(angle: rotationAngle, axis: normalize(rotationAxis))
            }
            
            rootEntity.addChild(lineEntity)
        }
        
        return rootEntity
    }
    
    /// Create a 3D timeline visualization
    /// - Parameter data: Data for the visualization
    /// - Returns: Entity containing the timeline
    private func createTimelineVisualization(data: [String: Any]) -> Entity {
        let rootEntity = Entity()
        
        // Extract data for the timeline
        guard let events = data["events"] as? [[String: Any]] else {
            return rootEntity
        }
        
        // Create base line for timeline
        let lineMesh = MeshResource.generateBox(size: [0.5, 0.005, 0.005])
        let lineMaterial = SimpleMaterial(color: .gray, isMetallic: false)
        let lineEntity = ModelEntity(mesh: lineMesh, materials: [lineMaterial])
        lineEntity.position = [0, 0, 0]
        rootEntity.addChild(lineEntity)
        
        // Create event markers
        for (index, eventData) in events.enumerated() {
            let eventName = eventData["name"] as? String ?? "Event \(index)"
            let eventDate = eventData["date"] as? String ?? ""
            let eventColor = eventData["color"] as? UIColor ?? .blue
            
            // Create marker mesh
            let markerMesh = MeshResource.generateSphere(radius: 0.01)
            let markerMaterial = SimpleMaterial(color: eventColor, isMetallic: true)
            let markerEntity = ModelEntity(mesh: markerMesh, materials: [markerMaterial])
            
            // Position marker along timeline
            let position = -0.25 + 0.5 * (Float(index) / max(Float(events.count - 1), 1))
            markerEntity.position = [position, 0, 0]
            
            // Add marker to root
            rootEntity.addChild(markerEntity)
            
            // Add event label
            let labelText = "\(eventName)\n\(eventDate)"
            let labelMesh = MeshResource.generateText(
                labelText,
                extrusionDepth: 0.001,
                font: .systemFont(ofSize: 0.01),
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byTruncatingTail
            )
            let labelMaterial = SimpleMaterial(color: .white, isMetallic: false)
            let labelEntity = ModelEntity(mesh: labelMesh, materials: [labelMaterial])
            
            // Position label above marker
            labelEntity.position = [position, 0.03, 0]
            
            // Alternate labels above and below timeline to avoid overlap
            if index % 2 == 1 {
                labelEntity.position.y = -0.03
            }
            
            rootEntity.addChild(labelEntity)
        }
        
        return rootEntity
    }
    
    /// Create a 3D model visualization
    /// - Parameter data: Data for the visualization
    /// - Returns: Entity containing the 3D model
    private func createModel3DVisualization(data: [String: Any]) -> Entity {
        let rootEntity = Entity()
        
        // Extract model type
        let modelType = data["modelType"] as? String ?? "cube"
        
        // Create model based on type
        let modelEntity: ModelEntity
        
        switch modelType {
        case "cube":
            let mesh = MeshResource.generateBox(size: 0.1)
            let material = SimpleMaterial(color: .blue, isMetallic: true)
            modelEntity = ModelEntity(mesh: mesh, materials: [material])
            
        case "sphere":
            let mesh = MeshResource.generateSphere(radius: 0.05)
            let material = SimpleMaterial(color: .red, isMetallic: true)
            modelEntity = ModelEntity(mesh: mesh, materials: [material])
            
        case "cylinder":
            let mesh = MeshResource.generateCylinder(height: 0.1, radius: 0.05)
            let material = SimpleMaterial(color: .green, isMetallic: true)
            modelEntity = ModelEntity(mesh: mesh, materials: [material])
            
        case "torus":
            let mesh = MeshResource.generateTorus(ringRadius: 0.05, pipeRadius: 0.01)
            let material = SimpleMaterial(color: .purple, isMetallic: true)
            modelEntity = ModelEntity(mesh: mesh, materials: [material])
            
        default:
            // Default to cube
            let mesh = MeshResource.generateBox(size: 0.1)
            let material = SimpleMaterial(color: .blue, isMetallic: true)
            modelEntity = ModelEntity(mesh: mesh, materials: [material])
        }
        
        // Add model to root
        rootEntity.addChild(modelEntity)
        
        // Add animation if specified
        if let animate = data["animate"] as? Bool, animate {
            // Create rotation animation
            var rotationTransform = modelEntity.transform
            let rotationAnimation = BasicAnimation<Transform>(
                keyPath: \.transform,
                duration: 4.0,
                autoreverses: false,
                repeatCount: .infinity
            )
            
            rotationAnimation.fromValue = rotationTransform
            
            // Rotate 360 degrees around y-axis
            rotationTransform.rotation *= simd_quatf(angle: 2 * .pi, axis: [0, 1, 0])
            rotationAnimation.toValue = rotationTransform
            
            // Add animation to model
            modelEntity.addAnimation(rotationAnimation)
        }
        
        return rootEntity
    }
    
    /// Interact with a visualization anchor
    /// - Parameter anchor: The visualization anchor to interact with
    private func interactWithVisualization(_ anchor: VisualizationAnchor) {
        // Notify listeners that a visualization was activated
        anchorUpdateSubject.send(AnchorUpdate(
            type: .visualizationActivated,
            anchorID: anchor.id,
            data: [
                "type": anchor.type.rawValue,
                "data": anchor.data
            ]
        ))
        
        // Perform visualization-specific interactions
        switch anchor.type {
        case .barChart:
            // Highlight bars on activation
            highlightBarChart(anchor)
            
        case .network:
            // Highlight connections on activation
            highlightNetwork(anchor)
            
        case .timeline:
            // Animate timeline on activation
            animateTimeline(anchor)
            
        case .model3D:
            // Toggle animation on activation
            toggleModelAnimation(anchor)
        }
    }
    
    /// Highlight bars in a bar chart visualization
    /// - Parameter anchor: The visualization anchor
    private func highlightBarChart(_ anchor: VisualizationAnchor) {
        // Find bar entities
        let barEntities = anchor.visualizationEntity.children.filter { entity in
            // Bars are box-shaped entities positioned above the base
            if let modelEntity = entity as? ModelEntity,
               modelEntity.position.y > 0.01 {
                return true
            }
            return false
        }
        
        // Animate bars (scale up and down)
        for (index, entity) in barEntities.enumerated() {
            guard let modelEntity = entity as? ModelEntity else { continue }
            
            // Create scale animation
            var scaleTransform = modelEntity.transform
            let scaleAnimation = BasicAnimation<Transform>(
                keyPath: \.transform,
                duration: 0.5,
                autoreverses: true,
                repeatCount: 1
            )
            
            scaleAnimation.fromValue = scaleTransform
            
            // Scale up by 20%
            scaleTransform.scale *= 1.2
            scaleAnimation.toValue = scaleTransform
            
            // Add delay based on index for sequential effect
            scaleAnimation.delay = Double(index) * 0.1
            
            // Add animation to model
            modelEntity.addAnimation(scaleAnimation)
        }
    }
    
    /// Highlight connections in a network visualization
    /// - Parameter anchor: The visualization anchor
    private func highlightNetwork(_ anchor: VisualizationAnchor) {
        // Find node and line entities
        let nodeEntities = anchor.visualizationEntity.children.filter { entity in
            // Nodes are sphere-shaped entities
            if let modelEntity = entity as? ModelEntity,
               modelEntity.model?.mesh.contents is MeshResource.Contents.Sphere {
                return true
            }
            return false
        }
        
        let lineEntities = anchor.visualizationEntity.children.filter { entity in
            // Lines are thin box-shaped entities connecting nodes
            if let modelEntity = entity as? ModelEntity,
               modelEntity.model?.mesh.contents is MeshResource.Contents.Box,
               modelEntity.scale.x < 0.01 {
                return true
            }
            return false
        }
        
        // Animate nodes (pulse effect)
        for (index, entity) in nodeEntities.enumerated() {
            guard let modelEntity = entity as? ModelEntity else { continue }
            
            // Create scale animation
            var scaleTransform = modelEntity.transform
            let scaleAnimation = BasicAnimation<Transform>(
                keyPath: \.transform,
                duration: 0.7,
                autoreverses: true,
                repeatCount: 1
            )
            
            scaleAnimation.fromValue = scaleTransform
            
            // Scale up by 50%
            scaleTransform.scale *= 1.5
            scaleAnimation.toValue = scaleTransform
            
            // Add delay based on index for sequential effect
            scaleAnimation.delay = Double(index) * 0.1
            
            // Add animation to model
            modelEntity.addAnimation(scaleAnimation)
        }
        
        // Animate lines (highlight effect)
        for (index, entity) in lineEntities.enumerated() {
            guard let modelEntity = entity as? ModelEntity else { continue }
            
            // Create material animation
            let materialAnimation = BasicAnimation<Material>(
                keyPath: \Material.baseColor,
                duration: 0.5,
                autoreverses: true,
                repeatCount: 1
            )
            
            // Change color from gray to bright blue
            materialAnimation.fromValue = SimpleMaterial(color: .gray, isMetallic: false)
            materialAnimation.toValue = SimpleMaterial(color: .systemBlue, isMetallic: true)
            
            // Add delay based on index for sequential effect
            materialAnimation.delay = Double(index) * 0.1
            
            // Add animation to model
            if let material = modelEntity.model?.materials.first {
                modelEntity.model?.materials = [material]
                modelEntity.model?.materials[0].baseColor = .init(tint: .gray)
                modelEntity.model?.materials[0].addAnimation(materialAnimation)
            }
        }
    }
    
    /// Animate a timeline visualization
    /// - Parameter anchor: The visualization anchor
    private func animateTimeline(_ anchor: VisualizationAnchor) {
        // Find marker entities
        let markerEntities = anchor.visualizationEntity.children.filter { entity in
            // Markers are sphere-shaped entities positioned along the timeline
            if let modelEntity = entity as? ModelEntity,
               modelEntity.model?.mesh.contents is MeshResource.Contents.Sphere {
                return true
            }
            return false
        }
        
        // Animate markers (sequential highlight)
        for (index, entity) in markerEntities.enumerated() {
            guard let modelEntity = entity as? ModelEntity else { continue }
            
            // Create scale and material animation
            var scaleTransform = modelEntity.transform
            let scaleAnimation = BasicAnimation<Transform>(
                keyPath: \.transform,
                duration: 0.3,
                autoreverses: true,
                repeatCount: 1
            )
            
            scaleAnimation.fromValue = scaleTransform
            
            // Scale up by 200%
            scaleTransform.scale *= 2.0
            scaleAnimation.toValue = scaleTransform
            
            // Add delay based on index for sequential effect
            scaleAnimation.delay = Double(index) * 0.2
            
            // Add animation to model
            modelEntity.addAnimation(scaleAnimation)
            
            // Create material animation
            let materialAnimation = BasicAnimation<Material>(
                keyPath: \Material.baseColor,
                duration: 0.3,
                autoreverses: true,
                repeatCount: 1
            )
            
            // Change color to bright yellow
            materialAnimation.fromValue = modelEntity.model?.materials.first ?? SimpleMaterial(color: .blue, isMetallic: true)
            materialAnimation.toValue = SimpleMaterial(color: .yellow, isMetallic: true)
            
            // Add delay based on index for sequential effect
            materialAnimation.delay = Double(index) * 0.2
            
            // Add animation to model
            if let material = modelEntity.model?.materials.first {
                modelEntity.model?.materials = [material]
                modelEntity.model?.materials[0].addAnimation(materialAnimation)
            }
        }
    }
    
    /// Toggle animation for a 3D model visualization
    /// - Parameter anchor: The visualization anchor
    private func toggleModelAnimation(_ anchor: VisualizationAnchor) {
        // Find the model entity
        guard let modelEntity = anchor.visualizationEntity.children.first as? ModelEntity else {
            return
        }
        
        // Check if model already has animation
        if modelEntity.animationNames.isEmpty {
            // Add rotation animation
            var rotationTransform = modelEntity.transform
            let rotationAnimation = BasicAnimation<Transform>(
                keyPath: \.transform,
                duration: 4.0,
                autoreverses: false,
                repeatCount: .infinity
            )
            
            rotationAnimation.fromValue = rotationTransform
            
            // Rotate 360 degrees around y-axis
            rotationTransform.rotation *= simd_quatf(angle: 2 * .pi, axis: [0, 1, 0])
            rotationAnimation.toValue = rotationTransform
            
            // Add animation to model
            modelEntity.addAnimation(rotationAnimation)
        } else {
            // Toggle existing animations
            let isAnimating = !modelEntity.isPaused
            
            if isAnimating {
                // Pause animations
                modelEntity.pauseAllAnimations()
            } else {
                // Resume animations
                modelEntity.resumeAllAnimations()
            }
        }
    }
    
    // MARK: - Gesture-Based Interactions
    
    /// Create a gesture-based interaction zone
    /// - Parameter transform: World transform for the interaction zone
    /// - Returns: The created interaction zone
    func createGestureInteractionZone(at transform: simd_float4x4) -> UUID {
        guard let arView = arView else {
            fatalError("AR view not set up")
        }
        
        // Create a unique ID for the zone
        let zoneID = UUID()
        
        // Create an AR anchor
        let arAnchor = ARAnchor(transform: transform)
        arSession?.add(anchor: arAnchor)
        
        // Create an anchor entity
        let anchorEntity = AnchorEntity(anchor: arAnchor)
        
        // Create a visual representation of the interaction zone
        let zoneMesh = MeshResource.generateBox(size: [0.3, 0.3, 0.3])
        let zoneMaterial = SimpleMaterial(color: .clear, isMetallic: false)
        let zoneEntity = ModelEntity(mesh: zoneMesh, materials: [zoneMaterial])
        
        // Add wireframe to make zone visible
        let wireframeMesh = MeshResource.generateBox(size: [0.31, 0.31, 0.31])
        let wireframeMaterial = SimpleMaterial(color: .cyan, isMetallic: false)
        wireframeMaterial.baseColor.opacity = 0.3
        let wireframeEntity = ModelEntity(mesh: wireframeMesh, materials: [wireframeMaterial])
        wireframeEntity.model?.materials[0].faceCulling = .none
        
        anchorEntity.addChild(zoneEntity)
        anchorEntity.addChild(wireframeEntity)
        
        // Add a text label
        let textMesh = MeshResource.generateText(
            "Gesture Zone",
            extrusionDepth: 0.01,
            font: .systemFont(ofSize: 0.03),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )
        let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        textEntity.position = SIMD3<Float>(0, 0.2, 0)
        anchorEntity.addChild(textEntity)
        
        // Add the anchor entity to the scene
        arView.scene.addAnchor(anchorEntity)
        
        // Store the zone ID and entity for gesture detection
        // In a real implementation, we would track these zones and detect when
        // the user's hand enters the zone for gesture recognition
        
        // Notify listeners
        anchorUpdateSubject.send(AnchorUpdate(
            type: .gestureZoneCreated,
            anchorID: zoneID,
            data: ["position": [transform.columns.3.x, transform.columns.3.y, transform.columns.3.z]]
        ))
        
        return zoneID
    }
    
    // MARK: - Helper Methods
    
    /// Find a conversation anchor for an entity
    /// - Parameter entity: The entity to check
    /// - Returns: The conversation anchor if found
    private func getConversationAnchor(for entity: Entity) -> ConversationAnchor? {
        for anchor in conversationAnchors.values {
            if entity == anchor.anchorEntity || anchor.anchorEntity.children.contains(where: { $0 == entity }) {
                return anchor
            }
        }
        return nil
    }
    
    /// Find a visualization anchor for an entity
    /// - Parameter entity: The entity to check
    /// - Returns: The visualization anchor if found
    private func getVisualizationAnchor(for entity: Entity) -> VisualizationAnchor? {
        for anchor in visualizationAnchors.values {
            if entity == anchor.anchorEntity || anchor.anchorEntity.children.contains(where: { $0 == entity }) {
                return anchor
            }
        }
        return nil
    }
    
    /// Find an entity by its hash value
    /// - Parameter hash: The hash value of the entity
    /// - Returns: The entity if found
    private func findEntity(withHash hash: Int) -> Entity? {
        // Check conversation anchors
        for anchor in conversationAnchors.values {
            if anchor.anchorEntity.id.hashValue == hash {
                return anchor.anchorEntity
            }
            
            for child in anchor.anchorEntity.children {
                if child.id.hashValue == hash {
                    return child
                }
            }
        }
        
        // Check visualization anchors
        for anchor in visualizationAnchors.values {
            if anchor.anchorEntity.id.hashValue == hash {
                return anchor.anchorEntity
            }
            
            for child in anchor.anchorEntity.children {
                if child.id.hashValue == hash {
                    return child
                }
            }
        }
        
        return nil
    }
}

// MARK: - Supporting Types

/// Types of visualization anchors
enum VisualizationType: String {
    case barChart
    case network
    case timeline
    case model3D
}

/// Types of anchor updates
enum AnchorUpdateType {
    case conversationCreated
    case conversationUpdated
    case conversationActivated
    case visualizationCreated
    case visualizationUpdated
    case visualizationActivated
    case gestureZoneCreated
}

/// Represents an update to an anchor
struct AnchorUpdate {
    let type: AnchorUpdateType
    let anchorID: UUID
    let data: [String: Any]
}

/// Represents a conversation message
struct ConversationMessage {
    let text: String
    let isUser: Bool
    let timestamp: Date
}

/// Represents a conversation anchor in AR space
struct ConversationAnchor {
    let id: UUID
    let arAnchor: ARAnchor
    let anchorEntity: AnchorEntity
    let textEntity: ModelEntity
    var title: String
    var messages: [ConversationMessage]
}

/// Represents a visualization anchor in AR space
struct VisualizationAnchor {
    let id: UUID
    let arAnchor: ARAnchor
    let anchorEntity: AnchorEntity
    let visualizationEntity: Entity
    let textEntity: ModelEntity
    let type: VisualizationType
    let data: [String: Any]
}
