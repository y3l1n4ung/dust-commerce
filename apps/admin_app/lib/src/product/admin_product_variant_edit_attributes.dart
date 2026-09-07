part of 'admin_product_variant_edit_drawer.dart';

extension on _VariantEditDrawerState {
  List<Widget> _attributeFields(bool busy) => [
        Text(
          'Attributes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        ..._numberField('Weight', _values.weight, busy),
        ..._numberField('Width', _values.width, busy),
        ..._numberField('Length', _values.length, busy),
        ..._numberField('Height', _values.height, busy),
        _field(
          label: 'MID code',
          optional: true,
          controller: _values.midCode,
          enabled: !busy,
          validator: _optionalIdentifier,
        ),
        const SizedBox(height: 16),
        _field(
          label: 'HS code',
          optional: true,
          controller: _values.hsCode,
          enabled: !busy,
          validator: _optionalIdentifier,
        ),
        const SizedBox(height: 16),
        _countryField(busy),
      ];

  List<Widget> _numberField(
    String label,
    TextEditingController controller,
    bool busy,
  ) =>
      [
        _field(
          label: label,
          optional: true,
          controller: controller,
          enabled: !busy,
          validator: _optionalNumber,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
      ];

  Widget _countryField(bool busy) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Text('Country of origin',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(width: 5),
            Text(
              '(Optional)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ]),
          const SizedBox(height: 7),
          RawAutocomplete<({String code, String name})>(
            textEditingController: _values.originCountry,
            focusNode: _values.originCountryFocus,
            displayStringForOption: (country) => country.name,
            optionsBuilder: _countryOptions,
            onSelected: (country) => _setOriginCountry(country.code),
            fieldViewBuilder: (context, controller, focusNode, submit) =>
                TextFormField(
              controller: controller,
              focusNode: focusNode,
              enabled: !busy,
              onChanged: _typeOriginCountry,
              onFieldSubmitted: (_) => submit(),
              validator: (value) =>
                  (value?.isNotEmpty ?? false) && _originCountry == null
                      ? 'Choose a country'
                      : null,
              decoration: const InputDecoration(
                hintText: 'Select country',
                suffixIcon: Icon(Icons.unfold_more_rounded, size: 16),
                suffixIconConstraints: BoxConstraints.tightFor(
                  width: 34,
                  height: 34,
                ),
              ),
            ),
            optionsViewBuilder: _countryOptionsView,
          ),
        ],
      );

  Iterable<({String code, String name})> _countryOptions(
    TextEditingValue value,
  ) {
    final query = value.text.trim().toLowerCase();
    if (query.isEmpty) return _variantCountries;
    return _variantCountries.where(
      (country) =>
          country.name.toLowerCase().contains(query) ||
          country.code.contains(query),
    );
  }

  Widget _countryOptionsView(
    BuildContext context,
    AutocompleteOnSelected<({String code, String name})> onSelected,
    Iterable<({String code, String name})> options,
  ) =>
      Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(7),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width.clamp(0, 512).toDouble(),
            height: 240,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final country in options)
                  InkWell(
                    onTap: () => onSelected(country),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: Text(country.name),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}
