import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
    	final String text;
    	final VoidCallback onPressed;
    	final List<Color> colors;

    	const GradientButton({
    		super.key,
    		required this.text,
    		required this.onPressed,
    		this.colors = const [Color(0xFF9AEF5E), Color(0xFFF1C232)],
    	});

	@override
	Widget build(BuildContext context) {
		return Container(
			margin: EdgeInsets.symmetric(horizontal: 24),
			height: 52,
			decoration: BoxDecoration(
				gradient: LinearGradient(colors: colors),
				borderRadius: BorderRadius.circular(10),
				boxShadow: [
					BoxShadow(
						color: colors.last.withAlpha((0.22 * 255).round()),
						blurRadius: 8,
						offset: Offset(0, 4),
					)
				],
			),
			child: Material(
				color: Colors.transparent,
				child: InkWell(
					borderRadius: BorderRadius.circular(10),
					onTap: onPressed,
					child: Center(
						child: Text(text, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
					),
				),
			),
		);
	}
}
