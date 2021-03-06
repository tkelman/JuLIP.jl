"""
## module Potentials

### Summary

This module implements some basic interatomic potentials in pure Julia, as well
as provides building blocks and prototypes for further implementations
The implementation is done in such a way that they can be used either in "raw"
form or within abstract frameworks.

### Types

### `evaluate`, `evaluate_d`, `evaluate_dd`, `grad`

### The `@D`, `@DD`, `@GRAD` macros

TODO: write documentation

"""
module Potentials

using JuLIP: AbstractAtoms, AbstractNeighbourList, AbstractCalculator,
      bonds, sites,
      JVec, JVecs, mat, vec

# we also import grad from JuLIP, but to define derivatives
import JuLIP: grad, energy, forces, cutoff

export Potential, PairPotential, SitePotential

"""
`Potential`: generic abstract supertype for all potential-like things
"""
abstract Potential <: AbstractCalculator


"""
`PairPotential`: abstract supertype for pair potentials
"""
abstract PairPotential <: Potential

"""
`SitePotential`: abstract supertype for generic site potentials
"""
abstract SitePotential <: Potential


include("potentials_base.jl")
# * @pot, @D, @DD, @GRAD and related things


# Implementation of a generic site potential
# ================================================

energies(pot::SitePotential, at::AbstractAtoms) =
   Float64[ pot(r, R) for (_1,_2, r, R,_4) in sites(at, cutoff(pot)) ]

energy(pot::SitePotential, at::AbstractAtoms) = sum_kbn(energies(pot, at))

function forces(pot::SitePotential, at::AbstractAtoms)
   frc = zerovecs(length(at))
   for (i, j, r, R, _) in sites(at, cutoff(pot))
      dpot = @D pot(r, R)
      frc[j] -= dpot
      frc[i] += sum(dpot)
   end
   return frc
end



include("analyticpotential.jl")
# * AnalyticPotential

include("cutoffs.jl")
#   * SWCutoff
#   * ShiftCutoff
#   * SplineCutoff

include("pairpotentials.jl")
# * PairCalculator
# * LennardJonesPotential
# * MorsePotential
# * SimpleExponential

try
   include("adsite.jl")
   # * FDPotential : Site potential using ForwardDiff
catch
   warn("""adsite.jl could not be included; most likely some AD package is missing;
      at the moment it needs `ForwardDiff, ReverseDiffPrototype`""")
end

include("EMT.jl")
# * EMTCalculator

include("stillingerweber.jl")
# * type StillingerWeber



export ZeroSitePotential

@pot type ZeroSitePotential <: Potential
end

"a site potential that just returns zero"
ZeroSitePotential

evaluate(p::ZeroSitePotential, r, R) = 0.0
evaluate_d(p::ZeroSitePotential, r, R) = zeros(r)
cutoff(::ZeroSitePotential) = 0.0


end
