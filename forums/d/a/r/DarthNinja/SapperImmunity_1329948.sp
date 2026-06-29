/* Many of you come from the gold old days of tech (command lines, walking five miles in the snow to get your code to compile, etc)... */
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#define PLUGIN_VERSION "1.5.1"

new Handle:v_GlobalEnable = INVALID_HANDLE;
new Handle:v_ChatSpam = INVALID_HANDLE;
//new Handle:v_DealDamage = INVALID_HANDLE;

new bool:g_SapImmune[MAXPLAYERS+1] = { false, ...};
new bool:g_SpyHell[MAXPLAYERS+1] = { false, ...};
new g_AntiSappers[MAXPLAYERS+1];


public Plugin:myinfo = 
{
	name = "[TF2] Sapper Immunity",
	author = "DarthNinja",
	description = "Can't sap 'dis!",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
}

public OnPluginStart()
{
		RegAdminCmd("sm_giveantisapper", GiveAntiSapper, ADMFLAG_BAN);
		RegAdminCmd("sm_givesapimmunity", GrantSapImmunity, ADMFLAG_BAN);
		RegAdminCmd("sm_tormentspy", ToggleSpyHell, ADMFLAG_BAN);
		
		CreateConVar("sm_sapperimmunity_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		v_GlobalEnable = CreateConVar("sm_sapimmunity_global", "0", "Enable/Disable for all players <1/0>", 0, true, 0.0, true, 1.0);
		v_ChatSpam = CreateConVar("sm_sapimmunity_showtext", "1", "Set to 0 to disable anti-sapper text spam", 0, true, 0.0, true, 1.0);
		//v_DealDamage = CreateConVar("sm_sapimmunity_dealdamage", "0", "Damage the sapper and credit the engi, or just remove the sapper?", 0, true, 0.0, true, 1.0);
		
		HookEvent("player_sapped_object", SpahSappinMahStuff);
		//HookEvent("object_destroyed", Debug);
		LoadTranslations("common.phrases");
}

public Action:GiveAntiSapper(client,args)
{	
	if (args != 2)
	{
		ReplyToCommand(client, "Usage: sm_giveantisapper <client> <number>");
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
	new SQuantity = StringToInt(StrQuantity)
	
	for (new i = 0; i < target_count; i ++)
	{	
		g_AntiSappers[target_list[i]] = SQuantity;
		ReplyToCommand(client,"\x04[\x03Sap Immunity\x04]\x01 You gave \x04%N \x03%i\x01 Anti-Sappers!", target_list[i], SQuantity)
		PrintToChat(target_list[i],"\x04[\x03Sap Immunity\x04]\x01 An Admin has given you \x03%i \x04Anti-Sappers!", SQuantity)
	}
	
	return Plugin_Handled;
}

public Action:GrantSapImmunity(client,args)
{	
	if (args != 1 && args != 2)
	{
		ReplyToCommand(client, "Usage: sm_givesapimmunity <client> [1/0]");
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
			if (g_SapImmune[target_list[i]] == true)
			{
				g_SapImmune[target_list[i]] = false
				ReplyToCommand(client,"\x04[\x03Sap Immunity\x04]\x01 You took away \x04%N's\x01 Sapper Immunity!", target_list[i])
			}
			else if (g_SapImmune[target_list[i]] == false)
			{
				g_SapImmune[target_list[i]] = true
				ReplyToCommand(client,"\x04[\x03Sap Immunity\x04]\x01 You gave \x04%N\x01 Sapper Immunity!", target_list[i])
			}
		}
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
				g_SapImmune[target_list[i]] = false
				ReplyToCommand(client,"\x04[\x03Sap Immunity\x04]\x01 You took away \x04%N's\x01 Sapper Immunity!", target_list[i])
			}
			else if (iToggle == 1)
			{
				g_SapImmune[target_list[i]] = true
				ReplyToCommand(client,"\x04[\x03Sap Immunity\x04]\x01 You gave \x04%N\x01 Sapper Immunity!", target_list[i])
			}
		}
	
	}
	
	return Plugin_Handled;
}

public Action:ToggleSpyHell(client,args)
{	
	if (args != 1 && args != 2)
	{
		ReplyToCommand(client, "Usage: sm_tormentspy <client> [1/0]");
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
			if (g_SpyHell[target_list[i]] == true)
			{
				g_SpyHell[target_list[i]] = false
				ReplyToCommand(client,"\x04[\x03Sap Immunity\x04] \x04%N's\x01 Sappers will now work normally!", target_list[i])
			}
			else if (g_SpyHell[target_list[i]] == false)
			{
				g_SpyHell[target_list[i]] = true
				ReplyToCommand(client,"\x04[\x03Sap Immunity\x04] \x04%N's\x01 Sappers will now do nothing!", target_list[i])
			}
		}
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
				g_SpyHell[target_list[i]] = false
				ReplyToCommand(client,"\x04[\x03Sap Immunity\x04] \x04%N's\x01 Sappers will now work normally!", target_list[i])
			}
			else if (iToggle == 1)
			{
				g_SpyHell[target_list[i]] = true
				ReplyToCommand(client,"\x04[\x03Sap Immunity\x04] \x04%N's\x01 Sappers will now do nothing!", target_list[i])
			}
		}
	
	}
	
	return Plugin_Handled;
}

public Action:SpahSappinMahStuff(Handle:event, const String:name[], bool:dontBroadcast)
{
	new spy = GetClientOfUserId(GetEventInt(event, "userid"));
	new engi = GetClientOfUserId(GetEventInt(event, "ownerid"));
	new sapper = GetEventInt(event, "sapperid");
	
	new Handle:pack = CreateDataPack();
	
	if (GetConVarBool(v_GlobalEnable))
	{
		CreateDataTimer(0.1, KillSapper, pack);
		WritePackCell(pack, sapper);
		WritePackCell(pack, engi);
		WritePackCell(pack, spy);
		return Plugin_Handled;
	}
	
	if (g_SapImmune[engi])
	{
		CreateDataTimer(0.1, KillSapper, pack);
		WritePackCell(pack, sapper);
		WritePackCell(pack, engi);
		WritePackCell(pack, spy);
		return Plugin_Handled;
	}
	
	if (g_SpyHell[spy])
	{
		CreateDataTimer(0.1, KillSapper, pack);
		WritePackCell(pack, sapper);
		WritePackCell(pack, engi);
		WritePackCell(pack, spy);
		return Plugin_Handled;
	}
	
	if (g_AntiSappers[engi] > 0)
	{
		CreateDataTimer(0.1, KillSapper, pack);
		WritePackCell(pack, sapper);
		WritePackCell(pack, GetClientUserId(engi));
		WritePackCell(pack, GetClientUserId(spy));
		g_AntiSappers[engi] --
		if (GetConVarBool(v_ChatSpam))
		{
			PrintToChat(engi,"\x04[\x03Sap Immunity\x04]\x01 Your \x03Anti-Sapper\x01 has blocked a sap attempt!  You have \x04%i\x03 Anti-Sappers \x01remaining!", g_AntiSappers[engi])
		}
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:KillSapper(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new iSapper = ReadPackCell(pack);
	//new iEngiUser = ReadPackCell(pack);
	//new iSpyUser = ReadPackCell(pack);
	
	/* 
	if (GetConVarBool(v_DealDamage))
	{
		//Don't actually bother doing damage, just fire the event and kill the sapper.
		new Handle:hEvent = CreateEvent("object_destroyed");
		if (hEvent == INVALID_HANDLE)
			return Plugin_Continue;
	 
		SetEventInt(hEvent, "userid", iSpyUser);
		SetEventInt(hEvent, "attacker", iEngiUser);
		SetEventInt(hEvent, "assister", 0);
		SetEventString(hEvent, "weapon", "wrench");
		SetEventInt(hEvent, "weaponid", 10);
		SetEventInt(hEvent, "objecttype", 3); //Sapper
		SetEventInt(hEvent, "index", iSapper);
		SetEventBool(hEvent, "was_building", false);
		SetEventBool(hEvent, "isfake", true);
		
		FireEvent(hEvent);
	}
	*/
	AcceptEntityInput(iSapper, "Kill");
	return Plugin_Continue;
}
/*
public Action:Debug(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToChatAll( "object_destroyed")
	PrintToChatAll( "-------------------")
	PrintToChatAll( "userid = %i", GetEventInt(event, "userid"))
	PrintToChatAll( "attacker = %i", GetEventInt(event, "attacker"))
	PrintToChatAll( "assister = %i", GetEventInt(event, "assister"))
	decl String:buffer[64];
	GetEventString(event, "weapon", buffer, sizeof(buffer));
	PrintToChatAll( "weapon = %s", buffer)
	PrintToChatAll( "weaponid = %i", GetEventInt(event, "weaponid"))
	PrintToChatAll( "objecttype = %i", GetEventInt(event, "objecttype"))
	PrintToChatAll( "index = %i", GetEventInt(event, "index"))
	if (GetEventBool(event, "was_building"))
		PrintToChatAll( "was_building = true")
	else
		PrintToChatAll( "was_building = false")
}
*/