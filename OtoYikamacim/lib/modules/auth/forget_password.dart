import 'package:alsat/modules/auth/login_screen.dart';
import 'package:alsat/core/size.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      setState(() {
        _successMessage = 'Şifre sıfırlama bağlantısı email adresinize gönderildi.';
      });
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Bu email adresi ile kayıtlı kullanıcı bulunamadı.';
          break;
        case 'invalid-email':
          message = 'Geçersiz email adresi.';
          break;
        case 'too-many-requests':
          message = 'Çok fazla deneme yaptınız. Lütfen daha sonra tekrar deneyin.';
          break;
        default:
          message = 'Bir hata oluştu. Lütfen daha sonra tekrar deneyin.';
      }
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Bir hata oluştu. Lütfen daha sonra tekrar deneyin.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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
                      'Şifremi Unuttum',
                      style: GoogleFonts.poppins(
                        fontSize: SizeConfig.getProportionateFontSize(29.4),
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.getProportionateScreenHeight(15)),
                _buildNewPassword(),
                SizedBox(height: SizeConfig.getProportionateScreenHeight(27)),
                _buildEmailField(),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_successMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(color: Colors.green),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(height: SizeConfig.getProportionateScreenHeight(34)),
                _buildRegisterButton(),
                SizedBox(height: SizeConfig.getProportionateScreenHeight(20)),
                _buildRegisterLink(),
                SizedBox(height: SizeConfig.getProportionateScreenHeight(60)),
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
          onPressed: _isLoading ? null : _resetPassword,
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
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Gönder',
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

  Widget _buildLogo() {
    return Padding(
      padding: EdgeInsets.only(
          left: SizeConfig.getProportionateScreenWidth(14),
          right: SizeConfig.getProportionateScreenWidth(25)),
      child: SizedBox(
          height: SizeConfig.getProportionateScreenHeight(267),
          width: SizeConfig.getProportionateScreenWidth(321),
          child: Image.asset(
            'assets/forget.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error, size: 50, color: Colors.red);
            },
          )),
    );
  }

  Widget _buildNewPassword() {
    return Text(
      'Yeni Şifre',
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

  Widget _buildRegisterLink() {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          );
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
        ),
        child: Text(
          'Giriş Yap',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
