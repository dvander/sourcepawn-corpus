#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.2.3"

new Handle:g_CTFGrenadeDetonate;
new Handle:v_Mode = INVALID_HANDLE;
new bool:g_PlayerHasLastLaugh[MAXPLAYERS+1] = false;
new bool:g_PlayerHasLastLaugh2[MAXPLAYERS+1] = true;

public Plugin:myinfo =
{
	name = "[TF2] Automatic Demoman Detonation",
	author = "DarthNinja",
	description = "Auto-explode demoman's stickies on death",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
}

public OnPluginStart()
{
	new Handle:GameData = LoadGameConfigFile("CTFGrenadeDetonate");
	if (GameData == INVALID_HANDLE)
	{
		decl String:path[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, path, sizeof(path), "gamedata/CTFGrenadeDetonate.txt");
		LogError("Unable to load required gamedata in %s", path);
		SetFailState("Unable to load required gamedata in %s", path);
	}
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(GameData, SDKConf_Virtual, "GrenadeDetonate"); //CTFGrenadePipebombProjectile::Detonate(void)
	g_CTFGrenadeDetonate = EndPrepSDKCall();

	CreateConVar("sm_kersplode_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	v_Mode = CreateConVar("sm_kersplode_mode", "1", "0 = Global Disable, 1 = Manual Override, 2 = Global Enable", 0, true, 0.0, true, 2.0);

	RegAdminCmd("sm_lastlaugh", Grant_LastLaugh, ADMFLAG_SLAY);
	RegAdminCmd("sm_autodd", Grant_LastLaugh, ADMFLAG_SLAY);
	
	//Lateload support
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i))
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	LoadTranslations("common.phrases");
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	g_PlayerHasLastLaugh[client] = false;
	g_PlayerHasLastLaugh2[client] = true;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{	
	if (GetConVarInt(v_Mode) == 0)
		return Plugin_Continue; // Plugin disabled
	else if (GetConVarInt(v_Mode) == 1 && !g_PlayerHasLastLaugh[victim])
		return Plugin_Continue; // Manual mode + player hasn't been granted access
	else if (GetConVarInt(v_Mode) == 2 && !g_PlayerHasLastLaugh2[victim])
		return Plugin_Continue; // Global enable, but player has had their access removed
		
	if (TF2_GetPlayerClass(victim) != TFClass_DemoMan)
		return Plugin_Continue; //not a demo
	if (victim == attacker || victim == inflictor)
		return Plugin_Continue; //This is to prevent crashes
		
	if (!IsPlayerAlive(victim))
		return Plugin_Continue;	//The player should still be alive if they're taking damage, but who knows.
		
	if (attacker > 0 && attacker <= MAXPLAYERS && GetClientTeam(victim) == GetClientTeam(attacker))
		return Plugin_Continue;	//Players are on the same team - prevents taunt greifing bug TF2 has
	
	if (float(GetClientHealth(victim)) <= damage)
	{
		new iWeapon = GetPlayerWeaponSlot(victim, 1);
		if (iWeapon == -1)
			return Plugin_Continue;	//Player doesn't have a weapon in slot 2
		new iItemID = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");

		//	20 = Sticky
		//	130 = Scottish
		//	207 = Renamed Sticky or Strange Sticky
		//	265 = Sticky Jumper		
		//	661 = Festive sticky launcher
		if (iItemID == 20 || iItemID == 207 || iItemID == 130 || iItemID == 661)
		{
			new iSticky = -1;
			//new iStickyCount = 0;
			while ((iSticky = FindEntityByClassname(iSticky, "tf_projectile_pipe_remote")) != -1)
			{
				if (victim == GetEntPropEnt(iSticky, Prop_Send, "m_hThrower"))
				{
					SDKCall(g_CTFGrenadeDetonate, iSticky);
					//iStickyCount++;
				}
			}
			//PrintToChatAll("%i stickies found", iStickyCount);
		}
	}
	return Plugin_Continue;
}



public Action:Grant_LastLaugh(client,args)
{
	if (args != 1 && args != 2)
	{
		ReplyToCommand(client, "Usage: sm_autodd <client> [1/0]");
		return Plugin_Handled;
	}

	//Create strings
	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;

	//Get target arg
	GetCmdArg(1, buffer, sizeof(buffer));

	//Process
	if ((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	if (args == 1)
	{
		for (new i = 0; i < target_count; i ++)
		{
			if (g_PlayerHasLastLaugh[target_list[i]] == false)
			{
				g_PlayerHasLastLaugh[target_list[i]] = true;
				g_PlayerHasLastLaugh2[target_list[i]] = true;
			}
			else if (g_PlayerHasLastLaugh[target_list[i]] == true)
			{
				g_PlayerHasLastLaugh[target_list[i]] = false;
				g_PlayerHasLastLaugh2[target_list[i]] = false;
			}
		}
		ReplyToCommand(client,"\x04[LL]\x01 toggled Last Laugh on %s!", target_name);
	}

	else if (args == 2)
	{
		decl String:Toggle[32];
		GetCmdArg(2, Toggle, sizeof(Toggle));
		new iToggle = StringToInt(Toggle)

		for (new i = 0; i < target_count; i ++)
		{
			if (iToggle != 1)
			{
				g_PlayerHasLastLaugh[target_list[i]] = false;
				g_PlayerHasLastLaugh2[target_list[i]] = false;
			}
			else if (iToggle == 1)
			{
				g_PlayerHasLastLaugh[target_list[i]] = true;
				g_PlayerHasLastLaugh2[target_list[i]] = true;
			}
		}
		if (iToggle != 1)
		{
			ReplyToCommand(client,"\x04[LL]\x01 %s's stickies will no longer explode when they die.", target_name);
		}
		else if (iToggle == 1)
		{
			ReplyToCommand(client,"\x04[LL]\x01 %s's stickies will now explode when they die.", target_name);
		}
	}
	return Plugin_Handled;
}
