class L10n {
  static final Map<String, Map<String, String>> _translations = {
    'ja': {
      'appTitle': 'FreshBiz',
      'login': 'ログイン',
      'home': 'ホーム',
      'categories': '分類',
      'cart': 'カート',
      'myPage': 'マイページ',
    },
    'zh': {
      'appTitle': 'FreshBiz',
      'login': '登录',
      'home': '首页',
      'categories': '分类',
      'cart': '购物车',
      'myPage': '我的',
    },
  };

  static String t(String locale, String key) {
    return _translations[locale]?[key] ?? _translations['ja']?[key] ?? key;
  }
}