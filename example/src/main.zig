const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const wavez = @import("wavez_import_name");
const readWavFile = wavez.readWavFile;
const writeWavFile = wavez.writeWavFile;

pub fn main() !void {
    const filename = "wavfiles/album-leaf-12sec.wav";
    // const filename = "wavfiles/GoodStart.wav";

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // const num_chan = 1;
    const num_chan = 2;
    const interlace = false;

    const OutputSampleType = i16;
    // const SampleType = i24;
    // const SampleType = i32;

    print("reading: {s} ...", .{filename});
    const aud = try readWavFile(allocator, filename, interlace, num_chan);
    print(" done.\n", .{});

    for (0..10) |i| {
        print("x[{d:>3}]: {d:>5}\n", .{ i, aud.samples_a[i] });
    }
    print("sample_rate: {d}\n", .{aud.sample_rate});

    const outfilename = "wavfiles/junk_output.wav";

    print("writing: {s} ...", .{outfilename});
    try writeWavFile(outfilename, OutputSampleType, aud);
    print(" done.\n", .{});
}
