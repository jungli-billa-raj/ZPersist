const std = @import("std");
const expect = std.testing.expect;

const models = @import("models.zig");
const header = models.header;
const record_table = models.record_table;
const header_size = models.header_size;
const record_table_size = models.record_table_size;

//for now, it's just going to print in stderr
pub fn verify_header(file_name:[]const u8) !bool{
    var fb1:[256]u8 = undefined;
    const path = try std.fmt.bufPrint(&fb1, "{s}.tdos", .{file_name});
    var file = try std.fs.cwd().openFile(path, .{.mode = .read_only });
    defer file.close();

    var fb2:[1024]u8 = undefined;
    var reader = file.reader(&fb2);
    var reader_interface = &reader.interface;

    try reader.seekTo(0);

    const expected_header = try reader_interface.peek(4);
    if (std.mem.eql(u8, "TDOS", expected_header)){
        // try reader_interface.toss(4);
        return true;
    } 
    
    return false;

}

test "verify_header" {
    const result = try verify_header("test_file");
    try expect(result == true);
}

// // Move to byte 1024
// try file.seekTo(1024);

// // Move forward 50 bytes relative to current position
// try file.seekBy(50);

