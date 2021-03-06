PublicFunction[Tau]

SetUsage @ "
Tau is an alias for 2 * %Pi.
"

Tau = 2 * Pi;

(**************************************************************************************************)

PublicFunction[NLogN]

SetListable[NLogN];
NLogN[0|0.] := 0;
NLogN[n_] := n * Log2[n];

(**************************************************************************************************)

PublicFunction[RandomSeeded]

SetUsage @ "
RandomSeeded[body$, seeding$] evaluates body$ with %%RandomSeeding -> seeding$.
* seeding$ of Automatic does not localize the RNG when evaluating body$.
"

SetHoldFirst[RandomSeeded];

RandomSeeded[body_, Automatic] := body;
RandomSeeded[body_, other_] := BlockRandom[body, RandomSeeding -> other];

(**************************************************************************************************)

PrivateFunction[toListOfLists]

toListOfLists[list:{__List}] := list;
toListOfLists[list_List] := {list};
toListOfLists[_] := $Failed;

(**************************************************************************************************)

PublicFunction[ToInverseFunction]

SetUsage @ "
ToInverseFunction[f$] returns %InverseFunction[f$].
* ToInverseFunction exists to enable a fast-path for QuiverGeometry-specific functions.
"

ToInverseFunction[e_] := InverseFunction[e];

(**************************************************************************************************)

PrivateFunction[LookupAnnotation]

SetUsage @ "
LookupAnnotation[object$, key$] gives the value of the annotation associated with key$ in object$.
LookupAnnotation[object$, {key$1, key$2, $$}] gives a list of values.
LookupAnnotation[object$, spec$, default$] evaluates and returns default$ if the key or keys is not present.
* By default, if no value is present, Automatic is returned.
"

SetHoldRest[LookupAnnotation];

LookupAnnotation[obj_, key_, default_:Automatic] :=
  OnFailed[AnnotationValue[obj, key], default];

LookupAnnotation[obj_, key_List, default_:Automatic] :=
  VectorReplace[AnnotationValue[obj, key], $Failed :> default];

(**************************************************************************************************)

PrivateVariable[$TriangleVectors]

$TriangleVectors = {{0, 1}, {-1/2*Sqrt[3], -1/2}, {Sqrt[3]/2, -1/2}};

(**************************************************************************************************)

PrivateFunction[LengthNormalize]

LengthNormalize[{}] := {};
LengthNormalize[e_] := e / Length[e];

(**************************************************************************************************)

PrivateFunction[TotalNormalize]

TotalNormalize[{}] := {};
TotalNormalize[e_] := e / Max[Total[e], $MachineEpsilon];

(**************************************************************************************************)

PrivateFunction[notInternalSymbolQ]

SetHoldFirst @ notInternalSymbolQ;

notInternalSymbolQ[sym_Symbol] := !StringEndsQ[SymbolName @ Unevaluated @ sym, "$"];
notInternalSymbolQ[_] := True;
