import 'package:flutter/material.dart';
import '../widgets/shell_scaffold.dart';

class StatisticsScreen extends StatelessWidget {
	const StatisticsScreen({Key? key}) : super(key: key);

	@override
	Widget build(BuildContext context) {
		final cardBg = const Color(0xFF161616);
		return ShellScaffold(
			currentIndex: 4,
			body: SingleChildScrollView(
				padding: const EdgeInsets.symmetric(vertical: 16),
				child: Center(
					child: ConstrainedBox(
						constraints: const BoxConstraints(maxWidth: 760),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.stretch,
							children: [
								const Padding(
									padding: EdgeInsets.symmetric(horizontal: 16.0),
									child: Column(
										children: [
											Text('Análisis Financiero', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
											SizedBox(height: 6),
											Text('Comprende mejor tus patrones de gasto', style: TextStyle(color: Colors.white54)),
										],
									),
								),

								const SizedBox(height: 16),

								Padding(
									padding: const EdgeInsets.symmetric(horizontal: 16.0),
									child: Row(
										children: [
											Expanded(child: _smallStat('Total Ingresos', '\$3500', Colors.green)),
											const SizedBox(width: 8),
											Expanded(child: _smallStat('Total Gastos', '\$650', Colors.red)),
											const SizedBox(width: 8),
											Expanded(child: _smallStat('Promedio', '\$830', Colors.amber)),
										],
									),
								),

								const SizedBox(height: 12),

								Padding(
									padding: const EdgeInsets.symmetric(horizontal: 16.0),
									child: Container(
										padding: const EdgeInsets.all(12),
										decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												const Text('Tendencia Mensual', style: TextStyle(color: Colors.white)),
												const SizedBox(height: 12),
												SizedBox(height: 220, child: _barChartPlaceholder()),
											],
										),
									),
								),

								const SizedBox(height: 12),

								Padding(
									padding: const EdgeInsets.symmetric(horizontal: 16.0),
									child: Container(
										padding: const EdgeInsets.all(12),
										decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												const Text('Gastos por Categoría', style: TextStyle(color: Colors.white)),
												const SizedBox(height: 12),
												SizedBox(height: 200, child: _pieChartPlaceholder()),
												const SizedBox(height: 12),
												_categoryLegend('Comida', '\$450', 0.69, Colors.green),
												_categoryLegend('Transporte', '\$80', 0.12, Colors.amber),
												_categoryLegend('Entretenimiento', '\$120', 0.18, Colors.red),
											],
										),
									),
								),

								const SizedBox(height: 16),

								Padding(
									padding: const EdgeInsets.symmetric(horizontal: 16.0),
									child: Container(
										padding: const EdgeInsets.all(12),
										decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF9AEF5E), Color(0xFF7BB32F)]), borderRadius: BorderRadius.circular(12)),
										child: const Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												Text('Insights Financieros', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
												SizedBox(height: 8),
												Text('Tendencia Positiva - Tus ingresos han crecido 15% en los últimos 3 meses', style: TextStyle(color: Colors.black87)),
												SizedBox(height: 8),
												Text('Categoría Principal - Comida representa tu mayor gasto', style: TextStyle(color: Colors.black87)),
											],
										),
									),
								),

								const SizedBox(height: 80),
							],
						),
					),
				),
			),
		);
	}

	static Widget _smallStat(String title, String value, Color color) {
		return Container(
			padding: const EdgeInsets.all(12),
			decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(10)),
			child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white70)), const SizedBox(height: 8), Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18))]),
		);
	}

		static Widget _barChartPlaceholder() {
			return Container(
				decoration: BoxDecoration(color: Color(0xFF0F1720), borderRadius: BorderRadius.circular(8)),
				padding: const EdgeInsets.all(12),
				child: Column(
					children: [
						Expanded(
							child: Row(
								crossAxisAlignment: CrossAxisAlignment.end,
								children: List.generate(6, (i) => Expanded(
									child: Container(
										margin: const EdgeInsets.symmetric(horizontal: 6),
										height: 30.0 + i * 20.0,
										decoration: BoxDecoration(color: Colors.green[300 - i * 40], borderRadius: BorderRadius.circular(6)),
									),
								)),
							),
						),
						const SizedBox(height: 8),
						Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('Jul', style: TextStyle(color: Colors.white54)), Text('Dic', style: TextStyle(color: Colors.white54))]),
					],
				),
			);
		}

		static Widget _pieChartPlaceholder() {
			return Container(
				decoration: BoxDecoration(color: Color(0xFF0F1720), borderRadius: BorderRadius.circular(8)),
				child: Center(
					child: Row(
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
							Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
							const SizedBox(width: 12),
							Column(
								mainAxisSize: MainAxisSize.min,
								crossAxisAlignment: CrossAxisAlignment.start,
								children: const [
									Text('Comida 69%', style: TextStyle(color: Colors.white)),
									SizedBox(height: 6),
									Text('Transporte 12%', style: TextStyle(color: Colors.white54)),
									SizedBox(height: 6),
									Text('Entretenimiento 18%', style: TextStyle(color: Colors.white54)),
								],
							)
						],
					),
				),
			);
		}

	static Widget _categoryLegend(String label, String amount, double pct, Color color) {
		return Padding(
			padding: const EdgeInsets.symmetric(vertical: 6.0),
			child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
				Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.white))]),
				Row(children: [Text(amount, style: const TextStyle(color: Colors.white)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6)), child: Text('${(pct * 100).round()}%', style: const TextStyle(color: Colors.white70)))])
			]),
		);
	}
}

