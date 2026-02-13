// Channeled/Views/ScheduleView.swift
import SwiftUI

struct ScheduleView: View {
    var body: some View {
        NavigationStack {
            Text("Weekly EPG Grid - Coming Soon")
                .navigationTitle("Schedule")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {}) {
                            Image(systemName: "gear")
                        }
                    }
                }
        }
    }
}

#Preview {
    ScheduleView()
}
