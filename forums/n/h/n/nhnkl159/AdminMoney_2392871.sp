#pragma semicolon 1

#define DEBUG
#pragma tabsize 0
#define PLUGIN_AUTHOR "nhnkl159"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <colors>

// ----- Shit -----//
new ACCOUNT_OFFSET;

ConVar g_Enabled;
ConVar g_PrintToChat;


public Plugin myinfo = 
{
	name = "[CS:GO / ?] Admin Money",
	author = PLUGIN_AUTHOR,
	description = "Admin can set players money.",
	version = PLUGIN_VERSION,
	url = "-none-"
};

public void OnPluginStart()
{
	
	//Commands//
	RegAdminCmd("sm_setmoney", Cmd_SetMoney, ADMFLAG_BAN, "Set Money command");
	
	//Money variable
	ACCOUNT_OFFSET = FindSendPropOffs("CCSPlayer", "m_iAccount");
	
	
	//Convars//
	g_Enabled = CreateConVar("sm_adminmoney_enabled", "1", "Plugin enabled ?");
	g_PrintToChat = CreateConVar("sm_adminmoney_printtochat", "1", "Print to chat if admin set money ?");
	
}


public Action Cmd_SetMoney(client, args)
{
	new Money;
	
	if(GetConVarInt(g_Enabled) == 0)
	{
		return Plugin_Stop;
	}
	
	if(args != 2)
	{
		CPrintToChat(client, "\x05[Money]\x01 Usage : sm_setmoney <name> <money>");
		return Plugin_Handled;
	}
	
    new String:arg[MAX_NAME_LENGTH]; 
    GetCmdArg(1, arg, sizeof(arg)); 
    new String:arg2[MAX_NAME_LENGTH]; 
    GetCmdArg(2, arg2, sizeof(arg2)); 
    Money = StringToInt(arg2);

    new targets[1];
    new String:target_name[MAX_TARGET_LENGTH]; 
    new bool:tn_is_ml; 

    new targets_found = ProcessTargetString(arg, 
                                    client, 
                                    targets, sizeof(targets), 
                                    COMMAND_FILTER_NO_IMMUNITY|COMMAND_FILTER_NO_MULTI, 
                                    target_name, sizeof(target_name), tn_is_ml); 

    if (targets_found <= COMMAND_TARGET_NONE)
    { 
        ReplyToTargetError(client, targets_found); 
        return Plugin_Handled; 
         
    }

   	new target = targets[0];
	
	SetEntData(target, ACCOUNT_OFFSET, Money);
	
	if(GetConVarInt(g_PrintToChat) == 1)
	{
		CPrintToChatAll("\x05[Money]\x01 \x07%N\x01 set \x07%N\x01 money to \x07%d", client, target, Money);
	}
	
	
	return Plugin_Handled;
}