import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../landmark_recognition/data/services/llm_service.dart';

/// Splash screen that shows VistaGuide branding and handles initial routing
/// Also handles AI model checking/downloading on first launch
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  // Model download state
  bool _isDownloadingModel = false;
  double _modelDownloadProgress = 0.0;
  String _statusMessage = 'Loading...';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    // Wait for initial animations to complete
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Step 1: Check and download AI model if needed
    await _checkAndDownloadModel();

    if (!mounted) return;

    // Step 2: Check authentication status and route
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is authenticated, go to home
      context.go(AppRoutes.home);
    } else {
      // User is not authenticated, go to login
      context.go(AppRoutes.login);
    }
  }

  Future<void> _checkAndDownloadModel() async {
    final llmService = LlmService();
    
    setState(() {
      _statusMessage = 'Loading...';
    });
    
    // Check if model already exists
    final modelExists = await llmService.isModelDownloaded();
    
    if (modelExists) {
      // Model exists, just proceed
      setState(() {
        _statusMessage = 'AI ready!';
      });
      await Future.delayed(const Duration(milliseconds: 300));
      return;
    }
    
    // Model doesn't exist - download it
    setState(() {
      _isDownloadingModel = true;
      _statusMessage = 'Downloading resources (289 MB)...';
    });
    
    final success = await llmService.downloadModel(
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _modelDownloadProgress = progress;
            _statusMessage = 'Downloading resources... ${(progress * 100).toStringAsFixed(0)}%';
          });
        }
      },
    );
    
    setState(() {
      _isDownloadingModel = false;
    });
    
    if (success) {
      setState(() {
        _statusMessage = 'Ready to move!';
      });
      await Future.delayed(const Duration(milliseconds: 500));
    } else {
      // Download failed - app can still work with limited features
      setState(() {
        _statusMessage = 'Continuing without AI...';
      });
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: Image.asset(
                          'assets/images/vistaguide_logo.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to custom VG logo if image fails to load
                            return Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(60),
                              ),
                              child: const Center(
                                child: Text(
                                  'VG',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // App Name
                    const Text(
                      'VistaGuide',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tagline
                    const Text(
                      'AI Travel Companion',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 60),

                    // Loading indicator or download progress
                    if (_isDownloadingModel) ...[
                      // Show download progress
                      SizedBox(
                        width: 200,
                        child: Column(
                          children: [
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: _modelDownloadProgress,
                                minHeight: 6,
                                backgroundColor: Colors.white.withValues(alpha: 0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Percentage
                            Text(
                              '${(_modelDownloadProgress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Regular loading spinner
                      const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Status message
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
