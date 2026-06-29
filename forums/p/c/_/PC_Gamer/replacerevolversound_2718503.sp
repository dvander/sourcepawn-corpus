#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

public Plugin myinfo = 
{
	name = "[TF2] Revolver Sound Replacement",
	author = "torridgristle",
	description = "Replaces Revolver Shooting Sounds with Enforcer Sounds",
	version = "PLUGIN_VERSION 1.0",
	url = "www.sourcemod.com"	
}

public OnPluginStart()
{
	AddNormalSoundHook(SoundHook);
	PrecacheSound("weapons/tf_spy_enforcer_revolver_01.wav");
	PrecacheSound("weapons/tf_spy_enforcer_revolver_02.wav");
	PrecacheSound("weapons/tf_spy_enforcer_revolver_03.wav");
	PrecacheSound("weapons/tf_spy_enforcer_revolver_04.wav");
	PrecacheSound("weapons/tf_spy_enforcer_revolver_05.wav");
	PrecacheSound("weapons/tf_spy_enforcer_revolver_06.wav");
	PrecacheSound("weapons/tf_spy_enforcer_revolver_crit.wav");	
}

public Action:SoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (StrEqual(sound, "weapons/revolver_shoot.wav"))
	{
		int iRand = GetRandomInt(1,6);
		switch (iRand)
		{
		case 1:
			{
				Format(sound, sizeof(sound), "weapons/tf_spy_enforcer_revolver_01.wav");
				EmitSoundToClient(entity, "weapons/tf_spy_enforcer_revolver_01.wav", entity);
				return Plugin_Changed;
			}
		case 2:
			{
				Format(sound, sizeof(sound), "weapons/tf_spy_enforcer_revolver_02.wav");
				EmitSoundToClient(entity, "weapons/tf_spy_enforcer_revolver_02.wav", entity);
				return Plugin_Changed;
			}
		case 3:
			{
				Format(sound, sizeof(sound), "weapons/tf_spy_enforcer_revolver_03.wav");
				EmitSoundToClient(entity, "weapons/tf_spy_enforcer_revolver_03.wav", entity);
				return Plugin_Changed;
			}
		case 4:
			{
				Format(sound, sizeof(sound), "weapons/tf_spy_enforcer_revolver_04.wav");
				EmitSoundToClient(entity, "weapons/tf_spy_enforcer_revolver_04.wav", entity);
				return Plugin_Changed;
			}
		case 5:
			{
				Format(sound, sizeof(sound), "weapons/tf_spy_enforcer_revolver_05.wav");
				EmitSoundToClient(entity, "weapons/tf_spy_enforcer_revolver_05.wav", entity);
				return Plugin_Changed;
			}
		case 6:
			{
				Format(sound, sizeof(sound), "weapons/tf_spy_enforcer_revolver_06.wav");
				EmitSoundToClient(entity, "weapons/tf_spy_enforcer_revolver_06.wav", entity);
				return Plugin_Changed;
			}				
		}			
	}
	if (StrEqual(sound, "weapons/revolver_shoot_crit.wav"))
	{
		Format(sound, sizeof(sound), "weapons/tf_spy_enforcer_revolver_crit.wav");
		EmitSoundToClient(entity, "weapons/tf_spy_enforcer_revolver_crit.wav", entity);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}  