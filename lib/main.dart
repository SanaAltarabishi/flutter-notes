import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FreeNotesApp());
}


//todo: add the ability to choose form the options that the url return in the world not just keep one of them
//we did something similar that he can edit it
//todo: voice notes
//todo : make sure from the recongizing, if it ronded it not being test proberly ?
/*
todo :
InteractiveViewer + Canvas أكبر من الشاشة + Zoom/Pan + فصل Canvas coordinates عن screen coordinates.
وليس SingleChildScrollView أفقي + عمودي لوحدهم؛ لأنك تحتاج zoom + pan + transformation، وInteractiveViewer أنسب لهذا السيناريو. */
//todo : add lock for the books and pages :)
//todo: check the theme and how we using it
//todo : check the router and navigation
//todo:fix the zooming with the text !!

//_____________________________________________
/*
done:
1. feat(canvas): implement auto-expanding infinite canvas with edge detection

- Added dynamic canvas resizing that triggers when the drawing pointer reaches the boundaries of the current canvas.
- Implemented critical coordinate translation logic for top/left expansions: existing strokes and blocks are shifted right/down by the expansion delta. This ensures the active drawing point remains visually anchored under the user's finger, preventing visual jumps.
- Updated `CanvasState` to support a dynamic `canvasSize` instead of fixed page dimensions.
- Refined eraser cursor calculations, clearly distinguishing between viewport (screen) coordinates and scene coordinates to maintain a consistent visual radius regardless of the zoom level.
- Added comprehensive inline documentation explaining the scene translation math and the viewport coordinate tracking for the eraser cursor.
-----------------------------
2. fix(canvas): wrap text blocks at their own width

Text was laid out up to the right edge of the canvas and ignored
TextBlock.width, so long text stayed on one line and ran off the page.
The selection box measured it the same way, so it grew with the text.
- add TextBlockLayout as the single place that decides text layout:
  wrap at the block's own width, never past the right edge of the canvas
- use it in the painter (_drawText, _blockBounds), SelectionGeometry,
  and in selectAt / updateSelection, so the drawn text, the selection
  box and the touch test always match
- scale the width together with the font size when only the font size
  changes (slider), so line breaks stay the same
- use TextBlockLayout.defaultWidth for _defaultTextWidth


3.change the app name to Inko

4. change the SplashPage and add AppBackground

5. change the color palette + the icon colors to fit the palette

6.fix the bug in the saving of the drawing

7.adding the search bar for the books and pages


*/