@doc raw"""
    evolution(M, ρ0, Δt, steps; threshold, nonzero_tol, verbose, filename)
Solve the time evolution for auxiliary density operators based on propagator (generated by `FastExpm.jl`)
with initial state is given in the type of density-matrix (`ρ0`).

This method will return the time evolution of `ADOs` corresponds to `tlist = 0 : Δt : (Δt * steps)`

# Parameters
- `M::AbstractHEOMLSMatrix` : the matrix given from HEOM model
- `ρ0` : system initial state (density matrix)
- `Δt::Real` : A specific time step (time interval).
- `steps::Int` : The number of time steps
- `threshold::Real` : Determines the threshold for the Taylor series. Defaults to `1.0e-6`.
- `nonzero_tol::Real` : Strips elements smaller than `nonzero_tol` at each computation step to preserve sparsity. Defaults to `1.0e-14`.
- `verbose::Bool` : To display verbose output and progress bar during the process or not. Defaults to `true`.
- `filename::String` : If filename was specified, the ADOs at each time point will be saved into the JLD2 file "filename.jld2" during the solving process.

For more details, please refer to [`FastExpm.jl`](https://github.com/fmentink/FastExpm.jl)

# Returns
- `ADOs_list` : The auxiliary density operators of each time step.
"""
function evolution(
        M::AbstractHEOMLSMatrix, 
        ρ0, 
        Δt::Real,
        steps::Int;
        threshold   = 1.0e-6,
        nonzero_tol = 1.0e-14,
        verbose::Bool = true,
        filename::String = ""
    )
    
    _ρ0 = HandleMatrixType(ρ0, M.dim, "ρ0 (initial state)")

    # vectorize initial state
    ρ1   = sparse(sparsevec(_ρ0))
    ados = ADOs(sparsevec(ρ1.nzind, ρ1.nzval, M.N * M.sup_dim), M.N, M.parity)

    return evolution(M, ados, Δt, steps;
        threshold   = threshold,
        nonzero_tol = nonzero_tol,
        verbose = verbose,
        filename = filename
    )
end

@doc raw"""
    evolution(M, ados, Δt, steps; threshold, nonzero_tol, verbose, filename)
Solve the time evolution for auxiliary density operators based on propagator (generated by `FastExpm.jl`)
with initial state is given in the type of `ADOs`.

This method will return the time evolution of `ADOs` corresponds to `tlist = 0 : Δt : (Δt * steps)`

# Parameters
- `M::AbstractHEOMLSMatrix` : the matrix given from HEOM model
- `ados::ADOs` : initial auxiliary density operators
- `Δt::Real` : A specific time step (time interval).
- `steps::Int` : The number of time steps
- `threshold::Real` : Determines the threshold for the Taylor series. Defaults to `1.0e-6`.
- `nonzero_tol::Real` : Strips elements smaller than `nonzero_tol` at each computation step to preserve sparsity. Defaults to `1.0e-14`.
- `verbose::Bool` : To display verbose output and progress bar during the process or not. Defaults to `true`.
- `filename::String` : If filename was specified, the ADOs at each time point will be saved into the JLD2 file "filename.jld2" during the solving process.

For more details, please refer to [`FastExpm.jl`](https://github.com/fmentink/FastExpm.jl)

# Returns
- `ADOs_list` : The auxiliary density operators of each time step.
"""
@noinline function evolution(
        M::AbstractHEOMLSMatrix, 
        ados::ADOs,
        Δt::Real,
        steps::Int;
        threshold   = 1.0e-6,
        nonzero_tol = 1.0e-14,
        verbose::Bool = true,
        filename::String = ""
    )

    if (M.dim != ados.dim)
        error("The system dimension between M and ados are not consistent.")
    end

    if (M.N != ados.N)
        error("The number N between M and ados are not consistent.")
    end

    if (typeof(M.parity) != typeof(ados.parity))
        error("The parity between M and ados are not consistent.")
    end

    SAVE::Bool = (filename != "")
    if SAVE 
        FILENAME = filename * ".jld2"
        if isfile(FILENAME)
            error("FILE: $(FILENAME) already exist.")
        end
    end

    ADOs_list::Vector{ADOs} = [ados]
    if SAVE
        jldopen(FILENAME, "a") do file
            file["0"] = ados
        end
    end

    # Generate propagator
    if verbose
        print("Generating propagator...")
        flush(stdout)
    end
    exp_Mt = Propagator(M, Δt; threshold = threshold, nonzero_tol = nonzero_tol)
    if verbose
        println("[DONE]")
        flush(stdout)
    end

    # start solving
    ρvec = copy(ados.data)
    if verbose
        print("Solving time evolution for auxiliary density operators...\n")
        flush(stdout)
        prog = Progress(steps + 1; start=1, desc="Progress : ", PROGBAR_OPTIONS...)
    end
    for n in 1:steps
        ρvec = exp_Mt * ρvec
        
        # save the ADOs
        ados = ADOs(ρvec, M.dim, M.N, M.parity)
        push!(ADOs_list, ados)
        
        if SAVE
            jldopen(FILENAME, "a") do file
                file[string(n * Δt)] = ados
            end
        end
        if verbose
            next!(prog)
        end
    end
    if verbose
        println("[DONE]\n")
        flush(stdout)
    end

    return ADOs_list
end

@doc raw"""
    evolution(M, ρ0, tlist; solver, reltol, abstol, maxiters, save_everystep, verbose, filename, SOLVEROptions...)
Solve the time evolution for auxiliary density operators based on ordinary differential equations
with initial state is given in the type of density-matrix (`ρ0`).

# Parameters
- `M::AbstractHEOMLSMatrix` : the matrix given from HEOM model
- `ρ0` : system initial state (density matrix)
- `tlist::AbstractVector` : Denote the specific time points to save the solution at, during the solving process.
- `solver` : solver in package `DifferentialEquations.jl`. Default to `DP5()`.
- `reltol::Real` : Relative tolerance in adaptive timestepping. Default to `1.0e-6`.
- `abstol::Real` : Absolute tolerance in adaptive timestepping. Default to `1.0e-8`.
- `maxiters::Real` : Maximum number of iterations before stopping. Default to `1e5`.
- `save_everystep::Bool` : Saves the result at every step. Defaults to `false`.
- `verbose::Bool` : To display verbose output and progress bar during the process or not. Defaults to `true`.
- `filename::String` : If filename was specified, the ADOs at each time point will be saved into the JLD2 file "filename.jld2" during the solving process.
- `SOLVEROptions` : extra options for solver

For more details about solvers and extra options, please refer to [`DifferentialEquations.jl`](https://diffeq.sciml.ai/stable/)

# Returns
- `ADOs_list` : The auxiliary density operators in each time point.
"""
function evolution(
        M::AbstractHEOMLSMatrix, 
        ρ0, 
        tlist::AbstractVector;
        solver = DP5(),
        reltol::Real = 1.0e-6,
        abstol::Real = 1.0e-8,
        maxiters::Real = 1e5,
        save_everystep::Bool=false,
        verbose::Bool = true,
        filename::String = "",
        SOLVEROptions...
    )

    _ρ0 = HandleMatrixType(ρ0, M.dim, "ρ0 (initial state)")

    # vectorize initial state
    ρ1   = sparse(sparsevec(_ρ0))
    ados = ADOs(sparsevec(ρ1.nzind, ρ1.nzval, M.N * M.sup_dim), M.N, M.parity)

    return evolution(M, ados, tlist;
        solver = solver,
        reltol = reltol,
        abstol = abstol,
        maxiters = maxiters,
        save_everystep = save_everystep,
        verbose = verbose,
        filename = filename,
        SOLVEROptions...
    )
end

@doc raw"""
    evolution(M, ados, tlist; solver, reltol, abstol, maxiters, save_everystep, verbose, filename, SOLVEROptions...)
Solve the time evolution for auxiliary density operators based on ordinary differential equations
with initial state is given in the type of `ADOs`.

# Parameters
- `M::AbstractHEOMLSMatrix` : the matrix given from HEOM model
- `ados::ADOs` : initial auxiliary density operators
- `tlist::AbstractVector` : Denote the specific time points to save the solution at, during the solving process.
- `solver` : solver in package `DifferentialEquations.jl`. Default to `DP5()`.
- `reltol::Real` : Relative tolerance in adaptive timestepping. Default to `1.0e-6`.
- `abstol::Real` : Absolute tolerance in adaptive timestepping. Default to `1.0e-8`.
- `maxiters::Real` : Maximum number of iterations before stopping. Default to `1e5`.
- `save_everystep::Bool` : Saves the result at every step. Defaults to `false`.
- `verbose::Bool` : To display verbose output and progress bar during the process or not. Defaults to `true`.
- `filename::String` : If filename was specified, the ADOs at each time point will be saved into the JLD2 file "filename.jld2" during the solving process.
- `SOLVEROptions` : extra options for solver

For more details about solvers and extra options, please refer to [`DifferentialEquations.jl`](https://diffeq.sciml.ai/stable/)

# Returns
- `ADOs_list` : The auxiliary density operators in each time point.
"""
@noinline function evolution(
        M::AbstractHEOMLSMatrix, 
        ados::ADOs, 
        tlist::AbstractVector;
        solver = DP5(),
        reltol::Real = 1.0e-6,
        abstol::Real = 1.0e-8,
        maxiters::Real = 1e5,
        save_everystep::Bool=false,
        verbose::Bool = true,
        filename::String = "",
        SOLVEROptions...
    )

    if (M.dim != ados.dim)
        error("The system dimension between M and ados are not consistent.")
    end

    if (M.N != ados.N)
        error("The ADOs number \"N\" between M and ados are not consistent.")
    end

    if (typeof(M.parity) != typeof(ados.parity))
        error("The parity between M and ados are not consistent.")
    end

    SAVE::Bool = (filename != "")
    if SAVE 
        FILENAME = filename * ".jld2"
        if isfile(FILENAME)
            error("FILE: $(FILENAME) already exist.")
        end
    end

    ADOs_list::Vector{ADOs} = [ados]
    if SAVE
        jldopen(FILENAME, "a") do file
            file[string(tlist[1])] = ados
        end
    end

    # problem: dρ/dt = L * ρ(0)
    L = MatrixOperator(M.data)
    prob = ODEProblem(L, Vector(ados.data), (tlist[1], tlist[end]))

    # setup integrator
    integrator = init(
        prob,
        solver;
        reltol = reltol,
        abstol = abstol,
        maxiters = maxiters,
        save_everystep = save_everystep,
        SOLVEROptions...
    )

    # start solving ode
    if verbose
        print("Solving time evolution for auxiliary density operators...\n")
        flush(stdout)
        prog = Progress(length(tlist); start=1, desc="Progress : ", PROGBAR_OPTIONS...)
    end
    idx = 1
    dt_list = diff(tlist)
    for dt in dt_list
        idx += 1
        step!(integrator, dt, true)
        
        # save the ADOs
        ados = ADOs(copy(integrator.u), M.dim, M.N, M.parity)
        push!(ADOs_list, ados)
        
        if SAVE
            jldopen(FILENAME, "a") do file
                file[string(tlist[idx])] = ados
            end
        end
        if verbose
            next!(prog)
        end
    end
    if verbose
        println("[DONE]\n")
        flush(stdout)
    end

    return ADOs_list
end

@doc raw"""
    evolution(M, ρ0, tlist, H, param; solver, reltol, abstol, maxiters, save_everystep, verbose, filename, SOLVEROptions...)
Solve the time evolution for auxiliary density operators with time-dependent system Hamiltonian based on ordinary differential equations
with initial state is given in the type of density-matrix (`ρ0`).
# Parameters
- `M::AbstractHEOMLSMatrix` : the matrix given from HEOM model (with time-independent system Hamiltonian)
- `ρ0` : system initial state (density matrix)
- `tlist::AbstractVector` : Denote the specific time points to save the solution at, during the solving process.
- `H::Function` : a function for time-dependent part of system Hamiltonian. The function will be called by `H(param, t)` and should return the time-dependent part system Hamiltonian matrix at time `t` with `AbstractMatrix` type.
- `param::Tuple`: the tuple of parameters which is used to call `H(param, t)` for the time-dependent system Hamiltonian. Default to empty tuple `()`.
- `solver` : solver in package `DifferentialEquations.jl`. Default to `DP5()`.
- `reltol::Real` : Relative tolerance in adaptive timestepping. Default to `1.0e-6`.
- `abstol::Real` : Absolute tolerance in adaptive timestepping. Default to `1.0e-8`.
- `maxiters::Real` : Maximum number of iterations before stopping. Default to `1e5`.
- `save_everystep::Bool` : Saves the result at every step. Defaults to `false`.
- `verbose::Bool` : To display verbose output and progress bar during the process or not. Defaults to `true`.
- `filename::String` : If filename was specified, the ADOs at each time point will be saved into the JLD2 file "filename.jld2" during the solving process.
- `SOLVEROptions` : extra options for solver

For more details about solvers and extra options, please refer to [`DifferentialEquations.jl`](https://diffeq.sciml.ai/stable/)

# Returns
- `ADOs_list` : The auxiliary density operators in each time point.
"""
function evolution(
        M::AbstractHEOMLSMatrix,
        ρ0, 
        tlist::AbstractVector,
        H::Function,
        param::Tuple = ();
        solver = DP5(),
        reltol::Real = 1.0e-6,
        abstol::Real = 1.0e-8,
        maxiters::Real = 1e5,
        save_everystep::Bool=false,
        verbose::Bool = true,
        filename::String = "",
        SOLVEROptions...
    )

    _ρ0 = HandleMatrixType(ρ0, M.dim, "ρ0 (initial state)")

    # vectorize initial state
    ρ1   = sparse(sparsevec(_ρ0))
    ados = ADOs(sparsevec(ρ1.nzind, ρ1.nzval, M.N * M.sup_dim), M.N, M.parity)

    return evolution(M, ados, tlist, H, param;
        solver = solver,
        reltol = reltol,
        abstol = abstol,
        maxiters = maxiters,
        save_everystep = save_everystep,
        verbose = verbose,
        filename = filename,
        SOLVEROptions...
    )
end

@doc raw"""
    evolution(M, ados, tlist, H, param; solver, reltol, abstol, maxiters, save_everystep, verbose, filename, SOLVEROptions...)
Solve the time evolution for auxiliary density operators with time-dependent system Hamiltonian based on ordinary differential equations
with initial state is given in the type of `ADOs`.
# Parameters
- `M::AbstractHEOMLSMatrix` : the matrix given from HEOM model (with time-independent system Hamiltonian)
- `ados::ADOs` : initial auxiliary density operators
- `tlist::AbstractVector` : Denote the specific time points to save the solution at, during the solving process.
- `H::Function` : a function for time-dependent part of system Hamiltonian. The function will be called by `H(param, t)` and should return the time-dependent part system Hamiltonian matrix at time `t` with `AbstractMatrix` type.
- `param::Tuple`: the tuple of parameters which is used to call `H(param, t)` for the time-dependent system Hamiltonian. Default to empty tuple `()`.
- `solver` : solver in package `DifferentialEquations.jl`. Default to `DP5()`.
- `reltol::Real` : Relative tolerance in adaptive timestepping. Default to `1.0e-6`.
- `abstol::Real` : Absolute tolerance in adaptive timestepping. Default to `1.0e-8`.
- `maxiters::Real` : Maximum number of iterations before stopping. Default to `1e5`.
- `save_everystep::Bool` : Saves the result at every step. Defaults to `false`.
- `verbose::Bool` : To display verbose output and progress bar during the process or not. Defaults to `true`.
- `filename::String` : If filename was specified, the ADOs at each time point will be saved into the JLD2 file "filename.jld2" during the solving process.
- `SOLVEROptions` : extra options for solver

For more details about solvers and extra options, please refer to [`DifferentialEquations.jl`](https://diffeq.sciml.ai/stable/)

# Returns
- `ADOs_list` : The auxiliary density operators in each time point.
"""
@noinline function evolution(
        M::AbstractHEOMLSMatrix,
        ados::ADOs, 
        tlist::AbstractVector,
        H::Function,
        param::Tuple = ();
        solver = DP5(),
        reltol::Real = 1.0e-6,
        abstol::Real = 1.0e-8,
        maxiters::Real = 1e5,
        save_everystep::Bool=false,
        verbose::Bool = true,
        filename::String = "",
        SOLVEROptions...
    )

    if (M.dim != ados.dim)
        error("The system dimension between M and ados are not consistent.")
    end

    if (M.N != ados.N)
        error("The ADOs number \"N\" between M and ados are not consistent.")
    end

    if (typeof(M.parity) != typeof(ados.parity))
        error("The parity between M and ados are not consistent.")
    end

    SAVE::Bool = (filename != "")
    if SAVE 
        FILENAME = filename * ".jld2"
        if isfile(FILENAME)
            error("FILE: $(FILENAME) already exist.")
        end
    end

    ADOs_list::Vector{ADOs} = [ados]
    if SAVE
        jldopen(FILENAME, "a") do file
            file[string(tlist[1])] = ados
        end
    end
    
    Ht  = H(param, tlist[1])
    _Ht = HandleMatrixType(Ht, M.dim, "H (Hamiltonian) at t=$(tlist[1])")
    Lt  = kron(sparse(I, M.N, M.N), - 1im * (spre(_Ht) - spost(_Ht)))
    L   = MatrixOperator(M.data + Lt, update_func! = _update_L!)
    
    # problem: dρ/dt = L(t) * ρ(0)
    ## M.dim will check whether the returned time-dependent Hamiltonian has the correct dimension
    prob = ODEProblem(L, Vector(ados.data), (tlist[1], tlist[end]), (M, H, param))

    # setup integrator
    integrator = init(
        prob,
        solver;
        reltol = reltol,
        abstol = abstol,
        maxiters = maxiters,
        save_everystep = save_everystep,
        SOLVEROptions...
    )

    # start solving ode
    if verbose
        print("Solving time evolution for auxiliary density operators with time-dependent Hamiltonian...\n")
        flush(stdout)
        prog = Progress(length(tlist); start=1, desc="Progress : ", PROGBAR_OPTIONS...)
    end
    idx = 1
    dt_list = diff(tlist)
    for dt in dt_list
        idx += 1
        step!(integrator, dt, true)
        
        # save the ADOs
        ados = ADOs(copy(integrator.u), M.dim, M.N, M.parity)
        push!(ADOs_list, ados)
        
        if SAVE
            jldopen(FILENAME, "a") do file
                file[string(tlist[idx])] = ados
            end
        end
        if verbose
            next!(prog)
        end
    end
    if verbose
        println("[DONE]\n")
        flush(stdout)
    end

    return ADOs_list
end

# define the update function for evolution with time-dependent system Hamiltonian H(param, t)
function _update_L!(L, u, p, t)
    M, H, param = p

    # check system dimension of Hamiltonian
    Ht  = H(param, t)
    _Ht = HandleMatrixType(Ht, M.dim, "H (Hamiltonian) at t=$(t)")

    # update the block diagonal terms of L
    L .= M.data - kron(sparse(I, M.N, M.N), 1im * (spre(_Ht) - spost(_Ht)))
    nothing
end