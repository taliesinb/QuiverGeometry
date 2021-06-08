PackageExport["IllustatePathsOnFundamentalQuiver"]

IllustatePathsOnFundamentalQuiver[quiver_, pathSpecs_, opts___] := Scope[
  quivers = Labeled[DrawFundamentalQuiverPath[quiver, #1, #2, #3], FormatCardinalWord @ #1]& @@@ pathSpecs;
  regionSpec = Style[Arrow @ Path[1, #1], #2, "Foreground", HighlightRadius->0.3, EdgeSetback -> 2.5]& @@@ pathSpecs;
  lattice = LatticeGraph[
    quiver, opts, GraphRegionHighlight -> regionSpec, ArrowheadSize -> Scaled[0.8],
    LabelCardinals -> True, DirectedEdges -> True, ImagePadding -> {{0, 20}, {20, 0}},
    ArrowheadShape -> "Line"
  ];
  SpacedRow[lattice, quivers, Spacings -> 0]
]


(**************************************************************************************************)

PackageExport["DrawFundamentalQuiverPath"]

DrawFundamentalQuiverPath[quiver_, path_, color_, adjustments_] := Scope[
  regionSpec = Style[
    Arrow[Path[1, path, PathAdjustments -> adjustments]], color, "Foreground",
    HighlightRadius -> 0.3, EdgeSetback -> 3, PathOutline -> False
  ];
  ExtendedGraph[quiver, GraphRegionHighlight -> regionSpec, ArrowheadStyle -> $Gray, ArrowheadSize -> MediumSmall,
    ImagePadding -> 15, EdgeStyle -> LightGray, LabelCardinals -> True,
    GraphLegend -> None, ArrowheadShape -> "Line"]
];


(**************************************************************************************************)

PackageExport["PathBuilder"]

PathBuilder[vertex_, path_String, adjustments_:{}] :=
  GraphRegionHighlight -> Style[Arrow[Path[vertex, path, PathAdjustments -> adjustments]], $Purple,
    "Foreground", HighlightRadius->0.3, EdgeSetback -> 2];

PathBuilder[vertex_, {path1_String, path2_String}] :=
  GraphRegionHighlight -> Style[
      {Style[Arrow[Path[vertex, path1]], $Purple],
       Style[Arrow[Path[vertex, path2]], $Teal]},
      "Foreground", HighlightRadius->0.3, EdgeSetback -> 2];

(**************************************************************************************************)

PackageExport["UnitGraphics"]

UnitGraphics[g_, n_:1] := Graphics[g,
  ImageSize -> Medium, PlotRange -> {{-n, n}, {-n, n}}, PlotRangePadding -> Scaled[0.1],
  Frame -> True, FrameTicks -> None, GridLines -> {Range[-n, n, n / 5], Range[-n, n, n / 5]}
];

(**************************************************************************************************)

PackageExport["LabeledEdgeGraph"]

LabeledEdgeGraph[g_, opts___] := ExtendedGraph[g, opts,
  VertexSize -> Large, ArrowheadSize -> Medium,
  LabelCardinals->True, ImagePadding -> {{20,10},{20,10}},
  VertexLabels -> "Name",
  ImageSize -> ("ShortestEdge" -> 60)
];


(**************************************************************************************************)

PackageExport["LatticeColoringPlot"]

$customColors = <|"a" -> $Purple, "b" -> $Pink, "c" -> $Teal, "x" -> $Pink, "y" -> $Teal|>;

$plcOrientation = "Horizontal";

LatticeColoringPlot[quiver_, args___, "Orientation" -> o_] := Block[
  {$plcOrientation = o},
  LatticeColoringPlot[quiver, args]
];

LatticeColoringPlot[quiver_, args___] := Scope[
  quiver = Quiver[quiver];
  notb = VertexCount[quiver] > 1;
  icon = Quiver[quiver,
    GraphLegend -> None,
    ArrowheadSize -> MediumSmall,
    ArrowheadShape -> {"Arrow", TwoWayStyle -> "OutClose"},
    ArrowheadStyle -> $LightGray,
    LabelCardinals -> True, VertexSize -> Huge,
    ImagePadding -> {{12, 12},{20, 20}}, ImageSize -> "ShortestEdge" -> 45,
    VertexColorFunction -> "Index",
    VertexCoordinates -> If[notb, CirclePoints @ VertexCount[quiver], {{0, 0}}]
  ];
  If[notb, icon //= CombineMultiedges];
  graph = LatticeGraph[quiver, args,
    VertexColorFunction -> "GeneratingVertex",
    VertexSize -> 1.2, ImageSize -> 120, GraphLegend -> None
  ];
  If[$plcOrientation === "Horizontal",
    Row[{graph, icon}, Spacer[15]],
    Labeled[graph, icon]
  ]
]

(**************************************************************************************************)

PackageExport["LatticeColoringRow"]

LatticeColoringRow[list_List, args___] :=
  MapSpacedRow[LatticeColoringPlot[#, args, "Orientation" -> "Vertical"]&, list];

(**************************************************************************************************)

PackageExport["LatticeColoringGrid"]

makeColoringGridEntry[label:(_String | _Integer | _Subscript), ___] :=
  {Item[Style[label, $LegendLabelStyle, 15, Bold], ItemSize -> {Full, 2}, Alignment -> Center], SpanFromLeft};

makeColoringGridEntry[None, ___] :=
  {" ", SpanFromLeft};

makeColoringGridEntry[quiver_List, args___] :=
  Map[makeColoringGridEntry[#, args]&, quiver];

makeColoringGridEntry[quiver_, args___] :=
  First @ LatticeColoringPlot[quiver, args];

LatticeColoringGrid[items_, args___] := Scope[
  entries = Map[Flatten[List[makeColoringGridEntry[#, args]]]&, items];
  entries = PadRight[entries, Automatic, ""];
  entries = Replace[entries, row:{_, SpanFromLeft, Repeated[""]} :> Replace[row, "" -> SpanFromLeft, {1}], {1}];
  Grid[
    entries,
    Spacings -> {0, 0}, ItemSize -> {All, 0},
    Alignment -> Center
  ]
];

(**************************************************************************************************)

PackageExport["HighlightCompassDomain"]

HighlightCompassDomain[graph_, cardinals_, color_] := Scope[
  region = ConnectedSubgraph[EdgePattern[_, _, Alternatives @@ cardinals]];
  arrowheadStyle = Append[All -> Transparent] @ KeyTake[LookupCardinalColors @ graph, cardinals];
  ExtendedGraph[graph, ArrowheadStyle -> arrowheadStyle, EdgeStyle -> VeryThick,
    ColorRules -> {region -> Opacity[1,color], All -> LightGray}, GraphLegend -> None]
];

(**************************************************************************************************)

PackageExport["CompassDiagram"]

CompassDiagram[compasses_, equivSets_, opts___] := Scope[
  cardinals = DeleteDuplicates[Join @@ Values @ compasses];
  equivSets = DeleteDuplicates @ Join[equivSets, Map[Negated, equivSets, {2}], List /@ cardinals];
  equivIndex = Map[Union @@ Part[equivSets, #]&, PositionIndex[equivSets, 2]];
  compassIndex = PositionIndex[compasses, 2] /. Key[k_] :> k;
  CollectTo[{$edges}, Do[
    createEdges[card, equivCard],
    {card, cardinals},
    {equivCard, equivIndex[card]}
  ]];
  compasses = Keys @ compasses;
  coords = {-#1, #2}& @@@ CirclePoints[Length @ compasses];
  ExtendedGraph[compasses, $edges, VertexCoordinates -> coords,
    opts,
    GraphLayout -> {"MultiEdgeDistance" -> 0.13},
    GraphLegend -> Automatic, Cardinals -> cardinals,
    ArrowheadShape -> {"PairedSquare", PairedDistance -> 0, NegationStyle -> "OverBar"},
    VertexLabelStyle -> {LabelPosition -> Automatic},
    VertexLabels -> "Name", ArrowheadSize -> Large
  ]
];

createEdges[card1_, card2_] := Outer[
  {comp1, comp2} |-> If[Order[comp1, comp2] == 1,
    Internal`StuffBag[$edges, DirectedEdge[comp1, comp2, CardinalSet[{card1, card2}]]]
  ],
  compassIndex @ card1, compassIndex @ StripNegated @ card2, 1
];

(**************************************************************************************************)

PackageExport["MobiusStrip"]

MobiusStrip[n_, is3D_:False] := Scope[
  $n = n; tauN = Tau / n; $isA = Table[i <= n/2, {i, 0, n-1}];
  $isC = RotateLeft[$isA, Ceiling[n/3]];
  $isB = RotateRight[$isA, Ceiling[n/3]];
  edges = mobiousPatch /@ Range[0, n-1];
  vertices = Flatten @ Table[LatticeVertex[{x, y}], {x, 0, n-1}, {y, -1, 1}];
  coords = If[is3D,
    Flatten[Table[TorusVector[{n, y}, {phi, phi/2}], {phi, 0, Tau - tauN, tauN}, {y, -1, 1}], 1],
    First /@ vertices
  ];
  Quiver[vertices, edges,
    VertexCoordinates -> coords,
    EdgeShapeFunction -> If[is3D, Automatic, drawMobiusEdge],
    ImagePadding -> {{20, 20}, {20, 0}}, Cardinals -> {"x", "a", "b", "c"},
    GraphOrigin -> LatticeVertex[{Floor[n/2], 0}]
  ]
];

mlv[x_, y_] := LatticeVertex[{Mod[x, $n], If[x == $n || x == -1, -y, y]}];

mobiousPatch[x_] := <|
  "x" -> Table[mlv[x, y] -> mlv[x + 1, y], {y, -1, 1}],
  toCards[x] -> {DirectedPath[mlv[x, -1], mlv[x, 0], mlv[x, 1]]}
|>;
toCardinalSet[{e_}] := e;
toCardinalSet[e_] := CardinalSet[e];
toCards[n_] := toCardinalSet @ Pick[{"a", "b", If[n < $n/2, Negated @ "c", "c"]}, {Part[$isA, n+1], Part[$isB, n+1], Part[$isC, n+1]}];

drawMobiusEdge[assoc_] := Scope[
  UnpackAssociation[assoc, coordinates, arrowheads, shape, edgeIndex];
  {a, b} = {{ax, ay}, {bx, by}} = FirstLast[coordinates];
  lines = If[EuclideanDistance[a, b] > 1,
    ab = Normalize[b - a];
    ab *= If[Abs[First[ab]] > Abs[Last[ab]], {1, 0}, {0, 1}] * 0.8;
    {l, r} = {{b + ab, b}, {a, a - ab}};
    counter = assoc["Counter"];
    {shape /@ {l, r}, {Opacity[1, $DarkGray], Text[counter, Mean @ #, {0, 1.8}]& /@ {l, r}}}
  ,
    shape @ {a, b}
  ];
  Style[lines, arrowheads]
];

(**************************************************************************************************)

PackageExport["SimpleLabeledGraph"]

SimpleLabeledGraph[args___] := ExtendedGraph[args, $simpleLabeledGraphOpts];

$simpleLabeledGraphOpts = Sequence[
  CardinalColors -> None, VertexLabels -> Automatic, EdgeLabels -> "Cardinal",
  VertexCoordinates -> {{-1, 0}, {0, 0}, {1, 0}}, ImagePadding -> {{0,0}, {0, 25}}, EdgeLabelStyle -> {Spacings -> -0.3},
  GraphLayout -> {"MultiEdgeDistance" -> 0.6}, ArrowheadPosition -> 0.59, ImageSize -> "ShortestEdge" -> 55, ArrowheadSize -> Medium
];

(**************************************************************************************************)

PackageExport["SimpleLabeledQuiver"]

SimpleLabeledQuiver[args___] := Quiver[args, $simpleLabeledQuiverOpts];

$simpleLabeledQuiverOpts = Sequence[
  VertexLabels -> "Name",
  VertexCoordinates -> RotateLeft[CirclePoints[3],2],
  GraphLayout -> {"MultiEdgeDistance" -> 0.2}, ArrowheadPosition -> 0.59, ImageSize -> "ShortestEdge" -> 80, ArrowheadSize -> Medium
];