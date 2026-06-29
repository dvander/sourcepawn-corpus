#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#pragma semicolon 1

public Plugin:myinfo =
{
	name = "[TF2] Unused h5 lines",
	author = "Pelipoika",
	description = "Missing in action.",
	version = "1.1",
	url = "http://wiki.teamfortress.com/wiki/Spy_responses#Unused_responses"
};

public OnPluginStart()
{
	AddNormalSoundHook(NormalSHook:Sound);
}

public OnMapStart()
{
	PrecacheSound("vo/taunts/spy_highfive01.wav");
	PrecacheSound("vo/taunts/spy_highfive02.wav");
	PrecacheSound("vo/taunts/spy_highfive03.wav");
	PrecacheSound("vo/taunts/spy_highfive04.wav");
	PrecacheSound("vo/taunts/spy_highfive05.wav");
	PrecacheSound("vo/taunts/spy_highfive06.wav");
	PrecacheSound("vo/taunts/spy_highfive07.wav");
	PrecacheSound("vo/taunts/spy_highfive08.wav");
	PrecacheSound("vo/taunts/spy_highfive09.wav");
	PrecacheSound("vo/taunts/spy_highfive10.wav");
	PrecacheSound("vo/taunts/spy_highfive11.wav");
	PrecacheSound("vo/taunts/spy_highfive12.wav");
	PrecacheSound("vo/taunts/spy_highfive13.wav");
	PrecacheSound("vo/taunts/spy_highfive14.wav");
	
	PrecacheSound("vo/taunts/spy_highfive_success01.wav");
	PrecacheSound("vo/taunts/spy_highfive_success02.wav");
	PrecacheSound("vo/taunts/spy_highfive_success03.wav");
	PrecacheSound("vo/taunts/spy_highfive_success04.wav");
	PrecacheSound("vo/taunts/spy_highfive_success05.wav");
}

public Action:Sound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &ent, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidEntity(ent) && ent < 1 || ent > MaxClients || channel < 1)
		return Plugin_Continue;
		
	if (IsValidClient(ent))
	{
		if(TF2_GetPlayerClass(ent) == TFClass_Spy)
		{
			if(StrContains(sample, "vo/taunts/spy_highfive_success", false) != -1)
			{
				Format(sample, sizeof(sample), "vo/taunts/spy_highfive_success0%i.wav", GetRandomInt(1, 5));
				return Plugin_Changed;
			}
			else if(StrContains(sample, "vo/taunts/spy_highfive", false) != -1)
			{
				switch(GetRandomInt(1,2))
				{
					case 1: Format(sample, sizeof(sample), "vo/taunts/spy_highfive0%i.wav", GetRandomInt(1, 9));
					case 2: Format(sample, sizeof(sample), "vo/taunts/spy_highfive%i.wav", GetRandomInt(10, 14));
				}
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	return IsClientInGame(client);
}