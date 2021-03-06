PrivateFunction[bannerToMarkdown]

bannerToMarkdown[text_String] := bannerToMarkdown[text] = outputCellToMarkdown @ makeBannerCell[text];

makeBannerCell[str_] := Cell[BoxData @ makeBannerGraphics[str, 5], "Output"];

makeBannerGraphics[str_, n_] := ToBoxes @
  Framed[
    Graphics[
      Text[Style[str, Bold, FontColor -> Black,
        FontFamily -> "Helvetica", FontSize -> 14]],
      Background -> RGBColor[0.9558361921359645, 0.8310111921713484, 0.0999649884717605, 1.],
      FrameStyle -> None,
      PlotRange -> {{-1, 1}, {-1, 1}/n},
      ImageSize -> {200, 200/n}
    ],
    ImageMargins -> 25, FrameStyle -> None
  ];
