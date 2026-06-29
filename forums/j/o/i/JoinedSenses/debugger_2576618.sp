#pragma newdecls required
#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

bool g_bTempEntDisable;
bool g_bTempEntInfo;
bool g_bEntInfo;
bool g_bTransmitInfo;
bool g_bParticleInfo;
bool g_bSoundInfo;

static int g_iUtils_EffectDispatchTable;

public Plugin myinfo = 
{
	name = "Sound and Entity Debugger",
	author = "JoinedSenses",
	description = "Prints sound and entity info to chat",
	version = "1.0.0"
}
char g_saEntList[][] = {
	"weapon",
	"sprite",
	"projectile"
};
char g_bExcludedParticles[][] = {
	"waterfall"
};
public void OnPluginStart(){
	RegAdminCmd("sm_teinf", cmdTempEntInfo, ADMFLAG_ROOT);
	RegAdminCmd("sm_einf", cmdEntInfo, ADMFLAG_ROOT);
	RegAdminCmd("sm_trinf", cmdTransmitInfo, ADMFLAG_ROOT);
	RegAdminCmd("sm_pinf", cmdParticleInfo, ADMFLAG_ROOT);
	RegAdminCmd("sm_sinf", cmdSoundInfo, ADMFLAG_ROOT);
	RegAdminCmd("sm_tedisable", cmdTempEntDisable, ADMFLAG_ROOT);

	AddTempEntHook("Armor Ricochet", TEHookTest);
	AddTempEntHook("BeamEntPoint", TEHookTest);
	AddTempEntHook("BeamEnts", TEHookTest);
	AddTempEntHook("BeamFollow", TEHookTest);
	AddTempEntHook("BeamLaser", TEHookTest);
	AddTempEntHook("BeamPoints", TEHookTest);
	AddTempEntHook("BeamRing", TEHookTest);
	AddTempEntHook("BeamRingPoint", TEHookTest);
	AddTempEntHook("BeamSpline", TEHookTest);
	AddTempEntHook("Blood Sprite", TEHookTest);
	AddTempEntHook("Blood Stream", TEHookTest);
	AddTempEntHook("breakmodel", TEHookTest);
	AddTempEntHook("BSP Decal", TEHookTest);
	AddTempEntHook("Bubbles", TEHookTest);
	AddTempEntHook("Bubble Trail", TEHookTest);
	AddTempEntHook("Client Projectile", TEHookTest);
	AddTempEntHook("Dust", TEHookTest);
	AddTempEntHook("Dynamic Light", TEHookTest);
	AddTempEntHook("EffectDispatch", TEHookTest);
	AddTempEntHook("Energy Splash", TEHookTest);
	AddTempEntHook("Entity Decal", TEHookTest);
	AddTempEntHook("Explosion", TEHookTest);
	AddTempEntHook("Fire Bullets", TEHookTest);
	AddTempEntHook("Fizz", TEHookTest);
	AddTempEntHook("Footprint Decal", TEHookTest);
	AddTempEntHook("GaussExplosion", TEHookTest);
	AddTempEntHook("GlowSprite", TEHookTest);
	AddTempEntHook("Impact", TEHookTest);
	AddTempEntHook("KillPlayerAttachments", TEHookTest);
	AddTempEntHook("Large Funnel", TEHookTest);
	AddTempEntHook("Metal Sparks", TEHookTest);
	AddTempEntHook("physicsprop", TEHookTest);
	AddTempEntHook("PlayerAnimEvent", TEHookTest);
	AddTempEntHook("Player Decal", TEHookTest);
	AddTempEntHook("Projected Decal", TEHookTest);
	AddTempEntHook("Show Line", TEHookTest);
	AddTempEntHook("Smoke", TEHookTest);
	AddTempEntHook("Sparks", TEHookTest);
	AddTempEntHook("Sprite", TEHookTest);
	AddTempEntHook("Surface Shatter", TEHookTest);
	AddTempEntHook("TFBlood", TEHookTest);
	AddTempEntHook("TFExplosion", TEHookTest);
	AddTempEntHook("TFParticleEffect", TEHookTest);
	AddTempEntHook("World Decal", TEHookTest);
	
	AddAmbientSoundHook(view_as<AmbientSHook>(AmbientSoundHook));
	AddNormalSoundHook(view_as<NormalSHook>(NormalSoundHook));
}
public void OnMapStart(){
	g_iUtils_EffectDispatchTable = FindStringTable("EffectDispatch");
}
public Action cmdTempEntDisable(int client, int args){
	g_bTempEntDisable = !g_bTempEntDisable;
	if (g_bTempEntDisable){
		PrintToChatAll("Temp entities disabled");
	}
	else{
		PrintToChatAll("Temp entities enabled");
	}
	return Plugin_Handled;
}
public Action cmdTempEntInfo(int client, int args){
	g_bTempEntInfo = !g_bTempEntInfo;
	if (g_bTempEntInfo){
		PrintToChatAll("Temp entity info enabled");
	}
	else{
		PrintToChatAll("Temp entity info disabled");
	}
	return Plugin_Handled;
}
public Action cmdEntInfo(int client, int args){
	g_bEntInfo = !g_bEntInfo;
	if (g_bEntInfo){
		PrintToChatAll("Entity info enabled");
	}
	else{
		PrintToChatAll("Entity info disabled");
	}
	return Plugin_Handled;
}
public Action cmdTransmitInfo(int client, int args){
	g_bTransmitInfo = !g_bTransmitInfo;
	if (g_bTransmitInfo){
		PrintToChatAll("Transmit info enabled");
	}
	else{
		PrintToChatAll("Transmit info disabled");
	}
	return Plugin_Handled;
}
public Action cmdParticleInfo(int client, int args){
	g_bParticleInfo = !g_bParticleInfo;
	if (g_bParticleInfo){
		PrintToChatAll("Particle info enabled");
	}
	else{
		PrintToChatAll("Particle info disabled");
	}
	return Plugin_Handled;
}
public Action cmdSoundInfo(int client, int args){
	g_bSoundInfo = !g_bSoundInfo;
	if (g_bSoundInfo){
		PrintToChatAll("Sound name enabled");
	}
	else{
		PrintToChatAll("Sound name disabled");
	}
	return Plugin_Handled;
}
public Action AmbientSoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags){
	if (g_bSoundInfo){
		PrintToChatAll("Ambient sound is %s from %i", sample, entity);
	}
}
public Action NormalSoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags){
	if (g_bSoundInfo){
		PrintToChatAll("Normal sound is %s", sample);
	}
}
public Action TEHookTest(const char[] te_name, const int[] Players, int numClients, float delay){
	if (g_bTempEntInfo){
		PrintToChatAll("Temp Ent name is %s", te_name);
		if (StrContains(te_name, "EffectDispatch") != -1){
			int effectindex = TE_ReadNum("m_iEffectName");
			char effectname[32];
			ReadStringTable(g_iUtils_EffectDispatchTable, effectindex, effectname, sizeof(effectname));
			PrintToChatAll("[TE] Effect: %s", effectname);
		}	
	}
	if (g_bTempEntDisable){
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public void OnEntityCreated(int entity, const char[] classname){
	if (g_bEntInfo || g_bTransmitInfo || g_bParticleInfo){
		PrintToChatAll("[Create] Class name from root is %s", classname);

		for (int i = 0; i<=sizeof(g_saEntList)-1; i++){	
			if (StrContains(classname, g_saEntList[i]) != -1){
				if (g_bEntInfo || g_bParticleInfo){
					PrintToChatAll("[Create Ent List]Class name is %s", classname);
				}
				SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
			}
		}
		if (StrContains(classname, "info_particle") == 0){
			PrintToChatAll("[Create Particle] particle match");
			char effectname[32];	
			GetEntPropString(entity, Prop_Data, "m_iszEffectName", effectname, sizeof(effectname));
			if (g_bParticleInfo){
				PrintToChatAll("effect name from entcreate is %s", effectname);
				PrintToChatAll("Class name from entcreate is %s", classname);
			}
			SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
		}
	}
}
public void OnEntitySpawned(int entity){
	if (g_bEntInfo || g_bTransmitInfo || g_bParticleInfo){
		char sClassName[32];
		GetEntityClassname(entity, sClassName, sizeof(sClassName));
		PrintToChatAll("[Spawn] Class name from root is %s", sClassName);
		if (StrContains(sClassName, "info_particle") != -1){
			char effectname[32];	
			GetEntPropString(entity, Prop_Data, "m_iszEffectName", effectname, sizeof(effectname));
			if (g_bParticleInfo){
				PrintToChatAll("Class name from particlespawned is %s", sClassName);
				PrintToChatAll("Effect name from particlespawned is %s", effectname);
			}
			SDKHook(entity, SDKHook_SetTransmit, Hook_Entity_SetTransmit);
		}
		else{
			if (g_bEntInfo){
				PrintToChatAll("Class name from particlespawned is %s", sClassName);
			}
			SDKHook(entity, SDKHook_SetTransmit, Hook_Entity_SetTransmit);
		}
	}
}
public Action Hook_Entity_SetTransmit(int entity, int client){
	if (g_bTransmitInfo || g_bParticleInfo){
		char sClassName[32];
		GetEntityClassname(entity, sClassName, sizeof(sClassName));
		if (StrContains(sClassName, "info_particle") != -1){
			if(g_bParticleInfo){
				char effectname[32];	
				GetEntPropString(entity, Prop_Data, "m_iszEffectName", effectname, sizeof(effectname));
				for (int i = 0; i<=sizeof(g_bExcludedParticles)-1; i++){
					if (!(StrContains(effectname, g_bExcludedParticles[i]) != -1)){
						PrintToChatAll("Effect name from transmit is %s", effectname);
					}
				}
			}
		}
		else{
			if (g_bEntInfo){
				PrintToChatAll("Class name from transmit is %s", sClassName);
			}
		}
	}
}