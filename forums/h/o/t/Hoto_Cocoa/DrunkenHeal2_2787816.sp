#include <sourcemod>
#include <tf2_stocks>


#define PLUGIN_VERSION  "2.0.0"

public Plugin:myinfo =
{
	name = "[TF2] Drunken Heal: Refilled",
	author = "DarthNinja, HotoCocoaco",
	description = "The booze! It heals!",
	version = PLUGIN_VERSION,
	url = "forums.alliedmods.net/showthread.php?t=173094"
};

ConVar g_iHealAmount;
ConVar g_fCooldown;
ConVar g_iBrokenBottle;

bool g_bIsSuddenDeath;
bool g_bIsCoolingDown[MAXPLAYERS+1] = false;
bool g_bIsDrinking[MAXPLAYERS+1] = false;

float g_vOrig[MAXPLAYERS+1][3];

public void OnPluginStart()
{
	g_iHealAmount = CreateConVar("sm_drunkenheal_amount", "15", "Amount Healed By Bottle - 0 disables plugin.");
	g_fCooldown = CreateConVar("sm_drunkenheal_cooldown", "0", "Heal Cooldown Time [In Seconds] | 0 = Disabled (Default 10)", 0, true, 0.0, false);
	g_iBrokenBottle = CreateConVar("sm_drunkenheal_broken", "3", "Broken Bottle: 0 = Heals nothing, 1 = Heals half value, 2 = Deals double, 3 = no change");

	AutoExecConfig(true, "DrunkenHeal");

	HookEvent("teamplay_round_stalemate", Event_SuddenDeathStart);
	HookEvent("teamplay_round_start", Event_SuddenDeathEnd);
	HookEvent("teamplay_round_win", Event_SuddenDeathEnd);
	HookEvent("post_inventory_application", Event_Regen);
}

void Event_SuddenDeathStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bIsSuddenDeath = true;
}

void Event_SuddenDeathEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bIsSuddenDeath = false;
}

void Event_Regen(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bIsCoolingDown[client] = false;
}

public void OnMapStart()
{
	g_bIsSuddenDeath = false;

	for(int i = 1; i <= MaxClients; i++)
	{
		g_bIsCoolingDown[i] = false;
		g_bIsDrinking[i] = false;
	}
}

public void OnClientDisconnect(int client)
{
	g_bIsCoolingDown[client] = false;
	g_bIsDrinking[client] = false;
}

// Use TF2_OnConditionAdded instead of RegConsoleCmd to detect if players use their taunt.
public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (condition == TFCond_Taunting)
	{
		if (!IsPlayerAlive(client) || TF2_GetPlayerClass(client) != TFClass_DemoMan || g_iHealAmount.IntValue == 0)
			return;

		if (g_bIsSuddenDeath)
		{
			PrintHintText(client, "Drunken Heal is Disabled in Sudden Death!");
			return;
		}

		int activeweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (activeweapon == -1)
			return;

		int index = GetEntProp(activeweapon, Prop_Send, "m_iItemDefinitionIndex");

		//---------------------------
		// 1	=	Bottle
		// 191	=	Custom Bottle
		// 609 = Scottish Handshake
		//---------------------------
		if (index == 1 || index == 191 || index == 609)
		{
			if (!g_bIsCoolingDown[client] && !g_bIsDrinking[client])
			{
				float cooldown = g_fCooldown.FloatValue;
				if (cooldown > 0)
				{
					g_bIsCoolingDown[client] = true;
					CreateTimer(cooldown, CooldownTimer, EntIndexToEntRef(client));
				}

				g_bIsDrinking[client] = true;
				GetClientAbsOrigin(client, g_vOrig[client]);

				CreateTimer(2.2, OnStartDrinking, EntIndexToEntRef(client));
				CreateTimer(4.0, OnFinishDrinking, EntIndexToEntRef(client));
			}
		}
	}
}

Action CooldownTimer(Handle timer, int ref)
{
	int client = EntRefToEntIndex(ref);
	if (client != INVALID_ENT_REFERENCE)
	{
		PrintHintText(client, "Your Bottle Is Full Again");
	}

	g_bIsCoolingDown[client] = false;

	return Plugin_Continue;
}

Action OnStartDrinking(Handle timer, int ref)
{
	int client = EntRefToEntIndex(ref);
	if (client != INVALID_ENT_REFERENCE && IsClientInGame(client) && IsPlayerAlive(client))
	{
		float new_origin[3];
		GetClientAbsOrigin(client, new_origin);
		if (!VectorEqual(g_vOrig[client], new_origin))
			return Plugin_Continue;	//Player changed location

		int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if (weapon == -1)
			return Plugin_Continue;	//No melee weapon

		int health = g_iHealAmount.IntValue;
		if (GetEntProp(weapon, Prop_Send, "m_bBroken") == 1)	//Bottle is broken
		{
			switch(g_iBrokenBottle.IntValue)
			{
			  case 0:
			  {
			  	health = 0;
			  }
				case 1:
				{
					health = RoundFloat(health * 0.5);
				}
				case 2:
				{
					health *= 2;
				}
			}
		}

		if (health == 0)
		{
			PrintHintText(client, "Sorry, ye cannot be swiggin' from a broken bottle!\n 0 damage healed.");
		}
		else
		{
			int currecthealth = GetClientHealth(client);
			int maxhealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
			if (currecthealth + health >= maxhealth)
			{
				SetEntityHealth(client, maxhealth);
			}
			else
			{
				SetEntityHealth(client, currecthealth + health);
			}

			PrintHintText(client, "Your Bottle Healed %i Health!", health);
		}
	}

	return Plugin_Continue;
}

Action OnFinishDrinking(Handle timer, int ref)
{
	int client = EntRefToEntIndex(ref);
	if (client != INVALID_ENT_REFERENCE)
	{
		g_bIsDrinking[client] = false;
	}

	return Plugin_Continue;
}

bool VectorEqual(float vec1[3], float vec2[3])
{
	for(int i = 0; i <= 2; i++)
	{
		if (vec1[i] != vec2[i])
		{
			return false;
		}
	}

	return true;
}
