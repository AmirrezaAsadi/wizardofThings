//
//  ContentView.swift
//  WizardofHome
//
//  Created by Amir on 1/30/24.
//
import SwiftUI

// MARK: - Models
enum DeviceType {
    case sensor, onOff
}

struct Device: Identifiable {
    var id = UUID()
    var name: String
    var type: DeviceType
    var isOn: Bool?  // Only for onOff devices
    var value: String?  // Only for sensor devices
}

struct Person: Identifiable {
    var id = UUID()
    var name: String
    var bio: String
}

struct Event: Identifiable {
    var id = UUID()
    var description: String
    var timestamp: Date
}

struct Rule: Identifiable {
    var id = UUID()
    var description: String
}

class HomeData: ObservableObject {
    @Published var devices: [Device] = []
    @Published var people: [Person] = []
    @Published var address: String = ""
    @Published var rules: [Rule] = []
}

// MARK: - ContentView
struct ContentView: View {
    @StateObject var homeData = HomeData()

    var body: some View {
        TabView {
            DevicesView(homeData: homeData)
                .tabItem {
                    Label("Devices", systemImage: "thermometer.transmission")
                }

            PeopleView(homeData: homeData)
                .tabItem {
                    Label("Enviornment", systemImage: "square.split.bottomrightquarter")
                }

            EventsView(homeData: homeData)
                .tabItem {
                    Label("Events", systemImage: "list.bullet.rectangle.portrait")
                }

            RulesView(homeData: homeData)
                .tabItem {
                    Label("Rules", systemImage: "list.bullet.rectangle")
                }
        }
    }
}

// MARK: - DevicesView
struct DevicesView: View {
    @ObservedObject var homeData: HomeData
    @State private var showingAddDevice = false

    var body: some View {
        NavigationView {
            List {
                ForEach(homeData.devices) { device in
                    DeviceRow(device: device)
                }
                .onDelete(perform: deleteDevice)
            }
            .navigationTitle("Devices")
            .toolbar {
                Button(action: {
                    showingAddDevice = true
                }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddDevice) {
                AddDeviceView(homeData: homeData)
            }
        }
    }

    private func deleteDevice(at offsets: IndexSet) {
        homeData.devices.remove(atOffsets: offsets)
    }
}

struct DeviceRow: View {
    var device: Device

    var body: some View {
        HStack {
            Text(device.name)
            Spacer()
            if device.type == .onOff, let isOn = device.isOn {
                Text(isOn ? "On" : "Off")
            } else if device.type == .sensor, let value = device.value {
                Text("Value: \(value)")
            }
        }
    }
}

struct AddDeviceView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var homeData: HomeData
    @State private var deviceName = ""
    @State private var deviceType = DeviceType.onOff
    @State private var isOn = false

    var body: some View {
        NavigationView {
            Form {
                TextField("Device Name", text: $deviceName)
                Picker("Type", selection: $deviceType) {
                    Text("On/Off").tag(DeviceType.onOff)
                    Text("Sensor").tag(DeviceType.sensor)
                }
                .pickerStyle(SegmentedPickerStyle())

                if deviceType == .onOff {
                    Toggle(isOn: $isOn) {
                        Text("Initial State")
                    }
                }

                Button("Add Device") {
                    let newDevice = Device(name: deviceName, type: deviceType, isOn: deviceType == .onOff ? isOn : nil)
                    homeData.devices.append(newDevice)
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationTitle("Add Device")
            .toolbar {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

// MARK: - PeopleView
struct PeopleView: View {
    @ObservedObject var homeData: HomeData
    @State private var showingAddPerson = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("People")) {
                    ForEach(homeData.people) { person in
                        VStack(alignment: .leading) {
                            Text(person.name).font(.headline)
                            Text(person.bio).font(.subheadline)
                        }
                    }
                    .onDelete(perform: deletePerson)
                }

                Section(header: Text("Address")) {
                    TextField("Enter Address", text: $homeData.address)
                }
            }
            .navigationTitle("People")
            .toolbar {
                Button(action: {
                    showingAddPerson = true
                }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddPerson) {
                AddPersonView(homeData: homeData)
            }
        }
    }

    private func deletePerson(at offsets: IndexSet) {
        homeData.people.remove(atOffsets: offsets)
    }
}

struct AddPersonView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var homeData: HomeData
    @State private var name = ""
    @State private var bio = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("Name", text: $name)
                TextField("Bio", text: $bio)
                Button("Add Person") {
                    let newPerson = Person(name: name, bio: bio)
                    homeData.people.append(newPerson)
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationTitle("Add Person")
            .toolbar {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

// MARK: - EventsView
// EventsView remains unchanged

// MARK: - RulesView
struct RulesView: View {
    @ObservedObject var homeData: HomeData
    @State private var showingAddRule = false
    @State private var newRuleDescription = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(homeData.rules) { rule in
                    Text(rule.description)
                }
                .onDelete(perform: deleteRule)
            }
            .navigationTitle("Rules")
            .toolbar {
                Button(action: {
                    showingAddRule.toggle()
                }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddRule) {
                NavigationView {
                    Form {
                        TextField("Rule Description", text: $newRuleDescription)
                        Button("Add Rule") {
                            let rule = Rule(description: newRuleDescription)
                            homeData.rules.append(rule)
                            newRuleDescription = ""
                            showingAddRule = false
                        }
                    }
                    .navigationTitle("Add New Rule")
                }
            }
        }
    }

    private func deleteRule(at offsets: IndexSet) {
        homeData.rules.remove(atOffsets: offsets)
    }
}

struct EventsView: View {
    @State private var events = [Event(description: "Initial Event", timestamp: Date())]
    @ObservedObject var homeData: HomeData
    let chatGPTClient = ChatGPTClient()

    var body: some View {
        NavigationView {
            List(events) { event in
                VStack(alignment: .leading) {
                    Text(event.description)
                    Text(event.timestamp, style: .date)
                }
            }
            .navigationTitle("Events")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Fetch Events") {
                        fetchNewEvents()
                    }
                    Button("Call Smart Home") {
                        callSmartHome() // This button does the same thing as "Fetch Events"
                    }
                }
            }
        }
    }

    private func fetchNewEvents() {
        let prompt = generatePrompt(homeData: homeData)
        chatGPTClient.sendMessage(prompt) { response in
            DispatchQueue.main.async {
                // Assuming the response is a string that can be directly used as an event description
                let newEvent = Event(description: response, timestamp: Date())
                self.events.append(newEvent)
            }
        }
    }

    private func generatePrompt(homeData: HomeData) -> String {
        var prompt = "Given the following devices, people, and rules in a smart home, with the current time of day and location, provide updates on device states and any new events:\n\n"
        prompt += "Devices:\n"
        for device in homeData.devices {
            let deviceTypeDescription = device.type == .onOff ? "On/Off Device" : "Sensor"
            let stateOrValueDescription = device.type == .onOff ? (device.isOn ?? false ? "on" : "off") : (device.value ?? "unknown value")
            prompt += "- \(device.name) (\(deviceTypeDescription)) is \(stateOrValueDescription)\n"
        }
        prompt += "\nPeople:\n"
        for person in homeData.people {
            prompt += "- \(person.name): \(person.bio)\n"
        }
        prompt += "\nRules:\n"
        for rule in homeData.rules {
            prompt += "- \(rule.description)\n"
        }
        prompt += "\nTime of Day: \(formatCurrentTime())\n"
        prompt += "Location: \(homeData.address)\n"
        return prompt
    }

    private func formatCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    private func callSmartHome() {
        let firstprompt = generatePrompt(homeData: homeData)
        let prompt = firstprompt + "Provide the current state of all smart home devices based on  rules , make sure to provide the sensor value, do not provide extra information just return device name and state like Oven is Off ,  or IF DEVICE IS SENSOR  RETURN DEVICE NAME is the predicted value of sensors"
        chatGPTClient.sendMessage(prompt) { response in
            DispatchQueue.main.async {
                self.parseDeviceStates(response: response)
            }
        }
    }

    private func parseDeviceStates(response: String) {
        let lines = response.split(separator: "\n").map { String($0) }

        for line in lines {
            let components = line.components(separatedBy: " is ")
            guard components.count == 2 else {
                print("Unexpected line format: \(line)")
                continue
            }

            let deviceName = components[0]
            let stateOrValueComponent = components[1]

            if let index = self.homeData.devices.firstIndex(where: { $0.name.lowercased() == deviceName.lowercased() }) {
                let device = self.homeData.devices[index]
                
                DispatchQueue.main.async {
                    var eventDescription = ""

                    if device.type == .onOff {
                        // For on/off devices, change the state based on the response
                        let isDeviceOn = stateOrValueComponent.lowercased() == "on"
                        self.homeData.devices[index].isOn = isDeviceOn
                        eventDescription = "\(deviceName) is now \(isDeviceOn ? "On" : "Off")"
                    } else if device.type == .sensor {
                        // For sensor devices, update the value based on the response
                        self.homeData.devices[index].value = stateOrValueComponent
                        eventDescription = "\(deviceName) value is \(stateOrValueComponent)"
                    }

                    if !eventDescription.isEmpty {
                        // Creating a new event for the update
                        let newEvent = Event(description: eventDescription, timestamp: Date())
                        self.events.append(newEvent)
                    }
                }
            } else {
                print("Device named \(deviceName) not found.")
            }
        }
    }

}



#Preview {
    ContentView()
}
