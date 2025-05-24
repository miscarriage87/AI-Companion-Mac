
//
//  ContextManager.swift
//  AI Companion
//
//  Created: May 20, 2025
//

import Foundation
import Combine
import CoreLocation
import EventKit

/// ContextManager detects and manages the user's current context
/// It provides information about the user's location, activity, time, and system state
/// to enable context-aware AI responses and proactive suggestions
class ContextManager: NSObject {
    // MARK: - Properties
    
    // Location manager
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    private var currentPlacemark: CLPlacemark?
    
    // Activity recognition
    private var currentActivity: UserActivity = .unknown
    
    // Calendar integration
    private let eventStore = EKEventStore()
    private var calendarAccessGranted = false
    
    // System state monitoring
    private var isConnectedToWifi = false
    private var batteryLevel: Float = 1.0
    private var isBatteryCharging = false
    
    // Publishers
    private let locationUpdateSubject = PassthroughSubject<UserLocation, Never>()
    private let activityUpdateSubject = PassthroughSubject<UserActivity, Never>()
    private let contextUpdateSubject = PassthroughSubject<ContextUpdate, Never>()
    
    var locationUpdates: AnyPublisher<UserLocation, Never> {
        return locationUpdateSubject.eraseToAnyPublisher()
    }
    
    var activityUpdates: AnyPublisher<UserActivity, Never> {
        return activityUpdateSubject.eraseToAnyPublisher()
    }
    
    var contextUpdates: AnyPublisher<ContextUpdate, Never> {
        return contextUpdateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupLocationManager()
        requestCalendarAccess()
        setupSystemMonitoring()
        startActivityRecognition()
    }
    
    // MARK: - Setup
    
    /// Set up the location manager
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    /// Request access to the user's calendar
    private func requestCalendarAccess() {
        Task {
            do {
                if #available(macOS 14.0, *) {
                    let accessGranted = try await eventStore.requestFullAccessToEvents()
                    self.calendarAccessGranted = accessGranted
                } else {
                    // For older macOS versions
                    eventStore.requestAccess(to: .event) { [weak self] granted, error in
                        DispatchQueue.main.async {
                            self?.calendarAccessGranted = granted
                            if let error = error {
                                print("Calendar access error: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            } catch {
                print("Failed to request calendar access: \(error.localizedDescription)")
            }
        }
    }
    
    /// Set up system state monitoring
    private func setupSystemMonitoring() {
        // Monitor network connectivity
        monitorNetworkConnectivity()
        
        // Monitor battery status
        monitorBatteryStatus()
        
        // Start periodic context updates
        startPeriodicContextUpdates()
    }
    
    /// Start activity recognition
    private func startActivityRecognition() {
        // In a real implementation, this would use motion sensors and ML
        // For now, we'll simulate activity recognition with a timer
        simulateActivityRecognition()
    }
    
    // MARK: - Context Monitoring
    
    /// Monitor network connectivity
    private func monitorNetworkConnectivity() {
        // In a real implementation, this would use NWPathMonitor
        // For now, we'll assume WiFi is available
        isConnectedToWifi = true
    }
    
    /// Monitor battery status
    private func monitorBatteryStatus() {
        // In a real implementation, this would use IOKit
        // For now, we'll set default values
        batteryLevel = 0.8
        isBatteryCharging = true
    }
    
    /// Start periodic context updates
    private func startPeriodicContextUpdates() {
        // Update context every minute
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateContext()
        }
    }
    
    /// Simulate activity recognition
    private func simulateActivityRecognition() {
        // In a real implementation, this would use CoreMotion and ML
        // For now, we'll simulate activities based on time of day
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let hour = Calendar.current.component(.hour, from: Date())
            let weekday = Calendar.current.component(.weekday, from: Date())
            
            // Simulate different activities based on time
            if weekday >= 2 && weekday <= 6 {
                // Weekday
                if hour >= 9 && hour < 12 {
                    self.updateActivity(.working)
                } else if hour >= 12 && hour < 13 {
                    self.updateActivity(.eating)
                } else if hour >= 13 && hour < 17 {
                    self.updateActivity(.working)
                } else if hour >= 17 && hour < 19 {
                    self.updateActivity(.commuting)
                } else if hour >= 19 && hour < 22 {
                    self.updateActivity(.relaxing)
                } else {
                    self.updateActivity(.sleeping)
                }
            } else {
                // Weekend
                if hour >= 9 && hour < 11 {
                    self.updateActivity(.relaxing)
                } else if hour >= 11 && hour < 14 {
                    self.updateActivity(.exercising)
                } else if hour >= 14 && hour < 18 {
                    self.updateActivity(.socializing)
                } else if hour >= 18 && hour < 23 {
                    self.updateActivity(.relaxing)
                } else {
                    self.updateActivity(.sleeping)
                }
            }
        }
    }
    
    /// Update the current activity
    /// - Parameter activity: The new activity
    private func updateActivity(_ activity: UserActivity) {
        if currentActivity != activity {
            currentActivity = activity
            activityUpdateSubject.send(activity)
            
            // Also send a context update
            updateContext()
        }
    }
    
    /// Update the overall context
    private func updateContext() {
        let userLocation = determineUserLocation()
        let timeContext = determineTimeContext()
        let calendarContext = fetchCalendarContext()
        
        let contextUpdate = ContextUpdate(
            timestamp: Date(),
            location: userLocation,
            activity: currentActivity,
            timeContext: timeContext,
            calendarContext: calendarContext,
            systemContext: SystemContext(
                isConnectedToWifi: isConnectedToWifi,
                batteryLevel: batteryLevel,
                isBatteryCharging: isBatteryCharging
            )
        )
        
        contextUpdateSubject.send(contextUpdate)
    }
    
    // MARK: - Context Determination
    
    /// Determine the user's location type
    /// - Returns: The user's location type
    private func determineUserLocation() -> UserLocation {
        guard let placemark = currentPlacemark else {
            return .unknown
        }
        
        // Check for home location
        if isHomeLocation(placemark) {
            return .home
        }
        
        // Check for work location
        if isWorkLocation(placemark) {
            return .work
        }
        
        // Check for other known locations
        if let areasOfInterest = placemark.areasOfInterest, !areasOfInterest.isEmpty {
            // Check for common location types
            for area in areasOfInterest {
                if area.lowercased().contains("restaurant") || area.lowercased().contains("café") {
                    return .restaurant
                }
                if area.lowercased().contains("gym") || area.lowercased().contains("fitness") {
                    return .gym
                }
                if area.lowercased().contains("store") || area.lowercased().contains("mall") || area.lowercased().contains("shop") {
                    return .store
                }
                if area.lowercased().contains("park") || area.lowercased().contains("garden") {
                    return .outdoors
                }
            }
        }
        
        // Check location type based on placemark data
        if placemark.thoroughfare != nil && placemark.subThoroughfare != nil {
            // Has street address, likely a building
            return .building
        }
        
        return .unknown
    }
    
    /// Check if the placemark is the user's home location
    /// - Parameter placemark: The placemark to check
    /// - Returns: Whether this is the home location
    private func isHomeLocation(_ placemark: CLPlacemark) -> Bool {
        // In a real implementation, this would compare with a stored home address
        // For now, we'll return false
        return false
    }
    
    /// Check if the placemark is the user's work location
    /// - Parameter placemark: The placemark to check
    /// - Returns: Whether this is the work location
    private func isWorkLocation(_ placemark: CLPlacemark) -> Bool {
        // In a real implementation, this would compare with a stored work address
        // For now, we'll return false
        return false
    }
    
    /// Determine the current time context
    /// - Returns: The time context
    private func determineTimeContext() -> TimeContext {
        let date = Date()
        let calendar = Calendar.current
        
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let weekday = calendar.component(.weekday, from: date)
        
        // Determine time of day
        let timeOfDay: TimeOfDay
        if hour >= 5 && hour < 12 {
            timeOfDay = .morning
        } else if hour >= 12 && hour < 17 {
            timeOfDay = .afternoon
        } else if hour >= 17 && hour < 21 {
            timeOfDay = .evening
        } else {
            timeOfDay = .night
        }
        
        // Determine day type
        let dayType: DayType
        if weekday == 1 || weekday == 7 {
            dayType = .weekend
        } else {
            dayType = .weekday
        }
        
        // Check for special dates
        let isHoliday = checkIfHoliday(date)
        
        return TimeContext(
            date: date,
            timeOfDay: timeOfDay,
            dayType: dayType,
            isHoliday: isHoliday
        )
    }
    
    /// Check if a date is a holiday
    /// - Parameter date: The date to check
    /// - Returns: Whether the date is a holiday
    private func checkIfHoliday(_ date: Date) -> Bool {
        // In a real implementation, this would check against a holiday calendar
        // For now, we'll return false
        return false
    }
    
    /// Fetch the user's calendar context
    /// - Returns: The calendar context
    private func fetchCalendarContext() -> CalendarContext {
        guard calendarAccessGranted else {
            return CalendarContext(
                hasUpcomingMeeting: false,
                nextMeetingTitle: nil,
                nextMeetingTime: nil,
                isBusyDay: false
            )
        }
        
        let now = Date()
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
        
        // Get events for today
        let predicate = eventStore.predicateForEvents(withStart: now, end: endOfDay, calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        // Check for upcoming meetings
        let upcomingEvents = events.filter { $0.startDate > now }
        let hasUpcomingMeeting = !upcomingEvents.isEmpty
        
        // Get next meeting details
        let nextMeeting = upcomingEvents.min { $0.startDate < $1.startDate }
        
        // Check if today is busy
        let isBusyDay = events.count > 3
        
        return CalendarContext(
            hasUpcomingMeeting: hasUpcomingMeeting,
            nextMeetingTitle: nextMeeting?.title,
            nextMeetingTime: nextMeeting?.startDate,
            isBusyDay: isBusyDay
        )
    }
    
    // MARK: - Public Methods
    
    /// Get the user's current location type
    /// - Returns: The current location type
    func getCurrentLocation() -> UserLocation {
        return determineUserLocation()
    }
    
    /// Get the user's current activity
    /// - Returns: The current activity
    func getCurrentActivity() -> UserActivity {
        return currentActivity
    }
    
    /// Get the current time context
    /// - Returns: The time context
    func getCurrentTimeContext() -> TimeContext {
        return determineTimeContext()
    }
    
    /// Get the current calendar context
    /// - Returns: The calendar context
    func getCurrentCalendarContext() -> CalendarContext {
        return fetchCalendarContext()
    }
    
    /// Get the complete current context
    /// - Returns: The current context
    func getCurrentContext() -> ContextUpdate {
        let userLocation = determineUserLocation()
        let timeContext = determineTimeContext()
        let calendarContext = fetchCalendarContext()
        
        return ContextUpdate(
            timestamp: Date(),
            location: userLocation,
            activity: currentActivity,
            timeContext: timeContext,
            calendarContext: calendarContext,
            systemContext: SystemContext(
                isConnectedToWifi: isConnectedToWifi,
                batteryLevel: batteryLevel,
                isBatteryCharging: isBatteryCharging
            )
        )
    }
    
    /// Generate proactive suggestions based on current context
    /// - Returns: Array of suggestions
    func generateProactiveSuggestions() -> [ProactiveSuggestion] {
        var suggestions: [ProactiveSuggestion] = []
        
        let context = getCurrentContext()
        
        // Location-based suggestions
        switch context.location {
        case .home:
            if context.timeContext.timeOfDay == .morning {
                suggestions.append(ProactiveSuggestion(
                    title: "Morning Routine",
                    description: "Would you like to start your morning routine?",
                    type: .routine,
                    priority: .medium
                ))
            }
            
            if context.timeContext.timeOfDay == .evening {
                suggestions.append(ProactiveSuggestion(
                    title: "Evening Summary",
                    description: "Review your day and plan for tomorrow",
                    type: .summary,
                    priority: .medium
                ))
            }
            
        case .work:
            if context.timeContext.timeOfDay == .morning {
                suggestions.append(ProactiveSuggestion(
                    title: "Work Day Planning",
                    description: "Review your tasks and meetings for today",
                    type: .planning,
                    priority: .high
                ))
            }
            
            if context.calendarContext.hasUpcomingMeeting {
                suggestions.append(ProactiveSuggestion(
                    title: "Meeting Preparation",
                    description: "Prepare for your upcoming meeting: \(context.calendarContext.nextMeetingTitle ?? "Untitled")",
                    type: .meeting,
                    priority: .high
                ))
            }
            
        case .commuting:
            suggestions.append(ProactiveSuggestion(
                title: "Traffic Update",
                description: "Check current traffic conditions",
                type: .information,
                priority: .medium
            ))
            
            suggestions.append(ProactiveSuggestion(
                title: "Listen to News",
                description: "Catch up on the latest news during your commute",
                type: .content,
                priority: .low
            ))
            
        case .restaurant:
            suggestions.append(ProactiveSuggestion(
                title: "Meal Tracking",
                description: "Would you like to log your meal?",
                type: .health,
                priority: .low
            ))
            
        case .gym:
            suggestions.append(ProactiveSuggestion(
                title: "Workout Tracking",
                description: "Start tracking your workout",
                type: .health,
                priority: .medium
            ))
            
        default:
            break
        }
        
        // Activity-based suggestions
        switch context.activity {
        case .working:
            suggestions.append(ProactiveSuggestion(
                title: "Focus Mode",
                description: "Enable focus mode to minimize distractions",
                type: .productivity,
                priority: .medium
            ))
            
        case .relaxing:
            suggestions.append(ProactiveSuggestion(
                title: "Relaxation Content",
                description: "Would you like some relaxing music or meditation?",
                type: .content,
                priority: .low
            ))
            
        case .exercising:
            suggestions.append(ProactiveSuggestion(
                title: "Workout Playlist",
                description: "Play your workout playlist",
                type: .content,
                priority: .medium
            ))
            
        case .sleeping:
            // Don't disturb during sleep
            break
            
        default:
            break
        }
        
        // Time-based suggestions
        if context.timeContext.timeOfDay == .morning {
            suggestions.append(ProactiveSuggestion(
                title: "Weather Forecast",
                description: "Check today's weather forecast",
                type: .information,
                priority: .medium
            ))
        }
        
        if context.timeContext.timeOfDay == .evening {
            suggestions.append(ProactiveSuggestion(
                title: "Tomorrow's Schedule",
                description: "Review your schedule for tomorrow",
                type: .planning,
                priority: .medium
            ))
        }
        
        // System-based suggestions
        if context.systemContext.batteryLevel < 0.2 && !context.systemContext.isBatteryCharging {
            suggestions.append(ProactiveSuggestion(
                title: "Low Battery",
                description: "Your battery is low. Consider connecting to power.",
                type: .system,
                priority: .high
            ))
        }
        
        // Sort by priority
        return suggestions.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
}

// MARK: - CLLocationManagerDelegate

extension ContextManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Update current location
        currentLocation = location
        
        // Reverse geocode to get placemark
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self, let placemark = placemarks?.first else { return }
            
            // Update current placemark
            self.currentPlacemark = placemark
            
            // Determine user location type
            let userLocation = self.determineUserLocation()
            
            // Notify subscribers
            self.locationUpdateSubject.send(userLocation)
            
            // Update overall context
            self.updateContext()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
}

// MARK: - Supporting Types

/// Types of user locations
enum UserLocation {
    case home
    case work
    case commuting
    case restaurant
    case store
    case gym
    case outdoors
    case building
    case unknown
}

/// Types of user activities
enum UserActivity {
    case working
    case relaxing
    case commuting
    case exercising
    case eating
    case socializing
    case meeting
    case sleeping
    case unknown
}

/// Times of day
enum TimeOfDay {
    case morning
    case afternoon
    case evening
    case night
}

/// Day types
enum DayType {
    case weekday
    case weekend
}

/// Time context information
struct TimeContext {
    let date: Date
    let timeOfDay: TimeOfDay
    let dayType: DayType
    let isHoliday: Bool
}

/// Calendar context information
struct CalendarContext {
    let hasUpcomingMeeting: Bool
    let nextMeetingTitle: String?
    let nextMeetingTime: Date?
    let isBusyDay: Bool
}

/// System context information
struct SystemContext {
    let isConnectedToWifi: Bool
    let batteryLevel: Float
    let isBatteryCharging: Bool
}

/// Complete context update
struct ContextUpdate {
    let timestamp: Date
    let location: UserLocation
    let activity: UserActivity
    let timeContext: TimeContext
    let calendarContext: CalendarContext
    let systemContext: SystemContext
}

/// Types of proactive suggestions
enum ProactiveSuggestionType {
    case routine
    case planning
    case meeting
    case information
    case content
    case productivity
    case health
    case summary
    case system
}

/// Suggestion priority levels
enum SuggestionPriority: Int {
    case low = 1
    case medium = 2
    case high = 3
}

/// Proactive suggestion
struct ProactiveSuggestion {
    let title: String
    let description: String
    let type: ProactiveSuggestionType
    let priority: SuggestionPriority
}
