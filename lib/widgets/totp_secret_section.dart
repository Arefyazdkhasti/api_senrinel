// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:get/get.dart';

import '../controllers/access_controller.dart';
import '../global_configs.dart';
import '../res/all_controller_keys.dart';

// Project imports:
class TotoSecretSection extends StatefulWidget {
  const TotoSecretSection({super.key});

  @override
  State<TotoSecretSection> createState() => _TotoSecretSectionState();
}

class _TotoSecretSectionState extends State<TotoSecretSection> {
  bool isLoading = false;
  final TextEditingController textFieldController = TextEditingController();

  final AccessController accessController = Get.find(
    tag: AllControllerKeys.accessControllerKey,
  );

  @override
  void initState() {
    super.initState();

    accessController.initialize();
  }

  Future<void> verifyOTP(String otp) async {
    setState(() => isLoading = true);
    final success = await accessController.validateCode(otp);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => isLoading = false);
    if (success && mounted) {
      Navigator.of(context).pop(true);
      accessController.enableDebugFeatures();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('totp_secret_section'),
      padding: globalMarginAll * 4,
      child: TextField(
        controller: textFieldController,
        maxLength: 6,
        enabled: !isLoading,
        keyboardType: TextInputType.number,
        onSubmitted: (String otpCode) async => verifyOTP(otpCode),
        decoration: InputDecoration(
          label: Text('totp'),
          counterText: '',
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
            borderRadius: globalBorderRadius * 2,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
            borderRadius: globalBorderRadius * 2,
          ),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
            borderRadius: globalBorderRadius * 2,
          ),
          suffixIcon: TextButton(
            onPressed: isLoading
                ? null
                : () => verifyOTP(textFieldController.text.trim()),
            child: isLoading
                ? SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : Text('Submit'),
          ),
        ),
      ),
    );
  }
}
