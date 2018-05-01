#
# BBGG: BBG correspondence and Beilinson monad
#
# Implementations
#
InstallMethod( AsPresentationInCAP,
                [ IsHomalgGradedModule ],
    function( M )
    local N, s;
    s := PositionOfTheDefaultPresentation( M );
    SetPositionOfTheDefaultPresentation( M, 1 );
    if IsHomalgRightObjectOrMorphismOfRightObjects( M ) then
        N := AsGradedRightPresentation( MatrixOfRelations( M ), DegreesOfGenerators( M ) );
        SetPositionOfTheDefaultPresentation( M, s );
        SetAsPresentationInHomalg( N, M );
        return N;
    else
        N := AsGradedLeftPresentation( MatrixOfRelations( M ), DegreesOfGenerators( M ) );
        SetPositionOfTheDefaultPresentation( M, s );
        SetAsPresentationInHomalg( N, M );
        return N;
    fi;
end );

InstallMethod( AsPresentationInHomalg,
                [ IsGradedLeftOrRightPresentation ],
    function( M )
    local N;
    if IsGradedRightPresentation( M ) then
        N := RightPresentationWithDegrees( UnderlyingMatrix( M ), GeneratorDegrees( M ) );
        SetAsPresentationInCAP( N, M );
        return N;
    else
        N := LeftPresentationWithDegrees( UnderlyingMatrix( M ), GeneratorDegrees( M ) );
        SetAsPresentationInCAP( N, M );
        return N;
    fi;
end );

InstallMethod( AsPresentationMorphismInCAP,
                [ IsHomalgGradedMap ],
    function( f )
    local g, M, N, s, t;
    s := PositionOfTheDefaultPresentation( Source( f ) );
    t := PositionOfTheDefaultPresentation( Range( f ) );
    
    SetPositionOfTheDefaultPresentation( Source( f ), 1 );
    SetPositionOfTheDefaultPresentation( Range( f ), 1 );
    
    M := AsPresentationInCAP( Source( f ) );
    N := AsPresentationInCAP( Range( f ) );
    
    g := GradedPresentationMorphism( M, MatrixOfMap( f ), N );

    SetPositionOfTheDefaultPresentation( Source( f ), s );
    SetPositionOfTheDefaultPresentation( Range( f ), t );
    SetAsPresentationInHomalg( g, f );
    
    return g;

end );

InstallMethod( AsPresentationMorphismInHomalg,
                [ IsGradedLeftOrRightPresentationMorphism ],
    function( f )
    local M, N, g;
    M := AsPresentationInHomalg( Source( f ) );
    N := AsPresentationInHomalg( Range( f ) );
    g :=  GradedMap( UnderlyingMatrix( f ), M, N );
    SetAsPresentationMorphismInCAP( g, f );
    return g;
end );

InstallMethod( RFunctor,
                [ IsHomalgGradedRing ],
    function( S )
    local cat_lp_ext, cat_lp_sym, cochains, R; 

    cat_lp_sym := GradedLeftPresentations( S );
    cat_lp_ext := GradedLeftPresentations( KoszulDualRing( S ) );
    cochains := CochainComplexCategory( GradedLeftPresentations( KoszulDualRing( S ) ) );

    R := CapFunctor( "R resolution ", cat_lp_sym, cochains );
    
    AddObjectFunction( R, 
        function( M )
        local hM, diff, d, C;
        hM := AsPresentationInHomalg( M );
        diff := MapLazy( IntegersList, i -> AsPresentationMorphismInCAP( RepresentationMapOfKoszulId( i, hM ) ), 1 );
        C := CochainComplex( cat_lp_ext , diff );
        d := ShallowCopy( GeneratorDegrees( M ) );

        # the output of GeneratorDegrees is in general not integer.
        Apply( d, String );
        Apply( d, Int );
        SetLowerBound( C, Minimum( d ) - 1 );
        return C;
        end );

        AddMorphismFunction( R, 
        function( new_source, f, new_range )
        local M, N, G1, G2, hM, hN, mors;
        M := Source( f );
        N := Range( f );
        hM := AsPresentationInHomalg( M );
        hN := AsPresentationInHomalg( N );
        mors := MapLazy( IntegersList, 
                function( n )
                local hMn, hNn, hMn_, hNn_, iMn, iNn, l;
                hMn := HomogeneousPartOverCoefficientsRing( n, hM );
                hNn := HomogeneousPartOverCoefficientsRing( n, hN );
                G1 := GetGenerators( hMn );
                G2 := GetGenerators( hNn );
                if Length( G1 ) = 0 or Length( G2 ) = 0 then 
                    return ZeroMorphism( new_source[ n ], new_range[ n ] );
                fi;
                hMn_ := UnionOfRows( G1 )*S;
                hNn_ := UnionOfRows( G2 )*S;
                iMn := GradedPresentationMorphism( GradedFreeLeftPresentation( NrRows( hMn_ ), S, List( [1..NrRows( hMn_ ) ], i -> n ) ), hMn_, M );
                iNn := GradedPresentationMorphism( GradedFreeLeftPresentation( NrRows( hNn_ ), S, List( [1..NrRows( hNn_ ) ], i -> n ) ), hNn_, N );
                l := Lift( PreCompose( iMn, f ), iNn );
                return GradedPresentationMorphism( new_source[ n ], UnderlyingMatrix( l )*KoszulDualRing( S ), new_range[ n ] );
                end, 1 );
        return CochainMorphism( new_source, new_range, mors );
        end );

    return R;
end );

InstallMethod( CastelnuovoMumfordRegularity,
                [ IsGradedLeftOrRightPresentation ],
    function( M )
    return CastelnuovoMumfordRegularity( AsPresentationInHomalg( M ) );
end );

InstallMethod( TateResolution, 
                [ IsGradedLeftOrRightPresentation ],
    function( M )
    local cat, hM, diff, C;
    cat := GradedLeftPresentations( KoszulDualRing( UnderlyingHomalgRing( M ) ) );
    hM := AsPresentationInHomalg( M );
    diff := MapLazy( IntegersList, i -> 
        AsPresentationMorphismInCAP( CertainMorphism( TateResolution( hM, i, i + 1 ), i ) ), 1 );
    return CochainComplex( cat , diff );
end );