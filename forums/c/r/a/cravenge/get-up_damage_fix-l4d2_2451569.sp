#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define ANIM_FIRST 1
#define ANIM_SECOND 2
#define ANIM_THIRD 3
#define ANIM_FOURTH 4
#define ANIM_FIFTH 5

new bool:damageBlocked[MAXPLAYERS+1];
new bool:lateLoad;

public APLRes:AskPluginLoad2(Handle:plugin, bool:late, String:error[], errMax) 
{
	lateLoad = late;
	return APLRes_Success;    
}

public Plugin:myinfo =
{
    name = "[L4D2] Get-Up Damage Fix",
    author = "Standalone (aka Manu), Visor",
    description = "Fixes Damages Taken While Get-Up Animations Are Ongoing.",
    version = "1.1",
    url = "https://github.com/Attano/L4D2-Competitive-Framework"
};

public OnPluginStart() 
{
    HookEvent("pounce_stopped", OnAnimationsPlaying);
    HookEvent("charger_pummel_end", OnAnimationsPlaying);
    HookEvent("charger_carry_end", OnAnimationsPlaying);
    HookEvent("player_bot_replace", OnPlayerBotReplace);
    HookEvent("bot_player_replace", OnBotPlayerReplace);
    HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
	
	if (lateLoad) 
	{
		for (new i = 1; i <= MaxClients; i++) 
		{
			if (IsClientInGame(i)) 
			{
				OnClientPutInServer(i);
			}
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (!IsSurvivor(victim))
	{
		return Plugin_Continue;
	}
	
	if (damageBlocked[victim])
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
        if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			damageBlocked[i] = false;
		}
	}
}

public OnMapEnd()
{
    for (new i = 1; i <= MaxClients; i++)
	{
        if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			damageBlocked[i] = false;
		}
	}
}

public Action:OnBotPlayerReplace(Handle:event, const String:name[], bool:dontBroadcast) 
{
    new player = GetClientOfUserId(GetEventInt(event, "player"));
	if (!IsSurvivor(player) || IsFakeClient(player))
	{
		return;
	}
    
    if (damageBlocked[player])
    {
        SDKHook(player, SDKHook_PostThink, OnThink);
    }
}

public Action:OnPlayerBotReplace(Handle:event, const String:name[], bool:dontBroadcast) 
{
    new bot = GetClientOfUserId(GetEventInt(event, "bot"));
    if (GetClientTeam(bot) != 2)
	{
		return;
	}
    
    if (damageBlocked[bot])
    {
        SDKHook(bot, SDKHook_PostThink, OnThink);
    }
}

public Action:OnAnimationsPlaying(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!IsSurvivor(client))
	{
		return;
	}
	
    damageBlocked[client] = true;
	CreateTimer(0.2, HookOnThink, client);
}

public Action:HookOnThink(Handle:timer, any:client)
{
	SDKHook(client, SDKHook_PostThink, OnThink);
	return Plugin_Stop;
}

public OnThink(client)
{
    new sequence = GetEntProp(client, Prop_Send, "m_nSequence");
    if (sequence != CollectCurrentAnimInfo(client, ANIM_FIRST) && sequence != CollectCurrentAnimInfo(client, ANIM_SECOND) && sequence != CollectCurrentAnimInfo(client, ANIM_THIRD) && sequence != CollectCurrentAnimInfo(client, ANIM_FOURTH) && sequence != CollectCurrentAnimInfo(client, ANIM_FIFTH))
    {
        damageBlocked[client] = false;
        SDKUnhook(client, SDKHook_PostThink, OnThink);
    }
}

stock bool:IsSurvivor(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

stock CollectCurrentAnimInfo(client, anim_type)
{
	new currentSurvivorAnim = 0;
	
	decl String:survCliMod[PLATFORM_MAX_PATH];
	GetClientModel(client, survCliMod, sizeof(survCliMod));
	if(StrEqual(survCliMod, "models/survivors/survivor_coach.mdl", false))
	{
		switch (anim_type)
		{
			case ANIM_FIRST: currentSurvivorAnim = 621;
			case ANIM_SECOND: currentSurvivorAnim = 656;
			case ANIM_THIRD: currentSurvivorAnim = 660;
			case ANIM_FOURTH: currentSurvivorAnim = 661;
			case ANIM_FIFTH: currentSurvivorAnim = 629;
		}
	}
	else if(StrEqual(survCliMod, "models/survivors/survivor_gambler.mdl", false))
	{
		switch (anim_type)
		{
			case ANIM_FIRST: currentSurvivorAnim = 620;
			case ANIM_SECOND: currentSurvivorAnim = 667;
			case ANIM_THIRD: currentSurvivorAnim = 671;
			case ANIM_FOURTH: currentSurvivorAnim = 672;
			case ANIM_FIFTH: currentSurvivorAnim = 629;
		}
	}
	else if(StrEqual(survCliMod, "models/survivors/survivor_producer.mdl", false))
	{
		switch (anim_type)
		{
			case ANIM_FIRST: currentSurvivorAnim = 629;
			case ANIM_SECOND: currentSurvivorAnim = 674;
			case ANIM_THIRD: currentSurvivorAnim = 678;
			case ANIM_FOURTH: currentSurvivorAnim = 679;
			case ANIM_FIFTH: currentSurvivorAnim = 637;
		}
	}
	else if(StrEqual(survCliMod, "models/survivors/survivor_mechanic.mdl", false))
	{
		switch (anim_type)
		{
			case ANIM_FIRST: currentSurvivorAnim = 625;
			case ANIM_SECOND: currentSurvivorAnim = 671;
			case ANIM_THIRD: currentSurvivorAnim = 675;
			case ANIM_FOURTH: currentSurvivorAnim = 676;
			case ANIM_FIFTH: currentSurvivorAnim = 634;
		}
	}
	else if(StrEqual(survCliMod, "models/survivors/survivor_manager.mdl", false))
	{
		switch (anim_type)
		{
			case ANIM_FIRST: currentSurvivorAnim = 528;
			case ANIM_SECOND: currentSurvivorAnim = 759;
			case ANIM_THIRD: currentSurvivorAnim = 763;
			case ANIM_FOURTH: currentSurvivorAnim = 764;
			case ANIM_FIFTH: currentSurvivorAnim = 537;
		}
	}
	else if(StrEqual(survCliMod, "models/survivors/survivor_teenangst.mdl", false))
	{
		switch (anim_type)
		{
			case ANIM_FIRST: currentSurvivorAnim = 537;
			case ANIM_SECOND: currentSurvivorAnim = 819;
			case ANIM_THIRD: currentSurvivorAnim = 823;
			case ANIM_FOURTH: currentSurvivorAnim = 824;
			case ANIM_FIFTH: currentSurvivorAnim = 546;
		}
	}
	else if(StrEqual(survCliMod, "models/survivors/survivor_namvet.mdl", false))
	{
		switch (anim_type)
		{
			case ANIM_FIRST: currentSurvivorAnim = 528;
			case ANIM_SECOND: currentSurvivorAnim = 759;
			case ANIM_THIRD: currentSurvivorAnim = 763;
			case ANIM_FOURTH: currentSurvivorAnim = 764;
			case ANIM_FIFTH: currentSurvivorAnim = 537;
		}
	}
	else if(StrEqual(survCliMod, "models/survivors/survivor_biker.mdl", false))
	{
		switch (anim_type)
		{
			case ANIM_FIRST: currentSurvivorAnim = 531;
			case ANIM_SECOND: currentSurvivorAnim = 762;
			case ANIM_THIRD: currentSurvivorAnim = 766;
			case ANIM_FOURTH: currentSurvivorAnim = 767;
			case ANIM_FIFTH: currentSurvivorAnim = 540;
		}
	}
	
	return currentSurvivorAnim;
}

