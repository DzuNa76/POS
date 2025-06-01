class Validators {
  static String? emailValidator(String? value) {
    if (value == null || value.isEmpty) return "Email tidak boleh kosong";
    if (!value.contains('@')) return "Email harus mengandung '@'";
    return null;
  }

  static String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) return "Password tidak boleh kosong";
    if (value.length < 6) return "Password minimal 6 karakter";
    return null;
  }
}
