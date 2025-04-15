//
//  extension_example.swift
//  extension-example
//
//  Created by Dimitri Dessus on 28/09/2022.
//

import ActivityKit
import WidgetKit
import SwiftUI

@main
struct Widgets: WidgetBundle {
  var body: some Widget {
    if #available(iOS 16.1, *) {
      MembershipCardApp()
    }
  }
}

// We need to redefined live activities pipe
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
  public typealias LiveDeliveryData = ContentState
  
  public struct ContentState: Codable, Hashable { }
  
  var id = UUID()
}

// Create shared default with custom group
let sharedDefault = UserDefaults(suiteName: "group.radar.liveactivities")!

// Helper extension for hex colors
extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}

@available(iOSApplicationExtension 16.1, *)
struct MembershipCardApp: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
      let memberName = sharedDefault.string(forKey: context.attributes.prefixedKey("memberName")) ?? "Member"
      let memberType = sharedDefault.string(forKey: context.attributes.prefixedKey("memberType")) ?? "PRIMARY"
      let memberNumber = sharedDefault.string(forKey: context.attributes.prefixedKey("memberNumber")) ?? "00000000"
      let membershipLevel = sharedDefault.string(forKey: context.attributes.prefixedKey("membershipLevel")) ?? "Standard"
      let geofenceDescription = sharedDefault.string(forKey: context.attributes.prefixedKey("geofenceDescription")) ?? "Not in a store"
      
      ZStack {
        LinearGradient(colors: [Color(hex: 0x000257), Color(hex: 0x000257).opacity(0.8)], startPoint: .topLeading, endPoint: .bottom)
        
        VStack(spacing: 12) {
          HStack {
            VStack(alignment: .leading) {
              Text(memberName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
              
              Text(memberType)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
              Text(membershipLevel)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                  membershipLevel == "Gold" ? Color.yellow.opacity(0.5) : 
                  membershipLevel == "Platinum" ? Color.gray.opacity(0.5) : 
                  Color.white.opacity(0.3)
                )
                .cornerRadius(12)
            }
          }
          
          Divider()
            .background(Color.white)
          
          HStack {
            Text("Member #:")
              .font(.subheadline)
              .foregroundColor(.white.opacity(0.8))
            
            Text(memberNumber)
              .font(.subheadline)
              .fontWeight(.bold)
              .foregroundColor(.white)
          }
          
          Spacer()
          
          VStack(alignment: .center, spacing: 8) {
            Text("Current Location")
              .font(.subheadline)
              .fontWeight(.medium)
              .foregroundColor(.white.opacity(0.8))
            
            Text(geofenceDescription)
              .font(.headline)
              .fontWeight(.bold)
              .foregroundColor(.white)
              .multilineTextAlignment(.center)
          }
          
          Spacer()
          
          Link(destination: URL(string: "la://my.app/membership")!) {
            Text("View Full Details")
              .font(.subheadline)
              .foregroundColor(.white)
              .padding(.horizontal, 16)
              .padding(.vertical, 8)
              .background(Color.white.opacity(0.2))
              .cornerRadius(8)
          }
        }
        .padding()
      }
      .frame(height: 180)
    } dynamicIsland: { context in
      let memberName = sharedDefault.string(forKey: context.attributes.prefixedKey("memberName")) ?? "Member"
      let memberType = sharedDefault.string(forKey: context.attributes.prefixedKey("memberType")) ?? "PRIMARY"
      let memberNumber = sharedDefault.string(forKey: context.attributes.prefixedKey("memberNumber")) ?? "00000000"
      let membershipLevel = sharedDefault.string(forKey: context.attributes.prefixedKey("membershipLevel")) ?? "Standard"
      let geofenceDescription = sharedDefault.string(forKey: context.attributes.prefixedKey("geofenceDescription")) ?? "Not in a store"
      
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          VStack(alignment: .leading, spacing: 4) {
            Text(memberName)
              .font(.headline)
              .fontWeight(.bold)
              .foregroundColor(.white)
            
            Text(memberType)
              .font(.caption)
              .foregroundColor(.white.opacity(0.8))
          }
          .padding(.leading, 4)
        }
        
        DynamicIslandExpandedRegion(.trailing) {
          Text(membershipLevel)
            .font(.system(size: 14))
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
              membershipLevel == "Gold" ? Color.yellow.opacity(0.5) : 
              membershipLevel == "Platinum" ? Color.gray.opacity(0.5) : 
              Color.white.opacity(0.3)
            )
            .cornerRadius(8)
        }
        
        DynamicIslandExpandedRegion(.center) {
          VStack(spacing: 8) {
            Text("Current Location")
              .font(.caption)
              .foregroundColor(.white.opacity(0.8))
            
            Text(geofenceDescription)
              .font(.caption2)
              .fontWeight(.bold)
              .foregroundColor(.white)
              .multilineTextAlignment(.center)
              .frame(maxWidth: .infinity)
          }
        }
        
        DynamicIslandExpandedRegion(.bottom) {
          Link(destination: URL(string: "la://my.app/membership")!) {
            Text("View Full Details")
              .font(.caption)
              .foregroundColor(.white)
              .padding(.horizontal, 12)
              .padding(.vertical, 4)
              .background(Color.white.opacity(0.2))
              .cornerRadius(6)
          }
          .padding(.top, 4)
        }
      } compactLeading: {
        Text(membershipLevel)
          .font(.system(size: 12))
          .fontWeight(.bold)
          .foregroundColor(
            membershipLevel == "Gold" ? .yellow : 
            membershipLevel == "Platinum" ? .gray : 
            .white
          )
      } compactTrailing: {
        Image(systemName: "mappin.circle.fill")
          .foregroundColor(.white)
          .padding(4)
      } minimal: {
        Image(systemName: "person.crop.circle.fill")
          .foregroundColor(.white)
      }
    }
  }
}

extension LiveActivitiesAppAttributes {
  func prefixedKey(_ key: String) -> String {
    return "\(id)_\(key)"
  }
}