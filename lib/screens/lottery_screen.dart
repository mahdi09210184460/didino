import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../providers/admin_provider.dart';
import '../providers/wallet_provider.dart';

class LotteryScreen extends StatelessWidget {
  const LotteryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProv = Provider.of<AdminProvider>(context);
    final walletProv = Provider.of<WalletProvider>(context);
    final activeLotteries = adminProv.lotteries.where((l) => l['is_active'] == true).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('قرعه‌کشی و جوایز'), backgroundColor: AppColors.background),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🔥 قرعه‌کشی‌های فعال', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...activeLotteries.map((l) => _buildLotteryCard(context, l, walletProv, adminProv)),
            const SizedBox(height: 30),
            const Text('🏆 برندگان خوش‌شانس قبلی', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildWinnersList(adminProv.winners),
          ],
        ),
      ),
    );
  }

  Widget _buildLotteryCard(BuildContext context, Map<String, dynamic> lottery, WalletProvider wallet, AdminProvider admin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: lottery['banner_url'] != null 
              ? Image.network(lottery['banner_url'], height: 180, width: double.infinity, fit: BoxFit.cover)
              : Container(height: 180, color: AppColors.primary, child: const Icon(Icons.image, size: 50, color: Colors.white38)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lottery['title'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(lottery['description'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const Divider(color: Colors.white10, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoItem(Icons.calendar_month, 'تاریخ برگزاری', lottery['draw_date']?.toString().split('T')[0] ?? 'نامشخص'),
                    _infoItem(Icons.payments, 'هزینه ورود', '${(lottery['cost'] as num).toInt()} ت'),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _showPaymentOptions(context, lottery, wallet, admin),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('شرکت در قرعه‌کشی', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 14, color: AppColors.secondary), const SizedBox(width: 4), Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10))]),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showPaymentOptions(BuildContext context, Map<String, dynamic> lottery, WalletProvider wallet, AdminProvider admin) {
    final cost = (lottery['cost'] as num).toDouble();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('انتخاب روش پرداخت', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: AppColors.secondary),
              title: const Text('پرداخت از کیف پول', style: TextStyle(color: Colors.white)),
              subtitle: Text('موجودی: ${wallet.balance.toInt()} تومان', style: const TextStyle(color: Colors.white54)),
              onTap: () async {
                bool success = await wallet.deductBalance(cost, 'شرکت در قرعه‌کشی');
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ثبت‌نام با موفقیت انجام شد ✅')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('موجودی کافی نیست!')));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.blueAccent),
              title: const Text('پرداخت مستقیم آنلاین', style: TextStyle(color: Colors.white)),
              onTap: () {
                if (admin.activeGateways.isNotEmpty) {
                  launchUrl(Uri.parse(admin.activeGateways.first.url), mode: LaunchMode.externalApplication);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinnersList(List<Map<String, dynamic>> winners) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: winners.length,
      itemBuilder: (context, index) {
        final w = winners[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.emoji_events, color: Colors.white)),
          title: Text(w['user_name'] ?? 'کاربر ناشناس', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(w['prize_title'] ?? 'جایزه ویژه', style: const TextStyle(color: Colors.white70)),
          trailing: Text(w['winner_date']?.toString() ?? '', style: const TextStyle(color: Colors.white24, fontSize: 10)),
        );
      },
    );
  }
}
