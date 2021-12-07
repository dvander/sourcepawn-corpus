#include <sourcemod>
#define PLUGIN_VERSION "1.0.0"

new Handle:v_TextEnabled = INVALID_HANDLE;
new Handle:v_MaxCash = INVALID_HANDLE;

new g_iAccount = -1;
new g_iAutoCash[MAXPLAYERS + 1] = {-1, ...};

public Plugin:myinfo = 
{
	name = "[CS:S] Give Cash",
	author = "DarthNinja",
	description = "Change player's cash amounts",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
};

public OnPluginStart()
{
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	if (g_iAccount == -1)
	{
		SetFailState("[CS:S] Give Cash - Failed to find offset for m_iAccount!");
	}
	
	CreateConVar("sm_givecash_version", PLUGIN_VERSION, "Plugin Version", FCVAR_REPLICATED|FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_SPONLY);
	
	v_MaxCash = CreateConVar("sm_givecash_max", "1", "Enable/Disable cap of 60,000 cash max <1/0>", 0, true, 0.0, true, 1.0);
	v_TextEnabled = CreateConVar("sm_givecash_showtext", "1", "Set to 0 to skip telling the target client about changes to their cash", 0, true, 0.0, true, 1.0);
	
	RegAdminCmd("sm_cash", SetCash, ADMFLAG_SLAY, "sm_cash <target> <value> - Sets <target>'s cash to <value>");
	RegAdminCmd("sm_setcash", SetCash, ADMFLAG_SLAY, "sm_setcash <target> <value> - Sets <target>'s cash to <value>");
	RegAdminCmd("sm_addcash", AddCash, ADMFLAG_SLAY, "sm_addcash <target> <value> - Adds <value> to the <target>'s cash");
	RegAdminCmd("sm_autocash", AutoCash, ADMFLAG_SLAY, "sm_autocash <target> <value> - Sets <target>'s cash to <value> at the start of every round. Use -1 to cancel");
	
	//hook player_spawn for AutoCash
	HookEvent("player_spawn", AutoCash2);
	
	LoadTranslations("common.phrases");
	//LoadTranslations("plugin.givecash");
}


public AutoCash2(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (g_iAutoCash[client] != -1)
	{
		if (GetConVarBool(v_TextEnabled))
		{
			PrintToChat(client, "\x04[\x03Give Cash\x04]:\x01 Your cash has automatically been set to \x05%i\x01 due to the start of the round", g_iAutoCash[client]);
		}
		SetEntData(client, g_iAccount, g_iAutoCash[client]);
	}
}


public Action:AutoCash(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "Usage: sm_autocash <target> <value>");
		return Plugin_Handled;	
	}
	
	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
	GetCmdArg(1, buffer, sizeof(buffer));
	
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
	
	//Get the cash value
	decl String:Cash[15];
	GetCmdArg(2, Cash, sizeof(Cash));
	new iCash = StringToInt(Cash);
	
	// Make sure values are greater then 0 and less them 60,000
	if (iCash < 0 && iCash != -1)
	{
		ReplyToCommand(client, "[SM] Cash value is less then 0 - Using 0 instead!");
		iCash = 0;
	}
	else if (iCash > 60000 && GetConVarBool(v_MaxCash))  //65000~ cash max before it causes problems
	{
		ReplyToCommand(client, "[SM] Cash value is over 60000 - Using 60000 to prevent problems!");
		iCash = 60000;
	}
	if (iCash == -1)
	{
		ShowActivity2(client, "\x04[\x03Give Cash\x04] "," \x05%s\x01 will no longer receive cash at the start of every round.", target_name);
	}
	else 
	{
		ShowActivity2(client, "\x04[\x03Give Cash\x04] "," \x01Set \x05%s's\x01 to receive \x04%i\x01 cash at the start of every round!", target_name, iCash);
	}
	
	for (new i = 0; i < target_count; i ++)
	{
		g_iAutoCash[target_list[i]] = iCash;
		
		if (GetConVarBool(v_TextEnabled) && iCash != -1)
		{
			PrintToChat(target_list[i], "\x04[\x03Give Cash\x04]:\x01 An admin set your cash to change to \x05%i\x01 every time you spawn!", iCash);
		}
	}
	return Plugin_Handled;
}


public Action:SetCash(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "Usage: sm_cash <target> <value>");
		return Plugin_Handled;	
	}
	
	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
	GetCmdArg(1, buffer, sizeof(buffer));
	
	if ((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	//Get the cash value
	decl String:Cash[15];
	GetCmdArg(2, Cash, sizeof(Cash));
	new iCash = StringToInt(Cash);
	
	// Make sure values are greater then 0 and less them 60,000
	if (iCash < 0)
	{
		ReplyToCommand(client, "[SM] Cash value is less then 0 - Using 0 instead!");
		iCash = 0;
	}
	else if (iCash > 60000 && GetConVarBool(v_MaxCash))  //65000~ cash max before it causes problems
	{
		ReplyToCommand(client, "[SM] Cash value is over 60000 - Using 60000 to prevent problems!");
		iCash = 60000;
	}
	
	ShowActivity2(client, "\x04[\x03Give Cash\x04] "," \x01Set \x05%s's\x01 cash to \x04%i\x01!", target_name, iCash);
	for (new i = 0; i < target_count; i ++)
	{	
		//get Cash using GetEntData(client, g_iAccount); if we wanted to add
		//Set Cash
		SetEntData(target_list[i], g_iAccount, iCash);
		if (GetConVarBool(v_TextEnabled))
		{
			PrintToChat(target_list[i], "\x04[\x03Give Cash\x04]:\x01 An admin set your cash to \x05%i\x01!", iCash);
		}
	}
	
	return Plugin_Handled;
}


public Action:AddCash(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "Usage: sm_addcash <target> <value>");
		return Plugin_Handled;	
	}
	
	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
	GetCmdArg(1, buffer, sizeof(buffer));
	
	if ((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	//Get the cash value
	decl String:Cash[15];
	GetCmdArg(2, Cash, sizeof(Cash));
	new iCash = StringToInt(Cash);
	
	// Make sure values are greater then 0 and less them 60,000
	if (iCash < 0)
	{
		ReplyToCommand(client, "[SM] Cash value is less then 0 - Using 0 instead!");
		iCash = 0;
	}
	else if (iCash > 60000 && GetConVarBool(v_MaxCash))  //65000~ cash max before it causes problems
	{
		ReplyToCommand(client, "[SM] Cash value is over 60000 - Using 60000 to prevent problems!");
		iCash = 60000;
	}
	
	ShowActivity2(client, "\x04[\x03Give Cash\x04] "," \x01Added \x04%i\x01 to \x05%s's\x01 cash!", iCash, target_name);
	for (new i = 0; i < target_count; i ++)
	{	
		if (GetConVarBool(v_TextEnabled))
		{
			PrintToChat(target_list[i], "\x04[\x03Give Cash\x04]:\x01 An admin added \x05%i\x01 to your cash!", iCash);
		}
		
		//Get current cash
		new iExistingCash = GetEntData(target_list[i], g_iAccount);
		//Add cash
		iCash = iCash + iExistingCash;
		if (iCash > 60000 && GetConVarBool(v_MaxCash)) // Check this again
		{
			iCash = 60000;
		}
		//Set cash
		SetEntData(target_list[i], g_iAccount, iCash);
	}
	
	return Plugin_Handled;
}
