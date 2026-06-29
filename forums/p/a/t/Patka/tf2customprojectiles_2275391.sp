#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION		"1.1"

#define PROJECTILE_COUNT	16
#define MENU_MAIN			(1 << 1)
#define MENU_MODELS			(1 << 2)
#define MENU_EFFECTS		(1 << 3)
#define MENU_MODEL_SLOT		(1 << 4)
#define MENU_EFFECT_SLOT	(1 << 5)

new Handle:g_hCvarParticleTime = INVALID_HANDLE;
new Float:g_fParticleTime;

new String:g_strModelName[256][256];
new String:g_strModelPath[256][256];
new g_iProjectileCount;

new String:g_strEffectName[256][256];
new String:g_strEffectClassname[256][256];
new g_iEffectCount;

new g_iClientModelIndex[MAXPLAYERS+1];
new String:g_strClientModelPath[MAXPLAYERS+1][PROJECTILE_COUNT][256];

new String:g_strClientEffectName[MAXPLAYERS+1][256];
new String:g_strClientEffectClassname[MAXPLAYERS+1][PROJECTILE_COUNT][256];

public Plugin:myinfo =
{
	name = "TF2 Custom Projectiles",
	author = "Patka",
	description = "Customize projectile models and effects.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("tf_custom_projectiles_version", PLUGIN_VERSION, "TF2 Custom Projectiles plugin version.", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	g_hCvarParticleTime = CreateConVar("sm_cproj_effect_time", "5.0", "Time a projectile effect is attached", FCVAR_PLUGIN, true, 0.0, true, 60.0);
	RegAdminCmd("sm_proj", Command_Projectiles, ADMFLAG_CUSTOM6);
	HookConVarChange(g_hCvarParticleTime, Cvar_Changed);
}

public OnConfigsExecuted()
{
	g_fParticleTime = GetConVarFloat(g_hCvarParticleTime);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	OnConfigsExecuted();
}

public OnMapStart()
{
	LoadProjectiles();
}

public OnClientPostAdminCheck(client)
{
	g_iClientModelIndex[client] = -1;
	g_strClientEffectName[client] = "";
	
	for (new i = 0; i < PROJECTILE_COUNT; i++)
	{
		g_strClientModelPath[client][i] = "";
		g_strClientEffectClassname[client][i] = "";
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "tf_projectile_arrow"))
	{
		SDKHook(entity, SDKHook_SpawnPost, TF_PROJECTILE_ARROW);
	}
	
	if (StrEqual(classname, "tf_projectile_ball_ornament"))
	{
		SDKHook(entity, SDKHook_SpawnPost, TF_PROJECTILE_BALL_ORNAMENT);
	}
	
	if (StrEqual(classname, "tf_projectile_cleaver"))
	{
		SDKHook(entity, SDKHook_SpawnPost, TF_PROJECTILE_CLEAVER);
	}
	
	if (StrEqual(classname, "tf_projectile_energy_ball"))
	{
		SDKHook(entity, SDKHook_SpawnPost, TF_PROJECTILE_ENERGY_BALL);
	}
	
	if (StrEqual(classname, "tf_projectile_energy_ring"))
	{
		SDKHook(entity, SDKHook_SpawnPost, TF_PROJECTILE_ENERGY_RING);
	}
	
	if (StrEqual(classname, "tf_projectile_flare"))
	{
		SDKHook(entity, SDKHook_SpawnPost, TF_PROJECTILE_FLARE);
	}
	
	if (StrEqual(classname, "tf_projectile_healing_bolt"))
	{
		SDKHook(entity, SDKHook_SpawnPost, TF_PROJECTILE_HEALING_BOLT);
	}
	
	if (StrEqual(classname, "tf_projectile_jar"))
	{
		SDKHook(entity, SDKHook_SpawnPost, TF_PROJECTILE_JAR);
	}
	
	if (StrEqual(classname, "tf_projectile_jar_milk"))
	{
		SDKHook(entity, SDKHook_SpawnPost, TF_PROJECTILE_JAR_MILK);
	}
	
	if (StrEqual(classname, "tf_projectile_pipe"))
	{
		SDKHook(entity, SDKHook_SpawnPost, TF_PROJECTILE_PIPE);
	}
	
	if (StrEqual(classname, "tf_projectile_pipe_remote"))
	{
		SDKHook(entity, SDKHook_SpawnPost, TF_PROJECTILE_PIPE_REMOTE);
	}
	
	if (StrEqual(classname, "tf_projectile_rocket"))
	{
		SDKHook(entity, SDKHook_SpawnPost, TF_PROJECTILE_ROCKET);
	}
	
	if (StrEqual(classname, "tf_projectile_sentryrocket"))
	{
		SDKHook(entity, SDKHook_SpawnPost, TF_PROJECTILE_SENTRYROCKET);
	}
	
	if (StrEqual(classname, "tf_projectile_stun_ball"))
	{
		SDKHook(entity, SDKHook_SpawnPost, TF_PROJECTILE_STUN_BALL);
	}
	
	if (StrEqual(classname, "tf_projectile_syringe"))
	{
		SDKHook(entity, SDKHook_SpawnPost, TF_PROJECTILE_SYRINGE);
	}
	
	if (StrEqual(classname, "tf_projectile_throwable"))
	{
		SDKHook(entity, SDKHook_SpawnPost, TF_PROJECTILE_THROWABLE);
	}
}

public TF_PROJECTILE_ARROW(entity)
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	SetModelAndParticle(client, entity, 0);
}

public TF_PROJECTILE_BALL_ORNAMENT(entity)
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	SetModelAndParticle(client, entity, 1);
}

public TF_PROJECTILE_CLEAVER(entity)
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	SetModelAndParticle(client, entity, 2);
}

public TF_PROJECTILE_ENERGY_BALL(entity)
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	SetModelAndParticle(client, entity, 3);
}

public TF_PROJECTILE_ENERGY_RING(entity)
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	SetModelAndParticle(client, entity, 4);
}

public TF_PROJECTILE_FLARE(entity)
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	SetModelAndParticle(client, entity, 5);
}

public TF_PROJECTILE_HEALING_BOLT(entity)
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	SetModelAndParticle(client, entity, 6);
}

public TF_PROJECTILE_JAR(entity)
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	SetModelAndParticle(client, entity, 7);
}

public TF_PROJECTILE_JAR_MILK(entity)
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	SetModelAndParticle(client, entity, 8);
}

public TF_PROJECTILE_PIPE(entity)
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	SetModelAndParticle(client, entity, 9);
}

public TF_PROJECTILE_PIPE_REMOTE(entity)
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	SetModelAndParticle(client, entity, 10);
}

public TF_PROJECTILE_ROCKET(entity)
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	SetModelAndParticle(client, entity, 11);
}

public TF_PROJECTILE_SENTRYROCKET(entity)
{
	new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	new sentry = FindSendPropOffs("CObjectSentrygun", "m_hBuilder");
	new client = GetEntDataEnt2(owner, sentry);
	SetModelAndParticle(client, entity, 12);
}

public TF_PROJECTILE_STUN_BALL(entity)
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	SetModelAndParticle(client, entity, 13);
}

public TF_PROJECTILE_SYRINGE(entity)
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	SetModelAndParticle(client, entity, 14);
}

public TF_PROJECTILE_THROWABLE(entity)
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	SetModelAndParticle(client, entity, 15);
}

public Action:Command_Projectiles(client, args)
{
	if (args != 0)
	{
		ReplyToCommand(client, "[SM] Usage: sm_proj");
		return Plugin_Handled;
	}
	
	LoadProjectiles();
	LoadEffectCFG();
	ShowProjectilesMenu(client, MENU_MAIN);
	return Plugin_Handled;
}

public ShowProjectilesMenu(client, menutype)
{
	decl i;
	decl String:index[256];
	decl Handle:menu;
	
	if (menutype & MENU_MAIN)
	{
		menu = CreateMenu(hMainMenu);
		SetMenuTitle(menu, "TF2 Projectiles Menu:");
		AddMenuItem(menu, "0", "Model");
		AddMenuItem(menu, "1", "Effect");
	}
	
	if (menutype & MENU_MODELS)
	{
		menu = CreateMenu(hProjectilesMenu);
		SetMenuTitle(menu, "TF2 Projectile Model:");
		SetMenuExitBackButton(menu, true);
		AddMenuItem(menu, "-1", "Remove Model");
		
		for (i = 0; i < g_iProjectileCount; i++)
		{
			IntToString(i, index, sizeof(index));
			AddMenuItem(menu, index, g_strModelName[i]);
		}
	}
	
	if (menutype & MENU_EFFECTS)
	{
		menu = CreateMenu(hProjectileEffectMenu);
		SetMenuTitle(menu, "TF2 Projectile Effect:");
		SetMenuExitBackButton(menu, true);
		AddMenuItem(menu, "", "Remove Effect");
		
		for (i = 0; i < g_iEffectCount; i++)
		{
			AddMenuItem(menu, g_strEffectClassname[i], g_strEffectName[i]);
		}
	}
	
	if (menutype & MENU_MODEL_SLOT)
	{
		menu = CreateMenu(hProjectileSlotMenu);
		SetMenuTitle(menu, "TF2 Projectile Model Slot:");
		SetMenuExitBackButton(menu, true);
		AddSlotsToMenu(menu);
	}
	
	if (menutype & MENU_EFFECT_SLOT)
	{
		menu = CreateMenu(hEffectSlotMenu);
		SetMenuTitle(menu, "TF2 Projectile Effect Slot:");
		SetMenuExitBackButton(menu, true);
		AddSlotsToMenu(menu);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

stock AddSlotsToMenu(Handle:menu)
{
	AddMenuItem(menu, "0", "Huntsman Arrow");
	AddMenuItem(menu, "1", "Wrap Assassin Ball Ornament");
	AddMenuItem(menu, "2", "Flying Gulletine Cleaver");
	AddMenuItem(menu, "3", "The Cow Mangler 5000");
	//AddMenuItem(menu, "4", "Energy Ring");
	AddMenuItem(menu, "5", "Flare Gun Flare");
	AddMenuItem(menu, "6", "Crusader's Crossbow Healing Bolt");
	AddMenuItem(menu, "7", "Jarate");
	AddMenuItem(menu, "8", "Mad Milk");
	AddMenuItem(menu, "9", "Gernade Launcher Pipe");
	AddMenuItem(menu, "10", "Sticky Bomb Launcher Pipe");
	AddMenuItem(menu, "11", "Rocket Launcher Rocket");
	AddMenuItem(menu, "12", "Sentry Rocket");
	AddMenuItem(menu, "13", "Sandman Stun Ball");
	AddMenuItem(menu, "14", "Syringe Gun Syringe");
	//AddMenuItem(menu, "15", "Throwable");
}

public hMainMenu(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:choice[64];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			new index = StringToInt(choice);
			
			switch (index)
			{
				case 0:
				{
					ShowProjectilesMenu(client, MENU_MODELS);
				}
				
				case 1:
				{
					ShowProjectilesMenu(client, MENU_EFFECTS);
				}
			}
		}
		
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public hProjectilesMenu(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:choice[64];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			new index = StringToInt(choice);
			g_iClientModelIndex[client] = index;
			ShowProjectilesMenu(client, MENU_MODEL_SLOT);
		}
		
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				ShowProjectilesMenu(client, MENU_MAIN);
			}
		}
		
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public hProjectileEffectMenu(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:choice[64];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			g_strClientEffectName[client] = choice;
			ShowProjectilesMenu(client, MENU_EFFECT_SLOT);
		}
		
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				ShowProjectilesMenu(client, MENU_MAIN);
			}
		}
		
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public hProjectileSlotMenu(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:choice[64];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			new slot = StringToInt(choice);
			new index = g_iClientModelIndex[client];
			
			if (index == -1)
			{
				g_strClientModelPath[client][slot] = "";
			}
			else
			{
				g_strClientModelPath[client][slot] = g_strModelPath[index];
			}
			
			ShowProjectilesMenu(client, MENU_MODELS);
		}
		
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				ShowProjectilesMenu(client, MENU_MODELS);
			}
		}
		
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public hEffectSlotMenu(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:choice[64];
			GetMenuItem(menu, param2, choice, sizeof(choice));
			new slot = StringToInt(choice);
			g_strClientEffectClassname[client][slot] = g_strClientEffectName[client];
			
			ShowProjectilesMenu(client, MENU_EFFECTS);
		}
		
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				ShowProjectilesMenu(client, MENU_EFFECTS);
			}
		}
		
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

stock SetModelAndParticle(client, entity, index)
{
	if (IsValidClient(client))
	{
		if (!StrEqual(g_strClientModelPath[client][index], ""))
		{
			SetEntityModel(entity, g_strClientModelPath[client][index]);
		}
		
		if (!StrEqual(g_strClientEffectClassname[client][index], ""))
		{
			new iParticle = CreateParticle(entity, g_strClientEffectClassname[client][index], true);
			new Handle:pack;
			CreateDataTimer(g_fParticleTime, Timer_KillParticle, pack);
			WritePackCell(pack, iParticle);
		}
	}
}

public Action:Timer_KillParticle(Handle:timer, Handle:pack)
{
	ResetPack(pack);	
	new entity = ReadPackCell(pack);
	
	if (IsValidEdict(entity))
	{
		RemoveEdict(entity);
	}
	
	return Plugin_Stop;
}

stock CreateParticle(iEntity, String:strParticle[], bool:bAttach = false, String:strAttachmentPoint[]="", Float:fOffset[3]={0.0, 0.0, 0.0})
{
	new iParticle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(iParticle))
	{
		decl Float:fPosition[3];
		decl Float:fAngles[3];
		decl Float:fForward[3];
		decl Float:fRight[3];
		decl Float:fUp[3];
		
		// Retrieve entity's position and angles
		//GetClientAbsOrigin(iClient, fPosition);
		//GetClientAbsAngles(iClient, fAngles);
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPosition);
		
		// Determine vectors and apply offset
		GetAngleVectors(fAngles, fForward, fRight, fUp);    // I assume 'x' is Right, 'y' is Forward and 'z' is Up
		fPosition[0] += fRight[0]*fOffset[0] + fForward[0]*fOffset[1] + fUp[0]*fOffset[2];
		fPosition[1] += fRight[1]*fOffset[0] + fForward[1]*fOffset[1] + fUp[1]*fOffset[2];
		fPosition[2] += fRight[2]*fOffset[0] + fForward[2]*fOffset[1] + fUp[2]*fOffset[2];
		
		// Teleport and attach to client
		//TeleportEntity(iParticle, fPosition, fAngles, NULL_VECTOR);
		TeleportEntity(iParticle, fPosition, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(iParticle, "effect_name", strParticle);
		
		if (bAttach == true)
		{
			SetVariantString("!activator");
			AcceptEntityInput(iParticle, "SetParent", iEntity, iParticle, 0);            
			
			if (StrEqual(strAttachmentPoint, "") == false)
			{
				SetVariantString(strAttachmentPoint);
				AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset", iParticle, iParticle, 0);                
			}
		}
		
		// Spawn and start
		DispatchSpawn(iParticle);
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "Start");
	}
	
	return iParticle;
}

stock LoadProjectileCFG()
{
	new Handle:kvProjectileCFG = CreateKeyValues("tf2projectiles");
	new String:strLocation[256];
	
	// Load the key files.
	BuildPath(Path_SM, strLocation, sizeof(strLocation), "configs/tf2projectiles/projectiles.cfg");
	FileToKeyValues(kvProjectileCFG, strLocation);
	
	// Check if the parsed values are correct
	if (!KvGotoFirstSubKey(kvProjectileCFG)) 
	{
		SetFailState("Error, can't read file containing the projectiles list: %s", strLocation);
		return;
	}
	
	new i = 0;
	do
	{
		KvGetSectionName(kvProjectileCFG, g_strModelName[i], 256);
		KvGetString(kvProjectileCFG, "Model", g_strModelPath[i], 256);
		i++;
	}
	while (KvGotoNextKey(kvProjectileCFG));
	
	g_iProjectileCount = i;
	CloseHandle(kvProjectileCFG);
}

stock LoadEffectCFG()
{
	new Handle:kvEffectCFG = CreateKeyValues("tf2projectileeffects");
	new String:strLocation[256];
	
	// Load the key files.
	BuildPath(Path_SM, strLocation, sizeof(strLocation), "configs/tf2projectiles/effects.cfg");
	FileToKeyValues(kvEffectCFG, strLocation);
	
	// Check if the parsed values are correct
	if (!KvGotoFirstSubKey(kvEffectCFG)) 
	{
		SetFailState("Error, can't read file containing the effects list: %s", strLocation);
		return;
	}
	
	new i = 0;
	do
	{
		KvGetSectionName(kvEffectCFG, g_strEffectName[i], 256);
		KvGetString(kvEffectCFG, "Classname", g_strEffectClassname[i], 256);
		i++;
	}
	while (KvGotoNextKey(kvEffectCFG));
	
	g_iEffectCount = i;
	CloseHandle(kvEffectCFG);
}

stock LoadProjectiles()
{
	LoadProjectileCFG();
	for (new i = 0; i < g_iProjectileCount; i++)
	{
		PrecacheModel(g_strModelPath[i]);
	}
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}

stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}
