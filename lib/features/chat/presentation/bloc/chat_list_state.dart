part of 'chat_list_bloc.dart';

enum ChatListStatus { initial, loading, success, failure }

class ChatListState extends Equatable {
  final ChatListStatus status;
  final List<ChatRoom> rooms;
  final String? errorMessage;

  const ChatListState({
    this.status = ChatListStatus.initial,
    this.rooms = const [],
    this.errorMessage,
  });

  ChatListState copyWith({
    ChatListStatus? status,
    List<ChatRoom>? rooms,
    String? errorMessage,
  }) {
    return ChatListState(
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, rooms, errorMessage];
}
