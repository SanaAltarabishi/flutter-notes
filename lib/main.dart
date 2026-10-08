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
//todo: fix the exeption  of the toolbar
//todo : add change color and name to the books
//todo: make the page name not like that also the design of it not like that
//todo : use the fvm to this project..
//todo : when i select the drawing and change the color it back to pin ! it okay with the highlighter and the magic but not with the selection
//todo: if we only could change the color and the size of the text so we have to fix - either to make every think could change its color and size or - to make the slider and the color change not active in this parts (also in the earaser ) meaning to make the color and the slider section appera only with the tools that could update the stuff in it and use it
//for example in the magic i only can change the color ,so i don't need the slider of the size , in the earaser i don't need both , in the highliter i need bot , but in the select(lasso) i don't need the color or the slider (or we add the ability to use them and this will be a ux deision)
//todo : make the eye and the tap container in the same one container
//_____________________________________________
/*
- update the tool bar
- Added an edit button to book_card.dart.
Connected the button to the existing edit form in books_page.dart.
Editing now keeps the current book title and color initialized in book_form_dialog.dart.
The existing ColorPicker can change the initialized color.
- adding name parameter to the pages
- adding update name flow
- adding fvm
- fix the expetion in the toolbar
*/