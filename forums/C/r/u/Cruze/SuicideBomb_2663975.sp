#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define GAME_TF		1
#define GAME_CSGO	2
#define GAME_CSS	3

bool admins[MAXPLAYERS + 1];
float maxDist = 250.0, baseDmg = 400.0;
int gamefolder = 0;
char flagStr[16];
bool ff;

public Plugin myinfo =
{
	name = "Suicide Bomb",
	author = "The Count. Edit: Cruze",
	description = "Allah, Who Snackbar",
	version = "1.0",
	url = "http://steamcommunity.com/profiles/76561197983205071/"
}

public void OnPluginStart()
{
	char game[32];
	GetGameFolderName(game, sizeof(game));
	gamefolder = 0;
	if(StrEqual(game, "tf", false))
	{
		gamefolder = GAME_TF;
	}
	else if(StrEqual(game, "csgo", false))
	{
		gamefolder = GAME_CSGO;
	}
	else if(StrEqual(game, "cstrike", false))
	{
		gamefolder = GAME_CSS;
	}
	ff = false;
	
	AddCommandListener(SuicideBomb, "kill");
	AddCommandListener(SuicideBomb, "explode");
	
	Format(flagStr, sizeof(flagStr), "a");
	HookConVarChange(CreateConVar("sm_bomb_max", "250", "Maximum explosion radius"), OnMaxDist);
	HookConVarChange(CreateConVar("sm_bomb_damage", "400", "Damage from explosion center"), OnBaseDmg);
	HookConVarChange(CreateConVar("sm_bomb_flag", "a", "Flag string for exploding"), OnFlagStr);
	HookConVarChange(CreateConVar("sm_bomb_ff", "0", "Enable/Disable Friendly Fire"), OnFF);
}

public void OnMapStart()
{
	if(gamefolder == GAME_CSGO)
	{
		CSGOPrecache("weapons/hegrenade/explode3.wav");
		CSGOPrecache("weapons/hegrenade/explode4.wav");
		CSGOPrecache("weapons/hegrenade/explode5.wav");
	}
	else if(gamefolder == GAME_CSS)
	{
		PrecacheSound("weapons/hegrenade/explode3.wav", true);
		PrecacheSound("weapons/hegrenade/explode4.wav", true);
		PrecacheSound("weapons/hegrenade/explode5.wav", true);
	}
	else
	{
		PrecacheSound("weapons/explode3.wav", true);
		PrecacheSound("weapons/explode4.wav", true);
		PrecacheSound("weapons/explode5.wav", true);
		PrecacheSound("weapons/mortar/mortar_explode1.wav", true);
		PrecacheSound("weapons/mortar/mortar_explode2.wav", true);
		PrecacheSound("weapons/mortar/mortar_explode3.wav", true);
	}
}

public void OnClientPostAdminCheck(int client)
{
	AdminFlag flg;
	BitToFlag(ReadFlagString(flagStr), flg);
	admins[client] = GetAdminFlag(GetUserAdmin(client), flg, Access_Effective);
}

public void OnClientDisconnect(int client)
{
	admins[client] = false;
}

public int OnMaxDist(Handle conv, const char[] oldv, const char[] newv)
{
	maxDist = StringToFloat(newv);
}
public int OnBaseDmg(Handle conv, const char[] oldv, const char[] newv)
{
	baseDmg = StringToFloat(newv);
}
public int OnFlagStr(Handle conv, const char[] oldv, const char[] newv)
{
	strcopy(flagStr, sizeof(flagStr), newv);
}
public int OnFF(Handle conv, const char[] oldv, const char[] newv)
{
	ff = (StringToInt(newv) == 0 ? false : true);
}

public Action SuicideBomb(int client, char[] command, int argc)
{
	if(admins[client] && IsPlayerAlive(client))
	{
		float pos[3], pos2[3];
		GetClientAbsOrigin(client, pos);
		int ent = (gamefolder == GAME_TF ? CreateEntityByName("tf_projectile_rocket") : 0);//Fake rocket to use as weapon
		int team = GetClientTeam(client);
		for(int i = 1; i <= MaxClients; i++)
		{
			if(i != client && IsClientInGame(i) && IsPlayerAlive(i))
			{
				if(team == GetClientTeam(i) && !ff)
				{
					continue;
				}
				GetClientAbsOrigin(i, pos2);
				float dist = GetVectorDistance(pos, pos2);
				if(dist <= maxDist){
					SDKHooks_TakeDamage(i, ent, client, (1 - dist/maxDist)*baseDmg, (DMG_ALWAYSGIB | DMG_CRIT | DMG_BLAST));
				}
			}
		}
		SDKHooks_TakeDamage(client, ent, client, GetClientHealth(client)*7.0, (DMG_ALWAYSGIB | DMG_CRIT | DMG_BLAST));//Explosion death, not regular suicide
		char particletype[64];
		if(gamefolder == GAME_CSGO)
		{
			Format(particletype, sizeof(particletype), "explosion_c4_500");
		}
		else if(gamefolder == GAME_CSS)
		{
			Format(particletype, sizeof(particletype), "bomb_explosion_huge"); //I don't have css to test this particle system :/
		}
		else
		{
			Format(particletype, sizeof(particletype), "ExplosionCore_buildings");
		}
		char temp[128];
		if(gamefolder == GAME_CSGO || gamefolder == GAME_CSS)
		{
			Format(temp, sizeof(temp), "weapons/hegrenade/explode%d.wav", GetRandomInt(3,5));
		}
		else
		{
			if(GetRandomInt(1, 2) == 1)
			{
				Format(temp, sizeof(temp), "weapons/explode%d.wav", GetRandomInt(3, 5));
			}
			else
			{
				Format(temp, sizeof(temp), "weapons/mortar/mortar_explode%d.wav", GetRandomInt(1, 3));
			}
		}
		EmitSoundToAll(temp, client, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
		if(gamefolder == GAME_TF)
		{
			AcceptEntityInput(ent, "Kill");
		}
	}
	return Plugin_Handled;
}

public void PlayEffect(int ent, char[] particleType)
{
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		float pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(6.0, Timer_RemoveEffect, particle);
	}
}

public Action Timer_RemoveEffect(Handle timer, any ent)
{
	AcceptEntityInput(ent, "Kill");
	return Plugin_Stop;
}

public void CSGOPrecache(const char[] path)
{
	PrecacheSound(path, true);
	char temp[128];
	Format(temp, sizeof(temp), "*%s", path);
	AddToStringTable(FindStringTable("soundprecache"), temp);
}