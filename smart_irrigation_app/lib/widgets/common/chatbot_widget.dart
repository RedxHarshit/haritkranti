import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../constants/colors.dart';
import '../../providers/irrigation_provider.dart';
import '../../providers/language_provider.dart';

class ChatbotWidget extends StatefulWidget {
  const ChatbotWidget({super.key});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget> with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _animation;
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _currentIsHindi = false;
  
  static final String _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? 'default_fallback_key';
  late GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    
    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: _geminiApiKey,
    );
    
    // Initialize with current language
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isHindi = context.read<LanguageProvider>().isHindi;
      _currentIsHindi = isHindi;
      _addWelcomeMessage(isHindi);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageProvider = context.watch<LanguageProvider>();
    if (languageProvider.isHindi != _currentIsHindi) {
      _currentIsHindi = languageProvider.isHindi;
      setState(() {
        _messages.clear();
        _addWelcomeMessage(_currentIsHindi);
      });
    }
  }

  void _addWelcomeMessage(bool isHindi) {
    _messages.add(ChatMessage(
      text: isHindi 
        ? "नमस्ते! मैं आपका स्मार्ट कृषि सहायक हूं। मिट्टी की नमी, सिंचाई, मौसम या किसी भी कृषि प्रश्न के बारे में पूछें!"
        : "Hello! I'm your smart farming assistant. Ask me about soil moisture, irrigation, weather, or any farming questions!",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isExpanded) _buildChatWindow(),
          const SizedBox(height: 12),
          _buildChatButton(),
        ],
      ),
    );
  }

  Widget _buildChatButton() {
    return FloatingActionButton(
      onPressed: () {
        setState(() {
          _isExpanded = !_isExpanded;
          if (_isExpanded) {
            _controller.forward();
          } else {
            _controller.reverse();
          }
        });
      },
      backgroundColor: AppColors.primaryGreen,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          _isExpanded ? Icons.close : Icons.chat,
          key: ValueKey(_isExpanded),
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildChatWindow() {
    final isHindi = context.watch<LanguageProvider>().isHindi;

    return SizeTransition(
      sizeFactor: _animation,
      axisAlignment: -1.0,
      child: Container(
        width: 300,
        height: 420,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.agriculture, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    isHindi ? 'फार्म सहायक' : 'Farm Assistant',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
              ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 8),
                    Text(isHindi ? 'AI सोच रहा है...' : 'AI is thinking...'),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.black12))),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: isHindi ? 'खेत के बारे में पूछें...' : 'Ask about your farm...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _sendMessage(_messageController.text),
                    icon: Icon(Icons.send, color: AppColors.primaryGreen),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primaryGreen : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: message.isUser ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _messageController.clear();
      _isLoading = true;
    });

    try {
      final response = await _getGeminiResponse(text);
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false, timestamp: DateTime.now()));
        _isLoading = false;
      });
    } catch (e) {
      final isHindi = context.read<LanguageProvider>().isHindi;
      setState(() {
        String errorMsg = isHindi 
          ? 'क्षमा करें, कुछ गलत हुआ।'
          : 'Sorry, I encountered an error.';
        if (e.toString().contains('API key')) {
          errorMsg = isHindi 
            ? 'कृपया अपना API key कॉन्फ़िगरेशन जांचें।'
            : 'Please check your API key configuration.';
        }
        _messages.add(ChatMessage(text: errorMsg, isUser: false, timestamp: DateTime.now()));
        _isLoading = false;
      });
    }
  }

  Future<String> _getGeminiResponse(String userMessage) async {
    final irrigationProvider = Provider.of<IrrigationProvider>(context, listen: false);
    final isHindi = context.read<LanguageProvider>().isHindi;
    final data = irrigationProvider.currentData;

    final zonesContext = data.zones.map((z) =>
      '- ${z.name} (${z.cropType}): ${z.soilMoisture.toStringAsFixed(0)}% (optimal ${z.optimalMoistureMin.toStringAsFixed(0)}-${z.optimalMoistureMax.toStringAsFixed(0)}%), ${z.isActive ? "ON" : "OFF"}'
    ).join('\n');

    final prompt = '''
You are an AI assistant for a smart irrigation system. ${isHindi ? 'Please respond in Hindi language.' : 'Please respond in English language.'} Here's the current farm data:
- Battery Level: ${data.batteryLevel.toStringAsFixed(0)}%
- Upper Tank Level: ${data.upperTankLevel.toStringAsFixed(0)}%
- Lower Tank Level: ${data.lowerTankLevel.toStringAsFixed(0)}%
- Irrigation Status: ${irrigationProvider.irrigationEnabled ? 'ON' : 'OFF'}
- Zones:
$zonesContext

User question: $userMessage

Please provide helpful farming advice based on this data. Keep responses concise and practical. ${isHindi ? 'Respond only in Hindi language.' : 'Respond only in English language.'}
''';

    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    
    return response.text ?? (isHindi ? 'कोई जवाब नहीं मिला' : 'No response generated');
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}
