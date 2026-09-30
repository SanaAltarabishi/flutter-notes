import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FreeNotesApp());
}


//todo: add the ability to choose form the options that the url return in the world not just keep one of them
//we did something similar that he can edit it
//todo: voice notes
//todo: if we tap on the save we cannot make redo an undo :)
/*
todo :
InteractiveViewer + Canvas أكبر من الشاشة + Zoom/Pan + فصل Canvas coordinates عن screen coordinates.
وليس SingleChildScrollView أفقي + عمودي لوحدهم؛ لأنك تحتاج zoom + pan + transformation، وInteractiveViewer أنسب لهذا السيناريو. */
//_____________________________________________

