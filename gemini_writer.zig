const std = @import("std");

// [Header] (fixed size 40 bytes)
const header = extern struct {
    magic: [4]u8 = "TDOS".*,
    version: u16 = 1,
    header_size: u16,
    record_count: u64,
    file_size: u64,
};

const record_table = extern struct {
    string_offset: u64,
    string_length: u64,
    flags: u32,
};

pub fn create_new_file(name: []const u8) !void {
    var fb1: [256]u8 = undefined;
    const path = try std.fmt.bufPrint(&fb1, "{s}.tdos", .{name});

    // [FIX 1] Remove .{ .read = true }. Use defaults (Write Only).
    // This often fixes the BADF error during initial flush.
    const file = try std.fs.cwd().createFile(path, .{});
    defer file.close();

    // Setup Buffered Writer
    var buf: [4096]u8 = undefined;
    var bw = file.writer(&buf);
    
    // [FIX 2] Use .interface as you correctly identified
    const writer = &bw.interface;

    // Write Header (Little Endian)
    try writer.writeAll("TDOS");
    try writer.writeInt(u16, 1, .little);
    try writer.writeInt(u16, 40, .little);
    try writer.writeInt(u64, 0, .little);
    try writer.writeInt(u64, 40, .little);

    const padding = [_]u8{0} ** 16;
    try writer.writeAll(&padding);

    // [FIX 3] Flush the Buffer struct (bw), not the interface
    try bw.flush();
}

pub fn addRecord(file_name: []const u8, data: []const u8) !void {
    var fb1: [256]u8 = undefined;
    const path = try std.fmt.bufPrint(&fb1, "{s}.tdos", .{file_name});

    // Open Read/Write (Needed for Seek + Write)
    const file = try std.fs.cwd().openFile(path, .{ .mode = .read_write });
    defer file.close();

    // [FIX 4] Seek FIRST.
    const file_size = try file.getEndPos();
    try file.seekTo(file_size);
    
    // Debug: Prove we are at the end
    // std.debug.print("Appending at offset: {d}\n", .{file_size});

    // [FIX 5] Create Writer AFTER seeking
    var buf: [4096]u8 = undefined;
    var bw = file.writer(&buf);
    const writer = bw.interface;

    const record_meta_size: u64 = 20; 
    const string_offset = file_size + record_meta_size;

    const newRecord = record_table{
        .flags = 0,
        .string_length = data.len,
        .string_offset = string_offset,
    };

    // Write Data
    try writer.writeInt(u64, newRecord.string_offset, .little);
    try writer.writeInt(u64, newRecord.string_length, .little);
    try writer.writeInt(u32, newRecord.flags, .little);
    try writer.writeAll(data);

    // [FIX 6] Flush Buffer
    try bw.flush();
}

test "addRecord" {
    std.debug.print("\n=== new test run ===\n", .{});
    try create_new_file("test_file");

    // Verification 1: Did the header actually write?
    {
        const file = try std.fs.cwd().openFile("test_file.tdos", .{});
        const size = try file.getEndPos();
        file.close();
        if (size == 0) return error.HeaderWriteFailed;
        std.debug.print("Header verified. Size: {d}\n", .{size});
    }

    try addRecord("test_file", "Hello, my name is Raj");
    try addRecord("test_file", "Hello, my name is Aadarsh");
    try addRecord("test_file", "Hello, my name is Suraj");
    
    // Verification 2: Final Size
    const file = try std.fs.cwd().openFile("test_file.tdos", .{});
    defer file.close();
    std.debug.print("Final file size: {d} bytes\n", .{try file.getEndPos()});
}
