// lib/vat/screens/vat_payment_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/vat_response_model.dart';
import '../models/vat_payment_model.dart';
import '../service/vat_payment_service.dart';

class VatPaymentPage extends StatefulWidget {
  final VatResponseModel vat;
  final String? currentUserId;

  /// ✅ When true (default), the "Add Payment" flow is available.
  /// When false (e.g. center admin viewing), only the summary +
  /// history are shown — no pay button / add form.
  final bool canPay;

  const VatPaymentPage({
    super.key,
    required this.vat,
    required this.currentUserId,
    this.canPay = true,
  });

  @override
  State<VatPaymentPage> createState() => _VatPaymentPageState();
}

class _VatPaymentPageState extends State<VatPaymentPage> {
  static const double _totalPrice = 5000.0;

  // ✅ Fixed receiver number (matches backend `VatPayment.receiverPhoneNumber`)
  static const String _receiverPhone = '+8801874648472';

  bool _loading = true;
  String? _error;
  List<VatPaymentModel> _payments = [];
  bool _addMode = false;

  // ---- Add form ----
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _transactionIdCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _method = 'bKash';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _transactionIdCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  // ============ LOAD PAYMENTS ============
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (widget.vat.id == null || widget.vat.id!.isEmpty) {
        throw Exception('Invalid VAT');
      }
      final list = await VatPaymentService.findByVatId(widget.vat.id!);

      if (!mounted) return;
      setState(() {
        _payments = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('No such payment') ||
          msg.contains('NoSuchElementException')) {
        setState(() {
          _payments = [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = msg.replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  double get _paidAmount =>
      _payments.fold(0.0, (sum, p) => sum + p.amount);

  double get _remainingAmount {
    final r = _totalPrice - _paidAmount;
    return r < 0 ? 0 : r;
  }

  // ============ COPY RECEIVER PHONE ============
  Future<void> _copyReceiverNumber() async {
    await Clipboard.setData(const ClipboardData(text: _receiverPhone));
    _snack('Receiver number copied');
  }

  // ============ SUBMIT PAYMENT ============
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.currentUserId == null || widget.currentUserId!.isEmpty) {
      _snack('User not logged in', true);
      return;
    }

    setState(() => _submitting = true);

    try {
      final senderName = widget.vat.userName.isEmpty
          ? 'User'
          : widget.vat.userName;

      final payment = VatPaymentModel(
        senderUserId: widget.currentUserId!,
        senderUserName: senderName,
        senderPhoneNumber: _phoneCtrl.text.trim(),
        receiverPhoneNumber: _receiverPhone,
        amount: double.parse(_amountCtrl.text.trim()),
        transactionId: _transactionIdCtrl.text.trim(),
        sendingTime: DateTime.now().toUtc(),
        vatId: widget.vat.id!,
      );

      await VatPaymentService.addPayment(
        payment: payment,
        userId: widget.currentUserId!,
      );

      _snack('Payment added successfully');
      _phoneCtrl.clear();
      _transactionIdCtrl.clear();
      _amountCtrl.clear();
      setState(() => _addMode = false);
      await _load();
    } catch (e) {
      _snack('Failed: $e', true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, [bool isError = false]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  // ============ BUILD ============
  @override
  Widget build(BuildContext context) {
    // Never show the add form if not allowed
    final showAddForm = widget.canPay && _addMode;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          showAddForm ? 'New Payment' : 'VAT Payments',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          // ✅ "+" icon — only when canPay and not already in add mode
          if (widget.canPay && !_addMode && !_loading && _error == null)
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF1565C0)),
              tooltip: 'Add Payment',
              onPressed: () => setState(() => _addMode = true),
            ),

          // ✅ Close (cancel add) icon — only when in add mode
          if (showAddForm)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black87),
              tooltip: 'Cancel',
              onPressed: () => setState(() => _addMode = false),
            ),
        ],
      ),
      body: showAddForm ? _buildAddForm() : _buildPaymentView(),
    );
  }

  // ============ Payment Overview + History ============
  Widget _buildPaymentView() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1565C0)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 56, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF1565C0),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Summary card ----
          _summaryCard(),
          const SizedBox(height: 12),

          // ✅ Receiver number card
          _receiverCard(),
          const SizedBox(height: 16),

          // ---- Add payment CTA (owner only) ----
          if (widget.canPay) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _addMode = true),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Send New Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ] else
            const SizedBox(height: 8),

          // ---- History ----
          Row(
            children: [
              const Icon(Icons.history,
                  size: 18, color: Color(0xFF1565C0)),
              const SizedBox(width: 6),
              Text(
                'Payment History',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '${_payments.length} record${_payments.length == 1 ? '' : 's'}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_payments.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.receipt_long,
                      size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  Text(
                    'No payments yet',
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._payments.map(_paymentCard),
        ],
      ),
    );
  }

  // ============ Receiver Number Card ============
  Widget _receiverCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF1565C0).withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Color(0xFF1565C0),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send money to',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _receiverPhone,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy,
                color: Color(0xFF1565C0), size: 20),
            tooltip: 'Copy number',
            onPressed: _copyReceiverNumber,
          ),
        ],
      ),
    );
  }

  // ============ Summary Card ============
  Widget _summaryCard() {
    final progress = _paidAmount / _totalPrice;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1565C0),
            const Color(0xFF1565C0).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Summary',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
          const SizedBox(height: 14),

          _moneyRow(
              'Total Amount', _totalPrice, Colors.white.withOpacity(0.95)),
          const SizedBox(height: 8),
          _moneyRow('Paid', _paidAmount, Colors.green.shade200),
          const SizedBox(height: 8),
          _moneyRow(
            'Remaining',
            _remainingAmount,
            _remainingAmount <= 0
                ? Colors.green.shade200
                : Colors.orange.shade200,
          ),

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(
                _remainingAmount <= 0
                    ? Colors.green.shade300
                    : Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _remainingAmount <= 0
                ? '✓ Fully paid'
                : '${(progress * 100).toStringAsFixed(0)}% completed',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moneyRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withOpacity(0.85),
          ),
        ),
        Text(
          '৳ ${value.toStringAsFixed(0)}',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ============ Payment Card ============
  Widget _paymentCard(VatPaymentModel p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.check_circle,
                    color: Colors.green.shade700, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '৳ ${p.amount.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (p.sendingTime != null)
                      Text(
                        _formatDate(p.sendingTime!),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          _row('Transaction ID', p.transactionId),
          _row('Sender Phone', p.senderPhoneNumber),
          _row('Sender', p.senderUserName),
          _row(
            'Receiver Phone',
            p.receiverPhoneNumber.isEmpty
                ? _receiverPhone
                : p.receiverPhoneNumber,
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              k,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v.isEmpty ? '-' : v,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}  '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  // ============ Add Form ============
  Widget _buildAddForm() {
    final remaining = _remainingAmount;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Remaining banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: remaining <= 0
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: remaining <= 0
                    ? Colors.green.shade200
                    : Colors.orange.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  remaining <= 0
                      ? Icons.check_circle
                      : Icons.info_outline,
                  color: remaining <= 0
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        remaining <= 0
                            ? 'Already fully paid'
                            : 'Remaining Amount',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        '৳ ${remaining.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: remaining <= 0
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ✅ Receiver number banner (prominent, before picking method)
          _receiverCard(),
          const SizedBox(height: 16),

          // Method
          _label('Payment Method'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                _methodTile('bKash', Icons.account_balance_wallet,
                    Colors.pink.shade400),
                _methodTile('Rocket', Icons.rocket_launch,
                    Colors.purple.shade400),
                _methodTile('Card / Other', Icons.credit_card,
                    Colors.blue.shade400),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Sender phone
          _label('Sender Phone Number'),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
            decoration: _inputDeco('e.g., 01712345678'),
          ),
          const SizedBox(height: 16),

          // Amount
          _label('Amount'),
          TextFormField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              final n = double.tryParse(v.trim());
              if (n == null || n <= 0) return 'Invalid amount';
              if (n > remaining) {
                return 'Cannot exceed ৳${remaining.toStringAsFixed(0)}';
              }
              return null;
            },
            decoration: _inputDeco('e.g., 1000'),
          ),
          const SizedBox(height: 16),

          // Transaction ID
          _label('Transaction ID'),
          TextFormField(
            controller: _transactionIdCtrl,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
            decoration: _inputDeco('e.g., TXN123456789'),
          ),
          const SizedBox(height: 24),

          // Submit
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Pay Now',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Total: ৳ 5,000 · Paid: ৳ ${_paidAmount.toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodTile(String name, IconData icon, Color color) {
    final selected = _method == name;
    return InkWell(
      onTap: () => setState(() => _method = name),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Radio<String>(
              value: name,
              groupValue: _method,
              activeColor: const Color(0xFF1565C0),
              onChanged: (v) => setState(() => _method = v ?? _method),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        t,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.white,
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
            const BorderSide(color: Color(0xFF1565C0), width: 1.5),
      ),
    );
  }
}