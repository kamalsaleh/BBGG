LoadPackage( "StableCategoriesForCAP" );
ReadPackage( "BBGG", "/examples/glp_over_g_exterior_algebra/glp_over_g_exterior_algebra.g" );
ReadPackage( "BBGG", "/examples/glp_over_g_exterior_algebra/complexes_of_graded_left_presentations_over_graded_polynomial_ring.g" );

BindGlobal( "ADD_METHODS_TO_STABLE_CAT_OF_GRADED_LEFT_PRESENTATIONS_OVER_EXTERIOR_ALGEBRA",

function( category )

##
AddLiftColift( category,
    function( alpha, beta, gamma, delta )
    local lift;
    lift := graded_colift_lift_in_stable_category(
            UnderlyingUnstableMorphism( alpha ),
            UnderlyingUnstableMorphism( beta ),
            UnderlyingUnstableMorphism( gamma ),
            UnderlyingUnstableMorphism( delta )
            );
    if lift = fail then
        return fail;
    else
        return AsStableMorphism( lift );
    fi;

    end );

## Since we have LiftColift, we automatically have Lifts & Colifts (see Derivations in Triangulated categories).
##
AddIsSplitMonomorphism( category,
    function( mor )
    local l;
    l := Colift( mor, IdentityMorphism( Source( mor ) ) );

    if l = fail then
        AddToReasons( "IsSplitMonomorphism: because the morphism can not be colifted to the identity morphism of the source" );
        return false;
    else
        return true;
    fi;

end );

AddIsSplitEpimorphism( category,
    function( mor )
    local l;
    l := Lift( IdentityMorphism( Range( mor ) ), mor );

    if l = fail then
        AddToReasons( "IsSplitMonomorphism: because the morphism can not be lifted to the identity morphism of the Range" );
        return false;
    else
        return true;
    fi;

end );

AddInverseImmutable( category,
    function( mor )
    return Lift( IdentityMorphism( Range( mor ) ), mor );
end );

end );

generators_of_stable_hom := function( M, N )
    local basis;
    basis := graded_generators_of_external_hom( UnderlyingUnstableObject(M), UnderlyingUnstableObject(N));
    Apply( basis, AsStableMorphism );
    basis := DuplicateFreeList( Filtered( basis, b -> not IsZeroForMorphisms( b ) ) );
    return basis;
end;

graded_compute_coefficients_for_stable_morphisms := function( b, f )
    local R, basis_indices, Q, a, A, B, C, vec, main_list, matrix, constant, M, N, sol, F;

    M := Source( f );
    N := Range( f );

    if not IsWellDefined( f ) then
        return fail;
    fi;

    R := HomalgRing( UnderlyingMatrix( M ) );
    basis_indices := standard_list_of_basis_indices( R );
    Q := CoefficientsRing( R );

    F := List( b, UnderlyingMatrix );
    a := MonomorphismIntoSomeInjectiveObject( UnderlyingUnstableObject( M ) );
    A := UnderlyingMatrix( a );
    B := UnderlyingMatrix( N );
    C := UnderlyingMatrix( f );

    vec := function( H ) return Iterated( List( [ 1 .. NrColumns( H ) ], i -> CertainColumns( H, [ i ] ) ), UnionOfRows ); end;

    main_list :=
        List( [ 1 .. Length( basis_indices) ],
        function( i )
        local current_F, current_C, main;
        current_F := List( F, g -> DecompositionOfHomalgMat( g )[i][2]*Q );
        current_C := DecompositionOfHomalgMat(C)[ i ][2]*Q;
        main := UnionOfColumns( Iterated( List( current_F, vec ), UnionOfColumns ), FF2( basis_indices[i], A, B )*Q );
        return [ main, vec( current_C) ];
        end );

    matrix :=   Iterated( List( main_list, m -> m[ 1 ] ), UnionOfRows );
    constant := Iterated( List( main_list, m -> m[ 2 ] ), UnionOfRows );
    sol := LeftDivide( matrix, constant );
    if sol = fail then
        return fail;
    else
        return EntriesOfHomalgMatrix( CertainRows( sol, [ 1..Length( b ) ] ) );
    fi;
end;

basis_of_stable_hom := function( M, N )
local generators, i, basis;

generators := generators_of_stable_hom( M, N );

if generators = [ ] then
    return [ ];
fi;

basis := [ generators[ 1 ] ];

for i in [ 2 .. Length( generators ) ] do

    if WithComments = true then
        Print( "Testing the redundancy of the ", i, "'th morphism out of ", Length( generators ), "morphisms!." );
    fi;

    if graded_compute_coefficients_for_stable_morphisms( basis, generators[ i ] ) = fail then
        Add( basis, generators[ i ] );
    fi;
od;

return basis;
end;

DeclareAttribute( "iso_to_reduced_stable_module", IsStableCategoryObject );
DeclareAttribute( "iso_from_reduced_stable_module", IsStableCategoryObject );

InstallMethod( iso_to_reduced_stable_module,
            [ IsStableCategoryObject ],
    function( M )
    local m, hM, s, rM, cM, iso;
    cM := UnderlyingUnstableObject( M );
    m := is_reduced_graded_module( cM );
    if m = true then
        hM := AsPresentationInHomalg( cM );
        ByASmallerPresentation( hM );
        s := PositionOfTheDefaultPresentation( hM );
        rM := AsGradedLeftPresentation( MatrixOfRelations( hM ), DegreesOfGenerators( hM ) );
        return AsStableMorphism( GradedPresentationMorphism( cM, TransitionMatrix( hM, 1, s ), rM ) );
    else
        iso := PreCompose( AsStableMorphism( CokernelProjection( m[ 2 ] ) ), iso_to_reduced_stable_module( AsStableObject( CokernelObject( m[ 2 ] ) ) ) );
        Assert( 3, IsIsomorphism( iso ) );
        SetIsIsomorphism( iso, true );
        return iso;
    fi;
end );

InstallMethod( iso_from_reduced_stable_module,
            [ IsStableCategoryObject ],
    function( M )
    return Inverse( iso_to_reduced_stable_module( M ) );
end );

# this function can be implemented using the monoidal structure of lp over the polynomial ring
graded_generators_of_external_hom := function( M, N )
	local hM, hN, G;
	hM := AsPresentationInHomalg( M );
	hN := AsPresentationInHomalg( N );
	G := GetGenerators( Hom( hM, hN ) );
	return List( G, AsPresentationMorphismInCAP );
end;

n := InputFromUser( "Please enter n to define the polynomial ring Q[x_0,...,x_n],  n = " );
vars := Concatenation( Concatenation( [ "x0" ] , List( [ 1 .. n ], i -> Concatenation( ",x", String( i ) ) ) ) );
R := HomalgFieldOfRationalsInSingular( )*vars;
S := GradedRing( R );
A := KoszulDualRing( S );

lp_cat_sym := LeftPresentations( R );

graded_lp_cat_sym := GradedLeftPresentations( S : FinalizeCategory := false );

AddEvaluationMorphismWithGivenSource( graded_lp_cat_sym,
    function( a, b, s )
    local mor;
    mor := EvaluationMorphismWithGivenSource( UnderlyingPresentationObject( a ), UnderlyingPresentationObject( b ), UnderlyingPresentationObject( s ) );
    return GradedPresentationMorphism( s, UnderlyingMatrix( mor )*S, b );
end );

AddCoevaluationMorphismWithGivenRange( graded_lp_cat_sym,
    function( a, b, r )
    local mor;
    mor := CoevaluationMorphismWithGivenRange( UnderlyingPresentationObject( a ), UnderlyingPresentationObject( b ), UnderlyingPresentationObject( r ) );
    return GradedPresentationMorphism( a, UnderlyingMatrix( mor )*S, r );
end );

AddEpimorphismFromSomeProjectiveObject( graded_lp_cat_sym,
    function( M )
    local hM, U, current_degrees;
    hM := AsPresentationInHomalg( M );
    ByASmallerPresentation( hM );
    U := UnderlyingModule( hM );
    current_degrees := DegreesOfGenerators( hM );
    return GradedPresentationMorphism(
                GradedFreeLeftPresentation( Length( current_degrees), S, current_degrees ),
                TransitionMatrix( U, PositionOfTheDefaultPresentation(U), 1 )*S,
                M );
end, -1 );

##
AddIsProjective( graded_lp_cat_sym,
    function( M )
    local l;
    l := Lift( IdentityMorphism( M ), EpimorphismFromSomeProjectiveObject( M ) );
    if l = fail then
	return false;
    else
	return true;
    fi;
end );

Finalize( graded_lp_cat_sym );

cospan_to_span := FunctorFromCospansToSpans( graded_lp_cat_sym );;
cospan_to_three_arrows := FunctorFromCospansToThreeArrows( graded_lp_cat_sym );;
span_to_three_arrows := FunctorFromSpansToThreeArrows( graded_lp_cat_sym );;
span_to_cospan := FunctorFromSpansToCospans( graded_lp_cat_sym );;

# constructing the chain complex category of left presentations over R
chains_lp_cat_sym := ChainComplexCategory( lp_cat_sym : FinalizeCategory := false );
AddLift( chains_lp_cat_sym, compute_lifts_in_chains );
AddColift( chains_lp_cat_sym, compute_colifts_in_chains );
AddIsNullHomotopic( chains_lp_cat_sym, phi -> not Colift( NaturalInjectionInMappingCone( IdentityMorphism( Source( phi ) ) ), phi ) = fail );
AddHomotopyMorphisms( chains_lp_cat_sym, compute_homotopy_chain_morphisms_for_null_homotopic_morphism );
Finalize( chains_lp_cat_sym );

# constructing the cochain complex category of left presentations over R
cochains_lp_cat_sym := CochainComplexCategory( lp_cat_sym : FinalizeCategory := false );
AddLift( cochains_lp_cat_sym, compute_lifts_in_cochains );
AddColift( cochains_lp_cat_sym, compute_colifts_in_cochains );
AddIsNullHomotopic( cochains_lp_cat_sym, phi -> not Colift( NaturalInjectionInMappingCone( IdentityMorphism( Source( phi ) ) ), phi ) = fail );
AddHomotopyMorphisms( cochains_lp_cat_sym, compute_homotopy_cochain_morphisms_for_null_homotopic_morphism );
Finalize( cochains_lp_cat_sym );

# constructing the chain complex category of graded left presentations over S
chains_graded_lp_cat_sym := ChainComplexCategory( graded_lp_cat_sym : FinalizeCategory := false );
AddLift( chains_graded_lp_cat_sym, compute_lifts_in_chains );
AddColift( chains_graded_lp_cat_sym, compute_colifts_in_chains );
AddIsNullHomotopic( chains_graded_lp_cat_sym, phi -> not Colift( NaturalInjectionInMappingCone( IdentityMorphism( Source( phi ) ) ), phi ) = fail );
AddHomotopyMorphisms( chains_graded_lp_cat_sym, compute_homotopy_chain_morphisms_for_null_homotopic_morphism );
Finalize( chains_graded_lp_cat_sym );

# constructing the cochain complex category of graded left presentations over S
cochains_graded_lp_cat_sym := CochainComplexCategory( graded_lp_cat_sym : FinalizeCategory := false );
AddLift( cochains_graded_lp_cat_sym, compute_lifts_in_cochains );
AddColift( cochains_graded_lp_cat_sym, compute_colifts_in_cochains );
AddIsNullHomotopic( cochains_graded_lp_cat_sym, phi -> not Colift( NaturalInjectionInMappingCone( IdentityMorphism( Source( phi ) ) ), phi ) = fail );
AddHomotopyMorphisms( cochains_graded_lp_cat_sym, compute_homotopy_cochain_morphisms_for_null_homotopic_morphism );
Finalize( cochains_graded_lp_cat_sym );

# constructing the category Ch( ch( graded_lp_Cat_sym ) ) and the it associated bicomplex category
cochains_cochains_graded_lp_cat_sym := CochainComplexCategory( cochains_graded_lp_cat_sym );
bicomplexes_of_graded_lp_cat_sym := AsCategoryOfBicomplexes( cochains_cochains_graded_lp_cat_sym );

# constructing the category of graded left presentations over exterior algebra A
graded_lp_cat_ext := GradedLeftPresentations( A: FinalizeCategory := false );
AddLiftAlongMonomorphism( graded_lp_cat_ext,
    function( iota, tau )
    local l;
    l := LiftAlongMonomorphism( UnderlyingPresentationMorphism( iota ),
            UnderlyingPresentationMorphism( tau ) );
    return GradedPresentationMorphism( Source( tau ), l, Source( iota ) );
end );

AddEpimorphismFromSomeProjectiveObject( graded_lp_cat_ext,
    function( M )
    local hM, U, current_degrees;
    hM := AsPresentationInHomalg( M );
    ByASmallerPresentation( hM );
    U := UnderlyingModule( hM );
    current_degrees := DegreesOfGenerators( hM );
    return GradedPresentationMorphism(
                GradedFreeLeftPresentation( Length( current_degrees), A, current_degrees ),
                TransitionMatrix( U, PositionOfTheDefaultPresentation(U), 1 )*A,
                M );
end, -1 );

SetIsFrobeniusCategory( graded_lp_cat_ext, true );
ADD_METHODS_TO_GRADED_LEFT_PRESENTATIONS_OVER_EXTERIOR_ALGEBRA( graded_lp_cat_ext );
TurnAbelianCategoryToExactCategory( graded_lp_cat_ext );
SetTestFunctionForStableCategories(graded_lp_cat_ext, CanBeFactoredThroughExactProjective );
Finalize( graded_lp_cat_ext );

cochains_graded_lp_cat_ext := CochainComplexCategory( graded_lp_cat_ext );

# constructing the stable category of graded left presentations over A and giving it the
# triangulated structure
stable_lp_cat_ext := StableCategory( graded_lp_cat_ext );
SetIsTriangulatedCategory( stable_lp_cat_ext, true );
ADD_METHODS_TO_STABLE_CAT_OF_GRADED_LEFT_PRESENTATIONS_OVER_EXTERIOR_ALGEBRA( stable_lp_cat_ext );
AsTriangulatedCategory( stable_lp_cat_ext );
Finalize( stable_lp_cat_ext );

# constructing the category of coherent sheaves over P^n = Proj(S)
IsFiniteDimensionalGradedLeftPresentation := function(M)
                                            return IsZero(HilbertPolynomial(AsPresentationInHomalg(M)));
                                            end;
C := FullSubcategoryByMembershipFunction(graded_lp_cat_sym, IsFiniteDimensionalGradedLeftPresentation );
coh := graded_lp_cat_sym / C;
cochains_of_coh := CochainComplexCategory( coh );
cochains_cochains_of_coh := CochainComplexCategory( cochains_of_coh );
bicomplexes_of_coh := AsCategoryOfBicomplexes( cochains_cochains_of_coh );

# The sheafification functor
Sh := CanonicalProjection( coh );
ChSh := ExtendFunctorToCochainComplexCategoryFunctor(Sh);
BiSh := ExtendFunctorToCohomologicalBicomplexCategoryFunctor(Sh);


##
St := CapFunctor( "modules to stable modules", graded_lp_cat_sym, stable_lp_cat_ext );
AddObjectFunction( St,
	function( M )
	local tM;
	tM := TateResolution( M );
	return AsStableObject( Source( CyclesAt( tM, 0 ) ) );
end );

AddMorphismFunction( St,
	function( s, f, r )
	local tf;
	tf := TateResolution( f );
	return AsStableMorphism( KernelLift( Range( tf )^0, PreCompose( CyclesAt( Source( tf ), 0 ), tf[ 0 ] ) ) );
end );

##
AsStable := CapFunctor( "as stable functor", graded_lp_cat_ext, stable_lp_cat_ext );
AddObjectFunction( AsStable, AsStableObject );
AddMorphismFunction( AsStable,
	function( s, f, r )
	return AsStableMorphism( f );
end );

w_A := function(k)
	return ApplyFunctor( TwistFunctor( A, k ),
			     GradedFreeLeftPresentation( 1, A, [ Length( IndeterminatesOfExteriorRing( A ) ) ] ) );
end;

RR := RFunctor( S );
ChRR := ExtendFunctorToCochainComplexCategoryFunctor( RR );
LL := LFunctor( S );
ChLL := ExtendFunctorToCochainComplexCategoryFunctor( LL );
TT := TateFunctor( S );

Trunc_leq_m1 := BrutalTruncationAboveFunctor( cochains_graded_lp_cat_sym, -1 );;

KeyDependentOperation( "_Trunc_leq_rm1", IsHomalgGradedRing, IsInt, ReturnTrue );
InstallMethod( _Trunc_leq_rm1Op,
            [ IsHomalgGradedRing, IsInt ],
    function( S, r )
    return BrutalTruncationAboveFunctor( cochains_graded_lp_cat_ext, r - 1 );
end );


KeyDependentOperation( "_Trunc_g_rm1", IsHomalgGradedRing, IsInt, ReturnTrue );
InstallMethod( _Trunc_g_rm1Op,
            [ IsHomalgGradedRing, IsInt ],
    function( S, r )
    return BrutalTruncationBelowFunctor( cochains_graded_lp_cat_ext, r - 1 );
end );

ChTrunc_leq_m1 := ExtendFunctorToCochainComplexCategoryFunctor( Trunc_leq_m1 );;

# the functor from the category of bicomplexes to cochains that returns the cochain of vertical cohomologies
# at row -1

Cochain_of_ver_coho_sym := ComplexOfVerticalCohomologiesFunctorAt( bicomplexes_of_graded_lp_cat_sym, -1 );
Cochain_of_ver_coho_coh := ComplexOfVerticalCohomologiesFunctorAt( bicomplexes_of_coh, -1 );

Coh0_sym := CohomologyFunctorAt( cochains_graded_lp_cat_sym, graded_lp_cat_sym, 0 );
Coh0_coh := CohomologyFunctorAt( cochains_of_coh, coh, 0 );

KeyDependentOperation( "_Cochain_of_hor_coho_sym_rm1", IsHomalgGradedRing, IsInt, ReturnTrue );
KeyDependentOperation( "_Cochain_of_hor_coho_coh_rm1", IsHomalgGradedRing, IsInt, ReturnTrue );
KeyDependentOperation( "_Coh_mr_sym", IsHomalgGradedRing, IsInt, ReturnTrue );
KeyDependentOperation( "_Coh_mr_coh", IsHomalgGradedRing, IsInt, ReturnTrue );
KeyDependentOperation( "_Coh_r_ext", IsHomalgGradedRing, IsInt, ReturnTrue );

##
InstallMethod( _Coh_r_extOp,
            [ IsHomalgGradedRing, IsInt ],
    function( S, r )
    return CohomologyFunctorAt( cochains_graded_lp_cat_ext, graded_lp_cat_ext, r );
end );

##
InstallMethod( _Cochain_of_hor_coho_sym_rm1Op,
            [ IsHomalgGradedRing, IsInt ],
    function( S, r )
    return ComplexOfHorizontalCohomologiesFunctorAt( bicomplexes_of_graded_lp_cat_sym, r - 1 );
end );

##
InstallMethod( _Cochain_of_hor_coho_coh_rm1Op,
            [ IsHomalgGradedRing, IsInt ],
    function( S, r )
    return ComplexOfHorizontalCohomologiesFunctorAt( bicomplexes_of_coh, r - 1 );
end );

##
InstallMethod( _Coh_mr_symOp,
            [ IsHomalgGradedRing, IsInt ],
    function( S, r )
    return CohomologyFunctorAt( cochains_graded_lp_cat_sym, graded_lp_cat_sym, -r );
end );

##
InstallMethod( _Coh_mr_cohOp,
            [ IsHomalgGradedRing, IsInt ],
    function( S, r )
    return CohomologyFunctorAt( cochains_of_coh, coh, -r );
end );


# Ch(Ch( graded_lp_cat_sym )) -> Bicomplex( graded__lp_cat_sym)

ChCh_to_Bi_sym := ComplexOfComplexesToBicomplexFunctor(cochains_cochains_graded_lp_cat_sym, bicomplexes_of_graded_lp_cat_sym );;

##
Beilinson_complex_Serre_v1 := CapFunctor( "Beilinson Complex functor (Output is cochain of sheaves)",
                            graded_lp_cat_sym, cochains_of_coh );
AddObjectFunction( Beilinson_complex_Serre_v1,
    function( M )
    return ApplyFunctor(
        PreCompose( [ TT, ChLL, ChTrunc_leq_m1, ChCh_to_Bi_sym, BiSh, Cochain_of_ver_coho_coh ] ), M );;
end );

AddMorphismFunction( Beilinson_complex_Serre_v1,
    function( new_source, f, new_range )
    return ApplyFunctor(
        PreCompose( [ TT, ChLL, ChTrunc_leq_m1, ChCh_to_Bi_sym, BiSh, Cochain_of_ver_coho_coh ] ),
        f );;
end );

##
Beilinson_complex_sym := CapFunctor( "Beilinson Complex functor (Output is cochains of S-modules)",
                        graded_lp_cat_sym, cochains_graded_lp_cat_sym );
AddObjectFunction( Beilinson_complex_sym,
    function( M )
    return ApplyFunctor(
        PreCompose( [ TT, ChLL, ChTrunc_leq_m1, ChCh_to_Bi_sym, Cochain_of_ver_coho_sym ] ), M );;
end );

AddMorphismFunction( Beilinson_complex_sym,
    function( new_source, f, new_range )
    return ApplyFunctor(
        PreCompose( [ TT, ChLL, ChTrunc_leq_m1, ChCh_to_Bi_sym, Cochain_of_ver_coho_sym ] ), f );;
end );

##
Beilinson_complex_Serre_v2 := CapFunctor( "Beilinson Complex functor (Output is cochain of sheaves)",
                            graded_lp_cat_sym, cochains_of_coh );
AddObjectFunction( Beilinson_complex_Serre_v2,
    function( M )
    return ApplyFunctor( PreCompose( [ Beilinson_complex_sym, ChSh ] ), M );;
end );

AddMorphismFunction( Beilinson_complex_Serre_v2,
    function( new_source, f, new_range )
    return ApplyFunctor( PreCompose( [ Beilinson_complex_sym, ChSh ] ), f );;
end );



KeyDependentOperation( "TruncationToBeilinson", IsGradedLeftPresentation, IsInt, ReturnTrue );
InstallMethod( TruncationToBeilinsonOp,
                [ IsGradedLeftPresentation, IsInt ],
    function( M, r )
    local a, CV, CH, i1, i2, p1, p2, L, iso, Trunc_leq_rm1,
        indices, Cochain_of_hor_coho_sym_rm1, mono;
    if r < Maximum( 2, CastelnuovoMumfordRegularity( M ) ) then
        Error( "r should be >= maximim(2, reg(M))" );
    fi;
    Trunc_leq_rm1 := _Trunc_leq_rm1(S,r);
    Cochain_of_hor_coho_sym_rm1 := _Cochain_of_hor_coho_sym_rm1(S,r);

    a := ApplyFunctor( PreCompose( [ TT, Trunc_leq_rm1, ChLL, ChTrunc_leq_m1, ChCh_to_Bi_sym ] ), M );
    CV := ApplyFunctor( Cochain_of_ver_coho_sym, a );;
    CH := ApplyFunctor( Cochain_of_hor_coho_sym_rm1, a );;
    i1 := GeneralizedEmbeddingOfCohomologyAt( CH, -r );;
    i2 := GeneralizedEmbeddingOfHorizontalCohomologyAt( a, r-1, -r );;
    p1 := GeneralizedProjectionOntoVerticalCohomologyAt( a, 0, -1 );;
    p2 := GeneralizedProjectionOntoCohomologyAt( CV, 0 );
    indices := Reversed( List( [ 1 .. r-1 ], i -> [ i, -i ] ) );;
    L := List( indices,i -> GeneralizedMorphismByCospan(
            VerticalDifferentialAt( a, i[1], i[2]-1 ),
            HorizontalDifferentialAt( a, i[1]-1, i[2] ) ) );;
    cospan_to_span := FunctorFromCospansToSpans( graded_lp_cat_sym );;
    L := List( L, l -> ApplyFunctor( cospan_to_span, l ) );;
    mono := PreCompose( Concatenation( [ i1, i2 ], L, [ p1, p2 ] ) );
    iso := SerreQuotientCategoryMorphism( coh, ApplyFunctor( span_to_three_arrows, mono ) );
    return iso;
end );


Canonicalize_coh_v1 := CapFunctor( "Canonicalization Functor version 1",
                    graded_lp_cat_sym, coh );
AddObjectFunction( Canonicalize_coh_v1,
    function( M )
    local r;
    r := Maximum( 2, CastelnuovoMumfordRegularity( M ) );
    return ApplyFunctor(  PreCompose(
        [ TT,_Trunc_leq_rm1(S,r), ChLL, ChTrunc_leq_m1, ChCh_to_Bi_sym,
            _Cochain_of_hor_coho_sym_rm1(S,r), _Coh_mr_sym(S,r), Sh
        ] ), M );
end );

AddMorphismFunction( Canonicalize_coh_v1,
    function( source, f, range )
    local M1, M2, r1, r2, r, can_f_r, Br, Br1, Br2, CH,
    CH1, CH2, L, indices, lift, i1, i2, p1, p2, i, p;
    M1 := Source( f );
    M2 := Range( f );

    r1 := Maximum( 2, CastelnuovoMumfordRegularity( M1 ) );
    r2 := Maximum( 2, CastelnuovoMumfordRegularity( M2 ) );

    r := Maximum( r1, r2 );

    can_f_r := ApplyFunctor(  PreCompose(
        [ TT,_Trunc_leq_rm1(S,r), ChLL, ChTrunc_leq_m1, ChCh_to_Bi_sym,
            _Cochain_of_hor_coho_sym_rm1(S,r), _Coh_mr_sym(S,r), Sh
        ] ), f );
    if r1 < r then
        Br := ApplyFunctor(  PreCompose(
        [ TT,_Trunc_leq_rm1(S,r), ChLL, ChTrunc_leq_m1, ChCh_to_Bi_sym ] ), M1 );

        CH := ApplyFunctor( _Cochain_of_hor_coho_sym_rm1(S,r), Br );;

        Br1 := ApplyFunctor(  PreCompose(
        [ TT,_Trunc_leq_rm1(S,r1), ChLL, ChTrunc_leq_m1, ChCh_to_Bi_sym ] ), M1 );

        CH1 := ApplyFunctor( _Cochain_of_hor_coho_sym_rm1(S,r1), Br1 );;

        i1 := GeneralizedEmbeddingOfCohomologyAt( CH1, -r1 );
        i2 := GeneralizedEmbeddingOfHorizontalCohomologyAt( Br1, r1 - 1, -r1 );
        i := PreCompose( i1, i2 );
        i := ApplyFunctor( span_to_cospan, i );
        p1 := GeneralizedProjectionOntoHorizontalCohomologyAt( Br, r - 1, -r );
        p2 := GeneralizedProjectionOntoCohomologyAt( CH, -r );
        p := PreCompose( p1, p2 );
        p := ApplyFunctor( span_to_cospan, p );
        indices := List( [ r1 .. r - 1 ], i -> [ i, -i ] );
        L := List( indices, i -> GeneralizedMorphismByCospan(
            HorizontalDifferentialAt( Br, i[1]-1, i[2] ), VerticalDifferentialAt( Br, i[1], i[2] -1 )
            ) );

        lift := PreCompose( [ i, L, p ] );
        lift := ApplyFunctor( cospan_to_three_arrows, lift );
        lift := SerreQuotientCategoryMorphism( coh, lift );

        return PreCompose( lift, can_f_r );
    elif r2 < r then
        Br := ApplyFunctor(  PreCompose(
        [ TT,_Trunc_leq_rm1(S,r), ChLL, ChTrunc_leq_m1, ChCh_to_Bi_sym ] ), M2 );

        CH := ApplyFunctor( _Cochain_of_hor_coho_sym_rm1(S,r), Br );;

        Br2 := ApplyFunctor(  PreCompose(
        [ TT,_Trunc_leq_rm1(S,r2), ChLL, ChTrunc_leq_m1, ChCh_to_Bi_sym ] ), M2 );

        CH2 := ApplyFunctor( _Cochain_of_hor_coho_sym_rm1(S,r2), Br2 );;

        i1 := GeneralizedEmbeddingOfCohomologyAt( CH, -r );
        i2 := GeneralizedEmbeddingOfHorizontalCohomologyAt( Br, r - 1, -r );
        i := PreCompose( i1, i2 );
        i := ApplyFunctor( span_to_cospan, i );
        p1 := GeneralizedProjectionOntoHorizontalCohomologyAt( Br2, r2 - 1, -r2 );
        p2 := GeneralizedProjectionOntoCohomologyAt( CH2, -r2 );
        p := PreCompose( p1, p2 );
        p := ApplyFunctor( span_to_cospan, p );
        indices := Reversed( List( [ r2 .. r - 1 ], i -> [ i, -i ] ) );
        L := List( indices, i -> GeneralizedMorphismByCospan(
            VerticalDifferentialAt( Br, i[1], i[2] -1 ), HorizontalDifferentialAt( Br, i[1]-1, i[2] )
            ) );
        L := PreCompose(L);

        lift := PreCompose( [ i, L, p ] );
        lift := ApplyFunctor( cospan_to_three_arrows, lift );
        lift := SerreQuotientCategoryMorphism( coh, lift );

        return PreCompose( can_f_r, lift );
    else
        return can_f_r;
    fi;
end );


Nat_1 := NaturalTransformation( "Nat. iso. from Canonicalize -> Sh(H0(Beilinson))",
        Canonicalize_coh_v1, PreCompose( [ Beilinson_complex_sym, Coh0_sym, Sh ] ) );
AddNaturalTransformationFunction( Nat_1,
    function( source, M, range )
    return TruncationToBeilinson( M, Maximum( 2, CastelnuovoMumfordRegularity ( M ) ) );
end );

Standard_coh_v1 := CapFunctor( "Some Name", graded_lp_cat_sym, coh );
Nat_2 := NaturalTransformation( "Nat. iso. from Canonicalize -> Standard",
    Canonicalize_coh_v1, Standard_coh_v1 );

AddObjectFunction( Standard_coh_v1,
    function( M )
    local r, tM, lift, P, phi;
    r := Maximum( 2, CastelnuovoMumfordRegularity( M ) );
    tM := ApplyFunctor( PreCompose( [ TT ] ), M );
    lift := KernelLift( tM^r, tM^(r-1) );
    P := Range( lift );
    phi := CochainMorphism(
        ApplyFunctor( _Trunc_leq_rm1(S,r), tM ),
        StalkCochainComplex( P, r - 1 ),
        [ lift ], r - 1 );
    phi := ApplyFunctor(
        PreCompose( [ ChLL, ChCh_to_Bi_sym, _Cochain_of_hor_coho_sym_rm1(S,r), _Coh_mr_sym(S,r), Sh ] ),
         phi );
    return Range( phi );
end );

AddMorphismFunction( Standard_coh_v1,
    function( source, f, range )
    local M1, M2;

    M1 := Source( f );
    M2 := Range( f );

    return PreCompose(
        [
            Inverse( ApplyNaturalTransformation( Nat_2, M1 ) ),
            ApplyFunctor( Canonicalize_coh_v1, f ),
            ApplyNaturalTransformation( Nat_2, M2 )
        ]
    );
end );

AddNaturalTransformationFunction( Nat_2,
    function( source, M, range )
    local r, tM, lift, P, phi;
    r := Maximum( 2, CastelnuovoMumfordRegularity( M ) );
    tM := ApplyFunctor( PreCompose( [ TT ] ), M );
    lift := KernelLift( tM^r, tM^(r-1) );
    P := Range( lift );
    phi := CochainMorphism(
        ApplyFunctor( _Trunc_leq_rm1(S,r), tM ),
        StalkCochainComplex( P, r - 1 ),
        [ lift ], r - 1 );
    phi := ApplyFunctor(
        PreCompose( [ ChLL, ChCh_to_Bi_sym, _Cochain_of_hor_coho_sym_rm1(S,r), _Coh_mr_sym(S,r), Sh ] ),
         phi );
    return phi;
end );

TruncateModule_sym := CapFunctor( "to be named", graded_lp_cat_sym, graded_lp_cat_sym );

AddObjectFunction( TruncateModule_sym,
    function( M )
    local r;
    r := Maximum( 2, CastelnuovoMumfordRegularity( M ) );
    return GradedLeftPresentationGeneratedByHomogeneousPart( M, r);
end );

AddMorphismFunction( TruncateModule_sym,
    function( source, f, range )
    local M1, M2, emb1, emb2, r1, r2;
    M1 := Source( f );
    M2 := Range( f );

    r1 := Maximum( 2, CastelnuovoMumfordRegularity( M1 ) );
    r2 := Maximum( 2, CastelnuovoMumfordRegularity( M2 ) );

    M1 := GradedLeftPresentationGeneratedByHomogeneousPart( M1, r1 );
    M2 := GradedLeftPresentationGeneratedByHomogeneousPart( M2, r2 );

    emb1 := EmbeddingInSuperObject( M1 );
    emb2 := EmbeddingInSuperObject( M2 );

    return LiftAlongMonomorphism( emb2, PreCompose( emb1, f ) );
end );

Nat_3 := NaturalTransformation( "from truncation functor to identity functor",
        TruncateModule_sym, IdentityFunctor( graded_lp_cat_sym ) );
AddNaturalTransformationFunction( Nat_3,
    function( source, M, range )
    local r;
    r := Maximum( 2, CastelnuovoMumfordRegularity( M ) );
    return EmbeddingInSuperObject( GradedLeftPresentationGeneratedByHomogeneousPart( M, r ) );
end );

quit;

AddMorphismFunction( Standard_coh,
    function( source, f, range )
    local M1, M2, r1, r2, r, stand_f;
    M1 := Source( f );
    M2 := Range( f );

    r1 := Maximum( 2, CastelnuovoMumfordRegularity( M1 ) );
    r2 := Maximum( 2, CastelnuovoMumfordRegularity( M2 ) );

    r := Maximum( r1, r2 );

    stand_f := ApplyFunctor( PreCompose(
        [ TT, _Trunc_g_rm1( S, r ), _Coh_r_ext(S, r), LL, _Coh_mr_sym( S, r ), Sh ] ), f );
    if r1 < r then

        tMr1 := ApplyFunctor( PreCompose( [ TT, _Trunc_g_rm1(S, r1) ] ), M1 );
        P1 := ApplyFunctor( _Coh_r_ext( S, r1 ), tMr1 );
        phi := CochainMorphism(
            StalkCochainComplex( P1, r1 ),
            tMr1,
            [ HonestRepresentative( GeneralizedEmbeddingOfCohomologyAt( tMr1, r1 ) ) ],
            r1 );
        phi_r1 := ApplyFunctor( PreCompose( [ ChLL, ChCh_to_Bi_sym ] ), phi );

        tMr := ApplyFunctor( PreCompose( [ TT, _Trunc_g_rm1(S, r) ] ), M1 );
        P := ApplyFunctor( _Coh_r_ext( S, r ), tMr );
        phi := CochainMorphism(
            StalkCochainComplex( P, r ),
            tMr,
            [ HonestRepresentative( GeneralizedEmbeddingOfCohomologyAt( tM, r ) ) ],
            r );
        phi_r := ApplyFunctor( PreCompose( [ ChLL, ChCh_to_Bi_sym ] ), phi );
        i1 := GeneralizedEmbeddingOfVerticalCohomologyAt( Source( phi_r1 ), r1, -r1 );
        i1 := ApplyFunctor( span_to_three_arrows, i1 );
        i2 := MorphismAt( phi_r1, r1, -r1 );
        indices := List( [ r1 + 1 .. r ], i -> [ i, -i + 1 ] );
        L := List( indices, i -> GeneralizedMorphismByCospan(
            HorizontalDifferentialAt( Range( phi_r ), i[1] - 1, i[2] ),
            VerticalDifferentialAt( Range( phi_r ), i[1], i[2] - 1 )
        ) );

        p1 := MorphismAt( phi_r, r, -r );
        p1 := ApplyFunctor( Sh, p1 );
        p2 := GeneralizedProjectionOfVerticalCohomologyAt( Source( phi_r ), r, -r );
        p2 := ApplyFunctor( span_to_three_arrows, p );



    elif r2 < r then
        Error( "to do" );
    else
        return stand_f;
    fi;

end );

Canonicalize_coh_v2 := CapFunctor( "Canonicalization Functor",
                    graded_lp_cat_sym, coh );
AddObjectFunction( Canonicalize_coh_v2,
    function( M )
    local r;
    r := Maximum( 2, CastelnuovoMumfordRegularity( M ) );
    return ApplyFunctor(  PreCompose(
        [ TT,_Trunc_leq_rm1(S,r), ChLL, ChTrunc_leq_m1, ChCh_to_Bi_sym,
            _Cochain_of_hor_coho_sym_rm1(S,r), _Coh_mr_sym(S,r), Sh
        ] ), M );
end );

AddMorphismFunction( Canonicalize_coh_v2,
    function( source, f, range )
    local M1, M2, r1, r2, r, can_f_r;
    M1 := Source( f );
    M2 := Range( f );

    r1 := Maximum( 2, CastelnuovoMumfordRegularity( M1 ) );
    r2 := Maximum( 2, CastelnuovoMumfordRegularity( M2 ) );

    r := Maximum( r1, r2 );

    can_f_r := ApplyFunctor(  PreCompose(
        [ TT,_Trunc_leq_rm1(S,r), ChLL, ChTrunc_leq_m1, ChCh_to_Bi_sym,
            _Cochain_of_hor_coho_sym_rm1(S,r), _Coh_mr_sym(S,r), Sh
        ] ), f );
    if r1 < r then
        return PreCompose(
        # LiftAlongMonomorphism( TruncationToBeilinson( M1, r ), TruncationToBeilinson( M1, r1 ) )
        # or pre...
            PreCompose( TruncationToBeilinson( M1, r1 ), Inverse( TruncationToBeilinson( M1, r ) ) ),
            can_f_r
            );
    elif r2 < r then
        return PreCompose(
            can_f_r,
        #LiftAlongMonomorphism( TruncationToBeilinson( M2, r2 ), TruncationToBeilinson( M2, r ) )
        # or pre...
            PreCompose( TruncationToBeilinson( M2, r ), Inverse( TruncationToBeilinson( M2, r2 ) ) )
            );
    else
        return can_f_r;
    fi;
end );

test_right := function( M, i )
    local r, Mr, emb_of_Mr, Trunc_leq_m1, Cochain_of_hor_coho_sym_rm1, Coh_mr,
        tM, colift, P, Pr, emb_of_Pr, emb, mat, tau1, tau2, phi, tau, mono1, mono2,
        a, CV, CH, i1, i2, p1, p2, L, iso1, iso2, Trunc_leq_rm1, indices;
    #r := Maximum( 2, CastelnuovoMumfordRegularity( M ) ) + i;;
    r := i;
    Mr := GradedLeftPresentationGeneratedByHomogeneousPart( M, r );
    emb_of_Mr := EmbeddingInSuperObject( Mr );

    # Using r we define 3 functors:

    # the following functor truncates the tate resolution (the output is concentrated in window
    #[ -ifinity .. r - 1 ] ).
    Trunc_leq_rm1 := _Trunc_leq_rm1(S,r);

    # This functor computes the complex of horizontal cohomologies of a bicomplex at index r
    Cochain_of_hor_coho_sym_rm1 := _Cochain_of_hor_coho_sym_rm1(r);

    # This computes the Cohomology at cohomological index -r
    Coh_mr := _Coh_mr_sym(r);

    # Hom_S(L(P),M) \sim Hom_k(P,M) \sim Hom_A(P,R(M))
    tM := ApplyFunctor( TT, M );;
    colift := CokernelColift( tM^(r-2), tM^(r-1) );;
    P := CokernelObject( tM^(r-2) );;
    Pr := GradedLeftPresentationGeneratedByHomogeneousPart( P, r );;
    emb_of_Pr := EmbeddingInSuperObject( Pr );;
    emb := PreCompose( emb_of_Pr, colift );;
    mat := UnderlyingMatrix(emb);;
    mat := DecompositionOfHomalgMat(mat)[2^(n+1)][2]*S;;

    # We don't need tM anymore, we only need now a truncation of it.
    tM := ApplyFunctor( PreCompose( [ TT, Trunc_leq_rm1 ] ), M );
    phi := CochainMorphism( tM, StalkCochainComplex( P, r - 1 ),
                            [ CokernelProjection( tM^(r-2) ) ], r - 1 );

    tau1 := ApplyFunctor(
        PreCompose( [ ChLL, ChTrunc_leq_m1, ChCh_to_Bi_sym, Cochain_of_hor_coho_sym_rm1 ] ),
        phi );

    tau2 := CochainMorphism( Range( tau1 ), StalkCochainComplex( M, -r ),
        [ PreCompose(
            GradedPresentationMorphism( Range( tau1 )[ -r ], mat, Mr ), emb_of_Mr ) ], -r );

    # Note: You may think that the following tau is quasi-isomorphism, but it may not.
    # because here we are in modules not in (Serre Quotients).
    tau := PreCompose( tau1, tau2 );

    mono1 := PreCompose(
            ApplyFunctor( Coh_mr, tau ),
            HonestRepresentative( GeneralizedEmbeddingOfCohomologyAt( Range( tau ), -r ) )
            );

    a := ApplyFunctor( PreCompose( [ TT, Trunc_leq_rm1, ChLL, ChTrunc_leq_m1, ChCh_to_Bi_sym ] ), M );
    CV := ApplyFunctor( Cochain_of_ver_coho_sym, a );;
    CH := ApplyFunctor( Cochain_of_hor_coho_sym_rm1, a );;
    i1 := GeneralizedEmbeddingOfCohomologyAt( CH, -r );;
    i2 := GeneralizedEmbeddingOfHorizontalCohomologyAt( a, r-1, -r );;
    p1 := GeneralizedProjectionOntoVerticalCohomologyAt( a, 0, -1 );;
    p2 := GeneralizedProjectionOntoCohomologyAt( CV, 0 );
    indices := Reversed( List( [ 1 .. r-1 ], i -> [ i, -i ] ) );;
    L := List( indices,i -> GeneralizedMorphismByCospan(
            VerticalDifferentialAt( a, i[1], i[2]-1 ),
            HorizontalDifferentialAt( a, i[1]-1, i[2] ) ) );;
    cospan_to_span := FunctorFromCospansToSpans( graded_lp_cat_sym );;
    L := List( L, l -> ApplyFunctor( cospan_to_span, l ) );;
    mono2 := PreCompose( Concatenation( [ i1, i2 ], L, [ p1, p2 ] ) );
    return [ mono1, HonestRepresentative( mono2 )];
    iso1 := Inverse( ApplyFunctor( Sh, mono1 ) );
    iso2 := SerreQuotientCategoryMorphism( coh, ApplyFunctor( span_to_three_arrows, mono2 ) );

    return PreCompose( iso1, iso2 );

end;

# searching for the nat trans.
_nat := function(i)
local Nat;
if i<0 then Error("?");fi;

Nat := NaturalTransformation( "To be named", Sh, PreCompose( [ Beilinson_complex_sym, Coh0_sym, Sh ] ) );
AddNaturalTransformationFunction( Nat,
    function( source, M, range )
    local r, Mr, emb_of_Mr, Trunc_leq_m1, Cochain_of_hor_coho_sym_rm1, Coh_mr,
        tM, colift, P, Pr, emb_of_Pr, emb, mat, tau1, tau2, phi, tau, mono1, mono2,
        a, CV, CH, i1, i2, p1, p2, L, iso1, iso2, Trunc_leq_rm1, indices;
    #r := Maximum( 2, CastelnuovoMumfordRegularity( M ) ) + i;;
    r := i;
    Mr := GradedLeftPresentationGeneratedByHomogeneousPart( M, r );
    emb_of_Mr := EmbeddingInSuperObject( Mr );

    # Using r we define 3 functors:

    # the following functor truncates the tate resolution (the output is concentrated in window
    #[ -ifinity .. r - 1 ] ).
    Trunc_leq_rm1 := _Trunc_leq_rm1(r);

    # This functor computes the complex of horizontal cohomologies of a bicomplex at index r
    Cochain_of_hor_coho_sym_rm1 := _Cochain_of_hor_coho_sym_rm1(r);

    # This computes the Cohomology at cohomological index -r
    Coh_mr := CohomologyFunctorAt( cochains_graded_lp_cat_sym, graded_lp_cat_sym, -r );

    # Hom_S(L(P),M) \sim Hom_k(P,M) \sim Hom_A(P,R(M))
    tM := ApplyFunctor( TT, M );;
    colift := CokernelColift( tM^(r-2), tM^(r-1) );;
    P := CokernelObject( tM^(r-2) );;
    Pr := GradedLeftPresentationGeneratedByHomogeneousPart( P, r );;
    emb_of_Pr := EmbeddingInSuperObject( Pr );;
    emb := PreCompose( emb_of_Pr, colift );;
    mat := UnderlyingMatrix(emb);;
    mat := DecompositionOfHomalgMat(mat)[2^(n+1)][2]*S;;

    # We don't need tM anymore, we only need now a truncation of it.
    tM := ApplyFunctor( PreCompose( [ TT, Trunc_leq_rm1 ] ), M );
    phi := CochainMorphism( tM, StalkCochainComplex( P, r - 1 ),
                            [ CokernelProjection( tM^(r-2) ) ], r - 1 );

    tau1 := ApplyFunctor(
        PreCompose( [ ChLL, ChTrunc_leq_m1, ChCh_to_Bi_sym, Cochain_of_hor_coho_sym_rm1 ] ),
        phi );

    tau2 := CochainMorphism( Range( tau1 ), StalkCochainComplex( M, -r ),
        [ PreCompose(
            GradedPresentationMorphism( Range( tau1 )[ -r ], mat, Mr ), emb_of_Mr ) ], -r );

    # Note: You may think that the following tau is quasi-isomorphism, but it may not.
    # because here we are in modules not in (Serre Quotients).
    tau := PreCompose( tau1, tau2 );

    mono1 := PreCompose(
            ApplyFunctor( Coh_mr, tau ),
            HonestRepresentative( GeneralizedEmbeddingOfCohomologyAt( Range( tau ), -r ) )
            );

    a := ApplyFunctor( PreCompose( [ TT, Trunc_leq_rm1, ChLL, ChTrunc_leq_m1, ChCh_to_Bi_sym ] ), M );
    CV := ApplyFunctor( Cochain_of_ver_coho_sym, a );;
    CH := ApplyFunctor( Cochain_of_hor_coho_sym_rm1, a );;
    i1 := GeneralizedEmbeddingOfCohomologyAt( CH, -r );;
    i2 := GeneralizedEmbeddingOfHorizontalCohomologyAt( a, r-1, -r );;
    p1 := GeneralizedProjectionOntoVerticalCohomologyAt( a, 0, -1 );;
    p2 := GeneralizedProjectionOntoCohomologyAt( CV, 0 );
    indices := Reversed( List( [ 1 .. r-1 ], i -> [ i, -i ] ) );;
    L := List( indices,i -> GeneralizedMorphismByCospan(
            VerticalDifferentialAt( a, i[1], i[2]-1 ),
            HorizontalDifferentialAt( a, i[1]-1, i[2] ) ) );;
    cospan_to_span := FunctorFromCospansToSpans( graded_lp_cat_sym );;
    L := List( L, l -> ApplyFunctor( cospan_to_span, l ) );;
    mono2 := PreCompose( Concatenation( [ i1, i2 ], L, [ p1, p2 ] ) );

    iso1 := Inverse( ApplyFunctor( Sh, mono1 ) );
    iso2 := SerreQuotientCategoryMorphism( coh, ApplyFunctor( span_to_three_arrows, mono2 ) );

    return PreCompose( iso1, iso2 );

end );

return Nat;
end;

Nat := NaturalTransformation( "Name", Sh, Beilinson );
AddNaturalTransformationFunction( Nat,
    function( source, M, range )
    local r, M_geq_r, trunc_leq_m1, T, trunc_leq_rm1,ch_trunc_leq_m1, complexes_sym,
    bicomplxes_sym, complexes_to_bicomplex, L, chL, trunc_leq_rm1_TM_geq_r, phi,
    bicomplexes_morphism, tau, LP, tM, colift, P, Pr, emb, emb_of_Pr, t, mat, i1, i2, i, p1, p2, p, l,
    Hmr, iso1, iso2, cospan_to_span, mor, g_emb, a, CV, CH, indices, iso, Trunc_leq_rm1;

    r := Maximum( 2, CastelnuovoMumfordRegularity( M ) );;
    M_geq_r := GradedLeftPresentationGeneratedByHomogeneousPart( M, r );;
    trunc_leq_rm1 := BrutalTruncationAboveFunctor( cochains_graded_lp_cat_ext, r-1 );;
    T := TateFunctor(S);;
    trunc_leq_m1 := BrutalTruncationAboveFunctor( cochains_graded_lp_cat_sym, -1 );;
    ch_trunc_leq_m1 := ExtendFunctorToCochainComplexCategoryFunctor(trunc_leq_m1 );;
    complexes_sym := CochainComplexCategory( cochains_graded_lp_cat_sym );;
    bicomplxes_sym := AsCategoryOfBicomplexes(complexes_sym);;
    complexes_to_bicomplex := ComplexOfComplexesToBicomplexFunctor(complexes_sym, bicomplxes_sym );;
    L := LFunctor(S);;
    chL := ExtendFunctorToCochainComplexCategoryFunctor(L);;
    trunc_leq_rm1_TM_geq_r := ApplyFunctor( PreCompose(T,trunc_leq_rm1), M_geq_r );;
    phi := CochainMorphism(
    trunc_leq_rm1_TM_geq_r,
    StalkCochainComplex( CokernelObject( trunc_leq_rm1_TM_geq_r^(r-2) ), r-1 ),
    [ CokernelProjection( trunc_leq_rm1_TM_geq_r^(r-2) ) ],
    r-1 );
    bicomplexes_morphism := ApplyFunctor( PreCompose( [ chL, ch_trunc_leq_m1, complexes_to_bicomplex ] ), phi );;
    tau := ComplexMorphismOfHorizontalCohomologiesAt(bicomplexes_morphism, r-1 );;
    LP := Range( tau );
###
    tM := ApplyFunctor(T,M);;
    colift := CokernelColift( tM^(r-2), tM^(r-1) );;
    P := Source(colift);;
    Pr := GradedLeftPresentationGeneratedByHomogeneousPart(P,r);;
    emb_of_Pr := EmbeddingInSuperObject(Pr);;
    emb := PreCompose( emb_of_Pr, colift );;
    mat := UnderlyingMatrix(emb);;
    mat := DecompositionOfHomalgMat(mat)[2^(n+1)][2]*S;;
    ##
    t := GradedPresentationMorphism( LP[ -r ], mat, M_geq_r );;
    emb := EmbeddingInSuperObject( M_geq_r );;
    phi := CochainMorphism( Range(tau), StalkCochainComplex( M, -r ), [ PreCompose( t, emb ) ], -r );;
    Hmr := CohomologyFunctorAt( cochains_graded_lp_cat_sym, graded_lp_cat_sym, -r );;;;
    mor := ApplyFunctor( Hmr, PreCompose( tau, phi ) );;
    g_emb := GeneralizedEmbeddingOfCohomologyAt(Range(phi),-r);;
    iso1 := PreCompose( mor, HonestRepresentative( g_emb ) );;

    #####
    a := ApplyFunctor( PreCompose( [ T, trunc_leq_rm1, chL, ch_trunc_leq_m1, complexes_to_bicomplex ] ), M );;
    #a := Source( bicomplexes_morphism );;
    CV := ComplexOfVerticalCohomologiesAt( a, -1 );;
    CH := ComplexOfHorizontalCohomologiesAt( a, r - 1 );;
    i1 := GeneralizedEmbeddingOfCohomologyAt(CH, -r );;
    i2 := GeneralizedEmbeddingOfHorizontalCohomologyAt(a, r-1, -r );;
    p1 := GeneralizedProjectionOntoVerticalCohomologyAt(a, 0, -1 );;
    p2 := GeneralizedProjectionOntoCohomologyAt(CV, 0);
    i := PreCompose(i1,i2);;
    p := PreCompose(p1,p2);;
    indices := Reversed( List( [ 1 .. r-1 ], i -> [ i, -i ] ) );;
    L := List( indices,i -> GeneralizedMorphismByCospan(
            VerticalDifferentialAt(a, i[1], i[2]-1 ),
            HorizontalDifferentialAt(a, i[1]-1, i[2] ) ) );;
    cospan_to_span := FunctorFromCospansToSpans( graded_lp_cat_sym );;
    L := List( L, l -> ApplyFunctor( cospan_to_span, l ) );;
    iso2  := HonestRepresentative( PreCompose( Concatenation( [ [ i ], L, [ p ] ] ) ) );
    return PreCompose( Inverse( ApplyFunctor( Sh, iso1 ) ), ApplyFunctor( Sh, iso2 ) );
end );
