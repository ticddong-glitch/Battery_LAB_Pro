import 'package:flutter/material.dart';
import '../widgets/calculator_card.dart';
import '../widgets/side_menu.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SideMenu(),

      appBar: AppBar(
        title: const Text(
          "Battery LAB Pro",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Text(
                      "🔋 Battery LAB Pro",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Battery Research Toolkit",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Welcome Researcher 👋",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      "Everything you need for battery experiments.",
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              const Text(
                "⭐ Favorite Tools",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              CalculatorCard(
                icon: Icons.science,
                title: "Theory Capacity",
                subtitle: "Calculate theoretical capacity",
                color: Colors.blue,
                onTap: () {},
              ),

              CalculatorCard(
                icon: Icons.balance,
                title: "Loading Level",
                subtitle: "Calculate electrode loading",
                color: Colors.green,
                onTap: () {},
              ),

              const SizedBox(height: 25),

              const Divider(),

              const SizedBox(height: 20),

              const Text(
                "🧪 LAB Tools",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              CalculatorCard(
                icon: Icons.opacity,
                title: "Slurry Calculator",
                subtitle: "Calculate slurry composition",
                color: Colors.orange,
                onTap: () {},
              ),

              CalculatorCard(
                icon: Icons.show_chart,
                title: "Areal Capacity",
                subtitle: "Calculate areal capacity",
                color: Colors.purple,
                onTap: () {},
              ),

              CalculatorCard(
                icon: Icons.calculate,
                title: "Coming Soon",
                subtitle: "More calculators will be added",
                color: Colors.grey,
                onTap: () {},
              ),

              const SizedBox(height: 30),

            ],
          ),
        ),
      ),
    );
  }
}