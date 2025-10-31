import 'package:alsat/data/services/auth_service.dart';
import 'package:alsat/modules/auth/forget_password.dart';
import 'package:alsat/modules/auth/register_screen.dart';
import 'package:alsat/modules/admin/admin_panel_screen.dart';
import 'package:alsat/core/size.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:alsat/modules/home/main_page_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      if (!mounted) return;
      setState(() => _isLoading = true);

      try {
        print('Login denemesi başlatıldı.');

        final userData = await _authService.signin(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          context: context,
        );

        if (!mounted) return; // Yönlendirme yapmadan önce tekrar kontrol et

        if (userData != null) {
          if (userData['isAdmin'] == true) {
            print('Admin olarak yönlendiriliyor...');
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
              (route) => false,
            );
          } else {
            print('Normal kullanıcı olarak yönlendiriliyor...');
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MainScreen()),
              (route) => false,
            );
          }
        } else {
          // Giriş başarısız, hata mesajı zaten servis içinde gösteriliyor
          print('Giriş başarısız, kullanıcı bilgileri alınamadı.');
        }
      } catch (e) {
        print('Login sırasında hata oluştu: $e');
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Giriş yapılırken bir hata oluştu',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.black54,
            textColor: Colors.white,
            fontSize: 14.0,
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
          print('Loading kapatıldı.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: SizeConfig.getProportionateScreenHeight(7)),
                _buildLogo(),
                SizedBox(height: SizeConfig.getProportionateScreenHeight(48)),
                Text(
                  'Giriş Yap',
                  style: GoogleFonts.poppins(
                    fontSize: SizeConfig.getProportionateFontSize(29.4),
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: SizeConfig.getProportionateScreenHeight(7)),
                Text(
                  'Giriş yapmak için devam et',
                  style: GoogleFonts.poppins(
                    fontSize: SizeConfig.getProportionateFontSize(14),
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: SizeConfig.getProportionateScreenHeight(7)),
                _buildForgetLink(),
                SizedBox(height: SizeConfig.getProportionateScreenHeight(17)),
                _buildEmailField(),
                SizedBox(height: SizeConfig.getProportionateScreenHeight(17)),
                _buildPasswordField(),
                SizedBox(height: SizeConfig.getProportionateScreenHeight(40)),
                _buildLoginButton(),
                SizedBox(height: SizeConfig.getProportionateScreenHeight(7)),
                _buildRegisterLink(),
                SizedBox(height: SizeConfig.getProportionateScreenHeight(43)),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: EdgeInsets.only(
          left: SizeConfig.getProportionateScreenWidth(65),
          right: SizeConfig.getProportionateScreenWidth(53)),
      child: Container(
          height: SizeConfig.getProportionateScreenHeight(206),
          width: SizeConfig.getProportionateScreenWidth(242),
          child: Image.asset(
            'assets/amico.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error, size: 50, color: Colors.red);
            },
          )),
    );
  }

  Widget _buildEmailField() {
    return Padding(
      padding: EdgeInsets.only(
          left: SizeConfig.getProportionateScreenWidth(70),
          right: SizeConfig.getProportionateScreenWidth(48)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(
                right: SizeConfig.getProportionateScreenWidth(17)),
            child: Image.asset(
              'assets/email.png',
              height: SizeConfig.getProportionateScreenHeight(27),
              width: SizeConfig.getProportionateScreenWidth(26),
            ),
          ),
          SizedBox(
            width: SizeConfig.getProportionateScreenWidth(174),
            height: SizeConfig.getProportionateScreenHeight(26),
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                label: Text("Email"),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: const BorderSide(color: Colors.black, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: const BorderSide(color: Colors.black, width: 1),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen email adresinizi girin';
                }
                if (!value.contains('@')) {
                  return 'Geçerli bir email adresi girin';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: EdgeInsets.only(
        left: SizeConfig.getProportionateScreenWidth(70),
        right: SizeConfig.getProportionateScreenWidth(48),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(
              right: SizeConfig.getProportionateScreenWidth(18),
            ),
            child: Image.asset(
              'assets/password.png',
              height: SizeConfig.getProportionateScreenHeight(24),
              width: SizeConfig.getProportionateScreenWidth(25),
            ),
          ),
          SizedBox(
            width: SizeConfig.getProportionateScreenWidth(174),
            height: SizeConfig.getProportionateScreenHeight(26),
            child: TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                label: Text("Şifre"),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: const BorderSide(color: Colors.black, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: const BorderSide(color: Colors.black, width: 1),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen şifrenizi girin';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return Padding(
      padding: EdgeInsets.only(
        left: SizeConfig.getProportionateScreenWidth(115),
        right: SizeConfig.getProportionateScreenWidth(119),
      ),
      child: SizedBox(
        width: SizeConfig.getProportionateScreenWidth(126),
        height: SizeConfig.getProportionateScreenHeight(28),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7E57C2),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                SizeConfig.getProportionateScreenWidth(40),
              ),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? SizedBox(
                  height: SizeConfig.getProportionateScreenHeight(20),
                  width: SizeConfig.getProportionateScreenWidth(20),
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Giriş Yap',
                  style: TextStyle(
                    fontSize: SizeConfig.getProportionateFontSize(14),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildForgetLink() {
    return Text.rich(
      TextSpan(
        text: "Şifremi ",
        style: GoogleFonts.poppins(
          color: Colors.grey[600],
        ),
        children: [
          TextSpan(
            text: 'Unuttum',
            style: GoogleFonts.poppins(
              color: const Color(0xFF7E57C2),
              fontWeight: FontWeight.bold,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForgetPasswordScreen(),
                  ),
                );
              },
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildRegisterLink() {
    return Text.rich(
      TextSpan(
        text: "Hesabınız yok mu? ",
        style: GoogleFonts.poppins(
          color: Colors.grey[600],
        ),
        children: [
          TextSpan(
            text: 'Kayıt Ol',
            style: GoogleFonts.poppins(
              color: const Color(0xFF7E57C2),
              fontWeight: FontWeight.bold,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterScreen(),
                  ),
                );
              },
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildFooter() {
    return Container(
      child: Row(children: [
        Image.asset(
          'assets/lele.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.error, size: 50, color: Colors.red);
          },
        ),
        const Spacer(),
        Image.asset(
          'assets/rele.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.error, size: 50, color: Colors.red);
          },
        )
      ]),
    );
  }
}
