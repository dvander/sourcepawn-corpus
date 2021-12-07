#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1

#define PLUGIN_VERSION "1.2"
#define RESETSCORE_ADMINFLAG ADMFLAG_SLAY

new Handle:hPluginEnable;
new Handle:hPublic;
new bool:CSS = false;
new bool:CSGO = false;

public Plugin:myinfo =
{
        name = "AbNeR ResetScore",
        author = "AbNeR_CSS",
        description = "Type !resetscore to reset your score",
        version = PLUGIN_VERSION,
        url = "www.tecnohardclan.com"
};

public OnPluginStart()
{  
		RegConsoleCmd("resetscore", CommandResetScore);
		RegConsoleCmd("rs", CommandResetScore);
		RegAdminCmd("sm_resetplayer", CommandResetPlayer, RESETSCORE_ADMINFLAG);
		RegAdminCmd("sm_setscore", CommandSetScore, RESETSCORE_ADMINFLAG);
		RegAdminCmd("sm_setstars", CommandSetStars, RESETSCORE_ADMINFLAG);
		
		decl String:theFolder[40];
		GetGameFolderName(theFolder, sizeof(theFolder));
		
		if(StrEqual(theFolder, "cstrike"))
		{
			CSS = true;
		}
		else if(StrEqual(theFolder, "csgo"))
		{
			CSGO = true;
			RegAdminCmd("sm_setassists", CommandSetAssists, RESETSCORE_ADMINFLAG);
		}
		AutoExecConfig();
		CreateConVar("abner_resetscore_version", PLUGIN_VERSION, "Resetscore Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
		hPluginEnable = CreateConVar("sm_resetscore", "1", "Enable or Disable the Plugin", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
		hPublic = CreateConVar("sm_resetscore_public", "1", "Enable or disable the messages when player reset her score", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
        
}
public Action:CommandResetScore(id, args)
{                        
				new String:name[MAX_NAME_LENGTH];
				GetClientName(id, name, sizeof(name));
				
				if(CSS)
				{			
					if(!id)
					{
						PrintToServer("[RS] The server cannot reset the score.");
						return Plugin_Handled;
					}
				
					if(GetConVarInt(hPluginEnable) == 0)
					{
						PrintToChat(id, "\x01\x04[RS]\x01 The plugin is disabled.");
						return Plugin_Handled;
					}
					
					if(GetClientDeaths(id) == 0 && GetClientFrags(id) == 0 && CS_GetMVPCount(id) == 0)
					{
						PrintToChat(id, "\x01\x04[RS]\x01 Your score is already 0.");
						return Plugin_Handled;
					}
					SetClientFrags(id, 0);
					SetClientDeaths(id, 0);
					CS_SetMVPCount(id, 0);
					if(GetConVarInt(hPublic) == 1)
					{
						PrintToChatAll("\x01\x04[RS]\x01 Player\x03 %s\x01 has just reseted his score.", name);
                    }
					else
					{
						PrintToChat(id, "\x01\x04[RS]\x01 You have reset your score!");
					}
				}
				
				if(CSGO)
				{			
					if(!id)
					{
						PrintToServer("[RS] The server cannot reset the score.");
						return Plugin_Handled;
					}
				
					if(GetConVarInt(hPluginEnable) == 0)
					{
						PrintToChat(id, "\x01\x0B\x04[RS]\x01 The plugin is disabled.");
						return Plugin_Handled;
					}
					
					if(GetClientDeaths(id) == 0 && GetClientFrags(id) == 0 && CS_GetMVPCount(id) == 0 && CS_GetClientAssists(id) == 0)
					{
						PrintToChat(id, "\x01\x0B\x04[RS]\x01 Your score is already 0.");
						return Plugin_Handled;
					}
					SetClientFrags(id, 0);
					SetClientDeaths(id, 0);
					CS_SetMVPCount(id, 0);
					CS_SetClientAssists(id, 0);
					CS_SetClientContributionScore(id, 0);
					if(GetConVarInt(hPublic) == 1)
					{
						PrintToChatAll("\x01\x0B\x04[RS]\x01 Player\x06 %s\x01 has just reset their score.", name);
                    }
					else
					{
						PrintToChat(id, "\x01\x0B\x04[RS]\x01 You have reset your score!");
					}
				}
				return Plugin_Handled;
}

stock SetClientFrags(index, frags)
{
        SetEntProp(index, Prop_Data, "m_iFrags", frags);
        return 1;
}
stock SetClientDeaths(index, deaths)
{
        SetEntProp(index, Prop_Data, "m_iDeaths", deaths);
        return 1;
}

	
public Action:CommandResetPlayer(client, args)
{                           
	new String:arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
                     	
	if (args != 1)
	{
	      ReplyToCommand(client, "\x01[RS] Usage: sm_setscore <name or #userid> <Kills> <Deaths>");
	      return Plugin_Handled;
	}
 	
	decl String:target_name[MAX_TARGET_LENGTH];
	new String:nameadm[MAX_NAME_LENGTH];
	GetClientName(client, nameadm, sizeof(nameadm));
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
	arg1,
	client,
	target_list,
	MAXPLAYERS,
	COMMAND_TARGET_NONE,
	target_name,
	sizeof(target_name),
	tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}


  	for (new i = 0; i < target_count; i++)
	{
		SetEntProp(target_list[i], Prop_Data, "m_iFrags", 0);
		SetEntProp(target_list[i], Prop_Data, "m_iDeaths", 0);
		CS_SetClientContributionScore(target_list[i], 0);
		CS_SetMVPCount(target_list[i], 0);
		if(CSGO)
		{
			CS_SetClientAssists(target_list[i], 0);
		}
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[RS] ", "reset score of %s", nameadm, target_name);
	}
	else
	{
		ShowActivity2(client, "[RS] ", "reset score of %s", target_name);
	}
	return Plugin_Handled;
}
public Action:CommandSetScore(client, args)
{                           
        
	new String:arg1[32], String:arg2[20], String:arg3[20];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	new kills = StringToInt(arg2);
	new deaths = StringToInt(arg3);
                     	
	if (args != 3)
	{
	      ReplyToCommand(client, "\x01[RS] Usage: sm_setscore <name or #userid> <Kills> <Deaths>");
	      return Plugin_Handled;
	}
 	
	decl String:target_name[MAX_TARGET_LENGTH];
	new String:nameadm[MAX_NAME_LENGTH];
	GetClientName(client, nameadm, sizeof(nameadm));
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
	arg1,
	client,
	target_list,
	MAXPLAYERS,
	COMMAND_TARGET_NONE,
	target_name,
	sizeof(target_name),
	tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}


  	for (new i = 0; i < target_count; i++)
	{
		SetEntProp(target_list[i], Prop_Data, "m_iFrags", kills);
		SetEntProp(target_list[i], Prop_Data, "m_iDeaths", deaths);
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[RS] ", "set score of %s to %d/%d.", target_name, kills, deaths);
	}
	else
	{
		ShowActivity2(client, "[RS] ", "set score of %s to %d/%d.", target_name, kills, deaths);
	}

	return Plugin_Handled;
}

public Action:CommandSetAssists(client, args)
{                           
        
	new String:arg1[32], String:arg2[20];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	new assists = StringToInt(arg2);
                     	
	if (args != 2)
	{
	      ReplyToCommand(client, "\x01[RS] Usage: sm_setassists <name or #userid> <assists>");
	      return Plugin_Handled;
	}
 	
	decl String:target_name[MAX_TARGET_LENGTH];
	new String:nameadm[MAX_NAME_LENGTH];
	GetClientName(client, nameadm, sizeof(nameadm));
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
	arg1,
	client,
	target_list,
	MAXPLAYERS,
	COMMAND_TARGET_NONE,
	target_name,
	sizeof(target_name),
	tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}


  	for (new i = 0; i < target_count; i++)
	{   
		CS_SetClientAssists(target_list[i], assists);
	}

	if (tn_is_ml)
	{
		ShowActivity2(client, "[RS] ", "set assists of %s to %d.", target_name, assists);
	}
	else
	{
		ShowActivity2(client, "[RS] ", "set assists of %s to %d.", target_name, assists);
	}

	return Plugin_Handled;
}

public Action:CommandSetStars(client, args)
{                           
        
	new String:arg1[32], String:arg2[20];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	new stars = StringToInt(arg2);
                     	
	if (args != 2)
	{
	      ReplyToCommand(client, "\x01[RS] Usage: sm_setstars <name or #userid> <stars>");
	      return Plugin_Handled;
	}
 	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
	arg1,
	client,
	target_list,
	MAXPLAYERS,
	COMMAND_TARGET_NONE,
	target_name,
	sizeof(target_name),
	tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

  	for (new i = 0; i < target_count; i++)
	{
		CS_SetMVPCount(target_list[i], stars);
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[RS] ", "set stars of %s to %d.", target_name, stars);
	}
	else
	{
		ShowActivity2(client, "[RS] ", "set stars of %s to %d.", target_name, stars);
	}

	return Plugin_Handled;
}