import 'package:flutter/material.dart';

const _adminNavy = Color(0xFF132941);
const _adminBlue = Color(0xFF2F80ED);

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.selectedItem,
    required this.onItemTap,
    this.wireframeLabel = 'WIREFRAME ・ 19',
  });

  static const items = [
    'ダッシュボード',
    '管理者・権限',
    '会員',
    '育成ゲーム',
    'QR施策',
    'ランキング',
    '景品',
    '監査ログ',
    'WordPress',
  ];

  final String selectedItem;
  final ValueChanged<String> onItemTap;
  final String wireframeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: _adminNavy,
      padding: const EdgeInsets.fromLTRB(17, 27, 11, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 17),
            child: Text(
              'BlueSharks',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 17, top: 2),
            child: Text(
              '運用管理',
              style: TextStyle(color: Color(0xFFB8C5D5), fontSize: 11),
            ),
          ),
          const SizedBox(height: 38),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 7),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = item == selectedItem;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(7),
                    onTap: () => onItemTap(item),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? _adminBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 17),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.circle : Icons.radio_button_unchecked,
                            size: isSelected ? 7 : 9,
                            color: isSelected ? Colors.white : const Color(0xFFC8D4E2),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            item,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFFC8D4E2),
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 17),
            child: Text(
              wireframeLabel,
              style: TextStyle(color: Color(0xFF8192A6), fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}
