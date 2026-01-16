import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for TextInputFormatter
import 'package:offline_billing/common/components/colors/colors.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class TitleCaseTextFormatter extends TextInputFormatter {
  String toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map(
          (word) =>
              word.isEmpty
                  ? ''
                  : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final titleCased = toTitleCase(newValue.text);
    return TextEditingValue(text: titleCased, selection: newValue.selection);
  }
}

Future<String?> showOptionSelectorBottomSheet({
  required BuildContext context,
  required String title,
  required List<String> initialOptions,
  String? selectedOption,
  bool enableDelete = false,
  bool enableCustomAdd = true,
  bool enableSearch = true,
}) async {
  List<String> options = List.from(initialOptions);
  List<String> filteredOptions = List.from(options);
  String? tempSelectedOption = selectedOption;

  TextEditingController searchController = TextEditingController();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController shortNameController = TextEditingController();

  return await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.88,
        child: StatefulBuilder(
          builder: (context, setModalState) {
            void filterOptions(String query) {
              setModalState(() {
                filteredOptions =
                    options
                        .where(
                          (option) => option.toLowerCase().contains(
                            query.toLowerCase(),
                          ),
                        )
                        .toList();
              });
            }

            void addCustomOption() {
              final fullName = fullNameController.text.trim();
              final shortName = shortNameController.text.trim();

              if (fullName.isNotEmpty &&
                  (title == 'Unit' ? shortName.isNotEmpty : true)) {
                final newOption =
                    title == 'Unit' ? '$fullName ($shortName)' : fullName;

                if (!options.contains(newOption)) {
                  setModalState(() {
                    options.insert(0, newOption);
                    filterOptions(searchController.text);
                    tempSelectedOption = newOption;
                    fullNameController.clear();
                    shortNameController.clear();
                  });
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                children: [
                  // 🔺 Title and Close Icon
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 🔍 Search Bar
                  if (enableSearch) ...[
                    TextField(
                      controller: searchController,
                      onChanged: filterOptions,
                      decoration: InputDecoration(
                        hintText: "Search $title",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // 📋 List of Options
                  Expanded(
                    child:
                        filteredOptions.isEmpty
                            ? const Center(child: Text("No results found."))
                            : ListView.builder(
                              itemCount: filteredOptions.length,
                              itemBuilder: (context, index) {
                                final option = filteredOptions[index];
                                return InkWell(
                                  onTap: () {
                                    setModalState(() {
                                      tempSelectedOption = option;
                                    });
                                  },
                                  child: ListTile(
                                    title: Text(option),
                                    leading: Radio<String>(
                                      value: option,
                                      groupValue: tempSelectedOption,
                                      onChanged: (value) {
                                        setModalState(() {
                                          tempSelectedOption = value;
                                        });
                                      },
                                    ),
                                    trailing:
                                        enableDelete
                                            ? IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              onPressed: () {
                                                Navigator.pop(
                                                  context,
                                                  "DELETE:$option",
                                                );
                                              },
                                            )
                                            : null,
                                  ),
                                );
                              },
                            ),
                  ),

                  const SizedBox(height: 10),

                  // ➕ Add Custom Option
                  if (enableCustomAdd)
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: fullNameController,
                              inputFormatters: [TitleCaseTextFormatter()],
                              decoration: InputDecoration(
                                hintText: "Full name",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (title == 'Unit') ...[
                            Expanded(
                              child: TextField(
                                controller: shortNameController,
                                inputFormatters: [UpperCaseTextFormatter()],
                                decoration: InputDecoration(
                                  hintText: "Shortname",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          ElevatedButton(
                            onPressed: addCustomOption,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              fixedSize: const Size(55, 55),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 10),

                  // ✅ Confirm Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, tempSelectedOption);
                    },
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(330, 50),
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "CONFIRM",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
