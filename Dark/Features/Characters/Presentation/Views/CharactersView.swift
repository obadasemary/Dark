// Characters/Presentation/Views/CharactersView.swift
import SwiftUI

struct CharactersView: View {
    @State private var viewModel = CharactersViewModel()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Characters")
                .task { await viewModel.loadInitialPageIfNeeded() }
        }
    }

    // MARK: - States

    @ViewBuilder
    private var content: some View {
        if viewModel.characters.isEmpty && viewModel.isLoading {
            ProgressView("Loading characters…")
        } else if viewModel.characters.isEmpty, let error = viewModel.errorMessage {
            errorView(message: error)
        } else {
            characterList
        }
    }

    private var characterList: some View {
        List {
            ForEach(viewModel.characters) { character in
                CharacterRow(character: character)
                    .task {
                        // .task is cancelled automatically when the row disappears,
                        // preventing stale triggers from off-screen rows.
                        await viewModel.onItemAppear(character)
                    }
            }
            paginationFooter
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private var paginationFooter: some View {
        if viewModel.isLoading {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .listRowSeparator(.hidden)
        } else if let error = viewModel.errorMessage {
            VStack(spacing: 8) {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Retry") {
                    Task { await viewModel.retry() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .listRowSeparator(.hidden)
        } else if !viewModel.hasNextPage {
            Text("All \(viewModel.characters.count) characters loaded")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity)
                .padding()
                .listRowSeparator(.hidden)
        }
    }

    private func errorView(message: String) -> some View {
        ContentUnavailableView(
            label: {
                Label("Something went wrong", systemImage: "wifi.exclamationmark")
            },
            description: {
                Text(message)
            },
            actions: {
                Button("Retry") {
                    Task { await viewModel.retry() }
                }
                .buttonStyle(.borderedProminent)
            }
        )
    }
}

#Preview {
    CharactersView()
}
