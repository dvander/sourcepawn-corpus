/*****************************/
//Pragma
#pragma semicolon 1
//#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[TF2] Pre-Ambassador"
#define PLUGIN_DESCRIPTION "Changes the Ambassador to do 102 damage for headshots from any range."
#define PLUGIN_VERSION "1.0.0"

/*****************************/
//Includes
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

/*****************************/
//ConVars
ConVar convar_Enabled;

/*****************************/
//Globals

int g_CritParticle = INVALID_STRING_INDEX;

/*****************************/
//Plugin Info
public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = "Drixevel", 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	convar_Enabled = CreateConVar("sm_preambassador_enabled", "1", "Is this plugin enabled or disabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			OnClientPutInServer(i);
}

public void OnMapStart()
{
	PrecacheSound("player/crit_received1.wav");
	PrecacheSound("player/crit_hit.wav");
	
	int tblidx = FindStringTable("ParticleEffectNames");
	char tmp[128];
	
	for (int i = 0; i < GetStringTableNumStrings(tblidx); i++)
	{
		ReadStringTable(tblidx, i, tmp, sizeof(tmp));
		
		if (StrEqual(tmp, "crit_text", false))
		{
			g_CritParticle = i;
			break;
		}
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!convar_Enabled.BoolValue || !IsValidEntity(weapon))
		return Plugin_Continue;
	
	int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	
	if (damagecustom == TF_CUSTOM_HEADSHOT && (index == 61 || index == 1006))
	{
		if ((damagetype & DMG_ACID) != DMG_ACID)
		{
			EmitSoundToClient(victim, "player/crit_received1.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, 95);
			EmitSoundToClient(attacker, "player/crit_hit.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, 85);
			
			if (g_CritParticle != INVALID_STRING_INDEX)
			{
				float origin[3];
				GetEntPropVector(victim, Prop_Send, "m_vecOrigin", origin);
				
				TE_Start("TFParticleEffect");
				TE_WriteFloat("m_vecOrigin[0]", origin[0]);
				TE_WriteFloat("m_vecOrigin[1]", origin[1]);
				TE_WriteFloat("m_vecOrigin[2]", origin[2] + 56.0);
				TE_WriteNum("m_iParticleSystemIndex", g_CritParticle);

				TE_SendToClient(attacker);
			}
		}
		
		damage = 102.0;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}