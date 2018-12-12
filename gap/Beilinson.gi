
##
InstallMethod( TwistedOmegaModuleOp,
    [ IsExteriorRing, IsInt ],
    function( A, i )
      return GradedFreeLeftPresentation( 1, A, [ Length( IndeterminatesOfExteriorRing( A ) ) - i ] );
 end );

##
InstallMethod( BasisBetweenTwistedOmegaModules,
    [ IsExteriorRing, IsInt, IsInt ],
    function( A, i, j )
      local n, omega_i, omega_j, G, indeterminates, combinations, index, L;

      omega_i :=TwistedOmegaModule( A, i );
      omega_j :=TwistedOmegaModule( A, j );

      indeterminates := IndeterminatesOfExteriorRing( A );
      
      n := Length( indeterminates );

      if i < j then
          return [  ];
      fi;

      if i = j then
          return [ IdentityMorphism( TwistedOmegaModule( A, i ) ) ];
      fi;

      if i = j + 1 then
          G := List( indeterminates, ind -> HomalgMatrix( [ [ ind ] ], 1, 1, A ) );
          return List( G, g -> GradedPresentationMorphism( omega_i, g, omega_j ) );
      elif i = j + n then
          G := HomalgMatrix( [ [ Product( indeterminates ) ] ], 1, 1, A );
          return [ GradedPresentationMorphism( omega_i, G, omega_j ) ];
      elif i > j + n then
          return [  ];
      else
          G := Reversed( List( [ 1 .. n-1 ], k -> BasisBetweenTwistedOmegaModules( A, k, k - 1 ) ) );
          index := n - i;
          combinations := Combinations( [ 1 .. n ], i - j );
          L := List( combinations, comb -> List( [ 1 .. i - j ], k-> G[index+k-1][comb[k]] ) );
          return List( L, l -> PreCompose(l) );
      fi;

end );

##
BindGlobal( "IS_ZERO_SHEAF",
    function( N )
      return IsZero( HilbertPolynomial( AsPresentationInHomalg( N ) ) );
end );

##
InstallMethod( CoherentSheavesOverProjectiveSpace, 
    [ IsHomalgGradedRing ],
    function( S )
      local graded_lp_cat_sym, sub_cat;
      graded_lp_cat_sym := GradedLeftPresentations( S );
      sub_cat := FullSubcategoryByMembershipFunction( graded_lp_cat_sym, IS_ZERO_SHEAF );
      return graded_lp_cat_sym / sub_cat;
end );

##
InstallMethod( TwistedStructureSheafOp,
    [ IsHomalgGradedRing, IsInt ],
    function( S, i )
      return GradedFreeLeftPresentation( 1, S, [ -i ] );
end );


##
InstallMethod( TwistedCotangentSheafAsCochainOp,
    [ IsHomalgGradedRing, IsInt ],
    function( S, i )
      local L, graded_lp_cat, cochains, Tr;
      L := LCochainFunctor( S );
      graded_lp_cat := GradedLeftPresentations( S );
      cochains := CochainComplexCategory( graded_lp_cat );
      Tr := BrutalTruncationAboveFunctor( cochains, -1 );
      return ShiftUnsignedLazy( ApplyFunctor( PreCompose( [ L, Tr ] ), TwistedOmegaModule( KoszulDualRing( S ), i ) ), -1 );
end );

##
InstallMethod( TwistedCotangentSheafAsChainOp,
    [ IsHomalgGradedRing, IsInt ],
    function( S, i )
      return AsChainComplex( TwistedCotangentSheafAsCochain( S, i ) );
end );

InstallMethod( TwistedCotangentSheafOp,
    [ IsHomalgGradedRing, IsInt ],
    function( S, i )
      local n, cotangent_sheaf_as_chain;
      n := Length( IndeterminatesOfPolynomialRing( S ) );
      if i < 0 or i > n - 1 then
          Error( Concatenation( "Twisted cotangent sheaves Ω^i(i) are defined only for i = 0,...,", String( n - 1 ) ) );
      fi;
      # NOTICE THIS
      if i = -1 then
          return GradedFreeLeftPresentation( 1, S, [ 0 ] );
      else
          cotangent_sheaf_as_chain := TwistedCotangentSheafAsChain( S, i );
          return CokernelObject( cotangent_sheaf_as_chain^1 );
      fi;
end );

##
InstallMethodWithCache( BasisBetweenTwistedStructureSheaves,
    [ IsHomalgGradedRing, IsInt, IsInt ],
    function( S, u, v )
      local n, L, l, o_u, o_v, indeterminates;

      n := Length( IndeterminatesOfPolynomialRing( S ) );
      if u > v then
          return [ ];
      elif u = v then
          return [ IdentityMorphism( TwistedStructureSheaf( S, u ) ) ];
      else
          o_u := GradedFreeLeftPresentation( 1, S, [ -u ] );
          o_v := GradedFreeLeftPresentation( 1, S, [ -v ] );

          L := Combinations( [ 1 .. n+v-u-1 ], v-u );
          L := List( L, l -> l - [ 0 .. v-u - 1 ] );
          indeterminates := IndeterminatesOfPolynomialRing( S );
          L := List( L, indices -> Product( List( indices, index -> indeterminates[index] ) ) );
          L := List( L, l -> HomalgMatrix( [[l]], 1, 1, S ) );
          return List( L, mat -> GradedPresentationMorphism( o_u, mat, o_v ) );
      fi;
end );

##
InstallMethodWithCache( BasisBetweenTwistedCotangentSheaves, 
    "this should return the basis of Hom( omega^i(i),omega^j(j) )",
    [ IsHomalgGradedRing, IsInt, IsInt ],
    function( S, i, j )
      local L, graded_lp_cat, cochains, Tr, Cok, F, B;
      L := LCochainFunctor( S );
      graded_lp_cat := GradedLeftPresentations( S );
      cochains := CochainComplexCategory( graded_lp_cat );
      Tr := BrutalTruncationAboveFunctor( cochains, -1 );
      Cok := CokernelObjectFunctor( cochains, graded_lp_cat, -2 );
      F := PreCompose( [ L, Tr, Cok ] );
      B := BasisBetweenTwistedOmegaModules( KoszulDualRing( S ), i, j );
      return List( B, b -> ApplyFunctor( F, b ) );
end );

InstallMethod( BeilinsonReplacement, 
    [ IsCapCategoryObject and IsBoundedChainComplex ],
    function( C )
    local TC, S, chains, cat, n, diff, diffs, rep, reg;
    TC := TateResolution( C );
    reg := CastelnuovoMumfordRegularity( C );
    chains := CapCategory( C );
    cat := UnderlyingCategory( chains );
    S := cat!.ring_for_representation_category; 
    n := Length( IndeterminatesOfPolynomialRing( S ) );
    diff := function(i)
            local B, b, d, u, L;
            B := BeilinsonReplacement( C );
            
            # very nice trick to improve speed and reduce computations
            if i < reg then
                b := B^( i + 1 );
            elif i> reg then
                b := B^( i - 1 );
            fi;

            if i> ActiveUpperBound( B ) + 1 or i<= ActiveLowerBound( B ) then
                return ZeroObjectFunctorial( cat );
            else
                if i-1 in ComputedDifferentialAts( TC ) then
                    d := GeneratorDegrees( TC[ i-1 ] );
                    # It would be more secure to write j<1, but since the Tate res is minimal,
                    # there is no units in differentials matrices. Hence it is ok to write i<=1
                    # Tate is minimal because I am using homalg to compute the projective cover.
                    if ForAll( d, j -> j <= 1 ) then
                        u := UniversalMorphismFromZeroObject( TC[ i - 1 ] );
                        L := MORPHISM_OF_TWISTED_OMEGA_MODULES_AS_LIST_OF_RECORDS( u );
                        SetUpperBound( B, i );
                    else
                        L := MORPHISM_OF_TWISTED_OMEGA_MODULES_AS_LIST_OF_RECORDS( TC^i );
                    fi;
                
                elif i+1 in ComputedDifferentialAts( TC ) then
                    d := GeneratorDegrees( TC[ i ] );
                    # Same as above
                    if ForAll( d, j -> j >= n ) then
                        u := UniversalMorphismIntoZeroObject( TC[ i ] );
                        L := MORPHISM_OF_TWISTED_OMEGA_MODULES_AS_LIST_OF_RECORDS( u );
                        SetLowerBound( B, i - 1 );
                    else
                        L := MORPHISM_OF_TWISTED_OMEGA_MODULES_AS_LIST_OF_RECORDS( TC^i );
                    fi;
                else    
                    L := MORPHISM_OF_TWISTED_OMEGA_MODULES_AS_LIST_OF_RECORDS( TC^i );
                fi;

                return LIST_OF_RECORDS_TO_MORPHISM_OF_TWISTED_COTANGENT_SHEAVES( S, L );
            fi;
            end;
    diffs := MapLazy( IntegersList, diff, 1 );
    rep := ChainComplex( cat, diffs );
    SetUpperBound( rep, ActiveUpperBound(C)+n-1 );
    SetLowerBound( rep, ActiveLowerBound(C)-n+1 );
    return rep;
end );

InstallMethod( BeilinsonReplacement, 
    [ IsCapCategoryMorphism and IsBoundedChainMorphism ],
    function( phi )
    local Tphi, S, chains, cat, n, mor, mors, rep, source, range;
    Tphi := TateResolution( phi );
    chains := CapCategory( phi );
    cat := UnderlyingCategory( chains );
    S := cat!.ring_for_representation_category;
    n := Length( IndeterminatesOfPolynomialRing( S ) );
    source := BeilinsonReplacement( Source( phi ) );
    range := BeilinsonReplacement( Range( phi ) );
    mor :=  function( i )
            local a, b, l, u, L;
            a := source[ i ];
            b := range[ i ];

            l := Maximum( ActiveLowerBound( source ), ActiveLowerBound( range ) );
            u := Minimum( ActiveUpperBound( source ), ActiveUpperBound( range ) );

            if i >= u or i <= l then
                return ZeroMorphism( a, b );
            else
                L := MORPHISM_OF_TWISTED_OMEGA_MODULES_AS_LIST_OF_RECORDS( Tphi[i] );
                return LIST_OF_RECORDS_TO_MORPHISM_OF_TWISTED_COTANGENT_SHEAVES( S, L );
            fi;
            end;
    mors := MapLazy( IntegersList, mor, 1 );
    rep := ChainMorphism( source, range, mors );
    return rep;
end );

InstallMethod( BeilinsonReplacement,
    [ IsCapCategoryObject and IsGradedLeftPresentation ],
    function( M )
    local R;
    R := UnderlyingHomalgRing( M );
    if HasIsExteriorRing( R ) and IsExteriorRing( R ) then
        TryNextMethod(  );
    else
        return BeilinsonReplacement( StalkChainComplex( M, 0 ) );
    fi;
end );

InstallMethod( BeilinsonReplacement,
    [ IsCapCategoryMorphism and IsGradedLeftPresentationMorphism ],
    function( phi )
    local R;
    R := UnderlyingHomalgRing( phi );
    if HasIsExteriorRing( R ) and IsExteriorRing( R ) then
        TryNextMethod(  );
    else
        return BeilinsonReplacement( StalkChainMorphism( phi, 0 ) );
    fi;
end );

InstallMethod( BeilinsonReplacement, 
    [ IsCapCategoryObject and IsGradedLeftPresentation ],
    function( P )
    local TP, R, S, chains, cat, n, diff, diffs, rep, reg;

    R := UnderlyingHomalgRing( P );
    if HasIsExteriorRing( R ) and IsExteriorRing( R ) then

    TP := TateResolution( P );
    reg := 0;
    S := KoszulDualRing( R );

    cat := GradedLeftPresentations( S );
    chains := ChainComplexCategory( cat );
    n := Length( IndeterminatesOfExteriorRing( R ) );
    diff := function(i)
            local B, b, d, u, L;
            B := BeilinsonReplacement( P );
            
            # very nice trick to improve speed and reduce computations
            if i < reg then
                b := B^( i + 1 );
            elif i> reg then
                b := B^( i - 1 );
            fi;

            if ( HasActiveUpperBound( B ) and i> ActiveUpperBound( B ) + 1 ) or 
                ( HasActiveLowerBound( B ) and i<= ActiveLowerBound( B ) ) then
                return ZeroObjectFunctorial( cat );
            else
                if i-1 in ComputedDifferentialAts( TP ) then
                    d := GeneratorDegrees( TP[ i-1 ] );
                    # It would be more secure to write j<1, but since the Tate res is minimal,
                    # there is no units in differentials matrices. Hence it is ok to write i<=1
                    # Tate is minimal because I am using homalg to compute the projective cover.
                    if ForAll( d, j -> j <= 1 ) then
                        u := UniversalMorphismFromZeroObject( TP[ i - 1 ] );
                        L := MORPHISM_OF_TWISTED_OMEGA_MODULES_AS_LIST_OF_RECORDS( u );
                        SetUpperBound( B, i );
                    else
                        L := MORPHISM_OF_TWISTED_OMEGA_MODULES_AS_LIST_OF_RECORDS( TP^i );
                    fi;
                
                elif i+1 in ComputedDifferentialAts( TP ) then
                    d := GeneratorDegrees( TP[ i ] );
                    # Same as above
                    if ForAll( d, j -> j >= n ) then
                        u := UniversalMorphismIntoZeroObject( TP[ i ] );
                        L := MORPHISM_OF_TWISTED_OMEGA_MODULES_AS_LIST_OF_RECORDS( u );
                        SetLowerBound( B, i - 1 );
                    else
                        L := MORPHISM_OF_TWISTED_OMEGA_MODULES_AS_LIST_OF_RECORDS( TP^i );
                    fi;
                else
                    L := MORPHISM_OF_TWISTED_OMEGA_MODULES_AS_LIST_OF_RECORDS( TP^i );
                fi;

                return LIST_OF_RECORDS_TO_MORPHISM_OF_TWISTED_COTANGENT_SHEAVES( S, L );
            fi;
            end;
    diffs := MapLazy( IntegersList, diff, 1 );
    rep := ChainComplex( cat, diffs );
    return rep;
    else
        TryNextMethod();
    fi;

end );

InstallMethod( BeilinsonReplacement,
    [ IsCapCategoryMorphism and IsGradedLeftPresentationMorphism ],
    function( phi )
    local Tphi, R, S, chains, cat, n, mor, mors, rep, source, range;
    
    R := UnderlyingHomalgRing( phi );
    if HasIsExteriorRing( R ) and IsExteriorRing( R ) then

        Tphi := TateResolution( phi );
        S := KoszulDualRing( R );
        n := Length( IndeterminatesOfPolynomialRing( S ) );
        source := BeilinsonReplacement( Source( phi ) );
        range := BeilinsonReplacement( Range( phi ) );
        mor :=  function( i )
                local a, b, l, u, L;
                a := source[ i ];
                b := range[ i ];
            
                l := -infinity;
                u := infinity;

                if HasActiveLowerBound( source ) and HasActiveLowerBound( range ) then
                    l := Maximum( ActiveLowerBound( source ), ActiveLowerBound( range ) );
                fi;
            
                if HasActiveUpperBound( source ) and HasActiveUpperBound( range ) then
                    u := Minimum( ActiveUpperBound( source ), ActiveUpperBound( range ) );
                fi;

                if i >= u or i <= l then
                    return ZeroMorphism( a, b );
                else
                   L := MORPHISM_OF_TWISTED_OMEGA_MODULES_AS_LIST_OF_RECORDS( Tphi[i] );
                    return LIST_OF_RECORDS_TO_MORPHISM_OF_TWISTED_COTANGENT_SHEAVES( S, L );
                fi;
                end;
        mors := MapLazy( IntegersList, mor, 1 );
        rep := ChainMorphism( source, range, mors );
        return rep;
    else
       TryNextMethod(  ); 
    fi;
end );

##
InstallMethodWithCache( RECORD_TO_MORPHISM_OF_TWISTED_COTANGENT_SHEAVES,
        [ IsHomalgGradedRing, IsRecord ],
    function( S, record )
    local cat, projectives, coefficients, u, v, source, range;

    cat := GradedLeftPresentations( S );
    
    u := record!.indices[ 1 ];
    v := record!.indices[ 2 ];

    if u = -1 and v = -1 then
        return ZeroMorphism( ZeroObject( cat ), ZeroObject( cat ) );
    elif v = -1 then
        return UniversalMorphismIntoZeroObject( TwistedCotangentSheaf( S, u ) );
    elif  u = -1 then
        return UniversalMorphismFromZeroObject( TwistedCotangentSheaf( S, v ) );
    fi;

    if record!.coefficients = [] then
        source := TwistedCotangentSheaf( S, u );
        range :=  TwistedCotangentSheaf( S, v );
        return ZeroMorphism( source, range );
    else
        coefficients := List( record!.coefficients, c -> String( c )/S );
        return coefficients*BasisBetweenTwistedCotangentSheaves( S, u, v );
    fi;                     

end );


##
InstallMethodWithCache( LIST_OF_RECORDS_TO_MORPHISM_OF_TWISTED_COTANGENT_SHEAVES,
        [ IsHomalgGradedRing, IsList ],
    function( S, L )
    local mor;
    mor :=  MorphismBetweenDirectSums(
        List( L, l -> List( l, m -> RECORD_TO_MORPHISM_OF_TWISTED_COTANGENT_SHEAVES( S, m ) ) ) );
    mor!.UNDERLYING_LIST_OF_RECORDS := L;
    return mor;
end );

##
InstallMethod( MORPHISM_OF_TWISTED_OMEGA_MODULES_AS_LIST_OF_RECORDS,
    [ IsGradedLeftPresentationMorphism ],
    function( phi )
    local K, degrees_range, degrees_source, index_1, index_2, A, B, sol, n, sources, ranges, s, r, L;
    
    K := UnderlyingHomalgRing( phi );
    n := Length( IndeterminatesOfExteriorRing( K ) );
    degrees_source := GeneratorDegrees( Source( phi ) );
    degrees_range  := GeneratorDegrees( Range( phi ) );

    if NrRows( UnderlyingMatrix( Source( phi ) ) ) <> 0 or 
        NrRows( UnderlyingMatrix( Range( phi ) ) ) <> 0 then
            Error( "The source and range should be free modules" );
    fi;

    if Length( degrees_source ) <= 1 and Length( degrees_range ) <= 1 then

        if degrees_source = [  ] and degrees_range = [  ] then
            return [ [ rec( indices := [ -1, -1 ], coefficients := [] ) ] ];
        elif degrees_source = [  ] and not Int( String( degrees_range[ 1 ] ) ) in [ 1 .. n ] then
            return [ [ rec( indices := [ -1, -1  ], coefficients := [  ] ) ] ];
        elif degrees_source = [  ] and Int( String( degrees_range[ 1 ] ) ) in [ 1 .. n ] then
            return [ [ rec( indices := [ -1, Int( String( n - degrees_range[ 1 ]  ) ) ], coefficients := [] ) ] ];
        elif degrees_range = [ ] and not Int( String( degrees_source[ 1 ] ) ) in [ 1 .. n ] then
            return [ [ rec( indices := [ -1, -1 ], coefficients := [] ) ] ];
        elif degrees_range = [ ] and Int( String( degrees_source[ 1 ] ) ) in [ 1 .. n ] then
            return [ [ rec( indices := [ Int( String( n - degrees_source[ 1 ] ) ), -1 ], coefficients := [  ] ) ] ];
        elif not Int( String( degrees_source[ 1 ] ) ) in [ 1 .. n ] and not Int( String( degrees_range[ 1 ] ) ) in [ 1 .. n ] then 
            return [ [ rec( indices := [ -1, -1  ], coefficients := [  ] ) ] ];
        elif not Int( String( degrees_source[ 1 ] ) ) in [ 1 .. n ] then
            return [ [ rec( indices := [ -1, Int( String( n - degrees_range[ 1 ]  ) ) ], coefficients := [  ] ) ] ];
        elif not Int( String( degrees_range[ 1 ] ) ) in [ 1 .. n ] then
            return [ [ rec( indices := [ Int( String( n - degrees_source[ 1 ] ) ), -1 ], coefficients := [  ] ) ] ];
        elif IsZeroForMorphisms( phi ) then
            return [ [ rec(  indices := [ Int( String( n-degrees_source[1] ) ),
                                        Int( String( n-degrees_range[1] ) ) ], coefficients := [  ] ) ] ];
        else
            index_1 := Int( String( n - degrees_source[ 1 ] ) );
            index_2 := Int( String( n - degrees_range[ 1 ] ) );
            B := BasisBetweenTwistedOmegaModules( K, index_1, index_2 );
            B := List( B, UnderlyingMatrix );
            B := UnionOfRows( B );
            A := UnderlyingMatrix( phi );
            sol := EntriesOfHomalgMatrix( RightDivide( A, B ) );
            return [ [ rec( indices := [ index_1, index_2 ], coefficients := sol ) ] ];
        fi;
    else
        sources := List( degrees_source, d -> GradedFreeLeftPresentation( 1, K, [ d ] ) );
        if sources = [ ] then
            sources := [ ZeroObject( phi ) ];
        fi;
        s := Length( sources );
        
        ranges  := List( degrees_range, d -> GradedFreeLeftPresentation( 1, K, [ d ] ) );
        if ranges = [ ] then
            ranges := [ ZeroObject( phi ) ];
        fi;
        r := Length( ranges );
        L := List( [ 1 .. s ], u -> 
            List( [ 1 .. r ], v -> PreCompose(
                [
                    InjectionOfCofactorOfDirectSum( sources, u ),
                    phi,
                    ProjectionInFactorOfDirectSum( ranges, v )
                ]
            )));
        L := List( L, l -> List( l, m -> MORPHISM_OF_TWISTED_OMEGA_MODULES_AS_LIST_OF_RECORDS(m)[1][1] ) );
        L := Filtered( L, l -> not ForAll( l, r -> r.indices = [ -1, -1 ] ) );
        if L = [  ] then
            return [[ rec( indices := [ -1, -1  ], coefficients := [  ] ) ]];
        else
            return L;
        fi;
    fi;
end );
 
##
InstallMethod( ViewObj, 
    [ IsGradedLeftPresentation ],
    function( M )
      local mat, s, i, degrees, n, R;
      mat := UnderlyingMatrix( M );
      R := UnderlyingHomalgRing( M );
      n := Length( Indeterminates( R ) );
      s := "";
      if NrRows( mat ) = 0 then
          degrees := GeneratorDegrees( M );
          degrees := Collected( degrees );
          if degrees = [ ] then
              Print( "0" );
          fi;
              
          if not HasIsExteriorRing( R ) then
              for i in degrees do
                  s := Concatenation( s, "S(",String( -i[ 1 ] ),")^", String( i[ 2 ] ), " ⊕ " );
              od;
          else
              for i in degrees do
                  s := Concatenation( s, "ω(", String( n - i[ 1 ] ), ")^", String( i[ 2 ] ), " ⊕ " );
              od;
          fi;
          
          s := s{ [ 1 .. Length( s ) - 5 ] };
          Print( s );
      
      else
          TryNextMethod(  );
      fi;
end );

##
InstallMethod( ViewObj, 
    [ IsGradedLeftPresentation ],
    function( M )
      local mat, s, i, degrees, n, R;
      mat := UnderlyingMatrix( M );
      R := UnderlyingHomalgRing( M );
      n := Length( Indeterminates( R ) );
      s := "";
      if NrRows( mat ) = 0 then
          degrees := GeneratorDegrees( M );
          degrees := Collected( degrees );
          if degrees = [ ] then
              Print( "0" );
          fi;
              
          if not HasIsExteriorRing( R ) then
              for i in degrees do
                  s := Concatenation( s, "S(",String( -i[ 1 ] ),")^", String( i[ 2 ] ), " ⊕ " );
              od;
          else
              for i in degrees do
                  s := Concatenation( s, "ω(", String( n - i[ 1 ] ), ")^", String( i[ 2 ] ), " ⊕ " );
              od;
          fi;
          
          s := s{ [ 1 .. Length( s ) - 5 ] };
          Print( s );
      
      else
          TryNextMethod(  );
      fi;
end );
