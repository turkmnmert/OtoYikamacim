import 'package:alsat/data/services/auth_service.dart';
import 'package:alsat/modules/auth/login_screen.dart';
import 'package:alsat/core/size.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullnameController = TextEditingController();
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

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _authService.signup(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullname: _fullnameController.text.trim(),
          context: context,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Kayıt olurken bir hata oluştu: \\n${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
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
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Yeni Hesap',
                      style: GoogleFonts.poppins(
                        fontSize: SizeConfig.getProportionateFontSize(29.4),
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Oluştur',
                      style: GoogleFonts.poppins(
                        fontSize: SizeConfig.getProportionateFontSize(29.4),
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.getProportionateScreenHeight(11)),
                _buildRegisterLink(),
                SizedBox(height: SizeConfig.getProportionateScreenHeight(15)),
                _buildFullNameField(),
                SizedBox(height: SizeConfig.getProportionateScreenHeight(17)),
                _buildEmailField(),
                SizedBox(height: SizeConfig.getProportionateScreenHeight(17)),
                _buildPasswordField(),
                SizedBox(height: SizeConfig.getProportionateScreenHeight(26)),
                _buildRegisterButton(),
                SizedBox(height: SizeConfig.getProportionateScreenHeight(42)),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Padding(
      padding: EdgeInsets.only(
        left: SizeConfig.getProportionateScreenWidth(115),
        right: SizeConfig.getProportionateScreenWidth(119),
      ),
      child: SizedBox(
        width: SizeConfig.getProportionateScreenWidth(126),
        height: SizeConfig.getProportionateScreenHeight(28),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _register,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF7E57C2),
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
                  'Kayıt Ol',
                  style: TextStyle(
                    fontSize: SizeConfig.getProportionateFontSize(14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
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

  Widget _buildFullNameField() {
    return Padding(
      padding: EdgeInsets.only(
        left: SizeConfig.getProportionateScreenWidth(70),
        right: SizeConfig.getProportionateScreenWidth(48),
        top: SizeConfig.getProportionateScreenHeight(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(
              right: SizeConfig.getProportionateScreenWidth(18),
            ),
            child: Image.asset(
              'assets/person.png',
              height: SizeConfig.getProportionateScreenHeight(24),
              width: SizeConfig.getProportionateScreenWidth(25),
            ),
          ),
          SizedBox(
            width: SizeConfig.getProportionateScreenWidth(174),
            height: SizeConfig.getProportionateScreenHeight(26),
            child: TextFormField(
              controller: _fullnameController,
              decoration: InputDecoration(
                label: Text("Ad Soyad"),
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
                  return 'lütfen adınızı girin';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: EdgeInsets.only(
          left: SizeConfig.getProportionateScreenWidth(54),
          right: SizeConfig.getProportionateScreenWidth(42)),
      child: Container(
          height: SizeConfig.getProportionateScreenHeight(226),
          width: SizeConfig.getProportionateScreenWidth(264),
          child: Image.asset(
            'assets/register.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error, size: 50, color: Colors.red);
            },
          )),
    );
  }

  Widget _buildRegisterLink() {
    return Text.rich(
      TextSpan(
        text: 'Zaten kayıtlı mısınız? ',
        style: GoogleFonts.poppins(
          color: Colors.grey[600],
        ),
        children: [
          TextSpan(
            text: 'Giriş Yap',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
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
        Spacer(),
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
