//
//  SignInView.swift
//  UltraHFR
//

import HFRDesign
import HFRKit
import SwiftUI

/// Signing in to HFR. The password goes to HFR only and is not kept.
struct SignInView: View {
    @Environment(AccountStore.self) private var accounts
    @Environment(\.dismiss) private var dismiss
    @State private var pseudo: String
    @State private var password = ""
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    /// `pseudo`: prefilled when signing in again after the session expired.
    init(pseudo: String = "") {
        _pseudo = State(initialValue: pseudo)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Pseudo", text: $pseudo)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Mot de passe", text: $password)
                        .textContentType(.password)
                        .onSubmit(signIn)
                } footer: {
                    Text("Ton mot de passe n'est envoyé qu'à forum.hardware.fr et n'est pas enregistré : l'app garde seulement la session HFR, dans le trousseau de l'appareil.")
                }
                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
                Section {
                    Link("Créer un compte sur HFR", destination: URL(string: "https://forum.hardware.fr/inscription.php?config=hfr.inc")!)
                    Link("Mot de passe oublié", destination: URL(string: "https://forum.hardware.fr/password.php?config=hfr.inc")!)
                }
            }
            .navigationTitle("Connexion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Se connecter", action: signIn)
                        .disabled(pseudo.isEmpty || password.isEmpty || isSigningIn)
                }
            }
            .disabled(isSigningIn)
            .overlay {
                if isSigningIn {
                    ProgressView("Connexion…")
                        .padding()
                        .background(.regularMaterial, in: .rect(cornerRadius: 16))
                }
            }
        }
    }

    private func signIn() {
        guard !pseudo.isEmpty, !password.isEmpty, !isSigningIn else { return }
        isSigningIn = true
        errorMessage = nil
        Task {
            defer { isSigningIn = false }
            do throws(HFRLoginError) {
                try await accounts.signIn(pseudo: pseudo, password: password)
                password = ""
                dismiss()
            } catch {
                errorMessage = switch error {
                case .wrongCredentials: "Pseudo ou mot de passe incorrect."
                case .network: "Impossible de joindre forum.hardware.fr."
                case .unexpectedAnswer: "HFR a répondu de façon inattendue. Réessaie dans un moment."
                }
            }
        }
    }
}
