part of 'chat_list_bloc.dart';

enum ChatListStatus { initial, loading, success, failure }
enum ChatFilter { all, unread }

class ChatListState extends Equatable {
  final ChatListStatus status;
  final List<ChatRoom> rooms;
  final String? errorMessage;
  final ChatFilter filter;
  final String searchQuery;

  const ChatListState({
    this.status = ChatListStatus.initial,
    this.rooms = const [],
    this.errorMessage,
    this.filter = ChatFilter.all,
    this.searchQuery = '',
  });

  ChatListState copyWith({
    ChatListStatus? status,
    List<ChatRoom>? rooms,
    String? errorMessage,
    ChatFilter? filter,
    String? searchQuery,
  }) {
    return ChatListState(
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      errorMessage: errorMessage ?? this.errorMessage,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [status, rooms, errorMessage, filter, searchQuery];
}
