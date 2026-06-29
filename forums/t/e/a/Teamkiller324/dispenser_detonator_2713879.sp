/*
* Dispenser Detonator (TF2) 
* Author(s): retsam
* File: dispenser_detonator.sp
* Description: Makes dispensers explode dealing damage to enemies within radius!
*
*
* 0.2.2
*	- Updated syntax [Tk /id/Teamkiller324]
*
*
* 0.2.1
*	- Fixed invalid edict error [MasterOfTheXP]
*
*
* 0.2 - Moved the non-sdk hook detonation function to its own stock.
*	- Put the particle duration to 6 secs instead of 5.
*     
* 0.1
*	- Initial release. 
*/

#pragma semicolon 1

#include	<sourcemod>
#include	<tf2_stocks>
#undef		REQUIRE_EXTENSIONS
#include	<sdkhooks>

#pragma		semicolon 1
#pragma		newdecls required

#define		PLUGIN_VERSION "0.2.2"

#define		TF_OBJECT_DISPENSER	0

ConVar		Cvar_DispenserDet_Enabled;
ConVar		Cvar_DispenserDet_Damage;
ConVar		Cvar_DispenserDet_DmgForce;
ConVar		Cvar_DispenserDet_Radius;
ConVar		Cvar_DispenserDet_Mode;

int			g_cvarDetDamage;
int			g_cvarDetRadius;
int			g_cvarDetMode;

float		g_fcvarDmgForce;

bool		g_bIsEnabled = true;
bool		g_bUseSDKhooks;
bool		g_bInfoMsgShown[MAXPLAYERS+1] = { false, ... };
bool		g_bDestroyCmdUsed[MAXPLAYERS+1] = { false, ... };
bool		g_bDetEnabled[MAXPLAYERS+1] = { true, ... };

public Plugin myinfo = 
{
	name = "Dispenser Detonator",
	author = "retsam, fixed by MasterOfTheXP, Updated syntax by Tk /id/Teamkiller324",
	description = "Makes dispensers explode dealing damage to enemies within radius!",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=134904"
}

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_TF2)
		SetFailState("[dispenser_detonator.sp] Detected game other than [TF2], plugin disabled.");

	CreateConVar("sm_dispenserdet_version", PLUGIN_VERSION, "Version of Dispenser Detonator", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Cvar_DispenserDet_Enabled 	= CreateConVar("sm_dispenserdet_enabled",	"1",	"Enable dispenser detonator plugin?(1/0 = yes/no)");
	Cvar_DispenserDet_Mode		= CreateConVar("sm_dispenserdet_mode",		"2",	"Mode for damage calculation used. (0/1/2) \n0=flat base damage \n1=base damage is multiplied by dispenser level only \n2=damage is calculated by base,metal,level.");
	Cvar_DispenserDet_Damage	= CreateConVar("sm_dispenserdet_damage",	"40.0", "Base explosion damage. (Note: This is only the base damage and may not be the total damage depending on mode)", _, true, 0.0, true, 500.0);
	Cvar_DispenserDet_DmgForce	= CreateConVar("sm_dispenserdet_dmgforce",	"0.0",	"Explosion damage force. This has to do with the force/knockback emitted on player based on damage received. (Not sure this cvar changes anything)", _, true, 0.0, true, 300.0);
	Cvar_DispenserDet_Radius	= CreateConVar("sm_dispenserdet_radius",	"125.0","Explosion radius.", _, true, 25.0, true, 1000.0);

	HookEvent("player_death", Hook_PlayerDeath, EventHookMode_Pre);

	HookConVarChange(Cvar_DispenserDet_Enabled, Cvars_Changed);
	HookConVarChange(Cvar_DispenserDet_Damage, Cvars_Changed);
	HookConVarChange(Cvar_DispenserDet_DmgForce, Cvars_Changed);
	HookConVarChange(Cvar_DispenserDet_Radius, Cvars_Changed);
	HookConVarChange(Cvar_DispenserDet_Mode, Cvars_Changed);

	AddCommandListener(Command_Destroy, "destroy");
	RegConsoleCmd("sm_detonate", Command_DetToggle, "Toggle Dispenser Detonator");
	RegConsoleCmd("sm_det", Command_DetToggle, "Toggle Dispenser Detonator");

	AutoExecConfig(true, "plugin.dispenser_detonator");
}

public void OnAllPluginsLoaded()
{
	char sExtError[256];
	int iExtStatus = GetExtensionFileStatus("sdkhooks.ext", sExtError, sizeof(sExtError));
	if (iExtStatus == -2)
	{
		PrintToServer("[dispenser_detonator.sp] SDK Hooks extension was not found.");
		PrintToServer("[dispenser_detonator.sp] Plugin continued to load, but will run in Non-SDKhooks mode.");
		g_bUseSDKhooks = false;
	}
	if (iExtStatus == -1 || iExtStatus == 0)
	{
		PrintToServer("[dispenser_detonator.sp] SDK Hooks extension is loaded with errors.");
		PrintToServer("[dispenser_detonator.sp] Status reported was [%s].", sExtError);
		PrintToServer("[dispenser_detonator.sp] Plugin continued to load, but will run in Non-SDKhooks mode.");
		g_bUseSDKhooks = false;
	}
	if (iExtStatus == 1)
	{
		PrintToServer("[dispenser_detonator.sp] SDK Hooks extension is loaded.");
		PrintToServer("[dispenser_detonator.sp] Plugin will use SDK Hooks.");
		g_bUseSDKhooks = true;
	}
}

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "sdkhooks.ext"))
	g_bUseSDKhooks = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if(StrEqual(name, "sdkhooks.ext"))
	g_bUseSDKhooks = false;
}

public void OnClientPostAdminCheck(int client)
{
	g_bDestroyCmdUsed[client] = false;
	g_bDetEnabled[client] = true;
	g_bInfoMsgShown[client] = false;
}

public void OnConfigsExecuted()
{
	g_bIsEnabled = GetConVarBool(Cvar_DispenserDet_Enabled);
	g_cvarDetDamage = GetConVarInt(Cvar_DispenserDet_Damage);
	g_fcvarDmgForce = GetConVarFloat(Cvar_DispenserDet_DmgForce);
	g_cvarDetRadius = GetConVarInt(Cvar_DispenserDet_Radius);
	g_cvarDetMode = GetConVarInt(Cvar_DispenserDet_Mode);
}

public Action Command_DetToggle(int client, int args)
{
	if(!g_bIsEnabled || client < 1 || !IsClientInGame(client))
		return Plugin_Handled;

	if(TF2_GetPlayerClass(client) != TFClass_Engineer)
	{
		PrintToChat(client, "\x01[SM] You must be an Engineer to use this command.");
		return Plugin_Handled;
	}

	if(g_bDetEnabled[client])
	{
		g_bDetEnabled[client] = false;
		PrintHintText(client, "Detonator: [disabled]");
		//StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
	}
	else
	{
		g_bDetEnabled[client] = true;
		PrintHintText(client, "Detonator: [enabled]");
		//StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
	}

	return Plugin_Handled;
}

public Action Hook_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_bIsEnabled)
		return Plugin_Continue;

	int deathflags = GetEventInt(event, "death_flags");
	if(deathflags & 32) return Plugin_Continue;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(client < 1 || attacker < 1 || client == attacker)
		return Plugin_Continue;
	
	if(g_bDestroyCmdUsed[attacker])
	{
		//PrintToChatAll("DestroyCmd was used by attacker..");
		char weapon[64];
		GetEventString(event, "weapon_logclassname", weapon, sizeof(weapon));
		//PrintToChatAll("Weapon is: %s", weapon);
		if(strcmp(weapon[0], "env_explosion", false) == 0)
		{
			SetEventString(event, "weapon_logclassname", "dispenser");
			SetEventString(event, "weapon", "building_carried_destroyed");
			SetEventInt(event, "customkill", 0);
			
			PrintToChat(client, "\x01\x03%N \x01detonated you with his dispenser!", attacker);
		}
	}
	return Plugin_Continue;
}

public void OnEntityDestroyed(int entity)
{
	if (entity < 0 || entity > 2048) return;
	char className[32];
	GetEdictClassname(entity, className, sizeof(className));
	//PrintToChatAll("Entity is:  %s", className);
	if(StrEqual(className,"obj_dispenser"))
	{
		int iOwner = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
		//PrintToChatAll("iOwner = %N", iOwner);
		if(iOwner > 0)
		{
			if(g_bDestroyCmdUsed[iOwner])
			{
				float fObjPos[3];
				int dmg;
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fObjPos);
				
				if(g_cvarDetMode != 0)
				{
					int level = GetEntProp(entity, Prop_Send, "m_iUpgradeLevel");
					int metal = GetEntProp(entity, Prop_Send, "m_iAmmoMetal");
					//PrintToChatAll("m_iUpgradeLevel: %i", level);
					//PrintToChatAll("m_iAmmoMetal: %i", metal);
					
					if(g_cvarDetMode == 2) //dmg = RoundFloat(float(g_cvarDetDamage) + ((metal / 10) + (level * 20));
						dmg = RoundFloat(float(g_cvarDetDamage) + ((metal / 12) * level) + ((level * level) * 22));
						
					else
						dmg = g_cvarDetDamage * level;
				}
				else
					dmg = g_cvarDetDamage;
				
				//PrintToChatAll("Damage calculated is: %i", dmg);
				
				CreateExplosion(iOwner, fObjPos, dmg);
			}
		}
	}
}

public Action Command_Destroy(int client, char[] command, int args)
{
	if(!g_bIsEnabled)
	return Plugin_Continue;
	
	if(client < 1 || !IsClientInGame(client))
	return Plugin_Continue;
	
	//if(TF2_GetPlayerClass(client) != TFClass_Engineer)
	//return Plugin_Continue;
	
	char strCommand[64];
	GetCmdArg(1, strCommand, sizeof(strCommand));
	
	int objType = StringToInt(strCommand);
	if(objType != TF_OBJECT_DISPENSER)
	return Plugin_Continue;
	
	if(!g_bInfoMsgShown[client])
		CreateTimer(1.5, Timer_InfoMessage, client, TIMER_FLAG_NO_MAPCHANGE);
	
	if(g_bUseSDKhooks)
	{
		if(g_bDetEnabled[client])
			g_bDestroyCmdUsed[client] = true;
	}
	else
	{ 
		//PrintToChatAll("SDKhooks not used. FindEntityByClassname..");
		if(g_bDetEnabled[client])
			DetonateBuilding(client);	
	}

	return Plugin_Continue;
}

public void CreateExplosion(int client, float pos[3], int dmg)
{
	//PrintToChatAll("Dispenser detonated!");

	int ent = CreateEntityByName("env_explosion");

	if(IsValidEntity(ent))
	{
		int iTeam = GetEntProp(client, Prop_Data, "m_iTeamNum");
		
		DispatchKeyValueFloat(ent, "DamageForce", g_fcvarDmgForce);
		
		SetEntProp(ent, Prop_Data, "m_iMagnitude", dmg, 4);
		SetEntProp(ent, Prop_Data, "m_iRadiusOverride", g_cvarDetRadius, 4);
		SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client); //Set the owner of the explosion
		
		DispatchSpawn(ent);
		
		SetVariantInt(iTeam);
		AcceptEntityInput(ent, "TeamNum", -1, -1, 0);
		
		SetVariantInt(iTeam);
		AcceptEntityInput(ent, "SetTeam", -1, -1, 0);
		
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(ent, "Explode", -1, -1, 0);
		
		AttachParticleTimer("sentrydamage_4", 6.0, ent);
		
		g_bDestroyCmdUsed[client] = false;
		
		CreateTimer(1.0, Timer_KillExplosion, ent, TIMER_FLAG_NO_MAPCHANGE); //This shouldnt be needed but done for safety.
	}
}

public Action Timer_KillExplosion(Handle timer, any ent)
{
	if(IsValidEntity(ent))
	{
		char classname[256];
		GetEdictClassname(ent, classname, sizeof(classname));
		if(StrEqual(classname, "env_explosion", false))
		{
			//PrintToChatAll("KillExplosion: env_explosion killed");
			//RemoveEdict(ent)
			AcceptEntityInput(ent, "kill");
		}
	}
}

public Action Timer_InfoMessage(Handle timer, any client)
{
	if(!IsClientInGame(client))
	return;

	g_bInfoMsgShown[client] = true;
	PrintToChat(client, "\x01[SM] \x04Dispensers explode when detonated by owner! \x01Bind a key: say !det\x04/\x01!detonate \x04or \x01sm_det\x04/\x01sm_detonate \x04to toggle detonator On/Off.");
}

stock void DetonateBuilding(int client)
{
	int obj = -1;
	while ((obj = FindEntityByClassname(obj, "obj_dispenser")) != -1)
	{
		int owner = GetEntPropEnt(obj, Prop_Send, "m_hBuilder");
		if(owner == client)
		{
			float fObjPos[3];
			int dmg;
			//new Float:fClientPos[3];
			//GetClientAbsOrigin(client, fClientPos);
			GetEntPropVector(obj, Prop_Send, "m_vecOrigin", fObjPos);
			
			if(g_cvarDetMode != 0)
			{
				int level = GetEntProp(obj, Prop_Send, "m_iUpgradeLevel");
				int metal = GetEntProp(obj, Prop_Send, "m_iAmmoMetal");
				//PrintToChatAll("m_iUpgradeLevel: %i", level);
				//PrintToChatAll("m_iAmmoMetal: %i", metal);
				
				if(g_cvarDetMode == 2) //dmg = RoundFloat(float(g_cvarDetDamage) + ((metal / 10) + (level * 20));
					dmg = RoundFloat(float(g_cvarDetDamage) + ((metal / 12) * level) + ((level * level) * 22)); 
					
				else
					dmg = g_cvarDetDamage * level;
			}
			else
				dmg = g_cvarDetDamage;
			
			g_bDestroyCmdUsed[client] = true;
			CreateExplosion(client, fObjPos, dmg);
		}
	}
}

stock Handle AttachParticleTimer(const char[] type, float time, int entity)
{
	int particle = CreateEntityByName("info_particle_system");
	
	if(IsValidEntity(particle))
	{
		float pos[3];

		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		
		pos[0] += 0.0;
		pos[1] += 0.0;
		pos[2] += 0.0;
		
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", type);
		
		DispatchKeyValue(particle, "targetname", "dispenserparticle");
		
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");
		
		return CreateTimer(time, Timer_DeleteParticle, particle, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
		LogError("[DispenserDetParticle]: Could not create info_particle_system");
	
	return INVALID_HANDLE;
}

public Action Timer_DeleteParticle(Handle timer, any particle)
{
	if(IsValidEntity(particle))
	{
		char classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		
		if(StrEqual(classname, "info_particle_system", false))
			AcceptEntityInput(particle, "kill");
	}
}

public void Cvars_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar == Cvar_DispenserDet_Enabled)
	{
		if(StringToInt(newValue) == 0)
			g_bIsEnabled = false;
		else
			g_bIsEnabled = true;
	}
	else if(convar == Cvar_DispenserDet_Damage)
		g_cvarDetDamage = StringToInt(newValue);
	else if(convar == Cvar_DispenserDet_Radius)
		g_cvarDetRadius = StringToInt(newValue);
	else if(convar == Cvar_DispenserDet_DmgForce)
		g_fcvarDmgForce = StringToFloat(newValue);
	else if(convar == Cvar_DispenserDet_Mode)
		g_cvarDetMode = StringToInt(newValue);
}
