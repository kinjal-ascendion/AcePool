part of 'chat_list_bloc.dart';

abstract class ChatListEvent extends Equatable {
  const ChatListEvent();
  @override
  List<Object?> get props => [];
}

class ChatListSubscriptionRequested extends ChatListEvent {
  final String userId;
  const ChatListSubscriptionRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class ChatListUpdated extends ChatListEvent {
  final List<ChatRoom> rooms;
  const ChatListUpdated(this.rooms);
  @override
  List<Object?> get props => [rooms];
}

class ChatFilterChanged extends ChatListEvent {
  final ChatFilter filter;
  const ChatFilterChanged(this.filter);
  @override
  List<Object?> get props => [filter];
}

class ChatSearchQueryChanged extends ChatListEvent {
  final String query;
  const ChatSearchQueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}
