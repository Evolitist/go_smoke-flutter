import 'package:flutter/material.dart';

class FilterChipBlock extends StatefulWidget {
  final String labelText;
  final List<String> names;
  final List<bool> states;
  final bool Function(int i) enabled;
  final bool showCounter;
  final ValueSetter<int> onSelected;

  const FilterChipBlock({
    Key key,
    this.labelText,
    @required this.names,
    @required this.states,
    this.enabled,
    this.showCounter: false,
    this.onSelected,
  })  : assert(names != null),
        super(key: key);

  @override
  _FilterChipBlockState createState() => _FilterChipBlockState();
}

class _FilterChipBlockState extends State<FilterChipBlock> {
  @override
  Widget build(BuildContext context) {
    if (widget.names.isEmpty) {
      return Container();
    }
    bool Function(int i) enabled = widget.enabled ?? (i) => true;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: widget.labelText,
        counterText: widget.showCounter
            ? '${widget.states.where((b) => b).length}/${widget.names.length}'
            : null,
        border: OutlineInputBorder(),
      ),
      child: Wrap(
        spacing: 8.0,
        children: List.generate(
          widget.names.length,
          (i) {
            //TODO: implement geofence
            return FilterChip(
              label: Text(widget.names[i]),
              selected: widget.states[i],
              onSelected: enabled(i) ? (b) {
                if (widget.onSelected != null) {
                  widget.onSelected(i);
                }
              } : null,
            );
          },
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
        children: List.generate(
          widget.names.length,
          (i) {
            ThemeData theme = Theme.of(context);
            return ChoiceChip(
              label: Text(widget.names[i]),
              selected: _selected == i,
              selectedColor: Colors.orange.withOpacity(0.24),
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
