***zig*** simple tool for reading/writing of wav files

***Features:***

* <ins> limited to pcm files
* <ins> supports file reads and file writes of sample types i16, i24, i32, and f32
* <ins> supports conversion between 1-channel and 2-channels
* <ins> upon reading, all samples are converted to normalized f32 (values between -1.0 and 1.0)

***To run example:***
* <ins> clone repository to local disk </ins>
* <ins> cd examples </ins>
* <ins> zig build </ins> creates executable in the **bin** directory
* <ins> zig build run </ins> will run example
* <ins> **Note:** example looks for sample wav files in "wavfiles" subdirectory from run directory.

