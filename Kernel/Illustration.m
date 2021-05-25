Package["GraphTools`"]

PackageImport["GeneralUtilities`"]


(**************************************************************************************************)

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
  LabelCardinals->True,ImagePadding->{{20,10},{20,0}}, VertexLabels -> "Name"
];


(**************************************************************************************************)

PackageExport["PlotLatticeColoring"]

$customColors = <|"a" -> $Purple, "b" -> $Pink, "c" -> $Teal, "x" -> $Pink, "y" -> $Teal|>;

PlotLatticeColoring[quiver_, args___] := Scope[
  quiver = Quiver[quiver];
  notb = VertexCount[quiver] > 1;
  icon = Quiver[quiver,
    GraphLegend -> None,
    ArrowheadSize -> MediumSmall,
    ArrowheadShape -> {"Arrow", TwoWayStyle -> "Out"},
    ArrowheadStyle -> $LightGray,
    LabelCardinals -> True, VertexSize -> Huge,
    ImagePadding -> 8, ImageSize -> {100, 100},
    VertexColorFunction -> "Index",
    GraphLayout -> If[notb, "CircularEmbedding", Automatic]
  ];
  If[notb, icon //= CombineMultiedges];
  Row[{LatticeGraph[quiver, args,
    VertexColorFunction -> "GeneratingVertex",
    VertexSize -> 1.2, ImageSize -> 150, GraphLegend -> None
  ], icon}, Spacer[15]]
]

(**************************************************************************************************)

PackageExport["LatticeColoringGrid"]

LatticeColoringGrid[items_, args___] := Scope[
  Grid[
    Map[PlotLatticeColoring[#, args]&, items, {2}],
    Spacings -> {5, 0}
  ]
];
