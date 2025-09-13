# Obfuscate

🔐 **text obfuscation toolkit** with both CLI and library support.

Obfuscate your text data using multiple obfuscation methods including custom character mapping, classic ciphers, and encoding techniques.

## Features

- **🖥️ CLI Tool**: Ready-to-use command-line interface for quick text obfuscation
- **📚 Dart Library**: Integrate seamlessly into your Dart/Flutter projects
- **🔀 Multiple Methods**:
    - **Base64 Encoding**: Standard Base64 text encoding/decoding
    - **ROT13 Cipher**: Classic letter substitution cipher
    - **XOR Cipher**: Bitwise XOR encryption with custom keys
    - **String Reversal**: Simple character order reversal
    - **Custom Mapping**: Define your own character substitution rules
- **⚙️ Flexible Options**:
    - Preserve original character case
    - Handle unmapped characters gracefully
    - Support for stdin/stdout and file I/O
    - JSON-based custom mapping definitions

### Global CLI Installation:
```bash
dart pub global activate obfuscate