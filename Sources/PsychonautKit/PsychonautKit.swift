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
    public var name: String
    public var roas: [AdministrationRoute]
    public var addictionPotential: String?
    public var `class`: SubstanceClass?
    public var images: [ImageLink]
    public var summary: String?
    public var tolerance: ToleranceInfo?
    public var commonNames: [String]?
    public var crossTolerances: [String]?
    public var effects: [SubstanceEffect]
    public var toxicity: [String]?
}

public struct SubstanceEffect: Codable {
    public var name: String
    public var url: String
}

public struct ToleranceInfo: Codable {
    public var full: String?
    public var half: String?
    public var zero: String?
}

public struct AdministrationRoute: Codable {
    public var name: String
    public var dose: DosageInfo?
    public var duration: DurationInfo
    public var bioavailability: Bioavailability?
}

public struct SubstanceClass: Codable {
    public var chemical: [String]?
    public var psychoactive: [String]?
}

public struct ImageLink: Codable {
    public var image: String
}

public struct DosageInfo: Codable {
    public var units: String
    public var threshold: Float?
    public var heavy: Float?
    public var common: DosageAmount?
    public var light: DosageAmount?
    public var strong: DosageAmount?
}

public struct DosageAmount: Codable {
    public var min: Float
    public var max: Float
}

public struct Bioavailability: Codable {
    public var min: Float
    public var max: Float
}

public struct DurationInfo: Codable {
    public var afterglow: Duration?
    public var comeup: Duration?
    public var offset: Duration?
    public var onset: Duration?
    public var peak: Duration?
    public var total: Duration?
}

public struct Duration: Codable {
    public var min: Float?
    public var max: Float?
    public var units: String
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
