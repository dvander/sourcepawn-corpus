#pragma semicolon 1
#include <sourcemod>
#include <freak_fortress_2>
#include <morecolors>

public Plugin:myinfo = {
	name = "Anti-Solo Rage",
	author = "Nanochip",
	description = "Disables solo rages.",
	version = "1.0",
	url = "lol"
};

new Handle:cvarAntiSoloRageBypass;

new bool:canMsg = true;
new bool:soloRage;

public OnPluginStart()
{
	cvarAntiSoloRageBypass = CreateConVar("sm_antisolorage_bypass", "", "Which bosses do you want to bypass the anti solo rage?");
}

public FF2_PreAbility(boss, const String:pluginName[], const String:abilityName[], slot, &bool:enabled)
{
	new Float:rageDist = FF2_GetRageDist(boss, "default_abilities", "");
	new client = GetClientOfUserId(FF2_GetBossUserId(boss));
	
	if (IsBossBypassed(client)) return;
	
	decl Float:fClientEyePosition[3];
	GetClientEyePosition(client, fClientEyePosition);
	
	new players = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsClientConnected(i) && !IsClientObserver(i) && GetClientTeam(i) != GetClientTeam(client))
		{
			decl Float:fClientLocation[3];
			GetClientAbsOrigin(i, fClientLocation);
			
			fClientLocation[2] += 90;
			
			decl Float:fDistance[3];
			MakeVectorFromPoints(fClientLocation, fClientEyePosition, fDistance);
			
			if (GetVectorLength(fDistance) < rageDist && GetClientTeam(client) != GetClientTeam(i))
			{
				players++;
			}
		}
	}
	
	if (players == 1 && slot == 0)
	{
		enabled = false;
		soloRage = true;
	} else {
		soloRage = false;
	}
}

public OnGameFrame()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (FF2_GetBossIndex(i) != -1)
		{
			if (soloRage && canMsg)
			{
				CPrintToChatAll("{olive}[FF2] {default}%N tried to {red}Solo-Rage{default}! It's not very effective...", i);
				canMsg = false;
				soloRage = false;
				CreateTimer(10.0, Timer_Delay, _, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action:Timer_Delay(Handle:timer)
{
	canMsg = true;
}

bool:IsBossBypassed(client)
{
	new index = FF2_GetBossIndex(client);
	decl String:name[56], String:cvar[1024];
	FF2_GetBossSpecial(index, name, sizeof(name));
	GetConVarString(cvarAntiSoloRageBypass, cvar, sizeof(cvar));
	if (StrContains(cvar, name, false) != -1) return true;
	return false;
}