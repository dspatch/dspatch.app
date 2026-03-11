import 'package:re_highlight/languages/bash.dart';
import 'package:re_highlight/languages/c.dart';
import 'package:re_highlight/languages/cpp.dart';
import 'package:re_highlight/languages/csharp.dart';
import 'package:re_highlight/languages/css.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:re_highlight/languages/diff.dart';
import 'package:re_highlight/languages/dockerfile.dart';
import 'package:re_highlight/languages/go.dart';
import 'package:re_highlight/languages/graphql.dart';
import 'package:re_highlight/languages/groovy.dart';
import 'package:re_highlight/languages/ini.dart';
import 'package:re_highlight/languages/java.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/kotlin.dart';
import 'package:re_highlight/languages/lua.dart';
import 'package:re_highlight/languages/makefile.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/languages/perl.dart';
import 'package:re_highlight/languages/php.dart';
import 'package:re_highlight/languages/plaintext.dart';
import 'package:re_highlight/languages/powershell.dart';
import 'package:re_highlight/languages/properties.dart';
import 'package:re_highlight/languages/protobuf.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/languages/ruby.dart';
import 'package:re_highlight/languages/rust.dart';
import 'package:re_highlight/languages/scala.dart';
import 'package:re_highlight/languages/scss.dart';
import 'package:re_highlight/languages/shell.dart';
import 'package:re_highlight/languages/sql.dart';
import 'package:re_highlight/languages/swift.dart';
import 'package:re_highlight/languages/typescript.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/languages/yaml.dart';
import 'package:re_highlight/re_highlight.dart';

/// Curated map of re_highlight language keys to their [Mode] definitions.
final Map<String, Mode> kSupportedLanguageModes = {
  'bash': langBash,
  'c': langC,
  'cpp': langCpp,
  'csharp': langCsharp,
  'css': langCss,
  'dart': langDart,
  'diff': langDiff,
  'dockerfile': langDockerfile,
  'go': langGo,
  'graphql': langGraphql,
  'groovy': langGroovy,
  'ini': langIni,
  'java': langJava,
  'javascript': langJavascript,
  'json': langJson,
  'kotlin': langKotlin,
  'lua': langLua,
  'makefile': langMakefile,
  'markdown': langMarkdown,
  'perl': langPerl,
  'php': langPhp,
  'plaintext': langPlaintext,
  'powershell': langPowershell,
  'properties': langProperties,
  'protobuf': langProtobuf,
  'python': langPython,
  'ruby': langRuby,
  'rust': langRust,
  'scala': langScala,
  'scss': langScss,
  'shell': langShell,
  'sql': langSql,
  'swift': langSwift,
  'typescript': langTypescript,
  'xml': langXml,
  'yaml': langYaml,
};

/// Maps file extensions (with leading dot) to re_highlight language keys.
const Map<String, String> kExtensionToLanguage = {
  '.bash': 'bash',
  '.c': 'c',
  '.cc': 'cpp',
  '.cfg': 'ini',
  '.conf': 'ini',
  '.cpp': 'cpp',
  '.cs': 'csharp',
  '.css': 'css',
  '.cxx': 'cpp',
  '.dart': 'dart',
  '.diff': 'diff',
  '.dockerfile': 'dockerfile',
  '.go': 'go',
  '.gql': 'graphql',
  '.gradle': 'groovy',
  '.graphql': 'graphql',
  '.groovy': 'groovy',
  '.h': 'c',
  '.hpp': 'cpp',
  '.htm': 'xml',
  '.html': 'xml',
  '.ini': 'ini',
  '.java': 'java',
  '.js': 'javascript',
  '.json': 'json',
  '.jsonc': 'json',
  '.jsx': 'javascript',
  '.kt': 'kotlin',
  '.kts': 'kotlin',
  '.lock': 'json',
  '.lua': 'lua',
  '.m': 'c',
  '.md': 'markdown',
  '.mk': 'makefile',
  '.patch': 'diff',
  '.php': 'php',
  '.pl': 'perl',
  '.pm': 'perl',
  '.properties': 'properties',
  '.proto': 'protobuf',
  '.ps1': 'powershell',
  '.py': 'python',
  '.pyi': 'python',
  '.pyw': 'python',
  '.rb': 'ruby',
  '.rs': 'rust',
  '.sass': 'scss',
  '.sc': 'scala',
  '.scala': 'scala',
  '.scss': 'scss',
  '.sh': 'bash',
  '.sql': 'sql',
  '.swift': 'swift',
  '.toml': 'ini',
  '.ts': 'typescript',
  '.tsx': 'typescript',
  '.txt': 'plaintext',
  '.xml': 'xml',
  '.yaml': 'yaml',
  '.yml': 'yaml',
  '.zsh': 'bash',
};

/// Maps special filenames (lowercase) to re_highlight language keys.
const Map<String, String> kFilenameToLanguage = {
  'dockerfile': 'dockerfile',
  'makefile': 'makefile',
  'gemfile': 'ruby',
  'rakefile': 'ruby',
  '.gitignore': 'ini',
  '.dockerignore': 'ini',
  '.editorconfig': 'ini',
  '.env': 'ini',
  '.env.local': 'ini',
  '.bashrc': 'bash',
  '.bash_profile': 'bash',
  '.zshrc': 'bash',
  '.profile': 'bash',
};

/// Detects a language key from a filename.
///
/// Returns the re_highlight language key (e.g. `'python'`, `'json'`), or
/// `null` if the language cannot be determined. A non-null return value is
/// guaranteed to exist in [kSupportedLanguageModes].
String? languageFromFilename(String filename) {
  final lower = filename.toLowerCase();

  // Check exact filename matches first.
  final byName = kFilenameToLanguage[lower];
  if (byName != null && kSupportedLanguageModes.containsKey(byName)) {
    return byName;
  }

  // Check extension.
  final dotIndex = lower.lastIndexOf('.');
  if (dotIndex == -1) return null;
  final ext = lower.substring(dotIndex);
  final lang = kExtensionToLanguage[ext];
  if (lang != null && kSupportedLanguageModes.containsKey(lang)) {
    return lang;
  }

  return null;
}
