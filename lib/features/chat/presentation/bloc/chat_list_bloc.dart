import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/usecases/get_chat_rooms_usecase.dart';

part 'chat_list_event.dart';
part 'chat_list_state.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final GetChatRoomsUseCase _getChatRooms;
  StreamSubscription? _subscription;

  ChatListBloc({
    required GetChatRoomsUseCase getChatRooms,
  })  : _getChatRooms = getChatRooms,
        super(const ChatListState()) {
    on<ChatListSubscriptionRequested>(_onSubscriptionRequested);
    on<ChatListUpdated>(_onChatListUpdated);
  }

  void _onSubscriptionRequested(
    ChatListSubscriptionRequested event,
    Emitter<ChatListState> emit,
  ) {
    emit(state.copyWith(status: ChatListStatus.loading));
    _subscription?.cancel();
    _subscription = _getChatRooms(event.userId).listen(
      (rooms) => add(ChatListUpdated(rooms)),
      onError: (e) => add(ChatListUpdated(const [])),
    );
  }

  void _onChatListUpdated(
    ChatListUpdated event,
    Emitter<ChatListState> emit,
  ) {
    emit(state.copyWith(
      status: ChatListStatus.success,
      rooms: event.rooms,
    ));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
