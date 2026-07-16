import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/get_messages_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetMessagesUseCase _getMessages;
  final SendMessageUseCase _sendMessage;
  StreamSubscription? _subscription;

  ChatBloc({
    required GetMessagesUseCase getMessages,
    required SendMessageUseCase sendMessage,
  })  : _getMessages = getMessages,
        _sendMessage = sendMessage,
        super(const ChatState()) {
    on<ChatMessagesSubscriptionRequested>(_onSubscriptionRequested);
    on<ChatMessagesUpdated>(_onMessagesUpdated);
    on<ChatMessageSent>(_onMessageSent);
  }

  void _onSubscriptionRequested(
    ChatMessagesSubscriptionRequested event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(status: ChatStatus.loading));
    _subscription?.cancel();
    _subscription = _getMessages(event.chatId).listen(
      (messages) => add(ChatMessagesUpdated(messages)),
      onError: (e) => add(ChatMessagesUpdated(const [])), // Simplified error handling
    );
  }

  void _onMessagesUpdated(
    ChatMessagesUpdated event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(
      status: ChatStatus.success,
      messages: event.messages,
    ));
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final message = ChatMessage(
        id: '',
        senderId: event.senderId,
        receiverId: event.receiverId,
        text: event.text,
        audioUrl: event.audioUrl,
        type: event.type,
        timestamp: DateTime.now(),
      );
      await _sendMessage(
        chatId: event.chatId,
        message: message,
        senderName: event.senderName,
        receiverName: event.receiverName,
      );
    } catch (e) {
      emit(state.copyWith(status: ChatStatus.failure, errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
