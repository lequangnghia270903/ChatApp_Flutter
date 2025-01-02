import 'package:chat_app_flutter/providers/authentication_provider.dart';
import 'package:chat_app_flutter/utilities/assets_manager.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScrennState();
}

class _LoginScrennState extends State<LoginScreen> {
  final TextEditingController _phoneNumberController = TextEditingController();

  Country selectedCountry = Country(
    phoneCode: '84',
    countryCode: 'VN',
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: 'Vietnam',
    example: 'Vietnam',
    displayName: 'Vietnam',
    displayNameNoCountryCode: 'VN',
    e164Key: '',
  );

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthenticationProvider>();
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 20.0,
        ),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              width: 200,
              child: Lottie.asset(AssetsManager.chatBubble),
            ),
            Text(
              'Chat App',
              style: GoogleFonts.openSans(
                  fontSize: 28, fontWeight: FontWeight.w500),
            ),
            const SizedBox(
              height: 50,
            ),
            Text(
              'Nhập số điện thoại của bạn để nhận mã xác thực',
              style: GoogleFonts.openSans(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            TextFormField(
              controller: _phoneNumberController,
              maxLength: 10,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onChanged: (value) {
                setState(() {
                  _phoneNumberController.text = value;
                });
              },
              decoration: InputDecoration(
                counterText: '',
                hintText: 'Số điện thoại',
                hintStyle: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.fromLTRB(8.0, 12.0, 8.0, 12.0),
                  child: InkWell(
                    onTap: () {
                      showCountryPicker(
                        context: context,
                        showPhoneCode: true,
                        // countryListTheme: CountryListThemeData(
                        //   // bottomSheetHeight: 400,
                        //   textStyle: GoogleFonts.openSans(
                        //     fontSize: 16,
                        //     fontWeight: FontWeight.w500,
                        //   ),
                        // ),
                        onSelect: (Country country) {
                          setState(() {
                            selectedCountry = country;
                          });
                        },
                      );
                    },
                    child: Text(
                      '${selectedCountry.flagEmoji} +${selectedCountry.phoneCode}',
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                // This will change the color of the border when the TextField is focused
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Colors.blueAccent,
                    width: 2.0,
                  ),
                ),
                // Optional: This will keep the default border color when not focused
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.grey.shade500,
                    width: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              onPressed: _phoneNumberController.text.length > 9
                  ? () {
                      // sign in with phone number
                      authProvider.signInWithPhoneNumber(
                        phoneNumber:
                            '+${selectedCountry.phoneCode}${_phoneNumberController.text}',
                        context: context,
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                fixedSize: const Size(150, 55),
              ),
              child: authProvider.isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.done,
                          color: Colors.white,
                          size: 25,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Xác nhận',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
