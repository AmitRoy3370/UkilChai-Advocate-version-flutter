// lib/RJSC/widgets/rjsc_payment_section.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/rjsc_payment_model.dart';
import '../services/rjsc_payment_service.dart';

class RjscPaymentSection extends StatefulWidget {
  final String rjscId;
  final String senderUserId;
  final String senderUserName;
  final String senderPhoneNumber;
  final bool canPay;

  const RjscPaymentSection({
    super.key,
    required this.rjscId,
    required this.senderUserId,
    required this.senderUserName,
    required this.senderPhoneNumber,
    this.canPay = true,
  });

  @override
  State<RjscPaymentSection> createState() => _RjscPaymentSectionState();
}

class _RjscPaymentSectionState extends State<RjscPaymentSection> {
  // ============ Constants ============
  static const Color _primaryGreen = Color(0xFF0B5D36);
  static const Color _lightGreenBg = Color(0xFFECFDF5);
  static const Color _pendingAmber = Color(0xFFB45309);
  static const Color _pendingBg = Color(0xFFFFFBEB);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textGrey = Color(0xFF64748B);

  static const double TOTAL_AMOUNT = 5000.0;
  static const String RECEIVER_PHONE = '+8801874648472';
  static const double DEFAULT_PAY_AMOUNT = 5000.0;

  // ============ State ============
  bool _isLoading = true;
  String? _error;
  List<RjscPaymentModel> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  // ============ Load payments for this rjsc ============
  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await RjscPaymentService.findByRjscId(widget.rjscId);

      if (result['status'] == 'success') {
        final list = RjscPaymentService.parseList(result);
        setState(() {
          _payments = list;
          _isLoading = false;
        });
      } else {
        // No payments yet or error
        setState(() {
          _payments = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error: $e';
      });
    }
  }

  double get _totalPaid =>
      _payments.fold(0.0, (sum, p) => sum + p.amount);

  double get _remaining {
    final r = TOTAL_AMOUNT - _totalPaid;
    return r < 0 ? 0 : r;
  }

  bool get _isFullyPaid => _totalPaid >= TOTAL_AMOUNT;

  double get _progress {
    if (TOTAL_AMOUNT <= 0) return 0;
    final p = _totalPaid / TOTAL_AMOUNT;
    return p > 1 ? 1 : p;
  }

  // ============ Pay Dialog ============
  Future<void> _openPaymentDialog() async {
    final amountController = TextEditingController(
      text: _remaining.toStringAsFixed(0),
    );
    final trxController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: _lightGreenBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.payments_outlined,
                        color: _primaryGreen, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Make Payment',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Receiver info
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Send money to',
                            style: GoogleFonts.inter(
                                fontSize: 10, color: _textGrey),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            RECEIVER_PHONE,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Amount
                    Text(
                      'Amount (BDT)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        prefixText: '৳ ',
                        hintText: DEFAULT_PAY_AMOUNT.toStringAsFixed(0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Amount is required';
                        }
                        final n = double.tryParse(v.trim());
                        if (n == null || n <= 0) {
                          return 'Enter a valid amount';
                        }
                        if (n > _remaining) {
                          return 'Cannot exceed remaining ৳${_remaining.toStringAsFixed(0)}';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Transaction Id
                    Text(
                      'Transaction ID',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: trxController,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g. TXN123456789',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Transaction ID is required';
                        }
                        if (v.trim().length < 4) {
                          return 'Transaction ID is too short';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actionsPadding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 14),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogCtx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textGrey,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          setDialogState(() => isSubmitting = true);

                          final amount =
                              double.tryParse(amountController.text.trim()) ?? 0;
                          final trx = trxController.text.trim();

                          final payment = RjscPaymentModel(
                            senderUserId: widget.senderUserId,
                            senderUserName: widget.senderUserName,
                            senderPhoneNumber: widget.senderPhoneNumber,
                            transactionId: trx,
                            rjscId: widget.rjscId,
                            amount: amount,
                          );

                          final res = await RjscPaymentService.addPayment(
                            userId: widget.senderUserId,
                            payment: payment,
                          );

                          setDialogState(() => isSubmitting = false);

                          if (!mounted) return;

                          if (res['status'] == 'success') {
                            Navigator.pop(dialogCtx);
                            _showSnack('Payment recorded successfully');
                            await _loadPayments();
                          } else {
                            _showSnack(
                              res['message']?.toString() ??
                                  'Payment failed',
                              isError: true,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Pay Now',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : _primaryGreen,
      ),
    );
  }

  // ============ Build ============
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: _isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _primaryGreen),
                ),
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- Header ----
        Row(
          children: [
            const Icon(Icons.payments_outlined,
                color: _primaryGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              'Payment',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _isFullyPaid ? _lightGreenBg : _pendingBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isFullyPaid ? 'Fully Paid' : 'Payment Pending',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _isFullyPaid ? _primaryGreen : _pendingAmber,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ---- Receiver ----
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.phone_iphone,
                  size: 14, color: _textGrey),
              const SizedBox(width: 6),
              Text(
                'Send to: ',
                style: GoogleFonts.inter(
                    fontSize: 11, color: _textGrey),
              ),
              Expanded(
                child: Text(
                  RECEIVER_PHONE,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ---- Amounts ----
        Row(
          children: [
            Expanded(
              child: _amountCard(
                'Total',
                TOTAL_AMOUNT,
                const Color(0xFF0F172A),
                const Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _amountCard(
                'Paid',
                _totalPaid,
                _primaryGreen,
                _lightGreenBg,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _amountCard(
                'Remaining',
                _remaining,
                _isFullyPaid ? _primaryGreen : _pendingAmber,
                _isFullyPaid ? _lightGreenBg : _pendingBg,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ---- Progress Bar ----
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor:
                const AlwaysStoppedAnimation<Color>(_primaryGreen),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${(_progress * 100).toStringAsFixed(0)}% paid',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: _textGrey,
          ),
        ),

        // ---- Payment History ----
        if (_payments.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'Payment History (${_payments.length})',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _textGrey,
            ),
          ),
          const SizedBox(height: 8),
          ..._payments.map((p) => _paymentHistoryTile(p)),
        ],

        // ---- Pay Button (owner only) ----
        if (widget.canPay) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isFullyPaid ? null : _openPaymentDialog,
              icon: Icon(
                _isFullyPaid ? Icons.check_circle : Icons.payment,
                size: 18,
              ),
              label: Text(
                _isFullyPaid
                    ? 'Payment Completed'
                    : 'Pay ৳${_remaining.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ============ Amount Card ============
  Widget _amountCard(
      String label, double amount, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, color: _textGrey),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '৳${amount.toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ Payment History Tile ============
  Widget _paymentHistoryTile(RjscPaymentModel p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _lightGreenBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.receipt_long,
                  size: 16, color: _primaryGreen),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TXN: ${p.transactionId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                  ),
                  Text(
                    _formatDate(p.sendingTime),
                    style: GoogleFonts.inter(
                        fontSize: 10, color: _textGrey),
                  ),
                ],
              ),
            ),
            Text(
              '৳${p.amount.toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }
}