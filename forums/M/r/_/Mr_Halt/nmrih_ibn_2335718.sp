#pragma semicolon 1
#include <sdkhooks>
#define PLUGIN_VERSION "2.0"
new bool:Infection[MAXPLAYERS+1];
new bool:Bleeding[MAXPLAYERS+1];
public Plugin:myinfo =
{
	name = "[NMRiH] Infection & Bleeding Notification",
	author = "ys24ys, Mr.Halt",
	description = "Infection & Bleeding Notification for NMRiH",
	version = PLUGIN_VERSION,
	url = "http://blog.naver.com/pine0113"
};

public OnPluginStart()
{
	decl String:game[16];
	GetGameFolderName(game, sizeof(game));
	if(strcmp(game, "nmrih", false) != 0)
	{
		SetFailState("Unsupported game!");
	}
	
	CreateConVar("sm_nmrih_ibn_version", PLUGIN_VERSION, "[NMRiH] Infection & Bleeding Notification version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	LoadTranslations("nmrih_ibn.phrases");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	
	OnStatusTimer();
}

public OnStatusTimer()
{
	for(new Client=1; Client<=8; Client++)
	{
		CreateTimer(0.2, Event_PlayerStatus, Client, TIMER_REPEAT);
	}
}

public Action:Event_PlayerStatus(Handle:timer, any:Client)
{
	if(IsClientConnected(Client) && IsClientInGame(Client) && IsPlayerAlive(Client))
	{
		if(IsClientInfected(Client) == false) Infection[Client] = false;
		
		if(IsClientInfected(Client) == true)
		{
			if(Infection[Client] == false)
			{
				Infection[Client] = true;
				PrintToChatAll("\x01%N \x04%t", Client, "Notifi_Infection");
			}
		}
		
		if(IsClientBleeding(Client) == false) Bleeding[Client] = false;
		
		if(IsClientBleeding(Client))
		{
			if(Bleeding[Client] == false)
			{
				Bleeding[Client] = true;
				PrintToChatAll("\x01%N \x04%t", Client, "Notifi_Bleeding");
			}
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(Infection[Client] == true) Infection[Client] = false;
	if(Bleeding[Client] == true) Bleeding[Client] = false;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(Infection[Client] == true) Infection[Client] = false;
	if(Bleeding[Client] == true) Bleeding[Client] = false;
}

stock bool:IsClientInfected(Client)
{
	if(GetEntPropFloat(Client, Prop_Send, "m_flInfectionTime") > 0 && GetEntPropFloat(Client, Prop_Send, "m_flInfectionDeathTime") > 0) return true;
	else return false;
}

stock bool:IsClientBleeding(Client)
{
	if(GetEntProp(Client, Prop_Send, "_bleedingOut") == 1) return true;
	else return false;
}

