/* 
	Extra Cash
		Adds 16000 to every player on spawn 
		
*/


#include <sourcemod>

#define VERSION "0.2"

new g_iAccount = -1;
new Handle:Switch;
new Handle:Cash;

public Plugin:myinfo = 
{
	name = "Extra Cash",
	author = "Peoples Army",
	description = "Adds Extra Cash On Each Spawn",
	version = VERSION,
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	Switch = CreateConVar("extra_Cash_on","1","1 turns plugin on 0 is off",FCVAR_NOTIFY);
	Cash = CreateConVar("extra_cash_amount","16000","Sets Amount OF Money Given On Spawn",FCVAR_NOTIFY);
	HookEvent("player_spawn" , Spawn);
}

public Spawn(Handle: event , const String: name[] , bool: dontBroadcast)
{
	new clientID = GetEventInt(event,"userid");
	new client = GetClientOfUserId(clientID);
	if(GetConVarInt(Switch))
	{
		SetMoney(client,GetConVarInt(Cash));
	}
}

public SetMoney(client, amount)
{
	if (g_iAccount != -1)
	{
		SetEntData(client, g_iAccount, amount);
	}	
}