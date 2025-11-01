import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "image": "assets/images/image1.png",
      "title": "Conversas mais\npróximas",
      "subtitle": "Agora as conversas ficaram\ncada vez mais próximas.",
    },
    {
      "image": "assets/images/image1.png",
      "title": "Conexões\nInstantâneas?",
      "subtitle": "As melhores conversas\ncomeçam perto de você.",
    },
    {
      "image": "assets/images/image1.png",
      "title": "Rede de\nProximidade",
      "subtitle": "Descubra quem está perto e\ncomece a conversar.",
    },
  ];

  Future<void> _completeOnboardingAndNavigateToCadastro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Register()),
    );
  }

  void _nextPage() {
    final nextPage = _currentPage + 1;
    if (nextPage < onboardingData.length) {
      _controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboardingAndNavigateToCadastro();
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
                  physics: const BouncingScrollPhysics(), 
                  itemCount: onboardingData.length,
                  onPageChanged: (index) async {
                    setState(() => _currentPage = index);
                    if (index == onboardingData.length - 1) {
                      await Future.delayed(const Duration(milliseconds: 300));
                    }
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
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 300,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 50,
                              ),
                            );
                          },
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
