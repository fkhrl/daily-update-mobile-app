import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class _MedicineFormItem {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController durationCtrl = TextEditingController();
  final TextEditingController intervalCtrl = TextEditingController();
  TimeOfDay? morning;
  TimeOfDay? afternoon;
  TimeOfDay? night;

  void dispose() {
    nameCtrl.dispose();
    durationCtrl.dispose();
    intervalCtrl.dispose();
  }
}

class AddMedicineDialog extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onAddMedicines;

  const AddMedicineDialog({super.key, required this.onAddMedicines});

  @override
  State<AddMedicineDialog> createState() => _AddMedicineDialogState();
}

class _AddMedicineDialogState extends State<AddMedicineDialog> {
  final List<_MedicineFormItem> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _items.add(_MedicineFormItem());
  }

  @override
  void dispose() {
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addMore() {
    setState(() {
      _items.add(_MedicineFormItem());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _submit() async {
    List<Map<String, dynamic>> medicinesData = [];

    String formatTime(TimeOfDay? t) {
      if (t == null) return '';
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    for (var item in _items) {
      final name = item.nameCtrl.text.trim();
      if (name.isEmpty) continue;

      String? m = item.morning != null ? formatTime(item.morning) : null;
      String? a = item.afternoon != null ? formatTime(item.afternoon) : null;
      String? n = item.night != null ? formatTime(item.night) : null;
      int? durationDays = int.tryParse(item.durationCtrl.text.trim());
      int? intervalDays = int.tryParse(item.intervalCtrl.text.trim());

      medicinesData.add({
        'name': name,
        'morning_time': m,
        'afternoon_time': a,
        'night_time': n,
        if (durationDays != null) 'duration_days': durationDays,
        if (intervalDays != null) 'interval_days': intervalDays,
      });
    }

    if (medicinesData.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onAddMedicines(medicinesData);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Add Medicine', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 15),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white24, height: 40),
              itemBuilder: (context, index) {
                final item = _items[index];
                return _buildFormItem(item, index);
              },
            ),
          ),
          const SizedBox(height: 20),
          if (_items.length < 10) // arbitrary limit to prevent infinite
            TextButton.icon(
              onPressed: _addMore,
              icon: const Icon(Icons.add, color: Colors.indigoAccent),
              label: const Text('Add Another Medicine', style: TextStyle(color: Colors.indigoAccent)),
            ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, minimumSize: const Size(double.infinity, 50)),
            child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save All Medicines'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFormItem(_MedicineFormItem item, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_items.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Medicine #${index + 1}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20), onPressed: () => _removeItem(index)),
            ],
          ),
        const SizedBox(height: 10),
        TextField(
          controller: item.nameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Medicine Name',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF0F172A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: item.durationCtrl,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Duration (Days)',
                  hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: item.intervalCtrl,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Interval (e.g. 21 Days)',
                  hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Morning Time', style: TextStyle(color: Colors.white, fontSize: 14)),
          trailing: Text(item.morning?.format(context) ?? 'Not Set', style: const TextStyle(color: Colors.indigoAccent)),
          onTap: () async {
            final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
            if (t != null) setState(() => item.morning = t);
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Afternoon Time', style: TextStyle(color: Colors.white, fontSize: 14)),
          trailing: Text(item.afternoon?.format(context) ?? 'Not Set', style: const TextStyle(color: Colors.indigoAccent)),
          onTap: () async {
            final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 14, minute: 0));
            if (t != null) setState(() => item.afternoon = t);
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Night Time', style: TextStyle(color: Colors.white, fontSize: 14)),
          trailing: Text(item.night?.format(context) ?? 'Not Set', style: const TextStyle(color: Colors.indigoAccent)),
          onTap: () async {
            final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 20, minute: 0));
            if (t != null) setState(() => item.night = t);
          },
        ),
      ],
    );
  }
}
