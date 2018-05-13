ReadPackage( "BBGG", "/examples/glp_over_g_exterior_algebra/stable_cat_of_glp_over_exterior_algebra.g" );
m := RandomMatrixBetweenGradedFreeLeftModules( [3,4,7],[1,2,1,2,0], S);
M :=  AsGradedLeftPresentation(m,[1,2,1,2,0]);
T := TateTest( S );
TM := ApplyFunctor( T, M );
TM := BrutalTruncationAbove( TM, 1 );
TM := BrutalTruncationBelow( TM, -2 );
Ch_to_be_named := ExtendFunctorToCochainComplexCategoryFunctor( to_be_named );
U := ApplyFunctor( Ch_to_be_named, TM );
L := LFunctor( S );
ChL := ExtendFunctorToCochainComplexCategoryFunctor(L);
t := ApplyFunctor( ChL, U );
t := CohomologicalBicomplex(t);

t := TotalComplex(t);
H0 := CohomologyAt( t, 0 );
sM := AsStableObject( Source( CyclesAt( ApplyFunctor( T, M ), 0 ) ) );
sH0 := AsStableObject( Source( CyclesAt( ApplyFunctor( T, H0 ), 0 ) ) );
IsEqualForObjects( sM, sH0 );