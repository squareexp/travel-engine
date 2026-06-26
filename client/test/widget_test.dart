import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/design/theme.dart';
import 'package:client/shared/widgets/trip_timeline_card.dart';

void main() {
  testWidgets('trip timeline stays readable in the app theme', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TwendeTheme.light(),
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
            child: TripTimelineCard(
              date: 'FRI, 18 JUL',
              title: 'Mnemba Island snorkel',
              detail: 'Nungwi · 2 guests · Confirmed',
            ),
          ),
        ),
      ),
    );
    expect(find.text('Mnemba Island snorkel'), findsOneWidget);
    expect(find.textContaining('Nungwi'), findsOneWidget);
  });
}
