import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // FilteringTextInputFormatter

void main() => runApp(const MyApp());

/// NC4: model học phần (mã, tên, số tín chỉ).
/// Mã học phần ngoài INT4211 là mã đặt tạm – thay bằng mã thật nếu có.
class MonHoc {
  final String ma;
  final String ten;
  final int soTinChi;

  const MonHoc(this.ma, this.ten, this.soTinChi);

  @override
  String toString() => '$ma – $ten ($soTinChi tín chỉ)';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F3_231A290134',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0468D7)),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      home: const RegisterPage(),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Chìa khóa để điều khiển Form: validate(), reset(), save()
  final _formKey = GlobalKey<FormState>();

  // Controller đọc nội dung ô nhập — nhớ dispose()
  final _hoTenCtrl = TextEditingController();
  final _mssvCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _ngaySinhCtrl = TextEditingController(); // NC1

  // NC4: danh sách học phần là các đối tượng MonHoc thay vì chuỗi
  static const List<MonHoc> _monHocs = [
    MonHoc('INT4211', 'Lập trình di động', 3),
    MonHoc('INT2203', 'Cơ sở dữ liệu', 3),
    MonHoc('INT3401', 'Trí tuệ nhân tạo', 3),
    MonHoc('INT3412', 'Kiểm thử phần mềm', 2),
  ];
  static const _buoiHocs = ['Sáng', 'Chiều', 'Tối'];

  MonHoc? _monHoc; // giá trị của Dropdown (null = chưa chọn)
  String _heDaoTao = 'Chính quy'; // giá trị của nhóm Radio
  final Set<String> _buoiDaChon = {}; // các Checkbox đã tick
  bool _nhanThongBao = true; // Switch
  double _soTinChi = 15; // Slider
  DateTime? _ngaySinh; // NC1

  @override
  void dispose() {
    _hoTenCtrl.dispose();
    _mssvCtrl.dispose();
    _emailCtrl.dispose();
    _ngaySinhCtrl.dispose(); // controller mới thêm thì cũng phải dispose
    super.dispose();
  }

  // ---------------- Kiểm tra hợp lệ ----------------

  String? _kiemTraHoTen(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Vui lòng nhập họ tên';
    if (s.length < 3) return 'Họ tên phải có ít nhất 3 ký tự';
    return null; // null = hợp lệ
  }

  // MSSV của trường gồm đúng 10 ký tự chữ/số (ví dụ 231A290134).
  // Đề gốc dùng '^\d{10}$' (chỉ số); đổi để gõ được MSSV có chữ cái.
  String? _kiemTraMssv(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Vui lòng nhập MSSV';
    if (!RegExp(r'^[0-9A-Za-z]{10}$').hasMatch(s)) {
      return 'MSSV phải gồm đúng 10 ký tự (chữ cái hoặc chữ số)';
    }
    return null;
  }

  String? _kiemTraEmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Vui lòng nhập email';
    if (!RegExp(r'^[\w.\-]+@[\w\-]+\.[\w.\-]+$').hasMatch(s)) return 'Email không đúng định dạng';
    return null;
  }

  // ---------------- NC1: chọn ngày sinh ----------------

  /// Định dạng dd/MM/yyyy bằng cách ghép chuỗi thủ công (không cần package intl).
  String _dinhDangNgay(DateTime d) {
    final ngay = d.day.toString().padLeft(2, '0');
    final thang = d.month.toString().padLeft(2, '0');
    return '$ngay/$thang/${d.year}';
  }

  Future<void> _chonNgaySinh() async {
    final chon = await showDatePicker(
      context: context,
      initialDate: _ngaySinh ?? DateTime(2005, 1, 1),
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
      helpText: 'Chọn ngày sinh',
    );
    // Sau một lệnh await, màn hình có thể đã bị đóng → phải kiểm tra mounted
    if (chon == null || !mounted) return;
    setState(() {
      _ngaySinh = chon;
      _ngaySinhCtrl.text = _dinhDangNgay(chon);
    });
  }

  // ---------------- Đăng ký & Làm lại ----------------

  void _dangKy() {
    // 1) Kiểm tra các trường của Form
    final hopLe = _formKey.currentState!.validate();
    // 2) Kiểm tra các thành phần nằm ngoài Form
    if (_buoiDaChon.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy chọn ít nhất một buổi học')),
      );
      return;
    }
    // NC2: kiểm tra phụ thuộc giữa hai control (hệ đào tạo ↔ buổi học)
    if (_heDaoTao == 'Vừa làm vừa học' && !_buoiDaChon.contains('Tối')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hệ Vừa làm vừa học bắt buộc phải chọn buổi Tối')),
      );
      return;
    }
    if (!hopLe) return;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng ký'),
        content: Text(
          'Họ tên: ${_hoTenCtrl.text.trim()}\n'
          'MSSV: ${_mssvCtrl.text.trim()}\n'
          'Email: ${_emailCtrl.text.trim()}\n'
          'Ngày sinh: ${_ngaySinhCtrl.text}\n'
          'Học phần: $_monHoc\n'
          'Hệ đào tạo: $_heDaoTao\n'
          'Buổi học: ${(_buoiDaChon.toList()..sort()).join(", ")}\n'
          'Số tín chỉ: ${_soTinChi.round()}\n'
          'Nhận thông báo: ${_nhanThongBao ? "Có" : "Không"}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  void _lamLai() {
    _formKey.currentState!.reset(); // xóa nội dung và thông báo lỗi của các trường trong Form
    _hoTenCtrl.clear();
    _mssvCtrl.clear();
    _emailCtrl.clear();
    _ngaySinhCtrl.clear();
    setState(() {
      _monHoc = null;
      _heDaoTao = 'Chính quy';
      _buoiDaChon.clear();
      _nhanThongBao = true;
      _soTinChi = 15;
      _ngaySinh = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab F3 – Đăng ký học phần'),
        backgroundColor: scheme.primaryContainer,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction, // báo lỗi ngay khi gõ
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _hoTenCtrl,
                textInputAction: TextInputAction.next,
                maxLength: 50, // NC3: Flutter tự hiện bộ đếm "x/50" dưới ô
                decoration: const InputDecoration(
                  labelText: 'Họ và tên *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: _kiemTraHoTen,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mssvCtrl,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z]')), // chỉ chữ và số
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: 'Mã số sinh viên *',
                  prefixIcon: Icon(Icons.badge_outlined),
                  helperText: 'Gồm đúng 10 ký tự chữ hoặc số (ví dụ 231A290134)',
                ),
                validator: _kiemTraMssv,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: _kiemTraEmail,
              ),
              const SizedBox(height: 12),

              // NC1: ô ngày sinh chỉ đọc; chạm vào thì mở hộp chọn ngày
              TextFormField(
                controller: _ngaySinhCtrl,
                readOnly: true,
                onTap: _chonNgaySinh,
                decoration: const InputDecoration(
                  labelText: 'Ngày sinh *',
                  hintText: 'dd/MM/yyyy',
                  prefixIcon: Icon(Icons.cake_outlined),
                  suffixIcon: Icon(Icons.calendar_month_outlined),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng chọn ngày sinh' : null,
              ),
              const SizedBox(height: 12),

              // NC4: Dropdown<MonHoc> – value là đối tượng, không còn là chuỗi
              DropdownButtonFormField<MonHoc>(
                // initialValue chỉ đặt giá trị lúc khởi tạo; đổi key để ô được dựng lại
                // khi bấm "Làm lại" (Flutter < 3.35 dùng tham số value thay cho initialValue)
                key: ValueKey(_monHoc?.ma),
                initialValue: _monHoc,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Học phần đăng ký *',
                  prefixIcon: Icon(Icons.menu_book_outlined),
                ),
                items: _monHocs
                    .map((m) => DropdownMenuItem(value: m, child: Text('${m.ma} – ${m.ten}')))
                    .toList(),
                onChanged: (v) => setState(() => _monHoc = v),
                validator: (v) => v == null ? 'Hãy chọn một học phần' : null,
              ),
              // NC4: hiển thị số tín chỉ của học phần vừa chọn
              if (_monHoc != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 12),
                  child: Text(
                    'Học phần này có ${_monHoc!.soTinChi} tín chỉ',
                    style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
                  ),
                ),

              const SizedBox(height: 20),
              Text('Hệ đào tạo', style: Theme.of(context).textTheme.titleMedium),
              // Từ Flutter 3.35, nhóm Radio được quản lý bằng RadioGroup bao ngoài
              RadioGroup<String>(
                groupValue: _heDaoTao,
                onChanged: (v) => setState(() => _heDaoTao = v ?? 'Chính quy'),
                child: const Column(
                  children: [
                    RadioListTile<String>(
                      value: 'Chính quy',
                      title: Text('Chính quy'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<String>(
                      value: 'Vừa làm vừa học',
                      title: Text('Vừa làm vừa học'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              // NC2: nhắc người dùng ngay khi chọn hệ cần ràng buộc
              if (_heDaoTao == 'Vừa làm vừa học')
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Lưu ý: hệ này bắt buộc chọn buổi Tối',
                    style: TextStyle(color: scheme.tertiary),
                  ),
                ),

              const SizedBox(height: 8),
              Text('Buổi học mong muốn (chọn ≥ 1)',
                  style: Theme.of(context).textTheme.titleMedium),
              ..._buoiHocs.map((b) => CheckboxListTile(
                    value: _buoiDaChon.contains(b),
                    title: Text(b),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (chon) => setState(() {
                      if (chon == true) {
                        _buoiDaChon.add(b);
                      } else {
                        _buoiDaChon.remove(b);
                      }
                    }),
                  )),

              const SizedBox(height: 8),
              Text('Số tín chỉ đăng ký: ${_soTinChi.round()}',
                  style: Theme.of(context).textTheme.titleMedium),
              Slider(
                value: _soTinChi,
                min: 10,
                max: 24,
                divisions: 14,
                label: '${_soTinChi.round()}',
                onChanged: (v) => setState(() => _soTinChi = v),
              ),

              SwitchListTile(
                value: _nhanThongBao,
                title: const Text('Nhận thông báo qua email'),
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => _nhanThongBao = v),
              ),

              const SizedBox(height: 16),
              FilledButton(
                onPressed: _dangKy,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('ĐĂNG KÝ'),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: _lamLai, child: const Text('Làm lại')),
            ],
          ),
        ),
      ),
    );
  }
}
