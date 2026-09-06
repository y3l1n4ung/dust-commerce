part of 'account_auth_form.dart';

class _AccountFormFields extends StatelessWidget {
  const _AccountFormFields({
    required this.registering,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.showPassword,
    required this.onTogglePassword,
  });

  final bool registering;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController phone;
  final bool showPassword;
  final VoidCallback onTogglePassword;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          if (registering) ...[
            _field(
              context,
              controller: firstName,
              label: context.tr(
                'shop_account_first_name',
                defaultText: 'First name',
              ),
              autofillHints: const [AutofillHints.givenName],
              validator: (value) => _required(context, value),
            ),
            const SizedBox(height: 8),
            _field(
              context,
              controller: lastName,
              label: context.tr(
                'shop_account_last_name',
                defaultText: 'Last name',
              ),
              autofillHints: const [AutofillHints.familyName],
              validator: (value) => _required(context, value),
            ),
            const SizedBox(height: 8),
          ],
          _field(
            context,
            controller: email,
            label: context.tr('shop_account_email', defaultText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: (value) => _email(context, value),
          ),
          const SizedBox(height: 8),
          if (registering) ...[
            _field(
              context,
              controller: phone,
              label: context.tr('shop_account_phone', defaultText: 'Phone'),
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              required: false,
            ),
            const SizedBox(height: 8),
          ],
          _field(
            context,
            controller: password,
            label: context.tr(
              'shop_account_password',
              defaultText: 'Password',
            ),
            obscureText: !showPassword,
            autofillHints: [
              registering ? AutofillHints.newPassword : AutofillHints.password,
            ],
            validator: (value) => _password(context, value),
            suffixIcon: IconButton(
              onPressed: onTogglePassword,
              tooltip: showPassword
                  ? context.tr(
                      'shop_account_hide_password',
                      defaultText: 'Hide password',
                    )
                  : context.tr(
                      'shop_account_show_password',
                      defaultText: 'Show password',
                    ),
              icon: Icon(
                showPassword ? Icons.visibility : Icons.visibility_off,
                size: 18,
              ),
            ),
          ),
        ],
      );

  Widget _field(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    bool obscureText = false,
    bool required = true,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        validator: validator,
        obscureText: obscureText,
        obscuringCharacter: '•',
        decoration: InputDecoration(
          label: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: label),
                if (required)
                  const TextSpan(
                    text: '*',
                    style: TextStyle(color: StoreColors.rose),
                  ),
              ],
            ),
          ),
          suffixIcon: suffixIcon,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 44,
          ),
          filled: true,
          fillColor: StoreColors.subtle,
          isDense: true,
          constraints: const BoxConstraints(minHeight: 44),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: StoreColors.border),
          ),
          contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        ),
      );

  String? _required(BuildContext context, String? value) =>
      value == null || value.trim().isEmpty
          ? context.tr(
              'shop_account_required',
              defaultText: 'This field is required.',
            )
          : null;

  String? _email(BuildContext context, String? value) {
    final required = _required(context, value);
    if (required != null) return required;
    final normalized = value!.trim();
    return normalized.contains('@') &&
            normalized.lastIndexOf('.') > normalized.indexOf('@')
        ? null
        : context.tr(
            'shop_account_invalid_email',
            defaultText: 'Enter a valid email address.',
          );
  }

  String? _password(BuildContext context, String? value) {
    final required = _required(context, value);
    if (required != null) return required;
    return value!.length >= 12 && value.length <= 1024
        ? null
        : context.tr(
            'shop_account_password_length',
            defaultText: 'Use 12 to 1024 characters.',
          );
  }
}
