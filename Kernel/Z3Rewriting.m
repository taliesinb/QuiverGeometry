PackageExport["MatchData"]
PackageExport["TokenData"]

MatchData[a_, None] := MatchData[a];

(**************************************************************************************************)

declareBoxFormatting[
	MatchData[tokens:{__TokenData}] :> ToBoxes[
		Row[Underscript @@@ tokens]
	]
]

(**************************************************************************************************)

PackageExport["RewritingSystemObject"]

declareObjectPropertyDispatch[RewritingSystemObject, rewritingSystemProperty];

constructRewritingSystsem[type_, rules_] := Scope[
	rules //= ToList;
	If[!RuleListQ[rules], ReturnFailed[]];
	assoc = Association[
		"Type" -> type,
		"Rules" -> rules
	];
 	System`Private`ConstructNoEntry[RewritingSystemObject, assoc]
];

(**************************************************************************************************)

declareObjectPropertyDispatch[RewritingSystemObject, rewritingSystemProperty];

$rewritingSystemProperyDispatch = <||>;

rewritingSystemProperty[data_, args___] :=
  $rewritingSystemProperyDispatch[data["Type"]][data, args];

declareRewritingSystemDispatch[type_, dispatchFunction_] :=
	$rewritingSystemProperyDispatch[type] = dispatchFunction;

(**************************************************************************************************)

PackageExport["RewritingSystemObjectQ"]

RewritingSystemObjectQ = Case[
	rs_RewritingSystemObject ? System`Private`HoldNoEntryQ := True;
	_ := False;
];

(**************************************************************************************************)

MakeBoxes[rs_RewritingSystemObject ? System`Private`HoldNoEntryQ, form_] :=
  rewritingSystemObjectBoxes[rs, form];

rewritingSystemObjectBoxes[rs:RewritingSystemObject[data_], form_] := Scope[
  UnpackAssociation[data, type, rules];
  BoxForm`ArrangeSummaryBox[
    RewritingSystemObject, object, None,
    (* Always displayed *)
    {
     {summaryItem["Type", type]},
     {summaryItem["Rules", Column @ rules]}
    },
    (* Displayed on request *)
    {},
    form,
    "Interpretable" -> Automatic
  ]
];

(**************************************************************************************************)

PackageExport["StringPlot"]

charToColor = Replace[{
	"r" -> $Red, "g" -> $Green, "b" -> $Blue,
	"a" -> $Red, "b" -> $Blue, "c" -> $Green,
	"x" -> $Teal, "y" -> $Orange, "z" -> $Pink,
	"0" -> White, "1" -> GrayLevel[0.3], "2" -> GrayLevel[0.65], "3" -> GrayLevel[0.4],
	"\[EmptySquare]" -> White, "\[FilledSquare]" -> GrayLevel[0.3],
	_ -> Pink
}];

StringPlot[s_String, sz_:6] :=
	FadedMeshImage[List @ ToRGB @ Map[charToColor, Characters @ s], sz]

(**************************************************************************************************)

PackageExport["StringRewritingSystem"]

StringRewritingSystem[rules_] := Scope[
	constructRewritingSystsem["String", rules]
]

declareRewritingSystemDispatch["String", stringRewritingSystemProperty]

stringRewritingSystemProperty[data_, "CayleyFunction", opts___Rule] := Scope[
	UnpackAssociation[data, rules];
	UnpackStringOptions[{opts}, True, labeled];
	If[labeled,
		StringLabeledReplaceList[rules],
		StringReplaceListOperator[rules]
	]
];

(**************************************************************************************************)

PackageExport["StringReplaceListOperator"]

StringReplaceListOperator[rules_][str_] :=
	StringReplaceList[str, rules];

(**************************************************************************************************)

PackageExport["StringLabeledReplaceList"]

StringLabeledReplaceList[str_, {rule_}] :=
	StringLabeledReplaceList[str, rule, None];

StringLabeledReplaceList[str_, rules_List] :=
	Catenate @ MapIndexed[
		StringLabeledReplaceList[str, #1, First @ #2]&,
		rules
	];

StringLabeledReplaceList[str_String, rule_, matchIndex_:None] := Scope[
	Map[
		span |-> Labeled[
			StringReplacePart[str, ochunk = StringReplace[ichunk = StringTake[str, span], rule], span],
			RewriteForm[
				StringRegionalStateForm[ichunk, span],
				StringRegionalStateForm[ochunk, span],
				matchIndex
			]
		],
		StringPosition[str, First @ rule]
	]
];

StringLabeledReplaceList[rule_][str_] := StringLabeledReplaceList[str, rule];
	
stringTokens[str_String, All] :=
	stringTokens[str, {1, StringLength @ str}];

stringTokens[str_String, span:{i_, j_}] :=
	Transpose[{
		Characters @ StringTake[str, span],
		Range[i, j]
	}];

(**************************************************************************************************)

PackageExport["CircularStringRewritingSystem"]

CircularStringRewritingSystem[rules_] := Scope[
	constructRewritingSystsem["CircularString", rules]
]

declareRewritingSystemDispatch["CircularString", circularStringRewritingSystemProperty]

circularStringRewritingSystemProperty[data_, "CayleyFunction", opts___Rule] := Scope[
	UnpackAssociation[data, rules];
	UnpackStringOptions[{opts}, True, labeled];
	If[labeled,
		CircularStringLabeledReplaceList[rules],
		CircularStringReplaceListOperator[rules]
	]
];

(**************************************************************************************************)

PackageExport["CircularStringReplaceListOperator"]

CircularStringReplaceListOperator[rules_][str_] :=
	Part[CircularStringLabeledReplaceList[str, rules], All, 1];

(**************************************************************************************************)

PackageExport["CircularStringLabeledReplaceList"]

CircularStringLabeledReplaceList[str_, {rule_}] :=
	CircularStringLabeledReplaceList[str, rule, None];

CircularStringLabeledReplaceList[str_, rules_List] :=
	Catenate @ MapIndexed[
		CircularStringLabeledReplaceList[str, #1, First @ #2]&,
		rules
	];

CircularStringLabeledReplaceList[str_String, rule_, matchIndex_:None] := Scope[
	str2 = StringJoin[str, str]; len = StringLength @ str;
	spans = StringPosition[str2, First @ rule];
	spans = {#, Mod[#, len, 1]}& /@ spans;
	spans = DeleteDuplicatesBy[spans, Last];
	VectorApply[
		{span, modSpan} |-> Labeled[
			circularStringReplacePart[str, ochunk = StringReplace[ichunk = StringTake[str2, span], rule], modSpan],
			RewriteForm[
				StringRegionalStateForm[ichunk, modSpan],
				StringRegionalStateForm[ochunk, modSpan],
				matchIndex
			]
		],
		spans
	]
];

CircularStringLabeledReplaceList[rule_][str_] := CircularStringLabeledReplaceList[str, rule];

circularStringReplacePart[str_, new_, {i_, j_}] /; j < i :=
	StringReplacePart[
		StringReplacePart[str, StringTake[new, 1 + len - i], {i, len}],
		StringTake[new, -j],
		{1, j}
	];

circularStringReplacePart[str_, new_, span_] := StringReplacePart[str, new, span];

(**************************************************************************************************)

PackageExport["PetriNet"]

PetriNet[rules_] := Scope[
	constructRewritingSystsem["PetriNet", rules]
]

(**************************************************************************************************)

PackageExport["RewriteQuiver"]
PackageExport["RewriteGraph"]

Options[RewriteQuiver] = Options[RewriteGraph] = Options[LatticeQuiver];

RewriteQuiver[system_RewritingSystemObject, initialState_, args___] :=
	rewriteGraphQuiver[system, initialState, True, args];

RewriteGraph[system_RewritingSystemObject, initialState_, args___] :=
	rewriteGraphQuiver[system, initialState, False, args];

rewriteGraphQuiver[system_, initialState_, isQuiver_, args___] := Scope[
	cayleyFunction = system["CayleyFunction", "Labeled" -> isQuiver];
	result = If[isQuiver, LatticeQuiver, LatticeGraph][
		<|"CayleyFunction" -> cayleyFunction, "InitialStates" -> {initialState}|>, args,
		GraphTheme -> If[isQuiver, "RewriteQuiver", "RewriteGraph"],
		DirectedEdges -> True,
		VertexNameFunction -> None
	];
	ExtendedGraph[result, Cardinals -> Sort[CardinalList[result]]]
]

(* TODO: fix Automatic options to inherit from the theme options *)

$RewriteQuiverThemeRules = {
  AspectRatioClipping -> False,
  ArrowheadSize -> 15,
  VertexSize -> 5, VertexFontSize -> 12,
  ImagePadding -> {Left -> 25, Right -> 25},
  ArrowheadPosition -> 0.5,
  ArrowheadShape -> "NarrowArrow",
  ImageSize -> ("ShortestEdge" -> 65),
  VertexLayout -> TreeVertexLayout[Orientation -> Left]
};

$RewriteGraphThemeRules = JoinOptions[
	ArrowheadStyle -> $Gray,
	ArrowheadShape -> "NarrowArrow",
	$RewriteQuiverThemeRules
];

$GraphThemeData["RewriteQuiver"] := $RewriteQuiverThemeRules;
$GraphThemeData["RewriteGraph"] := $RewriteGraphThemeRules;
