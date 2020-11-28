//
//  ViewController.swift
//  RxSwift-Weather-App
//
//  Created by AZM on 2020/11/26.
//

import UIKit
import RxSwift
import RxCocoa
import CoreLocation

class MainViewController: UIViewController {
    
    //MARK: - Properties
    
    let disposeBag = DisposeBag()
    let locationManager = CLLocationManager()
    let backView = UIView()
    
    let searchView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 10
        return view
    }()
    
    let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "magnifyingglass", withConfiguration: UIImage.SymbolConfiguration(weight: .light))?.withTintColor(.black, renderingMode: .alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)
        return button
    }()
    
    let searchTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter the city name"
        tf.backgroundColor = .white
        tf.returnKeyType = .search
        return tf
    }()
    
    let temperatureLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 30, weight: .light)
        label.textAlignment = .left
        label.textColor = .black
        return label
    }()
    
    let humidityLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 30, weight: .light)
        label.textAlignment = .left
        label.textColor = .black
        return label
    }()
    
    let cityNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 30, weight: .light)
        label.textAlignment = .left
        label.textColor = .black
        return label
    }()
    
    let feelsLikeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 30, weight: .light)
        label.textAlignment = .left
        label.textColor = .black
        return label
    }()
    
    let conditionImageView = UIImageView()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 30, weight: .light)
        label.textAlignment = .left
        label.textColor = .black
        return label
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 30, weight: .light)
        label.textAlignment = .left
        label.textColor = .black
        return label
    }()
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientLayer(from: #colorLiteral(red: 0.2169692753, green: 0.6123354953, blue: 0.9305571089, alpha: 1), to: #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1), view: view)
        setupBackView()
        subviewElements()
        subviewSearchView()
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.requestLocation()
        
        //temporary func
        self.searchTextField.rx.controlEvent(.editingDidEndOnExit)
            .asObservable()
            .map { self.searchTextField.text }
            .subscribe(onNext: { cityName in
                
                if let cityName = cityName {
                    if cityName.isEmpty {
                        self.displayWeather(nil)
                    } else {
                        self.fetchWeather(by: cityName)
                    }
                }
            }).disposed(by: disposeBag)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: - Helpers
    
    func setupBackView() {
        view.addSubview(backView)
        backView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor)
    }
    
    private func displayWeather(_ weather: Weather?) {

        if let weather = weather {
            self.temperatureLabel.text = "\(weather.temp) ℃"
            self.humidityLabel.text = "\(weather.humidity) 💧"
            self.feelsLikeLabel.text = "\(weather.feels_like)"
        } else {
            self.temperatureLabel.text = "temp"
            self.humidityLabel.text = "humidity"
            self.feelsLikeLabel.text = "feels_like"
        }
    }
    
    private func fetchWeather(by city: String) {
        
        guard let cityEncoded = city.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
              let url = URL.urlForWeatherAPI(city: cityEncoded) else { return }
        
        let resource = Resource<WeatherResult>(url: url)
        driveResults(with: resource)
    }
    
    func driveResults(with resource: Resource<WeatherResult>) {
        
        let search = URLRequest.load(resource: resource)
            .observeOn(MainScheduler.instance)
            .asDriver(onErrorJustReturn: WeatherResult.empty)
        
        search.map {"Temperature: \(Int($0.main.temp))"}
            .drive(self.temperatureLabel.rx.text)
            .disposed(by: disposeBag)
        
        search.map {"Feels like: \(Int($0.main.feels_like))"}
            .drive(self.feelsLikeLabel.rx.text)
            .disposed(by: disposeBag)
        
        search.map {"Humidity: \(Int($0.main.humidity))"}
            .drive(self.humidityLabel.rx.text)
            .disposed(by: disposeBag)
        
        search.map {"City: \($0.name)"}
            .drive(self.cityNameLabel.rx.text)
            .disposed(by: disposeBag)
        
        search.map {"Description: \($0.weather[0].main)"}
            .drive(self.descriptionLabel.rx.text)
            .disposed(by: disposeBag)
        
        search.map { result in
            self.getDate(unixTime: result.dt, timezone: result.timezone)
        }
        .drive(self.timeLabel.rx.text)
        .disposed(by: disposeBag)
        
        search.map { result in
            self.getImage(string: result.weather[0].conditionName)
        }
        .drive(self.conditionImageView.rx.image)
        .disposed(by: disposeBag)
    }
    
    func getImage(string: String) -> UIImage {
        let image = UIImage(systemName: string, withConfiguration: UIImage.SymbolConfiguration(weight: .regular))!
        return image
    }
    
    func getDate(unixTime: TimeInterval, timezone: Int) -> String {
        let usableDate = Date(timeIntervalSince1970: unixTime)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        dateFormatter.timeZone = TimeZone(secondsFromGMT: timezone)
        let dateString = dateFormatter.string(from: usableDate)
        computeBackground(date: usableDate, timezone: timezone)
        
        return dateString
    }
    
    func computeBackground(date: Date, timezone: Int) {
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: timezone)!
        let components = calendar.dateComponents([.hour], from: date)
        let hour = components.hour!
        
        switch hour {
        case 0...4:
            setupGradientLayer(from: #colorLiteral(red: 0.1184060797, green: 0.1662106514, blue: 0.2781483531, alpha: 1), to: #colorLiteral(red: 0.2088660233, green: 0.2310087041, blue: 0.2752940655, alpha: 1), view: backView)
        case 4...6:
            setupGradientLayer(from: #colorLiteral(red: 0.2206433117, green: 0.2262730896, blue: 0.386420846, alpha: 1), to: #colorLiteral(red: 0.2640908148, green: 0.2718340007, blue: 0.3379205167, alpha: 1), view: backView)
        case 6...18:
            setupGradientLayer(from: #colorLiteral(red: 0.4208476245, green: 0.6470199227, blue: 0.7576511502, alpha: 1), to: #colorLiteral(red: 0.4279688895, green: 0.5533929467, blue: 0.620791018, alpha: 1), view: backView)
        case 18...21:
            setupGradientLayer(from: #colorLiteral(red: 0.521568656, green: 0.1098039225, blue: 0.05098039284, alpha: 1), to: #colorLiteral(red: 0.4427648783, green: 0.3130459588, blue: 0.2771662577, alpha: 1), view: backView)
        case 21...23:
            setupGradientLayer(from: #colorLiteral(red: 0.2206433117, green: 0.2262730896, blue: 0.386420846, alpha: 1), to: #colorLiteral(red: 0.2640908148, green: 0.2718340007, blue: 0.3379205167, alpha: 1), view: backView)
        default:
            setupGradientLayer(from: #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1), to: #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1), view: backView)
        }
    }
    
    func setupGradientLayer(from topColor: UIColor, to bottomColor: UIColor, view: UIView) {
        let gradient = CAGradientLayer()
        gradient.colors = [topColor.cgColor, bottomColor.cgColor]
        gradient.locations = [0, 1]
        view.layer.addSublayer(gradient)
        gradient.frame = view.frame
    }
    
    //MARK: - Subviews
    
    func subviewElements() {
        let stack = UIStackView(arrangedSubviews: [temperatureLabel, humidityLabel, feelsLikeLabel, cityNameLabel, descriptionLabel, timeLabel ])
        stack.axis = .vertical
        stack.spacing = 10
        view.addSubview(stack)
        stack.anchor(top: view.topAnchor, left: view.leftAnchor, paddingTop: 200, paddingLeft: 20)
        
        view.addSubview(conditionImageView)
        conditionImageView.setDimensions(height: 30, width: 30)
        conditionImageView.anchor(top: view.centerYAnchor, left: view.leftAnchor, paddingTop: 70, paddingLeft: 20)
        conditionImageView.image?.withTintColor(.white)
        
    }
    
    func subviewSearchView() {
        view.addSubview(searchView)
        searchView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 70, paddingLeft: 50, paddingRight: 50, height: 40)
        
        //search textfield
        view.addSubview(searchTextField)
        searchTextField.anchor(top: searchView.topAnchor, left: searchView.leftAnchor, bottom: searchView.bottomAnchor, right: searchView.rightAnchor, paddingLeft: 8, paddingRight: 45)
        
        //search button
        view.addSubview(searchButton)
        searchButton.anchor(top: searchView.topAnchor, left: searchTextField.rightAnchor, bottom: searchView.bottomAnchor, right: searchView.rightAnchor, paddingRight: 5)
    }
    
    //MARK: - Selectors
    
    @objc func searchTapped() {
        fetchWeather(by: self.searchTextField.text ?? "")
    }
}

//MARK: - CLLocationManagerDelegate

extension MainViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        if let location = locations.last {
            
            guard let latitudeString = String(location.coordinate.latitude).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
                  let longitudeString = String(location.coordinate.longitude).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
                  let url = URL.urlForWeatherAPICoordinates(lat: latitudeString, lon: longitudeString) else { return }
            
            let resource = Resource<WeatherResult>(url: url)
            driveResults(with: resource)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}
