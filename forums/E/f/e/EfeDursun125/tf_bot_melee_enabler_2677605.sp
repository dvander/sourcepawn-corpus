#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION  "1.3"

public Plugin myinfo = 
{
	name = "[TF2] TFBot Melee Enabler",
	author = "EfeDursun125",
	description = "This Plugin Allows Bots Use Melee Weapons.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/EfeDursun91/"
}


float g_flMeleeTimer[MAXPLAYERS + 1];

Handle TFBotMeleeRange;

public OnPluginStart()
{
	TFBotMeleeRange = CreateConVar("tf_bot_melee_range", "200.0", "", FCVAR_NONE, true, 0.0, false, _);
	HookEvent("player_hurt", BotHurt, EventHookMode_Post);
}

stock float moveForward(float vel[3], float MaxSpeed)
{
	vel[0] = MaxSpeed;
	return vel;
}

public Action OnPlayerRunCmd(int client, &buttons, &impulse, float vel[3])
{
	if (IsValidClient(client))
	{
		if (IsFakeClient(client))
		{
			if (IsPlayerAlive(client))
			{
				if (g_flMeleeTimer[client] > GetGameTime())
				{
					if (IsValidEntity(IsWeaponSlotActive(client, 2)) && !IsWeaponSlotActive(client, 5) && TF2_GetPlayerClass(client) != TFClass_Sniper && TF2_GetPlayerClass(client) != TFClass_Spy && TF2_GetPlayerClass(client) != TFClass_Engineer)
					{
						if (IsWeaponSlotActive(client, 2))
						{
							if (!TF2_IsPlayerInCondition(client, TFCond_RestrictToMelee))
								TF2_AddCondition(client, TFCond_RestrictToMelee, TFCondDuration_Infinite);
							else
							{
								buttons |= IN_ATTACK;
								vel = moveForward(vel, 400.0);
							}
						}
						else
							EquipWeaponSlot(client, 2);
					}
				}
				else if (TF2_IsPlayerInCondition(client, TFCond_RestrictToMelee))
					TF2_RemoveCondition(client, TFCond_RestrictToMelee);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action BotHurt(Handle event, const char[] name, bool dontBroadcast)
{
	int botclient = GetClientOfUserId(GetEventInt(event, "userid"));
	int target = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (IsValidClient(botclient) && IsFakeClient(botclient))
	{
		if (IsValidClient(target))
		{
			float clientEyes[3];
			GetClientEyePosition(botclient, clientEyes);
			
			float targetEyes[3];
			GetClientEyePosition(target, targetEyes);
			
			if (GetVectorDistance(clientEyes, targetEyes, true) <= GetConVarFloat(TFBotMeleeRange) * GetConVarFloat(TFBotMeleeRange))
				g_flMeleeTimer[botclient] = GetGameTime() + 2.0;
		}
	}
}

stock void EquipWeaponSlot(int client, int slot)
{
	int iWeapon = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(iWeapon))
		EquipWeapon(client, iWeapon);
}

stock void EquipWeapon(int client, int weapon)
{
	char class[80];
	GetEntityClassname(weapon, class, sizeof(class));
	Format(class, sizeof(class), "use %s", class);
	FakeClientCommandThrottled(client, class);
}

float g_flNextCommand[MAXPLAYERS + 1];
stock bool FakeClientCommandThrottled(int client, const char[] command)
{
	if (g_flNextCommand[client] > GetGameTime())
		return false;
	
	FakeClientCommand(client, command);
	g_flNextCommand[client] = GetGameTime() + 0.4;
	return true;
}

stock bool IsWeaponSlotActive(int client, int slot)
{
    return GetPlayerWeaponSlot(client, slot) == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}

stock bool IsValidClient(int client) 
{
    if (!(1 <= client <= MaxClients) || !IsClientInGame(client)) 
        return false; 
    return true; 
}  