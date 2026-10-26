import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Auth/AuthService.dart';
import '../ChatRelatedPages/user_active_service.dart';
import '../RegistrationPage/RegistrationPage.dart';
import 'package:advocatechaiadvocate/Utils/BaseURL.dart' as baseURL;
import '../Utils/BaseURL.dart' as BASE_URL;
import '../main.dart'; // Add this for homePageKey

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<StatefulWidget> createState() {
    return LogInState();
  }
}

class LogInState extends State<LogIn> with SingleTickerProviderStateMixin {
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isVisible = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    
    // Animation controller for the spinning logo ring
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    
    doesItVisible();
  }

  @override
  void dispose() {
    _spinController.dispose();
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<bool> doesItVisible() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("jwt_token") ?? "";

    if (token.isEmpty) {
      return false;
    }

    String allAthleteURL = "${baseURL.Urls().baseURL}advocate/all";
    Uri uri = Uri.parse(allAthleteURL);

    var response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 403) {
      return false;
    }

    isVisible = true;

    setState(() {
      isVisible = true;
    });

    return true;
  }

  void setUserActive(bool active) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');
      String? userId = prefs.getString('userId');
      if (userId != null) {
        final response = await http.get(
          Uri.parse("${BASE_URL.Urls().baseURL}user-active/user/$userId"),
          headers: {
            'content-type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          await UserActiveService.updateUserActive(
            body["id"],
            userId,
            active,
            token,
          );
        } else {
          await UserActiveService.addUserActive(userId, active, token);
        }
      }
    } catch (e) {
      print(e);
    }
  }

  // ============================================================
  // ✅ Detect: email / phone / username
  // ============================================================
  String _detectLoginType(String input) {
    final trimmed = input.trim();

    // 1) Email
    final emailRegex = RegExp(r'^[\w\.\-\+]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
    if (emailRegex.hasMatch(trimmed)) {
      return 'email';
    }

    // 2) Phone — digits only, optional leading +, length 7–15
    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    final looksLikePhone = RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(trimmed);
    if (looksLikePhone && digitsOnly.length >= 7 && digitsOnly.length <= 15) {
      return 'phone';
    }

    // 3) Fallback: username
    return 'username';
  }

  // Keep only digits; preserve leading +
  String _normalizePhone(String input) {
    final trimmed = input.trim();
    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    return hasPlus ? '+$digits' : digits;
  }

  // ============================================================
  // ✅ Build the URL for the given login type.
  // ============================================================
  Uri _buildLoginUri(String loginType, String identifier, String password) {
    final base = baseURL.Urls().baseURL;

    switch (loginType) {
      case 'email':
        return Uri.parse("${base}auth/login/email").replace(
          queryParameters: {
            "email": identifier,
            "password": password,
          },
        );
      case 'phone':
        return Uri.parse("${base}auth/login/phone").replace(
          queryParameters: {
            "phone": identifier,
            "password": password,
          },
        );
      case 'username':
      default:
        return Uri.parse("${base}auth/login");
    }
  }

  Future<void> _submitForm() async {
    final String rawIdentifier = identifierController.text.trim();
    final String password = passwordController.text;

    if (rawIdentifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter username/email/phone and password"),
        ),
      );
      return;
    }

    final String loginType = _detectLoginType(rawIdentifier);
    final String identifier =
        loginType == 'phone' ? _normalizePhone(rawIdentifier) : rawIdentifier;

    setState(() => _isLoading = true);

    final Uri uri = _buildLoginUri(loginType, identifier, password);

    // Username login still uses the JSON body (existing contract).
    // Email/phone login passes everything via query params (new contract).
    final Map<String, dynamic> body = loginType == 'username'
        ? {"userName": identifier, "password": password}
        : {};

    print("🔍 Detected type : $loginType");
    print("🌐 Endpoint      : $uri");
    if (body.isNotEmpty) {
      print("📤 Body          : ${jsonEncode(body)}");
    }

    http.Response logInResponse;
    try {
      logInResponse = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: body.isEmpty ? null : jsonEncode(body),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Network error: $e");
      return;
    }

    setState(() => _isLoading = false);

    print("📥 Status        : ${logInResponse.statusCode}");
    print("📥 Body          : ${logInResponse.body}");

    if (logInResponse.statusCode == 200 || logInResponse.statusCode == 201) {
      final decoded = jsonDecode(logInResponse.body);
      final userId = decoded["userId"];
      final String token = decoded["token"];

      // ✅ KEEPING ADVOCATE CHECK LOGIC
      final advocateResponse = await http.get(
        Uri.parse("${baseURL.Urls().baseURL}advocate/findByUser/$userId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (advocateResponse.statusCode == 200) {
        // -------- Save token (App + Web) ----------
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("jwt_token", token);
        await prefs.setString("userId", userId);

        final advocateResponseBody = jsonDecode(advocateResponse.body);
        final advocateId = advocateResponseBody["id"];
        await prefs.setString("advocateId", advocateId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Logged in successfully...")),
        );

        setState(() {
          isVisible = true;
          AuthService.saveToken(token);
          AuthService.saveUserId(userId);
          setUserActive(true);
        });

        // Refresh user data and navigate back
        if (mounted) {
          if (homePageKey.currentState != null) {
            await homePageKey.currentState!.refreshUserData();
          }
          Navigator.pop(context, true);
        }
      } else {
        // Not an advocate
        _showError("Only advocate can take entry of this application");
      }
    } else {
      String message;
      final code = logInResponse.statusCode;
      final respBody = logInResponse.body;

      if (code == 401 || code == 403) {
        message = "Access denied ($code). Endpoint: $uri\n"
            "If this is /auth/login/email or /auth/login/phone, "
            "verify it is whitelisted in your SecurityConfig.";
      } else if (code == 404) {
        message = "Endpoint not found: $uri";
      } else if (code == 400) {
        message = "Bad request ($code). Server rejected the request shape.";
      } else if (code >= 500) {
        message = "Server error ($code). Please try again.";
      } else {
        message = "Login failed ($code): $respBody";
      }

      _showError(message);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // ============================================================
  // ✅ Spinning Badge Logo
  // ============================================================
  Widget _buildSpinningLogo() {
    const double badgeSize = 120;
    const double ringWidth = 4;
    const double innerPadding = 6;

    return SizedBox(
      width: badgeSize,
      height: badgeSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade700.withOpacity(0.18),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.green.shade200.withOpacity(0.5),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          RotationTransition(
            turns: _spinController,
            child: CustomPaint(
              size: const Size(badgeSize, badgeSize),
              painter: _LoginRingPainter(
                ringWidth: ringWidth,
                colors: [
                  Colors.green.shade300,
                  Colors.green.shade700,
                  Colors.lightGreen.shade400,
                  Colors.green.shade700,
                  Colors.green.shade300,
                ],
              ),
            ),
          ),
          Container(
            width: badgeSize - (ringWidth * 2) - (innerPadding * 2),
            height: badgeSize - (ringWidth * 2) - (innerPadding * 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.green.shade50, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png', // Ensure this asset exists in your pubspec.yaml
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.gavel_rounded,
                  color: Colors.green.shade700,
                  size: 42,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              _buildSpinningLogo(),
              const SizedBox(height: 20),
              Text(
                "Welcome Back!",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Login to your advocate account",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 40),

              // ✅ Universal input (Matches User Panel)
              TextField(
                controller: identifierController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: GoogleFonts.inter(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Username, Email or Phone',
                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: Colors.green.shade600,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: !_isPasswordVisible,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitForm(),
                style: GoogleFonts.inter(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: Colors.green.shade600,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Login",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.inter(color: Colors.grey.shade600),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegistrationPage()),
                      );
                    },
                    child: Text(
                      "Register",
                      style: GoogleFonts.inter(
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              // Show login status message
              if (isVisible)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    "You are logged in...",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Custom painter — gradient ring
// ============================================================
class _LoginRingPainter extends CustomPainter {
  final double ringWidth;
  final List<Color> colors;

  _LoginRingPainter({required this.ringWidth, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - ringWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: colors,
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        startAngle: 0,
        endAngle: math.pi * 2,
      ).createShader(rect);

    canvas.drawCircle(center, radius, paint);

    final shinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth * 0.5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.9),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.04, 0.09],
        startAngle: 0,
        endAngle: math.pi * 2,
      ).createShader(rect);

    canvas.drawCircle(center, radius, shinePaint);
  }

  @override
  bool shouldRepaint(covariant _LoginRingPainter old) {
    return old.ringWidth != ringWidth || old.colors != colors;
  }
}