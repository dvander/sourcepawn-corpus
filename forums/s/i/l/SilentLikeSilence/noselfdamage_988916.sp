#include <sourcemod>

new bool:NoDamage[MAXPLAYERS +1];

public Plugin:myinfo =
{
	name = "[TF2] No Self Damage",
	author = "John B.",
	description = "Players don't lose hps on rocketjump and stickyjump",
	version = "1.0.0",
	url = "www.sourcemod.net",
}

public OnPluginStart()
{
	RegConsoleCmd("sm_noselfdamage", Command_NoSelfDamage);

	HookEvent("player_hurt", Event_PlayerHurt);
}

public OnClientPutInServer(client)
{
	NoDamage[client] = false;
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damageamount = GetEventInt(event, "damageamount");
	new currenthealth = GetClientHealth(client);

	if(client == attacker && NoDamage[client] == true)
	{
		SetEntityHealth(client, currenthealth + damageamount);
	}
	else if(NoDamage[client] == false)
	{
		//Do Nothing
	}
	return Plugin_Continue;
}

public Action:Command_NoSelfDamage(client, args)
{
	if(NoDamage[client] == false)
	{	
		NoDamage[client] = true;
		ReplyToCommand(client, "\x04[No Self Damage]: \x03Enabled.");
	}
	else if(NoDamage[client] == true)
	{
		NoDamage[client] = false;
		ReplyToCommand(client, "\x04[No Self Damage]: \x03Disabled.");
	}
	return Plugin_Handled;
}