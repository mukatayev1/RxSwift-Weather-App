//
//  URLExtensions.swift
//  RxSwift-Weather-App
//
//  Created by AZM on 2020/11/26.
//

import UIKit
import RxSwift
import RxCocoa

extension URL {
    
    static func urlForWeatherAPI(city: String) -> URL? {
        return URL(string: "http://api.openweathermap.org/data/2.5/weather?q=\(city)&appid=da2eb5002d9bdfeb660e341eafb16cba&units=metric")
    }
}
