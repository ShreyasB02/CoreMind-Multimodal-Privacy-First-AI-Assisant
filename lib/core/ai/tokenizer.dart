
class SimpleTokenizer {
  // Basic vocabulary for proof-of-concept
  static final Map<String, int> _vocabulary = {
    '<pad>': 0,
    '<unk>': 1,
    '<start>': 2,
    '<end>': 3,
    // Common words
    'the': 4, 'a': 5, 'an': 6, 'and': 7, 'or': 8, 'but': 9, 'in': 10,
    'on': 11, 'at': 12, 'to': 13, 'for': 14, 'of': 15, 'with': 16,
    'by': 17, 'from': 18, 'about': 19, 'into': 20, 'through': 21,
    'during': 22, 'before': 23, 'after': 24, 'above': 25, 'below': 26,
    'up': 27, 'down': 28, 'out': 29, 'off': 30, 'over': 31, 'under': 32,
    // Common action words
    'remember': 33, 'save': 34, 'recall': 35, 'open': 36, 'close': 37,
    'play': 38, 'stop': 39, 'start': 40, 'end': 41, 'help': 42,
    'what': 43, 'when': 44, 'where': 45, 'why': 46, 'how': 47,
    'who': 48, 'which': 49, 'time': 50, 'date': 51, 'weather': 52,
    // Add more words as needed
  };

  static final Map<int, String> _reverseVocabulary =
  Map.fromEntries(_vocabulary.entries.map((e) => MapEntry(e.value, e.key)));

  static const int maxSequenceLength = 128;
  static const int unknownToken = 1;
  static const int padToken = 0;

  static List<int> encode(String text) {
    // Simple whitespace tokenization + vocabulary lookup
    List<String> words = text.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();

    List<int> tokens = [2]; // Start token

    for (String word in words) {
      int tokenId = _vocabulary[word] ?? unknownToken;
      tokens.add(tokenId);
    }

    tokens.add(3); // End token

    // Pad or truncate to max length
    if (tokens.length > maxSequenceLength) {
      tokens = tokens.sublist(0, maxSequenceLength);
    } else {
      while (tokens.length < maxSequenceLength) {
        tokens.add(padToken);
      }
    }

    return tokens;
  }

  static String decode(List<int> tokens) {
    return tokens
        .where((token) => token != padToken && token != 2 && token != 3)
        .map((token) => _reverseVocabulary[token] ?? '<unk>')
        .join(' ');
  }

  static int get vocabularySize => _vocabulary.length;
}
