import 'package:flutter/material.dart';

import '../services/prefs.dart';

class FilterChipBlock extends StatefulWidget {
  final String labelText;
  final List<Object> objects;
  final String Function(dynamic t) objectToName;
  final bool showCounter;
  final ValueSetter<int> onSelected;

  const FilterChipBlock({
    Key key,
    this.labelText,
    @required this.objects,
    @required this.objectToName,
    this.showCounter = false,
    this.onSelected,
  })  : assert(objects != null),
        super(key: key);

  @override
  _FilterChipBlockState createState() => _FilterChipBlockState();
}

class _FilterChipBlockState extends State<FilterChipBlock> {
  Map<Object, bool> _selected = Map();
  int _selectedCount = 0;

  @override
  Widget build(BuildContext context) {
    if (_selected.length != widget.objects.length) {
      _selected.removeWhere((key, _) {
        return !widget.objects.contains(key);
      });
      widget.objects.forEach((o) {
        if (!_selected.containsKey(o)) {
          _selected[o] = false;
        }
      });
    }
    if (widget.objects.isEmpty) return Container();
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
          widget.objects.length,
          (i) => FilterChip(
                label: Text(widget.objectToName(widget.objects[i])),
                selected: _selected[widget.objects[i]],
                onSelected: (b) {
                  _selected[widget.objects[i]] = b;
                  _selectedCount += b ? 1 : -1;
                  PrefsManager.of(context).set(
                    widget.labelText,
                    _selected.entries
                        .where((e) => e.value)
                        .map((e) => e.key.toString())
                        .toList(),
                  );
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
