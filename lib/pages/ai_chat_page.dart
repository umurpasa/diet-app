import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIChatPage extends StatefulWidget {
  @override
  _AIChatPageState createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String _userInfo = "";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    // Hoşgeldin mesajı
    _messages.add(
      ChatMessage(
        text: "Merhaba! Ben senin beslenme ve diyet danışmanınım. "
            "Beslenme, diyet veya sağlıklı yaşam hakkında sorularını yanıtlayabilirim.",
        isUser: false,
      ),
    );
  }

  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String age = prefs.getString('age') ?? "Unknown";
    String height = prefs.getString('height') ?? "Unknown";
    String weight = prefs.getString('weight') ?? "Unknown";
    String goal = prefs.getString('goal') ?? "Unknown";
    String allergies = prefs.getString('allergies') ?? "None";

    setState(() {
      _userInfo =
          "Age: $age, Height: $height cm, Weight: $weight kg, Goal: $goal, Allergies: $allergies";
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String message = _messageController.text;
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(text: message, isUser: true));
      _isTyping = true;
    });

    // Scroll to bottom
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    // Create context-aware prompt with user profile info
    String contextPrompt =
        "User profile: $_userInfo\n\nUser question: $message";

    try {
      String response = await _aiService.generateDietAdvice(contextPrompt);

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(text: response, isUser: false));
          _isTyping = false;
        });

        // Scroll to bottom again after receiving response
        Future.delayed(Duration(milliseconds: 100), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
              text:
                  "Üzgünüm, yanıt oluşturulurken bir hata oluştu. Lütfen tekrar deneyin.",
              isUser: false));
          _isTyping = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return TypingIndicator();
                }
                return _messages[index];
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black12,
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Bir soru sor...",
                      border: InputBorder.none,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(Colors.green, Icons.health_and_safety),
          SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).primaryColor.withOpacity(0.2)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                text,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          SizedBox(width: 10),
          if (isUser)
            _buildAvatar(Theme.of(context).primaryColor, Icons.person),
        ],
      ),
    );
  }

  Widget _buildAvatar(Color color, IconData icon) {
    return CircleAvatar(
      backgroundColor: color,
      child: Icon(
        icon,
        color: Colors.white,
      ),
    );
  }
}

class TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(Colors.green, Icons.health_and_safety),
          SizedBox(width: 10),
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                _buildDot(300),
                SizedBox(width: 2),
                _buildDot(600),
                SizedBox(width: 2),
                _buildDot(900),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Color color, IconData icon) {
    return CircleAvatar(
      backgroundColor: color,
      child: Icon(
        icon,
        color: Colors.white,
      ),
    );
  }

  Widget _buildDot(int milliseconds) {
    return AnimatedContainer(
      duration: Duration(milliseconds: milliseconds),
      decoration: BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
      height: 6,
      width: 6,
    );
  }
}
