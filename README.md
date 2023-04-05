# Coquille

A simple Swift wrapper around `Process` supporting Swift Concurrency and streamed output from `stdout` and `stderr`.

## Requirements

macOS 10.15+

## Installation

Add Coquille to your project using Xcode (File > Add Packages...) or by adding it to your project's `Package.swift` file:

dependencies: [
  .package(url: "https://github.com/alexrozanski/Coquille.git", from: "0.1.0")
]

## Usage

Coquille exposes its own `Process` class which you can interact with to execute commands. `Process.run()` is an `async` function so you can just `await` the exit code:

```swift
import Coquille

let process = Process(commandString: "pwd"))
_ = try await process.run() // Prints `pwd` to `stdout`

// Use `command:` for more easily working with variable command-line arguments
let deps = ["numpy", "torch"]
let process = Process(command: .init("python3", arguments: ["-m", "pip", "install"] + deps)))
_ = try await process.run()
```

### I/O

By default `Process` pipes output from the spawned process to `stdout` and `stderr`. This can be configured with `printStdout` and `printStderr`:

```swift
import Coquille

let process = Process(commandString: "brew install wget", printStderr: false))
_ = try await process.run() // Pipes standard output to `stdout` but will not pipe error output to `stderr`
```

You can also pass an `OutputHandler` for both stdout and stderr which will stream contents from both:

```swift
import Coquille

let process = Process(
  commandString: "swift build",
  stdout: { stdout in
    ...
  },
  stderr: { stderr in
    ...
  })
_ = try await process.run() // Streams standard and error output to the handlers provided to `stdout:` and `stderr:`
```

### Exit Codes

```swift
// `isSuccess` can be used to test the exit code for success
let hasRuby = (try await Process(commandString: "which ruby").run()).isSuccess

// Use `errorCode` to get a nonzero exit code
if let errorCode = (try await Process(commandString: "swift build").run()).errorCode {
  switch errorCode {
    case 127:
      // Command not found
    default:
      ...
  }
}
```

## Acknowledgements

Thanks to [Ben Chatelain](https://github.com/phatblat) for their [blog post](https://phatbl.at/2019/01/08/intercepting-stdout-in-swift.html) on intercepting stdout, used
to implement some of the tests in the test suite.
