// lib/Copyright/screens/widgets/copyright_payment_section.dart

import 'package:flutter/material.dart';
import '../../../Auth/AuthService.dart';
import '../../models/copyright_payment_model.dart';
import '../../services/copyright_payment_service.dart';
import '../../screens/widgets/make_payment_sheet.dart';

/// Fixed total fee for copyright registration
const double kCopyrightTotalFee = 5000.0;

class CopyrightPaymentSection extends StatefulWidget {
  final String copyrightId;
  final bool isOwner;
  final VoidCallback? onPaymentAdded;

  const CopyrightPaymentSection({
    super.key,
    required this.copyrightId,
    required this.isOwner,
    this.onPaymentAdded,
  });

  @override
  State<CopyrightPaymentSection> createState() =>
      _CopyrightPaymentSectionState();
}

class _CopyrightPaymentSectionState extends State<CopyrightPaymentSection> {
  List<CopyrightPaymentModel> _payments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result =
        await CopyrightPaymentService.findByCopyrightId(widget.copyrightId);

    if (!mounted) return;

    if (result['status'] == 'success') {
      final list = CopyrightPaymentService.parseList(result);
      setState(() {
        _payments = list;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = result['message'] ?? 'Failed to load payments';
      });
    }
  }

  double get _totalPaid =>
      _payments.fold(0.0, (sum, p) => sum + p.amount);

  double get _remaining {
    final r = kCopyrightTotalFee - _totalPaid;
    return r < 0 ? 0 : r;
  }

  bool get _isFullyPaid => _remaining <= 0;

  double get _progress {
    if (kCopyrightTotalFee == 0) return 0;
    final p = _totalPaid / kCopyrightTotalFee;
    return p > 1 ? 1 : p;
  }

  Future<void> _openMakePayment() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MakePaymentSheet(
        copyrightId: widget.copyrightId,
        remainingAmount: _remaining,
        totalFee: kCopyrightTotalFee,
      ),
    );

    if (added == true) {
      await _loadPayments();
      widget.onPaymentAdded?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------- Header ----------
          Row(
            children: [
              const Icon(Icons.payments_outlined,
                  size: 20, color: Color(0xFF1A3FBF)),
              const SizedBox(width: 8),
              const Text(
                'Payment',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3FBF),
                ),
              ),
              const Spacer(),
              if (_isFullyPaid)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 12, color: Color(0xFF2E7D32)),
                      SizedBox(width: 4),
                      Text(
                        'Paid',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_empty,
                          size: 12, color: Color(0xFFE65100)),
                      SizedBox(width: 4),
                      Text(
                        'Due',
                        style: TextStyle(
                          color: Color(0xFFE65100),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ---------- Amount summary ----------
          _amountSummary(),

          const SizedBox(height: 16),

          // ---------- Progress bar ----------
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                _isFullyPaid
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF1A3FBF),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${(_progress * 100).toStringAsFixed(0)}% paid',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade600),
              ),
              const Spacer(),
              if (!_isFullyPaid)
                Text(
                  '৳ ${_remaining.toStringAsFixed(0)} remaining',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFE65100),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // ---------- Payment history ----------
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_error != null)
            _errorWidget()
          else if (_payments.isEmpty)
            _emptyHistory()
          else
            _historyList(),

          // ---------- Add payment button ----------
          if (widget.isOwner && !_isFullyPaid) ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _openMakePayment,
              icon: const Icon(Icons.add_card, size: 18),
              label: const Text('Make Payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3FBF),
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // WIDGETS
  // ============================================================

  Widget _amountSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _summaryRow(
            'Total Fee',
            '৳ ${kCopyrightTotalFee.toStringAsFixed(0)}',
            color: Colors.black87,
          ),
          const SizedBox(height: 6),
          _summaryRow(
            'Paid',
            '৳ ${_totalPaid.toStringAsFixed(0)}',
            color: const Color(0xFF2E7D32),
          ),
          const Divider(height: 18),
          _summaryRow(
            'Remaining',
            '৳ ${_remaining.toStringAsFixed(0)}',
            color: _isFullyPaid
                ? const Color(0xFF2E7D32)
                : const Color(0xFFE65100),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    required Color color,
    bool bold = false,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: bold ? 15 : 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _emptyHistory() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 32, color: Colors.grey.shade400),
          const SizedBox(height: 6),
          Text(
            'No payments made yet',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _errorWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            _error ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.redAccent),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadPayments,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _historyList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment History (${_payments.length})',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        ..._payments.map((p) => _paymentTile(p)),
      ],
    );
  }

  Widget _paymentTile(CopyrightPaymentModel p) {
    final date = p.sendingTime;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check,
                size: 18, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '৳ ${p.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Txn: ${p.transactionId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}