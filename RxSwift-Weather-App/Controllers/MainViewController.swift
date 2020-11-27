//
//  ViewController.swift
//  RxSwift-Weather-App
//
//  Created by AZM on 2020/11/26.
//

import UIKit
import RxSwift
import RxCocoa

class MainViewController: UIViewController {
    
    //MARK: - Properties
    
    let disposeBag = DisposeBag()
    
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
        label.font = UIFont.systemFont(ofSize: 60, weight: .light)
        label.textAlignment = .center
        label.textColor = .black
        return label
    }()
    
    let humidityLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 40, weight: .light)
        label.textAlignment = .center
        label.textColor = .black
        return label
    }()
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        subviewElements()
        subviewSearchView()
        
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
    
    //MARK: - Helpers
    
    private func displayWeather(_ weather: Weather?) {
        
        if let weather = weather {
            self.temperatureLabel.text = "\(weather.temp) ℃"
            print("Temperature: \(weather.temp)")
            self.humidityLabel.text = "\(weather.humidity) 💧"
            print("Humidity: \(weather.humidity)")
            
        } else {
            self.temperatureLabel.text = "☀︎"
            self.humidityLabel.text = "☁︎"
        }
    }
    
    private func fetchWeather(by city: String) {
        
        guard let cityEncoded = city.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
              let url = URL.urlForWeatherAPI(city: cityEncoded) else { return }
        
        let resource = Resource<WeatherResult>(url: url)
        
        let search = URLRequest.load(resource: resource)
            .observeOn(MainScheduler.instance)
            .asDriver(onErrorJustReturn: WeatherResult.empty)
        
        search.map {"\($0.main.temp)"}
            .drive(self.temperatureLabel.rx.text)
            .disposed(by: disposeBag)
        
        search.map {"\($0.main.humidity)"}
            .drive(self.humidityLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
    //MARK: - Subviews
    
    func subviewElements() {
        //temperatureLabel
        view.addSubview(temperatureLabel)
        temperatureLabel.centerY(inView: view)
        temperatureLabel.anchor(left: view.leftAnchor, right: view.rightAnchor, width: 60, height: 60)
        
        //cityNameLabel
        view.addSubview(humidityLabel)
        humidityLabel.anchor(top: temperatureLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 40, width: 60, height: 60)
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

