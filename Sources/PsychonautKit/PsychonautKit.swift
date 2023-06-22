//
//  PsychonautKit.swift
//  PsychonautKit
//
//  Created by tarball on 6/20/23.
//

import Foundation

public enum PWError: Error {
    case urlParseError
    case responseError
}

public class PWAPI: ObservableObject {
    private init() {}
}

struct PWResponse1: Codable {
    var data: SubstanceResponse1
}

struct SubstanceResponse1: Codable {
    var substances: [SubstanceName]
}

struct SubstanceName: Codable {
    var name: String
}

struct PWResponse2: Codable {
    var data: SubstanceResponse2
}

struct SubstanceResponse2: Codable {
    var substances: [Substance]
}

public struct Substance: Codable {
    var name: String
    var roas: [AdministrationRoute]
    var addictionPotential: String?
    var `class`: SubstanceClass?
    var images: [ImageLink]
    var summary: String?
    var tolerance: ToleranceInfo?
    var commonNames: [String]?
    var crossTolerances: [String]?
    var effects: [SubstanceEffect]
    var toxicity: [String]?
}

public struct SubstanceEffect: Codable {
    var name: String
    var url: String
}

public struct ToleranceInfo: Codable {
    var full: String?
    var half: String?
    var zero: String?
}

public struct AdministrationRoute: Codable {
    var name: String
    var dose: DosageInfo?
    var duration: DurationInfo
    var bioavailability: Bioavailability?
}

public struct SubstanceClass: Codable {
    var chemical: [String]?
    var psychoactive: [String]?
}

public struct ImageLink: Codable {
    var image: String
}

public struct DosageInfo: Codable {
    var units: String
    var threshold: Float?
    var heavy: Float?
    var common: DosageAmount?
    var light: DosageAmount?
    var strong: DosageAmount?
}

public struct DosageAmount: Codable {
    var min: Float
    var max: Float
}

public struct Bioavailability: Codable {
    var min: Float
    var max: Float
}

public struct DurationInfo: Codable {
    var afterglow: Duration?
    var comeup: Duration?
    var offset: Duration?
    var onset: Duration?
    var peak: Duration?
    var total: Duration?
}

public struct Duration: Codable {
    var min: Float?
    var max: Float?
    var units: String
}

struct POSTData: Codable {
    var query: String
    init(_ query: String) { self.query = query }
}

public extension PWAPI {
    static func requestSubstances() async throws -> [String] {
        guard let url = URL(string: "https://api.psychonautwiki.org") else { throw PWError.urlParseError }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let query = """
        {
            substances(limit: 1000) {
                name
            }
        }
        """
        let data = POSTData(query)
        let body = try JSONEncoder().encode(data)
        request.httpBody = body
        let response = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(PWResponse1.self, from: response.0).data.substances.map { $0.name }
    }
}

public extension PWAPI {
    static func requestSubstanceInfo(query: String) async throws -> Substance {
        guard let url = URL(string: "https://api.psychonautwiki.org") else { throw PWError.urlParseError }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let query = """
        {
            substances(query: \"\(query)\") {
                name
                roas {
                    name
                    dose {
                        units
                        threshold
                        heavy
                        common { min max }
                        light { min max }
                        strong { min max }
                    }
                    duration {
                        afterglow { min max units }
                        comeup { min max units }
                        duration { min max units }
                        offset { min max units }
                        onset { min max units }
                        peak { min max units }
                        total { min max units }
                    }
                    bioavailability { min max }
                }
                toxicity
                addictionPotential
                class { chemical psychoactive }
                images { image }
                summary
                tolerance { full half zero }
                commonNames
                crossTolerances
                effects { name url }
            }
        }
        """
        let data = POSTData(query)
        let body = try JSONEncoder().encode(data)
        request.httpBody = body
        let response = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: response.0) as? [String: Any]
        #if DEBUG
        print(json as Any)
        #endif
        let substances = try JSONDecoder().decode(PWResponse2.self, from: response.0).data.substances
        guard let substance = substances.first else { throw PWError.responseError }
        return substance
    }
}
