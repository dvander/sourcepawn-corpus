/*
	Exclude Chat by pRED*
		- version 0.1
	
	Sends a text message to all players in the server except for one.
	
	To change the colour of the text (msgtype 4 only) change the defined colours/alpha below and recompile

	Cmds:
		sm_xsay <name or #userid> <message> - Sends a message to all players except specified player

	Cvars:
		sm_exclude_immunity - <0|1> If set to 1 all admins have immunity from being excluded otherwise only those with immunity status

		sm_exclude_msgtype: 1 - Chat Text
							2 - Hint Text
							3 - Center Say
							4 - Top Right Corner (coloured red atm)

	ToDo:
		Maybe add cvars to define what colour for the top right message thing. Seems a bit much tho.
		
	ChangeLog:
		0.1: Initial Version
*/


#include <sourcemod>

#define PLUGIN_VERSION "0.1"

#define RED 255
#define GREEN 0
#define BLUE 0
#define ALPHA 255

new Handle:admin_block;
new Handle:msg_type;

public Plugin:myinfo = 
{
	name = "Exclude Chat",
	author = "pRED*",
	description = "Prints a message to all player except for one",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases")
	
	CreateConVar("sm_exclude_version", PLUGIN_VERSION, "Exclude Chat Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	RegConsoleCmd("sm_xsay", Cmd_XSay,"<partial name or #userid>")
	
	admin_block = CreateConVar("sm_exclude_immunity","1","Should admins be immune from exclude messages? <1|0>")
	msg_type = CreateConVar("sm_exclude_msgtype","1","What type of message to display")
}

public Action:Cmd_XSay(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_rate <name or #userid> <message>")
		return Plugin_Handled;	
	}
	
	new String:buffer[300],String:name[32]
	GetCmdArgString(buffer, 299)
	new start = BreakString(buffer, name, 31)
	
	
	new Clients[2]
	new NumClients = SearchForClients(name, Clients, 2)

	if (NumClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client")
		return Plugin_Handled
	}
	else if (NumClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", name)
		return Plugin_Handled
	}
	else if (!CanUserTarget(client, Clients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target")
		return Plugin_Handled
	}
	
	exclude_print(client,Clients[0],buffer[start])

	return Plugin_Handled
}


public exclude_print(id,ex,String:message[])
{
	// get callers's name
	new String:callername[32]
	GetClientName(id,callername,31)

	new see_all,i
	new maxplayers=GetMaxClients()+1
	new immunity=GetConVarInt(admin_block)
	new type=GetConVarInt(msg_type)

	// go through players
	for(i=1;i<maxplayers;i++) 
	{
		if (!(IsClientInGame(i)))
			continue
			
		if (immunity)
			see_all = GetUserFlagBits(i)
		else
			see_all = 0

		// if our excluded player, skip
		if(i == ex && !see_all) continue;

		switch (type)
		{
		case 2: SendHintText(i,"%s : %s", callername,message)
		case 3: PrintCenterText(i, "%s : %s", callername,message)
		case 4: SendTopMessage(i,RED,GREEN,BLUE,ALPHA, "%s : %s", callername,message)
		default: PrintToChat(i,"\x01\x04(ALL) %s : %s", callername,message)
		}
	}
}

stock SendHintText(client,String:text[], any:...)
{
	new String:message[192];
	VFormat(message,191,text, 3);

	new len = strlen(message);
	
	if(len > 30)
	{
		new LastAdded=0;

		for(new i=0;i<len;i++)
		{
			if((message[i]==' ' && LastAdded > 30 && (len-i) > 10) || ((GetNextSpaceCount(text,i+1) + LastAdded)  > 34))
			{
				message[i] = '\n';
				LastAdded = 0;
			}
			else
				LastAdded++;
		}
	}

	new clients[2]
	clients[0]=client
	
	new Handle:HintMessage = StartMessage("HintText", clients, 1, USERMSG_RELIABLE)
	BfWriteByte(HintMessage,-1);
	BfWriteString(HintMessage,message);
	EndMessage();
}

stock GetNextSpaceCount(String:text[],CurIndex)
{
	new Count=0;
	new len = strlen(text);
	for(new i=CurIndex;i<len;i++)
	{
		if(text[i] == ' ')
			return Count;
		else
			Count++;
	}

	return Count;
}

stock SendTopMessage(client,r,g,b,a,String:text[], any:...)
{
	new String:message[100]
	VFormat(message,191,text, 7)
	
	new Handle:kv = CreateKeyValues("Stuff", "title", message)
	KvSetColor(kv, "color", r, g, b, a)
	KvSetNum(kv, "level", 1)
	KvSetNum(kv, "time", 10)

	CreateDialog(client, kv, DialogType_Msg)

	CloseHandle(kv)

	return
}
