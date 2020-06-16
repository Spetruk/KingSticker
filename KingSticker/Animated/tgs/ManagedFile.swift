//
//  ManagedFile.swift
//  KingSticker
//
//  Copyright © 2020 Purkylin King
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

public enum ManagedFileMode {
    case read
    case readwrite
    case append
}

private func wrappedWrite(_ fd: Int32, _ data: UnsafeRawPointer, _ count: Int) -> Int {
    return write(fd, data, count)
}

private func wrappedRead(_ fd: Int32, _ data: UnsafeMutableRawPointer, _ count: Int) -> Int {
    return read(fd, data, count)
}

public final class ManagedFile {
    private let queue: DispatchQueue?
    private let fd: Int32
    private let mode: ManagedFileMode
    
    public init?(queue: DispatchQueue, path: String, mode: ManagedFileMode) {
        self.queue = queue
        self.mode = mode
        let fileMode: Int32
        let accessMode: UInt16
        switch mode {
            case .read:
                fileMode = O_RDONLY
                accessMode = S_IRUSR
            case .readwrite:
                fileMode = O_RDWR | O_CREAT
                accessMode = S_IRUSR | S_IWUSR
            case .append:
                fileMode = O_WRONLY | O_CREAT | O_APPEND
                accessMode = S_IRUSR | S_IWUSR
        }
        let fd = open(path, fileMode, accessMode)
        if fd >= 0 {
            self.fd = fd
        } else {
            return nil
        }
    }
    
    deinit {
        close(self.fd)
    }
    
    @discardableResult
    public func write(_ data: UnsafeRawPointer, count: Int) -> Int {
        return wrappedWrite(self.fd, data, count)
    }
    
    public func read(_ data: UnsafeMutableRawPointer, _ count: Int) -> Int {
        return wrappedRead(self.fd, data, count)
    }
    
    public func readData(count: Int) -> Data {
        var result = Data(count: count)
        result.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<Int8>) -> Void in
            let readCount = self.read(bytes, count)
            assert(readCount == count)
        }
        return result
    }
    
    public func seek(position: Int64) {
        lseek(self.fd, position, SEEK_SET)
    }
    
    public func truncate(count: Int64) {
        ftruncate(self.fd, count)
    }
    
    public func getSize() -> Int? {
        var value = stat()
        if fstat(self.fd, &value) == 0 {
            return Int(value.st_size)
        } else {
            return nil
        }
    }
    
    public func sync() {
        fsync(self.fd)
    }
}
