#include <sourcemod>
#include <gungame>

new NumClients;

/******
 *Load*
*******/

public OnPluginStart()
{
	RegConsoleCmd("sm_clientcount", ClientCountCmd);
	RegConsoleCmd("sm_botcount", BotCountCmd);
	HookEvent("round_start", OnRoundStart);
}

/*********
 *Fowards*
**********/

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	NumClients = GetRealClientCount();
}

public OnClientDisconnect(client)
{
	if(!IsFakeClient(client))
		NumClients--;
}

public OnClientAuthorized(client)
{
	if(!IsFakeClient(client))
		NumClients++;
}

/**********
 *Commands*
***********/

public Action:ClientCountCmd(client, args)
{
	if(IsValidClient(client))
		ReplyToCommand(client, "\x01\x0B\x04[SM]\x01 Client count / Plugin count: [%i/%i]", GetRealClientCount(), NumClients);
	return Plugin_Handled;
}

public Action:BotCountCmd(client, args)
{
	if(IsValidClient(client))
		ReplyToCommand(client, "\x01\x0B\x04[SM]\x01 Bot count: %i", GetFakeClientCount());
	return Plugin_Handled;
}

/********
 *Events*
*********/

public Action:GG_OnClientLevelChange(client, level, difference, bool:steal, bool:last, bool:knife)
{
	if(NumClients < 2)
	{
		if(IsValidClient(client) && !IsFakeClient(client))
			PrintToChat(client, "You can't level up without another human present.");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

/********
 *Stocks*
*********/

stock GetRealClientCount()
{
	new count = 0;
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i))
			count++;
	return count;
}

stock GetFakeClientCount()
{
	new count = 0;
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && IsFakeClient(i))
			count++;
	return count;
}

stock IsValidClient(client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}