PublicFunction[ClearBundleData]

ClearBundleData[] := QuiverGeometryLoader`$BundleGraphCache = UAssociation[];

If[!AssociationQ[QuiverGeometryLoader`$BundleGraphCache],
QuiverGeometryLoader`$BundleGraphCache = UAssociation[]
];

(**************************************************************************************************)

PrivateFunction[bundleHashLookup]

bundleHashLookup[hash_, prop___] := QuiverGeometryLoader`$BundleGraphCache[hash, prop];

(**************************************************************************************************)

PublicFunction[BundleData]

BundleData[bundleGraph_Graph, key_:All] := Scope[
  data = getBundleGraphData[bundleGraph];
  If[!AssociationQ[data], ReturnFailed[]];
  If[key === All, data, Lookup[data, key]]
];

(**************************************************************************************************)

PrivateFunction[getBundleGraphData]

getBundleGraphData[bundleGraph_, baseGraph_:Automatic, fiberGraph_:None, sectionDisplayMethod_:Inherited] := Scope[
  
  hash = Hash[bundleGraph];
  If[AssociationQ[cachedValue = bundleHashLookup[hash]],
    Return @ cachedValue];

  bundleVertices = VertexList @ bundleGraph;
  bundleEdges = EdgeList @ bundleGraph;
  bundleVertexIndex = AssociationRange @ bundleVertices;
  bundleCoordinates = LookupVertexCoordinates @ bundleGraph;

  SetAutomatic[baseGraph, BundleToBaseGraph @ bundleGraph];
  baseVertices = VertexList @ baseGraph;
  baseVertexIndex = AssociationRange @ baseVertices;
  baseCoordinates = LookupVertexCoordinates @ baseGraph;

  fiberVertices = If[fiberGraph =!= None, VertexList @ fiberGraph, Union @ LastColumn @ VertexList @ bundleGraph];
  fiberVertexIndex = AssociationRange @ fiberVertices;
  fiberVertexColorFunction = DiscreteColorFunction[fiberVertices, Automatic];
  fiberGroups = GroupPairs @ bundleVertices;

  baseAdjacency = VertexAdjacencyAssociation @ baseGraph;
  taggedAdj = VertexTagAdjacencyAssociation @ bundleGraph;
  verticalAdjacency = joinAdjacencyAssociationsMatching[taggedAdj, BundleCardinal[None, _]];
  horizontalAdjacency = joinAdjacencyAssociationsMatching[taggedAdj, BundleCardinal[_, None]];

  areBundleAdjacent = AdjacentVerticesPredicate @ bundleGraph;
  areBaseAdjacent = AdjacentVerticesPredicate @ baseGraph;

  horizontalFoliation = CardinalSubquiver[bundleGraph, BundleCardinal[_, None]];
  verticalFoliation = CardinalSubquiver[bundleGraph, BundleCardinal[None, _]];

  cardinalIndex = EdgeToTagIndex @ bundleGraph;

  data = Association[
    "Hash" -> hash,
    "BundleGraph" -> bundleGraph,
    "BundleVertices" -> bundleVertices,
    "BundleVertexIndex" -> bundleVertexIndex,
    "BaseGraph" -> baseGraph,
    "BaseVertices" -> baseVertices,
    "BaseVertexIndex" -> baseVertexIndex,
    "FiberGraph" -> fiberGraph,
    "FiberVertices" -> fiberVertices,
    "FiberVertexIndex" -> fiberVertexIndex,
    "FiberGroups" -> fiberGroups,
    "BaseAdjacency" -> baseAdjacency,
    "VerticalAdjacency" -> verticalAdjacency,
    "HorizontalAdjacency" -> horizontalAdjacency,
    "HorizontalFoliation" -> horizontalFoliation,
    "VerticalFoliation" -> verticalFoliation,
    "AreBundleAdjacent" -> areBundleAdjacent,
    "AreBaseAdjacent" -> areBaseAdjacent,
    "FiberVertexColorFunction" -> fiberVertexColorFunction,
    "CardinalIndex" -> cardinalIndex,
    "SectionDisplayMethod" -> sectionDisplayMethod
  ];

  AssociateTo[QuiverGeometryLoader`$BundleGraphCache, hash -> data];

  data
];

joinAdjacencyAssociationsMatching[assocs_, pattern_] := Merge[Values @ KeySelect[assocs, MatchQ[pattern]], Catenate];

