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
  final int selected;
  final ValueSetter<int> onSelected;

  const ChoiceChipBlock({
    Key key,
    this.labelText,
    @required this.names,
    this.selected: 0,
    this.onSelected,
  })  : assert(names != null),
        super(key: key);

  @override
  _ChoiceChipBlockState createState() => _ChoiceChipBlockState();
}

class _ChoiceChipBlockState extends State<ChoiceChipBlock> {
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

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
            ThemeData theme = Theme.of(context);
            return ChoiceChip(
              label: Text(widget.names[i]),
              selected: _selected == i,
              selectedColor: Colors.orange.withAlpha(0x3d),
              labelStyle: theme.chipTheme.labelStyle.copyWith(
                  color: theme.brightness == Brightness.light
                      ? Colors.black
                      : Colors.white),
              shape: StadiumBorder(
                  side: BorderSide(
                      color: Colors.orange,
                      style: _selected == i
                          ? BorderStyle.solid
                          : BorderStyle.none)),
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
