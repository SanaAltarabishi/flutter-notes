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
- Changed setTool so selections are retained only while CanvasTool.lasso is active. The selected content itself is not deleted or changed—only the visual selection lines are cleared.
- add speech to text (voice notes) with the ability to choose the language and the engine (Deepgram or Groq).


*/