import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FreeNotesApp());
}


//todo: add the ability to choose form the options that the url return in the world not just keep one of them
//we did something similar that he can edit it
//todo: voice notes

/*
todo :
InteractiveViewer + Canvas أكبر من الشاشة + Zoom/Pan + فصل Canvas coordinates عن screen coordinates.
وليس SingleChildScrollView أفقي + عمودي لوحدهم؛ لأنك تحتاج zoom + pan + transformation، وInteractiveViewer أنسب لهذا السيناريو. */
//todo : make the pin movement sharpless !

//_____________________________________________

//done : i found a problem with the selection if we have a line using the drawing pen and hilighter , it detect all the block and not only the line or the stuff i need to be detected
//fix :stop the abilite to redo and undo after saving
//make the color picker core widget and use it with the canvas tool bar
//fix: improve stroke rendering smoothness
