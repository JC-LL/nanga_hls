require "colorize"
require "sxp"

require_relative "./nanga/code"
require_relative "./nanga/generic_lexer"
require_relative "./nanga/generic_parser"

require_relative "./nanga/version"
require_relative "./nanga/runner"
require_relative "./nanga/compiler"
require_relative "./nanga/visitor"
require_relative "./nanga/compiler_pass"

require_relative "./nanga/lexer"
require_relative "./nanga/parser"
require_relative "./nanga/symtable"

require_relative "./nanga/dummy_pass"
require_relative "./nanga/pretty_printer"
require_relative "./nanga/ast"
require_relative "./nanga/allocation_graph"
require_relative "./nanga/allocation"
require_relative "./nanga/open_classes"
require_relative "./nanga/emitter"
require_relative "./nanga/resolver"
require_relative "./nanga/ir_builder"
require_relative "./nanga/range_propagator"
require_relative "./nanga/strength_reductor"
require_relative "./nanga/symetrization"
require_relative "./nanga/dfg"
require_relative "./nanga/dfg_builder"
require_relative "./nanga/dfg_printer"
require_relative "./nanga/dfg_scheduler"
require_relative "./nanga/dfg_allocator"
require_relative "./nanga/scheduling_asap"
require_relative "./nanga/rtl"
require_relative "./nanga/controler_datapath_extractor"
require_relative "./nanga/vhdl_generator"
