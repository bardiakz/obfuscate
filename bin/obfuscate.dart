#!/usr/bin/env dart

import 'dart:io';
import 'package:args/args.dart';
import 'package:obfuscate/obfuscate.dart';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption(
      'method',
      abbr: 'm',
      allowed: ['base64', 'rot13', 'xor', 'reverse', 'custom'],
      defaultsTo: 'base64',
      help: 'Obfuscation method to use',
    )
    ..addOption(
      'key',
      abbr: 'k',
      help: 'Key for XOR method (integer) or custom mapping (JSON string)',
    )
    ..addFlag('decode', abbr: 'd', help: 'Decode instead of encode')
    ..addOption('input', abbr: 'i', help: 'Input text (or use stdin)')
    ..addOption('output', abbr: 'o', help: 'Output file (or use stdout)')
    ..addFlag('preserve-case', help: 'Preserve case for custom mapping')
    ..addFlag(
      'preserve-unmapped',
      help: 'Preserve unmapped characters for custom mapping',
    )
    ..addFlag('help', abbr: 'h', help: 'Show help information');

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      showHelp(parser);
      return;
    }

    final method = results['method'] as String;
    final decode = results['decode'] as bool;
    final preserveCase = results['preserve-case'] as bool;
    final preserveUnmapped = results['preserve-unmapped'] as bool;

    String input;
    if (results['input'] != null) {
      input = results['input'] as String;
    } else if (results.rest.isNotEmpty) {
      // Use remaining arguments as input text
      input = results.rest.join(' ');
    } else {
      // Read from stdin
      input = stdin.readLineSync() ?? '';
    }

    if (input.isEmpty) {
      print('Error: No input provided');
      exit(1);
    }

    String output;

    switch (method) {
      case 'base64':
        output = decode
            ? Obfuscate.deobfuscateBase64(input)
            : Obfuscate.obfuscateBase64(input);
        break;

      case 'rot13':
        output = decode
            ? Obfuscate.deobfuscateROT13(input)
            : Obfuscate.obfuscateROT13(input);
        break;

      case 'xor':
        final key = int.tryParse(results['key'] ?? '');
        if (key == null) {
          print('Error: XOR method requires an integer key (--key)');
          exit(1);
        }
        output = decode
            ? Obfuscate.deobfuscateXOR(input, key)
            : Obfuscate.obfuscateXOR(input, key);
        break;

      case 'reverse':
        output = decode
            ? Obfuscate.deobfuscateReverse(input)
            : Obfuscate.obfuscateReverse(input);
        break;

      case 'custom':
        final keyStr = results['key'] as String?;
        if (keyStr == null) {
          print('Error: Custom method requires a mapping key (--key)');
          print('Example: --key \'{"a":"x","b":"y"}\'');
          exit(1);
        }

        try {
          // Simple JSON parsing for custom mapping
          final Map<String, String> customMap = parseCustomMapping(keyStr);
          output = decode
              ? Obfuscate.deobfuscateWithMap(input, customMap)
              : Obfuscate.obfuscateWithMap(
                  input,
                  customMap,
                  preserveCase: preserveCase,
                  preserveUnmapped: preserveUnmapped,
                );
        } catch (e) {
          print('Error parsing custom mapping: $e');
          exit(1);
        }
        break;

      default:
        print('Error: Unknown method $method');
        exit(1);
    }

    // Output result
    if (results['output'] != null) {
      final file = File(results['output'] as String);
      file.writeAsStringSync(output);
      print('Output written to ${results['output']}');
    } else {
      print(output);
    }
  } catch (e) {
    print('Error: $e');
    print('\nUse --help for usage information');
    exit(1);
  }
}

void showHelp(ArgParser parser) {
  print('Obfuscate - Text obfuscation CLI tool\n');
  print('Usage: obfuscate [options] <text>');
  print('   or: obfuscate [options] -i <file>');
  print('   or: echo "text" | obfuscate [options]');
  print('\nOptions:');
  print(parser.usage);
  print('\nExamples:');
  print('  obfuscate -m base64 "Hello World"');
  print('  obfuscate -m rot13 -d "Uryyb Jbeyq"');
  print('  obfuscate -m xor -k 123 "Secret text"');
  print('  obfuscate -m custom -k \'{"a":"x","e":"y"}\' "Hello"');
  print('  echo "Hello" | obfuscate -m reverse');
  print('  obfuscate -m base64 -i input.txt -o output.txt');
}

Map<String, String> parseCustomMapping(String jsonStr) {
  // Simple JSON parsing - you might want to use a proper JSON parser
  // For now, this handles basic {"key":"value"} format
  final cleaned = jsonStr.trim();
  if (!cleaned.startsWith('{') || !cleaned.endsWith('}')) {
    throw FormatException('Invalid JSON format');
  }

  final Map<String, String> result = {};
  final content = cleaned.substring(1, cleaned.length - 1);
  final pairs = content.split(',');

  for (final pair in pairs) {
    final parts = pair.split(':');
    if (parts.length != 2) continue;

    final key = parts[0].trim().replaceAll('"', '');
    final value = parts[1].trim().replaceAll('"', '');
    result[key] = value;
  }

  return result;
}
