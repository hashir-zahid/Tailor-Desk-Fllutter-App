class Validators {
  static String? requiredField(String? v) {
    return (v == null || v.isEmpty) ? "Required field" : null;
  }

  static String? email(String? v) {
    if (v == null || v.isEmpty) return "Email is required";

    final emailReg = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailReg.hasMatch(v)) {
      return "Invalid email";
    }
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return "Password is required";
    if (v.length < 6) return "Password must be at least 6 characters";
    return null;
  }

  static String? confirmPassword(String? v, String password) {
    if (v == null || v.isEmpty) return "Please confirm your password";
    if (v != password) return "Passwords don't match";
    return null;
  }
}