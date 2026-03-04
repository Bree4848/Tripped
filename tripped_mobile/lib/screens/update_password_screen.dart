import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _updatePassword() async {
    // Basic validation
    if (_passwordController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Updates the password for the current recovery session
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text.trim()),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password updated successfully! Please login."),
            backgroundColor: Colors.green,
          ),
        );
        // Force back to login to re-authenticate with the new password
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An unexpected error occurred."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeDarkBlue = Color(0xFF1A237E);
    final themeYellow = Colors.yellow[700]!;

    return Scaffold(
      backgroundColor: themeYellow,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_reset, size: 120, color: themeDarkBlue),
                const Text(
                  "NEW PASSWORD",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: themeDarkBlue,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "SECURE YOUR ACCOUNT",
                  style: TextStyle(
                    color: themeDarkBlue,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 50),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "ENTER NEW PASSWORD",
                    hintStyle: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.3),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.vpn_key_outlined,
                      color: themeDarkBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeDarkBlue,
                      foregroundColor: themeYellow,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    onPressed: _isLoading ? null : _updatePassword,
                    child: _isLoading
                        ? CircularProgressIndicator(color: themeYellow)
                        : const Text(
                            "SAVE PASSWORD",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text(
                    "CANCEL",
                    style: TextStyle(
                      color: themeDarkBlue,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
