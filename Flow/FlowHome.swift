import SwiftUI

struct ActivityItem: Identifiable, Codable {
    var id = UUID()
    let title: String
    let subtitle: String
    let amount: Int
    let symbol: String
    let isSplit: Bool

    var isLegacySample: Bool {
        switch (title, subtitle, amount, symbol, isSplit) {
        case ("Sunday brunch", "Weekend people · You paid", 184000, "cup.and.saucer", true),
             ("Aarav Shah", "Demo transfer · Yesterday", 45000, "arrow.up.right", false),
             ("Groceries", "Our place · You paid", 126000, "basket", true):
            return true
        default:
            return false
        }
    }
}

struct FlowHome: View {
    enum Tab: String, CaseIterable { case home = "Home", groups = "Groups", activity = "Activity" }
    enum Sheet: String, Identifiable { case pay, split; var id: String { rawValue } }
    @State private var tab = Tab.home
    @State private var sheet: Sheet?
    @State private var recipientName = ""
    @State private var items: [ActivityItem] = []
    @State private var storageReady = true
    @State private var notice: String?
    @AppStorage("flow.demo.activity") private var savedActivity = Data()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    switch tab {
                    case .home: home
                    case .groups: groups
                    case .activity: activity
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 26)
                .padding(.bottom, 30)
            }
            navigation
        }
        .foregroundStyle(Palette.ink)
        .background(.white)
        .buttonStyle(PressStyle())
        .sheet(item: $sheet) { destination in
            if destination == .pay {
                PaymentSheet(initialRecipient: recipientName) { item in append(item) }
            } else {
                SplitSheet { item in append(item) }
            }
        }
        .alert("Saved activity needs attention", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
            Button("OK") { notice = nil }
        } message: { Text(notice ?? "") }
        .onAppear {
            guard !savedActivity.isEmpty else { return }
            do {
                let stored = try JSONDecoder().decode([ActivityItem].self, from: savedActivity)
                let cleaned = stored.filter { !$0.isLegacySample }
                if cleaned.count != stored.count {
                    savedActivity = try JSONEncoder().encode(cleaned)
                }
                items = cleaned
                storageReady = true
            } catch {
                storageReady = false
                notice = "Your saved activity could not be read. It has been preserved. New entries cannot be saved until it is recovered."
            }
        }
    }

    var snapshot: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 24) { header; home }
                .padding(24)
            Spacer(minLength: 0)
            navigation
        }.foregroundStyle(Palette.ink).background(.white).buttonStyle(PressStyle())
    }

    private func append(_ item: ActivityItem) {
        guard storageReady else {
            notice = "Your previous activity needs recovery before new entries can be saved."
            return
        }
        let updated = [item] + items
        do {
            let data = try JSONEncoder().encode(updated)
            items = updated
            savedActivity = data
        } catch { notice = "This entry could not be saved. Please try again." }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.forward.circle.fill").font(Typeface.font(25, weight: .regular))
                Text("rello").font(Typeface.font(30, weight: .semibold)).tracking(-1.6)
            }
            Spacer()
            Text("LOCAL DEMO").font(Typeface.font(9, weight: .semibold)).tracking(1.2)
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(Palette.surface, in: Capsule())
            Avatar(initials: "You", color: Palette.lime)
        }
    }

    private var home: some View {
        Group {
            VStack(alignment: .leading, spacing: 5) {
                Text("PAY. SPLIT. ALL SQUARE.").font(Typeface.font(11, weight: .medium)).tracking(1.3).foregroundStyle(Palette.muted)
                Text("Money, together.").font(Typeface.font(35, weight: .medium)).tracking(-1.2)
            }
            balanceCard
            HStack(spacing: 12) {
                quickAction("Pay someone", icon: "arrow.up.right", color: Palette.lime) { recipientName = ""; sheet = .pay }
                quickAction("Split a bill", icon: "divide", color: Palette.lavender) { sheet = .split }
            }
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Your people", trailing: "PAY A FRIEND")
                HStack {
                    ForEach(recentRecipients, id: \.self) { name in
                        person(name, initials: String(name.prefix(2)).uppercased(), color: Palette.lavender)
                        Spacer()
                    }
                    Button { recipientName = ""; sheet = .pay } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "plus").frame(width: 44, height: 44).background(Palette.surface, in: Circle())
                            Text("Someone new").font(Typeface.font(11, weight: .regular))
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Recent activity").font(Typeface.font(23, weight: .medium)).tracking(-0.6)
                    Spacer()
                    Button("View all") { tab = .activity }.font(Typeface.font(12, weight: .regular)).underline()
                }
                if items.isEmpty { emptyActivity }
                ForEach(items.prefix(3)) { item in activityRow(item) }
            }
        }
    }

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("YOUR SHARED SPENDING", systemImage: "circle.grid.2x2")
                    .font(Typeface.font(10, weight: .medium)).tracking(1.4)
                Spacer()
                Image(systemName: "arrow.up.right").accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("You paid across your expenses").font(Typeface.font(13))
                Text(money(items.filter(\.isSplit).reduce(0) { $0 + $1.amount }))
                    .font(Typeface.font(35, weight: .medium)).tracking(-1.2)
                    .minimumScaleFactor(0.6).lineLimit(1).monospacedDigit()
                    .contentTransition(.numericText())
            }
            HStack {
                Text("Good times.\nFair shares.").font(Typeface.font(15, weight: .medium)).lineSpacing(3)
                Spacer()
                PaymentArtwork().frame(width: 145, height: 98)
                    .rotationEffect(.degrees(-5))
            }
        }
        .padding(22)
        .background(Palette.lavender, in: RoundedRectangle(cornerRadius: 30))
    }

    private func quickAction(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: icon).font(Typeface.font(22, weight: .medium))
                HStack { Text(title).font(Typeface.font(14, weight: .medium)); Spacer() }
            }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
                .background(color.opacity(0.6), in: RoundedRectangle(cornerRadius: 24))
        }
    }

    private func person(_ name: String, initials: String, color: Color) -> some View {
        Button { recipientName = name; sheet = .pay } label: {
            VStack(spacing: 8) { Avatar(initials: initials, color: color); Text(name).font(Typeface.font(11, weight: .regular)) }
        }
    }

    private func sectionTitle(_ title: String, trailing: String) -> some View {
        HStack {
            Text(title).font(Typeface.font(23, weight: .medium)).tracking(-0.6)
            Spacer()
            Text(trailing).font(Typeface.font(10, weight: .medium)).tracking(1).foregroundStyle(Palette.muted)
        }
    }

    private func activityRow(_ item: ActivityItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.symbol).font(Typeface.font(19, weight: .regular))
                .frame(width: 44, height: 48)
                .background(item.isSplit ? Palette.lavender.opacity(0.45) : Palette.lime.opacity(0.6), in: RoundedRectangle(cornerRadius: 15))
            VStack(alignment: .leading, spacing: 5) {
                Text(item.title).font(Typeface.font(14, weight: .medium))
                Text(item.subtitle).font(Typeface.font(10, weight: .regular)).foregroundStyle(Palette.muted)
            }
            Spacer(minLength: 5)
            Text(money(item.amount)).font(Typeface.font(14, weight: .medium)).monospacedDigit()
        }.accessibilityElement(children: .combine)
    }

    private var groups: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Better\ntogether.").font(Typeface.font(46, weight: .medium)).tracking(-1.2)
            Text("Keep the memories. Split the rest.").foregroundStyle(Palette.muted)
            Text("No groups yet").font(Typeface.font(23, weight: .medium))
            Text("You can record an expense now. Shared groups and member balances are not connected yet.")
                .font(Typeface.font(14)).foregroundStyle(Palette.muted)
            PrimaryButton(title: "Split a bill", icon: "plus") { sheet = .split }
        }
    }

    private var activity: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Every little\nexchange.").font(Typeface.font(35, weight: .medium)).tracking(-1.2)
            Text("Your local activity").foregroundStyle(Palette.muted)
            if items.isEmpty { emptyActivity }
            ForEach(items) { item in activityRow(item) }
        }
    }

    private var recentRecipients: [String] {
        var names: [String] = []
        for item in items where !item.isSplit {
            if !names.contains(item.title) { names.append(item.title) }
            if names.count == 3 { break }
        }
        return names
    }

    private var emptyActivity: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("A fresh start.").font(Typeface.font(19, weight: .medium))
            Text("Your recorded expenses and demo payments will appear here. No bank transactions are connected.")
                .font(Typeface.font(13)).foregroundStyle(Palette.muted)
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var navigation: some View {
        HStack {
            ForEach(Tab.allCases, id: \.self) { destination in
                Button { tab = destination } label: {
                    VStack(spacing: 6) {
                        Image(systemName: destination == .home ? "square.grid.2x2" : destination == .groups ? "person.2" : "clock.arrow.circlepath")
                            .font(Typeface.font(19, weight: .regular))
                        Text(destination.rawValue).font(Typeface.font(10, weight: .medium))
                    }.frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(tab == destination ? Palette.lavender.opacity(0.6) : .clear, in: RoundedRectangle(cornerRadius: 19))
                }.accessibilityAddTraits(tab == destination ? .isSelected : [])
            }
        }.padding(10).background(.white)
            .overlay(alignment: .top) { Rectangle().fill(Palette.ink.opacity(0.07)).frame(height: 1) }
    }
}
