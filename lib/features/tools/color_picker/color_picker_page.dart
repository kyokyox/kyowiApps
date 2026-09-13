import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/seraph_header.dart';

class ColorPickerPage extends StatefulWidget {
  const ColorPickerPage({super.key});

  @override
  State<ColorPickerPage> createState() => _ColorPickerPageState();
}

class _ColorPickerPageState extends State<ColorPickerPage> {
  Color _baseColor = const Color(0xFF5B9BF0);
  Uint8List? _imageBytes;
  img.Image? _decodedImage;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;
    final decoded = img.decodeImage(bytes);
    setState(() {
      _imageBytes = bytes;
      _decodedImage = decoded;
    });
  }

  void _sampleAt(Offset localPos, Size widgetSize) {
    if (_decodedImage == null) return;
    final x = (localPos.dx / widgetSize.width * _decodedImage!.width).clamp(0, _decodedImage!.width - 1).toInt();
    final y = (localPos.dy / widgetSize.height * _decodedImage!.height).clamp(0, _decodedImage!.height - 1).toInt();
    final pixel = _decodedImage!.getPixel(x, y);
    setState(() {
      _baseColor = Color.fromARGB(255, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());
    });
  }

  String _hex(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  void _copyHex(Color c) {
    Clipboard.setData(ClipboardData(text: _hex(c)));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Hex tersalin'), duration: Duration(seconds: 1)));
  }

  // Teori warna sederhana: konversi RGB<->HSL buat generate palet.
  HSLColor get _hsl => HSLColor.fromColor(_baseColor);

  List<Color> get _complementary => [_baseColor, _hsl.withHue((_hsl.hue + 180) % 360).toColor()];

  List<Color> get _analogous => [
        _hsl.withHue((_hsl.hue - 30 + 360) % 360).toColor(),
        _baseColor,
        _hsl.withHue((_hsl.hue + 30) % 360).toColor(),
      ];

  List<Color> get _triadic => [
        _baseColor,
        _hsl.withHue((_hsl.hue + 120) % 360).toColor(),
        _hsl.withHue((_hsl.hue + 240) % 360).toColor(),
      ];

  List<Color> get _shades => List.generate(5, (i) {
        final lightness = (0.2 + i * 0.15).clamp(0.0, 1.0);
        return _hsl.withLightness(lightness).toColor();
      });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const SeraphHeader(
            title: 'Color', accent: 'Picker', subtitle: 'Pick warna & generate palet serasi'),
        Container(
          height: 90,
          decoration: BoxDecoration(
            color: _baseColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => _copyHex(_baseColor),
            child: Text(_hex(_baseColor),
                style: TextStyle(
                    color: _hsl.lightness > 0.6 ? Colors.black87 : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ),
        ),
        const SizedBox(height: 14),
        const Text('GESER BUAT UBAH WARNA', style: TextStyle(color: AppColors.gray, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 6),
        _hueSlider(),
        const SizedBox(height: 8),
        Slider(
          value: _hsl.saturation, min: 0, max: 1,
          activeColor: AppColors.cyan, inactiveColor: AppColors.line,
          onChanged: (v) => setState(() => _baseColor = _hsl.withSaturation(v).toColor()),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image_outlined, color: AppColors.cyan),
          label: const Text('Pick Warna dari Gambar', style: TextStyle(color: AppColors.ink)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.line), padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
        if (_imageBytes != null) ...[
          const SizedBox(height: 10),
          const Text('Tap di gambar buat sample warna', style: TextStyle(color: AppColors.gray, fontSize: 10.5)),
          const SizedBox(height: 6),
          LayoutBuilder(builder: (context, constraints) {
            final size = Size(constraints.maxWidth, 200);
            return GestureDetector(
              onTapUp: (details) => _sampleAt(details.localPosition, size),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(_imageBytes!, height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            );
          }),
        ],
        const SizedBox(height: 22),
        _paletteSection('Komplementer', _complementary),
        _paletteSection('Analog', _analogous),
        _paletteSection('Triadik', _triadic),
        _paletteSection('Shades', _shades),
      ],
    );
  }

  Widget _hueSlider() {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: List.generate(7, (i) => HSLColor.fromAHSL(1, i * 60.0, 1, 0.5).toColor()),
        ),
      ),
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: 24,
          activeTrackColor: Colors.transparent,
          inactiveTrackColor: Colors.transparent,
          thumbColor: Colors.white,
          overlayColor: Colors.transparent,
        ),
        child: Slider(
          value: _hsl.hue, min: 0, max: 360,
          onChanged: (v) => setState(() => _baseColor = _hsl.withHue(v).toColor()),
        ),
      ),
    );
  }

  Widget _paletteSection(String title, List<Color> colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.ink, fontSize: 12.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: colors
                .map((c) => Expanded(
                      child: GestureDetector(
                        onTap: () => _copyHex(c),
                        child: Container(
                          height: 56,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
