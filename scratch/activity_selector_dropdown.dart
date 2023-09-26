
  // Widget _activitySelector(BuildContext context) {
  //   List<String> activityNames = _activities.map((a) => a.name).toSet().toList();
  //   // print("chat: _activitySelector: activityNames: $activityNames");
  //   // print("chat: _activitySelector: _activity: ${_activity?.title}");
  //   return DropdownButton<String>(
  //     value: _activity?.name,
  //     icon: const Icon(Icons.arrow_downward),
  //     iconSize: 24,
  //     elevation: 16,
  //     style: Theme.of(context).textTheme.headlineSmall,
  //     underline: Container(
  //       height: 2,
  //       color: Theme.of(context).colorScheme.onSurface,
  //     ),
  //     onChanged: (String? newValue) {
  //       // print("chat: _activitySelector: onChanged: newValue: $newValue");
  //       // print("chat: _activitySelector: onChanged: _activities: ${_activities.map((a) => a.name).toList()}");
  //       // print("chat: _activitySelector: onChanged: _activity: ${_activity?.title}");
  //       setState(() {
  //         _activity = _activities.firstWhere((a) => a.name == newValue);
  //       });
  //     },
  //     items: activityNames.map<DropdownMenuItem<String>>((String value) {
  //       return DropdownMenuItem<String>(
  //         value: value,
  //         child: Text(value, style: Theme.of(context).textTheme.headlineSmall),
  //       );
  //     }).toList(),
  //   );
  // }
