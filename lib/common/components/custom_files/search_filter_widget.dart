import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

typedef ItemBuilder<T> = Widget Function(BuildContext context, T item);
typedef FilterFunction<T> = List<T> Function(List<T> items, String filter);
typedef DateExtractor<T> = DateTime? Function(T item);

class SearchFilterWidget<T> extends StatefulWidget {
  final List<T> items;
  final ItemBuilder<T> itemBuilder;
  final String hintText;
  final List<FilterOption<T>>? filterOptions;
  final Widget emptyStateWidget;
  final Widget? floatingActionButton;
  final FilterFunction<T>? customFilter;
  final Widget? header;
  final Widget? toggleButtons;
  final DateExtractor<T>? dateExtractor;

  const SearchFilterWidget({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.hintText,
    this.filterOptions,
    required this.emptyStateWidget,
    this.floatingActionButton,
    this.customFilter,
    this.header,
    this.toggleButtons,
    this.dateExtractor,
  });

  @override
  State<SearchFilterWidget<T>> createState() => _SearchFilterWidgetState<T>();
}

class _SearchFilterWidgetState<T> extends State<SearchFilterWidget<T>> {
  late List<T> _filteredItems;
  final TextEditingController _searchController = TextEditingController();
  String _currentFilter = 'None';
  FilterOption<T>? _selectedFilterOption;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
    _searchController.addListener(_filterItems);
    if (widget.filterOptions != null && widget.filterOptions!.isNotEmpty) {
      _selectedFilterOption = widget.filterOptions!.firstWhere(
        (option) => option.name == 'None',
        orElse: () => widget.filterOptions!.first,
      );
    }
  }

  @override
  void didUpdateWidget(covariant SearchFilterWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _filterItems();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      // Search filtering
      if (query.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems =
            widget.customFilter != null
                ? widget.customFilter!(widget.items, query)
                : widget.items
                    .where(
                      (item) => item.toString().toLowerCase().contains(query),
                    )
                    .toList();
      }

      // Apply selected filter option
      if (_selectedFilterOption != null &&
          _selectedFilterOption!.name != 'None') {
        _filteredItems = _selectedFilterOption!.filter(_filteredItems);
      }

      // Apply date range filter
      if (_selectedDateRange != null && widget.dateExtractor != null) {
        _filteredItems =
            _filteredItems.where((item) {
              final date = widget.dateExtractor!(item);
              if (date == null) return false;
              return !date.isBefore(_selectedDateRange!.start) &&
                  !date.isAfter(_selectedDateRange!.end);
            }).toList();
      }
    });
  }

  void _applyFilter(FilterOption<T> option) {
    setState(() {
      _selectedFilterOption = option;
      _currentFilter = option.name;
    });
    _filterItems();
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _filterItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.header != null) widget.header!,
        _buildSearchAndFilterRow(context),
        if (widget.toggleButtons != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: widget.toggleButtons!,
          ),
        if (_selectedFilterOption != null &&
            _selectedFilterOption!.name != 'None')
          _buildFilterIndicator(),
        if (_selectedDateRange != null) _buildDateIndicator(),
        Expanded(
          child:
              _filteredItems.isEmpty
                  ? widget.emptyStateWidget
                  : Stack(
                    children: [
                      ListView.builder(
                        itemCount: _filteredItems.length,
                        itemBuilder:
                            (context, index) => widget.itemBuilder(
                              context,
                              _filteredItems[index],
                            ),
                      ),
                      if (widget.floatingActionButton != null)
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: widget.floatingActionButton!,
                        ),
                    ],
                  ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.hintText,
                prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Colors.deepPurple,
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Colors.deepPurple,
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          if (widget.filterOptions != null &&
              widget.filterOptions!.isNotEmpty) ...[
            const SizedBox(width: 8),
            _buildFilterButton(context),
          ],
          if (widget.dateExtractor != null) ...[
            const SizedBox(width: 8),
            _buildDateButton(context),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    return _buildIconButton(
      icon: Icons.sort,
      onPressed: () => _showFilterOptions(context),
      tooltip: 'Filter',
    );
  }

  Widget _buildDateButton(BuildContext context) {
    return _buildIconButton(
      icon: Icons.date_range,
      onPressed: () => _pickDateRange(context),
      tooltip: 'Date Filter',
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        border: Border.all(color: Colors.deepPurple, width: 1.0),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.deepPurple),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildFilterIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Text(
            'Filter: $_currentFilter',
            style: const TextStyle(color: Colors.blue, fontSize: 12),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              final noneOption = widget.filterOptions!.firstWhere(
                (option) => option.name == 'None',
                orElse: () => widget.filterOptions!.first,
              );
              _applyFilter(noneOption);
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Text(
            'From: ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} '
            'To: ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}',
            style: const TextStyle(color: Colors.blue, fontSize: 12),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() => _selectedDateRange = null);
              _filterItems();
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterOptions(BuildContext context) async {
    if (widget.filterOptions == null || widget.filterOptions!.isEmpty) return;

    final result = await showModalBottomSheet<FilterOption<T>>(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Filter By',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...widget.filterOptions!.map((option) {
              return ListTile(
                leading: Icon(
                  option.icon,
                  color:
                      _selectedFilterOption == option
                          ? Colors.blue
                          : Colors.grey,
                ),
                title: Text(option.name),
                trailing:
                    _selectedFilterOption == option
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                onTap: () => Navigator.pop(context, option),
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      },
    );

    if (result != null) _applyFilter(result);
  }
}

class FilterOption<T> {
  final String name;
  final IconData icon;
  final List<T> Function(List<T>) filter;

  FilterOption({required this.name, required this.icon, required this.filter});
}
