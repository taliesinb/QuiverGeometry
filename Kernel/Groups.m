Package["GraphTools`"]


PackageImport["GeneralUtilities`"]


PackageScope["makeGenerators"]


$posIntOrInfinity = (_Integer ? Positive) | Infinity;

$IntZ = TemplateBox[{}, "Integers"] // RawBoxes;

GroupOrder;
Unprotect[GroupOrder];

(* since we are adding Infinity support to CyclicGroup and AbelianGroup, we must
prevent these RuleCondition-based messages *)
GroupTheory`PermutationGroups`Private`CheckGroupDegree[GroupOrder] := False;

PackageExport["GroupQ"]

SetUsage @ "
GroupQ[group$] returns True if group$ is a valid group.
"

GroupQ[HoldPattern @ PermutationGroup[{__Cycles}]] := True;
GroupQ[e_] := GroupTheory`PermutationGroups`Private`NamedGroupQ[e];


PackageExport["AbelianGroupQ"]

SetUsage @ "
AbelianGroupQ[group$] returns True if group$ is an Abelian group.
"

AbelianGroupQ[group_] := MatchQ[group,
  CyclicGroup[$posIntOrInfinity] | AbelianGroup[{Repeated[$posIntOrInfinity]}] | InfiniteAbelianGroup[_Integer] |
  GroupDirectProduct[list_List /; VectorQ[list, AbelianGroupQ]]
];


(* Framework to set up custom groups *)

declareGroup[rules__RuleDelayed] := Scan[declareGroup, {rules}];
declareGroup[pattern_ :> {"Generators" :> generators_, "Order" :> order_, "Format" :> format_}] := (
  GroupQ[HoldPattern @ pattern] := True;
  makeGenerators[HoldPattern @ pattern] := generators;
  GroupOrder[HoldPattern @ pattern] := order;
  declareFormatting[pattern :> format]
);

declareGroup[___] := Panic["BadDeclareGroup"];


(* Add support to AbelianGroup for Infinity *)

declareGroup[
  AbelianGroup[orders:{Repeated[$posIntOrInfinity]}] :> {
    "Generators" :> constructDirectProductGenerators[Apply[makeAbelianGeneratorBlocks, orders]],
    "Order" :> RuleCondition[Infinity, MemberQ[orders, Infinity]],
    "Format" :> Row[makeAbelianSymbol /@ orders, "\[CirclePlus]"]
  }
]

makeAbelianGeneratorBlocks[n_Integer, rest___] :=
  Prepend[makeAbelianGeneratorBlocks[rest], makeCylicGenerators[n]];

makeAbelianGeneratorBlocks[infs:Longest[Infinity..], rest___] :=
  Prepend[makeAbelianGeneratorBlocks[rest], makeInfiniteAbelianGenerators[Length[{infs}]]]

makeAbelianGeneratorBlocks[] := {};


(* Add support to CyclicGroup for Infinity *)

declareGroup[
  CyclicGroup[n:$posIntOrInfinity] :> {
    "Generators" :> makeCylicGenerators[n],
    "Order" :> n,
    "Format" :> makeAbelianSymbol[n]
  }
];

makeAbelianSymbol[n_Integer] := Subscript[$IntZ, n];
makeAbelianSymbol[Infinity] := $IntZ;

makeCylicGenerators[n_Integer] := {{{UnitRoot[n]}}};
makeCylicGenerators[Infinity] := makeInfiniteAbelianGenerators[1];


(* add formating for some existing groups *)

declareFormatting[
  AlternatingGroup[n_Integer] :> Subscript[Style["A", Italic], n],
  SymmetricGroup[n_Integer] :> Subscript[Style["S", Italic], n],
  DihedralGroup[n_Integer] :> Subscript["Di", n]
];


PackageExport["GroupDirectProduct"]

SetUsage @ "
GroupDirectProduct[{g$1, $$, g$n}] represents the product of several groups.
* The generators of the product is the union of generators of the g$i.
* GroupDirectProduct works with GroupRepresentation.
* GroupDirectProduct does not work with the other group theory functions.
";

declareGroup[
  GroupDirectProduct[groups:{Repeated[_ ? GroupQ]}] :> {
    "Generators" :> constructDirectProductGenerators[makeGenerators /@ g],
    "Order" :> Times @@ Map[GroupOrder, g],
    "Format" :> Apply[If[VectorQ[list, AbelianGroupQ], CirclePlus, CircleTimes], Map[maybeBracket, groups]]
  }
];

constructDirectProductGenerators[generatorLists_] := Scope[
  identities = IdentityMatrix[Length[First[#]]]& /@ generatorLists;
  Flatten[Table[
    Map[
      gen |-> BlockDiagonalMatrix[ReplacePart[identities, i -> gen]],
      generatorLists[[i]]
    ],
    {i, Length[generatorLists]}
  ], 1]
];

maybeBracket /: MakeBoxes[maybeBracket[e_], form:StandardForm | TraditionalForm] := Scope[
  subbox = MakeBoxes[e, form];
  If[MatchQ[subbox, TemplateBox[_, "RowWithSeparators"]], RowBox[{"(", subbox, ")"}], subbox]
];



PackageExport["DiscreteHeisenbergGroup"]

SetUsage @ "
DiscreteHeisenbergGroup[] represents the Heisenberg group of 3 \[Times] 3 upper-unitriangular matrices with integer entries.
* DiscreteHeisenbergGroup works with GroupRepresentation.
* DiscreteHeisenbergGroup does not work with the other group theory functions, since it has no finite permutation representation.
"

declareGroup[
  DiscreteHeisenbergGroup[] :> {
    "Generators" :> Map[UnitAffineMatrix[3, #]&, {{1, 2}, {1, 3}, {2, 3}}],
    "Order" :> Infinity,
    "Format" :> Style["H", Italic]
  }
];


PackageExport["InfiniteAbelianGroup"]

SetUsage @ "
InfiniteAbelianGroup[n$] represents an infinite Abelian group on n$ generators.
* InfiniteAbelianGroup works with GroupRepresentation.
* InfiniteAbelianGroup does not work with the other group theory functions, since it has no finite permutation representation.
"

declareGroup[
  InfiniteAbelianGroup[n_ ? Internal`PositiveIntegerQ] :> {
    "Generators" :> makeInfiniteAbelianGenerators[n],
    "Order" :> Infinity,
    "Format" :> If[n === 1, $IntZ, Superscript[$IntZ, n]]
  }
];

makeInfiniteAbelianGenerators[n_] :=
  Table[makeAffineUnitMatrix[i, n+1], {i, n}];

makeAffineUnitMatrix[i_, n_] :=
  ReplacePart[IdentityMatrix[n], {i, n} -> 1];



PackageExport["GroupGeneratorElements"]

SetUsage @ "
GroupGeneratorElements[group$] returns the RepresentationElement[$$] objects corresponding to its generators.
"

GroupGeneratorElements[group_] := Scope[
  rep = GroupRepresentation[group];
  If[!RepresentationObjectQ[rep], ReturnFailed[]];
  rep["Generators"]
];


(* PackageExport["QuaternionGroup"]

SetUsage @ "
QuaternionGroup[] represents the group of unit quaternions.
"
 *)



PackageExport["TranslationGroup"]

SetUsage @ "
TranslationGroup[vectors$] represents an Abelian translation group generated by the translation vectors vectors$.
TranslationGroup[RootSystem[$$]] uses the simple roots of a given root system.
* The group operation is given by composing translations.
* A generator acts by translating: adding its corresponding vector to its operand.
"

declareGroup[
  TranslationGroup[vecs_ ? MatrixQ] :> {
    "Generators" :> Map[TranslationMatrix, vecs],
    "Order" :> Infinity,
    "Format" :> Subsuperscript["T", Length @ vecs, Length @ First @ vecs]
  },
  TranslationGroup[rs_ ? RootSystemObjectQ] :> {
    "Generators" :> rs["TranslationMatrices"],
    "Order" :> Infinity,
    "Format" :> Tooltip[Subsuperscript["T", rs["Count"], rs["Dimension"]], rs]
  }
];


PackageExport["TranslationGroupQ"]

SetUsage @ "
TranslationGroupQ[group$] returns True if group$ is a ReflectionGroup.
"

TranslationGroupQ[_TranslationGroup] := True;
TranslationGroupQ[_] := False;


PackageExport["ReflectionGroup"]

SetUsage @ "
ReflectionGroup[vectors$] represents an reflection group generated by the reflection vectors vectors$.
ReflectionGroup[RootSystem[$$]] uses the positive roots of a given root system.
* The group operation is given by composing reflections.
* A generator acts by reflecting: reflecting its operand by a hyperplane perpendicular to its corresponding vector.
"

declareGroup[
  ReflectionGroup[vecs_ ? MatrixQ] :> {
    "Generators" :> Map[TranslationMatrix, vecs],
    "Order" :> Infinity,
    "Format" :> Subsuperscript["R", Length @ vecs, Length @ First @ vecs]
  },
  ReflectionGroup[rs_ ? RootSystemObjectQ] :> {
    "Generators" :> rs["ReflectionMatrices"],
    "Order" :> rs["Count"],
    "Format" :> Tooltip[Subsuperscript["R", rs["Count"]/2, rs["Dimension"]], rs]
  }
];

PackageExport["ReflectionGroupQ"]

SetUsage @ "
ReflectionGroupQ[group$] returns True if group$ is a ReflectionGroup.
"

ReflectionGroupQ[_ReflectionGroup] := True;
ReflectionGroupQ[_] := False;