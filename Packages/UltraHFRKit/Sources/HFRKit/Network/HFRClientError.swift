//
//  HFRClientError.swift
//  HFRKit
//

/// Why a request to HFR failed.
public enum HFRClientError: Error, Sendable, Equatable {
    /// No connection, timeout, TLS… (`URLError.Code` raw value).
    case network(Int)
    /// HFR answered with an unexpected HTTP status.
    case httpStatus(Int)
    /// The page could not be read.
    case parsing(HFRParsingError)
}
