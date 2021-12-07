#pragma semicolon 1
#include <sourcemod>
#include <devzones>
#include <multicolors>


Handle Credit_Reward_Amount = INVALID_HANDLE;

public Plugin myinfo =
{
	name = "SM DEV Zones - Store Credits",
	author = "SHITLER",
	description = "x credits reward on end of map",
	version = "1.0",
	url = "www.alliedmodders.com"
};

public OnPluginStart()
{
	Credit_Reward_Amount = CreateConVar("sm_credit_amount", "100", "Amount of credits to reward people.");
}

public Zone_OnClientEntry(client, String:zone[])
{	
	new userid = GetClientUserId(client);
	new amount = GetConVarInt(Credit_Reward_Amount);
	ClientCommand(client, "play gta.mp3");
	ServerCommand("sm_givecredits #%d %i", userid, amount);
	ServerCommand("sm_slay #%d", userid);
	CPrintToChatAll("{yellow}~.~.~.~.~.~.~.~.~.~.~.~.~.~.~.~.~.~.~.~.~.~.~.~.~.~.~");
	CPrintToChatAll("{orange}%N {yellow}has finished the map and won {orange}%i {yellow}credits.", client, amount);
	CPrintToChatAll("{yellow}~.~.~.~.~.~.~.~.~.~.~.~.~.~.~.~.~.~.~.~.~.~.~.~.~.~.~");
}