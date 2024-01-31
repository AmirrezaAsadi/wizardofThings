//
//  ContentView.swift
//  WizardofHome
//
//  Created by Amir on 1/30/24.
//
import SwiftUI

// MARK: - Models
enum DeviceType {
    case statusProvider, onOff
}

struct Device: Identifiable {
    var id = UUID()
    var name: String
    var type: DeviceType
    var isOn: Bool
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

class HomeData: ObservableObject {
    @Published var devices: [Device] = []
    @Published var people: [Person] = []
    @Published var address: String = ""
}

// MARK: - ContentView
struct ContentView: View {
    @StateObject var homeData = HomeData()

    var body: some View {
        TabView {
            DevicesView(homeData: homeData)
                .tabItem {
                    Label("Devices", systemImage: "1.square.fill")
                }

            PeopleView(homeData: homeData)
                .tabItem {
                    Label("People", systemImage: "2.square.fill")
                }

            EventsView(homeData: homeData)
                .tabItem {
                    Label("Events", systemImage: "calendar")
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
                    DeviceRow(device: device) { isOn in
                        if let index = homeData.devices.firstIndex(where: { $0.id == device.id }) {
                            homeData.devices[index].isOn = isOn
                        }
                    }
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
    var onToggle: (Bool) -> Void

    var body: some View {
        HStack {
            Text(device.name)
            Spacer()
            if device.type == .onOff {
                Toggle(isOn: Binding(get: {
                    device.isOn
                }, set: { newValue in
                    onToggle(newValue)
                })) {
                    Text("State")
                }
                .labelsHidden()
            } else {
                Text("Status Provider")
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
                    Text("Status Provider").tag(DeviceType.statusProvider)
                }
                .pickerStyle(SegmentedPickerStyle())

                if deviceType == .onOff {
                    Toggle(isOn: $isOn) {
                        Text("Initial State")
                    }
                }

                Button("Add Device") {
                    let newDevice = Device(name: deviceName, type: deviceType, isOn: isOn)
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
        var prompt = "Given the following devices and people in a smart home, with the current time of day and location, provide updates on device states and any new events:\n\n"
        prompt += "Devices:\n"
        for device in homeData.devices {
            let state = device.isOn ? "on" : "off"
            prompt += "- \(device.name) is \(state)\n"
        }
        prompt += "\nPeople:\n"
        for person in homeData.people {
            prompt += "- \(person.name): \(person.bio)\n"
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
        let prompt = firstprompt + "Request the current state of all smart home devices based on decision of smarthome system that priortize safety Just provide device name and state like Oven is Off"
        chatGPTClient.sendMessage(prompt) { response in
            DispatchQueue.main.async {
                self.parseDeviceStates(response: response)
            }
        }
    }

    private func parseDeviceStates(response: String) {
        // Splitting the response into lines in case multiple device states are reported
        let lines = response.split(separator: "\n").map { String($0) }

        for line in lines {
            // Attempt to extract device name and state from the line
            let components = line.components(separatedBy: " is ")
            guard components.count == 2 else {
                print("Unexpected line format: \(line)")
                continue
            }

            let deviceName = components[0]  // Extracting the device name
            let stateComponent = components[1].lowercased()  // Extracting the state and converting to lowercase for comparison

            // Determine the device state based on the state component
            let isDeviceOn: Bool
            if stateComponent == "on" {
                isDeviceOn = true
            } else if stateComponent == "off" {
                isDeviceOn = false
            } else {
                print("Unknown state: \(stateComponent) for device: \(deviceName)")
                continue  // Skip to the next line if the state is neither "on" nor "off"
            }

            // Find and update the device state in HomeData, and add an event
            if let index = self.homeData.devices.firstIndex(where: { $0.name.lowercased() == deviceName.lowercased() }) {
                DispatchQueue.main.async {
                    self.homeData.devices[index].isOn = isDeviceOn
                    // Create a new event with the device state update
                    let eventDescription = "\(deviceName) is now \(isDeviceOn ? "On" : "Off")"
                    let newEvent = Event(description: eventDescription, timestamp: Date())
                    self.events.append(newEvent)  // Add the new event to the events list
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
