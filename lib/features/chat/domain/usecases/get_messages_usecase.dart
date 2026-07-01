import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

class GetMessagesUseCase {
  final ChatRepository repository;
  GetMessagesUseCase(this.repository);

  Stream<List<ChatMessage>> call(String chatId) {
    return repository.getMessages(chatId);
  }
}
