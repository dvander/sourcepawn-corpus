#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

#define PLUGIN_VERSION "2.0.0"

new Handle:v_Enable = INVALID_HANDLE;
new Handle:v_AdminFlag = INVALID_HANDLE;
new Handle:v_AdminOnly = INVALID_HANDLE;
new Handle:v_FireMode = INVALID_HANDLE;
new Handle:v_Weapons = INVALID_HANDLE;

new Handle:Hud;

new bool:g_UnlimitedFireArrows[MAXPLAYERS+1] = { false, ...};
new g_FireArrowsClip[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "[TF2] Fancy Fire Arrows (Crossbow and Huntsman)",
	author = "DarthNinja",
	description = "Fire! Fire! Fire!",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
}

public OnPluginStart()
{
	CreateConVar("sm_firearrow_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	v_Enable = CreateConVar("sm_firearrows_enable", "1", "Enable/Disable the plugin [1/0]", 0, true, 0.0, true, 1.0);
	v_FireMode = CreateConVar("sm_firearrows_auto", "0", "Everyone always has fire arrows [1/0] (Leave set to 0 to use via commands)", 0, true, 0.0, true, 1.0);
	v_AdminOnly = CreateConVar("sm_firearrows_adminonly", "0", "Only admins always have fire arrows (not players)", 0, true, 0.0, true, 1.0);
	v_AdminFlag = CreateConVar("sm_firearrows_adminflag", "b", "Admin flag to use if adminonly is enabled.");
	v_Weapons = CreateConVar("sm_firearrows_weapons", "3", "1 = Huntsman only | 2 = Crossbow only | 3 = Both", 0, true, 1.0, true, 3.0);
	
	RegAdminCmd("sm_firearrows", Command_FireToggle, ADMFLAG_BAN);
	RegAdminCmd("sm_givefirearrows", Command_GiveArrows, ADMFLAG_BAN);
	RegAdminCmd("sm_gfa", Command_GiveArrows, ADMFLAG_BAN);
	
	HookEvent("player_team", FireArrowFix,  EventHookMode_Post);
	
	AutoExecConfig(true, "firearrows");
	
	Hud = CreateHudSynchronizer();
}

public FireArrowFix(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_UnlimitedFireArrows[client] = false;
	g_FireArrowsClip[client] = 0;
}

public Action:Command_GiveArrows(client, args)
{	
	if (args != 2)
	{
		ReplyToCommand(client, "Usage: sm_givefirearrows <client> <number>");
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
			COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	decl String:StrQuantity[32];
	GetCmdArg(2, StrQuantity, sizeof(StrQuantity));
	new ArrowQuantity = StringToInt(StrQuantity)
	
	ReplyToCommand(client,"\x04[Fire Arrows]\x01 You gave \x05%s \x04%i\x01 Fire Arrows!", target_name, ArrowQuantity)
	for (new i = 0; i < target_count; i ++)
	{	
		g_FireArrowsClip[target_list[i]] = ArrowQuantity;
		PrintToChat(target_list[i],"\x04[Fire Arrows]\x01 \x05%N\x01 has given you \x04%i Fire Arrows!", client, ArrowQuantity)
		
		SetHudTextParams(0.75, 0.85, 10.0, 187, 103, 63, 255, 2, 0.0, 0.1, 1.0);
		ShowSyncHudText(target_list[i], Hud, "Fire Arrows: %i", g_FireArrowsClip[target_list[i]]);
	}
	
	return Plugin_Handled;
}

public Action:Command_FireToggle(client,args)
{	
	if (args != 1 && args != 2)
	{
		ReplyToCommand(client, "Usage: sm_firearrows <client> [1/0]");
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
			COMMAND_FILTER_NO_BOTS,
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
			if (g_UnlimitedFireArrows[target_list[i]] == true)
			{
				g_UnlimitedFireArrows[target_list[i]] = false
			}
			else if (g_UnlimitedFireArrows[target_list[i]] == false)
			{
				g_UnlimitedFireArrows[target_list[i]] = true
			}
		}
		ReplyToCommand(client,"\x04[Fire Arrows]\x01 toggled FireArrows on %s!", target_name);
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
				g_UnlimitedFireArrows[target_list[i]] = false;
				PrintToChat(target_list[i],"\x04[Fire Arrows]\x01 An Admin removed your \x04Fire Arrows!")
			}
			else if (iToggle == 1)
			{
				g_UnlimitedFireArrows[target_list[i]] = true;
				PrintToChat(target_list[i],"\x04[Fire Arrows]\x01 An Admin has given you \x04Fire Arrows!");
			}
		}
		if (iToggle != 1)
		{
			ReplyToCommand(client,"\x04[Fire Arrows]\x01 You took away %s's FireArrows!", target_name);
		}
		else if (iToggle == 1)
		{
			ReplyToCommand(client,"\x04[Fire Arrows]\x01 You gave %s FireArrows!", target_name);
		}
	}
	
	return Plugin_Handled;
}

//This only gets called once
public OnEntityCreated(entity, const String:classname[])
{
	if(!GetConVarBool(v_Enable))
	{
		return; //Plugin is disabled
	}
	
	new iWeapons = GetConVarInt(v_Weapons);
	
	//PrintToChatAll("created %s", classname);
	if(StrEqual(classname, "tf_projectile_arrow") && iWeapons != 2)
	{
		SDKHook(entity, SDKHook_Spawn, FlameArrow);
	}
	else if(StrEqual(classname, "tf_projectile_healing_bolt") && iWeapons != 1)
	{
		SDKHook(entity, SDKHook_Spawn, FlameArrow);
	}
}

//This gets called twice
public FlameArrow(entity)
{
	new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if(owner < 1)
	{
		return; //Invalid player
	}
	
	new bool:IsAdmin
	new String:Flag[3];
	GetConVarString(v_AdminFlag, Flag, sizeof(Flag));
	if(IsValidAdmin(owner, Flag))
	{
		IsAdmin = true;
	}
	else
	{
		IsAdmin = false;
	}
	
	new bool:AutoIgnite = GetConVarBool(v_FireMode);
	new bool:AdminOnly = GetConVarBool(v_AdminOnly);
	
	//If player has been given fire arrows, use them first;
	if (g_FireArrowsClip[owner] > 0)
	{
		Ignite(entity);
		g_FireArrowsClip[owner] --;
		//PrintToChat(owner,"\x04[Fire Arrows]\x01 you have \x04%i\x01 Fire Arrows left!", g_FireArrowsClip[owner]);
		//Replace with hud ^
		SetHudTextParams(0.75, 0.85, 5.0, 187, 103, 63, 255, 1, 0.0, 0.5, 0.5);
		ShowSyncHudText(owner, Hud, "Fire Arrows: %i", g_FireArrowsClip[owner]);
	}
	else if (AutoIgnite && !AdminOnly)
	{
		Ignite(entity); //Auto Ignite is enabled, and Admin Only is disabled
		return;
	}
	else if (AutoIgnite && AdminOnly && IsAdmin)
	{
		Ignite(entity); //Auto ignite is enabled, admin only is enabled, and player is an admin
		return;
	}
	else if (g_UnlimitedFireArrows[owner])
	{
		Ignite(entity); //Player or admin has manual unlimited firearrows
		return;
	}
	
	//Unhook to prevent being called twice
	SDKUnhook(entity, SDKHook_Spawn, FlameArrow);
}

Ignite(entity)
{
	//PrintToChatAll("Setting arrow on fire!");
	SetEntProp(entity, Prop_Send, "m_bArrowAlight", 1);
}

stock bool:IsValidAdmin(client, const String:flags[])
{
	if(!IsClientConnected(client))
	return false;
	
	new ibFlags = ReadFlagString(flags);
	if(!StrEqual(flags, ""))
	{
		if((GetUserFlagBits(client) & ibFlags) == ibFlags)
		{
			return true;
		}
	}
	
	if(GetUserFlagBits(client) & ADMFLAG_ROOT) 
	{
		return true;
	}
	
	return false;
}