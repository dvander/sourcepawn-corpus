#include <sdkhooks>
#include <sourcebans>

#pragma semicolon 1
#pragma newdecls required

bool SourceBansExist = false;

public Plugin myinfo =
{
	name = "Anti-HealingArrows",
	author = "lugui",
	description = "Ban or kick players who use this cheat based healing arrow exploit",
	version = "1.0.1",
	url = ""
};

Handle bantime;

public void OnPluginStart()
{
	bantime =  CreateConVar("sm_aha_bantime", "0", "Amount of time to ban. Default: 0. -1: kick.", 0, true, -1.0, false, 0.0);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("sourcebans");
	return APLRes_Success;
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "sourcebans"))
    {
        SourceBansExist = true;
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "sourcebans"))
    {
        SourceBansExist = false;
    }
}

public void OnClientPutInServer(int client)
{
  	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnEntityCreated(int Ent, const char[] cls) //Hooks damage taken for buildings
{
	if(StrEqual(cls, "obj_sentrygun") || StrEqual(cls, "obj_dispenser") || StrEqual(cls, "obj_teleporter"))
	{
		SDKHook(Ent, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (damage < 0)
		HandlePlayer(attacker);
	return Plugin_Continue;
}

void HandlePlayer(int client)
{
	int time = GetConVarInt(bantime);
	if(!SourceBansExist)
	{
		if(time < 0)
		{
			KickClient(client, "Healing Arrow exploit");
		}
		else
		{
			BanClient(client, time, BANFLAG_AUTO, "Healing Arrow exploit", "Healing Arrow exploit", "HealingAroow", client);
		}
	}
	else
	{
		if(time < 0)
		{
			SourceBans_BanPlayer(0, client, time, "Healing Arrow exploit");
		}
		else
		{
			BanClient(client, time, BANFLAG_AUTO, "Healing Arrow exploit", "Healing Arrow exploit", "HealingAroow", client); // just to be sure
		}
	}
}
