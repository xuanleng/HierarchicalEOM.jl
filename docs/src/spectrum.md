# [Spectrum](@id doc-Spectrum)

## Introduction
We briefly summarize how to numerically compute the spectrum associated with the system degree of freedom. [Phys. Rev. Lett. 109, 266403 (2012)](https://link.aps.org/doi/10.1103/PhysRevLett.109.266403) showed that the spectrum can be evaluated either in time or frequency domain.

`HierarchicalEOM.jl` provides a function [`spectrum`](@ref) which performs the calculation in frequency domain. There are two different methods (as shown below) which depends on the [parity](@ref doc-Parity) of the HEOMLS matrices ``\hat{\mathcal{M}}`` corresponds to different system degree of freedom. 

If you want to calculate the spectrum associated with
 - [bosonic systems (Power Spectral Density)](@ref doc-PSD) : you have to provide ``\hat{\mathcal{M}}`` constructed in `EVEN` parity.
 - [fermionic systems (Density of States)](@ref doc-DOS) : you have to provide ``\hat{\mathcal{M}}`` constructed in `ODD` parity.

The function [`spectrum`](@ref) will automatically detect the [parity](@ref doc-Parity) of ``\hat{\mathcal{M}}`` by itself. Furthermore, the output of the function [`spectrum`](@ref) for both cases will always be in the type of `Vector{Float64}`, which contains the list of the spectrum values corresponding to the given `ω_list`.

`HierarchicalEOM.jl` wraps some of the functions in [LinearSolve.jl](http://linearsolve.sciml.ai/stable/), which is a very rich numerical library for solving the linear problems and provides many solvers. It offers quite a few options for the user to tailor the solver to their specific needs. The default solver (and its corresponding settings) are chosen to suit commonly encountered problems and should work fine for most of the cases. If you require more specialized methods, such as the choice of algorithm, please refer to [benchmark for LinearSolve solvers](@ref benchmark-LS-solvers) and also the documentation of [LinearSolve.jl](http://linearsolve.sciml.ai/stable/).

## [Power Spectral Density](@id doc-PSD)
Start from the spectrum for bosonic systems (power spectral density) in the time-domain. We write the system two-time correlation function in terms of the propagator ``\hat{\mathcal{G}}(t)=\exp(\hat{\mathcal{M}} t)`` for ``t>0``. The power spectral density ``S(\omega)`` can be obtained as
```math
\begin{aligned}
\pi S(\omega) 
&= \textrm{Re}\left\{\int_0^\infty dt \langle a^\dagger(t)a(0)\rangle e^{-i\omega t}\right\}\\
&= \textrm{Re}\left\{\int_0^\infty dt \langle a^\dagger e^{\hat{\mathcal{M}} t}a\rangle e^{-i\omega t}\right\}\\
&= -\textrm{Re}\left\{\langle a^\dagger (\hat{\mathcal{M}} -i\omega)^{-1} a\rangle\right\}\\
&= -\textrm{Re}\left\{\textrm{Tr}\left[ a^\dagger (\hat{\mathcal{M}} -i\omega)^{-1} a\rho^{(m,n,+)}_{\textbf{j} \vert \textbf{q}}\right]\right\},
\end{aligned}
```
where a half-Fourier transform has been introduced in the third line. We note that only the reduced density operator (``m=n=0``) is considered when taking the final trace operation.

The function [`spectrum`](@ref) solves the linear problem ``\textbf{A x}=\textbf{b}`` at a fixed frequency ``\omega`` where 
 - ``\textbf{A}=\hat{\mathcal{M}}-i\omega``
 - ``\textbf{b}=a\rho^{(m,n,+)}_{\textbf{j} \vert \textbf{q}}`` 
using the package [LinearSolve.jl](http://linearsolve.sciml.ai/stable/).

Finially, one can obtain the value of the power spectral density for specific ``\omega``, namely
```math
\pi S(\omega) = -\textrm{Re}\left\{\textrm{Tr}\left[ a^\dagger \textbf{x}\right]\right\}.
```

See also the docstring : [`spectrum`](@ref)

```julia
M::AbstractHEOMLSMatrix # need to be in "EVEN" parity

# the input state can be in either type (but usually ADOs):
ρ::AbstractMatrix # the reduced density operator
ρ::ADOs # the ADOs solved from "evolution" or "SteadyState"

# the (usually annihilation) operator "a" as shown above
a::AbstractMatrix 

# the spectrum value for the specific frequency ω which need to be solved
ω_list = 0:0.5:2 # [0.0, 0.5, 1.0, 1.5, 2.0]

πSω = spectrum(M, ρ, a, ω_list)
```
!!! note "Note"
    To calculate power spectral density, remember to construct ``\hat{\mathcal{M}}`` with `EVEN` [parity](@ref doc-Parity).

## [Density of States](@id doc-DOS)
Start from the spectrum for fermionic systems (density of states) in the time-domain. We write the system two-time correlation function in terms of the propagator ``\hat{\mathcal{G}}(t)=\exp(\hat{\mathcal{M}} t)`` for ``t>0``. The density of states ``A(\omega)`` can be obtained as
```math
\begin{aligned}
\pi A(\omega) 
&= \textrm{Re}\left\{\int_0^\infty dt \langle d(t)d^\dagger(0)\rangle e^{i\omega t}\right\} + \textrm{Re}\left\{\int_0^\infty dt \langle d^\dagger(t)d(0)\rangle e^{-i\omega t}\right\}\\
&= \textrm{Re}\left\{\int_0^\infty dt \langle d e^{\hat{\mathcal{M}} t}d^\dagger\rangle e^{i\omega t}\right\}+\textrm{Re}\left\{\int_0^\infty dt \langle d^\dagger e^{\hat{\mathcal{M}} t}d\rangle e^{-i\omega t}\right\}\\
&= -\textrm{Re}\left\{\langle d (\hat{\mathcal{M}} +i\omega)^{-1} d^\dagger\rangle + \langle d^\dagger (\hat{\mathcal{M}} -i\omega)^{-1} d\rangle\right\}\\
&= -\textrm{Re}\left\{\textrm{Tr}\left[ d (\hat{\mathcal{M}} +i\omega)^{-1} d^\dagger\rho^{(m,n,+)}_{\textbf{j} \vert \textbf{q}}\right] + \textrm{Tr}\left[ d^\dagger (\hat{\mathcal{M}} -i\omega)^{-1} d\rho^{(m,n,+)}_{\textbf{j} \vert \textbf{q}}\right]\right\},
\end{aligned}
```
where a half-Fourier transform has been introduced in the third line. We note that only the reduced density operator (``m=n=0``) is considered when taking the final trace operation.

The function [`spectrum`](@ref) solves two linear problems ``\textbf{A}_+ \textbf{x}_+=\textbf{b}_+`` and ``\textbf{A}_- \textbf{x}_-=\textbf{b}_-`` at a fixed frequency ``\omega`` where 
 - ``\textbf{A}_+=\hat{\mathcal{M}}+i\omega``
 - ``\textbf{b}_+=d^\dagger\rho^{(m,n,+)}_{\textbf{j} \vert \textbf{q}}`` 
 - ``\textbf{A}_-=\hat{\mathcal{M}}-i\omega``
 - ``\textbf{b}_-=d\rho^{(m,n,+)}_{\textbf{j} \vert \textbf{q}}`` 
using the package [LinearSolve.jl](http://linearsolve.sciml.ai/stable/).

Finially, one can obtain the density of states for specific ``\omega``, namely
```math
\pi A(\omega) = -\textrm{Re}\left\{\textrm{Tr}\left[ d \textbf{x}_+\right]+\textrm{Tr}\left[ d^\dagger \textbf{x}_-\right]\right\}.
```

!!! note "Odd-Parity for Density of States"
    As shown above, the HEOMLS matrix ``\hat{\mathcal{M}}`` acts on the `ODD`-parity space, compatibly with the parity of both the operators ``d\rho^{(m,n,+)}_{\textbf{j} \vert \textbf{q}}`` and ``d^\dagger\rho^{(m,n,+)}_{\textbf{j} \vert \textbf{q}}``.  
    Therefore, remember to construct ``\hat{\mathcal{M}}`` with `ODD` [parity](@ref doc-Parity) for solving spectrum of fermionic systems.

See also the docstring : [`spectrum`](@ref)

```julia
Hs::AbstractMatrix # system Hamiltonian
bath::FermionBath  # fermionic bath object
tier::Int          # fermionic truncation level 

# create HEOMLS matrix in both :even and ODD parity
M_even = M_Fermion(Hs, tier, bath) 
M_odd  = M_Fermion(Hs, tier, bath, ODD) 

# the input state can be in either type of density operator matrix or ADOs (but usually ADOs):
ados = SteadyState(M_even)

# the (usually annihilation) operator "d" as shown above
d::AbstractMatrix 

# the spectrum value for the specific frequency ω which need to be solved
ω_list = 0:0.5:2 # [0.0, 0.5, 1.0, 1.5, 2.0]

πAω = spectrum(M_odd, ados, d, ω_list)
```