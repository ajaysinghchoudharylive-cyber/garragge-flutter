import 'package:carsbuzz/sellcar/sell_car_flow.dart';
import 'package:carsbuzz/sellcar/sell_car_wizard_screen.dart' show showUploadLimitDialog;
import 'package:carsbuzz/sellcar/widgets/sell_ui.dart';
import 'package:carsbuzz/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Additional information checklist + "Post Ad", a port of the Android
/// FragmentAdditionalInformation (checklist_layout.xml). Each checkbox stores "Yes" / "No".
class SellChecklistScreen extends StatefulWidget {
  final SellCarFlow flow;

  const SellChecklistScreen({super.key, required this.flow});

  @override
  State<SellChecklistScreen> createState() => _SellChecklistScreenState();
}

class _Item {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color bg;
  final Color tint;
  final String? Function() get;
  final void Function(String) set;

  _Item(this.title, this.subtitle, this.icon, this.bg, this.tint, this.get, this.set);
}

class _SellChecklistScreenState extends State<SellChecklistScreen> {
  bool _posting = false;
  int _progress = 0;

  SellCarFlow get _flow => widget.flow;

  late final List<_Item> _items = [
    _Item('Insurance?', 'Is the vehicle insured?', Icons.security, const Color(0xFFEFF6FF),
        const Color(0xFF2563EB), () => _flow.form.insurance, (v) => _flow.form.insurance = v),
    _Item('Registration?', 'Is RC available?', Icons.app_registration, const Color(0xFFECFDF5),
        const Color(0xFF059669), () => _flow.form.registration,
        (v) => _flow.form.registration = v),
    _Item('Good Battery condition?', 'Is the battery in good state?', Icons.battery_unknown,
        const Color(0xFFF0FDF4), const Color(0xFF16A34A), () => _flow.form.battery,
        (v) => _flow.form.battery = v),
    _Item('Good Tyre Condition?', 'Are the tyres in good condition?', Icons.tire_repair,
        const Color(0xFFF5F3FF), const Color(0xFF7C3AED), () => _flow.form.tyre,
        (v) => _flow.form.tyre = v),
    _Item('Good Brakes Condition?', 'Are the brakes in good condition?', Icons.security,
        const Color(0xFFFFFBEB), const Color(0xFFD97706), () => _flow.form.brakes,
        (v) => _flow.form.brakes = v),
    _Item('Service history proof?', 'Is service history available?', Icons.build_circle_outlined,
        const Color(0xFFEFF6FF), const Color(0xFF2563EB), () => _flow.form.service,
        (v) => _flow.form.service = v),
    _Item('Loan Clearance?', 'Is the loan fully cleared?', Icons.attach_money,
        const Color(0xFFFDF2F8), const Color(0xFFDB2777), () => _flow.form.loan,
        (v) => _flow.form.loan = v),
    _Item('PUC Certificate?', 'Is PUC certificate available?', Icons.assured_workload,
        const Color(0xFFF5F3FF), const Color(0xFF7C3AED), () => _flow.form.puc,
        (v) => _flow.form.puc = v),
    _Item('No Challan Pending?', 'Are there no pending challans?', Icons.policy_outlined,
        const Color(0xFFECFEFF), const Color(0xFF0891B2), () => _flow.form.challan,
        (v) => _flow.form.challan = v),
  ];

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> _ensureOwnerName() async {
    if ((_flow.form.ownerName ?? '').trim().isNotEmpty) return true;
    final name = await askSellText(context,
        title: 'Your name', hint: 'Full name', message: 'Buyers will see this name on your ad.');
    if (name == null) return false;
    _flow.form.ownerName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', name);
    return true;
  }

  Future<void> _postAd() async {
    if (_posting) return;
    final form = _flow.form;
    // Unticked boxes are sent as "No", like Android.
    for (final item in _items) {
      if (item.get() == null) item.set('No');
    }
    if ((form.userId ?? 0) <= 0 || (form.phoneNumber ?? '').isEmpty) {
      _toast('Please log in again to post your ad.');
      return;
    }
    if (!form.isReadyToPost) {
      _toast('Some car details are missing. Please complete all steps.');
      return;
    }
    if (!form.hasMinimumImages) {
      _toast('Please add at least 6 photos.');
      return;
    }
    if (!await _ensureOwnerName()) return;

    setState(() {
      _posting = true;
      _progress = 0;
    });
    await _flow.ensureLocation();
    if (_flow.form.latitude == null && mounted) {
      setState(() => _posting = false);
      _toast("We need your location to show buyers where the car is. Please allow location access.");
      return;
    }
    final result = await _flow.repo.postAd(
      form,
      draftId: _flow.remoteDraftId,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );
    if (!mounted) return;
    setState(() => _posting = false);

    if (result.success) {
      _flow.posted = true;
      await showModalBottomSheet<void>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => const _SuccessSheet(),
      );
      if (mounted) SellCarFlow.popTo(context, null);
    } else if (result.isUploadLimitReached) {
      await showUploadLimitDialog(context, result.message);
    } else {
      _toast(result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_posting,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const SellToolbar(title: 'Sell Car', counter: '10/10'),
                  const SellStepper(active: 2),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text(
                          'Add these details to make your ad more trustworthy and attractive.',
                          style: TextStyle(fontSize: 14, color: SellColors.slate500),
                        ),
                        const SizedBox(height: 8),
                        for (int i = 0; i < _items.length; i++) ...[
                          if (i > 0) Container(height: 1, color: const Color(0xFFF1F5F9)),
                          _row(_items[i]),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SellPrimaryButton(
                      text: 'Post Ad',
                      height: 60,
                      fontSize: 18,
                      onPressed: _postAd,
                    ),
                  ),
                ],
              ),
              if (_posting) _uploadOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(_Item item) {
    final checked = item.get() == 'Yes';
    return InkWell(
      onTap: () => setState(() => item.set(checked ? 'No' : 'Yes')),
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: item.bg, shape: BoxShape.circle),
              child: Icon(item.icon, size: 20, color: item.tint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                  Text(item.subtitle,
                      style: const TextStyle(fontSize: 12, color: SellColors.slate500)),
                ],
              ),
            ),
            Checkbox(
              value: checked,
              activeColor: AppColors.accent,
              onChanged: (v) => setState(() => item.set(v == true ? 'Yes' : 'No')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Uploading car ad...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _progress == 0 || _progress >= 100 ? null : _progress / 100,
                minHeight: 6,
                color: AppColors.accent,
              ),
              const SizedBox(height: 12),
              Text(_progress >= 100 ? 'Finishing up...' : '$_progress%',
                  style: const TextStyle(fontSize: 13, color: SellColors.slate500)),
              const SizedBox(height: 4),
              const Text('Please keep the app open.',
                  style: TextStyle(fontSize: 11, color: SellColors.slate500)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Success bottom sheet (fragment_success_ad_post_dialog.xml).
class _SuccessSheet extends StatelessWidget {
  const _SuccessSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (final (dx, dy, color) in const [
                    (-80.0, -50.0, Color(0xFFFBBF24)),
                    (70.0, -60.0, Color(0xFF60A5FA)),
                    (-70.0, 50.0, Color(0xFFF472B6)),
                    (85.0, 40.0, Color(0xFF34D399)),
                    (0.0, -72.0, Color(0xFFA78BFA)),
                  ])
                    Transform.translate(
                      offset: Offset(dx, dy),
                      child: Icon(Icons.auto_awesome, size: 18, color: color),
                    ),
                  Container(
                    width: 88,
                    height: 88,
                    decoration:
                        const BoxDecoration(color: SellColors.green, shape: BoxShape.circle),
                    child: const Icon(Icons.check, size: 52, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Upload Successful!',
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            const Padding(
              padding: EdgeInsets.fromLTRB(40, 8, 40, 0),
              child: Text('Your ad has been submitted and is now under review.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Color(0xFF4B5563))),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.schedule, color: SellColors.green),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ads are reviewed within an hour.',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827))),
                        Text('However, some reviews take longer.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SellColors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Got it',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
