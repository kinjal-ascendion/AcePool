import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository repository;
  SendMessageUseCase(this.repository);

  Future<void> call({
    required String chatId,
    required ChatMessage message,
    required String senderName,
    required String receiverName,
  }) {
    return repository.sendMessage(chatId, message, senderName, receiverName);
  }
}
