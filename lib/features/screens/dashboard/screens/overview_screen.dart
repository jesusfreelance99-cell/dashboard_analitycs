import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/shared/metric_card_widget.dart';
import '../widgets/shared/panel_widget.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppConstants.spacingXl),
            _buildMetricsGrid(),
            const SizedBox(height: AppConstants.spacingXl),
            _buildTrendSection(),
            const SizedBox(height: AppConstants.spacingXl),
            _buildPlanDistribution(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen General',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Vista general del desempeño de tu negocio',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.ink2,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 768;
        final crossAxisCount = isCompact ? 1 : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: AppConstants.spacingLg,
          crossAxisSpacing: AppConstants.spacingLg,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            MetricCardWidget(
              title: 'Ingresos Totales',
              value: '\$45,230',
              change: '+12.5%',
              isPositive: true,
            ),
            MetricCardWidget(
              title: 'Suscriptores',
              value: '1,234',
              change: '+8.2%',
              isPositive: true,
            ),
            MetricCardWidget(
              title: 'Tasa de Conversión',
              value: '3.8%',
              change: '-0.5%',
              isPositive: false,
            ),
            MetricCardWidget(
              title: 'Costo Promedio',
              value: '\$12.50',
              change: '-2.1%',
              isPositive: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrendSection() {
    return PanelWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tendencias',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.fieldBg,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            ),
            child: const Center(
              child: Text('Gráfico de tendencias'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanDistribution() {
    return PanelWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribución por Plan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          _buildPlanRow('Plan Pro', 450, 0.45),
          const SizedBox(height: AppConstants.spacingSm),
          _buildPlanRow('Plan Basic', 350, 0.35),
          const SizedBox(height: AppConstants.spacingSm),
          _buildPlanRow('Plan Premium', 200, 0.20),
        ],
      ),
    );
  }

  Widget _buildPlanRow(String label, int count, double percentage) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.ink),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.fieldBg,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.pink,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppConstants.spacingSm),
        SizedBox(
          width: 50,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
