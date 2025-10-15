import 'package:flutter/material.dart';

class OnboardingScreen1 extends StatefulWidget {
  const OnboardingScreen1({super.key});

  @override
  State<OnboardingScreen1> createState() => _OnboardingScreen1State();
}

class _OnboardingScreen1State extends State<OnboardingScreen1> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "image": "assets/images/",
      "title": "Conversas mais\npróximas",
      "subtitle": "Agora as conversas ficaram\ncada vez mais próximas.",
    },
    {
      "image": "assets/images/",
      "title": "Conexões\nInstantâneas?",
      "subtitle": "As melhores conversas\ncomeçam perto de você.",
    },
    {
      "image": "assets/images/",
      "title": "Rede de\nProximidade",
      "subtitle": "Descubra quem está perto e\ncomece a conversar.",
    },
  ];

  void _nextPage() {
    final nextPage = _currentPage + 1;

    if (nextPage < onboardingData.length) {
      setState(() {
        _currentPage = nextPage;
      });
      _controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Navegar para a tela de login
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Login()));
      print("Última página atingida!");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(35),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: onboardingData.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = onboardingData[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Image.asset(
                          item["image"]!,
                          height: 300,
                          fit: BoxFit.contain,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              item["title"]!,
                              style: const TextStyle(
                                fontSize: 35,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item["subtitle"]!,
                              style: const TextStyle(
                                fontSize: 17,
                                fontStyle: FontStyle.italic,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 40),

              // Indicadores + botão de avanço
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      onboardingData.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildIndicator(index == _currentPage),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: const Color(0xFF004E89),
                      padding: const EdgeInsets.all(16),
                      elevation: 4,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: isActive ? 30 : 15,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF004E89) : Colors.blueGrey[300],
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
