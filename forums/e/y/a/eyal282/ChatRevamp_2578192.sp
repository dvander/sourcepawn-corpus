#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "Chat Revamp ( Chat Processor )",
	author = "Eyal282 ( FuckTheSchool )",
	description = "Allows plugins to intercept chat communications between players and edit them",
	version = "1.3",
	url = "<- URL ->"
}

new Handle:fw_ChatSent = INVALID_HANDLE;
new Handle:fw_ChatSent_Post = INVALID_HANDLE;

new Handle:cvHideNameChange = INVALID_HANDLE;
new Handle:cvDeadChat = INVALID_HANDLE;
new Handle:cvShortage = INVALID_HANDLE;

new bool:NewMessage[MAXPLAYERS];


public Action:CR_OnChatSent(Receiver, &Sender, &bChat, String:Tag[], String:Name[], String:Message[], &WillSend)
{
	if(WillSend)
	{
		if(GetConVarBool(cvHideNameChange))
		{	
			if(StrContains(Tag, "Name", false) != -1 && CheckCommandAccess(Sender, "sm_kick", ADMFLAG_KICK))
			{
				if(!CheckCommandAccess(Receiver, "sm_kick", ADMFLAG_KICK))
					return Plugin_Handled;
			}
		}
	}
	else
	{
		if(GetConVarBool(cvDeadChat))
		{
			if(StrContains(Tag, "Dead", false) != -1)
			{
				if(StrContains(Tag, "All") != -1 || GetClientTeam(Sender) == GetClientTeam(Receiver))
					WillSend = 1;
			}
		}
	}
	return Plugin_Continue;
}

public Action:CR_OnChatSent_Post(Receiver, Sender, bChat, String:Tag[], String:Name[], String:Message[])
{
	if(!GetConVarBool(cvHideNameChange))
		return Plugin_Continue;
		
	else if(StrContains(Tag, "Name", false) != -1 && CheckCommandAccess(Sender, "sm_kick", ADMFLAG_KICK))
		PrintToChat(Sender, "Your name change is only shown to admins!");
	
	return Plugin_Continue;
}
public OnPluginStart()
{	
	HookUserMessage(GetUserMessageId("SayText2"), Message_SayText2, true);
	
	// public Action:CR_OnChatSent(Receiver, &Sender, &bChat, String:Tag[], String:Name[], String:Message[], &WillSend)
	
	// @param Receiver			The client receiving the message.
	// @param Sender			The client sending the message.
	// @param bChat				Unsure, I think whether or not the message is printed in console not only in chat.
	// @param String:Tag[]		Message display tags ( Changing will not affect who will see it, but it acts as a format of message, Example: #L4D_Chat_All, #L4D_Chat_Infected )
	// @param String:Name[]		Name of the sender.
	// @param String:Message[]	The message the client sends.
	// @param WillSend			Will the message actually be sent without changing this to true? Change to true if you want to force the message to be sent even if it shouldn't.

	// @Return					Even to allow chat to send, Odd to disallow chat to send. Plugin_Stop will act as Plugin_Continue due to that.
	
	// @Note					Tag in L4D2 and probably all games will contain "Name" when the chat message is a name change.
	// @Note					All parameters are copied back to the forward except Receiver.
	
	fw_ChatSent = CreateGlobalForward("CR_OnChatSent", ET_Event, Param_Cell, Param_CellByRef, Param_CellByRef, Param_String, Param_String, Param_String, Param_CellByRef);
	
	// public Action:CR_OnChatSent_Post(Receiver, Sender, bChat, String:Tag[], String:Name[], String:Message[])
	
	// @Note: The parameters on post and pre are identical except no parameter of "WillSend".
	// @Note: Tag in L4D2 and probably all games will contain "Name" when the chat message is a name change.
	
	fw_ChatSent_Post = CreateGlobalForward("CR_OnChatSent_Post", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_String, Param_String, Param_String);
	
	
	cvHideNameChange = CreateConVar("cr_hide_admin_name_change", "1", "If set to 1, only admins can see name changes");
	cvDeadChat = CreateConVar("cr_dead_chat", "0", "If set to 1, dead players can chat.");
	cvShortage = CreateConVar("cr_shortage", "0");
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if(client > 0 && StrContains(command, "say") != -1)
	{
		NewMessage[client] = true;
	}
}

public Action:Message_SayText2(UserMsg msg_id, Handle:Bf, int[] players, int playersNum, bool reliable, bool init)
{
	new Sender = BfReadByte(Bf);
	
	if(Sender <= 0)
		return Plugin_Continue;
		
	else if(GetConVarInt(cvShortage))
		return Plugin_Continue;
	
	new bChat = BfReadByte(Bf);
	
	new String:Tag[50];
	BfReadString(Bf, Tag, sizeof(Tag));
	if(NewMessage[Sender])
		NewMessage[Sender] = false;
	
	
	else if(reliable)
	{
		if(StrContains(Tag, "Name", false) == -1)
			return Plugin_Stop;
	}
	
	new String:Name[64];
	BfReadString(Bf, Name, sizeof(Name));
	
	new String:Message[300];
	BfReadString(Bf, Message, sizeof(Message));
	
	new playersList[MAXPLAYERS];
	for(new i=1;i <= MaxClients;i++) 
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(IsFakeClient(i))
			continue;
			
		else if(StrContains(Tag, "Dead", false) != -1 && IsPlayerAlive(i))
			continue;
			
		else if(StrContains(Tag, "_All", false) == -1 && GetClientTeam(i) != GetClientTeam(Sender))
			continue;
			
		playersList[playersNum] = i;
		playersNum++;
	}
	

	new Handle:DP = CreateDataPack();
	
	WritePackCell(DP, Sender);
	WritePackCell(DP, bChat);
	WritePackString(DP, Tag);
	WritePackString(DP, Name);
	WritePackString(DP, Message);

	WritePackCell(DP, playersNum);
	
	for(new i=0;i < playersNum;i++)
		WritePackCell(DP, playersList[i]);
		
	RequestFrame(SendMessage, DP);
	return Plugin_Stop;
}

public SendMessage(Handle:DP)
{
	ResetPack(DP);
	new Sender = ReadPackCell(DP);
	new bChat = ReadPackCell(DP);
	new String:Tag[50];
	ReadPackString(DP, Tag, sizeof(Tag));
	new String:Name[64];
	ReadPackString(DP, Name, sizeof(Name));
	new String:Message[300];
	ReadPackString(DP, Message, sizeof(Message));
	new playersNum = ReadPackCell(DP);

	new players[MAXPLAYERS];
	
	for(new i=0;i < playersNum;i++)
	{
		players[i] = ReadPackCell(DP);
	}
	
	CloseHandle(DP);
	
	new ReturnValue;
	for(new Rec=1;Rec <= MaxClients;Rec++)
	{
		if(!IsClientInGame(Rec))
			continue;
			
		else if(IsFakeClient(Rec))
			continue;
			
		new WillSend = 0;
		
		if(FindValueInRegularArray(players, playersNum, Rec) != -1)
			WillSend = 1;
		
		Call_StartForward(fw_ChatSent);
		
		Call_PushCell(Rec);
		Call_PushCellRef(Sender);
		Call_PushCellRef(bChat);
		Call_PushStringEx(Tag, sizeof(Tag), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushStringEx(Name, sizeof(Name), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);	
		Call_PushStringEx(Message, sizeof(Message), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);	
		Call_PushCellRef(WillSend);
			
		Call_Finish(ReturnValue);
		
		if((ReturnValue & 1) == 1 || WillSend == 0)
				continue;
		
		static UserMsg:SayText;
		if(!SayText)
			SayText = GetUserMessageId("SayText2");
		
		new Handle:Bf = StartMessageOne("SayText2", Rec, USERMSG_BLOCKHOOKS);
		BfWriteByte(Bf, Sender);
		BfWriteByte(Bf, bChat);
		BfWriteString(Bf, Tag);
		BfWriteString(Bf, Name);
		BfWriteString(Bf, Message); 
		EndMessage()
	
		Call_StartForward(fw_ChatSent_Post);
		
		Call_PushCell(Rec);
		Call_PushCell(Sender);
		Call_PushCell(bChat);
		Call_PushString(Tag);
		Call_PushString(Name);	
		Call_PushString(Message);	
		
		Call_Finish(ReturnValue);
	}
}

stock PrintToChatRoot(const String:format[], any:...)
{
	new String:buffer[291];
	VFormat(buffer, sizeof(buffer), format, 2);
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		else if(IsFakeClient(i))
			continue;
			
		if(CheckCommandAccess(i, "sm_checkcommandaccess_root", ADMFLAG_ROOT))
			PrintToChat(i, buffer);
	}
}

stock FindValueInRegularArray(ArrayToFind[], arraysize, value)
{
	for(new i=0;i < arraysize;i++)
	{
		if(ArrayToFind[i] == value)
			return i;
	}
	
	return -1;
}