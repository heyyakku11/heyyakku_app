import 'package:flutter/material.dart';

class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Text('10', style: TextStyle(fontWeight: FontWeight.w800,fontSize: 16)),
                    Text('Asked', style: TextStyle(fontWeight: FontWeight.w600,fontSize: 16))
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Text('8', style: TextStyle(fontWeight: FontWeight.w800,fontSize: 16)),
                    Text('Answered', style: TextStyle(fontWeight: FontWeight.w600,fontSize: 16))
                  ],
                ),
              ),
            ),
          )
        ],
    );
  }
}

//
// Row(
// spacing: 10,
// children: [
// Expanded(
// child: Container(
// decoration: BoxDecoration(
// borderRadius: BorderRadius.circular(12),
// border: Border.all(color: Colors.grey),
// ),
// child: const Padding(
// padding: EdgeInsetsGeometry.all(10),
// child: Center(
// child: Column(
// children: [
// Text(
// 'Polls',
// style: TextStyle(
// fontWeight: FontWeight.w600,
// fontSize: 16,
// ),
// ),
// Text(
// '22',
// style: TextStyle(
// fontWeight: FontWeight.w600,
// fontSize: 16,
// ),
// ),
// ],
// ),
// ),
// ),
// ),
// ),
// Expanded(
// child: Container(
// decoration: BoxDecoration(
// borderRadius: BorderRadius.circular(12),
// border: Border.all(color: Colors.grey),
// ),
// child: const Padding(
// padding: EdgeInsetsGeometry.all(10),
// child: Center(
// child: Column(
// children: [
// Text(
// 'Anwered',
// style: TextStyle(
// fontWeight: FontWeight.w600,
// fontSize: 16,
// ),
// ),
// Text(
// '10',
// style: TextStyle(
// fontWeight: FontWeight.w600,
// fontSize: 16,
// ),
// ),
// ],
// ),
// ),
// ),
// ),
// ),
// Expanded(
// child: Container(
// decoration: BoxDecoration(
// borderRadius: BorderRadius.circular(12),
// border: Border.all(color: Colors.grey),
// ),
// child: const Padding(
// padding: EdgeInsetsGeometry.all(10),
// child: Center(
// child: Column(
// children: [
// Text(
// 'Draft',
// style: TextStyle(
// fontWeight: FontWeight.w600,
// fontSize: 16,
// ),
// ),
// Text(
// '8',
// style: TextStyle(
// fontWeight: FontWeight.w600,
// fontSize: 16,
// ),
// ),
// ],
// ),
// ),
// ),
// ),
// ),
// ],
// ),