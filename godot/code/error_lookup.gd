extends Script

static func get_error_description(err_num):
    var error_array = ["OK: No error.", "FAILED: Generic error, error uknown.", "ERR_UNAVAILABLE: Unavailable error, resource unavailable.", "ERR_UNCONFIGURED: Resource unconfigured.",
                    "ERR_UNAUTHORIZED: Resource returned unauthorized error.", "ERR_PARAMETER_RANGE_ERROR", "ERR_PARAMETER_RANGE_ERROR", "ERR_FILE_NOT_FOUND",
                    "ERR_FILE_BAD_DRIVE", "ERR_FILE_BAD_PATH", "ERR_FILE_NO_PERMISSION", "ERR_FILE_ALREADY_IN_USE", "ERR_FILE_CANT_OPEN", "ERR_FILE_CANT_WRITE",
                    "ERR_FILE_CANT_READ", "ERR_FILE_UNRECOGNIZED", "ERR_FILE_CORRUPT", "ERR_FILE_MISSING_DEPENDENCIES", "ERR_FILE_EOF", 
                    "ERR_CANT_OPEN: Can't open the resource. Typically a file but from a higher level library like ConfigFile or JSON."]
    return error_array[err_num]
