//
//  ContentView.swift
//  LemFiAssignment
//
//  Created by Kirils Sivokozs on 17/11/2025.
//

import SwiftUI
import Combine

struct ExchangeRateResponse: Decodable {
    let result: String
    let rates: [String: Double]
}

class ContentViewModel: ObservableObject {
    
    @Published var fromCurrency = "USD"
    @Published var toCurrency = "EUR"
    @Published var amountString = "100.00"
    @Published var convertedAmount: Double?
    
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    let apiUrl = "https://open.er-api.com/v6/latest/"
    
    init() {
        fromCurrency = UserDefaults.standard.string(forKey: "fromCurrency_last") ?? "USD"
        toCurrency = UserDefaults.standard.string(forKey: "toCurrency_last") ?? "EUR"
    }
    
    func fetchConversionRate() {
        
        guard let amount = Double(amountString) else {
            return
        }
        
        isLoading = true
        
        let url = URL(string: "\(apiUrl)\(fromCurrency)")!
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            
            if error != nil {
                print("Network Error")
                self.isLoading = false
                return
            }
            
            guard let data = data else {
                self.isLoading = false
                return
            }
            
            let response = try! JSONDecoder().decode(ExchangeRateResponse.self, from: data)
            
            let rate = response.rates[self.toCurrency]!
            
            DispatchQueue.main.async {
                self.convertedAmount = amount * rate
                self.isLoading = false
                
                self.saveCurrenciesToUserDefaults()
            }
            
        }.resume()
    }
    
    func saveCurrenciesToUserDefaults() {
        UserDefaults.standard.set(fromCurrency, forKey: "fromCurrency_last")
        UserDefaults.standard.set(toCurrency, forKey: "toCurrency_last")
    }
}

struct ContentView: View {
    
    @StateObject private var viewModel = ContentViewModel()
    
    let currencies = ["USD", "EUR", "NGN", "GBP", "JPY"]
    
    var body: some View {
        NavigationView {
            Form {
                
                Section(header: Text("Convert From")) {
                    Picker("From", selection: $viewModel.fromCurrency) {
                        ForEach(currencies, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    TextField("Amount", text: $viewModel.amountString)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif  
                }
                
                Section(header: Text("Convert To")) {
                    Picker("To", selection: $viewModel.toCurrency) {
                        ForEach(currencies, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    Button("Convert") {
                        viewModel.fetchConversionRate()
                    }
                }
                
                Section(header: Text("Result")) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if let amount = viewModel.convertedAmount {
                        Text(String(format: "%.2f %@", amount, viewModel.toCurrency))
                            .font(.largeTitle)
                    } else {
                        Text("Press 'Convert'")
                    }
                }
            }
            .navigationTitle("Currency Exchange")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
