#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required;

bool g_bHammered[MAXPLAYERS+1];

char g_strHitSounds[][] =
{
	{"vo/halloween_merasmus/sf14_merasmus_necromasher_01.mp3"},
	{"vo/halloween_merasmus/sf14_merasmus_necromasher_03.mp3"},
	{"vo/halloween_merasmus/sf14_merasmus_necromasher_04.mp3"},
	{"vo/halloween_merasmus/sf14_merasmus_necromasher_05.mp3"},
	{"vo/halloween_merasmus/sf14_merasmus_necromasher_07.mp3"},
	{"vo/halloween_merasmus/sf14_merasmus_necromasher_08.mp3"},
	{"vo/halloween_merasmus/sf14_merasmus_necromasher_09.mp3"},
	{"vo/halloween_merasmus/sf14_merasmus_necromasher_11.mp3"},
	{"vo/halloween_merasmus/sf14_merasmus_necromasher_12.mp3"},
	{"vo/halloween_merasmus/sf14_merasmus_necromasher_13.mp3"}
}

char g_strMissSounds[][] =
{
	{"vo/halloween_merasmus/sf14_merasmus_necromasher_miss_02.mp3"},
	{"vo/halloween_merasmus/sf14_merasmus_necromasher_miss_03.mp3"},
	{"vo/halloween_merasmus/sf14_merasmus_necromasher_miss_04.mp3"},
	{"vo/halloween_merasmus/sf14_merasmus_necromasher_miss_06.mp3"},
	{"vo/halloween_merasmus/sf14_merasmus_necromasher_miss_07.mp3"},
	{"vo/halloween_merasmus/sf14_merasmus_necromasher_miss_08.mp3"},
	{"vo/halloween_merasmus/sf14_merasmus_necromasher_miss_09.mp3"},
	{"vo/halloween_merasmus/sf14_merasmus_necromasher_miss_10.mp3"},
	{"vo/halloween_merasmus/sf14_merasmus_necromasher_miss_11.mp3"},
	{"vo/halloween_merasmus/sf14_merasmus_necromasher_miss_12.mp3"},
	{"vo/halloween_merasmus/sf14_merasmus_necromasher_miss_13.mp3"},
	{"vo/halloween_merasmus/sf14_merasmus_necromasher_miss_14.mp3"}
}

#define PLUGIN_VERSION "1.1"

public Plugin myinfo = 
{
	name = "[TF2] Necromasher",
	author = "Pelipoika",
	description = "Think Fast!",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	RegAdminCmd("sm_smash", Cmd_msg, ADMFLAG_ROOT);

	CreateConVar("sm_necromash_version", PLUGIN_VERSION, "Necromasher version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT);
}

public void OnClientAuthorized(int client) 
{
	g_bHammered[client] = false;
}

public void OnMapStart()
{
	PrecacheModel("models/props_halloween/hammer_gears_mechanism.mdl");
	PrecacheModel("models/props_halloween/hammer_mechanism.mdl");
	PrecacheModel("models/props_halloween/bell_button.mdl");
	
	PrecacheSound("misc/halloween/strongman_fast_impact_01.wav");
	PrecacheSound("ambient/explosions/explode_1.wav");
	PrecacheSound("misc/halloween/strongman_fast_whoosh_01.wav");
	PrecacheSound("misc/halloween/strongman_fast_swing_01.wav");
	PrecacheSound("doors/vent_open2.wav");

	for(int i = 0; i < sizeof(g_strHitSounds); i++)
		PrecacheSound(g_strHitSounds[i]);
		
	for(int i = 0; i < sizeof(g_strMissSounds); i++)
		PrecacheSound(g_strMissSounds[i]);
	
	HookEvent("player_death", player_death, EventHookMode_Pre);
}

public Action Cmd_msg(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "Usage: sm_mash <player /@all /@me etc>");
		return Plugin_Handled;
	}
	
	char arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int	target_count;
	bool tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg1,
			client, 
			target_list, 
			MAXPLAYERS, 
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		int player = target_list[i];
		
		if(IsValidClient(player) && IsPlayerAlive(player) && GetEntPropEnt(player, Prop_Send, "m_hGroundEntity") != -1)
		{
			float flPos[3], flPpos[3], flAngles[3];
			GetClientAbsOrigin(player, flPos);
			GetClientAbsOrigin(player, flPpos);
			GetClientEyeAngles(player, flAngles);
			flAngles[0] = 0.0;
			
			float vForward[3];
			GetAngleVectors(flAngles, vForward, NULL_VECTOR, NULL_VECTOR);
			flPos[0] -= (vForward[0] * 750);
			flPos[1] -= (vForward[1] * 750);
			flPos[2] -= (vForward[2] * 750);
			
			flPos[2] += 350.0;
		
			int gears = CreateEntityByName("prop_dynamic");
			if(IsValidEntity(gears))
			{
				DispatchKeyValueVector(gears, "origin", flPos);
				DispatchKeyValueVector(gears, "angles", flAngles);
				DispatchKeyValue(gears, "model", "models/props_halloween/hammer_gears_mechanism.mdl");
				DispatchSpawn(gears);
			}
			
			int hammer = CreateEntityByName("prop_dynamic");
			if(IsValidEntity(hammer))
			{
				DispatchKeyValueVector(hammer, "origin", flPos);
				DispatchKeyValueVector(hammer, "angles", flAngles);
				DispatchKeyValue(hammer, "model", "models/props_halloween/hammer_mechanism.mdl");
				DispatchSpawn(hammer);
			}
			
			int button = CreateEntityByName("prop_dynamic");
			if(IsValidEntity(button))
			{
				flPos[0] += (vForward[0] * 600);
				flPos[1] += (vForward[1] * 600);
				flPos[2] += (vForward[2] * 600);
				
				flPos[2] -= 100.0;
				flAngles[1] += 180.0;
				
				DispatchKeyValueVector(button, "origin", flPos);
				DispatchKeyValueVector(button, "angles", flAngles);
				DispatchKeyValue(button, "model", "models/props_halloween/bell_button.mdl");
				DispatchSpawn(button);
				
				Handle pack;
				CreateDataTimer(1.3, Timer_Hit, pack);
				WritePackFloat(pack, flPpos[0]); //Position of effects
				WritePackFloat(pack, flPpos[1]); //Position of effects
				WritePackFloat(pack, flPpos[2]); //Position of effects
				
				Handle pack2;
				CreateDataTimer(1.0, Timer_Whoosh, pack2);
				WritePackFloat(pack2, flPpos[0]); //Position of effects
				WritePackFloat(pack2, flPpos[1]); //Position of effects
				WritePackFloat(pack2, flPpos[2]); //Position of effects
				
				EmitSoundToAll("misc/halloween/strongman_fast_swing_01.wav", _, _, _, _, _, _, _, flPpos);
			}
			
			SetVariantString("OnUser1 !self:SetAnimation:smash:0:1");
			AcceptEntityInput(gears, "AddOutput");
			AcceptEntityInput(gears, "FireUser1");
			
			SetVariantString("OnUser1 !self:SetAnimation:smash:0:1");
			AcceptEntityInput(hammer, "AddOutput");
			AcceptEntityInput(hammer, "FireUser1");
			
			SetVariantString("OnUser1 !self:SetAnimation:hit:1.3:1");
			AcceptEntityInput(button, "AddOutput");
			AcceptEntityInput(button, "FireUser1");
			
			SetVariantString("OnUser2 !self:Kill::5.0:1");
			AcceptEntityInput(gears, "AddOutput");
			AcceptEntityInput(gears, "FireUser2");
			
			SetVariantString("OnUser2 !self:Kill::5.0:1");
			AcceptEntityInput(hammer, "AddOutput");
			AcceptEntityInput(hammer, "FireUser2");
			
			SetVariantString("OnUser2 !self:Kill::5.0:1");
			AcceptEntityInput(button, "AddOutput");
			AcceptEntityInput(button, "FireUser2");
		}
	}
	
	return Plugin_Handled;
}

public Action Timer_Hit(Handle timer, any pack)
{ 
	ResetPack(pack);
	
	float pos[3];
	pos[0] = ReadPackFloat(pack);
	pos[1] = ReadPackFloat(pack);
	pos[2] = ReadPackFloat(pack);
	
	int shaker = CreateEntityByName("env_shake");
	if(shaker != -1)
	{
		DispatchKeyValue(shaker, "amplitude", "10");
		DispatchKeyValue(shaker, "radius", "1500");
		DispatchKeyValue(shaker, "duration", "1");
		DispatchKeyValue(shaker, "frequency", "2.5");
		DispatchKeyValue(shaker, "spawnflags", "4");
		DispatchKeyValueVector(shaker, "origin", pos);
		
		DispatchSpawn(shaker);
		AcceptEntityInput(shaker, "StartShake");
		
		SetVariantString("OnUser1 !self:Kill::1.0:1");
		AcceptEntityInput(shaker, "AddOutput");
		AcceptEntityInput(shaker, "FireUser1");
	}
	
	EmitSoundToAll("ambient/explosions/explode_1.wav", _, _, _, _, _, _, _, pos);
	EmitSoundToAll("misc/halloween/strongman_fast_impact_01.wav", _, _, _, _, _, _, _, pos);
	
	bool bHit = false;
	float pos2[3], Vec[3], AngBuff[3];
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, pos2);

			if(GetVectorDistance(pos, pos2) <= 500.0)
			{
				MakeVectorFromPoints(pos, pos2, Vec);
				GetVectorAngles(Vec, AngBuff);
				AngBuff[0] -= 30.0; 
				GetAngleVectors(AngBuff, Vec, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(Vec, Vec);
				ScaleVector(Vec, 500.0);    
				Vec[2] += 250.0;
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, Vec);
			}
			
			if(GetVectorDistance(pos, pos2) <= 60.0)
			{
				g_bHammered[i] = true;
				SDKHooks_TakeDamage(i, i, i, 999999.0, DMG_CLUB|DMG_ALWAYSGIB|DMG_BLAST);
				bHit = true;
			}
		}
	}
	
	if(bHit)
	{
		int strSound = GetRandomInt(0, sizeof(g_strHitSounds) - 1);
		EmitSoundToAll(g_strHitSounds[strSound]);
	}
	else
	{
		int strSound = GetRandomInt(0, sizeof(g_strMissSounds) - 1);
		EmitSoundToAll(g_strMissSounds[strSound]);
	}
	
	//hammer_bell_ring_shockwave
	
	pos[2] += 10.0;
	CreateParticle("hammer_impact_button", pos);
	CreateParticle("hammer_bones_kickup", pos);
}

public Action Timer_Whoosh(Handle timer, any pack)
{ 
	ResetPack(pack);

	float pos[3];
	pos[0] = ReadPackFloat(pack);
	pos[1] = ReadPackFloat(pack);
	pos[2] = ReadPackFloat(pack);
	
	EmitSoundToAll("misc/halloween/strongman_fast_whoosh_01.wav", _, _, _, _, _, _, _, pos);
}

public Action player_death(Handle hEvent, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (g_bHammered[client])
	{
		SetEventString(hEvent, "weapon", "necro_smasher");
		SetEventString(hEvent, "weapon_logclassname", "necro_smasher");
		g_bHammered[client] = false;
	}
	
	return Plugin_Continue;
}

stock void CreateParticle(char[] particle, float pos[3])
{
	int tblidx = FindStringTable("ParticleEffectNames");
	char tmp[256];
	int count = GetStringTableNumStrings(tblidx);
	int stridx = INVALID_STRING_INDEX;
	for(int i = 0; i < count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if(StrEqual(tmp, particle, false))
        {
            stridx = i;
            break;
        }
    }
	for(int i = 1; i <= GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		TE_Start("TFParticleEffect");
		TE_WriteFloat("m_vecOrigin[0]", pos[0]);
		TE_WriteFloat("m_vecOrigin[1]", pos[1]);
		TE_WriteFloat("m_vecOrigin[2]", pos[2]);
		TE_WriteNum("m_iParticleSystemIndex", stridx);
		TE_WriteNum("entindex", -1);
		TE_WriteNum("m_iAttachType", 2);
		TE_SendToClient(i, 0.0);
	}
}

stock bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}