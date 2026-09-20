-module(ex06).
-compile(export_all).


%% makes process of the msg fxn, passing 0 args and assigns it to "chat" 
start() ->
	PID = self(),
	register(chat, spawn(ex06, msg, [PID])).

%% simple listener that returns a message
msg(PID) ->
	receive
		{sys, Text} -> io:format("*** ~s ***~n", [Text]), msg(PID);
		{sys2, Text} -> io:format("*** ~s ***~n", [Text]), disconnect(nodes()), exit(PID, chat_ended);
		{Name, Message} -> io:format("~s: ~s~n", [Name, Message]), msg(PID);
		bye -> io:format("You have disconnected.~n"),disconnect(nodes());
		_ -> io:format("Unrecognized Message~n"), msg(PID)
	end.	

%% use on terminal where you'll be connecting to
%% gets a user name and starts the msg process
init_chat() ->
	User1 = io:get_line("Enter your Name: "),
	start(),
	Username1 = string:trim(User1),
	io:format("Waiting for Connection..."),
	waiting(Username1).

%% use on connecting terminal and pass the terminal name
%% does same thing as init_chat() and connects to node
init_chat2(FrodoNode) ->
	User2 = io:get_line("Enter your Name: "),
	net_kernel:connect_node(FrodoNode),	
	start(),
	Username2 = string:trim(User2),	
	waiting(Username2).

waiting(Name) ->
    case nodes() of
        [] ->
            waiting(Name);
        _->
        	io:format("Established Connection!~n"),
        	send_chat(nodes(), {sys, Name ++ " has joined."}),
        	chat_room(Name)
    end.

%% chat room that gets an input from user and sends that message to other node's chat
chat_room(Name) ->
    Prompt = io_lib:format("~s: ", [Name]),
    Message = io:get_line(Prompt),
    Trimmed = string:trim(Message),
    case Trimmed of
        "bye" ->
        	case length(nodes()) of
        		1 ->
            		send_chat(nodes(), {sys2, Name ++ " has disconnected"});
	            _ -> 
	        		send_chat(nodes(), {sys, Name ++ " has disconnected"})
	        end,
			timer:sleep(100),
			chat ! bye;
        _ ->
            send_chat(nodes(), Name, Trimmed),
            chat_room(Name)
    end.

%% sends message to the node's chat process
send_chat([], _Message) -> ok;
send_chat([H | T], Message) ->  
    {chat, H} ! Message,  
    send_chat(T, Message).

send_chat([], _Name, _Message)-> ok;
send_chat([H | T], Name, Message) ->
	{chat, H} ! {Name, Message},
	send_chat(T, Name, Message).

%% for disconnecting to multiple nodes
disconnect([]) -> ok;
disconnect([H | T]) -> erlang:disconnect_node(H), disconnect(T).

