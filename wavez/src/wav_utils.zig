const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const Little = std.builtin.Endian.little;

pub const Audio = struct {
    const Self = @This();

    n_chan: u16 = 0,
    interleave: bool = false,
    sample_rate: u32 = 0,
    nsamp_per_chan: u32 = 0,
    samples_a: []f32 = undefined,
    samples_b: []f32 = undefined,

    pub fn init(self: *Self, allocator: Allocator) !void {
        try if (self.n_chan == 0) error.UninitializedProperty;
        try if ((self.n_chan != 1) and (self.n_chan != 2)) error.UnsupportedNumberChannels;

        try if (self.sample_rate == 0) error.UninitializedProperty;
        try if (self.nsamp_per_chan == 0) error.UninitializedProperty;

        self.samples_a = try allocator.alloc(f32, self.n_chan * self.nsamp_per_chan);

        switch (self.n_chan) {
            1 => {
                self.samples_a = try allocator.alloc(f32, self.nsamp_per_chan);
                self.samples_b.ptr = self.samples_a.ptr;
                self.samples_b.len = 0;
            },

            2 => {
                self.samples_a = try allocator.alloc(f32, 2 * self.nsamp_per_chan);
                switch (self.interleave) {
                    false => {

                        // memory for samples_a, is split into contiguous spaces
                        // for samples_a and samples_b

                        self.samples_b = self.samples_a[self.nsamp_per_chan..];
                        self.samples_a.len = self.nsamp_per_chan;
                    },

                    true => {

                        // when interleaved, all samples lie in slice samples_a length
                        // of samples_b is set to zero, and points to samples_a to avoid
                        // segmentation faults when printing struct (for example)

                        self.samples_b.len = 0;
                        self.samples_b.ptr = self.samples_a.ptr;
                    },
                }
            },
            else => {},
        }
    }
};

pub const WavHeader = struct {
    const Self = @This();

    chunk_id: [4]u8,
    chunk_size: u32,
    riff_type: [4]u8,

    pub fn read(self: *Self, file: std.fs.File) !void {
        self.chunk_id = try file.reader().readBytesNoEof(4);
        if (!std.mem.eql(u8, &self.chunk_id, "RIFF")) return error.Expected_RIFF;

        self.chunk_size = try file.reader().readInt(u32, Little);

        self.riff_type = try file.reader().readBytesNoEof(4);

        if (!std.mem.eql(u8, &self.riff_type, "WAVE")) return error.Expected_WAVE;
    }

    pub fn print(self: Self) void {
        std.debug.print("WavHeader.chunk_id: {s}\n", .{self.chunk_id});
        std.debug.print("WavHeader.chunk_size: {d}\n", .{self.chunk_size});
        std.debug.print("WavHeader.riff_type: {s}\n", .{self.riff_type});
    }
};

pub const FormatChunk = struct {
    const Self = @This();

    chunk_id: [4]u8,
    chunk_size: u32,

    format_tag: u16,
    num_channels: u16,
    sample_rate: u32,
    avg_bytes_per_sec: u32,
    block_align: u16,
    bits_per_sample: u16,

    pub fn read(self: *Self, file: std.fs.File) !void {
        self.chunk_id = try file.reader().readBytesNoEof(4);
        if (!std.mem.eql(u8, &self.chunk_id, "fmt ")) return error.Expected_fmt;

        self.chunk_size = try file.reader().readInt(u32, Little);
        if (self.chunk_size != 16) return error.Extra_format_bytes_not_implemented;

        self.format_tag = try file.reader().readInt(u16, Little);

        if (self.format_tag != 0x0001) return error.Unimplemented_format;

        self.num_channels = try file.reader().readInt(u16, Little);
        self.sample_rate = try file.reader().readInt(u32, Little);
        self.avg_bytes_per_sec = try file.reader().readInt(u32, Little);
        self.block_align = try file.reader().readInt(u16, Little);
        self.bits_per_sample = try file.reader().readInt(u16, Little);
    }

    pub fn print(self: Self) void {
        std.debug.print("FormatChunk.chunk_id: {s}\n", .{self.chunk_id});
        std.debug.print("FormatChunk.chunk_size: {d}\n", .{self.chunk_size});

        std.debug.print("FormatChunk.format_tag: {d}\n", .{self.format_tag});
        std.debug.print("FormatChunk.num_channels: {d}\n", .{self.num_channels});
        std.debug.print("FormatChunk.sample_rate: {d}\n", .{self.sample_rate});
        std.debug.print("FormatChunk.avg_bytes_per_sec: {d}\n", .{self.avg_bytes_per_sec});
        std.debug.print("FormatChunk.block_align: {d}\n", .{self.block_align});
        std.debug.print("FormatChunk.bits_per_sample: {d}\n", .{self.bits_per_sample});
    }
};

pub const DataChunk = struct {
    chunk_id: [4]u8,
    chunk_size: u32,

    const Self = @This();

    pub fn read(self: *Self, file: std.fs.File) !void {
        self.chunk_id = try file.reader().readBytesNoEof(4);

        if (!std.mem.eql(u8, &self.chunk_id, "data")) return error.DATA_not_found;

        self.chunk_size = try file.reader().readInt(u32, Little);
    }

    pub fn print(self: Self) void {
        std.debug.print("DataChunk.chunk_id: {s}\n", .{self.chunk_id});
        std.debug.print("DataChunk.chunk_size: {d}\n", .{self.chunk_size});
    }
};

pub fn readWavFile(allocator: Allocator, filename: []const u8, interleave: bool, num_chan: u16) !Audio {

    // NOTE: argument "num_chan" stipulates how we save the wavfile data into our Audio struct.
    // This is NOT dependendent on the number of channels in the wavfile being read.
    //
    // For examples, a two channel wavfile can be saved into Audio struct as a single channel
    // if desired.
    //
    // Similarly, a single channel wavfile could be saved into a two-channel Audio struct

    const file = std.fs.cwd().openFile(
        filename,
        .{ .mode = .read_only },
    ) catch |err| {
        std.log.err("Could not open file \"{s}\"\n", .{filename});
        return err;
    };

    defer file.close();

    const size = (try file.stat()).size;

    var wav_hdr: WavHeader = undefined;
    try wav_hdr.read(file);

    var fmt_ck: FormatChunk = undefined;
    try fmt_ck.read(file);

    var data_ck: DataChunk = undefined;
    try data_ck.read(file);

    if (false) {
        print("file size: {d}\n\n", .{size});
        wav_hdr.print();
        fmt_ck.print();
        data_ck.print();
    }

    const nsamp_per_chan: u32 = data_ck.chunk_size / (fmt_ck.bits_per_sample / 8) / fmt_ck.num_channels;

    var audio = Audio{ .n_chan = num_chan, .nsamp_per_chan = nsamp_per_chan, .interleave = interleave, .sample_rate = fmt_ck.sample_rate };
    try audio.init(allocator);

    const bits_per_sample = fmt_ck.bits_per_sample;

    if ((fmt_ck.num_channels == 1) and (num_chan == 1)) {

        // 1 channel to 1 channel ===========================================================

        var i: usize = 0;
        while (i < nsamp_per_chan) : (i += 1) {
            var tmp: f32 = undefined;

            switch (bits_per_sample) {
                16 => {
                    tmp = @as(f32, @floatFromInt(try file.reader().readInt(i16, Little))) / @as(f32, @floatFromInt(std.math.maxInt(i16)));
                },

                24 => {
                    tmp = @as(f32, @floatFromInt(try file.reader().readInt(i24, Little))) / @as(f32, @floatFromInt(std.math.maxInt(i24)));
                },

                32 => {
                    tmp = @as(f32, @floatFromInt(try file.reader().readInt(i32, Little))) / @as(f32, @floatFromInt(std.math.maxInt(i32)));
                },
                else => {
                    return error.UnExpectedBitsPerSample;
                },
            }
            audio.samples_a[i] = tmp;
        }
    } else if ((fmt_ck.num_channels == 1) and (num_chan == 2)) {

        // 1 channel to 2 channel ===========================================================

        var i: usize = 0;
        while (i < nsamp_per_chan) : (i += 1) {
            var tmp: f32 = undefined;
            switch (bits_per_sample) {
                16 => {
                    tmp = @as(f32, @floatFromInt(try file.reader().readInt(i16, Little))) / @as(f32, @floatFromInt(std.math.maxInt(i16)));
                },

                24 => {
                    tmp = @as(f32, @floatFromInt(try file.reader().readInt(i24, Little))) / @as(f32, @floatFromInt(std.math.maxInt(i24)));
                },

                32 => {
                    tmp = @as(f32, @floatFromInt(try file.reader().readInt(i32, Little))) / @as(f32, @floatFromInt(std.math.maxInt(i32)));
                },

                else => {
                    return error.UnExpectedBitsPerSample;
                },
            }

            if (!interleave) {
                audio.samples_a[i] = tmp;
                audio.samples_b[i] = tmp;
            } else {
                audio.samples_a[2 * i] = tmp;
                audio.samples_a[2 * i + 1] = tmp;
            }
        }
    } else if ((fmt_ck.num_channels == 2) and (num_chan == 1)) {

        // 2 channel to 1 channel ===========================================================

        var i: usize = 0;
        while (i < nsamp_per_chan) : (i += 1) {
            var tmp_a: f32 = undefined;
            var tmp_b: f32 = undefined;
            switch (bits_per_sample) {
                16 => {
                    const mx = @as(f32, @floatFromInt(std.math.maxInt(i16)));
                    tmp_a = @as(f32, @floatFromInt(try file.reader().readInt(i16, Little)));
                    tmp_b = @as(f32, @floatFromInt(try file.reader().readInt(i16, Little)));
                    audio.samples_a[i] = 0.5 * (tmp_a + tmp_b) / mx;
                },
                24 => {
                    const mx = @as(f32, @floatFromInt(std.math.maxInt(i24)));
                    tmp_a = @as(f32, @floatFromInt(try file.reader().readInt(i24, Little)));
                    tmp_b = @as(f32, @floatFromInt(try file.reader().readInt(i24, Little)));
                    audio.samples_a[i] = 0.5 * (tmp_a + tmp_b) / mx;
                },
                32 => {
                    const mx = @as(f32, @floatFromInt(std.math.maxInt(i32)));
                    tmp_a = @as(f32, @floatFromInt(try file.reader().readInt(i32, Little)));
                    tmp_b = @as(f32, @floatFromInt(try file.reader().readInt(i32, Little)));
                    audio.samples_a[i] = 0.5 * (tmp_a + tmp_b) / mx;
                },
                else => {
                    return error.UnExpectedBitsPerSample;
                },
            }
        }
    } else if ((fmt_ck.num_channels == 2) and (num_chan == 2)) {

        // 2 channel to 2 channel ===========================================================

        var i: usize = 0;
        while (i < nsamp_per_chan) : (i += 1) {
            var tmp_a: f32 = undefined;
            var tmp_b: f32 = undefined;

            switch (bits_per_sample) {
                16 => {
                    const mx = @as(f32, @floatFromInt(std.math.maxInt(i16)));
                    tmp_a = @as(f32, @floatFromInt(try file.reader().readInt(i16, Little))) / mx;
                    tmp_b = @as(f32, @floatFromInt(try file.reader().readInt(i16, Little))) / mx;
                },
                24 => {
                    const mx = @as(f32, @floatFromInt(std.math.maxInt(i24)));
                    tmp_a = @as(f32, @floatFromInt(try file.reader().readInt(i24, Little))) / mx;
                    tmp_b = @as(f32, @floatFromInt(try file.reader().readInt(i24, Little))) / mx;
                },
                32 => {
                    const mx = @as(f32, @floatFromInt(std.math.maxInt(i32)));
                    tmp_a = @as(f32, @floatFromInt(try file.reader().readInt(i32, Little))) / mx;
                    tmp_b = @as(f32, @floatFromInt(try file.reader().readInt(i32, Little))) / mx;
                },
                else => {
                    return error.UnExpectedBitsPerSample;
                },
            }

            if (!interleave) {
                audio.samples_a[i] = tmp_a;
                audio.samples_b[i] = tmp_b;
            } else {
                audio.samples_a[2 * i] = tmp_a;
                audio.samples_a[2 * i + 1] = tmp_b;
            }
        }
    }

    return audio;
}

pub fn writeWavFile(filename: []const u8, comptime SampleType: type, audio: Audio) !void {
    if ((SampleType != i16) and (SampleType != i24) and (SampleType != i32)) {
        @compileError("unexpected SampleType");
    }

    const bits_per_sample: u16 = @bitSizeOf(SampleType);
    const bytes_per_sample = bits_per_sample / 8;

    var file = std.fs.cwd().createFile(
        filename,
        .{ .read = true },
    ) catch |err| {
        std.log.err("Could not create file \"{s}\"\n", .{filename});
        return err;
    };

    file = std.fs.cwd().openFile(
        filename,
        .{ .mode = .write_only },
    ) catch |err| {
        std.log.err("Could not open file \"{s}\"\n", .{filename});
        return err;
    };

    const nBytes: u32 = @as(u32, audio.nsamp_per_chan) * @as(u32, audio.n_chan) * bytes_per_sample;

    const format_tag: u16 = 1;
    const avg_bytes_per_sec: u32 = audio.sample_rate * bytes_per_sample * audio.n_chan;
    const block_align: u16 = bytes_per_sample * audio.n_chan;

    const fmt_chunksize: u32 = 16;

    _ = try file.writer().write("RIFF");
    _ = try file.writer().writeInt(u32, nBytes + 36, Little);
    _ = try file.writer().write("WAVE");
    _ = try file.writer().write("fmt ");
    _ = try file.writer().writeInt(u32, fmt_chunksize, Little);
    _ = try file.writer().writeInt(u16, format_tag, Little);
    _ = try file.writer().writeInt(u16, audio.n_chan, Little);
    _ = try file.writer().writeInt(u32, audio.sample_rate, Little);
    _ = try file.writer().writeInt(u32, avg_bytes_per_sec, Little);
    _ = try file.writer().writeInt(u16, block_align, Little);
    _ = try file.writer().writeInt(u16, bits_per_sample, Little);

    _ = try file.writer().write("data");
    _ = try file.writer().writeInt(u32, nBytes, Little);

    var val_tmp: SampleType = undefined;
    const mx = @as(f32, @floatFromInt(std.math.maxInt(SampleType)));

    switch (audio.n_chan) {
        1 => {
            var i: usize = 0;
            while (i < audio.nsamp_per_chan) : (i += 1) {
                val_tmp = @intFromFloat(mx * audio.samples_a[i]);
                _ = try file.writer().writeInt(SampleType, val_tmp, Little);
            }
        },

        2 => {
            switch (audio.interleave) {
                false => {
                    var i: usize = 0;
                    while (i < audio.nsamp_per_chan) : (i += 1) {
                        val_tmp = @intFromFloat(mx * audio.samples_a[i]);
                        _ = try file.writer().writeInt(SampleType, val_tmp, Little);

                        val_tmp = @intFromFloat(mx * audio.samples_b[i]);
                        _ = try file.writer().writeInt(SampleType, val_tmp, Little);
                    }
                },

                true => {
                    var i: usize = 0;
                    while (i < audio.nsamp_per_chan) : (i += 1) {
                        val_tmp = @intFromFloat(mx * audio.samples_a[2 * i]);
                        _ = try file.writer().writeInt(SampleType, val_tmp, Little);

                        val_tmp = @intFromFloat(mx * audio.samples_a[2 * i + 1]);
                        _ = try file.writer().writeInt(SampleType, val_tmp, Little);
                    }
                },
            }
        },

        else => {},
    }

    defer file.close();
}
