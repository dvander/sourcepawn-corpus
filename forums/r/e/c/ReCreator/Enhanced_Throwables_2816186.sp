#pragma semicolon 1
#pragma newdecls required

#define MAX_FRAMECHECK 10

#define PLUGIN_VERSION "1.31"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PIPEBOMB_SOUND "weapons/hegrenade/beep.wav" //"PipeBomb.TimerBeep"
#define MOLOTOV_SOUND "weapons/molotov/fire_ignite_2.wav" //"Molotov.Throw"

#define ENABLE_AUTOEXEC true

public Plugin myinfo =
{
	name = "EnhancedThrowables",
	author = "Timocop, Lux",
	description = "Add Dynamic Lights to handheld throwables",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2413605"
};


enum EnumHandheld
{
	EnumHandheld_None,
	EnumHandheld_Pipebomb,
	EnumHandheld_Molotov,
	EnumHandheld_MaxEnum
}

bool bIsL4D2 = false;

Handle hCvar_HandheldLightPipBomb = INVALID_HANDLE;
Handle hCvar_HandheldLightMolotov = INVALID_HANDLE;
Handle hCvar_HandheldThrowLightEnabled = INVALID_HANDLE;


Handle hCvar_PipebombFuseColor = INVALID_HANDLE;
Handle hCvar_PipebombFlashColor = INVALID_HANDLE;
Handle hCvar_PipebombLightDistance = INVALID_HANDLE;
Handle hCvar_MolotovColor = INVALID_HANDLE;
Handle hCvar_MolotovLightDistance = INVALID_HANDLE;

bool g_bHandheldLightPipeBomb = false;
bool g_bHandheldLightMolotov = false;
bool g_bHandheldThrowLightEnabled = false;

char g_sPipebombFuseColor[12], g_sPipebombFlashColor[12], g_sMoloFlashColour[12];
float g_fPipebombLightDistance, g_fMolotovLightDistance;


public void OnPluginStart()
{
	char sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if(StrEqual(sGameName, "left4dead"))
		bIsL4D2 = false;
	else if(StrEqual(sGameName, "left4dead2"))
		bIsL4D2 = true;
	else
		SetFailState("This plugin only runs on Left 4 Dead and Left 4 Dead 2!");
	
	CreateConVar("EnhanceThrowables_Version", PLUGIN_VERSION, "Enhance Handheld Throwables version", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	hCvar_HandheldLightPipBomb = CreateConVar("l4d_handheld_light_pipe_bomb", "1", "Enables/Disables handheld pipebomb light.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_HandheldLightMolotov = CreateConVar("l4d_handheld_light_Molotov", "1", "Enables/Disables Molotov light.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_HandheldThrowLightEnabled = CreateConVar("l4d_handheld_throw_light_enable", "1", "Enables/Disables handheld light after throwing.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	hCvar_PipebombFuseColor = CreateConVar("l4d_handheld_light_pipebomb_fuse_colour", "215 215 1", "Pipebomb fure light color (0-255 0-255 0-255)", FCVAR_NOTIFY);
	hCvar_PipebombFlashColor = CreateConVar("l4d_handheld_light_pipebomb_flash_colour", "200 1 1", "Pipebomb flash light color (0-255 0-255 0-255)", FCVAR_NOTIFY);
	hCvar_PipebombLightDistance = CreateConVar("l4d_handheld_light_pipebomb_light_distance", "255.0", "Pipebomb Max light distance (0 = disabled)", FCVAR_NOTIFY, true, 0.1, true, 9999.0);
	
	hCvar_MolotovColor = CreateConVar("l4d_handheld_light_molotov_colour", "255 50 0", "Molotovs light color (0-255 0-255 0-255)", FCVAR_NOTIFY);
	hCvar_MolotovLightDistance = CreateConVar("l4d_handheld_light_molotov_light_distance", "200.0", "Molotovs light distance (0 = disabled)", FCVAR_NOTIFY, true, 0.1, true, 9999.0);
	
	HookConVarChange(hCvar_HandheldLightPipBomb, eConvarChanged);
	HookConVarChange(hCvar_HandheldLightMolotov, eConvarChanged);
	HookConVarChange(hCvar_HandheldThrowLightEnabled, eConvarChanged);
	
	HookConVarChange(hCvar_PipebombFuseColor, eConvarChanged);
	HookConVarChange(hCvar_PipebombFlashColor, eConvarChanged);
	HookConVarChange(hCvar_PipebombLightDistance, eConvarChanged);
	
	HookConVarChange(hCvar_MolotovColor, eConvarChanged);
	HookConVarChange(hCvar_MolotovLightDistance, eConvarChanged);
	
	CvarsChanged();
	
	AddNormalSoundHook(HandheldSoundHook);
	
	#if ENABLE_AUTOEXEC
	AutoExecConfig(true, "Enhance_Handheld_Throwables");
	#endif
}

public Action HandheldSoundHook(int clients[MAXPLAYERS], int &numClients,
        char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed) 
{
	if(!g_bHandheldThrowLightEnabled)
		return Plugin_Continue;
	
	if(entity < 0 || entity > 2048)
		return Plugin_Continue;
	
	static int iAlreadyThrownEntityRef[2048+1] = {INVALID_ENT_REFERENCE, ...};
	if(IsValidEntRef(iAlreadyThrownEntityRef[entity]))
		return Plugin_Continue;
	
	iAlreadyThrownEntityRef[entity] = EntIndexToEntRef(entity);
	
	if(!IsValidEntity(entity))
		return Plugin_Continue;
	
	static char sClassname[32];
	
	GetEntityClassname(entity, sClassname, sizeof(sClassname));
	if(!StrEqual(sClassname, "pipe_bomb_projectile") && !StrEqual(sClassname, "molotov_projectile"))
		return Plugin_Continue;
	
	switch(sClassname[0])
	{
		case 'p':
		{
			if(!StrEqual(sample, PIPEBOMB_SOUND))
				return Plugin_Continue;
			
			int iLight = CreateLight(entity, EnumHandheld_Pipebomb);
			if(iLight == -1 || !IsValidEntity(iLight))
				return Plugin_Continue;
			
			EntitySetParent(iLight, entity);
		}
		case 'm':
		{
			if(!StrEqual(sample, MOLOTOV_SOUND))
				return Plugin_Continue;
			
			int iLight = CreateLight(entity, EnumHandheld_Molotov);
			if(iLight == -1 || !IsValidEntity(iLight))
				return Plugin_Continue;
			
			EntitySetParent(iLight, entity);
		}
	}
	
	return Plugin_Continue;
}

public void OnGameFrame()
{
	static int ClientLightRef[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};
	static EnumHandheld iClienthandheld[MAXPLAYERS+1] = {EnumHandheld_None, ...};
	
	static int iFrameskip = 0;
	iFrameskip = (iFrameskip + 1) % MAX_FRAMECHECK;
	
	if(iFrameskip != 0 || !IsServerProcessing())
		return;
	
	//Dont use OnPlayerRunCmd, it doenst run when the player isnt in-game!
	//But you need to check if hes in-game or not, cuz remove light.
	static  int i;
	for(i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i)
				|| GetClientTeam(i) != 2
				|| !IsPlayerAlive(i)
				|| IsSurvivorIncapacitated(i)
				|| IsSurvivorBusyWithInfected(i)
				|| IsSurvivorUsingMountedWeapon(i))
		{
			
			if(IsValidEntRef(ClientLightRef[i]))
			{
				AcceptEntityInput(ClientLightRef[i], "Kill");
				ClientLightRef[i] = INVALID_ENT_REFERENCE;
			}
		}
		else
		{
			static EnumHandheld flCurrentHandheld;
			flCurrentHandheld = GetHoldingHandheld(i);
			
			//Fix on picking up other handhelds while holding an handheld
			if(flCurrentHandheld != iClienthandheld[i])
			{
				iClienthandheld[i] = flCurrentHandheld;
				
				if(IsValidEntRef(ClientLightRef[i]))
				{
					AcceptEntityInput(ClientLightRef[i], "Kill");
					ClientLightRef[i] = INVALID_ENT_REFERENCE;
				}
			}
			
			if(!IsValidEntRef(ClientLightRef[i]))
			{
				static int iLight;
				iLight = CreateLight(i, flCurrentHandheld);
				if(iLight != -1 && IsValidEntity(iLight))
				{
					ClientLightRef[i] = EntIndexToEntRef(iLight);
				}
			}
		}
	}
}

int CreateLight(int entity, EnumHandheld iHandheld=EnumHandheld_None)
{
	if(iHandheld != EnumHandheld_Pipebomb
			&& iHandheld != EnumHandheld_Molotov)
		return -1;
	
	switch(iHandheld)
	{
		case EnumHandheld_Pipebomb:
		{
			if(g_fPipebombLightDistance < 1.0)
				return -1;
		}
		case EnumHandheld_Molotov:
		{
			if(g_fMolotovLightDistance < 1.0)
				return -1;
		}
	}
	
	int iLight = CreateEntityByName("light_dynamic");
	if(iLight == -1)
		return -1;
	
	float fPos[3];
	EntityGetPosition(entity, fPos);
	
	TeleportEntity(iLight, fPos, NULL_VECTOR, NULL_VECTOR);
	
	if(entity < MaxClients+1)// should block the error on olderversion on error parent attachment
	{
		char sModel[31];
		GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
		
		switch(sModel[29])
		{
			case 'b', 'd', 'c', 'h', 'w' ://nick, rochelle, coach, ellis, adawong
			{
				EntitySetParentAttachment(iLight, entity, "weapon_bone");
			}
			case 'v', 'e', 'a'://bill, francis, louis
			{//armR_T
				EntitySetParentAttachment(iLight, entity, "armR_T");
				TeleportEntity(iLight,  view_as<float>({ 8.0, 18.0, 0.0 }),  view_as<float>({ -20.0, 100.0, 0.0 }), NULL_VECTOR);
			}
			case 'n'://zoey
			{
				EntitySetParentAttachment(iLight, entity, "armR_T");
				TeleportEntity(iLight,  view_as<float>({ 0.0, 20.0, 0.0 }),  view_as<float>({ 0.0, 90.0, 0.0 }), NULL_VECTOR);
			}
			default:
			{
				EntitySetParentAttachment(iLight, entity, "survivor_light");
			}
		}
	}
	
	switch(iHandheld)
	{
		case EnumHandheld_Pipebomb:
		{
			char sBuffer[64];
			
			DispatchKeyValue(iLight, "brightness", "1");
			DispatchKeyValueFloat(iLight, "spotlight_radius", 32.0);
			DispatchKeyValueFloat(iLight, "distance", g_fPipebombLightDistance / 8);
			DispatchKeyValue(iLight, "style", "-1");
			
			DispatchSpawn(iLight);
			ActivateEntity(iLight);
			
			AcceptEntityInput(iLight, "TurnOff");
			
			Format(sBuffer, sizeof(sBuffer), g_sPipebombFuseColor);
			SetVariantString(sBuffer);
			AcceptEntityInput(iLight, "Color");
			
			AcceptEntityInput(iLight, "TurnOn");
			
			Format(sBuffer, sizeof(sBuffer), "OnUser1 !self:Color:%s:0.0167:-1", g_sPipebombFlashColor);
			SetVariantString(sBuffer);
			AcceptEntityInput(iLight, "AddOutput");
			
			Format(sBuffer, sizeof(sBuffer), "OnUser1 !self:distance:%f:0.0344:-1", (g_fPipebombLightDistance / 7) * 2);
			SetVariantString(sBuffer);
			AcceptEntityInput(iLight, "AddOutput");
			
			Format(sBuffer, sizeof(sBuffer), "OnUser1 !self:distance:%f:0.0501:-1", (g_fPipebombLightDistance / 7) * 3);
			SetVariantString(sBuffer);
			AcceptEntityInput(iLight, "AddOutput");
			
			Format(sBuffer, sizeof(sBuffer), "OnUser1 !self:distance:%f:0.0668:-1", (g_fPipebombLightDistance / 7) * 4);
			SetVariantString(sBuffer);
			AcceptEntityInput(iLight, "AddOutput");
			
			Format(sBuffer, sizeof(sBuffer), "OnUser1 !self:distance:%f:0.0835:-1", (g_fPipebombLightDistance / 7) * 5);
			SetVariantString(sBuffer);
			AcceptEntityInput(iLight, "AddOutput");
			
			Format(sBuffer, sizeof(sBuffer), "OnUser1 !self:distance:%f:0.1002:-1", (g_fPipebombLightDistance / 7) * 6);
			SetVariantString(sBuffer);
			AcceptEntityInput(iLight, "AddOutput");
			
			Format(sBuffer, sizeof(sBuffer), "OnUser1 !self:distance:%f:0.1169:-1", g_fPipebombLightDistance);
			SetVariantString(sBuffer);
			AcceptEntityInput(iLight, "AddOutput");
			
			Format(sBuffer, sizeof(sBuffer), "OnUser1 !self:distance:%f.0:0.1336:-1", g_fPipebombLightDistance / 4);
			SetVariantString(sBuffer);
			AcceptEntityInput(iLight, "AddOutput");
			
			Format(sBuffer, sizeof(sBuffer), "OnUser1 !self:distance:%f.0:0.1503:-1", g_fPipebombLightDistance / 8);
			SetVariantString(sBuffer);
			AcceptEntityInput(iLight, "AddOutput");
			
			Format(sBuffer, sizeof(sBuffer), "OnUser1 !self:Color:%s:0.1503:-1", g_sPipebombFuseColor);
			SetVariantString(sBuffer);
			AcceptEntityInput(iLight, "AddOutput");
			
			SetVariantString("OnUser1 !self:FireUser1::0.20004:-1");
			AcceptEntityInput(iLight, "AddOutput");
			
			AcceptEntityInput(iLight, "FireUser1");
			
			return iLight;
		}
		case EnumHandheld_Molotov:
		{
			DispatchKeyValue(iLight, "brightness", "1");
			DispatchKeyValueFloat(iLight, "spotlight_radius", 32.0);
			DispatchKeyValueFloat(iLight, "distance", g_fMolotovLightDistance);
			DispatchKeyValue(iLight, "style", "6");
			
			DispatchSpawn(iLight);
			ActivateEntity(iLight);
			
			AcceptEntityInput(iLight, "TurnOff");
			
			SetVariantString(g_sMoloFlashColour);
			AcceptEntityInput(iLight, "Color");
			
			AcceptEntityInput(iLight, "TurnOn");
			
			return iLight;
		}
	}
	return -1;
}

public void OnMapStart()
{
	CvarsChanged();
}

public void eConvarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	CvarsChanged();
}

void CvarsChanged()
{
	g_bHandheldLightPipeBomb = GetConVarInt(hCvar_HandheldLightPipBomb) > 0;
	g_bHandheldLightMolotov = GetConVarInt(hCvar_HandheldLightMolotov) > 0;
	g_bHandheldThrowLightEnabled = GetConVarInt(hCvar_HandheldThrowLightEnabled) > 0;
	
	g_fPipebombLightDistance = GetConVarFloat(hCvar_PipebombLightDistance);
	GetConVarString(hCvar_PipebombFuseColor, g_sPipebombFuseColor, sizeof(g_sPipebombFuseColor));
	GetConVarString(hCvar_PipebombFlashColor, g_sPipebombFlashColor, sizeof(g_sPipebombFlashColor));
	
	g_fMolotovLightDistance = GetConVarFloat(hCvar_MolotovLightDistance);
	GetConVarString(hCvar_MolotovColor, g_sMoloFlashColour, sizeof(g_sMoloFlashColour));
}

//Tools Folding
static bool IsValidEntRef(int iEntRef)
{
	return (iEntRef != 0 && EntRefToEntIndex(iEntRef) != INVALID_ENT_REFERENCE);
}

void EntityGetPosition(int entity, float fPos[3])
{
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", fPos);
}

void EntitySetParent(int entity, int iTarget)
{
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", iTarget);
}

void EntitySetParentAttachment(int entity,int iTarget, char [] sAttachName)
{
	EntitySetParent(entity, iTarget);
	
	SetVariantString(sAttachName);
	AcceptEntityInput(entity, "SetParentAttachment");
}

static EnumHandheld GetHoldingHandheld(int client)
{
	char sHandheld[32];
	sHandheld[0] = 0;
	GetClientWeapon(client, sHandheld, sizeof(sHandheld));
	
	if(sHandheld[7] != 'p' && sHandheld[7] != 'm')
		return EnumHandheld_None;
	
	if(StrEqual(sHandheld, "weapon_pipe_bomb") && g_bHandheldLightPipeBomb)
		return EnumHandheld_Pipebomb;
	else if(StrEqual(sHandheld, "weapon_molotov") && g_bHandheldLightMolotov)
		return EnumHandheld_Molotov;
	
	return EnumHandheld_None;
}

static bool IsSurvivorIncapacitated(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0;
}

static bool IsSurvivorBusyWithInfected(int client)
{
	if(bIsL4D2)
	{
		if(GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0)
			return true;
		if(GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0)
			return true;
		if(GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0)
			return true;
		if(GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0)
			return true;
		if(GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0)
			return true;
	}
	else
	{
		if(GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0)
			return true;
		if(GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0)
			return true;
	}
	
	return false;
}

static bool IsSurvivorUsingMountedWeapon(int client)
{
	return (GetEntProp(client, Prop_Send, "m_usingMountedWeapon") > 0);
}
