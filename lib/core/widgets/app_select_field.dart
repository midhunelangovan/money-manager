import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppSelectItem<T> {
  final T value;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? iconWidget;
  final Color? iconColor;
  final String? badge;
  final Color? badgeColor;

  const AppSelectItem({
    required this.value,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconWidget,
    this.iconColor,
    this.badge,
    this.badgeColor,
  });
}

class AppSelectField<T> extends StatelessWidget {
  final String? label;
  final String hint;
  final T? value;
  final List<AppSelectItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? title;
  final bool? searchable;
  final Widget? leading;
  final Widget? trailingAction;
  final bool enabled;

  const AppSelectField({
    super.key,
    this.label,
    this.hint = 'Select an option',
    required this.value,
    required this.items,
    this.onChanged,
    this.title,
    this.searchable,
    this.leading,
    this.trailingAction,
    this.enabled = true,
  });

  AppSelectItem<T>? get _selectedItem {
    if (value == null) return null;
    for (final item in items) {
      if (item.value == value) return item;
    }
    return null;
  }

  void _openPicker(BuildContext context) async {
    if (!enabled || onChanged == null) return;

    final selected = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AppSelectModal<T>(
        title: title ?? (label != null ? 'Select $label' : 'Select Option'),
        items: items,
        selectedValue: value,
        searchable: searchable ?? (items.length > 5),
        trailingAction: trailingAction,
      ),
    );

    if (selected != null && onChanged != null) {
      onChanged!(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _selectedItem;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
        ],
        InkWell(
          onTap: enabled ? () => _openPicker(context) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 10),
                ] else if (selected?.iconWidget != null) ...[
                  selected!.iconWidget!,
                  const SizedBox(width: 10),
                ] else if (selected?.icon != null) ...[
                  Icon(
                    selected!.icon,
                    size: 20,
                    color: selected.iconColor ?? (isDark ? Theme.of(context).colorScheme.primary : AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: selected != null
                      ? Row(
                          children: [
                            Flexible(
                              child: Text(
                                selected.title,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (selected.badge != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (selected.badgeColor ?? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  selected.badge!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: selected.badgeColor ?? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        )
                      : Text(
                          hint,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w400,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AppSelectModal<T> extends StatefulWidget {
  final String title;
  final List<AppSelectItem<T>> items;
  final T? selectedValue;
  final bool searchable;
  final Widget? trailingAction;

  const _AppSelectModal({
    required this.title,
    required this.items,
    required this.selectedValue,
    required this.searchable,
    this.trailingAction,
  });

  @override
  State<_AppSelectModal<T>> createState() => _AppSelectModalState<T>();
}

class _AppSelectModalState<T> extends State<_AppSelectModal<T>> {
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppSelectItem<T>> get _filteredItems {
    if (_searchQuery.trim().isEmpty) return widget.items;
    final query = _searchQuery.trim().toLowerCase();
    return widget.items.where((item) {
      final matchTitle = item.title.toLowerCase().contains(query);
      final matchSub = item.subtitle?.toLowerCase().contains(query) ?? false;
      return matchTitle || matchSub;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filtered = _filteredItems;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: isDark ? const Border(top: BorderSide(color: AppColors.darkBorderSubtle)) : null,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  if (widget.trailingAction != null) widget.trailingAction!,
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),

            // Search box
            if (widget.searchable) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: isDark ? Border.all(color: AppColors.darkBorderSubtle) : null,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, size: 18, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: false,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            hintStyle: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: Icon(Icons.clear_rounded, size: 18, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],

            Divider(height: 1, color: isDark ? AppColors.darkBorderSubtle : null),

            // Items List
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No matching items found',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => Divider(height: 1, indent: 48, color: isDark ? AppColors.darkBorderSubtle : null),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isSelected = item.value == widget.selectedValue;

                        return ListTile(
                          onTap: () => Navigator.pop(context, item.value),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          leading: item.iconWidget ??
                              (item.icon != null
                                  ? Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: (item.iconColor ?? (isDark ? theme.colorScheme.primary : AppColors.primary)).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        item.icon,
                                        size: 20,
                                        color: item.iconColor ?? (isDark ? theme.colorScheme.primary : AppColors.primary),
                                      ),
                                    )
                                  : null),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? (isDark ? theme.colorScheme.primary : AppColors.primary)
                                        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (item.badge != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (item.badgeColor ?? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.badge!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: item.badgeColor ?? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: item.subtitle != null
                              ? Text(
                                  item.subtitle!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                )
                              : null,
                          trailing: isSelected
                              ? Icon(Icons.check_circle_rounded, color: isDark ? theme.colorScheme.primary : AppColors.primary, size: 22)
                              : Icon(
                                  Icons.radio_button_unchecked_rounded,
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  size: 22,
                                ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
