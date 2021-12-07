#include <sdktools>
#include <zombiereloaded>
#include <sdkhooks>
#include <emitsoundany>
#include <zrterminator>

#undef REQUIRE_PLUGIN
#tryinclude <entWatch>

#pragma newdecls required

#define PLUGIN_VERSION " 2.0[Redux] "
#define PREFIX "[\x02Terminator\x01]  "

#define sndBoom "maoling/nuke/boom.mp3"

enum cvars
{
	ConVar:InitRatio,
	ConVar:InitialHP,
	ConVar:MaxHP,
	ConVar:EnableCure,
	ConVar:KnockbackMultiple,
	ConVar:EnableDamage,
	ConVar:DamageRevolver,
	ConVar:DamageGoldKnife,
	ConVar:DamageMultiple,
	ConVar:DeathType,
	ConVar:AntiCamp,
	ConVar:ExplodeDamage,
	ConVar:ExplodeRadius,
	ConVar:BlockRespawn,
	ConVar:GlowEffect
}

Handle g_fwdOnTerminatorExec;
Handle g_fwdOnTerminatorDown;
Handle g_eCVARS[cvars];

bool g_bIsTerminator[MAXPLAYERS+1];
bool g_bHasTerminator;
bool g_bKillByTerminator[MAXPLAYERS+1];
int g_iInfectHP[MAXPLAYERS+1];
int g_iEdgeKnife[MAXPLAYERS+1];
int g_oVelocity;
float g_fAttackLoc[MAXPLAYERS+1][3];

public Plugin myinfo =
{
    name		= "Terminator",
    author		= "Kyle",
    description = "For last humans",
    version		= "Redux-1.0",
    url			= "http://steamcommunity.com/id/_xQy_/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ZE_IsClientTerminator", Native_IsClientTerminator);
	
	g_fwdOnTerminatorExec = CreateGlobalForward("ZE_OnTerminatorExec", ET_Ignore, Param_Cell);
	g_fwdOnTerminatorDown = CreateGlobalForward("ZE_OnTerminatorDown", ET_Ignore, Param_Cell);

	MarkNativeAsOptional("ZE_IsClientTakeEnt");

	g_oVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");

	return APLRes_Success;
}

public int Native_IsClientTerminator(Handle plugin, int numParams)
{
	return g_bIsTerminator[GetNativeCell(1)];
}

public void OnPluginStart()
{
	RegAdminCmd("sm_tset", AdminSetTerminator, ADMFLAG_BAN);

	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	
	g_eCVARS[InitRatio] = CreateConVar("ze_terminator_ratio", "8.0", "Remaining human to Amount of players ratio for initiate Terminator", _, true, 1.0, true, 64.0);
	g_eCVARS[InitialHP] = CreateConVar("ze_terminator_inithp", "20.0", "Initial HP of Terninator(Times of immute infect)", _, true, 0.0, true, 99999.0);
	g_eCVARS[MaxHP] = CreateConVar("ze_terminator_maxhp", "20.0", "Max HP of Terninator(Times of immute infect)", _, true, 1.0, true, 99999.0);
	g_eCVARS[EnableCure] = CreateConVar("ze_terminator_cure", "1.0", "Enable/Disable self-healing for Terminator", _, true, 0.0, true, 1.0);
	g_eCVARS[EnableDamage] = CreateConVar("ze_terminator_damage", "1.0", "Enable/Disable damage control for Terminator", _, true, 0.0, true, 1.0);
	g_eCVARS[DamageRevolver] = CreateConVar("ze_terminator_damage_r8", "10.0", "Damage mulitiple for R8 Revolver(0.0 = Disable, request ze_terminator_damage = 1)", _, true, 0.0, true, 99999.0);
	g_eCVARS[DamageGoldKnife] = CreateConVar("ze_terminator_damage_gg", "50.0", "Damage mulitiple for Gold Knife(0.0 = Disable, request ze_terminator_damage = 1)", _, true, 0.0, true, 99999.0);
	g_eCVARS[DamageMultiple] = CreateConVar("ze_terminator_damage_mp", "3.0", "Damage mulitiple for Other Weapons(0.0 = Disable, request ze_terminator_damage = 1)", _, true, 0.0, true, 99999.0);
	g_eCVARS[KnockbackMultiple] = CreateConVar("ze_terminator_knockback", "3.0", "Knockback mulitiple for Gold knife for Terminator(0.0 = Disable, request ze_terminator_damage = 1)", _, true, 0.0, true, 99999.0);
	g_eCVARS[DeathType] = CreateConVar("ze_terminator_deathtype", "2.0", "DeathType of Terminator: 0 = Infect, 1 = Suicide, 2 = Explode", _, true, 0.0, true, 2.0);
	g_eCVARS[AntiCamp] = CreateConVar("ze_terminator_anticamp", "1.0", "Enable/Disable Anti-Camp for Terminator (request ze_terminator_damage = 1)", _, true, 0.0, true, 1.0);
	g_eCVARS[ExplodeDamage] = CreateConVar("ze_terminator_explode_damage", "5000.0", "Damage of Terminator death explode effect (request ze_terminator_deathtype = 2)", _, true, 0.0, true, 99999.0);
	g_eCVARS[ExplodeRadius] = CreateConVar("ze_terminator_explode_radius", "300.0", "Initial HP of Terninator(Times of immute infect)", _, true, 0.0, true, 99999.0);
	g_eCVARS[BlockRespawn] = CreateConVar("ze_terminator_blockrespawn", "1.0", "Enable/Disable respawn for zombie slain by Terminator", _, true, 0.0, true, 1.0);
	g_eCVARS[GlowEffect] = CreateConVar("ze_terminator_gloweffect", "1.0", "Enable/Disable Highlight/Wallhack Terminator to Zombie", _, true, 0.0, true, 1.0);

	AutoExecConfig(true);
}

public void OnPluginEnd()
{
	for(int i = 1; i <= MaxClients; ++i)
		if(IsClientInGame(i))
			OnClientDisconnect(i);
}

public void OnMapStart()
{
	PrecacheSoundAny(sndBoom);
	AddFileToDownloadsTable("sound/maoling/nuke/boom.mp3");
}

public void OnClientPostAdminCheck(int client)
{
	g_bKillByTerminator[client] = false;
	g_bIsTerminator[client] = false;
	g_iInfectHP[client] = 0;
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!ZR_IsClientHuman(client))
		return;

	g_bKillByTerminator[client] = false;
	g_iInfectHP[client] = 0;
	g_iEdgeKnife[client] = 0;
	g_fAttackLoc[client] = view_as<float>({0.0, 0.0, 0.0});
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_bHasTerminator)
		return;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(client == attacker || !client || !attacker || !g_bIsTerminator[attacker])
		return;

	g_bKillByTerminator[client] = true;
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_bHasTerminator)
		return;

	g_bHasTerminator = false;

	for(int client=1; client<=MaxClients; ++client)
	{
		if(!IsClientInGame(client))
			continue;
	
		g_bKillByTerminator[client] = false;

		if(!g_bIsTerminator[client])
			continue;
	
		SetEntPropFloat(client, Prop_Send, "m_flDetectedByEnemySensorTime", 0.0);
		g_bIsTerminator[client] = false;
		g_iInfectHP[client] = 0;
		
		if(!IsPlayerAlive(client))
			continue;

		int weapon_index=-1;
		char weapon_string[20];
		if(((weapon_index = GetPlayerWeaponSlot(client, 1)) != -1) && GetEdictClassname(weapon_index, weapon_string, 20))
		{
			RemovePlayerItem(client, weapon_index);
			AcceptEntityInput(weapon_index, "Kill");
		}
		if(((weapon_index = GetPlayerWeaponSlot(client, 2)) != -1) && GetEdictClassname(weapon_index, weapon_string, 20))
		{
			RemovePlayerItem(client, weapon_index);
			AcceptEntityInput(weapon_index, "Kill");
		}
		GivePlayerItem(client, "weapon_knife");
	}
}

public Action Hook_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(!g_bHasTerminator)
		return Plugin_Continue;

	if(damage <= 0.0 || !IsValidClient(attacker) || !IsPlayerAlive(attacker))
		return Plugin_Continue;
	
	if(!IsValidEdict(weapon))
		return Plugin_Continue;
	
	if(g_iInfectHP[victim] <= 0)
		return Plugin_Continue;
	
	if(IsPlayerAlive(attacker) && ZR_IsClientZombie(attacker) && g_bIsTerminator[victim])
	{
		g_iInfectHP[victim]--;

		PrintHintText(victim, "<font size='40' color='#00FF00'>Remaining HP: <strong>%d</strong>点HP</font>", g_iInfectHP[victim]);
		PrintToChat(victim, "%s  Received 1 point damage from\x07%N\x01, Remaining HP:\x07 %d", PREFIX, attacker, g_iInfectHP[victim]);

		if(g_iInfectHP[victim] <= 0)
			RequestFrame(KillTerminator, victim);

		return Plugin_Handled;
	}

	if(!g_eCVARS[EnableDamage].BoolValue)
		return Plugin_Continue;

	if(g_bIsTerminator[attacker])
	{
		char clsname[32];
		GetEdictClassname(weapon, clsname, 32);	
		if(StrContains(clsname, "deagle", false ) != -1 && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 64)
		{
			float mtp = g_eCVARS[DamageRevolver].FloatValue;
			if(mtp >= 0.0)
				damage *= mtp;
			
			if(g_eCVARS[KnockbackMultiple].FloatValue > 0.0)
				DoTerminatorKnockBack(attacker, victim, damage);
		}
		else if(StrContains(clsname, "knife", false ) != -1)
		{
			float mtp = g_eCVARS[DamageGoldKnife].FloatValue;
			if(mtp >= 0.0)
				damage *= mtp;

			if(g_eCVARS[KnockbackMultiple].FloatValue > 0.0)
				DoTerminatorKnockBack(attacker, victim, damage);

			if(g_eCVARS[AntiCamp].BoolValue)
			{
				//Anti-Camp
				float loc[3];
				GetClientAbsOrigin(attacker, loc);
				
				float Distance = GetVectorDistance(g_fAttackLoc[attacker], loc);
				
				if(Distance < 35.0)
					g_iEdgeKnife[attacker]++;
				
				if(g_iEdgeKnife[attacker] > 5)
				{
					KillTerminator(attacker);
					PrintToChatAll("%s  \x04%N\x01 exploded.", PREFIX, attacker);
				}

				g_fAttackLoc[attacker] = loc;
			}
		}
		else
		{
			float mtp = g_eCVARS[DamageMultiple].FloatValue;
			if(mtp >= 0.0)
				damage *= mtp;
		}
		
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public Action ZR_OnClientRespawn(int &client, ZR_RespawnCondition &condition)
{
	if(!g_bHasTerminator)
		return Plugin_Continue;
	
	if(g_bIsTerminator[client])
		return Plugin_Handled;
	
	if(!g_eCVARS[BlockRespawn].BoolValue)
		return Plugin_Continue;

	if(g_bKillByTerminator[client])
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action ZR_OnClientInfect(int &client, int &attacker, bool &motherInfect, bool &respawnOverride, bool &respawn)
{
	if(motherInfect)
		return Plugin_Continue;

	if(g_bHasTerminator && g_bIsTerminator[client])
	{
		if(g_iInfectHP[client])
			return Plugin_Handled;
		
		if(g_eCVARS[DeathType].BoolValue)
			return Plugin_Continue;
	}

	return Plugin_Continue;
}

public int ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn)
{
	if(g_bHasTerminator)
		return;

	int Humans, player;
	for(int i=1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		if(!IsPlayerAlive(i))
			continue;
		
		player++;
		
		if(!ZR_IsClientHuman(i))
			continue;

		Humans++;
	}
	
	if(!Humans)
		return;
		
	if((player/Humans) >= g_eCVARS[InitRatio].IntValue)
		SetupTerminator();
}

void SetupTerminator()
{
	for(int client=1; client<=MaxClients; ++client)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client) && ZR_IsClientHuman(client))
		{
			g_bIsTerminator[client] = true;
			ExecTerminator(client);
		}
	}
	PrintCenterTextAll("<font color='#0066CC' size='30'>Terminator initiated!");
	g_bHasTerminator = true;
	CreateTimer(10.0, Timer_Cure, _, TIMER_REPEAT);
}

void ExecTerminator(int client)
{
	int weapon_index=-1;
	if(!IsClientTakeEnt(client))
	{	
		if(((weapon_index = GetPlayerWeaponSlot(client, 1)) != -1))
		{	
			RemovePlayerItem(client, weapon_index);
			AcceptEntityInput(weapon_index, "Kill");
		}
		
		if(((weapon_index = GetPlayerWeaponSlot(client, 2)) != -1))
		{
			RemovePlayerItem(client, weapon_index);
			AcceptEntityInput(weapon_index, "Kill");
			
		}

		GivePlayerItem(client, "weapon_revolver");
		GivePlayerItem(client, "weapon_knifegg");
	}

	PrintToChatAll("%s \x07%N \x0Chad became Terminator!", PREFIX, client);

	g_iInfectHP[client] = g_eCVARS[InitialHP].IntValue;
	SetEntityHealth(client, GetEntProp(client, Prop_Data, "m_iMaxHealth", 4, 0));
	
	if(g_eCVARS[GlowEffect].BoolValue)
		SetEntPropFloat(client, Prop_Send, "m_flDetectedByEnemySensorTime", 999999.99);

	OnTerminatorExec(client);
}

public Action AdminSetTerminator(int client, int args)
{
	g_bHasTerminator = true;
	g_bIsTerminator[client] = true;
	ExecTerminator(client);
	CreateTimer(10.0, Timer_Cure, _, TIMER_REPEAT);
}

public Action Timer_Cure(Handle timer, any data)
{
	if(!g_bHasTerminator)
		return Plugin_Stop;
	
	if(!g_eCVARS[EnableCure].BoolValue)
		return Plugin_Stop;

	CureTerminator();

	return Plugin_Continue;
}

void CureTerminator()
{
	for(int client = 1; client <= MaxClients; ++client)
	{
		if(!IsClientInGame(client))
			continue;
		
		if(!IsPlayerAlive(client))
			continue;
		
		if(!ZR_IsClientHuman(client))
			continue;
		
		if(!g_bIsTerminator[client])
			continue;

		SetEntityHealth(client, GetEntProp(client, Prop_Data, "m_iMaxHealth", 4, 0));

		if(g_iInfectHP[client] >= g_eCVARS[MaxHP].IntValue)
			continue;

		g_iInfectHP[client]++;

		PrintHintText(client, "<font size='40' color='#00FF00'>Resume<strong> 1 </strong>HP</font>");
		PrintToChat(client, "%s  Resume\x04 1 \x01point HP, Remaining HP:\x07 %d", PREFIX, g_iInfectHP[client]);
	}
}

void OnTerminatorExec(int client)
{
	Call_StartForward(g_fwdOnTerminatorExec);
	Call_PushCell(client);
	Call_Finish();
}

void OnTerminatorDown(int client)
{
	Call_StartForward(g_fwdOnTerminatorDown);
	Call_PushCell(client);
	Call_Finish();
}

void DoTerminatorKnockBack(int attacker, int victim, float damage)
{
	float clientloc[3];
	float attackerloc[3];
	float knockback = g_eCVARS[KnockbackMultiple].FloatValue;
	
	GetClientAbsOrigin(victim, clientloc);

	GetClientEyePosition(attacker, attackerloc);

	float attackerang[3];
	GetClientEyeAngles(attacker, attackerang);
        
	TR_TraceRayFilter(attackerloc, attackerang, MASK_ALL, RayType_Infinite, KnockbackTRFilter);
	TR_GetEndPosition(clientloc);
	
	knockback *= damage;
	
	KnockbackSetVelocity(victim, attackerloc, clientloc, knockback);
}

void KnockbackSetVelocity(int client, const float startpoint[3], const float endpoint[3], float magnitude)
{
	float vector[3];
	MakeVectorFromPoints(startpoint, endpoint, vector);
    
	NormalizeVector(vector, vector);
    
	ScaleVector(vector, magnitude);
   
	ToolsClientVelocity(client, vector);
}

public bool KnockbackTRFilter(int entity, int contentsMask)
{
	if(entity > 0 && entity < MAXPLAYERS)
		return false;
	return true;
}

stock void ToolsClientVelocity(int client, float vecVelocity[3], bool apply = true, bool stack = true)
{
	if(!apply)
	{
		for(int x = 0; x < 3; x++)
		{
			vecVelocity[x] = GetEntDataFloat(client, g_oVelocity + (x*4));
		}

		return;
	}
    
	if(stack)
	{
		float vecClientVelocity[3];

		for(int x = 0; x < 3; x++)
		{
			vecClientVelocity[x] = GetEntDataFloat(client, g_oVelocity + (x*4));
		}

		AddVectors(vecClientVelocity, vecVelocity, vecVelocity);
	}

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}

void KillTerminator(int victim)
{
	if(!IsClientInGame(victim))
		return;

	if(!IsPlayerAlive(victim))
		return;

	switch(g_eCVARS[DeathType].IntValue)
	{
		case 0: ZR_InfectClient(victim, -1, false, false, false);
		case 1: ForcePlayerSuicide(victim);
		case 2:
		{
			int iEnt = CreateEntityByName("env_explosion");
			float fPos[3];
			GetClientAbsOrigin(victim, fPos);
			
			SetEntProp(iEnt, Prop_Data, "m_spawnflags", 6146);
			SetEntProp(iEnt, Prop_Data, "m_iMagnitude", g_eCVARS[ExplodeDamage].IntValue);
			SetEntProp(iEnt, Prop_Data, "m_iRadiusOverride", g_eCVARS[ExplodeRadius].IntValue);

			DispatchSpawn(iEnt);
			ActivateEntity(iEnt);
			
			TeleportEntity(iEnt, fPos, NULL_VECTOR, NULL_VECTOR);
			SetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity", victim);

			AcceptEntityInput(iEnt, "Explode");
			AcceptEntityInput(iEnt, "Kill");
		}
	}
	
	SetEntPropFloat(victim, Prop_Send, "m_flDetectedByEnemySensorTime", 0.0);
	
	EmitSoundToAllAny(sndBoom, victim);
	OnTerminatorDown(victim);
}

stock bool IsClientTakeEnt(int client)
{
	if(GetFeatureStatus(FeatureType_Native, "ZE_IsClientTakeEnt") == FeatureStatus_Available)
		return ZE_IsClientTakeEnt(client);
	else
		return false;	
}

stock bool IsValidClient(int client)
{
	if(!(1 <= client <= MaxClients))
		return false;
	
	if(!IsClientInGame(client))
		return false;
	
	if(IsFakeClient(client))
		return false;
	
	return true;
}