# Swift Mindstorms

Use Swift on your Apple device (iOS, iPadOS, Catalyst, and Playgrounds) to control your LEGO® MINDSTORMS® Robot Inventor 51515 and SPIKE™ Prime 45678 inventions.

## Development status

This is an early pre-alpha release. Be aware that bugs may still exist, and the system my exhibit unexpected behaviour. 

Many of the commands and notifications have been shown to work under test conditions, however some parts may work in unexpected ways or fail to work at all. 

The communications protocol has been engineered from examples posted by enthusiasts on the internet. As such it is an ongoing endeavour undergoing continuous refinement. 

If you find this code interesting or useful, consider contributing to this project or donating.

Some areas where contributions are appreciated:

- Reporting bugs and feature requests: Please report bugs and log requests for missing features. Pull requests are welcome.
- Automated testing: Including unit tests and integration tests. Note this may include developing a specification for a test harness to verify side effects under isolation.
- Complete implementation: Implement support for all commands and response messages that are available on the devices. This may entail reverse engineering or trial and error.
- Hardware testing: Currently this code has only been tested with the MINDSTORMS® 51515 hub, motors, and pixel display has been tested. The SPIKE™ Prime hub should work, however independant verification will be valuable. Hardware that is not available with MINDSTORMS® also needs to be tested, such as the force sensor available with SPIKE™ Prime.
- Third party hardware: Add support for third party hardware as it becomes available. Possibly as external packages that use this code as a dependency.
- Documentation: Document current and upcoming features, including preconditions, constraints, side effects, and examples.
- Use: use this code in your projects. Tell us how it went, good or bad.
- Official support: *Kindly* petition LEGO® group to publish the communications protocol used by hub. The specification will be immensely valuable to the community of hobbyists and product developers at large, and reduce time and effort required to work with the hub.

## Installation

Install this as a standard Swift Package.

In Xcode:

1. Click File -> Swift Packages -> Add Package Dependency.
2. Enter the URL for the git repository: https://github.com/lukevanin/swift-mindstorms.
3. Click Next.
4. Chose Branch, and make sure the branch is set to *main*. 
5. Click Next.
6. Select the application target where the package should be added.
7. Click Finish.

Wait for the package to be downloaded and installed.

## Getting started

### Setup:

Add `NSBluetoothAlwaysUsageDescription` and `UISupportedExternalAccessoryProtocols` to your `Info.plist`. See below:

```
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>Allow this application to use Bluetooth to connect to your Lego® Mindstorms® programmable brick</string>
    <key>UISupportedExternalAccessoryProtocols</key>
    <array>
        <string>com.lego.les</string>
    </array>
```

_Scene based apps: The system Bluetooth MiFi connection dialog does not work with scene based apps, including apps that use UIKit with `SceneDelegate` or SwiftUI apps that use an `App` view. Only `UIWindow` based apps will work._

This code allows three ways to interact with the hub, from highest level to lowest: 

1. Use `Robot` or `TankRobot` APIs. These APIs provide a convenient interface to connect to the hub, enqueue commands to be executed, and receive status updates for each notification. This allows the least amount of customization.  
2. Use the `Hub` to send command requests to the hub, and observe notification events from the hub. Using the hub, you can implement your own commands as simple `Codable` structs. You will need to perform the bookkeeping to associate response events notifications with the issuing command, if that functionality is desired. 
3. Use the `BluetoothConnection` to send raw data to, and receive raw data from, the hub. This provides the most flexibility at the cost of complexity. The `BluetoothConnection` only provides a communications channel and simple buffering. You need to manage all other aspects of the communications, including encoding and decoding messages.

### 1. Robots

The easiest way to get started is to use the `Robot` class for general purpose applications. Use the `TankRobot` vehicles designed to use tank steering, that is, wheels which turn in opposite directions to steer the vehicle.

To use the Robot:

1. Import the framework:
```
import SwiftMindstorms
```

2. Instantiate the `Robot` or `TankRobot` class, passing in a `Hub` instance:
```
let bluetoothConnection = BluetoothConnection()
let hub = hub(connection: bluetoothConnection)
let robot = Robot(hub: hub)
```

3. Connect the hub and wait for the connection status to change to `connected`:
```
hub.status.sink { status in 
    switch status {
    case .connected:
        // The robot is now ready to receive commands.
        start()
    default:
        // Stop sending commands to the robot.
    }
}
.store(in: &cancellables)
```

4. Send a command to the robot and wait for the response:
```
robot.motorGoDirectionToPosition(
    port: .A,
    position: 90,
    direction: .shortest,
    speed: 25,
    stall: true,
    completion: { success in 
    
    }
)
```

### Hub

TODO: Documentation and examples

### BluetoothConnection

TODO: Documentation and examples

## TODOs

This is a non-exhaustive list of the intended code changes.

1. Return Combine `Future` from `Robot` and `TankRobot` methods, instead of using completions. Use async/awat when that becomes available.
2. Include better error descriptions in `Robot` completion result, instead of boolean success/failure.
3. Use type-safe units for command parameters (e.g. `Measurement<UnitAngle>`) instead of primitives.
4. Add support for CocoaPods.

## Acknowledgements

This code relies heavily on the work of others and has only been made possible through their contributions. The following have been invaluable in making this possible:

- [Bricklife LEGO SPIKE Prime JSON command examples](https://gist.github.com/bricklife/13c7fe07c3145dd94f4f23d20ccf5a79)
- [Bricklife Spike Playgrounds](https://github.com/bricklife/SpikePlaygrounds-Swift/tree/d0944002f0fb07b26b3c90602ab63c87dbea32da)
- [TUFTSCEEO ServiceDock for SPIKE Prime](https://github.com/tuftsceeo/SPIKE-Web-Interface/blob/03c42dc1fb954ffb52141fd92575b3c296b122a6/docs/modules/SPIKE/spike/ujsonrpc.js)

###

## License

This project is licensed under the MIT license. See the LICENSE file for details. The LICENSE must be included and displayed in any product that includes this code in whole or in part.

## Limitation of liability

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
