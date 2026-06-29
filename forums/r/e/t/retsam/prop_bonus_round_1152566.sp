/*
* Prop Bonus Round (TF2) 
* Author(s): retsam
* File: prop_bonus_round.sp
* Description: Turns the losing team into random props during bonus round!
*
* Credits to: strontiumdog for the idea based off his DODS version.
* Credits to: Antithasys for SMC Parser/SM auto-cmds code and much help!
* 
* 0.7 - Removed Logactivity cvar, no longer needed I dont think. Removed the precache models console spam. 
* 0.6 - Fix for non-prop errors. New Addcond code to deal with demoman glowing eyes. Flagged equip timer with timer_flag_no_mapchange. 
* 0.5 - Changed deletion code again(Crash issues fixed?). Fixed couple potential issues related to plugin being disabled.
* 0.4.1 - Changed the prop deletion code a bit. 
* 0.4 - Removed sm_forcethird cvar, forgot losing team in TF2 is already put into thirdperson. Changed IsValidEdict to IsValidEntity(possible crash issue?). Added couple more models.
* 0.3 - Added admin command for turning players into props. Moved some stuff around.
* 0.2	- Added admin only cvar and flag.  Added a log debug cvar. Put in a couple checks related to model stuff. 
* 0.1	- Initial release. 
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <tf2_stocks>

#define PLUGIN_VERSION "0.7"

#define INVIS					{255,255,255,0}
#define NORMAL					{255,255,255,255}

new Handle:hAdminMenu = INVALID_HANDLE;
new Handle:Cvar_AdminFlag = INVALID_HANDLE;
new Handle:Cvar_AdminOnly = INVALID_HANDLE;
new Handle:Cvar_ThirdTriggers = INVALID_HANDLE;
new Handle:Cvar_ThirdPerson = INVALID_HANDLE;
new Handle:Cvar_Enabled = INVALID_HANDLE;
new Handle:Cvar_HitRemoveProp = INVALID_HANDLE;
new Handle:g_hModelNames = INVALID_HANDLE;
new Handle:g_hModelPaths = INVALID_HANDLE;

new g_adminonlyCvar;
new g_thirdpersonCvar;
new g_hitremovePropCvar;
new g_iArraySize;
new winnerTeam;

new g_InThirdperson[MAXPLAYERS+1] = { 0, ... };
new g_PropModel[MAXPLAYERS+1] = { -1, ... };
new g_iPlayerModelIndex[MAXPLAYERS+1] = { -1, ... };
new g_iFov[MAXPLAYERS+1] = { -1, ... };
new g_iDefFov[MAXPLAYERS+1] = { -1, ... };

new bool:bIsPlayerAdmin[MAXPLAYERS + 1] = {false, ...};
new bool:IsEnabled = true;
new bool:BonusRound = false;

new String:g_sConfigPath[PLATFORM_MAX_PATH];
new String:g_sCharAdminFlag[32];

public Plugin:myinfo = 
{
	name = "Prop Bonus Round",
	author = "retsam",
	description = "Turns the losing team into random props during bonus round!",
	version = PLUGIN_VERSION,
	url = "www.multiclangaming.net"
}

public OnPluginStart()
{
	CheckGame();

	CreateConVar("sm_propbonus_version", PLUGIN_VERSION, "Version of Prop Bonus Round", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Cvar_Enabled = CreateConVar("sm_propbonus_enabled", "1", "Enable/Disable prop bounus round plugin.");
	Cvar_AdminOnly = CreateConVar("sm_propbonus_adminonly", "0", "Enable plugin for admins only? (1/0 = yes/no)");
	Cvar_AdminFlag = CreateConVar("sm_propbonus_flag", "b", "Admin flag to use if adminonly is enabled (only one).  Must be a in char format.");
	Cvar_ThirdPerson = CreateConVar("sm_propbonus_allowtriggers", "1", "Allow prop players thirdperson triggers?(1/0 = yes/no)");
	Cvar_HitRemoveProp = CreateConVar("sm_propbonus_removeproponhit", "0", "Remove player prop once they take damage?(1/0 = yes/no)");
	Cvar_ThirdTriggers = CreateConVar("sm_propbonus_triggers", "thirdperson,third", "SM command triggers for thirdperson - Separated by commas. Each will have the !third, /third, sm_third associated with it.");

	RegAdminCmd("sm_propplayer", Command_Propplayer, ADMFLAG_ROOT, "sm_propplayer <#userid|name>");

	HookEvent("teamplay_round_start", Hook_RoundStart, EventHookMode_Post);
	HookEvent("teamplay_round_win", Hook_RoundWin, EventHookMode_Post);
	HookEvent("player_death", Hook_Playerdeath, EventHookMode_Post);
	HookEvent("player_hurt", Hook_PlayerHurt, EventHookMode_Post);
	
	HookConVarChange(Cvar_Enabled, Cvars_Changed);
	HookConVarChange(Cvar_ThirdPerson, Cvars_Changed);
	HookConVarChange(Cvar_HitRemoveProp, Cvars_Changed);
	HookConVarChange(Cvar_AdminOnly, Cvars_Changed);
	
	CreateThirdpersonCommands();
	
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	
	AutoExecConfig(true, "plugin.propbonusround");
}

public OnClientPostAdminCheck(client)
{
	if(IsValidAdmin(client, g_sCharAdminFlag))
	{
		bIsPlayerAdmin[client] = true;
	}
	else
	{
		bIsPlayerAdmin[client] = false;
	}

	g_InThirdperson[client] = 0;
	g_PropModel[client] = -1;
	g_iPlayerModelIndex[client] = -1;
	g_iFov[client] = -1;
	g_iDefFov[client] = -1;
}

public OnConfigsExecuted()
{
	BonusRound = false;

	IsEnabled = GetConVarBool(Cvar_Enabled);
	GetConVarString(Cvar_AdminFlag, g_sCharAdminFlag, sizeof(g_sCharAdminFlag));

	g_thirdpersonCvar = GetConVarInt(Cvar_ThirdPerson);
	g_hitremovePropCvar = GetConVarInt(Cvar_HitRemoveProp);
	g_adminonlyCvar = GetConVarInt(Cvar_AdminOnly);
}

public OnClientDisconnect(client)
{
	g_InThirdperson[client] = 0;
	g_iPlayerModelIndex[client] = -1;
	g_PropModel[client] = -1;
}

public OnMapStart()
{
	//Process the models data file and make sure it exists. If not, create default.
	ProcessConfigFile();

	//Precache all models and names.
	decl String:sPath[100];
	for(new i = 0; i < GetArraySize(g_hModelNames); i++)
	{
		GetArrayString(g_hModelPaths, i, sPath, sizeof(sPath));
		//GetArrayString(g_hModelNames, i, sName, sizeof(sName));
		PrecacheModel(sPath, true);
		//PrintToServer("Precached: %s - %s", sName, sPath);
	} 
}

public Action:Command_Propplayer(client, args)
{
	decl String:target[65];
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_propplayer <#userid|name>");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, target, sizeof(target));
	
	if((target_count = ProcessTargetString(
					target,
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
	
	for(new i = 0; i < target_count; i++)
	{
		if(IsClientInGame(target_list[i]) && IsPlayerAlive(target_list[i]))
		{
			PerformPropPlayer(client, target_list[i]);
		}
	}
	return Plugin_Handled;
}

public Action:Hook_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!IsEnabled || !BonusRound || !g_hitremovePropCvar)
	return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(client <= 0 || attacker <= 0 || client == attacker)
	return Plugin_Continue;

	if(g_PropModel[client] != -1)
	{
		ClearPlayer(client);

		if(g_InThirdperson[client] == 1)
		{
			SwitchView(client);
		}
	}

	return Plugin_Continue;
}

public Action:Hook_Playerdeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!IsEnabled)
	return Plugin_Continue;

	new death_ringer = GetEventInt(event, "death_flags");
	if(death_ringer & 32) return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client <= 0 || !IsClientInGame(client))
	return Plugin_Continue;

	if(g_PropModel[client] != -1)
	{
		ClearPlayer(client);
		
		if(g_InThirdperson[client] == 1)
		{
			g_InThirdperson[client] = 0;
			
			if(g_iFov[client] != -1)
			{
				SetEntProp(client, Prop_Send, "m_iFOV", g_iFov[client]);
				SetEntProp(client, Prop_Send, "m_iDefaultFOV", g_iDefFov[client]);
				
				g_iFov[client] = -1;
				g_iDefFov[client] = -1;
			}
		}
	}

	return Plugin_Continue;
}

public Action:Hook_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!IsEnabled)
	return Plugin_Continue;

	for(new x = 1; x <= MaxClients; x++)
	{
		if(!IsClientConnected(x) || !IsClientInGame(x))
		{
			continue;
		}
		
		//If player is not a prop, skip.
		if(g_PropModel[x] < 0)
		{
			continue;
		}

		ClearPlayer(x);
		
		if(g_InThirdperson[x] == 1)
		{
			SwitchView(x);
		}
	}
	
	BonusRound = false;
	
	return Plugin_Continue;
}

public Action:Hook_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!IsEnabled)
	return Plugin_Continue;

	BonusRound = true;

	winnerTeam = GetEventInt(event, "team");
	
	//Entity limit check before attaching props
	if(!IsEntLimitReached())
	{
		CreateTimer(0.1, Timer_EquipProps, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Continue;
}

public Action:Timer_EquipProps(Handle:timer)
{
	for (new x = 1; x <= MaxClients; x++)
	{
		if(!IsClientInGame(x) || !IsPlayerAlive(x))
		{
			continue;
		}
		
		if(GetClientTeam(x) == winnerTeam)
		{
			continue;
		}
		
		//If player is already a prop, skip id.
		if(g_PropModel[x] != -1)
		{
			//PrintToChatAll("Client %i already is a prop, skipped", x);
			continue;
		}
		
		//If admin only cvar is enabled and not admin, skip id.
		if((g_adminonlyCvar && !bIsPlayerAdmin[x]))
		{
			//PrintToChatAll("Client %i doesnt have flag, skipped", x);
			continue;
		}
		
		CreatePropPlayer(x);
	}
}

public CreatePropPlayer(client)
{
	g_iPlayerModelIndex[client] = GetRandomInt(0, g_iArraySize);
	new String:sPath[PLATFORM_MAX_PATH], String:sName[128];
	GetArrayString(g_hModelNames, g_iPlayerModelIndex[client], sName, sizeof(sName));
	GetArrayString(g_hModelPaths, g_iPlayerModelIndex[client], sPath, sizeof(sPath));
	
	//Safety check to make sure they dont have model attached already.
	//DeleteProps(client);
	
	g_PropModel[client] = CreateEntityByName("prop_dynamic_override");
	if(g_PropModel[client] == -1)
	{
		ReplyToCommand(client, "Failed to create entity!");
		LogMessage("[PB] %i Failed to create entity!", client);
		return;
	}

	decl String:sPlayername[64];
	Format(sPlayername, sizeof(sPlayername), "target%i", client);
	DispatchKeyValue(client, "targetname", sPlayername);
	
	if(IsValidEntity(g_PropModel[client]))
	{
		DispatchKeyValue(g_PropModel[client],"model", sPath);
		
		DispatchKeyValue(g_PropModel[client], "disableshadows", "1");
		
		DispatchKeyValue(g_PropModel[client], "solid", "0");
		
		SetEntityMoveType(g_PropModel[client], MOVETYPE_NOCLIP);
		
		DispatchSpawn(g_PropModel[client]);			
		
		decl Float:origin[3], Float:angles[3];
		GetClientAbsOrigin(client, origin);
		GetClientAbsAngles(client, angles);
		
		origin[2] += 1.0;
		if(StrEqual(sName, "Trashcan") || StrEqual(sName, "Weather Vane") || StrEqual(sName, "Wood Barrel"))
		{
			origin[2] += 29.0;
		}
		
		//SetEntProp(g_PropModel[client], Prop_Data, "m_CollisionGroup", 5);
		//SetEntProp(g_PropModel[client], Prop_Send, "m_CollisionGroup", 5);
		
		TeleportEntity(g_PropModel[client], origin, angles, NULL_VECTOR);					
		
		/*		
		SetVariantFloat(1.0);
		AcceptEntityInput(g_PropModel[client], "SetScale", g_PropModel[client], g_PropModel[client], 0);
		*/
		
		SetVariantString(sPlayername);
		AcceptEntityInput(g_PropModel[client], "SetParent", g_PropModel[client], g_PropModel[client], 0);
		
		SetEntPropEnt(g_PropModel[client], Prop_Send, "m_hOwnerEntity", client);
		
		Colorize(client, INVIS);
		
		//Print Model name info to client
		PrintCenterText(client, "You are a %s!", sName);
		if(g_thirdpersonCvar == 1)
		{
			PrintToChat(client,"\x01You are disguised as a \x04%s\x01  - Type \x04!third\x01/\x04!thirdperson \x01to toggle thirdperson view!", sName);
		}
		else
		{
			PrintToChat(client,"\x01You are disguised as a \x04%s\x01 Go hide!", sName);
		}
	}
	else
	{
		ReplyToCommand(client, "Entity not valid, failed to create entity!");
		LogMessage("[PB] %i Entity not valid, failed to create entity!", client);
	}
}

PerformPropPlayer(client, target)
{
	if(!IsClientInGame(target) || !IsPlayerAlive(target))
	return;
	
	if(g_PropModel[target] == -1)
	{
		CreatePropPlayer(target);
		
		LogAction(client, target, "\"%L\" set prop on \"%L\"", client, target);
		ShowActivity(client, " set prop on %N", target);
	}
	else
	{
		ClearPlayer(target);
		
		if(g_InThirdperson[target] == 1)
		{
			SwitchView(target);
		}
		
		LogAction(client, target, "\"%L\" removed prop on \"%L\"", client, target);
		ShowActivity(client, " removed prop on %N", target);
	}
}

public Action:Command_Thirdperson(client, args)
{
	if(!IsEnabled || client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
	return Plugin_Handled;
	
	if(g_thirdpersonCvar != 1)
	{
		PrintToConsole(client, "[SM] Sorry, this command has been disabled.");
		return Plugin_Handled;
	}

	if(g_PropModel[client] != -1)
	{
		SwitchView(client);
	}
	else
	{
		ReplyToCommand(client, "[SM] You must be a PROP to use thirdperson.");
	}

	return Plugin_Handled;
}

stock SwitchView(client)
{
	if(client)
	{
		if(IsPlayerAlive(client))
		{
			if(g_InThirdperson[client] == 0)
			{
				g_InThirdperson[client] = 1;
				
				g_iFov[client] = GetEntProp(client,Prop_Data,"m_iFOV");
				g_iDefFov[client] = GetEntProp(client, Prop_Send, "m_iDefaultFOV");
				
				SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
				SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
				SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
				SetEntProp(client, Prop_Send, "m_iFOV", 120);
				SetEntProp(client, Prop_Send, "m_iDefaultFOV", 120);			
			}
			else
			{
				g_InThirdperson[client] = 0;
				SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
				SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
				SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
				SetEntProp(client, Prop_Send, "m_iFOV", g_iFov[client]);
				SetEntProp(client, Prop_Send, "m_iDefaultFOV", g_iDefFov[client]);
				
				g_iFov[client] = -1;
				g_iDefFov[client] = -1;			
			}
		}
	}
}

/*
Credit to pheadxdll for invisibility code.
*/
public Colorize(client, color[4])
{	
	//Colorize the weapons
	new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");	
	new String:classname[256];
	new type;
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	for(new i = 0, weapon; i < 47; i += 4)
	{
		weapon = GetEntDataEnt2(client, m_hMyWeapons + i);
		
		if(weapon > -1 )
		{
			GetEdictClassname(weapon, classname, sizeof(classname));
			if((StrContains(classname, "tf_weapon_",false) >= 0))
			{
				SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weapon, color[0], color[1], color[2], color[3]);
			}
		}
	}
	
	//Colorize the wearables, such as hats
	SetWearablesRGBA_Impl( client, "tf_wearable_item", "CTFWearableItem",color );
	SetWearablesRGBA_Impl( client, "tf_wearable_item_demoshield", "CTFWearableItemDemoShield", color);
	
	//Colorize the player
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
	
	if(color[3] > 0)
	type = 1;
	
	InvisibleHideFixes(client, class, type);
	return;
}

SetWearablesRGBA_Impl( client,  const String:entClass[], const String:serverClass[], color[4])
{
	new ent = -1;
	while( (ent = FindEntityByClassname(ent, entClass)) != -1 )
	{
		if ( IsValidEntity(ent) )
		{		
			if (GetEntDataEnt2(ent, FindSendPropOffs(serverClass, "m_hOwnerEntity")) == client)
			{
				SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
				SetEntityRenderColor(ent, color[0], color[1], color[2], color[3]);
			}
		}
	}
}

InvisibleHideFixes(client, TFClassType:class, type)
{
	if(class == TFClass_DemoMan)
	{
		new decapitations = GetEntProp(client, Prop_Send, "m_iDecapitations");
		if(decapitations >= 1)
		{
			if(!type)
			{
				//Removes Glowing Eye
				TF2_RemoveCond(client, 18);
			}
			else
			{
				//Add Glowing Eye
				TF2_AddCond(client, 18);
			}
		}
	}
	else if(class == TFClass_Spy)
	{
		new disguiseWeapon = GetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon");
		if(IsValidEntity(disguiseWeapon))
		{
			if(!type)
			{
				SetEntityRenderMode(disguiseWeapon , RENDER_TRANSCOLOR);
				new color[4] = INVIS;
				SetEntityRenderColor(disguiseWeapon , color[0], color[1], color[2], color[3]);
			}
			else
			{
				SetEntityRenderMode(disguiseWeapon , RENDER_TRANSCOLOR);
				new color[4] = NORMAL;
				SetEntityRenderColor(disguiseWeapon , color[0], color[1], color[2], color[3]);
			}
		}
	}
}

//This won't be required in the future as Sourcemod 1.4 already has this stuff
stock TF2_AddCond(client, cond) {
	new Handle:cvar = FindConVar("sv_cheats"), bool:enabled = GetConVarBool(cvar), flags = GetConVarFlags(cvar);
	if(!enabled) {
		SetConVarFlags(cvar, flags^FCVAR_NOTIFY^FCVAR_REPLICATED);
		SetConVarBool(cvar, true);
	}
	FakeClientCommand(client, "addcond %i", cond);
	//FakeClientCommand(client, "isLoser");
	if(!enabled) {
		SetConVarBool(cvar, false);
		SetConVarFlags(cvar, flags);
	}
}

stock TF2_RemoveCond(client, cond) {
	new Handle:cvar = FindConVar("sv_cheats"), bool:enabled = GetConVarBool(cvar), flags = GetConVarFlags(cvar);
	if(!enabled) {
		SetConVarFlags(cvar, flags^FCVAR_NOTIFY^FCVAR_REPLICATED);
		SetConVarBool(cvar, true);
	}
	FakeClientCommand(client, "removecond %i", cond);
	if(!enabled) {
		SetConVarBool(cvar, false);
		SetConVarFlags(cvar, flags);
	}
} 

/*
Credit for SMC Parser related code goes to Antithasys!
*/
stock ProcessConfigFile()
{
	BuildPath(Path_SM, g_sConfigPath, sizeof(g_sConfigPath), "data/propbonusround_models.txt");
	
	/*
	Model file checks. Auto-create or disable if necessary.
	*/
	if (!FileExists(g_sConfigPath))
	{
		/*
		Config file does not exist. Re-create the file before precache.
		*/
		LogMessage("Models file not found at %s. Auto-Creating file...", g_sConfigPath);
		SetupDefaultProplistFile();
		
		if (!FileExists(g_sConfigPath))
		{
			/*
	Second fail-safe check. Somehow, the file did not get created, so it is disable time.
	*/
			SetFailState("Models file (propbonusround_models.txt) still not found. You Suck.");
		}
	}
	
	if (g_hModelNames == INVALID_HANDLE)
	{
		g_hModelNames = CreateArray(128, 0);
		g_hModelPaths = CreateArray(PLATFORM_MAX_PATH, 0);
	}

	ClearArray(g_hModelNames);
	ClearArray(g_hModelPaths);

	new Handle:hParser = SMC_CreateParser();
	SMC_SetReaders(hParser, Config_NewSection, Config_KeyValue, Config_EndSection);
	SMC_SetParseEnd(hParser, Config_End);

	new line, col;
	new String:error[128];
	new SMCError:result = SMC_ParseFile(hParser, g_sConfigPath, line, col);
	CloseHandle(hParser);
	
	if (result != SMCError_Okay) 
	{
		SMC_GetErrorString(result, error, sizeof(error));
		LogError("[propbonus] %s on line %d, col %d of %s", error, line, col, g_sConfigPath);
		LogError("[propbonus] Propbonus is not running! Failed to parse %s", g_sConfigPath);
		SetFailState("Could not parse file %s", g_sConfigPath);
	}

	g_iArraySize = GetArraySize(g_hModelNames) - 1;
}

public SMCResult:Config_NewSection(Handle:parser, const String:section[], bool:quotes) 
{
	//LogMessage("In Section %s", section);
	//PrintToChatAll("In Section %s", section);
	return SMCParse_Continue;
}

public SMCResult:Config_KeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	//LogMessage("Saving model name %s", key);
	//LogMessage("Saving model path %s", value);
	//PrintToChatAll("Saving model name %s", key);
	//PrintToChatAll("Saving model path %s", value);
	
	PushArrayString(g_hModelNames, key);
	PushArrayString(g_hModelPaths, value);
	return SMCParse_Continue;
}

public SMCResult:Config_EndSection(Handle:parser) 
{	
	//LogMessage("Leaving Section");
	//PrintToChatAll("Leaving Section");
	return SMCParse_Continue;
}

public Config_End(Handle:parser, bool:halted, bool:failed) 
{
	if (failed)
	{
		SetFailState("Plugin configuration error");
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu")) 
	{
		hAdminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}
	
	hAdminMenu = topmenu;

	new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hAdminMenu,
		"sm_propplayer",
		TopMenuObject_Item,
		AdminMenu_Propplayer, 
		player_commands,
		"sm_propplayer",
		ADMFLAG_ROOT);
	}
}

public AdminMenu_Propplayer( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Prop player");
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplayPlayerMenu(param);
	}
}

DisplayPlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Players);
	
	decl String:title[100];
	Format(title, sizeof(title), "Choose Player:");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, true);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Players(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %s", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %s", "Unable to target");
		}
		else
		{					
			PerformPropPlayer(param1, target);
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayPlayerMenu(param1);
		}
	}
}

SetupDefaultProplistFile()
{
	new Handle:hKVBuildProplist = CreateKeyValues("propbonusround");

	KvJumpToKey(hKVBuildProplist, "proplist", true);
	KvSetString(hKVBuildProplist, "Oildrum", "models/props_2fort/oildrum.mdl");
	KvSetString(hKVBuildProplist, "Barricade Sign", "models/props_gameplay/sign_barricade001a.mdl");
	KvSetString(hKVBuildProplist, "Stack of Tires", "models/props_2fort/tire002.mdl");
	KvSetString(hKVBuildProplist, "Tire", "models/props_2fort/tire001.mdl");
	KvSetString(hKVBuildProplist, "Oil Can", "models/props_farm/oilcan02.mdl");
	KvSetString(hKVBuildProplist, "Dynamite Crate", "models/props_2fort/miningcrate001.mdl");
	KvSetString(hKVBuildProplist, "Water Pump", "models/props_2fort/waterpump001.mdl");
	KvSetString(hKVBuildProplist, "Control Point", "models/props_gameplay/cap_point_base.mdl");
	KvSetString(hKVBuildProplist, "Metal Bucket", "models/props_2fort/metalbucket001.mdl");
	KvSetString(hKVBuildProplist, "Trashcan", "models/props_2fort/wastebasket01.mdl");
	KvSetString(hKVBuildProplist, "Wood Barrel", "models/props_farm/wooden_barrel.mdl");
	KvSetString(hKVBuildProplist, "Lantern", "models/props_2fort/lantern001.mdl");
	KvSetString(hKVBuildProplist, "Stack of Trainwheels", "models/props_2fort/trainwheel003.mdl");
	KvSetString(hKVBuildProplist, "Corrugated Metal", "models/props_2fort/corrugated_metal003.mdl");
	KvSetString(hKVBuildProplist, "Milk Jug", "models/props_2fort/milkjug001.mdl");
	KvSetString(hKVBuildProplist, "Mop and Bucket", "models/props_2fort/mop_and_bucket.mdl");
	KvSetString(hKVBuildProplist, "Propane Tank", "models/props_2fort/propane_tank_tall01.mdl");
	KvSetString(hKVBuildProplist, "Tombstone", "models/props_halloween/tombstone_01.mdl");
	KvSetString(hKVBuildProplist, "Cow Cutout", "models/props_2fort/cow001_reference.mdl");
	KvSetString(hKVBuildProplist, "Biohazard Barrel", "models/props_badlands/barrel01.mdl");
	KvSetString(hKVBuildProplist, "Wood Pallet", "models/props_farm/pallet001.mdl");
	KvSetString(hKVBuildProplist, "Hay Patch", "models/props_farm/haypile001.mdl");
	KvSetString(hKVBuildProplist, "Concrete Block", "models/props_farm/concrete_block001.mdl");
	KvSetString(hKVBuildProplist, "Shrub", "models/props_forest/shrub_03b.mdl");
	KvSetString(hKVBuildProplist, "Wood Pile", "models/props_farm/wood_pile.mdl");
	KvSetString(hKVBuildProplist, "Welding Machine", "models/props_farm/welding_machine01.mdl");
	KvSetString(hKVBuildProplist, "Giant Cactus", "models/props_foliage/cactus01.mdl");
	KvSetString(hKVBuildProplist, "Tree", "models/props_foliage/tree01.mdl");
	KvSetString(hKVBuildProplist, "Cluster of Shrubs", "models/props_foliage/shrub_03_cluster.mdl");
	KvSetString(hKVBuildProplist, "Spike Plant", "models/props_foliage/spikeplant01.mdl");
	KvSetString(hKVBuildProplist, "Grain Sack", "models/props_granary/grain_sack.mdl");
	KvSetString(hKVBuildProplist, "Traffic Cone", "models/props_gameplay/orange_cone001.mdl");
	KvSetString(hKVBuildProplist, "Weather Vane", "models/props_2fort/weathervane001.mdl");
	KvSetString(hKVBuildProplist, "Milk Crate", "models/props_forest/milk_crate.mdl");
	KvSetString(hKVBuildProplist, "Rock", "models/props_nature/rock_worn001.mdl");
	KvSetString(hKVBuildProplist, "Computer Cart", "models/props_well/computer_cart01.mdl");
	KvSetString(hKVBuildProplist, "Skull Sign", "models/props_mining/sign001.mdl");
	KvSetString(hKVBuildProplist, "Wood Fence", "models/props_mining/fence001_reference.mdl");
	KvSetString(hKVBuildProplist, "Hay Bale", "models/props_gameplay/haybale.mdl");
	KvSetString(hKVBuildProplist, "Water Cooler", "models/props_spytech/watercooler.mdl");
	KvSetString(hKVBuildProplist, "Television", "models/props_spytech/tv001.mdl");
	KvSetString(hKVBuildProplist, "Jackolantern", "models/props_halloween/jackolantern_02.mdl");
	KvSetString(hKVBuildProplist, "Terminal Chair", "models/props_spytech/terminal_chair.mdl");
	KvSetString(hKVBuildProplist, "Hand Truck", "models/props_well/hand_truck01.mdl");
	KvSetString(hKVBuildProplist, "Sink", "models/props_2fort/sink001.mdl");
	KvSetString(hKVBuildProplist, "Chimney", "models/props_2fort/chimney005.mdl");

	KvRewind(hKVBuildProplist);			
	KeyValuesToFile(hKVBuildProplist, g_sConfigPath);
	
	//Phew...glad thats over with.
	CloseHandle(hKVBuildProplist);
}

/*
stock DeleteModel(client)
{	
	new anime = GetAnimeEnt(client);
	if(anime > 0 && IsValidEntity(anime))
	{
		AcceptEntityInput(anime, "kill");
	}
	if(anime > 0 && IsValidEdict(anime))
	{
		RemoveEdict(anime);
		g_PropModel[client] = -1;
	}
}

stock GetAnimeEnt(client)
{
	new client2, ent;
	while(IsValidEntity(ent) && (ent = FindEntityByClassname(ent, "prop_dynamic")) != -1)
	{
		client2 = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		if(client2 == client)
		{
			return ent;
		}
	}
	return -1;
}
*/

stock ClearPlayer(client)
{
	Colorize(client, NORMAL);
	DeleteProps(client);
	
	g_iPlayerModelIndex[client] = -1;
}

stock DeleteProps(client)
{
	if(g_PropModel[client] != -1)
	{
		if(IsValidEntity(g_PropModel[client]))
		{
			//PrintToChatAll("%i IsValidEntity, AcceptEntityInput KILL entity", client);
			//PrintToServer("%i IsValidEntity, AcceptEntityInput KILL entity", client);
			AcceptEntityInput(g_PropModel[client], "kill");
			g_PropModel[client] = -1;
		}
	}
}

CheckGame()
{
	new String:strGame[10];
	GetGameFolderName(strGame, sizeof(strGame));
	
	if(StrEqual(strGame, "tf"))
	{
		PrintToServer("[propbonusround] Detected game [TF2], plugin v%s loaded..", PLUGIN_VERSION);
	}
	else
	{
		SetFailState("[propbonusround] Detected game other than [TF2], plugin disabled.");
	}
}

/*
Credit for auto-create SM commands code goes to Antithasys!
*/
stock CreateThirdpersonCommands()
{
	new String:sBuffer[128], String:sTriggerCommands[18][128];
	GetConVarString(Cvar_ThirdTriggers, sBuffer, sizeof(sBuffer));
	ExplodeString(sBuffer, ",", sTriggerCommands, sizeof(sTriggerCommands), sizeof(sTriggerCommands[]));
	for (new x = 0; x < sizeof(sTriggerCommands); x++)
	{
		if(IsStringBlank(sTriggerCommands[x]))
		{
			continue;
		}
		new String:sCommand[128];
		Format(sCommand, sizeof(sCommand), "sm_%s", sTriggerCommands[x]);
		RegConsoleCmd(sCommand, Command_Thirdperson, "Command(s) used to enable thirdperson view");
	}
}

stock bool:IsStringBlank(const String:input[])
{
	new len = strlen(input);
	for (new i=0; i<len; i++)
	{
		if (!IsCharSpace(input[i]))
		{
			return false;
		}
	}
	return true;
}

stock bool:IsValidAdmin(client, const String:flags[])
{
	if (!IsClientConnected(client))
	return false;
	
	new ibFlags = ReadFlagString(flags);
	if((GetUserFlagBits(client) & ibFlags) == ibFlags)
	{
		return true;
	}
	
	return false;
}

stock bool:IsEntLimitReached()
{
	new maxents = GetMaxEntities();
	new i, c = 0;
	
	for(i = MaxClients; i <= maxents; i++)
	{
		if(IsValidEntity(i))
		c += 1;
		
	}
	
	//PrintToChatAll("%Entity Count: %i", c);
	
	if (c >= (maxents-32))
	{
		PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
		LogError("Entity limit is nearly reached: %d/%d", c, maxents);
		return true;
	}
	else
	return false;
}

public Cvars_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == Cvar_Enabled)
	{
		if(StringToInt(newValue) == 0)
		{
			IsEnabled = false;
			UnhookEvent("teamplay_round_start", Hook_RoundStart, EventHookMode_Post);
			UnhookEvent("teamplay_round_win", Hook_RoundWin, EventHookMode_Post);
			UnhookEvent("player_death", Hook_Playerdeath, EventHookMode_Post);
			UnhookEvent("player_hurt", Hook_PlayerHurt, EventHookMode_Post);
			for(new x = 1; x <= MaxClients; x++)
			{
				if(IsClientInGame(x) && IsPlayerAlive(x))
				{
					if(g_PropModel[x] != -1)
					{
						ClearPlayer(x);
					}
					if(g_InThirdperson[x] == 1)
					{
						SwitchView(x);
					}
				}
			}
		}
		else
		{
			IsEnabled = true;
			HookEvent("teamplay_round_start", Hook_RoundStart, EventHookMode_Post);
			HookEvent("teamplay_round_win", Hook_RoundWin, EventHookMode_Post);
			HookEvent("player_death", Hook_Playerdeath, EventHookMode_Post);
			HookEvent("player_hurt", Hook_PlayerHurt, EventHookMode_Post);
		}
	}
	else if(convar == Cvar_ThirdPerson)
	{
		g_thirdpersonCvar = StringToInt(newValue);
	}
	else if(convar == Cvar_HitRemoveProp)
	{
		g_hitremovePropCvar = StringToInt(newValue);
	}
	else if(convar == Cvar_AdminOnly)
	{
		g_adminonlyCvar = StringToInt(newValue);
	}
}
