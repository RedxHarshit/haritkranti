import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../providers/irrigation_provider.dart';
import '../../providers/language_provider.dart';

class IrrigationControlScreen extends StatelessWidget {
  const IrrigationControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final irrigationProvider = context.watch<IrrigationProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final zones = irrigationProvider.currentData.zones;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSystemHeader(context, languageProvider.isHindi),
          const SizedBox(height: 16),
          _buildOverallStats(context, languageProvider.isHindi),
          const SizedBox(height: 16),
          Text(
            languageProvider.isHindi ? 'फसल क्षेत्र' : 'Zones',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...zones.map((z) => _ZoneCard(zone: z, isHindi: languageProvider.isHindi)).toList(),
        ],
      ),
    );
  }

  Widget _buildSystemHeader(BuildContext context, bool isHindi) {
    final irrigationProvider = context.watch<IrrigationProvider>();
    final enabled = irrigationProvider.irrigationEnabled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.power : Icons.power_off,
            color: enabled ? AppColors.successGreen : AppColors.errorRed,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              enabled 
                ? (isHindi ? 'सिंचाई प्रणाली चालू' : 'Irrigation System ON')
                : (isHindi ? 'सिंचाई प्रणाली बंद' : 'Irrigation System OFF'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (v) => context.read<IrrigationProvider>().toggleIrrigationWithLanguage(isHindi),
            activeColor: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStats(BuildContext context, bool isHindi) {
    final data = context.watch<IrrigationProvider>().currentData;

    Widget stat(String title, String value, IconData icon, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 2),
                    Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        stat(
          isHindi ? 'औसत नमी' : 'Avg Moisture', 
          '${data.averageSoilMoisture.toInt()}%', 
          Icons.water_drop, 
          AppColors.waterBlue
        ),
        const SizedBox(width: 12),
        stat(
          isHindi ? 'ऊपरी टैंक' : 'Upper Tank', 
          '${data.upperTankLevel.toInt()}%', 
          Icons.water, 
          AppColors.primaryGreen
        ),
      ],
    );
  }
}

class _ZoneCard extends StatelessWidget {
  final CropZone zone;
  final bool isHindi;

  const _ZoneCard({required this.zone, required this.isHindi});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<IrrigationProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: zone.statusColor.withOpacity(0.15),
                child: Text(
                  zone.id.replaceAll(RegExp(r'[^0-9]'), ''), // FIXED: Only show numbers
                  style: TextStyle(color: zone.statusColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isHindi ? _getHindiZoneName(zone.name) : zone.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                isHindi ? _getHindiMoistureStatus(zone.moistureStatus) : zone.moistureStatus,
                style: TextStyle(color: zone.statusColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              Switch(
                value: zone.isActive,
                onChanged: (v) => provider.toggleZone(zone.id),
                activeColor: AppColors.primaryGreen,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.water_drop, color: AppColors.waterBlue, size: 18),
              const SizedBox(width: 6),
              Text('${isHindi ? 'मिट्टी की नमी' : 'Soil Moisture'}: ${zone.soilMoisture.toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.successGreen, size: 18),
              const SizedBox(width: 6),
              Text('${isHindi ? 'आदर्श' : 'Optimal'}: ${zone.optimalMoistureMin.toStringAsFixed(0)}% - ${zone.optimalMoistureMax.toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => provider.updateZoneMoisture(zone.id, (zone.soilMoisture + 5).clamp(0, 100)),
                  icon: const Icon(Icons.water),
                  label: Text(isHindi ? 'सिमुलेट +5%' : 'Simulate +5%'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => provider.updateZoneMoisture(zone.id, (zone.soilMoisture - 5).clamp(0, 100)),
                  icon: const Icon(Icons.remove),
                  label: Text(isHindi ? 'सिमुलेट -5%' : 'Simulate -5%'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getHindiZoneName(String zoneName) {
    if (zoneName.contains('Tomatoes')) return 'क्षेत्र 1 - टमाटर';
    if (zoneName.contains('Peppers')) return 'क्षेत्र 2 - मिर्च';
    if (zoneName.contains('Spinach')) return 'क्षेत्र 3 - पालक';
    return zoneName;
  }

  String _getHindiMoistureStatus(String status) {
    switch (status) {
      case 'Optimal': return 'आदर्श';
      case 'Needs water': return 'पानी चाहिए';
      case 'Over-watered': return 'अधिक पानी';
      default: return status;
    }
  }
}
