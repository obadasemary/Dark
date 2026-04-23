// Characters/Presentation/Views/CharacterRow.swift
import SwiftUI

struct CharacterRow: View {
    let character: Character

    var body: some View {
        HStack(spacing: 12) {
            characterAvatar
            characterInfo
        }
        .padding(.vertical, 4)
    }

    // MARK: - Subviews

    private var characterAvatar: some View {
        CachedAsyncImage(url: character.imageURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            ProgressView()
        } failure: {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .foregroundStyle(.secondary)
        }
        .frame(width: 64, height: 64)
        .clipShape(Circle())
        .overlay(Circle().stroke(statusColor, lineWidth: 2))
    }

    private var characterInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(character.name)
                .font(.headline)
                .lineLimit(1)
            statusLabel
            Text(character.species)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(character.location)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
    }

    private var statusLabel: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(character.status.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var statusColor: Color {
        switch character.status {
        case .alive: .green
        case .dead:  .red
        case .unknown: .gray
        }
    }
}
