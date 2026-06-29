#pragma semicolon 1
#include <sourcemod>
#include <cstrike>

public Plugin:myinfo = 
{
	name = "Deagle Blocker",
	author = "hams",
	description = "You cant buy a Deagle when this is loaded",
	version = "0.05",
	url = "http://www.sourcemod.net/"
};

public Action:CS_OnBuyCommand(client, const String:weapon[])
{
	if (StrEqual(weapon,"deagle"))
		{ PrintToChat(client, "Your blocked from buying a Deagle!"); return Plugin_Handled; }
	return Plugin_Continue;
}

