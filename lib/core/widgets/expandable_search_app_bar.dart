import 'dart:async';
import 'package:flutter/material.dart';

class ExpandableSearchAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final Widget title;
  final String hintText;
  final ValueChanged<String> onQueryChanged;
  final Color? backgroundColor;

  const ExpandableSearchAppBar({
    super.key,
    required this.title,
    required this.hintText,
    required this.onQueryChanged,
    this.backgroundColor,
  });

  @override
  State<ExpandableSearchAppBar> createState() =>
      _ExpandableSearchAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _ExpandableSearchAppBarState extends State<ExpandableSearchAppBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounce;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    if (_isOpen) {
      _closeSearch();
      return;
    }

    setState(() {
      _isOpen = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isOpen) {
        _focusNode.requestFocus();
      }
    });
  }

  void _closeSearch() {
    _debounce?.cancel();
    _controller.clear();
    _focusNode.unfocus();
    widget.onQueryChanged('');
    setState(() {
      _isOpen = false;
    });
  }

  void _onChanged(String query) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onQueryChanged(query);
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _controller.clear();
    widget.onQueryChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      title: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: _isOpen
            ? TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.clear),
                          tooltip: MaterialLocalizations.of(context)
                              .deleteButtonTooltip,
                        ),
                  isDense: true,
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              )
            : widget.title,
      ),
      backgroundColor: widget.backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      actions: [
        IconButton(
          onPressed: _toggleSearch,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              _isOpen ? Icons.close : Icons.search,
              key: ValueKey(_isOpen),
            ),
          ),
          tooltip: _isOpen ? 'Close search' : 'Search',
        ),
      ],
    );
  }
}
