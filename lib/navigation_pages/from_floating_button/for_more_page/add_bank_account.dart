import 'package:flutter/material.dart';
import 'package:offline_billing/common/components/colors/colors.dart';
import 'package:offline_billing/common/components/custom_files/NumberOnlyFormatter.dart';
import 'package:offline_billing/common/components/custom_files/custom_text_field.dart';

class AddBankAccountPage extends StatefulWidget {
  const AddBankAccountPage({Key? key}) : super(key: key);

  @override
  State<AddBankAccountPage> createState() => _AddBankAccountPageState();
}

class _AddBankAccountPageState extends State<AddBankAccountPage> {
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController holderNameController = TextEditingController();
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController ifscController = TextEditingController();
  final TextEditingController branchNameController = TextEditingController();
  final TextEditingController upiController = TextEditingController();
  final TextEditingController openingBalanceController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget sizedBox20() => const SizedBox(height: 20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text(
          "Add Bank Account",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, size: 30, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                labelText: 'Bank Name',
                controller: bankNameController,
              ),
              sizedBox20(),
              CustomTextField(
                labelText: 'Account Holder Name',
                controller: holderNameController,
              ),
              sizedBox20(),
              CustomTextField(
                labelText: 'Account Number',
                controller: accountNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  NumberOnlyFormatter(context, onError: _showSnackBar),
                ],
              ),
              sizedBox20(),
              CustomTextField(
                labelText: 'IFSC Code',
                controller: ifscController,
              ),
              sizedBox20(),
              CustomTextField(
                labelText: 'Branch Name',
                controller: branchNameController,
              ),
              sizedBox20(),
              CustomTextField(
                labelText: 'UPI ID',
                controller: upiController,
                keyboardType: TextInputType.emailAddress,
              ),
              sizedBox20(),
              CustomTextField(
                labelText: 'Opening Balance',
                controller: openingBalanceController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  NumberOnlyFormatter(context, onError: _showSnackBar),
                ],
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            fixedSize: const Size(350, 50),
            backgroundColor: primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            "SAVE",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
