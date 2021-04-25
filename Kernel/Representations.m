Package["GraphTools`"]


PackageImport["GeneralUtilities`"]


PackageExport["RepresentationObject"]

SetUsage @ "
RepresentationObject[$$] represents a group representation.
* It has the following properties, accessible via rep$['prop$']:
| 'CayleyGraph' | Cayley graph for the representation |
| 'Dimension' | size of the representation matrices |
| 'Generators' | a list of RepresentationElement objects |
| 'Group' | group being represented |
| 'GroupOrder' | order of the group being represented |
| 'Identity' | the RepresentationElement for the identity |
| 'Type' | the type of representation, as a string  |
"

constructGroupRepresentation[data_] := Scope[
  group = data["Group"];
  matrices = Normal /@ data["Generators"];
  matrices = ExpandUnitRoots[matrices];
  type = Which[
    TranslationGroupQ[group], "Translation",
    AnyTrue[matrices, ComplexMatrixQ], Which[
      AllTrue[matrices, UnitaryMatrixQ], "Unitary",
      AllTrue[matrices, HermitianMatrixQ], "Hermitian",
      True, "Complex"
    ],
    AllTrue[matrices, UpperUnitriangularMatrixQ], "Unitriangular",
    AllTrue[matrices, UpperTriangularMatrixQ], "Triangular",
    AllTrue[matrices, PermutationMatrixQ], "Permutation",
    AbelianGroupQ[group] || AllTrue[matrices, TranslationMatrixQ], "Abelian",
    True, "Mixed"
  ];
  System`Private`ConstructNoEntry[RepresentationObject, Append[data, "Type" -> type]]
];

$representationIcon =
 Framed[Style["R", FontSize -> 20], FrameStyle -> Gray,
  ImageSize -> {35, 35}, Alignment -> Center]

RepresentationObject /: MakeBoxes[object:RepresentationObject[data_Association] ? System`Private`HoldNoEntryQ, format_] := ModuleScope[
  UnpackAssociation[data, group, groupOrder, generators, dimension, type];
  BoxForm`ArrangeSummaryBox[
    RepresentationObject, object, $representationIcon; None,
    (* Always displayed *)
    {
     {BoxForm`SummaryItem[{"Group: ", group}], SpanFromLeft},
     {BoxForm`SummaryItem[{"Order: ", groupOrder}], BoxForm`SummaryItem[{"Type: ", type}]},
     {BoxForm`SummaryItem[{"Generators: ", Length[generators]}], BoxForm`SummaryItem[{"Dimension: ", dimension}]}
     },
    (* Displayed on request *)
    {{Row[generators, "  "], SpanFromLeft}},
    format,
    "Interpretable" -> Automatic
  ]
];

declareObjectPropertyDispatch[RepresentationObject, representationProperty];

representationProperty[assoc_, "Identity"] :=
  RepresentationElement @ IdentityMatrix[assoc["Dimension"]];

representationProperty[assoc_, "CayleyGraph"] :=
  computeCayleyQuiver[assoc];

representationProperty[assoc_, "CayleyFunction", opts___Rule] :=
  computeCayleyFunction[assoc, opts];

Options[computeCayleyFunction] = {"Symmetric" -> True, "Labeled" -> True};
computeCayleyFunction[data_, OptionsPattern[]] := Scope[
  UnpackAssociation[data, generators];
  UnpackOptions[symmetric, labeled];
  list = Flatten @ MapIndexed[
    {gen, index} |-> {
      If[labeled, Labeled[First @ index], Identity] @ gen,
      If[symmetric && (igen = InverseFunction[gen]) =!= gen,
        If[labeled, Labeled[Negated @ First @ index], Identity] @ igen,
        Nothing
      ]
    },
    generators
  ];
  ApplyThrough[list]
];


PackageExport["RepresentationObjectQ"]

SetUsage @ "
RepresentationObjectQ[rep$] returns True if rep$ is a valid RepresentationObject[$$].
"

RepresentationObjectQ[_RepresentationObject ? System`Private`HoldNoEntryQ] := True;
RepresentationObjectQ[_] := False;


PackageExport["CayleyFunction"]

SetUsage @ "
CayleyFunction[obj$] returns the function that takes an element of obj$ and \
returns a list of successors elements that represent the action of generators of obj$ on the element.
* rep can be a group, RepresentationObject, QuiverRerpresentationObject, or RootSystem.
CayleyFunction takes the following options:
| 'Symmetric' | True | whether to include the action of the inverses of the generators |
| 'Labeled' | True | whether to yield successors that are Labeled with the name of the corresponding generator |
* For 'Symmetric' -> True and 'Labeled' -> True, the inverses successors are labeled with Negated[gen$].
"

Options[CayleyFunction] = {
  "Symmetric" -> True,
  "Labeled" -> True
};

DeclareArgumentCount[CayleyFunction, 1];

CayleyFunction[object_, OptionsPattern[]] := Scope[
  UnpackOptions[labeled, symmetric];
  rep = Which[
    QuiverRepresentationObjectQ[object], object,
    RepresentationObject[object], object,
    GroupQ[object], GroupRepresentation[object],
    RootSystemQ[object], object,
    True, ReturnFailed["badrep"]
  ];
  rep["CayleyFunction", "Labeled" -> symmetric, "Symmetric" -> symmetric]
];


PackageExport["CayleyQuiver"]

SetUsage @ "
CayleyQuiver[obj$] returns the cardinal quiver representing the Cayley graph of a RepresentationObject or Group.
"

DeclareArgumentCount[CayleyQuiver, 1];

CayleyQuiver::incomplete = "Cayley graph is incomplete."
CayleyQuiver::notrep = "First argument should be a valid RepresentationObject or group."

CayleyQuiver[rep_] := Scope[
  rep = toRepresentation[rep, None];
  If[FailureQ[rep], ReturnFailed["notrep"]];
  computeCayleyQuiver @ getObjectData @ rep
];

computeCayleyQuiver[data_] := Scope[
  cfunc = computeCayleyFunction[data, "Labeled" -> True, "Symmetric" -> True];
  istate = List @ representationProperty[data, "Identity"];
  {edges, reason} = StateTransitionGraph[cfunc, istate, {"EdgeList", "TerminationReason"}, MaxDepth -> 8, MaxVertices -> 100];
  If[reason =!= "Complete", Message[CayleyQuiver::incomplete]];
  edges = DeleteDuplicates @ edges;
  Quiver[edges]
];

Unprotect[Labeled];

Labeled[None] := Identity;
Labeled[label_][g_] := Labeled[g, label];
Labeled[f_, label_][input___] := Labeled[f[input], label];

Protect[Labeled];


PackageExport["RepresentationElement"]

SetUsage @ "
RepresentationElement[matrix$] is the matrix representation of a group element.
* RepresentationElements are produced by a RepresentationObject[$$].
* RepresentationElement will format as a compact matrix.
* rep$1[rep$2] will return the RepresentationElement for g$1 \[CircleDot] g$2.
"

RepresentationElement /: InverseFunction[RepresentationElement[matrix_]] := RepresentationElement[Inverse[matrix]];

RepresentationElement /: Normal[RepresentationElement[matrix_]] :=
  If[Developer`PackedArrayQ[matrix], matrix, ExpandUnitRoots @ matrix];

declareFormatting[
  RepresentationElement[matrix_?MatrixQ] :> renderRepresentationMatrix[matrix, $isTraditionalForm]
];

splitImag[e_] := If[ContainsQ[e, _Complex], fmtComplexRow[Re @ e, Im @ e], e];

fmtComplexRow[0, im_] := Row[{im, $imagStr}];
fmtComplexRow[re_, im_] := Row[{re, "+", im, $imagStr}];

RepresentationElement[elem1_][RepresentationElement[elem2_]] := With[
  {res = Dot[elem1, elem2]},
  RepresentationElement @ If[Developer`PackedArrayQ[res], res, Expand @ res]
];


PackageExport["ToRepresentation"]

SetUsage @ "
ToRepresentation[obj$] attempts to convert obj$ to a RepresentationObject.
* If obj$ is already a RepresentationObject, it is returned unchanged.
* If obj$ is a group or QuiverRepresentation, its base representation is returned.
* If obj$ is a RootSystem, its TranslationGroup representation is returned.
* Otherwise, $Failed is returned.
"

ToRepresentation = MatchValues[
  r_RepresentationObject ? System`Private`HoldNoEntryQ := r;
  cq_QuiverRepresentationObject ? System`Private`HoldNoEntryQ := cq["Representation"];
  rs_RootSystemObject ? System`Private`HoldNoEntryQ := GroupRepresentation @ TranslationGroup @ rs;
  g_ ? GroupQ := GroupRepresentation @ g;
  _ := $Failed;
];


PackageScope["toRepresentation"]

toRepresentation["Abelian", n_] := GroupRepresentation[InfiniteAbelianGroup[n]];
toRepresentation["Redundant", n_] := RedundantAbelianRepresentation[n-1];
toRepresentation[spec_, _] :=  ToRepresentation @ spec;


PackageExport["CustomRepresentation"]

SetUsage @ "
CustomRepresentation[{matrix$1, $$, matrix$n}] takes a list of matrices and \
returns a RepresentationObject[$$].
CustomRepresentation[matrices$, group$] specifies that the representation is \
of the group group$.
"

DeclareArgumentCount[CustomRepresentation, {1, 2}];

declareSyntaxInfo[CustomRepresentation, {_, _.}];

CustomRepresentation::notmat = "First argument should be a list of matrices."
CustomRepresentation::badrepmat = "Matrices have inconsistent dimensions: ``."

CustomRepresentation[matrices_, group_:None] := Scope[
  If[!VectorQ[matrices, MatrixQ], ReturnFailed["notmat"]];
  matrices = Developer`ToPackedArray /@ Normal /@ matrices;
  dims = Dimensions[matrices];
  If[!MatchQ[dims, {_, _, _}], ReturnFailed["badintcode", Dimensions /@ matrices]];
  dim = Part[dims, 2];
  generators = RepresentationElement /@ matrices;
  repData = <|
    "Group" -> group,
    "GroupOrder" -> GroupOrder[group],
    "Generators" -> generators,
    "Dimension" -> dim
  |>;
  constructGroupRepresentation[repData]
];


PackageExport["RedundantAbelianRepresentation"]

SetUsage @ "
RedundantAbelianRepresentation[n$] produces a RepresentationObject whose n$ generators are translation \
matrices, namely upper unitriangular matrices with a single 1 and a following neighboring -1 in the \
final column.
* This representation is the representation of an Abelian group for which g$1 g$2 = g$3, g$2 g$3 = g$4, etc.
"

DeclareArgumentCount[RedundantAbelianRepresentation, 1];

makeRedundantAffineUnitMatrix[i_, n_] :=
  ReplacePart[IdentityMatrix[n], {{i, n} -> 1, {Mod[i+1, n-1, 1], n} -> -1}];

RedundantAbelianRepresentation::badrepdim = "The provided dimension `` should be >= 2."

RedundantAbelianRepresentation[n_Integer] := If[n < 2,
  Message[RedundantAbelianRepresentation::badrepdim, n],
  CustomRepresentation[
    Table[makeRedundantAffineUnitMatrix[i, n+2], {i, n+1}],
    InfiniteAbelianGroup[n]
  ]
]


PackageExport["RepresentationGenerators"]

SetUsage @ "
RepresentationGenerators[obj$] returns a list of RepresentationElement objects \
for the generators of a group, RepresentationObject, or QuiverRepresentationObject.
"

DeclareArgumentCount[RepresentationGenerators, 1];

RepresentationGenerators[obj_] := Scope[
  rep = CheckRepArg[1];
  rep["Generators"]
]


PackageExport["GroupRepresentation"]

SetUsage @ "
GroupRepresentation[group$] returns a RepresentationObject of a group group$.
"

DeclareArgumentCount[GroupRepresentation, 1];

General::badintcode = "Internal code returned inconsistent matrix dimensions: ``."

declareSyntaxInfo[GroupRepresentation, {_}];

GroupRepresentation[group_] := Scope[
  If[!GroupQ[group], ReturnFailed["notgroup", group]];
  matrices = Developer`ToPackedArray /@ Normal /@ makeGenerators[group];
  dims = Dimensions[matrices];
  If[!MatchQ[dims, {_, _, _}], ReturnFailed["badintcode", Dimensions /@ matrices]];
  dim = Part[dims, 2];
  generators = RepresentationElement /@ matrices;
  repData = <|
    "Group" -> group,
    "GroupOrder" -> GroupOrder[group],
    "Generators" -> generators,
    "Dimension" -> dim
  |>;
  constructGroupRepresentation[repData]
]


PackageScope["makeGenerators"]

(* this is the fallback for groups that don't have specific implementations *)
makeGenerators[group_] := permutationGroupMatrices[group];

permutationGroupMatrices[group_] := Scope[
  generators = GroupGenerators[group];
  If[!ListQ[generators], ReturnFailed[]];
  max = Max[PermutationMax /@ generators];
  Normal /@ Map[CyclesToPermutationMatrix[#, max]&, generators]
];

CyclesToPermutationMatrix[Cycles[cycles_], n_] := Scope[
  edges = Map[
    cycle |-> Map[# -> 1&, Partition[cycle, 2, 1, 1]],
    cycles
  ];
  stable = Complement[Range[n], Union @@ cycles];
  stableEdges = Map[{#, #} -> 1&, stable];
  SparseArray[Flatten @ {edges, stableEdges}, {n, n}]
];

complexAbelianMatrices[dims_] := Scope[
  n = Length[dims];
  Table[
    DiagonalMatrix @ ReplacePart[Ones[n], i -> RootOfUnity[Part[dims, i]]],
    {i, n}
  ]
];

unitRootAbelianMatrices[dims_] := Scope[
  n = Length[dims];
  Table[
    DiagonalMatrix @ ReplacePart[Ones[n], i -> UnitRoot[Part[dims, i]]],
    {i, n}
  ]
];


PackageExport["TransformGenerators"]

SetUsage @ "
TransformGenerators[representation$, transformation$] transforms the generators of a RepresentationObject[$$], \
returning a new RepresentationObject[$$].
* transformation$ can be the string 'Redundant', which forms Dot[g$i, Inverse[g$j]] for j$ = i$ + 1 (mod n$).
* transformation$ can be a function taking n$ matrices, where n$ is the number of existing generators. It should return \
a new list of matrices.
"

DeclareArgumentCount[TransformGenerators, 2];

TransformGenerators::namedtrans = "The transformation `` is not a known named transformation.";
TransformGenerators::badtrans = "The transformation returned an object of dimensions ``, instead of a list of square matrices.";

declareSyntaxInfo[TransformGenerators, {_, _}];

TransformGenerators[rep_, trans_] := Scope[
  rep = CheckRepArg[1];
  data = getObjectData[rep];
  gens = First /@ data["Generators"]; n = Length[gens];
  gens = Which[
    trans === "Redundant",
      shape = Length @ First @ First[gens];
      Table[Dot[gens[[i]], Inverse[gens[[Mod[i + 1, n, 1]]]]], {i, n}],
    StringQ[trans],
      ReturnFailed["namedtrans", trans],
    True,
      trans @@ gens
  ];
  dims = Dimensions[gens];
  If[!MatchQ[dims, {_, z_, z_}], ReturnFailed["badtrans", dims]];
  data["Generators"] = RepresentationElement /@ gens;
  constructGroupRepresentation[data]
];

