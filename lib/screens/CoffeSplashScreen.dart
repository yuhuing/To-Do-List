import 'dart:async';
import 'package:flutter/material.dart';

class CoffeeProgressSplash extends StatefulWidget {
  final Widget nextScreen;

  const CoffeeProgressSplash({super.key, required this.nextScreen});

  @override
  State<CoffeeProgressSplash> createState() => _CoffeeProgressSplashState();
}

class _CoffeeProgressSplashState extends State<CoffeeProgressSplash>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _steamController;
  late AnimationController _fadeController;
  late AnimationController _bubbleController;

  late Animation<double> _progressAnimation;
  late Animation<double> _steamAnimation;
  late Animation<double> _fadeAnimation;

  Timer? _progressTimer;
  double _currentProgress = 0.0;
  int _currentTask = 0;
  final int _totalTasks = 8;

  // Coffee theme colors
  static const Color espresso = Color(0xFF2C1810);
  static const Color coffeeBrown = Color(0xFF4A2C2A);
  static const Color caramelBrown = Color(0xFF8B5A2B);
  static const Color creamWhite = Color(0xFFFAF7F2);
  static const Color milkFoam = Color(0xFFF5F2ED);

  final List<String> _loadingTasks = [
    "Grinding coffee beans...",
    "Heating the water...",
    "Preparing your workspace...",
    "Loading your tasks...",
    "Brewing productivity...",
    "Adding motivation...",
    "Perfecting the blend...",
    "Ready to get things done!",
  ];

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _steamController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _bubbleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _steamAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _steamController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _startSplashSequence();
  }

  void _startSplashSequence() async {
    // Start fade in animation
    _fadeController.forward();

    // Start steam animation
    _steamController.repeat();
    _bubbleController.repeat();

    // Start progress animation
    _progressController.forward();

    // Simulate loading tasks
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_currentTask < _totalTasks) {
        setState(() {
          _currentTask++;
          _currentProgress = _currentTask / _totalTasks;
        });
      } else {
        timer.cancel();
        // Wait a bit then navigate
        Timer(const Duration(milliseconds: 1000), () {
          _navigateToNextScreen();
        });
      }
    });
  }

  void _navigateToNextScreen() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => widget.nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  Color _getCoffeeColor(double progress) {
    if (progress < 0.3) {
      return Color.lerp(milkFoam, caramelBrown, progress * 3.33)!;
    } else if (progress < 0.7) {
      return Color.lerp(caramelBrown, coffeeBrown, (progress - 0.3) * 2.5)!;
    } else {
      return Color.lerp(coffeeBrown, espresso, (progress - 0.7) * 3.33)!;
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _progressController.dispose();
    _steamController.dispose();
    _fadeController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [creamWhite, milkFoam, caramelBrown.withOpacity(0.05)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // App Title
                Text(
                  'Café Checklist',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: espresso,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 4),

                // Coffee Quote
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    '"A cup of coffee is the perfect boost\nto get things done."',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: caramelBrown,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Replace the Coffee Cup Progress section (around line 200-350) with this:

                // Coffee Cup Progress
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    double progress = _progressAnimation.value;

                    return Column(
                      children: [
                        // Combined Coffee Cup + Steam (kept together)
                        SizedBox(
                          width: 160,
                          height: 190, // Increased to accommodate steam
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Steam (positioned relative to cup)
                              if (progress > 0.1)
                                Positioned(
                                  top: 0, // At the very top
                                  child: SizedBox(
                                    height: 50,
                                    width: 160,
                                    child: AnimatedBuilder(
                                      animation: _steamController,
                                      builder: (context, child) {
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: List.generate(3, (index) {
                                            double delay = index * 0.3;
                                            double animValue =
                                                (_steamController.value +
                                                    delay) %
                                                1.0;

                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              child: Transform.translate(
                                                offset: Offset(
                                                  (index % 2 == 0 ? 1 : -1) *
                                                      (8 * animValue),
                                                  -animValue * 30,
                                                ),
                                                child: Opacity(
                                                  opacity:
                                                      (1.0 - animValue) *
                                                      progress *
                                                      0.8,
                                                  child: Container(
                                                    width: 4,
                                                    height: 18,
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment
                                                                .bottomCenter,
                                                        end:
                                                            Alignment.topCenter,
                                                        colors: [
                                                          Colors.white
                                                              .withOpacity(0.7),
                                                          Colors.white
                                                              .withOpacity(0.1),
                                                        ],
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            3,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        );
                                      },
                                    ),
                                  ),
                                ),

                              // Coffee Cup (positioned at bottom of stack)
                              Positioned(
                                bottom: 0,
                                child: SizedBox(
                                  width: 160,
                                  height: 140,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Coffee Mug Base
                                      Container(
                                        width: 160,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white,
                                              milkFoam,
                                              creamWhite,
                                            ],
                                          ),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                            bottomLeft: Radius.circular(32),
                                            bottomRight: Radius.circular(32),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: espresso.withOpacity(0.15),
                                              blurRadius: 20,
                                              offset: const Offset(0, 10),
                                            ),
                                            BoxShadow(
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(-3, -3),
                                            ),
                                          ],
                                          border: Border.all(
                                            color:
                                                caramelBrown, // More visible border
                                            width: 2,
                                          ),
                                        ),
                                      ),

                                      // Coffee Liquid (animated fill)
                                      Positioned(
                                        bottom: 8,
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(8),
                                            topRight: Radius.circular(8),
                                            bottomLeft: Radius.circular(26),
                                            bottomRight: Radius.circular(26),
                                          ),
                                          child: Container(
                                            width: 144,
                                            height: 104 * progress,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  _getCoffeeColor(
                                                    progress,
                                                  ).withOpacity(0.9),
                                                  _getCoffeeColor(progress),
                                                  _getCoffeeColor(
                                                    progress,
                                                  ).withOpacity(0.95),
                                                ],
                                              ),
                                            ),
                                            child: Stack(
                                              children: [
                                                // Coffee surface bubbles
                                                if (progress > 0.1)
                                                  AnimatedBuilder(
                                                    animation:
                                                        _bubbleController,
                                                    builder: (context, child) {
                                                      return Positioned(
                                                        top: 6,
                                                        left:
                                                            15 +
                                                            (30 *
                                                                _bubbleController
                                                                    .value),
                                                        child: Container(
                                                          width: 5,
                                                          height: 5,
                                                          decoration:
                                                              BoxDecoration(
                                                                color: milkFoam
                                                                    .withOpacity(
                                                                      0.6,
                                                                    ),
                                                                shape:
                                                                    BoxShape
                                                                        .circle,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                // Surface shine
                                                if (progress > 0.05)
                                                  Positioned(
                                                    top: 4,
                                                    left: 25,
                                                    child: Container(
                                                      width: 40,
                                                      height: 8,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withOpacity(0.4),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Coffee Mug Handle
                                      Positioned(
                                        right: -30,
                                        top: 20,
                                        child: Container(
                                          width: 40,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: milkFoam,
                                              width: 10,
                                            ),
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topRight: Radius.circular(25),
                                                  bottomRight: Radius.circular(
                                                    25,
                                                  ),
                                                ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: espresso.withOpacity(
                                                  0.1,
                                                ),
                                                blurRadius: 6,
                                                offset: const Offset(2, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Progress Information
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return Column(
                      children: [
                        Text(
                          '${(_progressAnimation.value * 100).round()}%',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: espresso,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_currentTask/$_totalTasks completed',
                          style: TextStyle(
                            fontSize: 16,
                            color: coffeeBrown,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_currentTask > 0 &&
                            _currentTask <= _loadingTasks.length)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              _loadingTasks[_currentTask - 1],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: caramelBrown,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                const Spacer(flex: 3),

                // Loading Indicator
                SizedBox(
                  width: 6,
                  height: 6,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(caramelBrown),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
