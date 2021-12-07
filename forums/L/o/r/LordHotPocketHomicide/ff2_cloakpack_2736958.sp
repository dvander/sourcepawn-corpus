
#define DEBUG

#define PLUGIN_NAME           "ff2_cloakpack"

#define CLOAK_SPEED			  "cloakpack_speed"
#define CLOAK_STATUS		  "cloakpack_statinvuln"
#define CLOAK_NOBUMP		  "cloakpack_nocollision"
#define CLOAK_TRAIL			  "cloakpack_particles"
#define CLOAK_DMG			  "cloakpack_damage"
#define CLOAK_SOUNDS		  "cloakpack_noise"
#define CLOAK_OVERCHARGE	  "cloakpack_overcharge_bomb"
#define CLOAK_FIXMODEL		  "cloakpack_fixmodel"

#define CLOAK_FRAG			  "misc/halloween/spell_mirv_explode_secondary.wav"

#define PLUGIN_AUTHOR         "Spookmaster"
#define PLUGIN_DESCRIPTION    "Various simple abilities for bosses that use invis watches."
#define PLUGIN_VERSION        "1.0"
#define PLUGIN_URL            ""

#include <sourcemod>
#include <sdktools>
#include <freak_fortress_2>
#include <sdkhooks>
#include <tf2items>
#include <tf2_stocks>

#pragma semicolon 1
//#pragma newdecls required

float cloakspd[MAXPLAYERS+1] = {0.0, ...};
float contactDrain[MAXPLAYERS+1] = {0.0, ...};
float dmgMult[MAXPLAYERS+1] = {1.0, ...};
float dmgDrain[MAXPLAYERS+1] = {0.0, ...};
float actSpan[MAXPLAYERS+1] = {0.0, ...};
float deactSpan[MAXPLAYERS+1] = {0.0, ...};
float overcharge_BaseDMG[MAXPLAYERS+1] = {0.0, ...};
float overcharge_DPS[MAXPLAYERS+1] = {0.0, ...};
float overcharge_HitDMG[MAXPLAYERS+1] = {0.0, ...};
float overcharge_MaxDMG[MAXPLAYERS+1] = {0.0, ...};				
float overcharge_BaseRadius[MAXPLAYERS+1] = {0.0, ...};
float overcharge_RPS[MAXPLAYERS+1] = {0.0, ...};
float overcharge_HitRadius[MAXPLAYERS+1] = {0.0, ...};
float overcharge_MaxRadius[MAXPLAYERS+1] = {0.0, ...};
float overcharge_Falloff[MAXPLAYERS+1] = {0.0, ...};		
float overcharge_CDTime[MAXPLAYERS+1] = {0.0, ...};
float overcharge_RageCost[MAXPLAYERS+1] = {0.0, ...};
float overcharge_WarningTime[MAXPLAYERS+1] = {0.0, ...};
float overcharge_HUDX[MAXPLAYERS+1] = {0.0, ...};
float overcharge_HUDY[MAXPLAYERS+1] = {0.0, ...};
float overcharge_DMG[MAXPLAYERS+1] = {0.0, ...};
float overcharge_Radius[MAXPLAYERS+1] = {0.0, ...};
float overcharge_CD[MAXPLAYERS+1] = {0.0, ...};
float stuckRadius[MAXPLAYERS+1] = {0.0, ...};

bool cloakDown[MAXPLAYERS+1] = {false, ...};
bool gonnaExplode[MAXPLAYERS+1] = {false, ...};

int milkInv[MAXPLAYERS+1] = {0, ...};
int flameInv[MAXPLAYERS+1] = {0, ...};
int gasInv[MAXPLAYERS+1] = {0, ...};
int bleedInv[MAXPLAYERS+1] = {0, ...};
int pissInv[MAXPLAYERS+1] = {0, ...};
int markInv[MAXPLAYERS+1] = {0, ...};
int flickInv[MAXPLAYERS+1] = {0, ...};
int dazeInv[MAXPLAYERS+1] = {0, ...};
int decloakMethod[MAXPLAYERS+1] = {0, ...};
int overcharge_StatMode[MAXPLAYERS+1] = {0, ...};
int overcharge_Uber[MAXPLAYERS+1] = {0, ...};

char actPartN[MAXPLAYERS+1][256];
char actPartAtt[MAXPLAYERS+1][256];
char cloakPartN[MAXPLAYERS+1][256];
char cloakPartAtt[MAXPLAYERS+1][256];
char deactPartN[MAXPLAYERS+1][256];
char deactPartAtt[MAXPLAYERS+1][256];
char actNoise[MAXPLAYERS+1][256];
char cloakNoise[MAXPLAYERS+1][256];
char deactNoise[MAXPLAYERS+1][256];
char overcharge_WarningSound[MAXPLAYERS+1][256];
char overcharge_WarningMessage[MAXPLAYERS+1][256];
char overcharge_ExplosionSound[MAXPLAYERS+1][256];
char overcharge_ExplosionParticle[MAXPLAYERS+1][256];
char mainModel[MAXPLAYERS+1][256];

new playerParticle[MAXPLAYERS+1];
new part1[MAXPLAYERS+1];
new part2[MAXPLAYERS+1];


Handle loopTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
Handle HUDTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart()
{
	HookEvent("arena_round_start", roundStart);
}

public OnMapStart()
{
	PrecacheSound(CLOAK_FRAG, true);
}

public void roundStart(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			int bossIDX = FF2_GetBossIndex(client);
			if (bossIDX != -1)
			{
				if (FF2_HasAbility(bossIDX, PLUGIN_NAME, CLOAK_SPEED))
				{
					cloakspd[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_SPEED, "arg0", 0, 0.0);
				}
				if (FF2_HasAbility(bossIDX, PLUGIN_NAME, CLOAK_STATUS))
				{
					milkInv[client] = FF2_GetArgI(bossIDX, PLUGIN_NAME, CLOAK_STATUS, "arg0", 0, 0);
					flameInv[client] = FF2_GetArgI(bossIDX, PLUGIN_NAME, CLOAK_STATUS, "arg1", 1, 0);
					gasInv[client] = FF2_GetArgI(bossIDX, PLUGIN_NAME, CLOAK_STATUS, "arg2", 2, 0);
					bleedInv[client] = FF2_GetArgI(bossIDX, PLUGIN_NAME, CLOAK_STATUS, "arg3", 3, 0);
					pissInv[client] = FF2_GetArgI(bossIDX, PLUGIN_NAME, CLOAK_STATUS, "arg4", 4, 0);
					markInv[client] = FF2_GetArgI(bossIDX, PLUGIN_NAME, CLOAK_STATUS, "arg5", 5, 0);
					flickInv[client] = FF2_GetArgI(bossIDX, PLUGIN_NAME, CLOAK_STATUS, "arg6", 6, 0);
					dazeInv[client] = FF2_GetArgI(bossIDX, PLUGIN_NAME, CLOAK_STATUS, "arg7", 7, 0);
					
					SDKHook(client, SDKHook_PreThink, cloakStats);
				}
				if (FF2_HasAbility(bossIDX, PLUGIN_NAME, CLOAK_DMG))
				{
					dmgMult[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_DMG, "arg0", 0, 0.0);
					dmgDrain[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_SPEED, "arg1", 1, 0.0);
				}
				if (FF2_HasAbility(bossIDX, PLUGIN_NAME, CLOAK_NOBUMP))
				{
					contactDrain[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_NOBUMP, "arg0", 0, 0.0);
					decloakMethod[client] = FF2_GetArgI(bossIDX, PLUGIN_NAME, CLOAK_NOBUMP, "arg1", 1, 0);
					stuckRadius[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_NOBUMP, "arg2", 2, 90.0);
					
					cloakDown[client] = (GetClientButtons(client) & IN_ATTACK2) != 0;
				}
				if (FF2_HasAbility(bossIDX, PLUGIN_NAME, CLOAK_TRAIL))
				{
					FF2_GetArgS(bossIDX, PLUGIN_NAME, CLOAK_TRAIL, "arg0", 0, actPartN[client], 256);
					FF2_GetArgS(bossIDX, PLUGIN_NAME, CLOAK_TRAIL, "arg6", 6, actPartAtt[client], 256);
					
					FF2_GetArgS(bossIDX, PLUGIN_NAME, CLOAK_TRAIL, "arg1", 1, cloakPartN[client], 256);
					FF2_GetArgS(bossIDX, PLUGIN_NAME, CLOAK_TRAIL, "arg2", 2, cloakPartAtt[client], 256);
					
					FF2_GetArgS(bossIDX, PLUGIN_NAME, CLOAK_TRAIL, "arg3", 3, deactPartN[client], 256);
					FF2_GetArgS(bossIDX, PLUGIN_NAME, CLOAK_TRAIL, "arg7", 7, deactPartAtt[client], 256);
					
					actSpan[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_TRAIL, "arg4", 4, 0.0);
					deactSpan[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_TRAIL, "arg5", 5, 0.0);
				}
				if (FF2_HasAbility(bossIDX, PLUGIN_NAME, CLOAK_SOUNDS))
				{
					FF2_GetArgS(bossIDX, PLUGIN_NAME, CLOAK_SOUNDS, "arg0", 0, actNoise[client], 256);
					FF2_GetArgS(bossIDX, PLUGIN_NAME, CLOAK_SOUNDS, "arg2", 2, cloakNoise[client], 256);
					FF2_GetArgS(bossIDX, PLUGIN_NAME, CLOAK_SOUNDS, "arg4", 4, deactNoise[client], 256);
				}
				if (FF2_HasAbility(bossIDX, PLUGIN_NAME, CLOAK_OVERCHARGE))
				{
					overcharge_BaseDMG[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_OVERCHARGE, "arg0", 0, 0.0);
					overcharge_DPS[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_OVERCHARGE, "arg1", 1, 0.0);
					overcharge_HitDMG[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_OVERCHARGE, "arg2", 2, 0.0);
					overcharge_MaxDMG[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_OVERCHARGE, "arg3", 3, 0.0);
					
					overcharge_BaseRadius[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_OVERCHARGE, "arg4", 4, 0.0);
					overcharge_RPS[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_OVERCHARGE, "arg5", 5, 0.0);
					overcharge_HitRadius[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_OVERCHARGE, "arg6", 6, 0.0);
					overcharge_MaxRadius[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_OVERCHARGE, "arg7", 7, 0.0);
					overcharge_Falloff[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_OVERCHARGE, "arg8", 8, 0.0);
					
					overcharge_CDTime[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_OVERCHARGE, "arg9", 9, 0.0);
					overcharge_RageCost[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_OVERCHARGE, "arg10", 10, 0.0);
					overcharge_WarningTime[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_OVERCHARGE, "arg11", 11, 0.0);
					
					FF2_GetArgS(bossIDX, PLUGIN_NAME, CLOAK_OVERCHARGE, "arg12", 12, overcharge_WarningSound[client], 256);
					FF2_GetArgS(bossIDX, PLUGIN_NAME, CLOAK_OVERCHARGE, "arg13", 13, overcharge_WarningMessage[client], 256);
					FF2_GetArgS(bossIDX, PLUGIN_NAME, CLOAK_OVERCHARGE, "arg14", 14, overcharge_ExplosionSound[client], 256);
					FF2_GetArgS(bossIDX, PLUGIN_NAME, CLOAK_OVERCHARGE, "arg19", 19, overcharge_ExplosionParticle[client], 256);
					
					overcharge_StatMode[client] = FF2_GetArgI(bossIDX, PLUGIN_NAME, CLOAK_OVERCHARGE, "arg15", 15, 0);
					
					overcharge_HUDX[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_OVERCHARGE, "arg16", 16, 0.0);
					overcharge_HUDY[client] = FF2_GetArgF(bossIDX, PLUGIN_NAME, CLOAK_OVERCHARGE, "arg17", 17, 0.0);
					
					overcharge_Uber[client] = FF2_GetArgI(bossIDX, PLUGIN_NAME, CLOAK_OVERCHARGE, "arg18", 18, 0);
					
					overcharge_DMG[client] = overcharge_BaseDMG[client];
					overcharge_Radius[client] = overcharge_BaseRadius[client];
					overcharge_CD[client] = overcharge_CDTime[client];
					
					HUDTimer[client] = CreateTimer(0.1, overcharge_HUD, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				if (FF2_HasAbility(bossIDX, PLUGIN_NAME, CLOAK_FIXMODEL))
				{
					GetClientModel(client, mainModel[client], 256);
				}
			}
		}
	}
	HookEvent("player_death", player_killed);
	HookEvent("teamplay_round_win", cloakEnd);
}

public void setModel(int client, char model[256])
{
	if (IsValidClient(client)/* && FileExists(model)*/)
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}
	/*else if (!FileExists(model))
	{
		LogError("[Cloak Pack] Failed to set the model: model is invalid.");
	}*/
}

public Action overcharge_HUD(Handle overcharge_HUD, int client)
{
	if (IsValidClient(client))
	{
		if (FF2_GetBossIndex(client) != -1 && FF2_GetRoundState() == 1 && IsPlayerAlive(client))
		{
			if (FF2_HasAbility(FF2_GetBossIndex(client), PLUGIN_NAME, CLOAK_OVERCHARGE))
			{
				incrementDMG(client, overcharge_DPS[client]);
				incrementRadius(client, overcharge_RPS[client]);
				if (gonnaExplode[client] && !StrEqual(overcharge_WarningMessage[client], ""))
				{
					SetHudTextParams(overcharge_HUDX[client], overcharge_HUDY[client], 0.1, 255, 0, 0, 255);
					for (int i = 1; i <= MaxClients; i++)
					{
						if (IsValidClient(i))
						{
							if (IsPlayerAlive(i) && TF2_GetClientTeam(i) != TF2_GetClientTeam(client))
							{
								ShowHudText(i, -1, overcharge_WarningMessage[client]);
							}
						}
					}
				}
				else if (overcharge_CD[client] >= 0.1)
				{
					overcharge_CD[client] += -0.1;
					if (overcharge_CD[client] < 0.1)
					{
						overcharge_CD[client] = 0.0;
					}
					SetHudTextParams(overcharge_HUDX[client], overcharge_HUDY[client], 0.1, 255, 0, 0, 255);
					ShowHudText(client, -1, "Cloak Overcharge is currently on cooldown (%is). Your stats:\nRADIUS: %i | BASE DAMAGE: %i", RoundFloat(overcharge_CD[client]), RoundFloat(overcharge_Radius[client]), RoundFloat(overcharge_DMG[client]));
				}
				else if (FF2_GetBossCharge(FF2_GetBossIndex(client), 0) < overcharge_RageCost[client])
				{
					SetHudTextParams(overcharge_HUDX[client], overcharge_HUDY[client], 0.1, 255, 0, 0, 255);
					ShowHudText(client, -1, "You don't have enough rage to use Cloak Overcharge (Cost: %i%) Your stats:\nRADIUS: %i | BASE DAMAGE: %i", RoundFloat(overcharge_RageCost[client]), RoundFloat(overcharge_Radius[client]), RoundFloat(overcharge_DMG[client]));
				}
				else if (!TF2_IsPlayerInCondition(client, TFCond_Cloaked))
				{
					if (overcharge_StatMode[client] == 1)
					{
						overcharge_DMG[client] = overcharge_BaseDMG[client];
						overcharge_Radius[client] = overcharge_BaseRadius[client];
					}
					SetHudTextParams(overcharge_HUDX[client], overcharge_HUDY[client], 0.1, 255, 255, 255, 255);
					ShowHudText(client, -1, "Cloak Overcharge is ready. Cloak to charge. Your stats:\nRADIUS: %i | BASE DAMAGE: %i", RoundFloat(overcharge_Radius[client]), RoundFloat(overcharge_DMG[client]));
				}
				else if (TF2_IsPlayerInCondition(client, TFCond_Cloaked))
				{
					SetHudTextParams(overcharge_HUDX[client], overcharge_HUDY[client], 0.1, 0, 0, 255, 255);
					ShowHudText(client, -1, "Your cloak is about to overcharge. Decloak to explode!\nYour stats, if activated now:\nRADIUS: %i | BASE DAMAGE: %i", RoundFloat(overcharge_Radius[client]), RoundFloat(overcharge_DMG[client]));
				}
			}
			else
			{
				KillTimer(HUDTimer[client]);
				HUDTimer[client] = INVALID_HANDLE;
			}
		}
		else if (FF2_GetBossIndex(client) == -1)
		{
			KillTimer(HUDTimer[client]);
			HUDTimer[client] = INVALID_HANDLE;
		}
		else if (FF2_GetRoundState() == 2)
		{
			KillTimer(HUDTimer[client]);
			HUDTimer[client] = INVALID_HANDLE;
		}
		else if (!IsPlayerAlive(client))
		{
			KillTimer(HUDTimer[client]);
			HUDTimer[client] = INVALID_HANDLE;
		}
	}
	else
	{
		KillTimer(HUDTimer[client]);
		HUDTimer[client] = INVALID_HANDLE;
	}
}

public void incrementDMG(int client, float amt)
{
	if (IsValidClient(client))
	{
		if (FF2_GetBossIndex(client) != -1 && FF2_GetRoundState() == 1 && IsPlayerAlive(client) && TF2_IsPlayerInCondition(client, TFCond_Cloaked))
		{
			if (FF2_HasAbility(FF2_GetBossIndex(client), PLUGIN_NAME, CLOAK_OVERCHARGE))
			{
				overcharge_DMG[client] += amt;
				if (overcharge_DMG[client] > overcharge_MaxDMG[client])
				{
					overcharge_DMG[client] = overcharge_MaxDMG[client];
				}
			}
		}
	}
}
public void incrementRadius(int client, float amt)
{
	if (IsValidClient(client))
	{
		if (FF2_GetBossIndex(client) != -1 && FF2_GetRoundState() == 1 && IsPlayerAlive(client) && TF2_IsPlayerInCondition(client, TFCond_Cloaked))
		{
			if (FF2_HasAbility(FF2_GetBossIndex(client), PLUGIN_NAME, CLOAK_OVERCHARGE))
			{
				overcharge_Radius[client] *= amt;
				if (overcharge_Radius[client] > overcharge_MaxRadius[client])
				{
					overcharge_Radius[client] = overcharge_MaxRadius[client];
				}
			}
		}
	}
}

public Action cloakStats(client)
{		
	if (IsValidClient(client))
	{
		if (TF2_IsPlayerInCondition(client, TFCond_Cloaked))
		{
			if (TF2_IsPlayerInCondition(client, TFCond_Milked) && milkInv[client] != 0)
			{
				TF2_RemoveCondition(client, TFCond_Milked);
			}
			if (TF2_IsPlayerInCondition(client, TFCond_OnFire) && flameInv[client] != 0)
			{
				TF2_RemoveCondition(client, TFCond_OnFire);
			}
			if (TF2_IsPlayerInCondition(client, TFCond_Gas) && gasInv[client] != 0)
			{
				TF2_RemoveCondition(client, TFCond_Gas);
			}
			if (TF2_IsPlayerInCondition(client, TFCond_Bleeding) && bleedInv[client] != 0)
			{
				TF2_RemoveCondition(client, TFCond_Bleeding);
			}
			if (TF2_IsPlayerInCondition(client, TFCond_Jarated) && pissInv[client] != 0)
			{
				TF2_RemoveCondition(client, TFCond_Jarated);
			}
			if (TF2_IsPlayerInCondition(client, TFCond_MarkedForDeath) && markInv[client] != 0)
			{
				TF2_RemoveCondition(client, TFCond_MarkedForDeath);
			}
			if (TF2_IsPlayerInCondition(client, TFCond_MarkedForDeathSilent) && markInv[client] != 0)
			{
				TF2_RemoveCondition(client, TFCond_MarkedForDeathSilent);
			}
			if (TF2_IsPlayerInCondition(client, TFCond_CloakFlicker) && flickInv[client] != 0)
			{
				TF2_RemoveCondition(client, TFCond_CloakFlicker);
			}
			if (TF2_IsPlayerInCondition(client, TFCond_Dazed) && dazeInv[client] != 0)
			{
				TF2_RemoveCondition(client, TFCond_Dazed);
			}
		}
	}
}

public Action cloakSpeed(client)
{		
	if (IsValidClient(client) && FF2_GetRoundState() == 1)
	{
		if (cloakspd[client] > 0.0)
		{
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", cloakspd[client]);
		}
		else
		{
			LogError("[Cloak Pack] ERROR: A VALUE LESS THAN/EQUAL TO 0.0 HAS BEEN USED FOR CLOAK SPEED! Exiting speed hook.");
			SDKUnhook(client, SDKHook_PreThink, cloakSpeed);
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	new bool:cloakDown2 = (buttons & IN_ATTACK2) != 0;
	if (IsValidClient(client))
	{
		if (cloakDown2 && !cloakDown[client])
		{
			int idx = FF2_GetBossIndex(client);
			if (idx != -1 && FF2_HasAbility(idx, PLUGIN_NAME, CLOAK_NOBUMP) && TF2_IsPlayerInCondition(client, TFCond_Cloaked) && decloakMethod[client] == 0)
			{
				float cloakLoc[3];
				GetClientAbsOrigin(client, cloakLoc);
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i))
					{
						if (IsPlayerAlive(i) && TF2_GetClientTeam(i) != TF2_GetClientTeam(client))
						{
							float playerLoc[3];
							GetClientAbsOrigin(i, playerLoc);
							if (GetVectorDistance(cloakLoc, playerLoc) <= stuckRadius[client])
							{
								return Plugin_Handled;
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public void TF2_OnConditionAdded(int client, TFCond cond)
{
	if (IsValidClient(client))
	{
		int idx = FF2_GetBossIndex(client);
		if (idx != -1 && IsPlayerAlive(client))
		{
			if (cond == TFCond_Cloaked)
			{
				if (FF2_HasAbility(idx, PLUGIN_NAME, CLOAK_NOBUMP))
				{
					SDKHook(client, SDKHook_PreThink, blockBumpPrethink);
				}
				if (FF2_HasAbility(idx, PLUGIN_NAME, CLOAK_SPEED))
				{
					SDKHook(client, SDKHook_PreThink, cloakSpeed);
				}
				if (FF2_HasAbility(idx, PLUGIN_NAME, CLOAK_DMG))
				{
					SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
				}
				if (FF2_HasAbility(idx, PLUGIN_NAME, CLOAK_TRAIL))
				{
					if (!StrEqual(actPartN[client], ""))
					{
						float partpos[3];
						GetClientAbsOrigin(client, partpos);
						spawnParticle1(actPartN[client], partpos, client, actPartAtt[client]);
					}
					if (!StrEqual(cloakPartN[client], ""))
					{
						attachParticle(client, cloakPartN[client], cloakPartAtt[client]);
					}
				}
				if (FF2_HasAbility(idx, PLUGIN_NAME, CLOAK_SOUNDS))
				{
					playNoise(actNoise[client], client, "", FF2_GetArgI(idx, PLUGIN_NAME, CLOAK_SOUNDS, "arg1", 1, 0));
					playNoise(cloakNoise[client], client, "", FF2_GetArgI(idx, PLUGIN_NAME, CLOAK_SOUNDS, "arg3", 3, 0));
					if (!StrEqual(cloakNoise[client], ""))
					{
						loopTimer[client] = CreateTimer(FF2_GetArgF(idx, PLUGIN_NAME, CLOAK_SOUNDS, "arg7", 7, 0.0), loopSound, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				if (FF2_HasAbility(idx, PLUGIN_NAME, CLOAK_OVERCHARGE))
				{
					SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage_Overcharge);
				}
				if (FF2_HasAbility(idx, PLUGIN_NAME, CLOAK_FIXMODEL))
				{
					setModel(client, "models/player/spy.mdl");
				}
			}
			else if (cond == TFCond_CloakFlicker)
			{
				if (flickInv[client] != 0)
				{
					TF2_RemoveCondition(client, TFCond_CloakFlicker);
				}
			}
		}
	}
}

public Action loopSound(Handle loopSound, int client)
{
	for (int client2 = 1; client2 <= MaxClients; client2++)
	{
		StopSound(client2, SNDCHAN_AUTO, cloakNoise[client]);
	}
	
	if (!IsValidClient(client))
	{
		KillTimer(loopTimer[client]);
		loopTimer[client] = INVALID_HANDLE;
	}
	
	if (!IsPlayerAlive(client) || !TF2_IsPlayerInCondition(client, TFCond_Cloaked) || FF2_GetBossIndex(client) == -1)
	{
		KillTimer(loopTimer[client]);
		loopTimer[client] = INVALID_HANDLE;
	}
	
	playNoise(cloakNoise[client], client, "", FF2_GetArgI(FF2_GetBossIndex(client), PLUGIN_NAME, CLOAK_SOUNDS, "arg3", 3, 0));
}

stock Handle attachParticle(int client, char type[256], char point[256])
{
	if (IsValidClient(client))
	{
		playerParticle[client] = CreateEntityByName("info_particle_system");
		
		if (IsValidEdict(playerParticle[client]))
		{
			decl Float:pos[3];
			GetClientAbsOrigin(client, pos);
			TeleportEntity(playerParticle[client], pos, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(playerParticle[client], "effect_name", type);
			SetVariantString("!activator");
			if (!StrEqual(point, ""))
			{
				AcceptEntityInput(playerParticle[client], "SetParent", client, playerParticle[client], 0);
				SetVariantString(point);
				AcceptEntityInput(playerParticle[client], "SetParentAttachmentMaintainOffset", playerParticle[client], playerParticle[client], 0);
			}
			DispatchKeyValue(playerParticle[client], "targetname", "present");
			DispatchSpawn(playerParticle[client]);
			ActivateEntity(playerParticle[client]);
			AcceptEntityInput(playerParticle[client], "Start");
		}
		else
		{
			LogError("(CreateParticle): Could not create info_particle_system");
		}
	}
	return INVALID_HANDLE;
}

stock Handle spawnParticle1(char type[256], float partpos[3], int client, char point[256]) //I am aware that using 2 separate particle spawning methods was perhaps the dumbest way I could've done this, but I'm lazy.
{
	if (IsValidClient(client))
	{
		part1[client] = CreateEntityByName("info_particle_system");
		
		if (IsValidEdict(part1[client]))
		{
			TeleportEntity(part1[client], partpos, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(part1[client], "effect_name", type);
			SetVariantString("!activator");
			if (!StrEqual(point, ""))
			{
				AcceptEntityInput(part1[client], "SetParent", client, part1[client], 0);
				SetVariantString(point);
				AcceptEntityInput(part1[client], "SetParentAttachmentMaintainOffset", part1[client], part1[client], 0);
			}
			DispatchKeyValue(part1[client], "targetname", "present");
			DispatchSpawn(part1[client]);
			ActivateEntity(part1[client]);
			AcceptEntityInput(part1[client], "Start");
			if (actSpan[client] > 0.0)
			{
				CreateTimer(actSpan[client], deleteit1, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else
		{
			LogError("(CreateParticle): Could not create info_particle_system");
		}
	}
	return INVALID_HANDLE;
}

public Action deleteit1(Handle deleteit1, int client)
{
	if (IsValidEdict(part1[client]))
	{
		char classname[64];
		
		GetEdictClassname(part1[client], classname, sizeof(classname));
		
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(part1[client], "Stop");
			AcceptEntityInput(part1[client], "Kill");
		}
	}
}

public Action blockBumpPrethink(client)
{	
	if (IsValidClient(client))
	{
		int idx = FF2_GetBossIndex(client);
		if (idx != -1 && IsPlayerAlive(client))
		{
			SetEntProp(client, Prop_Data, "m_CollisionGroup", 2); 
			float cloakLoc[3];
			GetClientAbsOrigin(client, cloakLoc);
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && i != client)
				{
					if (IsPlayerAlive(i))
					{
						float yourLoc[3];
						GetClientAbsOrigin(i, yourLoc);
						if (GetVectorDistance(cloakLoc, yourLoc) <= stuckRadius[client])
						{
							float cloak = GetEntPropFloat(client, Prop_Send, "m_flCloakMeter");
							if (contactDrain[client] > 0.0)
							{
								cloak = cloak - contactDrain[client];
								if (cloak > 1.0)
								{
									SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", cloak);
								}
							}
							if (cloak <= 1.0 && decloakMethod[client] == 0) //If the user would run out of cloak while inside of an enemy player, extend their cloak until they're out of range (prevents players from getting stuck inside each other)
							{
								SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", 2.0);
							}
							SetEntProp(i, Prop_Data, "m_CollisionGroup", 2);
						}
						else
						{
							SetEntProp(i, Prop_Data, "m_CollisionGroup", 5); 
						}
					}
				}
			}
		}
	}
}

public void TF2_OnConditionRemoved(int client, TFCond cond)
{
	if (IsValidClient(client))
	{
		int idx = FF2_GetBossIndex(client);
		if (cond == TFCond_Cloaked)
		{
			if (idx != -1)
			{
				if (FF2_HasAbility(idx, PLUGIN_NAME, CLOAK_NOBUMP))
				{
					float cloakLoc[3];
					GetClientAbsOrigin(client, cloakLoc);
					if (decloakMethod[client] == 2)
					{
						for (int h = 1; h <= MaxClients; h++)
						{
							if (IsValidClient(h))
							{
								if (IsPlayerAlive(h) && TF2_GetClientTeam(h) != TF2_GetClientTeam(client))
								{
									float playerLoc[3];
									GetClientAbsOrigin(h, playerLoc);
									if (GetVectorDistance(cloakLoc, playerLoc) <= stuckRadius[client])
									{
										SDKHooks_TakeDamage(h, client, client, 999.0, DMG_CRIT|DMG_BLAST|DMG_CLUB|DMG_ALWAYSGIB);
										EmitSoundToAll(CLOAK_FRAG, client);
									}
								}
							}
						}
					}
					SDKUnhook(client, SDKHook_PreThink, blockBumpPrethink);
					for (int i = 1; i <= MaxClients; i++)
					{
						if (IsValidClient(i))
						{
							SetEntProp(i, Prop_Data, "m_CollisionGroup", 5); 
						}
					}
				}
				if (FF2_HasAbility(idx, PLUGIN_NAME, CLOAK_SPEED))
				{
					SDKUnhook(client, SDKHook_PreThink, cloakSpeed);
				}
				if (FF2_HasAbility(idx, PLUGIN_NAME, CLOAK_DMG))
				{
					SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
				}
				if (FF2_HasAbility(idx, PLUGIN_NAME, CLOAK_TRAIL))
				{
					DeleteParticle(client);
					if (!StrEqual(deactPartN[client], ""))
					{
						float partLoc[3];
						GetClientAbsOrigin(client, partLoc);
						spawnParticle2(deactPartN[client], partLoc, client, deactPartAtt[client]);
					}
				}
				if (FF2_HasAbility(idx, PLUGIN_NAME, CLOAK_SOUNDS))
				{
					playNoise(deactNoise[client], client, cloakNoise[client], FF2_GetArgI(idx, PLUGIN_NAME, CLOAK_SOUNDS, "arg5", 5, 0));
					for (int client2 = 1; client2 <= MaxClients; client2++)
					{
						StopSound(client2, SNDCHAN_AUTO, cloakNoise[client]);
					}
					if (loopTimer[client] != INVALID_HANDLE)
					{
						KillTimer(loopTimer[client]);
					}
					loopTimer[client] = INVALID_HANDLE;
				}
				if (FF2_HasAbility(idx, PLUGIN_NAME, CLOAK_OVERCHARGE))
				{
					SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage_Overcharge);
					if (FF2_GetBossCharge(idx, 0) >= overcharge_RageCost[client] && overcharge_CD[client] < 0.1)
					{
						if (overcharge_WarningTime[client] > 0.0)
						{
							TF2_StunPlayer(client, overcharge_WarningTime[client], 0.0, TF_STUNFLAG_BONKSTUCK);
							TF2_AddCondition(client, TFCond_MegaHeal, overcharge_WarningTime[client]);
							if (overcharge_Uber[client] != 0)
							{
								TF2_AddCondition(client, TFCond_Ubercharged, overcharge_WarningTime[client]);
							}
							if (!StrEqual(overcharge_WarningSound[client], ""))
							{
								EmitSoundToAll(overcharge_WarningSound[client], client, _, SNDLEVEL_GUNFIRE);
							}
							CreateTimer(overcharge_WarningTime[client], overchargeBombTimer, client, TIMER_FLAG_NO_MAPCHANGE);
							gonnaExplode[client] = true;
						}
						else
						{
							TriggerOvercharge(client);
						}
					}
				}
				if (FF2_HasAbility(idx, PLUGIN_NAME, CLOAK_FIXMODEL))
				{
					setModel(client, mainModel[client]);
				}
			}
		}
	}
}

public Action overchargeBombTimer(Handle overchargeBombTimer, int client)
{
	if (IsValidClient(client))
	{
		if (FF2_GetBossIndex(client) != -1 && FF2_GetRoundState() == 1 && IsPlayerAlive(client))
		{
			if (FF2_HasAbility(FF2_GetBossIndex(client), PLUGIN_NAME, CLOAK_OVERCHARGE))
			{
				gonnaExplode[client] = false;
				TriggerOvercharge(client);
			}
		}
	}
}

public void TriggerOvercharge(int client)
{
	if (IsValidClient(client))
	{
		if (FF2_GetBossIndex(client) != -1 && FF2_GetRoundState() == 1 && IsPlayerAlive(client))
		{
			if (FF2_HasAbility(FF2_GetBossIndex(client), PLUGIN_NAME, CLOAK_OVERCHARGE))
			{
				if (!StrEqual(overcharge_ExplosionSound[client], ""))
				{
					EmitSoundToAll(overcharge_ExplosionSound[client], client, _, SNDLEVEL_GUNFIRE);
				}
				
				new particle = CreateEntityByName("info_particle_system");
				
				if (IsValidEdict(particle))
				{
					float pos[3];
					GetClientAbsOrigin(client, pos);
					TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
					DispatchKeyValue(particle, "effect_name", overcharge_ExplosionParticle[client]);
					DispatchKeyValue(particle, "targetname", "present");
					DispatchSpawn(particle);
					ActivateEntity(particle);
					AcceptEntityInput(particle, "Start");
				}
				else
				{
					LogError("(CreateParticle): Could not create info_particle_system");
				}
				
				FF2_SetBossCharge(FF2_GetBossIndex(client), 0, FF2_GetBossCharge(FF2_GetBossIndex(client), 0) - overcharge_RageCost[client]);
				float overLoc[3];
				GetClientAbsOrigin(client, overLoc);
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i))
					{
						if (IsPlayerAlive(i) && !IsInvuln(i) && TF2_GetClientTeam(i) != TF2_GetClientTeam(client))
						{
							float targLoc[3];
							GetClientAbsOrigin(i, targLoc);
							float dist = GetVectorDistance(overLoc, targLoc);
							if (dist <= overcharge_Radius[client])
							{
								float dmg = overcharge_DMG[client];
								if (overcharge_Falloff[client] != 1.0)
								{
									dmg = ((dist/overcharge_Radius[client]) * dmg)/overcharge_Falloff[client];
								}
								SDKHooks_TakeDamage(i, client, client, dmg, DMG_CLUB|DMG_BLAST|DMG_ALWAYSGIB);
							}
						}
					}
				}
				overcharge_DMG[client] = overcharge_BaseDMG[client];
				overcharge_Radius[client] = overcharge_BaseRadius[client];
			}
		}
	}
}

public void playNoise(char noise[256], int source, char stopNoise[256], int volume)
{
	//char path[256] = "sound/";
	if (!StrEqual(stopNoise, "", true))
	{
		//StrCat(path, 256, stopNoise);
		//if (FileExists(path))
		//{
		for (int client = 1; client <= MaxClients; client++)
		{
			StopSound(client, SNDCHAN_AUTO, stopNoise);
		}
		//}
		//else
		//{
		//	LogError("[Cloak Pack: Noise] ERROR: Unidentified file ''%s'' not found.", path);
		//}
		//path = "sound/";
	}
	if (!StrEqual(noise, ""))
	{
		//StrCat(path, 256, noise);
		//if (FileExists(path))
		//{
		if (IsValidClient(source))
		{
			if (FF2_GetBossIndex(source) != -1)
			{
				if (FF2_GetArgI(FF2_GetBossIndex(source), PLUGIN_NAME, CLOAK_SOUNDS, "arg6", 6, 0) != 0)
				{
					EmitSoundToAll(noise, source, _, volume);
				}
				else
				{
					for (int client2 = 1; client2 <= MaxClients; client2++)
					{
						if(IsValidClient(client2))
						{
							if (client2 != source)
							{
								EmitSoundToClient(client2, noise, source, _, volume);
							}
						}
					}
				}
			}
		}
		//}
		//else
		//{
		//	LogError("[Cloak Pack: Noise] ERROR: Unidentified file ''%s'' not found.", path);
		//}
	}
}

stock Handle spawnParticle2(char type[256], float partpos[3], int client, char point[256])
{
	if (IsValidClient(client))
	{
		part2[client] = CreateEntityByName("info_particle_system");
		
		if (IsValidEdict(part2[client]))
		{
			TeleportEntity(part2[client], partpos, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(part2[client], "effect_name", type);
			SetVariantString("!activator");
			if (!StrEqual(point, ""))
			{
				AcceptEntityInput(part2[client], "SetParent", client, part2[client], 0);
				SetVariantString(point);
				AcceptEntityInput(part2[client], "SetParentAttachmentMaintainOffset", part2[client], part2[client], 0);
			}
			DispatchKeyValue(part2[client], "targetname", "present");
			DispatchSpawn(part2[client]);
			ActivateEntity(part2[client]);
			AcceptEntityInput(part2[client], "Start");
			if (deactSpan[client] > 0.0)
			{
				CreateTimer(actSpan[client], deleteit2, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else
		{
			LogError("(CreateParticle): Could not create info_particle_system");
		}
	}
	return INVALID_HANDLE;
}

public Action deleteit2(Handle deleteit1, int client)
{
	if (IsValidEdict(part2[client]))
	{
		char classname[64];
		
		GetEdictClassname(part2[client], classname, sizeof(classname));
		
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(part2[client], "Stop");
			AcceptEntityInput(part2[client], "Kill");
		}
	}
}

public Action DeleteParticle(int client)
{
	if (IsValidEdict(playerParticle[client]))
	{
		char classname[64];
		
		GetEdictClassname(playerParticle[client], classname, sizeof(classname));
		
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(playerParticle[client], "Stop");
			AcceptEntityInput(playerParticle[client], "Kill");
		}
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon,
	Float:damageForce[3], Float:damageposition[3], damagecustom)
{
	if (IsValidClient(victim))
	{
		if (dmgDrain[victim] != 0.0)
		{
			float cloak = GetEntPropFloat(victim, Prop_Send, "m_flCloakMeter");
			if (cloak - dmgDrain[victim] >= 0.0)
			{
				SetEntPropFloat(victim, Prop_Send, "m_flCloakMeter", cloak - dmgDrain[victim]);
			}
		}
		if (dmgMult[victim] != 1.0)
		{
			damage *= dmgMult[victim];
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action:OnTakeDamage_Overcharge(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon,
	Float:damageForce[3], Float:damageposition[3], damagecustom)
{
	if (IsValidClient(victim))
	{
		incrementDMG(victim, overcharge_HitDMG[victim] * damage);
		incrementRadius(victim, overcharge_HitRadius[victim] * damage);
	}
	return Plugin_Continue;
}

public void cloakEnd(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			DeleteEverything(client);
		}
	}
	UnhookEvent("teamplay_round_win", cloakEnd);
}

public Action player_killed(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if (IsValidClient(client))
	{
		DeleteEverything(client);
	}
}

public void DeleteEverything(int client)
{
	if (IsValidClient(client))
	{
		cloakspd[client] = 0.0;
		dmgMult[client] = 1.0;
		dmgDrain[client] = 0.0;
		contactDrain[client] = 0.0;
		overcharge_BaseDMG[client] = 0.0;
		overcharge_DPS[client] = 0.0;
		overcharge_HitDMG[client] = 0.0;
		overcharge_MaxDMG[client] = 0.0;
		overcharge_BaseRadius[client] = 0.0;
		overcharge_RPS[client] = 0.0;
		overcharge_HitRadius[client] = 0.0;
		overcharge_MaxRadius[client] = 0.0;
		overcharge_Falloff[client] = 0.0;
		overcharge_CDTime[client] = 0.0;
		overcharge_RageCost[client] = 0.0;
		overcharge_WarningTime[client] = 0.0;
		overcharge_HUDX[client] = 0.0;
		overcharge_HUDY[client] = 0.0;
		overcharge_DMG[client] = 0.0;
		overcharge_Radius[client] = 0.0;
		overcharge_CD[client] = 0.0;
		
		milkInv[client] = 0;
		flameInv[client] = 0;
		gasInv[client] = 0;
		bleedInv[client] = 0;
		pissInv[client] = 0;
		markInv[client] = 0;
		flickInv[client] = 0;
		dazeInv[client] = 0;
		decloakMethod[client] = 0;
		overcharge_StatMode[client] = 0;
		overcharge_Uber[client] = 0;
		
		actPartN[client] = "";
		cloakPartN[client] = "";
		cloakPartAtt[client] = "";
		deactPartN[client] = "";
		actNoise[client] = "";
		cloakNoise[client] = "";
		deactNoise[client] = "";
		overcharge_WarningSound[client] = "";
		overcharge_WarningMessage[client] = "";
		overcharge_ExplosionSound[client] = "";
		overcharge_ExplosionParticle[client] = "";
		
		if (loopTimer[client] != INVALID_HANDLE)
		{
			KillTimer(loopTimer[client]);
		}
		loopTimer[client] = INVALID_HANDLE;
		
		if (HUDTimer[client] != INVALID_HANDLE)
		{
			KillTimer(HUDTimer[client]);
		}
		HUDTimer[client] = INVALID_HANDLE;
		
		DeleteParticle(client);
		
		SetEntProp(client, Prop_Data, "m_CollisionGroup", 5);
		
		for (int client2 = 1; client2 <= MaxClients; client2++)
		{
			StopSound(client2, SNDCHAN_AUTO, cloakNoise[client]);
		}
		
		if (FF2_HasAbility(FF2_GetBossIndex(client), PLUGIN_NAME, CLOAK_FIXMODEL))
		{
			setModel(client, mainModel[client]);
		}

		SDKUnhook(client, SDKHook_PreThink, cloakSpeed);
		SDKUnhook(client, SDKHook_PreThink, cloakStats);
		SDKUnhook(client, SDKHook_PreThink, blockBumpPrethink);
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage_Overcharge);
	}
}

stock bool IsValidClient(int client, bool replaycheck=true, bool onlyrealclients=true)
{
	if(client<=0 || client>MaxClients)
	{
		return false;
	}
	
	if(!IsClientInGame(client))
	{
		return false;
	}
	
	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}
	
	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
	}
	//if(onlyrealclients)                    Commented out for testing purposes
	//{
	//	if(IsFakeClient(client))
	//		return false;
	//}
	
	return true;
}

stock bool IsInvuln(int client) //Borrowed from Batfoxkid
{
	if(!IsValidClient(client))
	return true;
	
	return (TF2_IsPlayerInCondition(client, TFCond_Ubercharged) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedOnTakeDamage) ||
		TF2_IsPlayerInCondition(client, TFCond_Bonked) ||
		TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode) ||
		//TF2_IsPlayerInCondition(client, TFCond_MegaHeal) ||
		!GetEntProp(client, Prop_Data, "m_takedamage"));
}