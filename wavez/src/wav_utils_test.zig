const std = @import("std");
const print = std.debug.print;
const wav_utils = @import("wavez_import_name");

const maxInt = std.math.maxInt;

test "WavHeader and FormatChunk testing" {
    const filename = "wavfiles/one_channel_1000_16bit.wav";
    const file = std.fs.cwd().openFile(
        filename,
        .{ .mode = .read_only },
    ) catch |err| {
        std.log.err("Could not open file \"{s}\"\n", .{filename});
        return err;
    };

    defer file.close();

    var wav_hdr: wav_utils.WavHeader = undefined;
    var fmt_ck: wav_utils.FormatChunk = undefined;

    try wav_hdr.read(file);
    try fmt_ck.read(file);

    if (true) {
        print("\n", .{});
        wav_hdr.print();
        print("\n", .{});
        fmt_ck.print();
    }

    // wav header
    try std.testing.expect(std.mem.eql(u8, &wav_hdr.riff_type, "WAVE"));
    try std.testing.expect(std.mem.eql(u8, &wav_hdr.chunk_id, "RIFF"));
    try std.testing.expectEqual(@as(u32, 136), wav_hdr.chunk_size);

    // format chunk
    try std.testing.expect(std.mem.eql(u8, &fmt_ck.chunk_id, "fmt "));
    try std.testing.expectEqual(@as(u32, 16), fmt_ck.chunk_size);
    try std.testing.expectEqual(@as(u16, 1), fmt_ck.format_tag);
    try std.testing.expectEqual(@as(u16, 1), fmt_ck.num_channels);
    try std.testing.expectEqual(@as(u32, 44100), fmt_ck.sample_rate);
    try std.testing.expectEqual(@as(u32, 88200), fmt_ck.avg_bytes_per_sec);
    try std.testing.expectEqual(@as(u16, 2), fmt_ck.block_align);
    try std.testing.expectEqual(@as(u16, 16), fmt_ck.bits_per_sample);
}

test "readWavFile one-channel to one-channel testing" {
    const filename = [_][]const u8{
        "wavfiles/one_channel_1000_16bit.wav",
        "wavfiles/one_channel_1000_24bit.wav",
        "wavfiles/one_channel_1000_32bit.wav",
    };

    const wav_bits_per_sample = [_]comptime_int{
        16,
        24,
        32,
    };

    const interleave = [_]bool{
        false,
        true,
    };
    const num_chan = 1;

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    inline for (filename, 0..) |fname, i| {
        print("\none-channel wavfile to one-channel audio test\n", .{});
        inline for (interleave) |inter| {
            print("filename[{d}]: {s}, inter: {any}\n", .{ i, fname, inter });

            const aud = try wav_utils.readWavFile(allocator, fname, inter, num_chan);

            if (false) {
                print("\n", .{});
                std.debug.print("sample rate: {d}\n", .{aud.sample_rate});
                const nsamp = 10;
                for (0..nsamp) |j| {
                    std.debug.print("{d}\n", .{aud.samples_a[j]});
                }
            }

            try std.testing.expectEqual(@as(u32, 44100), aud.sample_rate);

            switch (wav_bits_per_sample[i]) {
                16 => {
                    // one_channel_1000_16bit.wav:
                    const mx = @as(f32, std.math.maxInt(i16));
                    try std.testing.expectEqual(@as(f32, 0) / mx, aud.samples_a[0]);
                    try std.testing.expectEqual(@as(f32, 4653) / mx, aud.samples_a[1]);
                    try std.testing.expectEqual(@as(f32, 9211) / mx, aud.samples_a[2]);
                    try std.testing.expectEqual(@as(f32, 13584) / mx, aud.samples_a[3]);
                    try std.testing.expectEqual(@as(f32, 17680) / mx, aud.samples_a[4]);
                    try std.testing.expectEqual(@as(f32, 21418) / mx, aud.samples_a[5]);
                    try std.testing.expectEqual(@as(f32, 24723) / mx, aud.samples_a[6]);
                    try std.testing.expectEqual(@as(f32, 27525) / mx, aud.samples_a[7]);
                    try std.testing.expectEqual(@as(f32, 29773) / mx, aud.samples_a[8]);
                    try std.testing.expectEqual(@as(f32, 31413) / mx, aud.samples_a[9]);
                },

                24 => {
                    // one_channel_1000_24bit.wav:
                    const mx = @as(f32, std.math.maxInt(i24));
                    try std.testing.expectEqual(@as(f32, 0) / mx, aud.samples_a[0]);
                    try std.testing.expectEqual(@as(f32, 1191134) / mx, aud.samples_a[1]);
                    try std.testing.expectEqual(@as(f32, 2358131) / mx, aud.samples_a[2]);
                    try std.testing.expectEqual(@as(f32, 3477339) / mx, aud.samples_a[3]);
                    try std.testing.expectEqual(@as(f32, 4526079) / mx, aud.samples_a[4]);
                    try std.testing.expectEqual(@as(f32, 5483098) / mx, aud.samples_a[5]);
                    try std.testing.expectEqual(@as(f32, 6329002) / mx, aud.samples_a[6]);
                    try std.testing.expectEqual(@as(f32, 7046648) / mx, aud.samples_a[7]);
                    try std.testing.expectEqual(@as(f32, 7621493) / mx, aud.samples_a[8]);
                    try std.testing.expectEqual(@as(f32, 8041889) / mx, aud.samples_a[9]);
                },

                32 => {
                    // one_channel_1000_32bit.wav:
                    const mx = @as(f32, std.math.maxInt(i32));
                    try std.testing.expectEqual(@as(f32, 0) / mx, aud.samples_a[0]);
                    try std.testing.expectEqual(@as(f32, 304930464) / mx, aud.samples_a[1]);
                    try std.testing.expectEqual(@as(f32, 603681536) / mx, aud.samples_a[2]);
                    try std.testing.expectEqual(@as(f32, 890198912) / mx, aud.samples_a[3]);
                    try std.testing.expectEqual(@as(f32, 1158676352) / mx, aud.samples_a[4]);
                    try std.testing.expectEqual(@as(f32, 1403673216) / mx, aud.samples_a[5]);
                    try std.testing.expectEqual(@as(f32, 1620224512) / mx, aud.samples_a[6]);
                    try std.testing.expectEqual(@as(f32, 1803941888) / mx, aud.samples_a[7]);
                    try std.testing.expectEqual(@as(f32, 1951102336) / mx, aud.samples_a[8]);
                    try std.testing.expectEqual(@as(f32, 2058723584) / mx, aud.samples_a[9]);
                },

                else => {
                    return error.UnexpectedBitsPerSample;
                },
            }
        }
    }
}

test "readWavFile one-channel to two-channel testing" {
    const filename = [_][]const u8{
        "wavfiles/one_channel_1000_16bit.wav",
        "wavfiles/one_channel_1000_24bit.wav",
        "wavfiles/one_channel_1000_32bit.wav",
    };

    const wav_bits_per_sample = [_]comptime_int{
        16,
        24,
        32,
    };
    const interleave = [_]bool{
        false,
        true,
    };
    const num_chan = 2;

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    inline for (filename, 0..) |fname, i| {
        print("\none-channel wavfile to two-channel audio test\n", .{});
        inline for (interleave) |inter| {
            print("filename[{d}]: {s}, inter: {any}\n", .{ i, fname, inter });

            const aud = try wav_utils.readWavFile(allocator, fname, inter, num_chan);

            if (false) {
                print("\n", .{});
                std.debug.print("sample rate: {d}\n", .{aud.sample_rate});
                const nsamp = 10;
                for (0..nsamp) |j| {
                    std.debug.print("{d}\n", .{aud.samples_a[j]});
                }
            }

            try std.testing.expectEqual(@as(u32, 44100), aud.sample_rate);

            switch (wav_bits_per_sample[i]) {
                16 => {
                    switch (inter) {
                        false => {
                            // one_channel_1000_16bit.wav:
                            const mx = @as(f32, std.math.maxInt(i16));
                            try std.testing.expectEqual(@as(f32, 0) / mx, aud.samples_a[0]);
                            try std.testing.expectEqual(@as(f32, 4653) / mx, aud.samples_a[1]);
                            try std.testing.expectEqual(@as(f32, 9211) / mx, aud.samples_a[2]);
                            try std.testing.expectEqual(@as(f32, 13584) / mx, aud.samples_a[3]);
                            try std.testing.expectEqual(@as(f32, 17680) / mx, aud.samples_a[4]);
                            try std.testing.expectEqual(@as(f32, 21418) / mx, aud.samples_a[5]);
                            try std.testing.expectEqual(@as(f32, 24723) / mx, aud.samples_a[6]);
                            try std.testing.expectEqual(@as(f32, 27525) / mx, aud.samples_a[7]);
                            try std.testing.expectEqual(@as(f32, 29773) / mx, aud.samples_a[8]);
                            try std.testing.expectEqual(@as(f32, 31413) / mx, aud.samples_a[9]);

                            try std.testing.expectEqual(@as(f32, 0) / mx, aud.samples_b[0]);
                            try std.testing.expectEqual(@as(f32, 4653) / mx, aud.samples_b[1]);
                            try std.testing.expectEqual(@as(f32, 9211) / mx, aud.samples_b[2]);
                            try std.testing.expectEqual(@as(f32, 13584) / mx, aud.samples_b[3]);
                            try std.testing.expectEqual(@as(f32, 17680) / mx, aud.samples_b[4]);
                            try std.testing.expectEqual(@as(f32, 21418) / mx, aud.samples_b[5]);
                            try std.testing.expectEqual(@as(f32, 24723) / mx, aud.samples_b[6]);
                            try std.testing.expectEqual(@as(f32, 27525) / mx, aud.samples_b[7]);
                            try std.testing.expectEqual(@as(f32, 29773) / mx, aud.samples_b[8]);
                            try std.testing.expectEqual(@as(f32, 31413) / mx, aud.samples_b[9]);
                        },

                        true => {
                            // one_channel_1000_16bit.wav:
                            const mx = @as(f32, std.math.maxInt(i16));
                            try std.testing.expectEqual(@as(f32, 0) / mx, aud.samples_a[0]);
                            try std.testing.expectEqual(@as(f32, 0) / mx, aud.samples_a[1]);
                            try std.testing.expectEqual(@as(f32, 4653) / mx, aud.samples_a[2]);
                            try std.testing.expectEqual(@as(f32, 4653) / mx, aud.samples_a[3]);
                            try std.testing.expectEqual(@as(f32, 9211) / mx, aud.samples_a[4]);
                            try std.testing.expectEqual(@as(f32, 9211) / mx, aud.samples_a[5]);
                            try std.testing.expectEqual(@as(f32, 13584) / mx, aud.samples_a[6]);
                            try std.testing.expectEqual(@as(f32, 13584) / mx, aud.samples_a[7]);
                            try std.testing.expectEqual(@as(f32, 17680) / mx, aud.samples_a[8]);
                            try std.testing.expectEqual(@as(f32, 17680) / mx, aud.samples_a[9]);
                            try std.testing.expectEqual(@as(f32, 21418) / mx, aud.samples_a[10]);
                            try std.testing.expectEqual(@as(f32, 21418) / mx, aud.samples_a[11]);
                            try std.testing.expectEqual(@as(f32, 24723) / mx, aud.samples_a[12]);
                            try std.testing.expectEqual(@as(f32, 24723) / mx, aud.samples_a[13]);
                            try std.testing.expectEqual(@as(f32, 27525) / mx, aud.samples_a[14]);
                            try std.testing.expectEqual(@as(f32, 27525) / mx, aud.samples_a[15]);
                            try std.testing.expectEqual(@as(f32, 29773) / mx, aud.samples_a[16]);
                            try std.testing.expectEqual(@as(f32, 29773) / mx, aud.samples_a[17]);
                            try std.testing.expectEqual(@as(f32, 31413) / mx, aud.samples_a[18]);
                            try std.testing.expectEqual(@as(f32, 31413) / mx, aud.samples_a[19]);
                        },
                    }
                },

                24 => {
                    switch (inter) {
                        false => {
                            // one_channel_1000_24bit.wav:
                            const mx = @as(f32, std.math.maxInt(i24));
                            try std.testing.expectEqual(@as(f32, 0) / mx, aud.samples_a[0]);
                            try std.testing.expectEqual(@as(f32, 1191134) / mx, aud.samples_a[1]);
                            try std.testing.expectEqual(@as(f32, 2358131) / mx, aud.samples_a[2]);
                            try std.testing.expectEqual(@as(f32, 3477339) / mx, aud.samples_a[3]);
                            try std.testing.expectEqual(@as(f32, 4526079) / mx, aud.samples_a[4]);
                            try std.testing.expectEqual(@as(f32, 5483098) / mx, aud.samples_a[5]);
                            try std.testing.expectEqual(@as(f32, 6329002) / mx, aud.samples_a[6]);
                            try std.testing.expectEqual(@as(f32, 7046648) / mx, aud.samples_a[7]);
                            try std.testing.expectEqual(@as(f32, 7621493) / mx, aud.samples_a[8]);
                            try std.testing.expectEqual(@as(f32, 8041889) / mx, aud.samples_a[9]);

                            try std.testing.expectEqual(@as(f32, 0) / mx, aud.samples_b[0]);
                            try std.testing.expectEqual(@as(f32, 1191134) / mx, aud.samples_b[1]);
                            try std.testing.expectEqual(@as(f32, 2358131) / mx, aud.samples_b[2]);
                            try std.testing.expectEqual(@as(f32, 3477339) / mx, aud.samples_b[3]);
                            try std.testing.expectEqual(@as(f32, 4526079) / mx, aud.samples_b[4]);
                            try std.testing.expectEqual(@as(f32, 5483098) / mx, aud.samples_b[5]);
                            try std.testing.expectEqual(@as(f32, 6329002) / mx, aud.samples_b[6]);
                            try std.testing.expectEqual(@as(f32, 7046648) / mx, aud.samples_b[7]);
                            try std.testing.expectEqual(@as(f32, 7621493) / mx, aud.samples_b[8]);
                            try std.testing.expectEqual(@as(f32, 8041889) / mx, aud.samples_b[9]);
                        },

                        true => {
                            // one_channel_1000_24bit.wav:
                            const mx = @as(f32, std.math.maxInt(i24));
                            try std.testing.expectEqual(@as(f32, 0) / mx, aud.samples_a[0]);
                            try std.testing.expectEqual(@as(f32, 0) / mx, aud.samples_a[1]);
                            try std.testing.expectEqual(@as(f32, 1191134) / mx, aud.samples_a[2]);
                            try std.testing.expectEqual(@as(f32, 1191134) / mx, aud.samples_a[3]);
                            try std.testing.expectEqual(@as(f32, 2358131) / mx, aud.samples_a[4]);
                            try std.testing.expectEqual(@as(f32, 2358131) / mx, aud.samples_a[5]);
                            try std.testing.expectEqual(@as(f32, 3477339) / mx, aud.samples_a[6]);
                            try std.testing.expectEqual(@as(f32, 3477339) / mx, aud.samples_a[7]);
                            try std.testing.expectEqual(@as(f32, 4526079) / mx, aud.samples_a[8]);
                            try std.testing.expectEqual(@as(f32, 4526079) / mx, aud.samples_a[9]);
                            try std.testing.expectEqual(@as(f32, 5483098) / mx, aud.samples_a[10]);
                            try std.testing.expectEqual(@as(f32, 5483098) / mx, aud.samples_a[11]);
                            try std.testing.expectEqual(@as(f32, 6329002) / mx, aud.samples_a[12]);
                            try std.testing.expectEqual(@as(f32, 6329002) / mx, aud.samples_a[13]);
                            try std.testing.expectEqual(@as(f32, 7046648) / mx, aud.samples_a[14]);
                            try std.testing.expectEqual(@as(f32, 7046648) / mx, aud.samples_a[15]);
                            try std.testing.expectEqual(@as(f32, 7621493) / mx, aud.samples_a[16]);
                            try std.testing.expectEqual(@as(f32, 7621493) / mx, aud.samples_a[17]);
                            try std.testing.expectEqual(@as(f32, 8041889) / mx, aud.samples_a[18]);
                            try std.testing.expectEqual(@as(f32, 8041889) / mx, aud.samples_a[19]);
                        },
                    }
                },

                32 => {
                    switch (inter) {
                        false => {
                            // one_channel_1000_32bit.wav:
                            const mx = @as(f32, std.math.maxInt(i32));
                            try std.testing.expectEqual(@as(f32, 0) / mx, aud.samples_a[0]);
                            try std.testing.expectEqual(@as(f32, 304930464) / mx, aud.samples_a[1]);
                            try std.testing.expectEqual(@as(f32, 603681536) / mx, aud.samples_a[2]);
                            try std.testing.expectEqual(@as(f32, 890198912) / mx, aud.samples_a[3]);
                            try std.testing.expectEqual(@as(f32, 1158676352) / mx, aud.samples_a[4]);
                            try std.testing.expectEqual(@as(f32, 1403673216) / mx, aud.samples_a[5]);
                            try std.testing.expectEqual(@as(f32, 1620224512) / mx, aud.samples_a[6]);
                            try std.testing.expectEqual(@as(f32, 1803941888) / mx, aud.samples_a[7]);
                            try std.testing.expectEqual(@as(f32, 1951102336) / mx, aud.samples_a[8]);
                            try std.testing.expectEqual(@as(f32, 2058723584) / mx, aud.samples_a[9]);

                            try std.testing.expectEqual(@as(f32, 0) / mx, aud.samples_b[0]);
                            try std.testing.expectEqual(@as(f32, 304930464) / mx, aud.samples_b[1]);
                            try std.testing.expectEqual(@as(f32, 603681536) / mx, aud.samples_b[2]);
                            try std.testing.expectEqual(@as(f32, 890198912) / mx, aud.samples_b[3]);
                            try std.testing.expectEqual(@as(f32, 1158676352) / mx, aud.samples_b[4]);
                            try std.testing.expectEqual(@as(f32, 1403673216) / mx, aud.samples_b[5]);
                            try std.testing.expectEqual(@as(f32, 1620224512) / mx, aud.samples_b[6]);
                            try std.testing.expectEqual(@as(f32, 1803941888) / mx, aud.samples_b[7]);
                            try std.testing.expectEqual(@as(f32, 1951102336) / mx, aud.samples_b[8]);
                            try std.testing.expectEqual(@as(f32, 2058723584) / mx, aud.samples_b[9]);
                        },

                        true => {
                            // one_channel_1000_32bit.wav:
                            const mx = @as(f32, std.math.maxInt(i32));
                            try std.testing.expectEqual(@as(f32, 0) / mx, aud.samples_a[0]);
                            try std.testing.expectEqual(@as(f32, 0) / mx, aud.samples_a[1]);
                            try std.testing.expectEqual(@as(f32, 304930464) / mx, aud.samples_a[2]);
                            try std.testing.expectEqual(@as(f32, 304930464) / mx, aud.samples_a[3]);
                            try std.testing.expectEqual(@as(f32, 603681536) / mx, aud.samples_a[4]);
                            try std.testing.expectEqual(@as(f32, 603681536) / mx, aud.samples_a[5]);
                            try std.testing.expectEqual(@as(f32, 890198912) / mx, aud.samples_a[6]);
                            try std.testing.expectEqual(@as(f32, 890198912) / mx, aud.samples_a[7]);
                            try std.testing.expectEqual(@as(f32, 1158676352) / mx, aud.samples_a[8]);
                            try std.testing.expectEqual(@as(f32, 1158676352) / mx, aud.samples_a[9]);
                            try std.testing.expectEqual(@as(f32, 1403673216) / mx, aud.samples_a[10]);
                            try std.testing.expectEqual(@as(f32, 1403673216) / mx, aud.samples_a[11]);
                            try std.testing.expectEqual(@as(f32, 1620224512) / mx, aud.samples_a[12]);
                            try std.testing.expectEqual(@as(f32, 1620224512) / mx, aud.samples_a[13]);
                            try std.testing.expectEqual(@as(f32, 1803941888) / mx, aud.samples_a[14]);
                            try std.testing.expectEqual(@as(f32, 1803941888) / mx, aud.samples_a[15]);
                            try std.testing.expectEqual(@as(f32, 1951102336) / mx, aud.samples_a[16]);
                            try std.testing.expectEqual(@as(f32, 1951102336) / mx, aud.samples_a[17]);
                            try std.testing.expectEqual(@as(f32, 2058723584) / mx, aud.samples_a[18]);
                            try std.testing.expectEqual(@as(f32, 2058723584) / mx, aud.samples_a[19]);
                        },
                    }
                },

                else => {
                    return error.UnexpectedBitsPerSample;
                },
            }
        }
    }
}

test "readWavFile two-channel to one-channel testing" {
    const expect = std.testing.expectEqual;
    const inter = false;

    const filename = [_][]const u8{
        "wavfiles/two_channel_1000_1111_16bit.wav",
        "wavfiles/two_channel_1000_1111_24bit.wav",
        "wavfiles/two_channel_1000_1111_32bit.wav",
    };

    const wav_bits_per_sample = [_]u16{ 16, 24, 32 };
    const num_chan = 1;

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    inline for (filename, 0..) |fname, i| {
        print("\ntwo-channel wavfile to one-channel audio test\n", .{});

        print("filename[{d}]: {s}, inter: {any}\n", .{ i, fname, inter });

        const aud = try wav_utils.readWavFile(allocator, fname, inter, num_chan);

        if (false) {
            print("\n", .{});
            std.debug.print("sample rate: {d}\n", .{aud.sample_rate});
            const nsamp = 10;
            for (0..nsamp) |j| {
                std.debug.print("{d}\n", .{aud.samples_a[j]});
            }
        }

        try std.testing.expectEqual(@as(u32, 44100), aud.sample_rate);

        switch (wav_bits_per_sample[i]) {
            16 => {
                // two_channel_1000_1111_16bit.wav:
                const mx = @as(f32, std.math.maxInt(i16));
                try expect(@as(f32, 0 + 1) / mx, 2 * aud.samples_a[0]);
                try expect(@as(f32, 4652 + 5162) / mx, 2 * aud.samples_a[1]);
                try expect(@as(f32, 9213 + 10206) / mx, 2 * aud.samples_a[2]);
                try expect(@as(f32, 13582 + 14977) / mx, 2 * aud.samples_a[3]);
                try expect(@as(f32, 17682 + 19394) / mx, 2 * aud.samples_a[4]);
                try expect(@as(f32, 21416 + 23306) / mx, 2 * aud.samples_a[5]);
                try expect(@as(f32, 24724 + 26653) / mx, 2 * aud.samples_a[6]);
                try expect(@as(f32, 27525 + 29318) / mx, 2 * aud.samples_a[7]);
                try expect(@as(f32, 29773 + 31264) / mx, 2 * aud.samples_a[8]);
                try expect(@as(f32, 31412 + 32417) / mx, 2 * aud.samples_a[9]);
            },

            24 => {
                // two_channel_1000_1111_24bit.wav:
                const mx = @as(f32, std.math.maxInt(i24));
                try expect(@as(f32, 0 + 0) / mx, 2 * aud.samples_a[0]);
                try expect(@as(f32, 1191134 + 1322300) / mx, 2 * aud.samples_a[1]);
                try expect(@as(f32, 2358131 + 2611538) / mx, 2 * aud.samples_a[2]);
                try expect(@as(f32, 3477339 + 3835478) / mx, 2 * aud.samples_a[3]);
                try expect(@as(f32, 4526079 + 4963517) / mx, 2 * aud.samples_a[4]);
                try expect(@as(f32, 5483098 + 5967450) / mx, 2 * aud.samples_a[5]);
                try expect(@as(f32, 6329002 + 6822174) / mx, 2 * aud.samples_a[6]);
                try expect(@as(f32, 7046648 + 7506320) / mx, 2 * aud.samples_a[7]);
                try expect(@as(f32, 7621493 + 8002780) / mx, 2 * aud.samples_a[8]);
                try expect(@as(f32, 8041889 + 8299141) / mx, 2 * aud.samples_a[9]);
            },

            32 => {
                // two_channel_1000_1111_32bit.wav:
                const mx = @as(f32, std.math.maxInt(i32));
                try expect(@as(f32, 0 + 0) / mx, 2 * aud.samples_a[0]);
                try expect(@as(f32, 304930304 + 338508800) / mx, 2 * aud.samples_a[1]);
                try expect(@as(f32, 603681536 + 668553728) / mx, 2 * aud.samples_a[2]);
                try expect(@as(f32, 890198784 + 981882368) / mx, 2 * aud.samples_a[3]);
                try expect(@as(f32, 1158676224 + 1270660352) / mx, 2 * aud.samples_a[4]);
                try expect(@as(f32, 1403673088 + 1527667200) / mx, 2 * aud.samples_a[5]);
                try expect(@as(f32, 1620224512 + 1746476544) / mx, 2 * aud.samples_a[6]);
                try expect(@as(f32, 1803941888 + 1921617920) / mx, 2 * aud.samples_a[7]);
                try expect(@as(f32, 1951102208 + 2048711680) / mx, 2 * aud.samples_a[8]);
                try expect(@as(f32, 2058723584 + 2124580096) / mx, 2 * aud.samples_a[9]);
            },

            else => {
                return error.UnexpectedBitsPerSample;
            },
        }
    }
}

test "readWavFile two-channel to two-channel interleaved testing" {
    const expect = std.testing.expectEqual;

    const filename = [_][]const u8{
        "wavfiles/two_channel_1000_1111_16bit.wav",
        "wavfiles/two_channel_1000_1111_24bit.wav",
        "wavfiles/two_channel_1000_1111_32bit.wav",
    };

    const wav_bits_per_sample = [_]comptime_int{
        16,
        24,
        32,
    };

    const interleave = true;
    const num_chan = 2;

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    inline for (filename, 0..) |fname, i| {
        print("\ntwo-channel wavfile to two-channel audio test\n", .{});

        print("filename[{d}]: {s}, inter: {any}\n", .{ i, fname, interleave });

        const aud = try wav_utils.readWavFile(allocator, fname, interleave, num_chan);

        if (false) {
            print("\n", .{});
            std.debug.print("sample rate: {d}\n", .{aud.sample_rate});
            const nsamp = 10;
            for (0..nsamp) |j| {
                std.debug.print("{d}\n", .{aud.samples_a[j]});
            }
        }

        try std.testing.expectEqual(@as(u32, 44100), aud.sample_rate);

        switch (wav_bits_per_sample[i]) {
            16 => {

                // two_channel_1000_1111_16bit.wav:
                const mx = @as(f32, std.math.maxInt(i16));
                try expect(@as(f32, 0) / mx, aud.samples_a[0]);
                try expect(@as(f32, 1) / mx, aud.samples_a[1]);

                try expect(@as(f32, 4652) / mx, aud.samples_a[2]);
                try expect(@as(f32, 5162) / mx, aud.samples_a[3]);

                try expect(@as(f32, 9213) / mx, aud.samples_a[4]);
                try expect(@as(f32, 10206) / mx, aud.samples_a[5]);

                try expect(@as(f32, 13582) / mx, aud.samples_a[6]);
                try expect(@as(f32, 14977) / mx, aud.samples_a[7]);

                try expect(@as(f32, 17682) / mx, aud.samples_a[8]);
                try expect(@as(f32, 19394) / mx, aud.samples_a[9]);

                try expect(@as(f32, 21416) / mx, aud.samples_a[10]);
                try expect(@as(f32, 23306) / mx, aud.samples_a[11]);

                try expect(@as(f32, 24724) / mx, aud.samples_a[12]);
                try expect(@as(f32, 26653) / mx, aud.samples_a[13]);

                try expect(@as(f32, 27525) / mx, aud.samples_a[14]);
                try expect(@as(f32, 29318) / mx, aud.samples_a[15]);

                try expect(@as(f32, 29773) / mx, aud.samples_a[16]);
                try expect(@as(f32, 31264) / mx, aud.samples_a[17]);

                try expect(@as(f32, 31412) / mx, aud.samples_a[18]);
                try expect(@as(f32, 32417) / mx, aud.samples_a[19]);
            },

            24 => {
                // two_channel_1000_1111_24bit.wav:
                const mx = @as(f32, std.math.maxInt(i24));
                try expect(@as(f32, 0) / mx, aud.samples_a[0]);
                try expect(@as(f32, 0) / mx, aud.samples_a[1]);

                try expect(@as(f32, 1191134) / mx, aud.samples_a[2]);
                try expect(@as(f32, 1322300) / mx, aud.samples_a[3]);

                try expect(@as(f32, 2358131) / mx, aud.samples_a[4]);
                try expect(@as(f32, 2611538) / mx, aud.samples_a[5]);

                try expect(@as(f32, 3477339) / mx, aud.samples_a[6]);
                try expect(@as(f32, 3835478) / mx, aud.samples_a[7]);

                try expect(@as(f32, 4526079) / mx, aud.samples_a[8]);
                try expect(@as(f32, 4963517) / mx, aud.samples_a[9]);

                try expect(@as(f32, 5483098) / mx, aud.samples_a[10]);
                try expect(@as(f32, 5967450) / mx, aud.samples_a[11]);

                try expect(@as(f32, 6329002) / mx, aud.samples_a[12]);
                try expect(@as(f32, 6822174) / mx, aud.samples_a[13]);

                try expect(@as(f32, 7046648) / mx, aud.samples_a[14]);
                try expect(@as(f32, 7506320) / mx, aud.samples_a[15]);

                try expect(@as(f32, 7621493) / mx, aud.samples_a[16]);
                try expect(@as(f32, 8002780) / mx, aud.samples_a[17]);

                try expect(@as(f32, 8041889) / mx, aud.samples_a[18]);
                try expect(@as(f32, 8299141) / mx, aud.samples_a[19]);
            },

            32 => {
                // two_channel_1000_1111_32bit.wav:
                const mx = @as(f32, std.math.maxInt(i32));
                try expect(@as(f32, 0) / mx, aud.samples_a[0]);
                try expect(@as(f32, 0) / mx, aud.samples_a[1]);

                try expect(@as(f32, 304930304) / mx, aud.samples_a[2]);
                try expect(@as(f32, 338508800) / mx, aud.samples_a[3]);

                try expect(@as(f32, 603681536) / mx, aud.samples_a[4]);
                try expect(@as(f32, 668553728) / mx, aud.samples_a[5]);

                try expect(@as(f32, 890198784) / mx, aud.samples_a[6]);
                try expect(@as(f32, 981882368) / mx, aud.samples_a[7]);

                try expect(@as(f32, 1158676224) / mx, aud.samples_a[8]);
                try expect(@as(f32, 1270660352) / mx, aud.samples_a[9]);

                try expect(@as(f32, 1403673088) / mx, aud.samples_a[10]);
                try expect(@as(f32, 1527667200) / mx, aud.samples_a[11]);

                try expect(@as(f32, 1620224512) / mx, aud.samples_a[12]);
                try expect(@as(f32, 1746476544) / mx, aud.samples_a[13]);

                try expect(@as(f32, 1803941888) / mx, aud.samples_a[14]);
                try expect(@as(f32, 1921617920) / mx, aud.samples_a[15]);

                try expect(@as(f32, 1951102208) / mx, aud.samples_a[16]);
                try expect(@as(f32, 2048711680) / mx, aud.samples_a[17]);

                try expect(@as(f32, 2058723584) / mx, aud.samples_a[18]);
                try expect(@as(f32, 2124580096) / mx, aud.samples_a[19]);
            },

            else => {
                return error.UnexpectedBitsPerSample;
            },
        }
    }
}

test "readWavFile two-channel to two-channel non-interleaved testing" {
    const expect = std.testing.expectEqual;

    const filename = [_][]const u8{
        "wavfiles/two_channel_1000_1111_16bit.wav",
        "wavfiles/two_channel_1000_1111_24bit.wav",
        "wavfiles/two_channel_1000_1111_32bit.wav",
    };

    const wav_bits_per_sample = [_]comptime_int{
        16,
        24,
        32,
    };

    const interleave = false;
    const num_chan = 2;

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    inline for (filename, 0..) |fname, i| {
        print("\ntwo-channel wavfile to two-channel audio test\n", .{});

        print("filename[{d}]: {s}, inter: {any}\n", .{ i, fname, interleave });

        const aud = try wav_utils.readWavFile(allocator, fname, interleave, num_chan);

        if (false) {
            print("\n", .{});
            std.debug.print("sample rate: {d}\n", .{aud.sample_rate});
            const nsamp = 10;
            for (0..nsamp) |j| {
                std.debug.print("{d}\n", .{aud.samples_a[j]});
            }
        }

        try std.testing.expectEqual(@as(u32, 44100), aud.sample_rate);

        switch (wav_bits_per_sample[i]) {
            16 => {

                // two_channel_1000_1111_16bit.wav:
                const mx = @as(f32, std.math.maxInt(i16));
                try expect(@as(f32, 0) / mx, aud.samples_a[0]);
                try expect(@as(f32, 1) / mx, aud.samples_b[0]);

                try expect(@as(f32, 4652) / mx, aud.samples_a[1]);
                try expect(@as(f32, 5162) / mx, aud.samples_b[1]);

                try expect(@as(f32, 9213) / mx, aud.samples_a[2]);
                try expect(@as(f32, 10206) / mx, aud.samples_b[2]);

                try expect(@as(f32, 13582) / mx, aud.samples_a[3]);
                try expect(@as(f32, 14977) / mx, aud.samples_b[3]);

                try expect(@as(f32, 17682) / mx, aud.samples_a[4]);
                try expect(@as(f32, 19394) / mx, aud.samples_b[4]);

                try expect(@as(f32, 21416) / mx, aud.samples_a[5]);
                try expect(@as(f32, 23306) / mx, aud.samples_b[5]);

                try expect(@as(f32, 24724) / mx, aud.samples_a[6]);
                try expect(@as(f32, 26653) / mx, aud.samples_b[6]);

                try expect(@as(f32, 27525) / mx, aud.samples_a[7]);
                try expect(@as(f32, 29318) / mx, aud.samples_b[7]);

                try expect(@as(f32, 29773) / mx, aud.samples_a[8]);
                try expect(@as(f32, 31264) / mx, aud.samples_b[8]);

                try expect(@as(f32, 31412) / mx, aud.samples_a[9]);
                try expect(@as(f32, 32417) / mx, aud.samples_b[9]);
            },

            24 => {
                // two_channel_1000_1111_24bit.wav:
                const mx = @as(f32, std.math.maxInt(i24));
                try expect(@as(f32, 0) / mx, aud.samples_a[0]);
                try expect(@as(f32, 0) / mx, aud.samples_b[0]);

                try expect(@as(f32, 1191134) / mx, aud.samples_a[1]);
                try expect(@as(f32, 1322300) / mx, aud.samples_b[1]);

                try expect(@as(f32, 2358131) / mx, aud.samples_a[2]);
                try expect(@as(f32, 2611538) / mx, aud.samples_b[2]);

                try expect(@as(f32, 3477339) / mx, aud.samples_a[3]);
                try expect(@as(f32, 3835478) / mx, aud.samples_b[3]);

                try expect(@as(f32, 4526079) / mx, aud.samples_a[4]);
                try expect(@as(f32, 4963517) / mx, aud.samples_b[4]);

                try expect(@as(f32, 5483098) / mx, aud.samples_a[5]);
                try expect(@as(f32, 5967450) / mx, aud.samples_b[5]);

                try expect(@as(f32, 6329002) / mx, aud.samples_a[6]);
                try expect(@as(f32, 6822174) / mx, aud.samples_b[6]);

                try expect(@as(f32, 7046648) / mx, aud.samples_a[7]);
                try expect(@as(f32, 7506320) / mx, aud.samples_b[7]);

                try expect(@as(f32, 7621493) / mx, aud.samples_a[8]);
                try expect(@as(f32, 8002780) / mx, aud.samples_b[8]);

                try expect(@as(f32, 8041889) / mx, aud.samples_a[9]);
                try expect(@as(f32, 8299141) / mx, aud.samples_b[9]);
            },

            32 => {
                // two_channel_1000_1111_32bit.wav:
                const mx = @as(f32, std.math.maxInt(i32));
                try expect(@as(f32, 0) / mx, aud.samples_a[0]);
                try expect(@as(f32, 0) / mx, aud.samples_b[0]);

                try expect(@as(f32, 304930304) / mx, aud.samples_a[1]);
                try expect(@as(f32, 338508800) / mx, aud.samples_b[1]);

                try expect(@as(f32, 603681536) / mx, aud.samples_a[2]);
                try expect(@as(f32, 668553728) / mx, aud.samples_b[2]);

                try expect(@as(f32, 890198784) / mx, aud.samples_a[3]);
                try expect(@as(f32, 981882368) / mx, aud.samples_b[3]);

                try expect(@as(f32, 1158676224) / mx, aud.samples_a[4]);
                try expect(@as(f32, 1270660352) / mx, aud.samples_b[4]);

                try expect(@as(f32, 1403673088) / mx, aud.samples_a[5]);
                try expect(@as(f32, 1527667200) / mx, aud.samples_b[5]);

                try expect(@as(f32, 1620224512) / mx, aud.samples_a[6]);
                try expect(@as(f32, 1746476544) / mx, aud.samples_b[6]);

                try expect(@as(f32, 1803941888) / mx, aud.samples_a[7]);
                try expect(@as(f32, 1921617920) / mx, aud.samples_b[7]);

                try expect(@as(f32, 1951102208) / mx, aud.samples_a[8]);
                try expect(@as(f32, 2048711680) / mx, aud.samples_b[8]);

                try expect(@as(f32, 2058723584) / mx, aud.samples_a[9]);
                try expect(@as(f32, 2124580096) / mx, aud.samples_b[9]);
            },

            else => {
                return error.UnexpectedBitsPerSample;
            },
        }
    }
}

test "writeWavFile 1 & 2 channel, non-interleaved and interleaved testing" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    const input_filelist = [_][]const u8{
        "wavfiles/one_channel_1000_16bit.wav",
        "wavfiles/one_channel_1000_24bit.wav",
        "wavfiles/one_channel_1000_32bit.wav",

        "wavfiles/two_channel_1000_1111_16bit.wav",
        "wavfiles/two_channel_1000_1111_24bit.wav",
        "wavfiles/two_channel_1000_1111_32bit.wav",
    };

    const SampleType = [_]type{ i16, i24, i32, i16, i24, i32 };

    const output_filename = "tmp_output.wav";

    const interleave = [_]bool{
        false,
        true,
    };
    const num_chan = [_]u16{ 1, 1, 1, 2, 2, 2 };

    inline for (input_filelist, 0..) |infile, i| {
        inline for (interleave) |inter| {
            const audio = try wav_utils.readWavFile(allocator, infile, inter, num_chan[i]);

            try wav_utils.writeWavFile(output_filename, SampleType[i], audio);

            const in_file = std.fs.cwd().openFile(
                input_filelist[i],
                .{ .mode = .read_only },
            ) catch |err| {
                std.log.err("Could not open file \"{s}\"\n", .{input_filelist[i]});
                return err;
            };
            const in_size = (try in_file.stat()).size;

            const out_file = std.fs.cwd().openFile(
                output_filename,
                .{ .mode = .read_only },
            ) catch |err| {
                std.log.err("Could not open file \"{s}\"\n", .{output_filename});
                return err;
            };
            const out_size = (try out_file.stat()).size;

            try std.testing.expectEqual(out_size, in_size);

            const max_bytes = 10000000;
            const in_bytes = try std.fs.File.readToEndAlloc(in_file, allocator, max_bytes);
            const out_bytes = try std.fs.File.readToEndAlloc(out_file, allocator, max_bytes);

            in_file.close();
            out_file.close();
            try std.fs.cwd().deleteFile(output_filename);

            try std.testing.expectEqual(true, std.mem.eql(u8, in_bytes, out_bytes));
        }
    }
}
