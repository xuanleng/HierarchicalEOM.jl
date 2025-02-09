## run the following command under HierarchicalEOM.jl root directory
# julia --project=docs/ -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd()));Pkg.instantiate()'
# julia --project=docs/ docs/make.jl

import Literate
using Documenter, HierarchicalEOM

const DRAFT = false # set `true` to disable cell evaluation

# clean and rebuild the output markdown directory for examples
doc_output_path = abspath(joinpath(@__DIR__, "src", "examples"))
if isdir(doc_output_path)
    rm(doc_output_path, recursive=true)
end
mkdir(doc_output_path)

# Generate page: Quick Start
QS_source_file = abspath(joinpath(@__DIR__, "..",  "examples", "quick_start.jl"))
Literate.markdown(QS_source_file, doc_output_path)

# Generate example pages
EXAMPLES = [
    "cavityQED",
    "dynamical_decoupling",
    "SIAM",
    "electronic_current"
]
EX_source_files = [abspath(joinpath(@__DIR__, "..",  "examples", "$(ex_name).jl")) for ex_name in EXAMPLES]
EX_output_files = ["examples/$(ex_name).md" for ex_name in EXAMPLES]
for file in EX_source_files
    Literate.markdown(file, doc_output_path)
end

# Generate benchmark pages
BENCHMARKS = [
    "benchmark_ODE_solvers",
    "benchmark_LS_solvers"
]
BM_source_files = [abspath(joinpath(@__DIR__, "..",  "examples", "$(bm_name).jl")) for bm_name in BENCHMARKS]
BM_output_files = ["examples/$(bm_name).md" for bm_name in BENCHMARKS]
for file in BM_source_files
    Literate.markdown(file, doc_output_path)
end

const PAGES = Any[
    "Home" => Any[
        "Introduction" => "index.md",
        "Installation" => "install.md",
        "Quick Start"  => "examples/quick_start.md",
        "Cite HierarchicalEOM.jl" => "cite.md"
    ],
    "Manual" => Any[
        "Bosonic Bath" => Any[
            "Introduction" => "bath_boson/bosonic_bath_intro.md",
            "Drude-Lorentz Spectral Density" => "bath_boson/Boson_Drude_Lorentz.md"
        ],
        "Bosonic Bath (RWA)" => Any[
            "Introduction" => "bath_boson_RWA/bosonic_bath_RWA_intro.md"
        ],
        "Fermionic Bath" => Any[
            "Introduction" => "bath_fermion/fermionic_bath_intro.md",
            "Lorentz Spectral Density" => "bath_fermion/Fermion_Lorentz.md"
        ],
        "Auxiliary Density Operators" => "ADOs.md",
        "HEOMLS Matrices" => Any[
            "Introduction" => "heom_matrix/HEOMLS_intro.md",
            "HEOMLS for Schrödinger Equation" => "heom_matrix/schrodinger_eq.md",
            "HEOMLS for Bosonic Bath" => "heom_matrix/M_Boson.md",
            "HEOMLS for Fermionic Bath" => "heom_matrix/M_Fermion.md",
            "HEOMLS for Bosonic and Fermionic Bath" => "heom_matrix/M_Boson_Fermion.md",
            "HEOMLS for Master Equation" => "heom_matrix/master_eq.md",
        ],
        "Hierarchy Dictionary" => "hierarchy_dictionary.md",
        "Time Evolution" => "time_evolution.md",
        "Stationary State" => "stationary_state.md",
        "Spectrum" => "spectrum.md",
        "Examples" => EX_output_files,
        "Benchmark Solvers" => BM_output_files,
        "Extensions" => Any[
            "QuantumOptics.jl" => "extensions/QuantumOptics.md"
        ]
    ],
    "Library API" => "libraryAPI.md"
]

makedocs(
    modules = [HierarchicalEOM],
    sitename = "Documentation | HierarchicalEOM.jl",
    pages  = PAGES,
    format = Documenter.HTML(
        prettyurls = (get(ENV, "CI", nothing) == "true"),    
        ansicolor  = true
    ),
    draft  = DRAFT
)

deploydocs(
    repo="github.com/NCKU-QFort/HierarchicalEOM.jl.git",
    devbranch = "main"
)