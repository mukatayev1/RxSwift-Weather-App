//
//  WeatherMode.swift
//  RxSwift-Weather-App
//
//  Created by AZM on 2020/11/26.
//

import UIKit
import CoreLocation

struct WeatherResult: Codable {
    let main: Weather
    let name: String
    let weather: [Condition]
    let dt: TimeInterval
    let timezone: Int
    let coord: Coordinates
}

struct Weather: Codable {
    let temp: Double
    let humidity: Double
    let feels_like: Double
}

struct Condition: Codable {
    let id: Int
    let main: String
    var conditionName: String {
        switch id {
        case 200...232:
            return "cloud.bolt"
        case 300...321:
            return "cloud.drizzle"
        case 500...531:
            return "cloud.rain"
        case 600...622:
            return "cloud.snow"
        case 701...781:
            return "cloud.fog"
        case 800:
            return "sun.max"
        case 801...804:
            return "cloud.bolt"
        default:
            return "cloud"
        }
    }
}

struct Coordinates: Codable {
    let lat: CLLocationDegrees
    let lon: CLLocationDegrees
}
