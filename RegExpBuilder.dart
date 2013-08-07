class RegExpBuilder {
  
  List<String> _literal;
  bool _ignoreCase;
  bool _multiLine;
  HashSet<String> _specialCharactersInsideCharacterClass;
  HashSet<String> _specialCharactersOutsideCharacterClass;
  List<String> _escapedString;
  int _min;
  int _max;
  String _of;
  bool _ofAny;
  int _ofGroup;
  String _from;
  String _notFrom;
  String _like;
  String _behind;
  String _notBehind;
  String _either;
  bool _reluctant;
  bool _capture;
  
  RegExpBuilder() {
    _literal = [];
    _specialCharactersInsideCharacterClass = new HashSet.from([@"^", @"-", @"]"]);
    _specialCharactersOutsideCharacterClass = new HashSet.from([@".", @"^", @"$", @"*", @"+", @"?", @"(", @")", @"[", @"{"]);
    _escapedString = [];
    _clear();
  }
  
  void _clear() {
    _ignoreCase = false;
    _multiLine = false;
    _min = -1;
    _max = -1;
    _of = "";
    _ofAny = false;
    _ofGroup = -1;
    _from = "";
    _notFrom = "";
    _like = "";
    _behind = "";
    _notBehind = "";
    _either = "";
    _reluctant = false;
    _capture = false;
  }
  
  void _flushState() {
    if (_of != "" || _ofAny || _ofGroup > 0 || _from != "" || _notFrom != "" || _like != "") {
      var captureLiteral = _capture ? "" : "?:";
      var quantityLiteral = _getQuantityLiteral();
      var characterLiteral = _getCharacterLiteral();
      var reluctantLiteral = _reluctant ? "?" : "";
      var behindLiteral = _behind != "" ? "(?=$_behind)" : "";
      var notBehindLiteral = _notBehind != "" ? "(?!$_notBehind)" : "";
      _literal.add("($captureLiteral(?:$characterLiteral)$quantityLiteral$reluctantLiteral)$behindLiteral$notBehindLiteral");
      _clear();
    }
  }
  
  String _getQuantityLiteral() {
    if (_min != -1) {
      if (_max != -1) {
        return "{$_min,$_max}";
      }
      return "{$_min,}";
    }
    return "{0,$_max}";
  }
  
  String _getCharacterLiteral() {
    if (_of != "") {
      return _of;
    }
    if (_ofAny) {
      return ".";
    }
    if (_ofGroup > 0) {
      return "\\$_ofGroup";
    }
    if (_from != "") {
      return "[$_from]";
    }
    if (_notFrom != "") {
      return "[^$_notFrom]";
    }
    if (_like != "") {
      return _like;
    }
  }
  
  String getLiteral() {
    _flushState();
    return Strings.concatAll(_literal);
  }
  
  RegExp getRegExp() {
    return new RegExp(getLiteral(), _ignoreCase, _multiLine);
  }
  
  RegExpBuilder ignoreCase() {
    _ignoreCase = true;
    return this;
  }
  
  RegExpBuilder multiLine() {
    _multiLine = true;
    return this;
  }
  
  RegExpBuilder start() {
    _literal.add("(?:^)");
    return this;
  }
  
  RegExpBuilder end() {
    _flushState();
    _literal.add(@"(?:$)");
    return this;
  }
  
  RegExpBuilder either(Function r) {
    _flushState();
    _either = r(new RegExpBuilder()).getLiteral();
    return this;
  }
  
  RegExpBuilder eitherString(String s) {
    return this.either((r) => r.exactly(1).of(s));
  }
  
  RegExpBuilder or(Function r) {
    var either = _either;
    var or = r(new RegExpBuilder()).getLiteral();
    if (either == "") {
      var lastOr = _literal.last();
      _literal[_literal.length - 1] = lastOr.substring(0, lastOr.length - 1);
      _literal.add("|(?:$or))");
    }
    else {
      _literal.add("(?:(?:$either)|(?:$or))");
    }
    _clear();
    return this;
  }
  
  RegExpBuilder orString(String s) {
    return this.or((r) => r.exactly(1).of(s));
  }
  
  RegExpBuilder exactly(int n) {
    _flushState();
    _min = n;
    _max = n;
    return this;
  }
  
  RegExpBuilder min(int n) {
    _flushState();
    _min = n;
    return this;
  }
  
  RegExpBuilder max(int n) {
    _flushState();
    _max = n;
    return this;
  }
  
  RegExpBuilder of(String s) {
    _of = _escapeOutsideCharacterClass(s);
    return this;
  }
  
  RegExpBuilder ofAny() {
    _ofAny = true;
    return this;
  }
  
  RegExpBuilder ofGroup(int n) {
    _ofGroup = n;
    return this;
  }
  
  RegExpBuilder from(List<String> s) {
    _from = _escapeInsideCharacterClass(Strings.concatAll(s));
    return this;
  }
  
  RegExpBuilder notFrom(List<String> s) {
    _notFrom = _escapeInsideCharacterClass(Strings.concatAll(s));
    return this;
  }
  
  RegExpBuilder like(Function r) {
    _like = r(new RegExpBuilder()).getLiteral();
    return this;
  }
  
  RegExpBuilder reluctantly() {
    _reluctant = true;
    return this;
  }
  
  RegExpBuilder behind(Function r) {
    _behind = r(new RegExpBuilder()).getLiteral();
    return this;
  }
  
  RegExpBuilder notBehind(Function r) {
    _notBehind = r(new RegExpBuilder()).getLiteral();
    return this;
  }
  
  RegExpBuilder asGroup() {
    _capture = true;
    return this;
  }
  
  RegExpBuilder then(String s) {
    return exactly(1).of(s);
  }
  
  RegExpBuilder some(List<String> s) {
    return min(1).from(s);
  }
  
  RegExpBuilder maybe(String s) {
    return max(1).of(s);
  }
  
  String _escapeInsideCharacterClass(String s) {
    return _escapeSpecialCharacters(s, _specialCharactersInsideCharacterClass);
  }

  String _escapeOutsideCharacterClass(String s) {
    return _escapeSpecialCharacters(s, _specialCharactersOutsideCharacterClass);
  }
  
  String _escapeSpecialCharacters(String s, Set<String> specialCharacters) {
    _escapedString.clear();
    for (var i = 0; i < s.length; i++) {
      var character = s[i];
      if (specialCharacters.contains(character)) {
        _escapedString.add("\\$character");
      }
      else {
        _escapedString.add(character);
      }
    }
    return Strings.concatAll(_escapedString);
  }
}
