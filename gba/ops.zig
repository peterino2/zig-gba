pub fn genericMemset(comptime T: type, destination: [*]volatile u8, value: T, count: usize) void {
    @setRuntimeSafety(false);
    const valueBytes: [*]const u8 = @ptrCast(&value);
    var index: usize = 0;
    while (index != count) : (index += 1) {
        comptime var expandIndex = 0;
        inline while (expandIndex < @sizeOf(T)) : (expandIndex += 1) {
            destination[(index * @sizeOf(T)) + expandIndex] = valueBytes[expandIndex];
        }
    }
}

pub fn alignedMemset(comptime T: type, destination: [*]align(@alignOf(T)) volatile u8, value: T, count: usize) void {
    @setRuntimeSafety(false);
    const alignedDestination: [*]volatile T = @ptrCast(destination);
    var index: usize = 0;
    while (index != count) : (index += 1) {
        alignedDestination[index] = value;
    }
}

pub fn memset32(destination: anytype, value: u32, count: usize) void {
    if ((@intFromPtr(destination) % 4) == 0) {
        alignedMemset(u32, destination, value, count);
    } else {
        genericMemset(u32, @ptrCast(destination), value, count);
    }
}

pub fn memcpy32(noalias destination: anytype, noalias source: anytype, count: usize) void {
    if (count < 4) {
        genericMemcpy(@ptrCast(destination), @ptrCast(source), count);
    } else {
        if ((@intFromPtr(destination) % 4) == 0 and (@intFromPtr(source) % 4) == 0) {
            alignedMemcpy(u32, @ptrCast(@alignCast(destination)), @ptrCast(@alignCast(source)), count);
        } else if ((@intFromPtr(destination) % 2) == 0 and (@intFromPtr(source) % 2) == 0) {
            alignedMemcpy(u16, destination, source, count);
        } else {
            genericMemcpy(@ptrCast(destination), @ptrCast(source), count);
        }
    }
}

pub fn memcpy16(noalias destination: anytype, noalias source: anytype, count: usize) void {
    if (count < 2) {
        genericMemcpy(@ptrCast(destination), @ptrCast(source), count);
    } else {
        genericMemcpy(@ptrCast(destination), @ptrCast(source), count);
    }
}

pub fn alignedMemcpy(comptime T: type, noalias destination: [*]align(@alignOf(T)) volatile u8, noalias source: [*]align(@alignOf(T)) const u8, count: usize) void {
    @setRuntimeSafety(false);
    const alignSize = count / @sizeOf(T);
    const remainderSize = count % @sizeOf(T);

    const alignDestination: [*]volatile T = @ptrCast(destination);
    const alignSource: [*]const T = @ptrCast(source);

    var index: usize = 0;
    while (index != alignSize) : (index += 1) {
        alignDestination[index] = alignSource[index];
    }

    index = count - remainderSize;
    while (index != count) : (index += 1) {
        destination[index] = source[index];
    }
}

pub fn genericMemcpy(noalias destination: [*]volatile u8, noalias source: [*]const u8, count: usize) void {
    @setRuntimeSafety(false);
    var index: usize = 0;
    while (index != count) : (index += 1) {
        destination[index] = source[index];
    }
}
