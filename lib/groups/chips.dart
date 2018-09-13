import 'package:flutter/material.dart';

class FilterChipBlock extends StatefulWidget {
  final String labelText;
  final List<String> names;
  final bool showCounter;
  final ValueSetter<int> onSelected;

  const FilterChipBlock({
    Key key,
    this.labelText,
    @required this.names,
    this.showCounter = false,
    this.onSelected,
  })  : assert(names != null),
        super(key: key);

  @override
  _FilterChipBlockState createState() => _FilterChipBlockState();
}

class _FilterChipBlockState extends State<FilterChipBlock> {
  Map<String, bool> _selected = Map();
  int _selectedCount = 0;

  @override
  Widget build(BuildContext context) {
    if (_selected.length != widget.names.length) {
      _selected.removeWhere((key, _) => !widget.names.contains(key));
      widget.names.forEach((s) {
        if (!_selected.containsKey(s)) {
          _selected[s] = false;
        }
      });
    }
    return InputDecorator(
      decoration: InputDecoration(
        labelText: widget.labelText,
        counterText:
            widget.showCounter ? '$_selectedCount/${_selected.length}' : null,
        border: OutlineInputBorder(),
      ),
      child: Wrap(
        spacing: 8.0,
        children: new List<Widget>.generate(
          widget.names.length,
          (i) => FilterChip(
                label: Text(widget.names[i]),
                selected: _selected[widget.names[i]],
                onSelected: (b) {
                  setState(() {
                    _selected[widget.names[i]] = b;
                    _selectedCount += b ? 1 : -1;
                  });
                  if (widget.onSelected != null) {
                    widget.onSelected(i);
                  }
                },
              ),
          growable: false,
        ),
      ),
    );
  }
}

class ChoiceChipBlock extends StatefulWidget {
  final String labelText;
  final List<String> names;
  final bool iconFont;
  final ValueSetter<int> onSelected;

  const ChoiceChipBlock({
    Key key,
    this.labelText,
    @required this.names,
    this.iconFont: false,
    this.onSelected,
  })  : assert(names != null),
        super(key: key);

  @override
  _ChoiceChipBlockState createState() => _ChoiceChipBlockState();
}

class _ChoiceChipBlockState extends State<ChoiceChipBlock> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: widget.labelText,
        border: OutlineInputBorder(),
      ),
      child: Wrap(
        spacing: 8.0,
        children: new List<Widget>.generate(
          widget.names.length,
          (i) {
            List<Icon> icons;
            if (widget.iconFont) {
              icons = List.generate(
                widget.names[i].length,
                (j) => Icon(IconData(
                      widget.names[i].codeUnitAt(j),
                      fontFamily: 'MaterialIcons',
                    )),
                growable: false,
              );
            }
            return FilterChip(
              label: widget.iconFont
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: icons,
                    )
                  : Text(widget.names[i]),
              selected: _selected == i,
              onSelected: (b) {
                setState(() {
                  _selected = i;
                });
                if (widget.onSelected != null) {
                  widget.onSelected(i);
                }
              },
            );
          },
          growable: false,
        ),
      ),
    );
  }
}
