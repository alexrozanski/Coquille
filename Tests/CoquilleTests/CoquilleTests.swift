import XCTest

@testable import Coquille

final class CoquilleTests: XCTestCase {

    /* Redirection code is based on https://phatbl.at/2019/01/08/intercepting-stdout-in-swift.html
     *
     * Something funny happens when extraacting pipe or source into another class/property but this works
     * fine when setup/teardown is done inside the test case, so duplicate this for now.
     *
     */

    // MARK: - Default I/O Streams

    func testDefaultStdoutParameter() async throws {
        let expectation = expectation(
            description: "Stdout handler should be called with correct output")
        expectation.assertForOverFulfill = false

        // Redirect stdout
        let pipe = Pipe()
        dup2(pipe.fileHandleForWriting.fileDescriptor, fileno(stdout))
        let queue = DispatchQueue.global(qos: .utility)
        let source = DispatchSource.makeReadSource(
            fileDescriptor: pipe.fileHandleForReading.fileDescriptor, queue: queue)
        source.setEventHandler {
            if !pipe.fileHandleForReading.availableData.isEmpty { expectation.fulfill() }
        }
        source.resume()

        // Test
        let process = Process(
            command: Process.Command("echo", arguments: ["Hello, World!"]))

        _ = try await process.run()

        // Tear down
        freopen("/dev/stdout", "a", stdout)
        try? pipe.fileHandleForWriting.close()

        await waitForExpectations(timeout: 5.0)
    }

    func testDefaultStderrParameter() async throws {
        let expectation = expectation(
            description: "Stderr handler should not be called as stderr output is ignored by default")
        expectation.assertForOverFulfill = false
        expectation.isInverted = true

        // Redirect stdout
        let pipe = Pipe()
        dup2(pipe.fileHandleForWriting.fileDescriptor, fileno(stderr))
        let queue = DispatchQueue.global(qos: .utility)
        let source = DispatchSource.makeReadSource(
            fileDescriptor: pipe.fileHandleForReading.fileDescriptor, queue: queue)
        source.setEventHandler {
            if !pipe.fileHandleForReading.availableData.isEmpty { expectation.fulfill() }
        }
        source.resume()

        let process = Process(
            command: Process.Command("echo", arguments: ["Hello, World!"]))

        _ = try await process.run()

        // Tear down
        freopen("/dev/stderr", "a", stderr)
        try? pipe.fileHandleForWriting.close()

        await waitForExpectations(timeout: 0.5)
    }

    func testPrintToStderr() async throws {
        let expectation = expectation(
            description: "Stderr handler should be called")
        expectation.assertForOverFulfill = false

        // Redirect stdout
        let pipe = Pipe()
        dup2(pipe.fileHandleForWriting.fileDescriptor, fileno(stderr))
        let queue = DispatchQueue.global(qos: .utility)
        let source = DispatchSource.makeReadSource(
            fileDescriptor: pipe.fileHandleForReading.fileDescriptor, queue: queue)
        source.setEventHandler {
            if !pipe.fileHandleForReading.availableData.isEmpty { expectation.fulfill() }
        }
        source.resume()

        let process = Process(commandString: "invalid-command")

        _ = try await process.run()

        // Tear down
        freopen("/dev/stderr", "a", stderr)
        try? pipe.fileHandleForWriting.close()

        await waitForExpectations(timeout: 0.5)
    }

    // MARK: - Running Commands

    func testCommandSuccess() async throws {
        let process = Process(
            command: Process.Command("echo", arguments: ["Hello, World!"]))

        do {
            let status = try await process.run()
            XCTAssertTrue(status.isSuccess, "Process run should be successful")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCommandFailure() async throws {
        let process = Process(commandString: "invalid-command")
        do {
            let status = try await process.run()
            XCTAssertTrue(status.isFailure, "Process run should fail")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Custom Handlers

    func testExecutionWithStdout() async throws {
        let expectation = expectation(
            description: "Stdout handler should be called with correct output")
        expectation.assertForOverFulfill = false
        let process = Process(
            command: Process.Command("echo", arguments: ["Hello, World!"])
        ) { stdout in
            XCTAssertEqual(stdout, "Hello, World!\n")
            expectation.fulfill()
        }

        do {
            let status = try await process.run()
            XCTAssertTrue(status.isSuccess, "Process run should be successful")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        await waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testExecutionWithStderr() async throws {
        let expectation = expectation(
            description: "Stderr handler should be called with output")
        expectation.assertForOverFulfill = false

        let process = Process(
            command: Process.Command("invalidCommand", arguments: ["Hello, World!"]),
            stderr: { stderr in
                XCTAssertTrue(!stderr.isEmpty, "stderr output should be non-empty")
                expectation.fulfill()
            })

        do {
            let status = try await process.run()
            XCTAssertTrue(status.isFailure, "Executing invalid command should fail")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        await waitForExpectations(timeout: 5.0, handler: nil)
    }
}
