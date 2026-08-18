# module HelpMode

_custom_helpmodes = []

function register(f)
    push!(_custom_helpmodes, f)
end

function modes()
    return _custom_helpmodes
end

function unregister(f)
    idx = findfirst(==(f), _custom_helpmodes)
    idx !== nothing && deleteat!(_custom_helpmodes, idx)
end

function check_custom_helpmode(io::IO, line::AbstractString)::Bool
    for f in _custom_helpmodes
        f(io, line) && return true
    end
    return false
end

using REPL: REPL
using .REPL: extended_help_on, keywords, isexpr
import .REPL: _helpmode

# from julia/stdlib/REPL/src/docview.jl
# function _helpmode(io::IO, line::AbstractString, mod::Module=Main, internal_accesses::Union{Nothing, Set{Pair{Module,Symbol}}}=nothing)
function _helpmode(io::Base.TTY, line::AbstractString, mod::Module=Main, internal_accesses::Union{Nothing, Set{Pair{Module,Symbol}}}=nothing)
    line = strip(line)
    check_custom_helpmode(io, line) && return
    ternary_operator_help = (line == "?" || line == "?:")
    if startswith(line, '?') && !ternary_operator_help
        line = line[2:end]
        extended_help_on[] = nothing
        brief = false
    else
        extended_help_on[] = line
        brief = true
    end
    # interpret anything starting with # or #= as asking for help on comments
    if startswith(line, "#")
        if startswith(line, "#=")
            line = "#="
        else
            line = "#"
        end
    end
    x = Meta.parse(line, raise = false, depwarn = false)
    assym = Symbol(line)
    expr =
        if haskey(keywords, assym) || Base.isoperator(assym) || isexpr(x, :error) ||
            isexpr(x, :invalid) || isexpr(x, :incomplete)
            # Docs for keywords must be treated separately since trying to parse a single
            # keyword such as `function` would throw a parse error due to the missing `end`.
            assym
        elseif isexpr(x, (:using, :import))
            (x::Expr).head
        else
            # Retrieving docs for macros requires us to make a distinction between the text
            # `@macroname` and `@macroname()`. These both parse the same, but are used by
            # the docsystem to return different results. The first returns all documentation
            # for `@macroname`, while the second returns *only* the docs for the 0-arg
            # definition if it exists.
            (isexpr(x, :macrocall, 1) && !endswith(line, "()")) ? quot(x) : x
        end
    # the following must call repl(io, expr) via the @repl macro
    # so that the resulting expressions are evaluated in the Base.Docs namespace
    :($REPL.@repl $io $expr $brief $mod $internal_accesses)
end # function _helpmode

# module HelpMode
