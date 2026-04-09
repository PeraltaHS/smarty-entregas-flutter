import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Serviço de criptografia de senhas usando PBKDF2-HMAC-SHA256.
///
/// Não depende de pacotes externos além do [crypto] que já está no pubspec.
///
/// Formato armazenado no banco:
///   `pbkdf2$ITERACOES$SALT_HEX$HASH_HEX`
///
/// Exemplo:
///   `pbkdf2$100000$a3f1...bc$9e2c...41`
class CryptoService {
  // OWASP 2024 recomenda ≥ 210.000 para PBKDF2-SHA256;
  // usamos 100.000 para equilibrar segurança e latência em dev.
  static const int _iterations  = 100000;
  static const int _keyBytes    = 32; // 256 bits
  static const int _saltBytes   = 32; // 256 bits

  // ── API pública ───────────────────────────────────────────────────────────

  /// Gera o hash seguro de [password].
  /// Retorna a string completa para armazenar no banco.
  static String hashPassword(String password) {
    final salt = _randomBytes(_saltBytes);
    final hash = _pbkdf2(_toBytes(password), salt, _iterations, _keyBytes);
    return 'pbkdf2\$$_iterations\$${_hex(salt)}\$${_hex(hash)}';
  }

  /// Retorna true se [password] corresponde ao [storedHash].
  ///
  /// Usa comparação em tempo constante para evitar timing attacks.
  /// Retorna false silenciosamente se o formato for inválido.
  static bool verifyPassword(String password, String storedHash) {
    final parts = storedHash.split('\$');
    if (parts.length != 4 || parts[0] != 'pbkdf2') return false;

    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations <= 0) return false;

    final Uint8List salt;
    final Uint8List expected;
    try {
      salt     = _unhex(parts[2]);
      expected = _unhex(parts[3]);
    } catch (_) {
      return false;
    }

    final computed = _pbkdf2(
        _toBytes(password), salt, iterations, expected.length);

    return _constantTimeEqual(computed, expected);
  }

  // ── PBKDF2-HMAC-SHA256 (RFC 2898) ────────────────────────────────────────

  static Uint8List _pbkdf2(
      List<int> password, Uint8List salt, int c, int dkLen) {
    final hmac   = Hmac(sha256, password);
    final output = <int>[];
    var   block  = 1;

    while (output.length < dkLen) {
      output.addAll(_pbkdf2Block(hmac, salt, c, block));
      block++;
    }

    return Uint8List.fromList(output.take(dkLen).toList());
  }

  /// Calcula um bloco Ti = U1 XOR U2 XOR ... XOR Uc
  static List<int> _pbkdf2Block(
      Hmac hmac, Uint8List salt, int c, int i) {
    // salt || INT(i) — inteiro big-endian de 4 bytes
    final msg = Uint8List(salt.length + 4);
    msg.setRange(0, salt.length, salt);
    msg[salt.length]     = (i >> 24) & 0xFF;
    msg[salt.length + 1] = (i >> 16) & 0xFF;
    msg[salt.length + 2] = (i >>  8) & 0xFF;
    msg[salt.length + 3] =  i        & 0xFF;

    var u      = hmac.convert(msg).bytes;
    final t    = List<int>.from(u);

    for (int iter = 1; iter < c; iter++) {
      u = hmac.convert(u).bytes;
      for (int j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }

    return t;
  }

  // ── Utilitários ───────────────────────────────────────────────────────────

  static Uint8List _randomBytes(int n) {
    final rng = Random.secure();
    return Uint8List.fromList(
        List.generate(n, (_) => rng.nextInt(256)));
  }

  static List<int> _toBytes(String s) {
    // Converte para UTF-8 sem importar dart:convert no call-site
    final list = <int>[];
    for (final unit in s.codeUnits) {
      if (unit < 0x80) {
        list.add(unit);
      } else if (unit < 0x800) {
        list
          ..add(0xC0 | (unit >> 6))
          ..add(0x80 | (unit & 0x3F));
      } else {
        list
          ..add(0xE0 | (unit >> 12))
          ..add(0x80 | ((unit >> 6) & 0x3F))
          ..add(0x80 | (unit & 0x3F));
      }
    }
    return list;
  }

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static Uint8List _unhex(String hex) {
    if (hex.length.isOdd) throw FormatException('hex length must be even');
    final out = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < out.length; i++) {
      out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  /// Comparação em tempo constante — evita timing attacks.
  static bool _constantTimeEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
