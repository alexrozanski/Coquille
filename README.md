# 🐚 Coquille

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Falexrozanski%2FCoquille%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/alexrozanski/Coquille)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Falexrozanski%2FCoquille%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/alexrozanski/Coquille)
[![Build Status](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2Falexrozanski%2FCoquille%2Fbadge%3Fref%3Dmain&style=flat&label=Build%20%2B%20Test)](https://actions-badge.atrox.dev/alexrozanski/Coquille/goto?ref=main)

A simple Swift wrapper around `Process` supporting Swift Concurrency and streamed output from `stdout` and `stderr`.

## Requirements

macOS 10.15+

## Installation

Add Coquille to your project using Xcode (File > Add Packages...) or by adding it to your project's `Package.swift` file:

```swift
dependencies: [
  .package(url: "https://github.com/alexrozanski/Coquille.git", from: "0.3.0")
]
```

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

By default `Process` does not pipe any output from the spawned process to `stdout` and `stderr`. This can be configured with `printStdout` and `printStderr`:

```swift
import Coquille

let process = Process(commandString: "brew install wget", printStdout: true))
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

### Cancellation

The main `Process.run()` function signature is:

```swift
public func run() async throws -> Status
```
    
which allows you use Swift Concurrency to execute the subprocess and `await` the exit status. However if you want to support cancellation you can use the other `run()` function:

```swift
public func run(with completionHandler: @escaping ((Status) -> Void)) -> ProcessCancellationHandle
```
    
This immediately returns an opaque `ProcessCancellationHandle` type which you can call `cancel()` on, should you wish to cancel execution, and the process status is delivered through a `completionHandler` closure.

## Acknowledgements

Thanks to [Ben Chatelain](https://github.com/phatblat) for their [blog post](https://phatbl.at/2019/01/08/intercepting-stdout-in-swift.html) on intercepting stdout, used
to implement some of the tests in the test suite.
