#scope_file

#import "Basic";
#import "Compiler";
#import "BuildCpp";
#import "Check";
#import "Bindings_Generator";
#import "File";

#scope_export

#run build();

build :: () {
    set_build_options_dc(.{do_output=true});

    options := get_build_options();
    do_debug := (options.optimization_level == .DEBUG);
    // build_cpp_dynamic_lib("raymath", "raymath.h", debug=do_debug);

    write_file := true;
    user_args := compiler_get_command_line_arguments();
    for user_args {
        if it == "-no_write"    write_file = false;
    }
    generate_bindings(write_file);

    w := compiler_create_workspace("Main program");
    
    options.output_type     = .EXECUTABLE;
    options.output_executable_name = "example";
    // options.llvm_options.output_llvm_ir = true;
    // options.stack_trace = false;
    // options.llvm_options.enable_split_modules = false;
    set_build_options(options, w);
    
    compiler_begin_intercept(w);
    add_build_file("main.jai", w);

    while true {
        message := compiler_wait_for_message();
        if !message break;
        
        if message.kind == {
          case .TYPECHECKED;
            do_error_checking(message, check_bindings = true);
            
          case .COMPLETE;
            break;
        }
    }

    compiler_end_intercept(w);
}

generate_bindings :: (write_file:bool=true) {
    output_filename: string;
    opts: Generate_Bindings_Options;
    {
        using opts;

        #if OS == .WINDOWS {
            output_filename          = "windows.jai";
        } else #if OS == .LINUX {
            output_filename          = "linux.jai";
        } else #if OS == .MACOS {
            // @ToDo: Determine dynamically? Customize?
            array_add(*system_include_paths, "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include");
            output_filename          = "macos.jai";
        } else {
            assert(false);
        }

        array_add(*libpaths,       ".");
        array_add(*libnames,      "raylib");
        // array_add(*libnames,      "raymath");
        array_add(*system_include_paths, GENERATOR_DEFAULT_SYSTEM_INCLUDE_PATH);
        array_add(*source_files,  "raylib.h");
        // array_add(*source_files,  "raymath.h");
        // array_add(*source_files,  "rlgl.h");
        // array_add(*source_files,  "raygui.h");
        array_add(*extra_clang_arguments, "-x", "c");
        strip_flags = 0;
        // strip_flags &= ~(Strip_Flags.CONSTRUCTORS | .DESTRUCTORS);

        generate_printf_wrappers = false;
    }

    bindings_builder, success := generate_bindings(opts);
    if !success     return;
    defer free_buffers(*bindings_builder);
    show_generator_results();

    if write_file {
        #if OS == .LINUX || OS == .MACOS {
            append(*bindings_builder, SUFFIX_UNIX);
        }
        success = write_entire_file(output_filename, bindings_builder);
        if !success {
            log_error("Could not write generated output to \"%\"\n", output_filename);
            return;
        }    
        log("\nOK! generated '%'\n", output_filename);
    }
}
