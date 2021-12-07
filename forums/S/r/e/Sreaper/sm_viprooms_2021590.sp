/*
	Version 1.2.0
	-=-=-=-=-=-=-
	- Plugin has been renamed to "viprooms" as it is no longer designed for only donators.
		- "Teleporting" now refers to entering a valid trigger_multiple entity to enter an area.
		- "Warping" now refers to issuing a !warp command to enter an area.
	- Removed "hold USE for x seconds" feature to activate a teleport after entering a trigger.
	- Teleports are no longer cancelled if the user exits the trigger_multiple entity.
	- Entering a trigger will now prompt the user with a menu, asking yes/no to teleport.
	- Configuration file has been renamed to sm_viprooms.ini
		- Areas can now be assigned a name, which will be displayed upon entering the trigger.
		- Areas can now be set to allow access to anyone, instead of requiring a specific flag.
		- Areas can now have a general override specified, in addition to specific flags.
	- Auth checks for areas now use CheckCommandAccess instead of hardcoded flag checks.
	- Removed hardcoded cvar that forced sm_donortele to move to a specific location.
	- Replaced sm_donortele command with sm_warp.
	- Command sm_warp now displays a list of available locations available to enter.
	- Cvar sm_viprooms_allow_warping added to globally disable the sm_warp command, if desired.
	- An additional entry has been added to sm_viprooms.ini, *_warping, to remove an entry from the sm_warp command.
	- Added a hardcoded #define to control the distance a player can move after entering a *_trigger before voiding the teleport confirm menu.

	Version 1.2.1
	-=-=-=-=-=-=-
	- Resolved issue where particles would remain attached if a client moved during a warp/teleport.
	
	Version 1.2.2
	-=-=-=-=-=-=-
	- Added g_fRefreshRate #define to control the rate at which warp/teleport hints/position checks occur.
	- Replaced "n_warping" with "n_activation", accepting values of 1/2/3. 1 = Physical only, 2 = Command only, 3 = Both.

	Version 1.2.3
	-=-=-=-=-=-=-
	- Added support for each location definition to have optional menu phrases that override the default translations.
	- Added support for an optional phrase to display whenever a client enters a teleportable location.
	- Added support for an optional phrase to be displayed when a client selects a location in sm_warp.
	- Added support for an optional phrase that displays after a user teleports or warps to a location.
	- Changed the hardcoded constants for maximum movement away from a teleport prompt and how frequently clients are queried to cvars.
	  - sm_viprooms_refresh_rate (def: 0.33), sm_viprooms_cancel_menu (def: 100)
	- Added support for an optional team to be required to access a teleport location or view it within sm_warp.
	- Added support for displaying a notification when a client teleports or warps.
	  - sm_viprooms_notify_action (-1 = disabled, 0 = everyone, otherwise it's the flag required to see notification)
	  - Translations: Phrase_Warp:Notify and Phrase_Teleport:Notify
	- Added support for allowing sm_warp #, where # is a valid entry from the cfg >= 0 and < total entries.
	  - Checks for being allowed to be warped to, checks users team. If valid, prompts user to warp.
	  - If user does not have access, defaults to listing available locations.
	- Modified translation Menu_Warp:Location to display [ID: #] after the name (to give the specific id for sm_warp)
	
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.2.3"

//Number of seconds menus to remain before closing. 0 = Infinite
#define WARP_MENU_DURATION 60
#define CONFIRM_MENU_DURATION 60

//Bit flags for activation codes.
#define ACTIVATE_ON_PHYSICAL 1
#define ACTIVATE_ON_COMMAND 2

new String:g_sParticle[64], String:g_sParticleRed[64], String:g_sParticleBlu[64], String:g_sNotify[8];
new Float:g_fCancelDistance, Float:g_fParticleOffset[3], Float:g_fRefreshRate, Float:g_fMaximumMovement;
new bool:g_bEnabled, bool:g_bLateLoad, bool:g_bMapCfgExists, bool:g_bCancelDamage, bool:g_bParticlesAllowed, bool:g_bParticle, bool:g_bWarpingAllowed;
new String:g_sGameName[10];

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hCancelDistance = INVALID_HANDLE;
new Handle:g_hCancelDamage = INVALID_HANDLE;
new Handle:g_hParticle = INVALID_HANDLE;
new Handle:g_hParticleRed = INVALID_HANDLE;
new Handle:g_hParticleBlu = INVALID_HANDLE;
new Handle:g_hParticleOffset = INVALID_HANDLE;
new Handle:g_hWarpingAllowed = INVALID_HANDLE;
new Handle:g_hMaximumMovement = INVALID_HANDLE;
new Handle:g_hRefreshRate = INVALID_HANDLE;
new Handle:g_hNotify = INVALID_HANDLE;

//Dynamic arrays to load per-map settings.
new Handle:g_hArray_Teleports = INVALID_HANDLE;
new Handle:g_hArray_Displays = INVALID_HANDLE;
new Handle:g_hArray_Positions = INVALID_HANDLE;
new Handle:g_hArray_Rotations = INVALID_HANDLE;
new Handle:g_hArray_Flags = INVALID_HANDLE;
new Handle:g_hArray_Overrides = INVALID_HANDLE;
new Handle:g_hArray_Delays = INVALID_HANDLE;
new Handle:g_hArray_Activations = INVALID_HANDLE;
new Handle:g_hArray_Teams = INVALID_HANDLE;
new Handle:g_hArray_PhraseSelect = INVALID_HANDLE;
new Handle:g_hArray_PhraseTitle = INVALID_HANDLE;
new Handle:g_hArray_PhraseConfirm = INVALID_HANDLE;
new Handle:g_hArray_PhraseCancel = INVALID_HANDLE;
new Handle:g_hArray_PhrasePrompt = INVALID_HANDLE;
new Handle:g_hArray_PhraseNotify = INVALID_HANDLE;

new g_iEntityIndex[2048] = { -1, ... };
new Float:g_fTriggerLocation[2048][3];

new g_iClientEntity[MAXPLAYERS + 1] = { -1, ... };
new g_iClientParticle[MAXPLAYERS + 1] = { -1, ... };
new Float:g_fClientEntering[MAXPLAYERS + 1];
new Float:g_fClientLocation[MAXPLAYERS + 1][3];

new Handle:g_hTimer_Teleporting[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
new Handle:g_hTimer_MonitorTeleport[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
new Handle:g_hTimer_Warping[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
new Handle:g_hTimer_MonitorWarp[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

public Plugin:myinfo =
{
	name = "Vip Areas", 
	author = "Twisted|Panda", 
	description = "Provides functionality for entering restricted areas.",
	version = PLUGIN_VERSION, 
	url = "http://forums.alliedmods.com/"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("sm_viprooms.phrases");
	CreateConVar("sm_viprooms_version", PLUGIN_VERSION, "Vip Areas: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_CHEAT|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	GetGameFolderName(g_sGameName, sizeof(g_sGameName));

	g_hEnabled = CreateConVar("sm_viprooms_enable", "1", "Enables/disables all features of the plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnSettingsChange);
	g_hCancelDistance = CreateConVar("sm_viprooms_cancel_distance", "0.0", "The maximum distance a player can travel from his/her original teleport location before cancelling the teleport. (-1 = Disabled, #.# = Distance)", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hCancelDistance, OnSettingsChange);
	g_hCancelDamage = CreateConVar("sm_viprooms_cancel_damage", "1", "If enabled, a teleport will be cancelled if the initiating client takes damage after initiating a teleport.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hCancelDamage, OnSettingsChange);
	if (!StrEqual(g_sGameName, "tf", false))
	{
		g_hParticle = CreateConVar("sm_viprooms_particle", "burningplayer_smoke", "The desired particle to use for the teleport effect.", FCVAR_NONE);
		HookConVarChange(g_hParticle, OnSettingsChange);
	}
	else
	{
		g_hParticleRed = CreateConVar("sm_viprooms_particle_red", "flaregun_energyfield_red", "The desired particle to use for the teleport effect on RED.", FCVAR_NONE);
		HookConVarChange(g_hParticleRed, OnSettingsChange);
		g_hParticleBlu = CreateConVar("sm_viprooms_particle_blu", "flaregun_energyfield_blue", "The desired particle to use for the teleport effect on BLU.", FCVAR_NONE);
		HookConVarChange(g_hParticleBlu, OnSettingsChange);
	}
	g_hParticleOffset = CreateConVar("sm_viprooms_particle_offset", "0 0 0", "The desired offset to use for the particle: note, it's attached to the head!", FCVAR_NONE);
	HookConVarChange(g_hParticleOffset, OnSettingsChange);
	g_hWarpingAllowed = CreateConVar("sm_viprooms_allow_warping", "1", "If enabled, the sm_warp command will be available for use.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hWarpingAllowed, OnSettingsChange);
	
	g_hRefreshRate = CreateConVar("sm_viprooms_refresh_rate", "0.33", "The frequency, in seconds, that players are monitored for teleporting / warping.", FCVAR_NONE, true, 0.1);
	HookConVarChange(g_hRefreshRate, OnSettingsChange);
	g_hMaximumMovement = CreateConVar("sm_viprooms_cancel_menu", "100", "The maximum distance a player can move from away from a teleport location prompt before it no longer works.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hMaximumMovement, OnSettingsChange);
	g_hNotify = CreateConVar("sm_viprooms_notify_action", "-1", "Determines who receives the notification that a player has teleported or warped. (-1 = Disabled, 0 = Everyone, otherwise the specified flag the user must possess, such as b)", FCVAR_NONE);
	HookConVarChange(g_hNotify, OnSettingsChange);

	g_bEnabled = GetConVarBool(g_hEnabled);
	g_fCancelDistance = GetConVarFloat(g_hCancelDistance);
	g_bCancelDamage = GetConVarBool(g_hCancelDamage);
	if (!StrEqual(g_sGameName, "tf", false))
	{
		GetConVarString(g_hParticle, g_sParticle, sizeof(g_sParticle));
		g_bParticle = !StrEqual(g_sParticle, "");
	}
	else
	{
		GetConVarString(g_hParticleRed, g_sParticleRed, sizeof(g_sParticleRed));
		GetConVarString(g_hParticleBlu, g_sParticleBlu, sizeof(g_sParticleBlu));
		g_bParticle = (!StrEqual(g_sParticleRed, "") || !StrEqual(g_sParticleBlu, ""));
	}
	decl String:sBuffer[3][8], String:sTemp[64];
	GetConVarString(g_hParticleOffset, sTemp, sizeof(sTemp));
	ExplodeString(sTemp, " ", sBuffer, 3, 8);
	for(new i = 0; i <= 2; i++)
		g_fParticleOffset[i] = StringToFloat(sBuffer[i]);
	g_bWarpingAllowed = GetConVarBool(g_hWarpingAllowed);
	g_fRefreshRate = GetConVarFloat(g_hRefreshRate);
	g_fMaximumMovement = GetConVarFloat(g_hMaximumMovement);
	GetConVarString(g_hNotify, g_sNotify, sizeof(g_sNotify));

	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("player_team", Event_OnPlayerTeam);
	
	RegConsoleCmd("sm_warp", Command_Warp); 
	g_hArray_Teleports = CreateArray(8);
	g_hArray_Displays = CreateArray(16);
	g_hArray_Positions = CreateArray(3);
	g_hArray_Rotations = CreateArray(3);
	g_hArray_Flags = CreateArray();
	g_hArray_Overrides = CreateArray(16);
	g_hArray_Delays = CreateArray();
	g_hArray_Activations = CreateArray();
	g_hArray_Teams = CreateArray();
	////////////////
	g_hArray_PhraseSelect = CreateArray(64);
	g_hArray_PhraseTitle = CreateArray(64);
	g_hArray_PhraseConfirm = CreateArray(16);
	g_hArray_PhraseCancel = CreateArray(16);
	g_hArray_PhrasePrompt = CreateArray(64);
	g_hArray_PhraseNotify = CreateArray(64);
	
	GetGameFolderName(sTemp, sizeof(sTemp));
	g_bParticlesAllowed = StrEqual(sTemp, "tf");
	
	Define_Configs();
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
		g_bEnabled = bool:StringToInt(newvalue);
	else if(cvar == g_hCancelDistance)
		g_fCancelDistance = StringToFloat(newvalue);
	else if(cvar == g_hCancelDamage)
		g_bCancelDamage = bool:StringToInt(newvalue);
	else if(cvar == g_hParticle)
	{
		strcopy(g_sParticle, sizeof(g_sParticle), newvalue);
		g_bParticle = !StrEqual(g_sParticle, "");
	}
	else if(cvar == g_hParticleRed)
	{
		strcopy(g_sParticleRed, sizeof(g_sParticleRed), newvalue);
		g_bParticle = (!StrEqual(g_sParticleRed, "") || !StrEqual(g_sParticleBlu, ""));
	}
	else if(cvar == g_hParticleBlu)
	{
		strcopy(g_sParticleBlu, sizeof(g_sParticleBlu), newvalue);
		g_bParticle = (!StrEqual(g_sParticleRed, "") || !StrEqual(g_sParticleBlu, ""));
	}
	else if(cvar == g_hParticleOffset)
	{
		decl String:sBuffer[3][8];
		ExplodeString(newvalue, " ", sBuffer, 3, 8);
		for(new i = 0; i <= 2; i++)
			g_fParticleOffset[i] = StringToFloat(sBuffer[i]);
	}
	else if(cvar == g_hWarpingAllowed)
		g_bWarpingAllowed = bool:StringToInt(newvalue);
	else if(cvar == g_hRefreshRate)
		g_fRefreshRate = StringToFloat(newvalue);
	else if(cvar == g_hMaximumMovement)
		g_fMaximumMovement = StringToFloat(newvalue);
	else if(cvar == g_hNotify)
		strcopy(g_sNotify, sizeof(g_sNotify), newvalue);
}

public OnClientPutInServer(client)
{
	if(g_bEnabled)
	{
		SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	}
}

public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		DeleteClientParticle(client);
		g_iClientEntity[client] = -1;

		if(g_hTimer_Teleporting[client] != INVALID_HANDLE && CloseHandle(g_hTimer_Teleporting[client]))
			g_hTimer_Teleporting[client] = INVALID_HANDLE;

		if(g_hTimer_MonitorTeleport[client] != INVALID_HANDLE && CloseHandle(g_hTimer_MonitorTeleport[client]))
			g_hTimer_MonitorTeleport[client] = INVALID_HANDLE;

		if(g_hTimer_Warping[client] != INVALID_HANDLE && CloseHandle(g_hTimer_Warping[client]))
			g_hTimer_Warping[client] = INVALID_HANDLE;

		if(g_hTimer_MonitorWarp[client] != INVALID_HANDLE && CloseHandle(g_hTimer_MonitorWarp[client]))
			g_hTimer_MonitorWarp[client] = INVALID_HANDLE;
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if(g_bEnabled && g_bMapCfgExists && entity >= 0)
	{
		if(StrEqual(classname, "trigger_multiple", false))
			CreateTimer(0.0, Timer_OnEntityCreated, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnEntityDestroyed(entity)
{
	if(g_bEnabled && entity >= 0)
	{
		g_iEntityIndex[entity] = -1;
	}
}

public Action:Timer_OnEntityCreated(Handle:timer, any:ref)
{
	new entity = EntRefToEntIndex(ref);
	if(entity != INVALID_ENT_REFERENCE)
	{
		decl iIndex, String:sBuffer[64];
		GetEntPropString(entity, Prop_Data, "m_iName", sBuffer, sizeof(sBuffer));
		if((iIndex = FindStringInArray(g_hArray_Teleports, sBuffer)) != -1)
		{
			SDKHook(entity, SDKHook_StartTouch, Hook_OnStartTouch);
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", g_fTriggerLocation[entity]);

			g_iEntityIndex[entity] = iIndex;
		}
	}
}

public OnConfigsExecuted()
{
	if(g_bEnabled)
	{
		Define_Configs();
		
		if(g_bLateLoad)
		{
			if(g_bMapCfgExists)
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i))
					{
						SDKHook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
					}
				}
				
				new iIndex;
				decl String:sClassname[32], String:sBuffer[32];
				for(new i = MaxClients + 1; i <= 2047; i++)
				{
					if(IsValidEntity(i) && IsValidEdict(i))
					{
						GetEdictClassname(i, sClassname, sizeof(sClassname));
						if(StrEqual(sClassname, "trigger_multiple", false))
						{
							GetEntPropString(i, Prop_Data, "m_iName", sBuffer, sizeof(sBuffer));
							if((iIndex = FindStringInArray(g_hArray_Teleports, sBuffer)) != -1)
							{
								SDKHook(i, SDKHook_StartTouch, Hook_OnStartTouch);
								GetEntPropVector(i, Prop_Send, "m_vecOrigin", g_fTriggerLocation[i]);
								
								g_iEntityIndex[i] = iIndex;
							}
						}
					}
				}
			}

			g_bLateLoad = false;
		}
	}
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;
			
		DeleteClientParticle(client);
		g_iClientEntity[client] = -1;

		if(g_hTimer_Teleporting[client] != INVALID_HANDLE && CloseHandle(g_hTimer_Teleporting[client]))
			g_hTimer_Teleporting[client] = INVALID_HANDLE;

		if(g_hTimer_MonitorTeleport[client] != INVALID_HANDLE && CloseHandle(g_hTimer_MonitorTeleport[client]))
			g_hTimer_MonitorTeleport[client] = INVALID_HANDLE;

		if(g_hTimer_Warping[client] != INVALID_HANDLE && CloseHandle(g_hTimer_Warping[client]))
			g_hTimer_Warping[client] = INVALID_HANDLE;

		if(g_hTimer_MonitorWarp[client] != INVALID_HANDLE && CloseHandle(g_hTimer_MonitorWarp[client]))
			g_hTimer_MonitorWarp[client] = INVALID_HANDLE;
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		DeleteClientParticle(client);
		g_iClientEntity[client] = -1;

		if(g_hTimer_Teleporting[client] != INVALID_HANDLE && CloseHandle(g_hTimer_Teleporting[client]))
			g_hTimer_Teleporting[client] = INVALID_HANDLE;

		if(g_hTimer_MonitorTeleport[client] != INVALID_HANDLE && CloseHandle(g_hTimer_MonitorTeleport[client]))
			g_hTimer_MonitorTeleport[client] = INVALID_HANDLE;

		if(g_hTimer_Warping[client] != INVALID_HANDLE && CloseHandle(g_hTimer_Warping[client]))
			g_hTimer_Warping[client] = INVALID_HANDLE;

		if(g_hTimer_MonitorWarp[client] != INVALID_HANDLE && CloseHandle(g_hTimer_MonitorWarp[client]))
			g_hTimer_MonitorWarp[client] = INVALID_HANDLE;
	}
	
	return Plugin_Continue;
}

public Action:Hook_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(g_bEnabled && g_bCancelDamage && victim > 0 && victim <= MaxClients)
	{
		if(g_hTimer_Teleporting[victim] != INVALID_HANDLE)
		{
			CloseHandle(g_hTimer_Teleporting[victim]);
			g_hTimer_Teleporting[victim] = INVALID_HANDLE;

			if(g_hTimer_MonitorTeleport[victim] != INVALID_HANDLE && CloseHandle(g_hTimer_MonitorTeleport[victim]))
				g_hTimer_MonitorTeleport[victim] = INVALID_HANDLE;

			decl String:sDisplay[64];
			GetArrayString(g_hArray_Displays, g_iEntityIndex[g_iClientEntity[victim]], sDisplay, sizeof(sDisplay));
			PrintToChat(victim, "%t%t", "Prefix_Chat", "Phrase_Teleport:Damage", sDisplay);
			PrintHintText(victim, "%t", "Phrase_Teleport:Failure");

			DeleteClientParticle(victim);
			g_iClientEntity[victim] = -1;
		}

		if(g_hTimer_Warping[victim] != INVALID_HANDLE)
		{
			CloseHandle(g_hTimer_Warping[victim]);
			g_hTimer_Warping[victim] = INVALID_HANDLE;

			if(g_hTimer_MonitorWarp[victim] != INVALID_HANDLE && CloseHandle(g_hTimer_MonitorWarp[victim]))
				g_hTimer_MonitorWarp[victim] = INVALID_HANDLE;

			decl String:sDisplay[64];
			GetArrayString(g_hArray_Displays, g_iEntityIndex[g_iClientEntity[victim]], sDisplay, sizeof(sDisplay));
			PrintToChat(victim, "%t%t", "Prefix_Chat", "Phrase_Warp:Damage", sDisplay);
			PrintHintText(victim, "%t", "Phrase_Warp:Failure");

			DeleteClientParticle(victim);
		}
	}
	
	return Plugin_Continue;
}

public Action:Hook_OnStartTouch(entity, client)
{
	if(g_bEnabled && client > 0 && client <= MaxClients && g_iEntityIndex[entity] != -1)
	{
		//Client already has a Teleport or Warp in progress.
		if(g_hTimer_Teleporting[client] != INVALID_HANDLE || g_hTimer_Warping[client] != INVALID_HANDLE)
			return Plugin_Continue;
	
		new iActivation = GetArrayCell(g_hArray_Activations, g_iEntityIndex[entity]);
		if(iActivation & ACTIVATE_ON_PHYSICAL)
		{
			//Ensure client has authorization to Teleport.
			decl String:sOverride[32];
			GetArrayString(g_hArray_Overrides, g_iEntityIndex[entity], sOverride, sizeof(sOverride));
			new iFlag = GetArrayCell(g_hArray_Flags, g_iEntityIndex[entity]);
			if(!iFlag || CheckCommandAccess(client, sOverride, iFlag))
			{
				new iTeam = GetArrayCell(g_hArray_Teams, g_iEntityIndex[entity]);
				if(!iTeam || GetClientTeam(client) == iTeam)
				{
					decl String:sDisplay[256];
					GetArrayString(g_hArray_PhrasePrompt, g_iEntityIndex[entity], sDisplay, sizeof(sDisplay));
					if(!StrEqual(sDisplay, ""))
						PrintToChat(client, "%t%s", "Prefix_Chat", sDisplay);

					Menu_ConfirmTeleport(client, entity);
				}
			}
		}
	}

	return Plugin_Continue;
}

Menu_ConfirmTeleport(client, entity)
{
	decl String:sTemp[256], String:sDisplay[256];
	new Handle:hMenu = CreateMenu(MenuHandler_ConfirmTeleport);

	GetArrayString(g_hArray_PhraseTitle, g_iEntityIndex[entity], sDisplay, sizeof(sDisplay));
	if(StrEqual(sDisplay, ""))
	{
		GetArrayString(g_hArray_Displays, g_iEntityIndex[entity], sTemp, sizeof(sTemp));
		Format(sDisplay, sizeof(sDisplay), "%T", "Menu_Teleport:Title", client, sTemp);
	}

	SetMenuTitle(hMenu, sDisplay);
	SetMenuExitButton(hMenu, false);
	SetMenuExitBackButton(hMenu, false);

	GetArrayString(g_hArray_PhraseConfirm, g_iEntityIndex[entity], sDisplay, sizeof(sDisplay));
	if(StrEqual(sDisplay, ""))
		Format(sDisplay, sizeof(sDisplay), "%T", "Menu_Teleport:Confirm", client);
	Format(sTemp, sizeof(sTemp), "1 %d", entity);
	AddMenuItem(hMenu, sTemp, sDisplay);

	GetArrayString(g_hArray_PhraseCancel, g_iEntityIndex[entity], sDisplay, sizeof(sDisplay));
	if(StrEqual(sDisplay, ""))
		Format(sDisplay, sizeof(sDisplay), "%T", "Menu_Teleport:Cancel", client);
	Format(sDisplay, sizeof(sDisplay), "0 %d", entity);
	AddMenuItem(hMenu, sDisplay, sTemp);

	DisplayMenu(hMenu, client, CONFIRM_MENU_DURATION);
}

public MenuHandler_ConfirmTeleport(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Select:
		{
			decl String:sOption[10], String:sBuffer[2][5];
			GetMenuItem(menu, param2, sOption, 10);
			ExplodeString(sOption, " ", sBuffer, 2, 5);
			
			if(StringToInt(sBuffer[0]))
			{
				new iEntity = StringToInt(sBuffer[1]);
				decl Float:fCurrent[3];
				GetClientAbsOrigin(param1, fCurrent);
				if(GetVectorDistance(g_fTriggerLocation[iEntity], fCurrent) > g_fMaximumMovement)
					return;	

				g_iClientEntity[param1] = iEntity;

				//Client has a warp in progress and does not need to teleport.
				if(g_hTimer_Warping[param1] != INVALID_HANDLE)
				{
					decl String:sDisplay[64];
					GetArrayString(g_hArray_Displays, g_iEntityIndex[iEntity], sDisplay, sizeof(sDisplay));

					PrintToChat(param1, "%t%t", "Prefix_Chat", "Phrase_Teleport:Warping", sDisplay);
				}
				else
				{
					CreateClientParticle(param1);
					g_fClientEntering[param1] = 0.0;
					if(g_fCancelDistance >= 0.0)
						GetClientAbsOrigin(param1, g_fClientLocation[param1]);

					new iTeam = GetArrayCell(g_hArray_Teams, g_iEntityIndex[iEntity]);
					if(iTeam && GetClientTeam(param1) != iTeam)
						return;
						
					new Float:fDelay = GetArrayCell(g_hArray_Delays, g_iEntityIndex[iEntity]);
					PrintHintText(param1, "%t", "Phrase_Teleport:Progress", g_fClientEntering[param1]);

					new Handle:hTeleportPack = INVALID_HANDLE;
					g_hTimer_Teleporting[param1] = CreateDataTimer(fDelay, Timer_Teleporting, hTeleportPack, TIMER_FLAG_NO_MAPCHANGE);
					WritePackCell(hTeleportPack, param1);
					WritePackCell(hTeleportPack, iEntity);
					
					new Handle:hMonitorPack = INVALID_HANDLE;
					g_hTimer_MonitorTeleport[param1] = CreateDataTimer(g_fRefreshRate, Timer_MonitorTeleport, hMonitorPack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
					WritePackCell(hMonitorPack, param1);
					WritePackCell(hMonitorPack, iEntity);
				}
			}
		}
	}
}

public Action:Timer_Teleporting(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new entity = ReadPackCell(pack);
	
	g_hTimer_Teleporting[client] = INVALID_HANDLE;
	if(g_hTimer_MonitorTeleport[client] != INVALID_HANDLE && CloseHandle(g_hTimer_MonitorTeleport[client]))
		g_hTimer_MonitorTeleport[client] = INVALID_HANDLE;

	decl Float:fPosition[3], Float:fRotation[3], String:sDisplay[256];
	GetArrayArray(g_hArray_Positions, g_iEntityIndex[entity], fPosition);
	GetArrayArray(g_hArray_Rotations, g_iEntityIndex[entity], fRotation);
	TeleportEntity(client, fPosition, fRotation, NULL_VECTOR);

	GetArrayString(g_hArray_PhraseNotify, g_iEntityIndex[entity], sDisplay, sizeof(sDisplay));
	if(!StrEqual(sDisplay, ""))
		PrintToChat(client, "%t%s", "Prefix_Chat", sDisplay);
	else
	{
		GetArrayString(g_hArray_Displays, g_iEntityIndex[entity], sDisplay, sizeof(sDisplay));
		PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Teleport:Enter", sDisplay);
		PrintHintText(client, "%t", "Phrase_Teleport:Success");
	}
	
	DeleteClientParticle(client);
	g_iClientEntity[client] = -1;
	
	if(!StrEqual(g_sNotify, "-1"))
	{
		if(StrEqual(g_sNotify, "0"))
			DisplayTeleportNotify(client, 0, sDisplay);
		else
			DisplayTeleportNotify(client, ReadFlagString(g_sNotify), sDisplay);
	}
	
	return Plugin_Continue;
}

public Action:Timer_MonitorTeleport(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new entity = ReadPackCell(pack);

	if(g_fCancelDistance >= 0.0)
	{
		decl Float:fCurrent[3];
		GetClientAbsOrigin(client, fCurrent);
		if(GetVectorDistance(g_fClientLocation[client], fCurrent) > g_fCancelDistance)
		{
			decl String:sDisplay[256];
			GetArrayString(g_hArray_Displays, g_iEntityIndex[entity], sDisplay, sizeof(sDisplay));
			PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Teleport:Movement", sDisplay);
			PrintHintText(client, "%t", "Phrase_Teleport:Failure");

			g_hTimer_MonitorTeleport[client] = INVALID_HANDLE;
			if(g_hTimer_Teleporting[client] != INVALID_HANDLE && CloseHandle(g_hTimer_Teleporting[client]))
				g_hTimer_Teleporting[client] = INVALID_HANDLE;
		
			g_iClientEntity[client] = -1;
			DeleteClientParticle(client);
			
			return Plugin_Stop;
		}
	}

	g_fClientEntering[client] += g_fRefreshRate;
	new Float:fTemp = (g_fClientEntering[client] / Float:GetArrayCell(g_hArray_Delays, g_iEntityIndex[entity])) * 100.0;
	PrintHintText(client, "%t", "Phrase_Teleport:Progress", fTemp);
	
	return Plugin_Continue;
}

public Action:Command_Warp(client, args)
{
	if(!g_bEnabled || !client || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) <= 1)
		return Plugin_Handled;
	else if(!g_bWarpingAllowed)
	{
		PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Warp:Disabled");
		return Plugin_Handled; 
	}
	else if(g_hTimer_Teleporting[client] != INVALID_HANDLE)
	{
		PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Warp:Teleporting");
		return Plugin_Handled; 
	}
	else if(g_hTimer_Warping[client] != INVALID_HANDLE)
	{
		PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Warp:Warping");
		return Plugin_Handled; 
	}

	new iActivation, iTeam, iSize = GetArraySize(g_hArray_Teleports);
	if(iSize)
	{
		decl String:sShortcut[64];
		GetCmdArg(1, sShortcut, sizeof(sShortcut));
		if(!StrEqual(sShortcut, ""))
		{
			new iArea = StringToInt(sShortcut);
			if(iArea >= 0 && iArea < iSize)
			{
				iActivation = GetArrayCell(g_hArray_Activations, iArea);
				if(iActivation & ACTIVATE_ON_COMMAND)
				{
					iTeam = GetArrayCell(g_hArray_Teams, iArea);
					if(!iTeam || GetClientTeam(client) == iTeam)
					{
						decl String:sTemp[256], String:sDisplay[256];
						GetArrayString(g_hArray_PhraseSelect, iArea, sDisplay, sizeof(sDisplay));
						if(!StrEqual(sDisplay, ""))
							PrintToChat(client, "%t%s", "Prefix_Chat", sDisplay);
						
						new Handle:hMenu = CreateMenu(MenuHandler_ConfirmWarp);

						GetArrayString(g_hArray_PhraseTitle, iArea, sDisplay, sizeof(sDisplay));
						if(StrEqual(sDisplay, ""))
						{
							GetArrayString(g_hArray_Displays, iArea, sTemp, sizeof(sTemp));
							Format(sDisplay, sizeof(sDisplay), "%T", "Menu_Warp:Title", client, sTemp);
						}

						SetMenuTitle(hMenu, sDisplay);
						SetMenuExitButton(hMenu, true);
						SetMenuExitBackButton(hMenu, false);

						GetArrayString(g_hArray_PhraseConfirm, iArea, sDisplay, sizeof(sDisplay));
						if(StrEqual(sDisplay, ""))
							Format(sDisplay, sizeof(sDisplay), "%T", "Menu_Warp:Confirm", client);
						Format(sTemp, sizeof(sTemp), "1 %d", iArea);
						AddMenuItem(hMenu, sTemp, sDisplay);

						GetArrayString(g_hArray_PhraseCancel, iArea, sDisplay, sizeof(sDisplay));
						if(StrEqual(sDisplay, ""))
							Format(sDisplay, sizeof(sDisplay), "%T", "Menu_Warp:Cancel", client);
						Format(sTemp, sizeof(sTemp), "0 %d", iArea);
						AddMenuItem(hMenu, sTemp, sDisplay);

						DisplayMenu(hMenu, client, CONFIRM_MENU_DURATION);
						return Plugin_Handled; 
		
					}
				}
			}
		}
	
		decl String:sOverride[32];
		new iTotal, iAllowed[iSize + 1];
		for(new i = 0; i < iSize; i++)
		{
			iActivation = GetArrayCell(g_hArray_Activations, i);
			if(iActivation & ACTIVATE_ON_COMMAND)
			{
				iTeam = GetArrayCell(g_hArray_Teams, i);
				if(!iTeam || GetClientTeam(client) == iTeam)
				{
					GetArrayString(g_hArray_Overrides, i, sOverride, sizeof(sOverride));
					new iFlag = GetArrayCell(g_hArray_Flags, i);
					if(!iFlag || CheckCommandAccess(client, sOverride, iFlag))
						iAllowed[iTotal++] = i;
				}
			}
		}
		
		if(iTotal)
		{
			decl String:sTemp[192], String:sDisplay[64];
			new Handle:hMenu = CreateMenu(MenuHandler_ListWarps);

			Format(sTemp, sizeof(sTemp), "%T", "Menu_Warp:List", client);
			SetMenuTitle(hMenu, sTemp);
			SetMenuExitButton(hMenu, true);
			SetMenuExitBackButton(hMenu, false);
			
			for(new i = 0; i < iTotal; i++)
			{					
				GetArrayString(g_hArray_Displays, iAllowed[i], sDisplay, sizeof(sDisplay));

				Format(sTemp, sizeof(sTemp), "%T", "Menu_Warp:Location", client, sDisplay, i);
				Format(sDisplay, sizeof(sDisplay), "%d", iAllowed[i]);
				AddMenuItem(hMenu, sDisplay, sTemp);
			}

			DisplayMenu(hMenu, client, WARP_MENU_DURATION);
		}
		else
			PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Warp:Unavailable");
	}
	else
		PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Warp:Unavailable");

	return Plugin_Handled; 
}

public MenuHandler_ListWarps(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Select:
		{
			decl String:sIndex[8], String:sTemp[256], String:sDisplay[256];
			GetMenuItem(menu, param2, sIndex, 8);
			new iIndex = StringToInt(sIndex);

			GetArrayString(g_hArray_PhraseSelect, iIndex, sDisplay, sizeof(sDisplay));
			if(!StrEqual(sDisplay, ""))
				PrintToChat(param1, "%t%s", "Prefix_Chat", sDisplay);
			
			new Handle:hMenu = CreateMenu(MenuHandler_ConfirmWarp);

			GetArrayString(g_hArray_PhraseTitle, iIndex, sDisplay, sizeof(sDisplay));
			if(StrEqual(sDisplay, ""))
			{
				GetArrayString(g_hArray_Displays, iIndex, sTemp, sizeof(sTemp));
				Format(sDisplay, sizeof(sDisplay), "%T", "Menu_Warp:Title", param1, sTemp);
			}

			SetMenuTitle(hMenu, sDisplay);
			SetMenuExitButton(hMenu, true);
			SetMenuExitBackButton(hMenu, false);

			GetArrayString(g_hArray_PhraseConfirm, iIndex, sDisplay, sizeof(sDisplay));
			if(StrEqual(sDisplay, ""))
				Format(sDisplay, sizeof(sDisplay), "%T", "Menu_Warp:Confirm", param1);
			Format(sTemp, sizeof(sTemp), "1 %d", iIndex);
			AddMenuItem(hMenu, sTemp, sDisplay);

			GetArrayString(g_hArray_PhraseCancel, iIndex, sDisplay, sizeof(sDisplay));
			if(StrEqual(sDisplay, ""))
				Format(sDisplay, sizeof(sDisplay), "%T", "Menu_Warp:Cancel", param1);
			Format(sTemp, sizeof(sTemp), "0 %d", iIndex);
			AddMenuItem(hMenu, sTemp, sDisplay);

			DisplayMenu(hMenu, param1, CONFIRM_MENU_DURATION);
		}
	}
}

public MenuHandler_ConfirmWarp(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Select:
		{
			decl String:sOption[10], String:sBuffer[2][5];
			GetMenuItem(menu, param2, sOption, 10);
			ExplodeString(sOption, " ", sBuffer, 2, 5);
			
			if(StringToInt(sBuffer[0]))
			{	
				new iIndex = StringToInt(sBuffer[1]);
				
				CreateClientParticle(param1);
				g_fClientEntering[param1] = 0.0;
				if(g_fCancelDistance >= 0.0)
					GetClientAbsOrigin(param1, g_fClientLocation[param1]);

				new iTeam = GetArrayCell(g_hArray_Teams, iIndex);
				if(iTeam && GetClientTeam(param1) != iTeam)
					return;
					
				new Float:fDelay = GetArrayCell(g_hArray_Delays, iIndex);
				PrintHintText(param1, "%t", "Phrase_Warp:Progress", g_fClientEntering[param1]);

				new Handle:g_hWarpPack = INVALID_HANDLE;
				g_hTimer_Warping[param1] = CreateDataTimer(fDelay, Timer_Warping, g_hWarpPack, TIMER_FLAG_NO_MAPCHANGE);
				WritePackCell(g_hWarpPack, param1);
				WritePackCell(g_hWarpPack, iIndex);
				
				new Handle:hMonitorWarpPack = INVALID_HANDLE;
				g_hTimer_MonitorWarp[param1] = CreateDataTimer(g_fRefreshRate, Timer_MonitorWarp, hMonitorWarpPack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				WritePackCell(hMonitorWarpPack, param1);
				WritePackCell(hMonitorWarpPack, iIndex);
			}
		}
	}
}

public Action:Timer_Warping(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new index = ReadPackCell(pack);
	
	g_hTimer_Warping[client] = INVALID_HANDLE;
	if(g_hTimer_MonitorWarp[client] != INVALID_HANDLE && CloseHandle(g_hTimer_MonitorWarp[client]))
		g_hTimer_MonitorWarp[client] = INVALID_HANDLE;

	decl Float:fPosition[3], Float:fRotation[3], String:sDisplay[256];
	GetArrayArray(g_hArray_Positions, index, fPosition);
	GetArrayArray(g_hArray_Rotations, index, fRotation);
	if(fRotation[0] || fRotation[1] || fRotation[2])
		TeleportEntity(client, fPosition, fRotation, NULL_VECTOR);
	else
		TeleportEntity(client, fPosition, NULL_VECTOR, NULL_VECTOR);

	GetArrayString(g_hArray_PhraseNotify, index, sDisplay, sizeof(sDisplay));
	if(!StrEqual(sDisplay, ""))
		PrintToChat(client, "%t%s", "Prefix_Chat", sDisplay);
	else
	{
		GetArrayString(g_hArray_Displays, index, sDisplay, sizeof(sDisplay));
		PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Warp:Enter", sDisplay);
		PrintHintText(client, "%t", "Phrase_Warp:Success");
	}
	
	DeleteClientParticle(client);

	if(!StrEqual(g_sNotify, "-1"))
	{
		if(StrEqual(g_sNotify, "0"))
			DisplayWarpNotify(client, 0, sDisplay);
		else
			DisplayWarpNotify(client, ReadFlagString(g_sNotify), sDisplay);
	}
	
	return Plugin_Continue;
}

public Action:Timer_MonitorWarp(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new index = ReadPackCell(pack);

	if(g_fCancelDistance >= 0.0)
	{
		decl Float:fCurrent[3];
		GetClientAbsOrigin(client, fCurrent);
		if(GetVectorDistance(g_fClientLocation[client], fCurrent) > g_fCancelDistance)
		{
			decl String:sDisplay[64];
			GetArrayString(g_hArray_Displays, index, sDisplay, sizeof(sDisplay));
			PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Warp:Movement", sDisplay);
			PrintHintText(client, "%t", "Phrase_Warp:Failure");

			g_hTimer_MonitorWarp[client] = INVALID_HANDLE;
			if(g_hTimer_Warping[client] != INVALID_HANDLE && CloseHandle(g_hTimer_Warping[client]))
				g_hTimer_Warping[client] = INVALID_HANDLE;

			DeleteClientParticle(client);
			return Plugin_Stop;
		}
	}

	g_fClientEntering[client] += g_fRefreshRate;
	new Float:fTemp = (g_fClientEntering[client] / Float:GetArrayCell(g_hArray_Delays, index)) * 100.0;
	PrintHintText(client, "%t", "Phrase_Warp:Progress", fTemp);
	
	return Plugin_Continue;
}

Define_Configs()
{
	ClearArray(g_hArray_Teleports);
	ClearArray(g_hArray_Displays);
	ClearArray(g_hArray_Positions);
	ClearArray(g_hArray_Rotations);
	ClearArray(g_hArray_Flags);
	ClearArray(g_hArray_Overrides);
	ClearArray(g_hArray_Delays);
	ClearArray(g_hArray_Activations);
	ClearArray(g_hArray_Teams);
	//////////////
	ClearArray(g_hArray_PhraseSelect);
	ClearArray(g_hArray_PhraseTitle);
	ClearArray(g_hArray_PhraseConfirm);
	ClearArray(g_hArray_PhraseCancel);
	ClearArray(g_hArray_PhrasePrompt);
	ClearArray(g_hArray_PhraseNotify);
	
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/sm_viprooms.ini");

	new Handle:hKeyValue = CreateKeyValues("viprooms");
	if(FileToKeyValues(hKeyValue, sPath))
	{
		decl Float:fBuffer[3], String:sBuffer[256], String:sCurrent[256], String:sExplode[3][8];
		GetCurrentMap(sCurrent, sizeof(sCurrent));
		KvGotoFirstSubKey(hKeyValue);
		do
		{
			KvGetSectionName(hKeyValue, sBuffer, sizeof(sBuffer));
			if((g_bMapCfgExists = StrEqual(sBuffer, sCurrent, false)))
			{
				new bExists = true, iIndex = 1;
				while(bExists)
				{
					Format(sCurrent, sizeof(sCurrent), "%d_activate", iIndex);
					KvGetString(hKeyValue, sCurrent, sBuffer, sizeof(sBuffer));
					if((bExists = !StrEqual(sBuffer, "")))
					{
						PushArrayCell(g_hArray_Activations, StringToInt(sBuffer));

						Format(sCurrent, sizeof(sCurrent), "%d_trigger", iIndex);
						KvGetString(hKeyValue, sCurrent, sBuffer, sizeof(sBuffer), "");
						PushArrayString(g_hArray_Teleports, sBuffer);

						Format(sCurrent, sizeof(sCurrent), "%d_display", iIndex);
						KvGetString(hKeyValue, sCurrent, sBuffer, sizeof(sBuffer), "");
						PushArrayString(g_hArray_Displays, sBuffer);
						
						Format(sCurrent, sizeof(sCurrent), "%d_position", iIndex);
						KvGetString(hKeyValue, sCurrent, sBuffer, sizeof(sBuffer), "0.0 0.0 0.0");
						ExplodeString(sBuffer, " ", sExplode, 3, 8);
						for(new i = 0; i <= 2; i++)
							fBuffer[i] = StringToFloat(sExplode[i]);
						PushArrayArray(g_hArray_Positions, fBuffer);
						
						Format(sCurrent, sizeof(sCurrent), "%d_rotation", iIndex);
						KvGetString(hKeyValue, sCurrent, sBuffer, sizeof(sBuffer), "0.0 0.0 0.0");
						ExplodeString(sBuffer, " ", sExplode, 3, 8);
						for(new i = 0; i <= 2; i++)
							fBuffer[i] = StringToFloat(sExplode[i]);
						PushArrayArray(g_hArray_Rotations, fBuffer);
						
						Format(sCurrent, sizeof(sCurrent), "%d_delay", iIndex);
						KvGetString(hKeyValue, sCurrent, sBuffer, sizeof(sBuffer), "0.0");
						PushArrayCell(g_hArray_Delays, StringToFloat(sBuffer));
						
						Format(sCurrent, sizeof(sCurrent), "%d_flag", iIndex);
						KvGetString(hKeyValue, sCurrent, sBuffer, sizeof(sBuffer), "");
						PushArrayCell(g_hArray_Flags, ReadFlagString(sBuffer));
						
						Format(sCurrent, sizeof(sCurrent), "%d_override", iIndex);
						KvGetString(hKeyValue, sCurrent, sBuffer, sizeof(sBuffer), "SM_VIPROOMS_OVERRIDE");
						PushArrayString(g_hArray_Overrides, sBuffer);
						
						Format(sCurrent, sizeof(sCurrent), "%d_team", iIndex);
						KvGetString(hKeyValue, sCurrent, sBuffer, sizeof(sBuffer), "0");
						PushArrayCell(g_hArray_Teams, StringToInt(sBuffer));
						
						///////////////
						
						Format(sCurrent, sizeof(sCurrent), "%d_select", iIndex);
						KvGetString(hKeyValue, sCurrent, sBuffer, sizeof(sBuffer), "");
						PushArrayString(g_hArray_PhraseSelect, sBuffer);
						
						Format(sCurrent, sizeof(sCurrent), "%d_title", iIndex);
						KvGetString(hKeyValue, sCurrent, sBuffer, sizeof(sBuffer), "");
						PushArrayString(g_hArray_PhraseTitle, sBuffer);
						
						Format(sCurrent, sizeof(sCurrent), "%d_confirm", iIndex);
						KvGetString(hKeyValue, sCurrent, sBuffer, sizeof(sBuffer), "");
						PushArrayString(g_hArray_PhraseConfirm, sBuffer);
						
						Format(sCurrent, sizeof(sCurrent), "%d_cancel", iIndex);
						KvGetString(hKeyValue, sCurrent, sBuffer, sizeof(sBuffer), "");
						PushArrayString(g_hArray_PhraseCancel, sBuffer);
						
						Format(sCurrent, sizeof(sCurrent), "%d_prompt", iIndex);
						KvGetString(hKeyValue, sCurrent, sBuffer, sizeof(sBuffer), "");
						PushArrayString(g_hArray_PhrasePrompt, sBuffer);
						
						Format(sCurrent, sizeof(sCurrent), "%d_notify", iIndex);
						KvGetString(hKeyValue, sCurrent, sBuffer, sizeof(sBuffer), "");
						PushArrayString(g_hArray_PhraseNotify, sBuffer);
					}

					iIndex++;
				}

				break;
			}
		}
		while (KvGotoNextKey(hKeyValue));

		CloseHandle(hKeyValue);
	}
}

CreateClientParticle(client)
{
	if(g_bParticle && g_bParticlesAllowed)
	{
		new String:particle[64];
		if (!StrEqual(g_sGameName, "tf", false))
			Format(particle, sizeof(particle), g_sParticle);
		else
			Format(particle, sizeof(particle), GetClientTeam(client) == 2 ? g_sParticleRed : g_sParticleBlu);
		
		if (!StrEqual(particle, ""))
		{
			new iEntity = CreateEntityByName("info_particle_system");
			if (IsValidEdict(iEntity) && IsPlayerAlive(client))
			{
				decl Float:fOrigin[3];
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", fOrigin);
				for(new i = 0; i <= 2; i++)
					fOrigin[i] += g_fParticleOffset[i];
				TeleportEntity(iEntity, fOrigin, NULL_VECTOR, NULL_VECTOR);
				DispatchKeyValue(iEntity, "effect_name", particle);
				SetVariantString("!activator");
				AcceptEntityInput(iEntity, "SetParent", client, iEntity, 0);
				DispatchSpawn(iEntity);
				ActivateEntity(iEntity);
				AcceptEntityInput(iEntity, "Start");

				g_iClientParticle[client] = iEntity;
			}
		}
	}
}

DisplayTeleportNotify(client, flags, const String:display[])
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(i != client && IsClientInGame(i) && (!flags || GetUserFlagBits(i) & flags))
		{
			PrintToChat(i, "%T", "Phrase_Teleport:Notify", client, display);
		}
	}
}

DisplayWarpNotify(client, flags, const String:display[])
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(i != client && IsClientInGame(i) && (!flags || GetUserFlagBits(i) & flags))
		{
			PrintToChat(i, "%T", "Phrase_Warp:Notify", client, display);
		}
	}
}

DeleteClientParticle(client)
{
	if(g_iClientParticle[client] != -1)
	{
		if(IsValidEntity(g_iClientParticle[client]))
		{
			AcceptEntityInput(g_iClientParticle[client], "Deactivate");
			AcceptEntityInput(g_iClientParticle[client], "Kill");
		}
			
		g_iClientParticle[client] = -1;
	}
}