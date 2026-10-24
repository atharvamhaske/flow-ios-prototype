import SwiftUI

struct ActivityItem: Identifiable, Codable {
    var id = UUID()
    let title: String
    let subtitle: String
    let amount: Int
    let symbol: String
    let isSplit: Bool
}

enum DemoData {
    static let activity = [
        ActivityItem(title: "Sunday brunch", subtitle: "Weekend people · You paid", amount: 184000, symbol: "cup.and.saucer", isSplit: true),
        ActivityItem(title: "Aarav Shah", subtitle: "Demo transfer · Yesterday", amount: 45000, symbol: "arrow.up.right", isSplit: false),
        ActivityItem(title: "Groceries", subtitle: "Our place · You paid", amount: 126000, symbol: "basket", isSplit: true)
    ]
}

struct FlowHome: View {
    enum Tab: String, CaseIterable { case home = "Home", groups = "Groups", activity = "Activity" }
    enum Sheet: String, Identifiable { case pay, split; var id: String { rawValue } }
    @State private var tab = Tab.home
    @State private var sheet: Sheet?
    @State private var recipientName = ""
    @State private var items = DemoData.activity
    @State private var notice: String?
    @AppStorage("flow.demo.activity") private var savedActivity = Data()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
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
            do { items = try JSONDecoder().decode([ActivityItem].self, from: savedActivity) }
            catch { notice = "Your saved demo activity could not be read. Sample activity is shown; the saved data has not been overwritten." }
        }
    }

    var snapshot: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 28) { header; home }
                .padding(24)
            Spacer(minLength: 0)
            navigation
        }.foregroundStyle(Palette.ink).background(.white).buttonStyle(PressStyle())
    }

    private func append(_ item: ActivityItem) {
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
                Image(systemName: "arrow.up.forward.circle.fill").font(.system(size: 25))
                Text("flow").font(.system(size: 30, weight: .semibold, design: .rounded)).tracking(-1.6)
            }
            Spacer()
            Text("LOCAL DEMO").font(.system(size: 9, weight: .semibold)).tracking(1.2)
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(Palette.surface, in: Capsule())
            Avatar(initials: "You", color: Palette.lime)
        }
    }

    private var home: some View {
        Group {
            VStack(alignment: .leading, spacing: 5) {
                Text("A little less owing.").foregroundStyle(Palette.muted)
                Text("More living.").font(.system(size: 43, weight: .medium)).tracking(-2)
            }
            balanceCard
            HStack(spacing: 12) {
                quickAction("Pay someone", icon: "arrow.up.right", color: Palette.lime) { recipientName = ""; sheet = .pay }
                quickAction("Split a bill", icon: "divide", color: Palette.lavender) { sheet = .split }
            }
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Your people", trailing: "PAY A FRIEND")
                HStack {
                    person("Aarav", initials: "AS", color: Palette.lavender)
                    Spacer()
                    person("Meera", initials: "MK", color: Palette.lime)
                    Spacer()
                    person("Riya", initials: "RP", color: Palette.lavender)
                    Spacer()
                    Button { recipientName = ""; sheet = .pay } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "plus").frame(width: 44, height: 44).background(Palette.surface, in: Circle())
                            Text("Someone new").font(.system(size: 11))
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Lately").font(.system(size: 23, weight: .medium)).tracking(-0.6)
                    Spacer()
                    Button("View all") { tab = .activity }.font(.system(size: 12)).underline()
                }
                ForEach(items.prefix(3)) { item in activityRow(item) }
            }
        }
    }

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Label("THE BIG PICTURE", systemImage: "circle.grid.2x2")
                    .font(.system(size: 10, weight: .medium)).tracking(1.4)
                Spacer()
                Image(systemName: "arrow.up.right")
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Shared spending").font(.system(size: 13))
                Text(money(items.filter(\.isSplit).reduce(0) { $0 + $1.amount }))
                    .font(.system(size: 43, weight: .medium, design: .rounded)).tracking(-2)
                    .minimumScaleFactor(0.6).lineLimit(1).monospacedDigit()
                    .contentTransition(.numericText())
            }
            HStack {
                Text("Good times. Fair shares.").font(.system(size: 12))
                Spacer()
                HStack(spacing: -12) {
                    Avatar(initials: "AS", color: Palette.lime)
                    Avatar(initials: "MK")
                    Avatar(initials: "+2", color: .white)
                }
            }
        }
        .padding(24)
        .background(Palette.lavender, in: RoundedRectangle(cornerRadius: 30))
    }

    private func quickAction(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: icon).font(.system(size: 22, weight: .medium))
                HStack { Text(title).font(.system(size: 14, weight: .medium)); Spacer() }
            }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                .background(color.opacity(0.6), in: RoundedRectangle(cornerRadius: 24))
        }
    }

    private func person(_ name: String, initials: String, color: Color) -> some View {
        Button { recipientName = name; sheet = .pay } label: {
            VStack(spacing: 8) { Avatar(initials: initials, color: color); Text(name).font(.system(size: 11)) }
        }
    }

    private func sectionTitle(_ title: String, trailing: String) -> some View {
        HStack {
            Text(title).font(.system(size: 23, weight: .medium)).tracking(-0.6)
            Spacer()
            Text(trailing).font(.system(size: 8, weight: .medium)).tracking(1).foregroundStyle(Palette.muted)
        }
    }

    private func activityRow(_ item: ActivityItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.symbol).font(.system(size: 19))
                .frame(width: 44, height: 48)
                .background(item.isSplit ? Palette.lavender.opacity(0.45) : Palette.lime.opacity(0.6), in: RoundedRectangle(cornerRadius: 15))
            VStack(alignment: .leading, spacing: 5) {
                Text(item.title).font(.system(size: 14, weight: .medium))
                Text(item.subtitle).font(.system(size: 10)).foregroundStyle(Palette.muted)
            }
            Spacer(minLength: 5)
            Text(money(item.amount)).font(.system(size: 14, weight: .medium)).monospacedDigit()
        }.accessibilityElement(children: .combine)
    }

    private var groups: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Better\ntogether.").font(.system(size: 46, weight: .medium)).tracking(-2)
            Text("Keep the memories. Split the rest.").foregroundStyle(Palette.muted)
            ForEach(Array(["Weekend people", "Our place"].enumerated()), id: \.offset) { index, title in
                VStack(alignment: .leading, spacing: 24) {
                    HStack { Image(systemName: index == 0 ? "sun.max" : "house").font(.system(size: 30)); Spacer(); Text("4 PEOPLE").font(.caption2).tracking(1) }
                    Text(title).font(.system(size: 28, weight: .medium)).tracking(-1)
                    Button { sheet = .split } label: {
                        HStack { Text("Add a shared expense"); Spacer(); Image(systemName: "plus") }.font(.system(size: 13))
                    }
                }.padding(26).background(index == 0 ? Palette.lavender : Palette.lime, in: RoundedRectangle(cornerRadius: 28))
            }
            Text("Sample groups · Expenses are saved on this device.")
                .font(.caption).foregroundStyle(Palette.muted)
        }
    }

    private var activity: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Every little\nexchange.").font(.system(size: 43, weight: .medium)).tracking(-2)
            Text("Your local activity").foregroundStyle(Palette.muted)
            ForEach(items) { item in activityRow(item) }
        }
    }

    private var navigation: some View {
        HStack {
            ForEach(Tab.allCases, id: \.self) { destination in
                Button { tab = destination } label: {
                    VStack(spacing: 6) {
                        Image(systemName: destination == .home ? "square.grid.2x2" : destination == .groups ? "person.2" : "clock.arrow.circlepath")
                            .font(.system(size: 19))
                        Text(destination.rawValue).font(.system(size: 10, weight: .medium))
                    }.frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(tab == destination ? Palette.lavender.opacity(0.6) : .clear, in: RoundedRectangle(cornerRadius: 19))
                }.accessibilityAddTraits(tab == destination ? .isSelected : [])
            }
        }.padding(10).background(.white)
            .overlay(alignment: .top) { Rectangle().fill(Palette.ink.opacity(0.07)).frame(height: 1) }
    }
}
