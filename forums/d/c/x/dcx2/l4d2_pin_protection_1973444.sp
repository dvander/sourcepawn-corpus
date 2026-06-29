#include <sourcemod>

#define PLUGIN_VERSION "1.1"
#define PLUGIN_AUTHOR "dcx2"
#define PLUGIN_NAME "L4D2 Pin Protection"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY

#define CAN_JOCKEY_PROTECT(%1) (%1 & 1)
#define CAN_SMOKER_PROTECT(%1) (%1 & 2)

// %1 = attacker
#define GET_JOCKEY_VICTIM(%1) 		(GetEntPropEnt(%1, Prop_Send, "m_jockeyVictim"))
#define GET_SMOKER_VICTIM(%1) 		(GetEntPropEnt(%1, Prop_Send, "m_tongueVictim"))
#define GET_HUNTER_VICTIM(%1) 		(GetEntPropEnt(%1, Prop_Send, "m_pounceVictim"))

#define GET_INFECTED_CLASS(%1)		(GetEntProp(%1, Prop_Send, "m_zombieClass"))
#define ZC_HUNTER 3

// %1 = victim, [%2 = attacker]
#define SET_HUNTER_ATTACKER(%1,%2)  SetEntPropEnt(%1, Prop_Send, "m_pounceAttacker", %2)
#define SET_HUNTER_VICTIM(%1,%2) 	SetEntPropEnt(%2, Prop_Send, "m_pounceVictim", %1)
#define GET_HUNTER_ATTACKER(%1) 	(GetEntPropEnt(%1, Prop_Send, "m_pounceAttacker"))
#define GET_JOCKEY_ATTACKER(%1) 	(GetEntPropEnt(%1, Prop_Send, "m_jockeyAttacker"))

// %1 = client
#define IS_VALID_CLIENT(%1) (%1 > 0 && %1 <= MaxClients)
#define IS_CONNECTED_INGAME(%1) (IsClientConnected(%1) && IsClientInGame(%1))
#define IS_SURVIVOR(%1) (GetClientTeam(%1) == 2)
#define IS_INFECTED(%1) (GetClientTeam(%1) == 3)

#define IS_VALID_INGAME(%1) (IS_VALID_CLIENT(%1) && IS_CONNECTED_INGAME(%1))

#define IS_VALID_SURVIVOR(%1) (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1) (IS_VALID_INGAME(%1) && IS_INFECTED(%1))

#define IS_SURVIVOR_ALIVE(%1) (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1) (IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))

// %1 = current, %2 = last, %3 = mask
#define PRESSING(%1,%2,%3) (((%1 & %3) != (%2 & %3)) && ((%1 & %3) == %3))
#define RELEASING(%1,%2,%3) (((%1 & %3) != (%2 & %3)) && ((%2 & %3) == %3))

new g_lastButtons[MAXPLAYERS+1] = { 0, ... };
new g_ProtectPin[MAXPLAYERS+1] = { 0, ... };

new g_fEnabled = 0;


public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = "Allows jockeys and smokers to protect their pin from other infected by pressing crouch",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1973444"
};

public OnPluginStart()
{
	//cvars
	CreateConVar("l4d2_pinprot_ver", PLUGIN_VERSION, PLUGIN_NAME, CVAR_FLAGS|FCVAR_DONTRECORD);
	
	new Handle:cvarEnable = CreateConVar("l4d2_pinprot_enable", "3", "Enable bit flag (add together):\n1=Jockeys can protect pins, 2=Smokers can protect pins", CVAR_FLAGS);
	HookConVarChange(cvarEnable, OnPinProtEnableChanged);
	g_fEnabled = GetConVarInt(cvarEnable);
	
	HookEvent("player_bot_replace", Event_PlayerBotReplace);
	HookEvent("bot_player_replace", Event_PlayerBotReplace);
}

public OnPinProtEnableChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
	g_fEnabled = StringToInt(newVal);

public Action:Event_PlayerBotReplace(Handle:event, const String:name[], bool:dontBroadcast)
{
	// If either a bot or a player being replaced are under any kind of pin protection, remove it
	new bot = GetClientOfUserId(GetEventInt(event, "bot"));
	new player = GetClientOfUserId(GetEventInt(event, "player"));
	if (IS_VALID_SURVIVOR(bot) && IS_VALID_SURVIVOR(player))
	{
		new attacker = GetProtectedAttacker(bot);
		RemoveProtection(attacker);
		attacker = GetProtectedAttacker(player);
		RemoveProtection(attacker);
	}
}

public Action:OnPlayerRunCmd(client, &buttons)
{
	// If we aren't an in-game infected, or we're a bot, do nothing
	if (!g_fEnabled || !IS_VALID_INFECTED(client) || IsFakeClient(client)) return Plugin_Continue;
	
	new victim = 0;
	
	// When an alive infected presses duck...
	if (PRESSING(buttons, g_lastButtons[client], IN_DUCK) && IsPlayerAlive(client))
	{
		victim = GetSmokerJockeyVictim(client);
		
		if (IS_SURVIVOR_ALIVE(victim))
		{
			AddProtection(client, victim);
		}
		else g_ProtectPin[client] = 0;
	}
		
	if (g_ProtectPin[client])
	{
		victim = GetSmokerJockeyVictim(client);
		
		// If not ducking, not alive, or the client has neither jockey nor smoker victim
		if ((!(buttons & IN_DUCK)) || !IsPlayerAlive(client) || !IS_SURVIVOR_ALIVE(victim) || !IS_SURVIVOR_ALIVE(g_ProtectPin[client]) || victim != g_ProtectPin[client])
		{
			RemoveProtection(client);
		}
	}
	g_lastButtons[client] = buttons;
	return Plugin_Continue;
}

public AddProtection(attacker, victim)
{
	// Prevent the attacker's victim from being stolen by tricking the game
	// into thinking the survivor is pinned by a hunter
	g_ProtectPin[attacker] = victim;
	SET_HUNTER_ATTACKER(victim, attacker);
}

public RemoveProtection(attacker)
{
	new HunterAttacker=-1;
	if (IS_VALID_SURVIVOR(g_ProtectPin[attacker]))
	{
		HunterAttacker = GET_HUNTER_ATTACKER(g_ProtectPin[attacker]);
		if (HunterAttacker > 0 && (!IS_VALID_INFECTED(HunterAttacker) || GET_INFECTED_CLASS(HunterAttacker) != ZC_HUNTER))
		{
			SET_HUNTER_ATTACKER(g_ProtectPin[attacker], -1);
		}
	}
	g_ProtectPin[attacker] = 0;

	HunterAttacker=-1;
	
	if (IS_VALID_INFECTED(attacker))
	{
		// Should also check current victim, in case they were swapped
		new currentVictim = GetSmokerJockeyVictim(attacker);
		if (IS_VALID_SURVIVOR(currentVictim))
		{
			HunterAttacker = GET_HUNTER_ATTACKER(currentVictim);
			if (HunterAttacker > 0 && (!IS_VALID_INFECTED(HunterAttacker) || GET_INFECTED_CLASS(HunterAttacker) != ZC_HUNTER))
			{
				SET_HUNTER_ATTACKER(currentVictim, -1);
			}
		}
		
		// Also, when a swap happens, it appears the jockey somehow gets a hunter victim
		// So we have to clear that, or the jockey starts acting real weird
		if (IS_VALID_SURVIVOR(GET_HUNTER_VICTIM(attacker)))
		{
			SET_HUNTER_VICTIM(-1, attacker);
		}
	}
}

public GetProtectedAttacker(PotentialVictim)
{
	new attacker = 0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (g_ProtectPin[i] == PotentialVictim) 
		{
			attacker = i;
			break;
		}
	}
	return attacker;
}

public GetSmokerJockeyVictim(attacker)
{
	new victim = 0;
	
	if (CAN_JOCKEY_PROTECT(g_fEnabled) && IS_VALID_INFECTED(attacker))
	{
		victim = GET_JOCKEY_VICTIM(attacker);
	}
	
	if (victim <= 0 && CAN_SMOKER_PROTECT(g_fEnabled) && IS_VALID_INFECTED(attacker))
	{
		victim = GET_SMOKER_VICTIM(attacker);
	}
	
	return victim;
}
