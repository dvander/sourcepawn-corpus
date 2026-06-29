#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name = "axe master",
	author = "gamemann",
	description = "gives clients axes at round start",
	version = "1.0",
	url =  ""
};

public PrecacheSurvModel()
{
	PrecacheModel("models/weapons/melee/v_fireaxe.mdl");
	PrecacheModel("models/weapons/melee/w_fireaxe.mdl");
}

public OnPluginStart()
{
	HookEvent("round_start", RoundStart);
}

public RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= GetMaxClients(); i++)
	if (IsClientInGame(i))
	{
		GiveAxe();
	}
}

public GiveAxe()
{
	for (new i = 1; i <= GetMaxClients(); i++)
	if (IsClientInGame(i))
	{
		PrintToChat(i, "\x03 you are getting an \x01 fireaxe");
		FakeClientCommand(i, "give fireaxe");
	}
}

public OnMapStart()
{
	PrecacheSurvModel();
}

		



