/* Plugin Template generated by Pawn Studio */

#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Delete Props",
	author = "explosivetaco",
	description = "A Plugin To Delete A Prop",
	version = "1.0",
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	RegConsoleCmd("say", Commandsay, "say hook");
}
public Action:Commandsay(client, args)
{
new String:prop[32];
GetCmdArg(1, prop, sizeof(prop));


	if(StrEqual(prop,"!del"))
	{
		FakeClientCommand(client,"ent_remove");
		PrintToChat(client, "\x04[Delete]\x01 Your Prop Has Been Deleted.");return Plugin_Handled
	}
	return Plugin_Continue;
}
