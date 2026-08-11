module test_helpmode_docview

using Test
using HelpMode

function custom_helpmode(io::IO, line::AbstractString)::Bool
end

HelpMode.register(custom_helpmode)
HelpMode.unregister(custom_helpmode)

@test isempty(HelpMode._custom_helpmodes)

end # module test_helpmode_docview
