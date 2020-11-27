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
            self.getImage(string: result.weather[0].conditionName)
        }
        .drive(self.conditionImageView.rx.image)
        .disposed(by: disposeBag)
    }
    
    func getImage(string: String) -> UIImage {
        let image = UIImage(systemName: string, withConfiguration: UIImage.SymbolConfiguration(weight: .regular))!
        return image
    }

    
    //MARK: - Subviews
    
    func subviewElements() {
        let stack = UIStackView(arrangedSubviews: [temperatureLabel, humidityLabel, feelsLikeLabel, cityNameLabel, descriptionLabel])
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

