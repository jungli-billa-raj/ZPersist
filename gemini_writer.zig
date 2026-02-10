const std = @import("std");

// [Header] (fixed size 40 bytes)
const header = extern struct {
    magic: [4]u8 = "TDOS".*,
    version: u16 = 1,
    header_size: u16,
    record_count: u64,
    file_size: u64,
};

// [Record Table] (fixed 16 bytes)
const record_table = extern struct {
    string_offset: u64,
    string_length: u64,
    flags: u32,
};

pub fn create_new_file(name: []const u8) !void {
    var pathBuffer: [256]u8 = undefined;
    const path = try std.fmt.bufPrint(&pathBuffer, "{s}.tdos", .{name});

    const file = try std.fs.cwd().createFile(path, .{ .read = true });
    defer file.close();

    const h = header{
        .header_size = 40,
        .file_size = 0,
        .record_count = 0,
    };

    // FIX: Write raw bytes directly. 
    // This avoids 'writer.writeStruct' dependencies that might be breaking your build.
    try file.writeAll(std.mem.asBytes(&h));
}

pub fn addRecord(file_name: []const u8, data: []const u8) !void {
    var fb1: [256]u8 = undefined;
    const path = try std.fmt.bufPrint(&fb1, "{s}.tdos", .{file_name});
    
    // Open in read_write mode
    const file = try std.fs.cwd().openFile(path, .{ .mode = .read_write });
    defer file.close();

    // 1. SEEK TO END
    // This was the main bug. We must find the TRUE end of the file.
    const current_file_size = try file.getEndPos();
    try file.seekTo(current_file_size);

    // 2. Calculate offsets
    const record_meta_size: u64 = @sizeOf(record_table);
    const string_data_offset = current_file_size + record_meta_size;

    const newRecord = record_table{
        .flags = 0,
        .string_length = data.len,
        .string_offset = string_data_offset,
    };

    // 3. Write Metadata + Data (Unbuffered)
    try file.writeAll(std.mem.asBytes(&newRecord));
    try file.writeAll(data);
    
    // (Optional) Update Header here to reflect new file size/count
}

test "addRecord" {
    std.debug.print("\n=== new test run ===\n", .{});
    try create_new_file("test_file");

    try addRecord("test_file", "Hello, my name is Raj");
    try addRecord("test_file", "Hello, my name is Aadarsh");
    try addRecord("test_file", "Hello, my name is Suraj");
    
    const file = try std.fs.cwd().openFile("test_file.tdos", .{});
    defer file.close();
    std.debug.print("Final file size: {d} bytes (Expected > 40)\n", .{try file.getEndPos()});
}
