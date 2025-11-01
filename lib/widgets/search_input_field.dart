import 'package:flutter/material.dart';

class SearchInputCustomTextField extends StatefulWidget {
  final TextEditingController searchTextEditingController;
  final FocusNode searchFocus;
  final Function(String) search;

  const SearchInputCustomTextField({
    super.key,
    required this.searchTextEditingController,
    required this.searchFocus,
    required this.search,
  });

  @override
  State<SearchInputCustomTextField> createState() =>
      _SearchInputCustomTextFieldState();
}

class _SearchInputCustomTextFieldState
    extends State<SearchInputCustomTextField> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = widget.searchTextEditingController;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(width: 1, color: theme.colorScheme.outlineVariant),
      ),
      child: TextField(
        controller: controller,
        focusNode: widget.searchFocus,
        textInputAction: TextInputAction.search,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          hintText: 'Search logs...',
          prefixIcon: const Icon(Icons.search_sharp, size: 22),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  splashRadius: 18,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    controller.clear();
                    widget.search('');
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {}); // refresh suffix icon visibility
          widget.search(value);
        },
      ),
    );
  }
}
