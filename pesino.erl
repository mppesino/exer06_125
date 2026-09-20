-module(pesino).
-compile (export_all).

start() ->
	register (chat, spawn(chat,chat,[])).

chat() ->
	receive
		{Name, Message} ->
			io:format("~s: ~s ~n",[Name, Message]),
			chat();
		bye ->
			io:format("Chat ended. ~n");
		_->
			io:format("Unrecognized message. ~n"),
			chat()
	end.

receiver() ->
    receive
        {Node} -> 
            io:format("Established Connection to ~s... ~n", [Node]),
            io:format("In Chat Room with ~s ~n", [Node]),
            receiver();
        bye ->
            Node = hd(nodes()), 
			io:format("Disconnected from partner ~s. ~n", [Node]),
            erlang:disconnect_node(Node);
		{Name, Message} ->
            CleanName = string:trim(Name),
            CleanMessage = string:trim(Message),

			io:format("~s: ~s ~n",[CleanName, CleanMessage]),
			receiver();
        _->
			io:format("Unrecognized message. ~n"),
			receiver()
	end.

init_chat() ->
    net_kernel:monitor_nodes(true),
    Name = io:get_line("Enter Your Name: "),
	register (pesino, spawn(pesino,receiver,[])),
    io:format("Waiting for Connection... ~n"),
    chat_room(Name, undefined).


init_chat2(Node) ->
    net_kernel:monitor_nodes(true),
    net_adm:ping(Node),
    Name = io:get_line("Enter Your Name: "),
	register (pesino, spawn(pesino, receiver, [])),
    io:format("Established Connection to ~s ~n", [Node]),
    io:format("In Chat Room with ~s ~n", [Node]),
    chat_room(Name, Node).

%% c(pesino).
%% pesino:init_chat().
%% pesino:init_chat2('frodo@pixelbuntu').

chat_room(Name, undefined) ->
    case nodes() of
        [] ->
            chat_room(Name, undefined);
        _->
            Node = hd(nodes()),
            io:format("Established Connection to ~s ~n", [Node]),
            io:format("In Chat Room with ~s ~n", [Node]),
            chat_room(Name, Node)
    end;
chat_room(Name, Node) ->
    CleanName = string:trim(Name),
    Format = io_lib:format("~s: ", [CleanName]),
    Message = io:get_line(Format),
    CleanMessage = string:trim(Message),

    case CleanMessage of
        "bye" ->
            {pesino, Node} ! bye,
            io:format("Ended Chat with ~s ~n", [Node]);
        _ ->
            {pesino, Node} ! {Name, CleanMessage},
            chat_room(Name, Node)
    end.
