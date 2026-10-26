// lib/Copyright/widgets/make_payment_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../Auth/AuthService.dart';
import '../../models/copyright_payment_model.dart';
import '../../services/copyright_payment_service.dart';

const String kReceiverPhone = '+8801874648472';

class MakePaymentSheet extends StatefulWidget {
  final String copyrightId;
  final double remainingAmount;
  final double totalFee;

  const MakePaymentSheet({
    super.key,
    required this.copyrightId,
    required this.remainingAmount,
    required this.totalFee,
  });

  @override
  State<MakePaymentSheet> createState() => _MakePaymentSheetState();
}

class _MakePaymentSheetState extends State<MakePaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _txnController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill amount with remaining
    _amountController.text = widget.remainingAmount.toStringAsFixed(0);
    // ⚠️ Name and phone are NOT auto-filled anymore
    // (AuthService.getUserName / getUserPhone don't exist)
    // User will enter them manually
  }

  @override
  void dispose() {
    _amountController.dispose();
    _txnController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final userId = await AuthService.getUserId() ?? '';
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;

    // Validation: amount not exceeding remaining
    if (amount > widget.remainingAmount + 0.01) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Amount exceeds remaining ৳ ${widget.remainingAmount.toStringAsFixed(0)}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final payment = CopyrightPaymentModel(
      senderUserId: userId,
      senderUserName: _nameController.text.trim(),
      senderPhoneNumber: _phoneController.text.trim(),
      receiverPhoneNumber: kReceiverPhone,
      transactionId: _txnController.text.trim(),
      copyrightId: widget.copyrightId,
      amount: amount,
      sendingTime: DateTime.now(),
    );

    final res = await CopyrightPaymentService.addPayment(
      userId: userId,
      payment: payment,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment recorded successfully'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Payment failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Grabber
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Make a Payment',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Send money to ${kReceiverPhone} and enter transaction ID below.',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 16),

                // Receiver info card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE65100).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.phone_android,
                            color: Color(0xFFE65100), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Receiver (bKash / Nagad)',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              kReceiverPhone,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(
                              const ClipboardData(text: kReceiverPhone));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Number copied')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Amount summary
                Row(
                  children: [
                    _miniStat(
                      label: 'Total',
                      value: '৳ ${widget.totalFee.toStringAsFixed(0)}',
                      color: Colors.black87,
                    ),
                    const SizedBox(width: 10),
                    _miniStat(
                      label: 'Remaining',
                      value: '৳ ${widget.remainingAmount.toStringAsFixed(0)}',
                      color: const Color(0xFFE65100),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Amount
                _label('Amount (৳)'),
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: _dec('Enter amount'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Amount required';
                    }
                    final n = double.tryParse(v.trim());
                    if (n == null || n <= 0) {
                      return 'Enter a valid amount';
                    }
                    if (n > widget.remainingAmount + 0.01) {
                      return 'Cannot exceed ৳ ${widget.remainingAmount.toStringAsFixed(0)}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Transaction ID
                _label('Transaction ID'),
                TextFormField(
                  controller: _txnController,
                  decoration: _dec('e.g. 8N7A2K9XYZ'),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Transaction ID required'
                          : null,
                ),
                const SizedBox(height: 12),

                // Sender name (manual input)
                _label('Your Name'),
                TextFormField(
                  controller: _nameController,
                  decoration: _dec('Enter your name'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Name required'
                          : null,
                ),
                const SizedBox(height: 12),

                // Sender phone (manual input)
                _label('Your Phone Number'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                  ],
                  decoration: _dec('01XXXXXXXXX'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Phone required';
                    }
                    final t = v.trim();
                    if (t.length < 11) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Submit
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3FBF),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Payment',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF1A3FBF), width: 1.5),
        ),
      );
}