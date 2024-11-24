// const beam = @import("beam");
const std = @import("std");

var global_colours: ?[]u8 = null;

const Point = struct { x: f64, y: f64 };
const point_size = @sizeOf(Point);
const Bounds = struct { topLeft: Point, bottomRight: Point, cols: usize, rows: usize };

/// Set the parameters for the computation
export fn initialize(
    rows: usize,
    cols: usize,
    imax: usize,
    topleft_x: f64,
    topleft_y: f64,
    bottomright_x: f64,
    bottomright_y: f64,
) void {
    const allocator = std.heap.page_allocator;

    const total_pixels = rows * cols;
    const bytes_needed = total_pixels * 4;

    // Free any existing allocation
    if (global_colours != null) {
        allocator.free(global_colours.?);
    }

    global_colours = allocator.alloc(u8, bytes_needed) catch unreachable;

    const bounds = Bounds{
        .topLeft = Point{ .x = topleft_x, .y = topleft_y },
        .bottomRight = Point{ .x = bottomright_x, .y = bottomright_y },
        .cols = cols,
        .rows = rows,
    };

    computeColours(imax, bounds);
}

fn computeColours(imax: usize, bounds: Bounds) void {
    var idx: usize = 0;
    while (idx < bounds.rows) : (idx += 1) {
        for (0..bounds.cols) |col_idx| {
            // Map the pixel to the complex plane
            const point = mapPixel(.{ idx, col_idx }, bounds);

            // Compute the iteration number (Mandelbrot or similar)
            const iterNumber = iterationNumber(point, imax);

            // Generate the RGBA color
            const colour = createRgba(iterNumber, imax);

            // Set the corresponding colour in the global array
            const colour_idx = (idx * bounds.cols + col_idx) * 4;
            @memcpy(global_colours.?[colour_idx .. colour_idx + 4], &colour);
        }
    }
}

fn iterationNumber(p: Point, imax: usize) ?usize {
    if (p.x > 0.6 or p.x < -2.1) return null;
    if (p.y > 1.2 or p.y < -1.2) return null;
    // first cardiod
    if ((p.x + 1) * (p.x + 1) + p.y * p.y < 0.0625) return null;

    var x2: f64 = 0;
    var y2: f64 = 0;
    var w: f64 = 0;

    for (0..imax) |j| {
        if (x2 + y2 > 4) return j;
        const x: f64 = x2 - y2 + p.x;
        const y: f64 = w - x2 - y2 + p.y;
        x2 = x * x;
        y2 = y * y;
        w = (x + y) * (x + y);
    }
    return null;
}

fn createRgba(iter: ?usize, imax: usize) [4]u8 {
    // If it didn't escape, return black
    if (iter == null) return [_]u8{ 0, 0, 0, 255 };

    if (iter.? < imax and iter.? > 0) {
        const i = iter.? % 16;
        return switch (i) {
            0 => [_]u8{ 66, 30, 15, 255 },
            1 => [_]u8{ 25, 7, 26, 255 },
            2 => [_]u8{ 9, 1, 47, 255 },
            3 => [_]u8{ 4, 4, 73, 255 },
            4 => [_]u8{ 0, 7, 100, 255 },
            5 => [_]u8{ 12, 44, 138, 255 },
            6 => [_]u8{ 24, 82, 177, 255 },
            7 => [_]u8{ 57, 125, 209, 255 },
            8 => [_]u8{ 134, 181, 229, 255 },
            9 => [_]u8{ 211, 236, 248, 255 },
            10 => [_]u8{ 241, 233, 191, 255 },
            11 => [_]u8{ 248, 201, 95, 255 },
            12 => [_]u8{ 255, 170, 0, 255 },
            13 => [_]u8{ 204, 128, 0, 255 },
            14 => [_]u8{ 153, 87, 0, 255 },
            15 => [_]u8{ 106, 52, 3, 255 },
            else => [_]u8{ 0, 0, 0, 255 },
        };
    }
    return [_]u8{ 0, 0, 0, 255 };
}

// canvas-(i,j) are rows,cols and become (x,y) 2D-coordinates within the bounds
fn mapPixel(pixel: [2]usize, ctx: Bounds) Point {
    const x: f64 = ctx.topLeft.x + @as(f64, @floatFromInt(pixel[1])) / @as(f64, @floatFromInt(ctx.cols)) * (ctx.bottomRight.x - ctx.topLeft.x);
    const y: f64 = ctx.topLeft.y - @as(f64, @floatFromInt(pixel[0])) / @as(f64, @floatFromInt(ctx.rows)) * (ctx.topLeft.y - ctx.bottomRight.y);
    return Point{ .x = x, .y = y };
}

// Webassembly requires the main function to return void
// pub export fn main() void {
//     std.debug.print("WebAssembly module started!\n", .{});
// }

export fn getColoursPointer() *u8 {
    // Expose the colours array to the host
    return &global_colours.?.ptr[0];
}

export fn getColoursSize() usize {
    return global_colours.?.len;
}

export fn freeColours() void {
    if (global_colours) |slice| {
        const allocator = std.heap.page_allocator;
        allocator.free(slice);
        global_colours = null;
    }
}
