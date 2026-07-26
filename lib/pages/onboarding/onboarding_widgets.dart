import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// Onboarding'in tasarım dili yapı taşları (BACKLOG F "Tasarım dili" —
/// bu ekranlar uygulamanın geri kalanına şablon):
/// kenarlık çizgisi yok (ayrım renk farkı + çok hafif gölge), 16-20px köşe,
/// hap birincil butonlar, dolgulu inputlar, seçili durum primaryContainer.

/// Kenarlıksız beyaz kart/çiplerde zeminden ayrım için çok hafif gölge.
const List<BoxShadow> onbSoftShadow = [
  BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2)),
];

/// Tam genişlik hap birincil buton (min 54px). [loading] iken dolu görünümü
/// korur ve spinner gösterir; validasyonla devre dışıyken tema soluk rengi.
class OnbPrimaryButton extends StatelessWidget {
  const OnbPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: loading ? AppColors.primary : null,
          disabledForegroundColor: loading ? AppColors.onPrimary : null,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.onPrimary,
                ),
              )
            : Text(label),
      ),
    );
  }
}

/// Hap ikincil buton (özet ekranındaki "İlk planımı oluştur").
class OnbSecondaryButton extends StatelessWidget {
  const OnbSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.4),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              )
            : Text(label),
      ),
    );
  }
}

/// Dolgulu, kenarlıksız, yuvarlak köşeli input (OutlineInputBorder değil).
class OnbTextField extends StatelessWidget {
  const OnbTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(16));
    const noBorder = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide.none,
    );
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 16, color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: noBorder,
        enabledBorder: noBorder,
        focusedBorder: noBorder,
      ),
    );
  }
}

/// Dikey seçim kartı: seçimsiz beyaz + hafif gölge, seçili primaryContainer
/// dolgu + onPrimaryContainer metin. Kenarlıksız, 18px köşe.
class OnbSelectCard extends StatelessWidget {
  const OnbSelectCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.emoji,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? emoji;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryContainer : AppColors.surface,
        borderRadius: radius,
        boxShadow: selected ? null : onbSoftShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 18,
              vertical: dense ? 14 : 18,
            ),
            child: Row(
              children: [
                if (emoji != null) ...[
                  Text(emoji!, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: dense ? 15 : 16,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.onPrimaryContainer
                          : AppColors.text,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: AppColors.onPrimaryContainer,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hap çip (tekil). Seçim grubu widget'ları bunu kullanır.
class OnbChip extends StatelessWidget {
  const OnbChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(100);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryContainer : AppColors.surface,
        borderRadius: radius,
        boxShadow: selected ? null : onbSoftShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.onPrimaryContainer : AppColors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tek seçimli çip grubu. Seçili çipe tekrar dokunmak seçimi kaldırır
/// (opsiyonel sorular böyle atlanabilir; zorunlularda İleri kapalı kalır).
class OnbChipGroup extends StatelessWidget {
  const OnbChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  /// (değer, görünen etiket) çiftleri.
  final List<(String, String)> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final (value, label) in options)
          OnbChip(
            label: label,
            selected: selected == value,
            onTap: () => onSelected(selected == value ? null : value),
          ),
      ],
    );
  }
}

/// Çok seçimli çip grubu. [exclusiveValue] (örn. "none") seçilince diğerleri
/// temizlenir; başka bir değer seçilince o kaldırılır.
class OnbMultiChipGroup extends StatelessWidget {
  const OnbMultiChipGroup({
    super.key,
    required this.options,
    required this.values,
    required this.onChanged,
    this.exclusiveValue,
  });

  final List<(String, String)> options;
  final Set<String> values;
  final ValueChanged<Set<String>> onChanged;
  final String? exclusiveValue;

  void _toggle(String value) {
    final next = Set<String>.from(values);
    if (next.contains(value)) {
      next.remove(value);
    } else if (value == exclusiveValue) {
      next
        ..clear()
        ..add(value);
    } else {
      next
        ..remove(exclusiveValue)
        ..add(value);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final (value, label) in options)
          OnbChip(
            label: label,
            selected: values.contains(value),
            onTap: () => _toggle(value),
          ),
      ],
    );
  }
}

/// Adım başlığı: büyük kalın soru + altında küçük gri "neden soruyoruz".
class OnbStepHeader extends StatelessWidget {
  const OnbStepHeader({super.key, required this.title, this.why});

  final String title;
  final String? why;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.15,
            color: AppColors.text,
          ),
        ),
        if (why != null) ...[
          const SizedBox(height: 12),
          Text(
            why!,
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Adım içindeki soru grubu etiketi.
class OnbSectionLabel extends StatelessWidget {
  const OnbSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
    );
  }
}
