import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controls/news_button.dart';

class ManageKeywordWidget extends StatefulWidget {
  const ManageKeywordWidget({super.key});

  @override
  State<ManageKeywordWidget> createState() => _ManageKeywordWidgetState();
}

class _ManageKeywordWidgetState extends State<ManageKeywordWidget> {
  final List<String> _keywords = [];
  final _controller = TextEditingController();
  static const String _prefsKey = 'saved_keywords';

  bool _isLoading = true;
  bool _isAddingKeyword = false; // キーワード入力フィールドの表示制御
  bool _isEditingKeyword = false; // 編集モードの制御

  final FocusNode _textFieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadKeywords();
  }

  @override
  void dispose() {
    _controller.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadKeywords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      setState(() {
        _keywords.addAll(prefs.getStringList(_prefsKey) ?? []);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveKeywords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _keywords);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      child: Column(
        children: [
          // タイトル + ボタンエリア

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'キーワード',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    // キーワード入力フィールドを表示する「登録」ボタン
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isAddingKeyword = !_isAddingKeyword;
                        });

                        // true になったタイミングでフォーカスを当てる
                        if (_isAddingKeyword) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            FocusScope.of(context)
                                .requestFocus(_textFieldFocusNode);
                          });
                        }
                      },
                      child: Text(_isAddingKeyword ? 'キャンセル' : '登録'),
                    ),
                    const SizedBox(width: 8),
                    // 編集モードを切り替えるボタン
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isEditingKeyword = !_isEditingKeyword;
                        });
                      },
                      child: Text(_isEditingKeyword ? '終了' : '編集'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // キーワード入力フィールド
          if (_isAddingKeyword)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _textFieldFocusNode,
                      decoration: const InputDecoration(
                        labelText: 'キーワードを入力',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_controller.text.isNotEmpty) {
                        setState(() {
                          _keywords.add(_controller.text);
                          _controller.clear();
                          _isAddingKeyword = false; // フィールドを閉じる
                        });
                        _saveKeywords();
                      }
                    },
                    child: const Text('追加'),
                  ),
                ],
              ),
            ),

          // 登録済みキーワード一覧
          Column(
            crossAxisAlignment: CrossAxisAlignment.start, // 必要に応じて調整
            children: _keywords.map((keyword) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10.0), // ボタン間の余白を設定
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ニュースを開くボタン (NewsButton) として使う
                    NewsButton(keyword: keyword),
                    const SizedBox(width: 4),
                    // 削除ボタン (×マーク) は 編集モードのときだけ表示
                    Visibility(
                      visible: _isEditingKeyword,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _keywords.remove(keyword);
                          });
                          _saveKeywords();
                        },
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }
}
