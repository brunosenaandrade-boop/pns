// Utilitarios de validacao para o painel admin

class Validators {
  // Validar CPF com digitos verificadores
  static bool isValidCPF(String cpf) {
    // Remover caracteres nao numericos
    cpf = cpf.replaceAll(RegExp(r'[^\d]'), '');

    // Verificar tamanho
    if (cpf.length != 11) return false;

    // Verificar se todos os digitos sao iguais (invalido)
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;

    // Validar primeiro digito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int firstDigit = (sum * 10) % 11;
    if (firstDigit == 10) firstDigit = 0;
    if (firstDigit != int.parse(cpf[9])) return false;

    // Validar segundo digito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    int secondDigit = (sum * 10) % 11;
    if (secondDigit == 10) secondDigit = 0;
    if (secondDigit != int.parse(cpf[10])) return false;

    return true;
  }

  // Validar email com regex
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      caseSensitive: false,
    );

    return emailRegex.hasMatch(email);
  }

  // Validar telefone brasileiro
  static bool isValidPhone(String phone) {
    // Remover caracteres nao numericos
    phone = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Telefone brasileiro: 10 ou 11 digitos (com DDD)
    // Pode ter +55 no inicio
    if (phone.startsWith('55') && phone.length >= 12) {
      phone = phone.substring(2);
    }

    if (phone.length < 10 || phone.length > 11) return false;

    // Se tem 11 digitos, o nono digito deve ser 9 (celular)
    if (phone.length == 11 && phone[2] != '9') return false;

    return true;
  }

  // Validar CEP
  static bool isValidCEP(String cep) {
    cep = cep.replaceAll(RegExp(r'[^\d]'), '');
    return cep.length == 8;
  }

  // Validar nome completo (pelo menos nome e sobrenome)
  static bool isValidFullName(String name) {
    final parts = name.trim().split(' ');
    return parts.length >= 2 && parts.every((p) => p.isNotEmpty);
  }

  // Mensagens de erro padronizadas
  static String? validateCPF(String? value) {
    if (value == null || value.isEmpty) return null; // CPF opcional
    final cpfDigits = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cpfDigits.isNotEmpty && !isValidCPF(cpfDigits)) {
      return 'CPF invalido';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return null; // Email opcional
    if (!isValidEmail(value)) {
      return 'Email invalido';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Telefone obrigatorio';
    if (!isValidPhone(value)) {
      return 'Telefone invalido';
    }
    return null;
  }

  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) return 'Nome obrigatorio';
    if (!isValidFullName(value)) {
      return 'Digite nome e sobrenome';
    }
    return null;
  }
}
