import 'package:flutter/material.dart';

import '../services/prefs.dart';

class FilterChipBlock extends StatefulWidget {
  final String labelText;
  final List<Object> objects;
  final String Function(int i) objectToName;
  final bool Function(int i) enabled;
  final bool showCounter;
  final ValueSetter<int> onSelected;

  const FilterChipBlock({
    Key key,
    this.labelText,
    @required this.objects,
    @required this.objectToName,
    this.enabled,
    this.showCounter: false,
    this.onSelected,
  })  : assert(objects != null),
        super(key: key);

  @override
  _FilterChipBlockState createState() => _FilterChipBlockState();
}

class _FilterChipBlockState extends State<FilterChipBlock> {
  @override
  Widget build(BuildContext context) {
    List<String> selection = List.castFrom(PrefsModel.of(
      context,
      aspect: widget.labelText,
      defaultValue: <String>[],
    ));
    if (widget.objects.isEmpty) {
      return Container();
    }
    bool Function(int i) enabled = widget.enabled ?? (i) => true;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: widget.labelText,
        counterText: widget.showCounter
            ? '${selection.length}/${widget.objects.length}'
            : null,
        border: OutlineInputBorder(),
      ),
      child: Wrap(
        spacing: 8.0,
        children: List.generate(
          widget.objects.length,
          (i) {
            String objectId = widget.objects[i].toString();
            //TODO: implement geofence
            /*if (selection.contains(objectId) && !enabled(i)) {
              PrefsManager.of(
                context,
              ).set(
                widget.labelText,
                List.of(selection)..remove(objectId),
              );
            }*/
            return FilterChip(
              label: Text(widget.objectToName(i)),
              selected: selection.contains(objectId),
              onSelected: enabled(i) ? (b) {
                List<String> newSelection = List.of(selection);
                if (b) {
                  newSelection.add(objectId);
                } else {
                  newSelection.remove(objectId);
                }
                PrefsManager.of(
                  context,
                ).set(
                  widget.labelText,
                  newSelection,
                );
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
