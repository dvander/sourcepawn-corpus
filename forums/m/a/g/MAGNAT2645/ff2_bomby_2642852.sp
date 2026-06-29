#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#pragma newdecls required

public Plugin myinfo = {
	name	= "Freak Fortress 2: Bombinomicon",
	author	= "Deathreus, Fix by MAGNAT2645",
	version = "1.0",
};

#define BOMBMODEL		"models/props_lakeside_event/bomb_temp.mdl"
#define BOMBYMODEL		"models/props_halloween/bombonomicon.mdl"

int BossTeam = view_as<int>(TFTeam_Blue);
float g_fDuration = 5.0, g_fBombDamage = 45.0, g_fBombDuration = 3.0;
int MinBomb = 2, MaxBomb = 4;
Handle BTime = INVALID_HANDLE;

void OnPluginStart2()
{
	HookEvent("teamplay_round_active", event_round_start);
	HookEvent("teamplay_round_win", event_round_end);
}

public void OnMapStart()
{
	PrecacheModel(BOMBMODEL, true);
	PrecacheModel(BOMBYMODEL, true);
}

public void event_round_start(Handle event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.3, Timer_GetBossTeam);
	for (int i = 1; i <= MaxClients; i++)
	{
		int Boss = -1;
		if (!IsValidClient(i) || (Boss = FF2_GetBossIndex(i)) == -1)
			continue;
		g_fDuration = FF2_GetAbilityArgumentFloat(Boss, this_plugin_name, "rage_bombinomicon", 1, 5.0);
		g_fBombDamage = FF2_GetAbilityArgumentFloat(Boss, this_plugin_name, "rage_bombinomicon", 2, 45.0);
		MinBomb = FF2_GetAbilityArgument(Boss, this_plugin_name, "rage_bombinomicon", 3, 2);
		MaxBomb = FF2_GetAbilityArgument(Boss, this_plugin_name, "rage_bombinomicon", 4, 4);
		g_fBombDuration = FF2_GetAbilityArgumentFloat(Boss, this_plugin_name, "rage_bombinomicon", 5, 3.0);
		/*if(FF2_HasAbility(Boss, this_plugin_name, "bomb_fix"))
		{
			SetWeaponsAlpha(Boss, 0);
			SetEntityRenderMode(Boss, RENDER_TRANSCOLOR);
			SetEntityRenderColor(Boss, _, _, _, 0);
			new Model = CreateEntityByName("prop_dynamic");
			if (IsValidEdict(Model))
			{
				new Float:posc[3], Float:ang[3];
				GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", posc);
				posc[2] += 64;
				GetClientEyeAngles(Boss, ang);
				ang[0] = 0.0;
				ang[2] = 0.0;

				DispatchKeyValue(Model, "model", BOMBYMODEL);
				//DispatchKeyValue(Model, "DefaultAnim", "");
				DispatchKeyValueVector(Model, "angles", ang);

				DispatchSpawn(Model);
				TeleportEntity(Model, posc, NULL_VECTOR, NULL_VECTOR);

				new Handle:data;
				CreateDataTimer(0.1, UpdateModel, data, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				WritePackCell(data, Boss);
				WritePackCell(data, Model);
			}
		}*/
	}
}

public void event_round_end(Handle event, const char[] name, bool dontBroadcast)
{
	/*for (int i = 1; i <= MaxClients; i++)
	{
		int Boss = -1;
		if (!IsValidClient(i) || (Boss = FF2_GetBossIndex(i)) == -1)
			continue;
		SetWeaponsAlpha(Boss, 255);
		SetEntityRenderMode(Boss, RENDER_TRANSCOLOR);
		SetEntityRenderColor(Boss, _, _, _, 255);
	}*/
	if( BTime != INVALID_HANDLE ) {
		KillTimer( BTime );
		BTime = INVALID_HANDLE;
	}
}

public void FF2_OnAbility2(int client, const char[] plugin_name, const char[] ability_name, int status)
{
	if (!strcmp(ability_name, "rage_bombinomicon"))
	{
		int iUserId = FF2_GetBossUserId( client ), iBoss = GetClientOfUserId( iUserId );
		float flVel[ 3 ] = { 0.0, 0.0, 800.0 };
		TeleportEntity( iBoss, NULL_VECTOR, NULL_VECTOR, flVel );
		CreateTimer( 0.65, StartBombAttack, iUserId );
		CreateTimer( g_fDuration, ResetTaunt, iUserId );
		CreateTimer( g_fDuration, KillBombs );
		SetVariantInt(1);
		AcceptEntityInput( iBoss, "SetForcedTauntCam" );
	}
}

void SpawnClusters(int ent, int target, char model[64])
{
	if (IsValidEntity(ent))
	{
		float pos[3], ang[3];
		GetClientEyePosition(target, pos);

		for (int i = 0; i <= GetRandomInt(MinBomb, MaxBomb); i++)
		{
			ang[0] = GetRandomFloat(-500.0, 500.0);
			ang[1] = GetRandomFloat(-500.0, 500.0);
			ang[2] = GetRandomFloat(-7.5, 7.5);

			int ent2 = CreateEntityByName("tf_projectile_pipe");
			if(ent2 != -1)
			{
				SetEntProp(ent2, Prop_Send, "m_iTeamNum", BossTeam);
				SetEntPropFloat(ent2, Prop_Data, "m_flDamage", g_fBombDamage);
				SetEntPropFloat(ent2, Prop_Data, "m_flDetonateTime", g_fBombDuration);
				//SetEntProp(ent2, Prop_Data, "m_DmgRadius", GetEntProp(ent2, Prop_Data, "m_DmgRadius")*2);
				SetEntPropEnt(ent2, Prop_Data, "m_hOwnerEntity", ent);

				DispatchSpawn(ent2);
				SetEntityModel(ent2, model);
				TeleportEntity(ent2, pos, ang, ang);
			}
		}
	}
}

void TimedParticle(int client, const char path[32], float FTime)
{
	int TParticle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(TParticle)) {
		float pos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);

		TeleportEntity(TParticle, pos, NULL_VECTOR, NULL_VECTOR);

		DispatchKeyValue(TParticle, "effect_name", path);

		DispatchKeyValue(TParticle, "targetname", "particle");

		SetVariantString("!activator");
		AcceptEntityInput(TParticle, "SetParent", client, TParticle, 0);

		DispatchSpawn(TParticle);
		ActivateEntity(TParticle);
		AcceptEntityInput(TParticle, "Start");
		CreateTimer( FTime, KillTParticle, EntIndexToEntRef( TParticle ) );
	}
}

/*void SetWeaponsAlpha(int client, int alpha)
{
	char classname[64];
	int m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");
	for(int i = 0, weapon; i < 189; i += 4)
	{
		weapon = GetEntDataEnt2(client, m_hMyWeapons + i);
		if(weapon > -1 && IsValidEdict(weapon))
		{
			GetEdictClassname(weapon, classname, sizeof(classname));
			if(StrContains(classname, "tf_weapon", false) != -1 || StrContains(classname, "tf_wearable", false) != -1)
			{
				SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weapon, 255, 255, 255, alpha);
			}
		}
	}
}*/

stock bool IsValidClient(int client, bool bAlive = false, bool bTeam = false)
{
	if(client <= 0 || client > MaxClients || !IsClientInGame(client))
		return false;

	if(IsClientSourceTV(client) || IsClientReplay(client))
		return false;

	if(bAlive && !IsPlayerAlive(client))
		return false;

	if(bTeam && GetClientTeam(client) != BossTeam)
		return false;

	return true;
}

public Action StartBombAttack(Handle timer, any data)
{
	int iClient = GetClientOfUserId( data );
	if ( !iClient )
		return Plugin_Stop;

	BTime = CreateTimer( 0.32, CreateBomb, data, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
	TimedParticle( iClient, "merasmus_book_attack", g_fDuration );
	SetEntityMoveType( iClient, MOVETYPE_NONE );
	SetEntProp( iClient, Prop_Data, "m_takedamage", 0 );

	return Plugin_Stop;
}

public Action CreateBomb(Handle timer, any data)
{
	int iClient = GetClientOfUserId( data );
	if ( IsValidClient( iClient, true, true ) )
		SpawnClusters( iClient, iClient, BOMBMODEL );
}

public Action KillBombs(Handle timer)
{
	KillTimer( BTime );
	BTime = INVALID_HANDLE;
}

public Action ResetTaunt(Handle timer, any data)
{
	int iClient = GetClientOfUserId( data );
	if ( !iClient )
		return Plugin_Stop;

	SetVariantInt(0);
	AcceptEntityInput(iClient, "SetForcedTauntCam");
	SetEntityMoveType(iClient, MOVETYPE_WALK);
	SetEntProp(iClient, Prop_Data, "m_takedamage", 2);

	return Plugin_Stop;
}

public Action KillTParticle(Handle timer, any data)
{
	int iEnt = EntRefToEntIndex( data );
	if ( iEnt != INVALID_ENT_REFERENCE )
		AcceptEntityInput( iEnt, "Kill" );
}

/*public Action:UpdateModel(Handle:timer, any:pack)
{
	ResetPack(pack);
	new Boss = GetClientOfUserId(FF2_GetBossUserId(ReadPackCell(pack)));
	new Model = ReadPackCell(pack);
	new Float:posc[3], Float:ang[3];

	GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", posc);
	posc[2] += 64;
	GetClientEyeAngles(Boss, ang);
	ang[0] = 0.0;
	ang[2] = 0.0;

	TeleportEntity(Model, posc, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValueVector(Model, "angles", ang);
}*/

public Action Timer_GetBossTeam(Handle timer) {
	BossTeam = FF2_GetBossTeam();
	return Plugin_Continue;
}