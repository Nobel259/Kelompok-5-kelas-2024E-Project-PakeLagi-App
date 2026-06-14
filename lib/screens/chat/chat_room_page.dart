import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../core/api_config.dart';
import '../../screens/seller/seller_profile_page.dart';

class ChatRoomPage extends StatefulWidget {
  final int receiverId;
  final String receiverName;
  final String? profilePictureUrl;

  const ChatRoomPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.profilePictureUrl,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final List<dynamic> _messages = [];
  bool _isLoading = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollingTimer;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _fetchMessages();

    // Start polling every 3 seconds to get new messages
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchMessages(isSilent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('user_id');
    });
  }

  Future<void> _fetchMessages({bool isSilent = false}) async {
    if (!isSilent) {
      setState(() => _isLoading = true);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/chats/${widget.receiverId}'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newMessages = data['data'] ?? [];

        if (newMessages.length != _messages.length) {
          setState(() {
            _messages.clear();
            _messages.addAll(newMessages);
          });
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToBottom(),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    } finally {
      if (!isSilent) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    // Optimistic UI update
    final tempId = DateTime.now().millisecondsSinceEpoch;
    final optimisticMessage = {
      'id': tempId,
      'sender_id': _currentUserId,
      'receiver_id': widget.receiverId,
      'message': text,
      'created_at': DateTime.now().toIso8601String(),
    };

    setState(() {
      _messages.add(optimisticMessage);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/chats'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'receiver_id': widget.receiverId, 'message': text}),
      );

      if (response.statusCode == 201) {
        _fetchMessages(isSilent: true);
      } else {
        // Rollback optimistic update on failure
        setState(() {
          _messages.removeWhere((msg) => msg['id'] == tempId);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal mengirim pesan')));
      }
    } catch (e) {
      // Rollback on connection error
      setState(() {
        _messages.removeWhere((msg) => msg['id'] == tempId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koneksi bermasalah saat mengirim pesan')),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatMessageTime(String timeStr) {
    try {
      final parsedDate = DateTime.tryParse(timeStr);
      if (parsedDate == null) return '';
      final localDate = parsedDate.toLocal();
      return '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  String _formatHeaderDate(String timeStr) {
    try {
      final parsedDate = DateTime.tryParse(timeStr);
      if (parsedDate == null) return '';
      final localDate = parsedDate.toLocal();

      final now = DateTime.now();
      if (localDate.year == now.year &&
          localDate.month == now.month &&
          localDate.day == now.day) {
        return 'Hari Ini';
      }

      const months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];

      return '${localDate.day.toString().padLeft(2, '0')} ${months[localDate.month - 1]}';
    } catch (e) {
      return '';
    }
  }

  bool _shouldShowDateSeparator(int index) {
    if (index == 0) return true;

    try {
      final currentMsgTime = DateTime.tryParse(_messages[index]['created_at']);
      final prevMsgTime = DateTime.tryParse(_messages[index - 1]['created_at']);

      if (currentMsgTime == null || prevMsgTime == null) return false;

      return currentMsgTime.toLocal().day != prevMsgTime.toLocal().day ||
          currentMsgTime.toLocal().month != prevMsgTime.toLocal().month ||
          currentMsgTime.toLocal().year != prevMsgTime.toLocal().year;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? profilePic = widget.profilePictureUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leadingWidth: 40,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF74070E),
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SellerProfilePage(
                  sellerId: widget.receiverId,
                  sellerName: widget.receiverName,
                ),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF2E6E6),
                backgroundImage: profilePic != null && profilePic.isNotEmpty
                    ? NetworkImage(
                        '${ApiConfig.host}/uploads/profiles/$profilePic',
                      )
                    : null,
                child: profilePic == null || profilePic.isEmpty
                    ? Text(
                        widget.receiverName.isNotEmpty
                            ? widget.receiverName[0].toUpperCase()
                            : 'P',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF74070E),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.receiverName,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading && _messages.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF74070E),
                        ),
                      ),
                    )
                  : _messages.isEmpty
                  ? _buildEmptyState()
                  : _buildMessageList(),
            ),
            _buildInputSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final bool isMe = msg['sender_id'] == _currentUserId;
        final showDateSeparator = _shouldShowDateSeparator(index);
        final timeStr = _formatMessageTime(msg['created_at']);
        final dateHeaderStr = _formatHeaderDate(msg['created_at']);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDateSeparator)
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    dateHeaderStr,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: isMe ? const Color(0xFFF2E6E6) : Colors.white,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      msg['message'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        color: Colors.black87,
                        height: 1.45,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        timeStr,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInputSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Ketik pesan...',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              height: 40,
              width: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF74070E),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: Color(0xFFF9EFEF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 40,
              color: Color(0xFF74070E),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Mulailah Obrolan!',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kirim pesan pertama Anda di bawah.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
