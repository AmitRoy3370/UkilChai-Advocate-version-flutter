import 'package:flutter/material.dart';
import './appeal_hearing_service.dart';

class ScheduleAppealHearingPage extends StatefulWidget {
  final String token;
  final String hearingId;
  final String userId;
  final bool needUpdate;

  const ScheduleAppealHearingPage({
    super.key,
    required this.token,
    required this.hearingId,
    required this.userId,
    required this.needUpdate,
  });

  @override
  State<ScheduleAppealHearingPage> createState() =>
      _ScheduleAppealHearingPageState();
}

class _ScheduleAppealHearingPageState extends State<ScheduleAppealHearingPage> {
  final TextEditingController reasonController = TextEditingController();

  DateTime? selectedDate;

  bool loading = false;

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (reasonController.text.isEmpty) return;

    setState(() => loading = true);

    String? appealHearingId;

    if (widget.needUpdate) {
      final res = await AppealHearingService.getByHearing(
        widget.token,
        widget.hearingId,
      );

      if (res != null) {
        appealHearingId = res.id;
      }
    }

    final res = !widget.needUpdate
        ? await AppealHearingService.addAppeal(
            token: widget.token,
            userId: widget.userId,
            hearingId: widget.hearingId,
            reason: reasonController.text,
          )
        : await AppealHearingService.updateAppeal(
            token: widget.token,
            appealId: appealHearingId.toString(),
            userId: widget.userId,
            hearingId: widget.hearingId,
            reason: reasonController.text,
          );

    setState(() => loading = false);

    if (res.statusCode == 200 || res.statusCode == 201) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${res.body} for the user :- ${widget.userId}")),
      );
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    if (widget.needUpdate) {
      collectPastReason();
    }
  }

  Future<void> collectPastReason() async {
    final res = await AppealHearingService.getByHearing(
      widget.token,
      widget.hearingId,
    );

    if (res != null) {
      reasonController.text = res.reason;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Schedule Appeal Hearing")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: "Reason",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: loading ? null : _submit,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Submit Appeal"),
            ),
          ],
        ),
      ),
    );
  }
}
