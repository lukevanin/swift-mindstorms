# Swift Mindstorms

Use Swift on your Apple device (iOS, iPadOS, MacOS, and Playgrounds) to control your LEGO® MINDSTORMS® Robot Inventor 51515 and SPIKE™ Prime 45678 inventions.

## Development status

This is an early pre-alpha release. Be aware that bugs may still exist, and the system my exhibit unexpected behaviour. 

Many of the commands and notifications have been shown to work under test conditions, however some parts may work in unexpected ways or fail to work at all. 

The communications protocol has been engineered from examples posted by enthusiasts on the internet. As such it is an ongoing endeavour undergoing continuous refinement. 

If you found this code useful, consider helping others by contributing to this project.

Some areas where contributions are appreciated:

- Reporting bugs and feature requests: Please report bugs and log requests for missing features. Pull requests are welcome.
- Automated testing: Including unit tests and integration tests. Note this may include developing a specification for a test harness to verify side effects under isolation.
- Complete implementation: Implement support for all commands and response messages that are available on the devices. This may entail reverse engineering or trial and error.
- Hardware testing: Currently this code has only been tested with the MINDSTORMS® 51515 hub, motors, and pixel display has been tested. The SPIKE™ Prime hub should work, however independant verification will be valuable. Hardware that is not available with MINDSTORMS® also needs to be tested, such as the force sensor available with SPIKE™ Prime.
- Third party hardware: Add support for third party hardware as it becomes available. Possibly as external packages that use this code as a dependency.
- Documentation: Document current and upcoming features, including preconditions, constraints, side effects, and examples.
- Use: use this code in your projects. Tell us how it went, good or bad.
- Official support: *Kindly* petition LEGO® group to publish the communications protocol used to communicate with the hub. The specification will be valuable to the wider community of hobbyists and product developers.

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
