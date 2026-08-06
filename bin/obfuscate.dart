#!/usr/bin/env dart

import 'dart:convert';
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
      help: 'Key for XOR method (0-255) or custom mapping (JSON string)',
    )
    ..addFlag('decode', abbr: 'd', help: 'Decode instead of encode')
    ..addOption('input', abbr: 'i', help: 'Input text (or use stdin)')
    ..addOption('output', abbr: 'o', help: 'Output file (or use stdout)')
    ..addFlag(
      'token',
      help: 'Treat --key mapping as a TokenSubstitutionCodec (1 char -> '
          'word) instead of SubstitutionCodec (1 char -> 1 char)',
    )
    ..addFlag('strict', help: 'Throw on unmapped characters (custom method)')
    ..addFlag('help', abbr: 'h', help: 'Show help information');

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      showHelp(parser);
      return;
    }

    final method = results['method'] as String;
    final decode = results['decode'] as bool;
    final token = results['token'] as bool;
    final strict = results['strict'] as bool;

    String input;
    if (results['input'] != null) {
      input = results['input'] as String;
    } else if (results.rest.isNotEmpty) {
      input = results.rest.join(' ');
    } else {
      input = stdin.readLineSync() ?? '';
    }

    if (input.isEmpty) {
      print('Error: No input provided');
      exit(1);
    }

    String output;

    try {
      switch (method) {
        case 'base64':
          const codec = Base64ObfuscationCodec();
          output = decode ? codec.deobfuscate(input) : codec.obfuscate(input);
          break;

        case 'rot13':
          const codec = Rot13Codec();
          output = decode ? codec.deobfuscate(input) : codec.obfuscate(input);
          break;

        case 'xor':
          final key = int.tryParse(results['key'] ?? '');
          if (key == null) {
            print('Error: XOR method requires an integer key 0-255 (--key)');
            exit(1);
          }
          final codec = XorCodec(key);
          output = decode ? codec.deobfuscate(input) : codec.obfuscate(input);
          break;

        case 'reverse':
          const codec = ReverseCodec();
          output = decode ? codec.deobfuscate(input) : codec.obfuscate(input);
          break;

        case 'custom':
          final keyStr = results['key'] as String?;
          if (keyStr == null) {
            print('Error: Custom method requires a mapping key (--key)');
            print('Example: --key \'{"a":"x","b":"y"}\'');
            exit(1);
          }

          final Map<String, String> customMap;
          try {
            final decoded = jsonDecode(keyStr) as Map<String, dynamic>;
            customMap = decoded.map((k, v) => MapEntry(k, v.toString()));
          } catch (e) {
            print('Error parsing custom mapping JSON: $e');
            exit(1);
          }

          final ObfuscationMethod codec = token
              ? TokenSubstitutionCodec(customMap)
              : SubstitutionCodec(customMap, strict: strict);

          output = decode ? codec.deobfuscate(input) : codec.obfuscate(input);
          break;

        default:
          print('Error: Unknown method $method');
          exit(1);
      }
    } on ObfuscationException catch (e) {
      print('Error: ${e.message}');
      exit(1);
    }

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
  print('  obfuscate -m custom --token -k \'{"a":"apple","b":"box"}\' "ab"');
  print('  echo "Hello" | obfuscate -m reverse');
  print('  obfuscate -m base64 -i input.txt -o output.txt');
}
