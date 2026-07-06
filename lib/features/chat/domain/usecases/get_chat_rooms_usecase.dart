import '../../domain/entities/chat_room.dart';
import '../../domain/repositories/chat_repository.dart';

class GetChatRoomsUseCase {
  final ChatRepository repository;
  GetChatRoomsUseCase(this.repository);

  Stream<List<ChatRoom>> call(String userId) {
    return repository.getChatRooms(userId);
  }
}
