#
# BBGG: BBG correspondence and Beilinson monad
#
# Implementations
#

InstallMethod( RCochainFunctor,
    [ IsHomalgGradedRing ],
  function( S )
    local cat_lp_ext, cat_lp_sym, cochains, R, A, n, name, ind_S, ind_A;
    
    ind_S := Indeterminates( S );
    
    n := Length( ind_S );
    
    A := KoszulDualRing( S );
    
    ind_A := Indeterminates( A );
    
    cat_lp_sym := GradedLeftPresentations( S );
    
    cat_lp_ext := GradedLeftPresentations( A );
    
    cochains := CochainComplexCategory( cat_lp_ext );
    
    name := Concatenation(
      "R functor from ",
      Name( cat_lp_sym ),
      " to ",
      Name( cochains )
    );
    
    R := CapFunctor( name, cat_lp_sym, cochains );
    
    AddObjectFunction( R,
      function( M )
        local hM, diff, d, C;
        
        hM := AsPresentationInHomalg( M );
        
        SetPositionOfTheDefaultPresentation( hM, 1 );
        
        diff := AsZFunction( 
                  function( i )
                    local maps, mats, mat, source, range;
                    
                    maps := List( ind_S, x -> RepresentationMapOfRingElement( x, hM, i ) );
                    
                    mats := List( maps, map -> MatrixOfMap( map ) * A );
                    
                    mat :=  MinusOne( A )^(n+1) * Sum( ListN( mats, ind_A, \* ) );
                    
                    source := GradedFreeLeftPresentation( NrRows( mat ), A, ListWithIdenticalEntries( NrRows( mat ), n + i ) );
                    
                    range := GradedFreeLeftPresentation( NrCols( mat ), A, ListWithIdenticalEntries( NrCols( mat ), n + i + 1 ) );

                    return GradedPresentationMorphism( source, mat, range );
                    
                  end );
                
        C := CochainComplex( cat_lp_ext , diff );
        
        d := ShallowCopy( GeneratorDegrees( M ) );
        
        Apply( d, HomalgElementToInteger );
        
        if Length( d ) = 0 then
          
          SetLowerBound( C, 1 );
        
        else
          
          SetLowerBound( C, Minimum( d ) );
        
        fi;
        
        return C;
        
      end );
    
    AddMorphismFunction( R, 
      function( new_source, f, new_range )
        local mors;
        
        mors := AsZFunction(  
                  function( k )
                    local H, map;
                    H := HomogeneousPartOverCoefficientsRingFunctor( S, k );
                    
                    map := ApplyFunctor( H, f );
                    
                    return
                      GradedPresentationMorphism(
                        new_source[ k ],
                        UnderlyingMatrix( map ) * KoszulDualRing( S ),
                        new_range[ k ] );
                    
                    end );
        
        return CochainMorphism( new_source, new_range, mors );
        
      end );
       
    return R;
    
end );

# This is old alternative implementation of the functor R
# Can be very slow comparing to the new one
BindGlobal( "R_COCHAIN_FUNCTOR_OLD",
    function( S )
    local cat_lp_ext, cat_lp_sym, cochains, R, KS, n, name; 

    n := Length( IndeterminatesOfPolynomialRing( S ) );
    KS := KoszulDualRing( S );
    cat_lp_sym := GradedLeftPresentations( S );
    cat_lp_ext := GradedLeftPresentations( KS );
    cochains := CochainComplexCategory( cat_lp_ext );
    name := Concatenation( "R functor from ", Name( cat_lp_sym ), " to ", Name( cochains ) );

    R := CapFunctor( name, cat_lp_sym, cochains );
    
    AddObjectFunction( R,
        function( M )
        local hM, diff, d, C;
        hM := AsPresentationInHomalg( M );
        SetPositionOfTheDefaultPresentation( hM, 1 );
        diff := AsZFunction(  i -> AsPresentationMorphismInCAP( RepresentationMapOfKoszulId( i, hM ) ) );
        C := CochainComplex( cat_lp_ext , diff );
        d := ShallowCopy( GeneratorDegrees( M ) );

        # the output of GeneratorDegrees is in general not integer.
        Apply( d, HomalgElementToInteger );

        if Length( d ) = 0 then
          
            SetLowerBound( C, 1 );
            
        else
            SetLowerBound( C, Minimum( d ) );
        fi;
        
        return C;
        end );

    AddMorphismFunction( R,
        function( new_source, f, new_range )
        local M, N, G1, G2, hM, hN, mors;
        M := Source( f );
        N := Range( f );
        hM := AsPresentationInHomalg( M );
        hN := AsPresentationInHomalg( N );
        mors := AsZFunction(
                function( k )
                local emb_hMk, emb_hNk, l;
                emb_hMk := EmbeddingInSuperObject( SubmoduleGeneratedByHomogeneousPart( k, hM ) );
                emb_hMk := AsPresentationMorphismInCAP( emb_hMk );
                emb_hNk := EmbeddingInSuperObject( SubmoduleGeneratedByHomogeneousPart( k, hN ) );
                emb_hNk := AsPresentationMorphismInCAP( emb_hNk );
                if not IsMonomorphism( emb_hNk ) then
                    Error( "Something unexpected happend!"  );
                fi;
                l := LiftAlongMonomorphism( emb_hNk, PreCompose( emb_hMk, f ) );
                return GradedPresentationMorphism( new_source[ k ], UnderlyingMatrix( l )*KoszulDualRing( S ), new_range[ k ] );
                end );
        return CochainMorphism( new_source, new_range, mors );
        end );

    return R;
end );

##
InstallMethod( RChainFunctor,
    [ IsHomalgGradedRing ],
    function( S )
    local A, cat_ext, chains_ext, cochains_ext, cochains_to_chains, R;
    
    if HasIsExteriorRing( S ) and IsExteriorRing( S ) then
      Error( "The input should be a graded polynomial ring" );
    fi;
    
    A := KoszulDualRing( S );
    
    cat_ext := GradedLeftPresentations( A );
    
    chains_ext := ChainComplexCategory( cat_ext : ObjectsEqualityForCache := 1, MorphismsEqualityForCache := 1 );
    
    cochains_ext := CochainComplexCategory( cat_ext : ObjectsEqualityForCache := 1, MorphismsEqualityForCache := 1 );
    
    cochains_to_chains := CochainToChainComplexFunctor( cochains_ext, chains_ext );
    
    R := PreCompose( [ RCochainFunctor( S ),  cochains_to_chains ] );
    
    return R;
    
end );


BindGlobal( "IS_POWER_OF_SOME_TWISTED_OMEGA_MODULE_WITH_EVEN_TWIST",
    function( P )
    local twist, n;
    n := Length( IndeterminatesOfExteriorRing( UnderlyingHomalgRing( P ) ) );
    if NrRows( UnderlyingMatrix( P ) ) = 0 and Length( DuplicateFreeList( GeneratorDegrees( P ) ) ) = 1 then
        twist := n - HomalgElementToInteger( GeneratorDegrees( P )[ 1 ] );
        if twist mod 2 = 0 then
            return [ true, twist ];
        else
            return [ false, twist ];
        fi;
    else
        return [ false, fail ];
    fi;
end );

##
InstallMethod( LCochainFunctor,
            [ IsHomalgGradedRing ],
  function( S )
    local cat_lp_ext, cat_lp_sym, cochains, ind_ext, ind_sym, L, KS, n, name;
    
    if HasIsExteriorRing( S ) and IsExteriorRing( S ) then
      Error( "The input should be a graded polynomial ring" );
    fi;
    n := Length( IndeterminatesOfPolynomialRing( S ) );
    KS := KoszulDualRing( S );
    ind_ext := IndeterminatesOfExteriorRing( KS );
    ind_sym := IndeterminatesOfPolynomialRing( S );
    
    cat_lp_sym := GradedLeftPresentations( S );
    cat_lp_ext := GradedLeftPresentations( KS );
    cochains := CochainComplexCategory( cat_lp_sym );
    name := Concatenation( "L functor from ", Name( cat_lp_ext ), " to ", Name( cochains ) );
    L := CapFunctor( name, cat_lp_ext, cochains );
    
    AddObjectFunction( L,
        function( M )
        local hM, diffs, C, d;
        hM := AsPresentationInHomalg( M );
         
        diffs := AsZFunction(
            function( i )
            local l, source, range, u;
            l := List( ind_ext, e -> RepresentationMapOfRingElement( e, hM, -i ) );
            l := List( l, m -> S * MatrixOfMap( m, 1, 1 ) );
            l := Sum( List( [ 1 .. n ], j -> ind_sym[ j ]* l[ j ] ) );
            source := GradedFreeLeftPresentation( NrRows( l ), S, List( [ 1 .. NrRows( l ) ], j -> -i ) );
            range := GradedFreeLeftPresentation( NrColumns( l ), S, List( [ 1 .. NrColumns( l ) ], j -> -i - 1 ) );
            l := GradedPresentationMorphism( source, l, range );
            return l;
            # This is still true because all I am doing is changing the basis of the homogeneous part -i of M
            # by multiplying it with -1.
            # u := IS_POWER_OF_SOME_TWISTED_OMEGA_MODULE_WITH_EVEN_TWIST( M );
            
            # if u[ 1 ] and i = u[ 2 ] - 1 and ( n mod 2 = 0 ) then
            #  Info( InfoBBGG, 1, "Basis change is applied when applying the functor L on an object!" );
            #  return AdditiveInverse( l );
            # else
            # return l;
            # fi;

            end );

        C :=  CochainComplex( cat_lp_sym, diffs );
        
        d := ShallowCopy( GeneratorDegrees( M ) );
        
        # the output of GeneratorDegrees is in general not integer.
        Apply( d, HomalgElementToInteger );
        
        if Length( d ) = 0 then
            SetLowerBound( C, 0 );
            SetUpperBound( C, 0 );
        else
            SetLowerBound( C, - Maximum( d ) );
            SetUpperBound( C, - Minimum( d ) + n );
        fi;
        
        return C;
        
        end );
    
    AddMorphismFunction( L,
        function( new_source, f, new_range )
        local M, N, mors;
        
        M := Source( f );
        N := Range( f );
        
        mors := AsZFunction(
                function( k )
                local l, s, r;
                l := ApplyFunctor( HomogeneousPartOverCoefficientsRingFunctor( KS, -k ), f );
                
                #s := IS_POWER_OF_SOME_TWISTED_OMEGA_MODULE_WITH_EVEN_TWIST( M );
                #r := IS_POWER_OF_SOME_TWISTED_OMEGA_MODULE_WITH_EVEN_TWIST( N );
                
                #if n mod 2 = 0 then
                
                #if ( s[ 1 ] and not r[ 1 ] ) or ( not s[ 1 ] and r[ 1 ] ) then
                #  if ( s[ 1 ] and k = s[ 2 ] ) or ( r[ 1 ] and k = r[ 2 ] ) then
                #    l := AdditiveInverse( l );
                #    Info( InfoBBGG, 1, "Basis change is applied when applying the functor L on a morphism!" );
                #  fi;
                #fi;
                #
                #if s[ 1 ] and r[ 1 ] and s[ 2 ] <> r[ 2 ] then
                #  if ( k = s[ 2 ] ) or ( k = r[ 2 ] ) then
                #    l := AdditiveInverse( l );
                #    Info( InfoBBGG, 1, "Basis change is applied when applying the functor L on a morphism!!" );
                #  fi;
                #fi;
                
                #fi;
                
                return GradedPresentationMorphism( new_source[ k ], UnderlyingMatrix( l ) * S, new_range[ k ] );
                
                end );
                
        return CochainMorphism( new_source, new_range, mors );
        end );
        
    return L;
    
end );

##
InstallMethod( LChainFunctor,
    [ IsHomalgGradedRing ],
    function( S )
    local cat_sym, chains_sym, cochains_sym, cochains_to_chains;
    
    if HasIsExteriorRing( S ) and IsExteriorRing( S ) then
      Error( "The input should be a graded polynomial ring" );
    fi;
    
    cat_sym := GradedLeftPresentations( S );
    
    chains_sym := ChainComplexCategory( cat_sym );
    cochains_sym := CochainComplexCategory( cat_sym );
    
    cochains_to_chains := CochainToChainComplexFunctor( cochains_sym, chains_sym );
    
    return PreCompose( [ LCochainFunctor( S ),  cochains_to_chains ] );
    
end );

##
# Can be very slow comparing to the new one.
# it is here only  for making tests.
BindGlobal( "L_COCHAIN_FUNCTOR_OLD",
    function( S )
    local cat_lp_ext, cat_lp_sym, cochains, ind_ext, ind_sym, L, KS, n, name;
    
    n := Length( IndeterminatesOfPolynomialRing( S ) );
    KS := KoszulDualRing( S );
    ind_ext := IndeterminatesOfExteriorRing( KS );
    ind_sym := IndeterminatesOfPolynomialRing( S );
    
    cat_lp_sym := GradedLeftPresentations( S );
    cat_lp_ext := GradedLeftPresentations( KS );
    cochains := CochainComplexCategory( cat_lp_sym );
    name := Concatenation( "L functor from ", Name( cat_lp_ext ), " to ", Name( cochains ) );
    L := CapFunctor( name, cat_lp_ext, cochains );
    
    AddObjectFunction( L,
        function( M )
        local hM, diffs, C, d;
        hM := AsPresentationInHomalg( M );
        diffs := AsZFunction(
            function( i )
            local l, source, range;
            l := List( ind_ext, e -> RepresentationMapOfRingElement( e, hM, -i ) );
            l := List( l, m -> S * MatrixOfMap( m, 1, 1 ) );
            l := Sum( List( [ 1 .. n ], j -> ind_sym[ j ]* l[ j ] ) );
            source := GradedFreeLeftPresentation( NrRows( l ), S, List( [ 1 .. NrRows( l ) ], j -> -i ) );
            range := GradedFreeLeftPresentation( NrColumns( l ), S, List( [ 1 .. NrColumns( l ) ], j -> -i - 1 ) );
            return GradedPresentationMorphism( source, l, range );
            end );
        C :=  CochainComplex( cat_lp_sym, diffs );
        
        d := ShallowCopy( GeneratorDegrees( M ) );
        
        # the output of GeneratorDegrees is in general not integer.
        Apply( d, HomalgElementToInteger );
        
        if Length( d ) = 0 then
            SetLowerBound( C, 0 );
            SetUpperBound( C, 0 );
        else
            SetLowerBound( C, - Maximum( d ) );
            SetUpperBound( C, - Minimum( d ) + n );
        fi;
        
        return C;
        
        end );
        
    AddMorphismFunction( L,
        function( new_source, f, new_range )
        local M, N, mors;
        
        M := Source( f );
        N := Range( f );
        
        mors := AsZFunction(
                function( k )
                local Mk, Nk, iMk, iNk, l;
                # There is a reason to write the next two lines like this
                # See AdjustedGenerators.
                Mk := GradedLeftPresentationGeneratedByHomogeneousPart( M, -k );
                Nk := GradedLeftPresentationGeneratedByHomogeneousPart( N, -k );
                iMk := EmbeddingInSuperObject( Mk );
                iNk := EmbeddingInSuperObject( Nk );
                
                if not IsMonomorphism( iNk ) then
                  Error( "Very serious: You think something is mono, but it is not" );
                fi;
                
                l := LiftAlongMonomorphism( iNk, PreCompose( iMk, f ) );
                
                return GradedPresentationMorphism( new_source[ k ], UnderlyingMatrix( l ) * S, new_range[ k ] );
              end );
        
        return CochainMorphism( new_source, new_range, mors );
      end );
      
    return L;
    
end );

##
InstallMethod( CastelnuovoMumfordRegularity,
                [ IsCapCategoryObject and IsCochainComplex ],
    function( C )
    local reg;
    reg := Maximum( List( [ ActiveLowerBound( C )  .. ActiveUpperBound( C ) ],
                        i -> i + CastelnuovoMumfordRegularity( C[ i ] ) ) );
    return Int( String( reg ) );
end );

##
InstallMethod( CastelnuovoMumfordRegularity,
                [ IsCapCategoryObject and IsChainComplex ],
    function( C )
    local reg;
    reg := Minimum( List( [ ActiveLowerBound( C ) .. ActiveUpperBound( C ) ],
                        i -> i - CastelnuovoMumfordRegularity( C[ i ] ) ) );
    return Int( String( reg ) );
end );

##
InstallMethodWithCrispCache( TateResolution,
    [ IsCapCategoryObject and IsChainComplex ],
  function( C )
    local chains, cat, S, A, lp_cat_ext, reg, R, ChR, B, Tot, ker, diffs, tot_i;
    
    chains := CapCategory( C );
    
    cat := UnderlyingCategory( chains );
    
    S := cat!.ring_for_representation_category;
    
    A := KoszulDualRing( S );
    
    lp_cat_ext := GradedLeftPresentations( A );
    
    reg := CastelnuovoMumfordRegularity( C );
    
    R := RChainFunctor( S );
    
    ChR := ExtendFunctorToChainComplexCategories( R );
    
    B := ApplyFunctor( ChR, C );
    
    B := HomologicalBicomplex( B );
    
    Tot := TotalComplex( B );
    
    diffs := AsZFunction(
      function( i )
        
        Info( InfoBBGG, 3, "Computing Tate resolution at index ", i );
        
        if i <= reg then
          
          tot_i := Tot^i;
          
          if i = reg and IsZeroForMorphisms( tot_i ) then
            
            return ZeroObjectFunctorial( lp_cat_ext );
          
          else
            
            return tot_i;
            
          fi;
        
        else
          
          ker := KernelEmbedding( diffs[ i - 1 ] );
          
          return
            PreCompose(
              EpimorphismFromSomeProjectiveObject( Source( ker ) ), ker
                );
        
        fi;
        
      end );
      
    return ChainComplex( lp_cat_ext, diffs );
    
end );

InstallMethodWithCrispCache( TateResolution,
    [ IsChainComplex, IsCapCategoryMorphism and IsChainMorphism, IsChainComplex ],
  function( new_source, phi, new_range )
    local chains, cat, S, A, lp_cat_ext, R, ChR, ChR_phi, B, Tot, reg_range, reg_source,
      reg, mors, kernel_lift_1, kernel_lift_2, kernel_functorial;
    
    chains := CapCategory( phi );
    
    cat := UnderlyingCategory( chains );
    
    S := cat!.ring_for_representation_category;
    
    A := KoszulDualRing( S );
    
    lp_cat_ext := GradedLeftPresentations( A );
    
    R := RChainFunctor( S );
    
    ChR := ExtendFunctorToChainComplexCategories( R );
    
    ChR_phi := ApplyFunctor( ChR, phi );
    
    B := BicomplexMorphism( ChR_phi );
    
    Tot := TotalComplexFunctorial( B );
    
    reg_source := CastelnuovoMumfordRegularity( Source( phi ) );
    
    reg_range := CastelnuovoMumfordRegularity( Range( phi ) );
    
    reg := Minimum( reg_source, reg_range );
    
    mors := AsZFunction(
      function( i )
        local mor;
        
        Info( InfoBBGG, 3, "Computing Tate resolution morphism at index ", i );
        
        if i <= reg then
          
          mor := Tot[ i ];
          
          if i = reg and ( IsZeroForObjects( new_source[ i ] )
              or IsZeroForObjects( new_range[ i ] ) ) then
                
                mor := ZeroMorphism( new_source[ i ], new_range[ i ] );
          
          fi;
          
          return mor;
        
        else
          
          return Lift( PreCompose( new_source^i, mors[ i - 1 ] ), new_range^i );
        
        fi;
        
      end );
    
    return ChainMorphism( new_source, new_range, mors );
    
end );

##
InstallMethodWithCrispCache( TateResolution,
    [ IsCapCategoryMorphism and IsChainMorphism ],
  function( phi )
    
    return
      TateResolution(
        TateResolution( Source( phi ) ),
        phi,
        TateResolution( Range( phi ) )
      );
    
end );
 
InstallMethodWithCrispCache( TateResolution,
    [ IsCapCategoryObject and IsGradedLeftPresentation ],
  function( M )
    local R;
    
    R := UnderlyingHomalgRing( M );
    
    if HasIsExteriorRing( R ) and IsExteriorRing( R ) then
      
      TryNextMethod();
    
    elif NrRows( UnderlyingMatrix( M ) ) = 0 and
          NrColumns( UnderlyingMatrix( M ) ) = 1 and
            GeneratorDegrees( M )[ 1 ] <> 0 then
          # I.e., It is of the form S(n)
          
          TryNextMethod( );
          
    else
      
      return TateResolution( StalkChainComplex( M, 0) );
    
    fi;
  
end );

InstallMethodWithCrispCache( TateResolution,
  [ IsCapCategoryObject and IsGradedLeftPresentation ],
  function( M )
    local R, degree, O, T, F, ChF, U;
    
    R := UnderlyingHomalgRing( M );
    
    if HasIsExteriorRing( R ) and IsExteriorRing( R ) then
      
      TryNextMethod();
    
    elif NrRows( UnderlyingMatrix( M ) ) = 0 and
          NrColumns( UnderlyingMatrix( M ) ) = 1 and
            GeneratorDegrees( M )[ 1 ] <> 0 then
        # I.e., It is of the form S(n)
        
        degree := GeneratorDegrees( M )[ 1 ];
        
        degree := HomalgElementToInteger( degree );
        
        O := TwistedGradedFreeModule( R, 0 );
        
        T := TateResolution( O );
        
        F := TwistFunctor( KoszulDualRing( R ), -degree );
        
        ChF := ExtendFunctorToChainComplexCategories( F );;
        
        T := ApplyFunctor( ChF, T );
        
        U := UnsignedShiftFunctor( CapCategory( T ), degree );
        
        T := ApplyFunctor( U, T );
        
        SetTateResolution( StalkChainComplex( M, 0 ), T );
        
        return T;
        
    else
      
      TryNextMethod( );
    
    fi;
  
end );

##
InstallMethodWithCrispCache( TateResolution,
    [ IsCapCategoryMorphism and IsGradedLeftPresentationMorphism ],
  function( phi )
    local R, degree, T, F, ChF, U;
    
    R := UnderlyingHomalgRing( phi );
    if HasIsExteriorRing( R ) and IsExteriorRing( R ) then
        TryNextMethod();
    
    # if the morphism is f: O(i) --> O(j)
    # Then use f[-i]:O(0) --> O(j-i)
    elif NrRows( UnderlyingMatrix( Source( phi ) ) ) = 0 and
            NrColumns( UnderlyingMatrix( Source( phi ) ) ) = 1 and
              GeneratorDegrees( Source( phi ) )[ 1 ] <> 0 and
                NrRows( UnderlyingMatrix( Range( phi ) ) ) = 0 and
                  NrColumns( UnderlyingMatrix( Range( phi ) ) ) = 1 then
                  
                  degree := GeneratorDegrees( Source( phi ) )[ 1 ];
          
                  degree := HomalgElementToInteger( degree );
                 
                  T := TateResolution( phi[ degree ] );
          
                  F := TwistFunctor( KoszulDualRing( R ), -degree );
      
                  ChF := ExtendFunctorToChainComplexCategories( F );
          
                  T := ApplyFunctor( ChF, T );
                  
                  U := UnsignedShiftFunctor( CapCategory( T ), degree );
                  
                  T := ApplyFunctor( U, T );
                  
                  SetTateResolution( StalkChainMorphism( phi, 0 ), T );
                  
                  return T;
    
    else
      
      return TateResolution( TateResolution( Source( phi ) ), StalkChainMorphism( phi, 0 ), TateResolution( Range( phi ) ) );
      
    fi;
end );

InstallMethodWithCrispCache( TateResolution,
    [ IsCapCategoryObject and IsGradedLeftPresentation ],
    function( P )
    local R, graded_lp_cat_ext, p, q, diffs;
    
    R := UnderlyingHomalgRing( P );
    
    if HasIsExteriorRing( R ) and IsExteriorRing( R ) then
        graded_lp_cat_ext := GradedLeftPresentations( R );
        p := ProjectiveResolution( P );
        q := InjectiveResolution( P );
        diffs := AsZFunction(
            function( i )
            if i > 1 then
                return p^( -i + 1 );
            elif i = 1 then
                return PreCompose( EpimorphismFromSomeProjectiveObject( P ), MonomorphismIntoSomeInjectiveObject( P ) );
            else
                return q^( -i );
            fi;
            end );
        return ChainComplex( graded_lp_cat_ext, diffs );
    
    else
        TryNextMethod();
    fi;
end );

InstallMethodWithCrispCache( TateResolution,
    [ IsCapCategoryMorphism and IsGradedLeftPresentationMorphism ],
    function( phi )
    local R, graded_lp_cat_ext, source, range, mors;
    
    R := UnderlyingHomalgRing( phi );
    
    if HasIsExteriorRing( R ) and IsExteriorRing( R ) then
        graded_lp_cat_ext := GradedLeftPresentations( R );
        source := TateResolution( Source( phi ) );
        range := TateResolution( Range( phi ) );
        mors := AsZFunction(
            function( i )
                                        local epi_to_range, epi_to_source;
                                        if i > 1 then
                                            return Lift( PreCompose( source^i, mors[ i - 1 ] ), range^i );
                                        elif i = 1 then
                                            epi_to_source := EpimorphismFromSomeProjectiveObject( Source( phi ) );
                                            epi_to_range := EpimorphismFromSomeProjectiveObject( Range( phi ) );
                                            return ProjectiveLift( PreCompose( epi_to_source, phi ), epi_to_range );
                                        else
                                            return Colift( source^( i + 1 ), PreCompose( mors[ i + 1 ], range^( i + 1 ) ) );
                                        fi;
                                        end );
        return ChainMorphism( source, range, mors );
        
    else
        TryNextMethod();
    fi;
end );

##
BindGlobal( "CAN_TWISTED_OMEGA_OBJECT",
  function( a )
    local A, full, add_full, n, degrees, pos;
    
    A := UnderlyingHomalgRing( a );
    
    full := FullSubcategoryGeneratedByTwistedOmegaModules( A );
    
    add_full := AdditiveClosure( full );
    
    n := Length( Indeterminates( A ) );
    
    degrees := GeneratorDegrees( a );
    
    degrees := List( degrees, HomalgElementToInteger );
    
    pos := PositionsProperty( degrees, d -> d in [ 1 .. n ] );
    
    degrees := List( degrees{ pos }, d -> - d + n );
    
    return AdditiveClosureObject( List( degrees, d -> TwistedOmegaModule( A, d ) / full ), add_full );
    
end );

##
BindGlobal( "CAN_TWISTED_OMEGA_MORPHISM",
  function( alpha )
    local A, full, n, a, can_a, b, can_b, degrees_a, pos_a, degrees_b, pos_b, matrix;
    
    A := UnderlyingHomalgRing( alpha );
    
    full := FullSubcategoryGeneratedByTwistedOmegaModules( A );
    
    n := Length( Indeterminates( A ) );
    
    a := Source( alpha );
    
    can_a := CAN_TWISTED_OMEGA_OBJECT( a );
    
    b := Range( alpha );
    
    can_b := CAN_TWISTED_OMEGA_OBJECT( b );
    
    degrees_a := GeneratorDegrees( a );
    
    degrees_a := List( degrees_a, HomalgElementToInteger );
    
    pos_a := PositionsProperty( degrees_a, d -> d in [ 1 .. n ] );
    
    degrees_a := List( degrees_a{ pos_a }, d -> - d + n );
   
    degrees_b := GeneratorDegrees( b );
    
    degrees_b := List( degrees_b, HomalgElementToInteger );
    
    pos_b := PositionsProperty( degrees_b, d -> d in [ 1 .. n ] );
    
    degrees_b := List( degrees_b{ pos_b }, d -> - d + n );
   
    matrix := UnderlyingMatrix( alpha );
    
    matrix := CertainColumns( CertainRows( matrix, pos_a ), pos_b );
    
    if NrCols( matrix ) = 0 then
      
      matrix := [ ];
      
    else
      
      matrix := List( [ 1 .. NrRows( matrix ) ],
                i -> List( [ 1 .. NrCols( matrix ) ],
                  j ->
                    GradedPresentationMorphism(
                        TwistedOmegaModule( A, degrees_a[ i ] ),
                        HomalgMatrix( [ [ matrix[ i, j ] ] ], 1, 1, A ),
                        TwistedOmegaModule( A, degrees_b[ j ] ) ) / full
                      ) );
   fi;
   
   return AdditiveClosureMorphism( can_a, matrix, can_b );
   
end );

##
BindGlobal( "CAN_TWISTED_OMEGA_CELL",
  function( cell )
     
    if IsCapCategoryObject( cell ) then
      
      return CAN_TWISTED_OMEGA_OBJECT( cell );
      
    else
      
      return CAN_TWISTED_OMEGA_MORPHISM( cell );
      
    fi;
    
end );

##
InstallMethod( TruncationFunctorUsingTateResolutionOp,
    [ IsHomalgGradedRing, IsInt ],
    function( S, i )
      local A, graded_lp_cat_ext, graded_lp_cat_sym, cochains_sym, cochains_ext, Ker, L, Cok, T, F, name;
      
      A := KoszulDualRing( S );
      
      graded_lp_cat_ext := GradedLeftPresentations( A );
      graded_lp_cat_sym := GradedLeftPresentations( S );
      
      
      cochains_sym := CochainComplexCategory( graded_lp_cat_sym );
      cochains_ext := CochainComplexCategory( graded_lp_cat_ext );
      
      Ker := KernelObjectFunctor( cochains_ext, graded_lp_cat_ext, i );;
      L := LCochainFunctor( S );
      Cok := CokernelObjectFunctor( cochains_sym, graded_lp_cat_sym, - i - 1 );
      
      T := PreCompose( [ Ker, L, Cok ] );
      
      name := Concatenation( "Truncation -using Tate resolution- endofunctor on ", Name( graded_lp_cat_sym ) ); 
      
      F := CapFunctor( name, graded_lp_cat_sym, graded_lp_cat_sym );
      
      AddObjectFunction( F,
      function( M )
        return ApplyFunctor( T, AsCochainComplex( TateResolution( M ) ) );
      end );
      
      AddMorphismFunction( F,
      function( source, phi, range )
        return ApplyFunctor( T, AsCochainMorphism( TateResolution( phi ) ) );
      end );
      
      return F;
end );

BindGlobal( "NatTransFromTruncationUsingTateResolutionToTruncationFunctorUsingHomalg_old",
    function( S, i )
      local graded_lp_cat, T1, T2, name, nat;
      
      graded_lp_cat := GradedLeftPresentations( S );
      
      T1 := TruncationFunctorUsingTateResolutionOp( S, i );
      T2 := TruncationFunctorUsingHomalg( S, i );
      name := Concatenation( "A natural transformation from ", Name( T1 ), " to ", Name( T2 ) );
      nat := NaturalTransformation( name, T1, T2 );
      
      AddNaturalTransformationFunction( nat,
      function( source, M, range )
        local A, L, tM, f, P, glp_i, nat_i, Mi, emb_Mi, emb_Mi_in_P, Pi, emb_Pi_in_P, lift, LP, mat, mor, colift;
        
        A := KoszulDualRing( S );
        L := LCochainFunctor( S );
        
        tM := AsCochainComplex( TateResolution( M ) );
        
        f := tM^i;
        P := KernelObject( f );
        glp_i := GLPGeneratedByHomogeneousPartFunctor( A, i );
        nat_i := NatTransFromGLPGeneratedByHomogeneousPartToIdentityFunctor( A, i );
        
        Mi := ApplyFunctor( glp_i, tM[ i ] );
        
        emb_Mi := ApplyNaturalTransformation( nat_i, tM[ i ] );
        emb_Mi_in_P := KernelLift( f, emb_Mi );
        
        Pi := ApplyFunctor( glp_i, P );
        
        emb_Pi_in_P := ApplyNaturalTransformation(  nat_i,  P );
        
        lift := LiftAlongMonomorphism( emb_Mi_in_P, emb_Pi_in_P );
        
        LP := ApplyFunctor( L, P );
        mat := UnderlyingMatrix( lift ) * S;
        mor := GradedPresentationMorphism( LP[ -i ], mat, range );
        colift := CokernelColift( LP^( -i - 1 ), mor );
        
        return colift;
      end );
      
      return nat;
end );

##
InstallMethod( NatTransFromTruncationUsingTateResolutionToIdentityFunctorOp,
    [ IsHomalgGradedRing, IsInt ],
    function( S, i )
      local A, inds, n, graded_lp_cat, T, Id, name, nat;

      A := KoszulDualRing( S );

      inds := IndeterminatesOfExteriorRing( A );

      n := Length( inds );

      graded_lp_cat := GradedLeftPresentations( S );
      
      T := TruncationFunctorUsingTateResolutionOp( S, i );
      Id := IdentityFunctor( graded_lp_cat );

      name := Concatenation( "A natural transformation from ", Name( T ), " to ", Name( Id ) );
      nat := NaturalTransformation( name, T, Id );

      AddNaturalTransformationFunction( nat,
      function( source, M, range )
        local L, tM, f, ker_emb, tM_i, htM_i, nat_i, L_ker_emb, emb_Mi, some_proj, max, mat, from_proj_to_Mi, mor, colift;
        
        if i < CastelnuovoMumfordRegularity( M ) then
          Error( "regularity of M should be less or equal to ", i );
        fi;

        L := LCochainFunctor( S );

        tM := AsCochainComplex( TateResolution( M ) );

        f := tM^i;
        ker_emb := KernelEmbedding( f );

        tM_i := Source( f );
        htM_i := AsPresentationInHomalg( tM_i );

        if Length( DuplicateFreeList( GeneratorDegrees( tM_i ) ) ) > 1 then
          Error( "This should not happen, check the regularity of the module!" );
        fi;

        nat_i := NatTransFromGLPGeneratedByHomogeneousPartToIdentityFunctor( S, i );

        L_ker_emb := ApplyFunctor( L, ker_emb );
        
        emb_Mi := ApplyNaturalTransformation( nat_i, M );
        
        some_proj := SomeProjectiveObject( Source( emb_Mi ) );

        max := HomalgElementToInteger( Maximum( GeneratorDegrees( tM_i ) ) );
        
        L := List( [ 1 .. n ], j -> RepresentationMapOfRingElement( inds[j], htM_i, max - j + 1 ) );

        mat := Product( List( L, MatrixOfMap ) );

        if LeftInverse( mat ) <> RightInverse( mat ) then
          Error( "The matrix is not invertable" );
        fi;
        
        # mat will be identity or -identity, depending on the number of indeterminates and max.
        mat := LeftInverse( mat );

        from_proj_to_Mi := GradedPresentationMorphism( some_proj, S*mat, Source( emb_Mi ) );

        mor := PreCompose( [ L_ker_emb[ -i ], from_proj_to_Mi, emb_Mi ] );
        
        if not IsZeroForMorphisms( PreCompose( Source( L_ker_emb )^( -i - 1 ), mor ) ) then
          Error( "Something unexpected happened!" );
        fi;

        colift := CokernelColift( Source( L_ker_emb )^( -i - 1 ), mor );

        return colift;
      end );

      return nat;
end );

##
BindGlobal( "NatTransFromTruncationUsingTateResolutionToIdentityFunctor_old",
#    [ IsHomalgGradedRing, IsInt ],
    function( S, i )
      local graded_lp_cat, T, Id, name, nat, nat_tate, nat_homalg;
      
      graded_lp_cat := GradedLeftPresentations( S );
      
      T := TruncationFunctorUsingTateResolutionOp( S, i );
      Id := IdentityFunctor( graded_lp_cat );
      name := Concatenation( "A natural transformation from ", Name( T ), " to ", Name( Id ) );
      nat := NaturalTransformation( name, T, Id );
      
      nat_tate   := NatTransFromTruncationUsingTateResolutionToTruncationFunctorUsingHomalg( S, i );
      nat_homalg := NatTransFromTruncationUsingHomalgToIdentityFunctor( S, i );
      
      AddNaturalTransformationFunction( nat,
      function( source, M, range )
        local nat_tate_M, nat_homalg_M;
        
        nat_tate_M := ApplyNaturalTransformation( nat_tate, M );
        nat_homalg_M := ApplyNaturalTransformation( nat_homalg, M );
        return PreCompose( nat_tate_M, nat_homalg_M );
        
      end );
      
      return nat;
end );

##
InstallMethod( TwistFunctor,
          [ IsHomalgGradedRing, IsHomalgElement ],
  function( S, degree )
    local cat, F;
    
    cat := GradedLeftPresentations( S );
    F := CapFunctor( Concatenation( String( degree ), "-twist endofunctor in ", Name( cat ) ), cat, cat );
    
    ##
    AddObjectFunction( F,
      function( M )
        local twist;
        if not IsBound( M!.ComputedTwists ) then
          M!.ComputedTwists := rec( );
        twist := AsGradedLeftPresentation( UnderlyingMatrix( M ), List( GeneratorDegrees( M ), d -> d - degree ) );
          M!.ComputedTwists!.( String( degree ) ) := twist;
          return twist;
        else
          if not String( degree ) in NamesOfComponents( M!.ComputedTwists ) then
          twist := AsGradedLeftPresentation( UnderlyingMatrix( M ), List( GeneratorDegrees( M ), d -> d - degree ) );
            M!.ComputedTwists!.( String( degree ) ) := twist;
            return twist;
          else
            return M!.ComputedTwists!.( String( degree ) );
          fi;
        fi;
    end );
    
    ##
    AddMorphismFunction( F,
      function( source, f, range )
        local twist;
        if not IsBound( f!.ComputedTwists ) then
          f!.ComputedTwists := rec( );
        twist := GradedPresentationMorphism( source, UnderlyingMatrix( f ), range );
          f!.ComputedTwists!.( String( degree ) ) := twist;
          return twist;
        else
          if not String( degree ) in NamesOfComponents( f!.ComputedTwists ) then
            twist := GradedPresentationMorphism( source, UnderlyingMatrix( f ), range );
            f!.ComputedTwists!.( String( degree ) ) := twist;
            return twist;
          else
            return f!.ComputedTwists!.( String( degree ) );
          fi;
        fi;
    end );
    
    return F;
end );

##
InstallMethod( TwistFunctor,
    [ IsHomalgGradedRing, IsList ],
    function( S, list )
      local degree;
      degree := HomalgModuleElement( list, DegreeGroup( S ) );
      return TwistFunctor( S, degree );
end );

##
InstallMethod( TwistFunctor,
    [ IsHomalgGradedRing, IsInt ],
    function( S, n )
      return TwistFunctor( S, [ n ] );
end );

##
InstallMethod( \[\],
    [ IsGradedLeftOrRightPresentation, IsHomalgElement ],
  function( M, degree )
    local ring;
    ring := UnderlyingHomalgRing( M );
    return ApplyFunctor( TwistFunctor( ring, degree ), M );
end );

##
InstallMethod( \[\],
    [ IsGradedLeftOrRightPresentation, IsList ],
  function( M, list )
    local ring;
    ring := UnderlyingHomalgRing( M );
    return ApplyFunctor( TwistFunctor( ring, list ), M );
end );

##
InstallMethod( \[\],
    [ IsGradedLeftOrRightPresentation, IsInt ],
  function( M, n )
    local ring;
    ring := UnderlyingHomalgRing( M );
    return ApplyFunctor( TwistFunctor( ring, n ), M );
end );

##
InstallMethod( \[\],
    [ IsGradedLeftOrRightPresentationMorphism, IsHomalgElement ],
  function( phi, degree )
    local ring;
    ring := UnderlyingHomalgRing( phi );
    return ApplyFunctor( TwistFunctor( ring, degree ), phi );
end );

##
InstallMethod( \[\],
    [ IsGradedLeftOrRightPresentationMorphism, IsList ],
  function( phi, list )
    local ring;
    ring := UnderlyingHomalgRing( phi );
    return ApplyFunctor( TwistFunctor( ring, list ), phi );
end );

##
InstallMethod( \[\],
    [ IsGradedLeftOrRightPresentationMorphism, IsInt ],
  function( phi, n )
    local ring;
    ring := UnderlyingHomalgRing( phi );
    return ApplyFunctor( TwistFunctor( ring, n ), phi );
end );

##
InstallMethod( DimensionOfTateCohomology,
        [ IsChainOrCochainComplex, IsInt, IsInt ],
  function( T, i, k )
    local cat, U, n, j, t, degrees;
    
    U := AsCochainComplex( T );
    
    cat := UnderlyingCategory( CapCategory( U ) );
    
    n := Length(
      IndeterminatesOfExteriorRing(
        cat!.ring_for_representation_category ) );
    
    j := i + k;
    
    t := -n - k;
    
    degrees := GeneratorDegrees( U[ j ] );
    
    degrees := List( degrees, HomalgElementToInteger );
    
    return Length( Positions( degrees, -t ) );
    
end );

##############################

# The output here is stable module that correspondes to O(k) [ the sheafification of S(k) ]
#InstallMethod( TwistedStructureBundleOp,
#          [ IsHomalgGradedRing, IsInt ],
#  function( Sym, k )
#    local F;
#    F := GradedFreeLeftPresentation( 1, Sym, [ -k ] );
#      return Source( CyclesAt( TateResolution( F ), 0 ) );
#end );

# See Appendix of Vector Bundels over complex projective spaces
#InstallMethod( TwistedCotangentBundleOp,
#          [ IsHomalgGradedRing, IsInt ],
#  function( A, k )
#    local n, F, hF, hM, cM, id, i, mat;
#    n := Length( IndeterminatesOfExteriorRing( A ) );
#    if k < 0 or k > n - 1 then
#      Error( Concatenation( "Cotangent bundels are defined only for 0,1,...,", String( n - 1 ) ) );
#    fi;
#    F := GradedFreeLeftPresentation( 1, A, [ n - k ] );
#    hF := AsPresentationInHomalg( F );
#    hM := SubmoduleGeneratedByHomogeneousPart( 0, hF );
#    hM := UnderlyingObject( hM );
#    cM := AsPresentationInCAP( hM );
#    mat := UnderlyingMatrix( cM );
#    id := HomalgInitialMatrix( NrColumns( mat ), NrColumns( mat ), A );
#    for i in [ 1 .. NrColumns( mat ) ] do
#      id[ i, NrColumns( mat ) - i + 1 ] := One( A );
#    od;
#    return AsGradedLeftPresentation( mat*id, Reversed( GeneratorDegrees( cM ) ) );
#end );
#
## See chapter 5, Sheaf cohomology and free resolutions over exterior algebra
#InstallMethod( KoszulSyzygyModuleOp,
#        [ IsHomalgGradedRing, IsInt ],
#  function( S, k )
#    local ind, K, koszul_resolution, n;
#    ind := Reversed( IndeterminatesOfPolynomialRing( S ) );
#    K := AsGradedLeftPresentation( HomalgMatrix( ind, S ), [ 0 ] );
#    koszul_resolution := ProjectiveResolution( K );
#    return CokernelObject( koszul_resolution^( -k - 2 ) );
#end );
