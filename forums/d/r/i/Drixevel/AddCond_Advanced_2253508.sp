#include <sourcemod>
#include <tf2_stocks>

public Plugin:myinfo = {
	name = "Add Condition Menu - Advanced",
	author = "The Count, Advanced by Keith Warren(Drixevel)",
	description = "Add any TF2 condition to yourself.",
	version = "1.0.0",
	//url = "http://steamcommunity.com/profiles/76561197983205071"
	url = "http://www.drixevel.com/"
}

#define COLOR_RED		"\x07B01313"
#define STRING_MAX		64
#define MAX_CONDITIONS		255

new Handle:cv_bStatus = INVALID_HANDLE;
new Handle:cv_bAdminOnly = INVALID_HANDLE;

new bool:bIsConfigLoaded;

enum eConditions
{
	String:Name[STRING_MAX],
	ID,
	String:Flags[STRING_MAX]
};
new ConditionsEnum[MAX_CONDITIONS][eConditions];
new Total = -1;

public OnPluginStart()
{
	cv_bStatus = CreateConVar("sm_cond_status", "1", "Status of the plugin: (1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cv_bAdminOnly = CreateConVar("sm_cond_admin", "0", "Enable/disable menu to follow a specific command access. (Command Access: TF2_Use_Conditions)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	RegConsoleCmd("sm_cond", Cmd_CondMenu, "Add and remove conditions.");
	RegConsoleCmd("sm_condition", Cmd_CondMenu, "Add and remove conditions.");
	RegConsoleCmd("sm_conditions", Cmd_CondMenu, "Add and remove conditions.");
	
	RegAdminCmd("sm_reloadcond", Cmd_Reload, ADMFLAG_ROOT, "Reload all conditions via config.");
	RegAdminCmd("sm_reloadcondition", Cmd_Reload, ADMFLAG_ROOT, "Reload all conditions via config.");
	RegAdminCmd("sm_reloadconditions", Cmd_Reload, ADMFLAG_ROOT, "Reload all conditions via config.");
}

public OnConfigsExecuted()
{
	if (!GetConVarBool(cv_bStatus)) return;
	
	ParseConditionsConfig();
}

bool:ParseConditionsConfig()
{
	bIsConfigLoaded = false;
	
	new Handle:DB = CreateKeyValues("Conditions");
	
	new String:sKvPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sKvPath, sizeof(sKvPath), "configs/tf2_addcond.cfg");
	
	if (!FileToKeyValues(DB, sKvPath))
	{
		LogError("Error parsing configuration file '%s': File is currently missing.", sKvPath);
		return false;
	}
	
	if(!KvGotoFirstSubKey(DB, false))
	{
		LogError("Error parsing configuration file '%s': File is currently empty.", sKvPath);
		return false;
	}
	
	Total = 0;
	do {
		LogMessage("Total = %i", Total);
		KvGetSectionName(DB, ConditionsEnum[Total][Name], 64);
		ConditionsEnum[Total][ID] = KvGetNum(DB, "condID");
		KvGetString(DB, "Flags", ConditionsEnum[Total][Flags], STRING_MAX);
		Total++;
	} while(KvGotoNextKey(DB, false));
	
	CloseHandle(DB);
	
	LogMessage("Conditions parsed successfully. [%i conditions]", Total);
	bIsConfigLoaded = true;
	
	return true;
}

public Action:Cmd_CondMenu(client, args)
{
	if (!GetConVarBool(cv_bStatus)) return Plugin_Handled;
	
	if (!bIsConfigLoaded)
	{
		ReplyToCommand(client, "[SM] Error accessing conditions menu, please tell an administrator.");
		return Plugin_Handled;
	}
	
	if(GetConVarBool(cv_bAdminOnly) && !CheckCommandAccess(client, "TF2_Use_Conditions", ADMFLAG_RESERVATION))
	{
		PrintToChat(client, "\x01[SM]%s Whoops!\x01 Looks like you're not allowed to do that!", COLOR_RED);
		return Plugin_Handled;
	}
	
	if(!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "[SM] Must be alive to add a condition.");
		return Plugin_Handled;
	}
	
	new Handle:hMenu = CreateMenu(Menu_Conditions);
	SetMenuTitle(hMenu, "Conditions:");
	
	for (new i = 0; i < Total; i++)
	{
		new iID = ConditionsEnum[i][ID];
		
		new String:sName[64];
		Format(sName, sizeof(sName), "%s[%s]", ConditionsEnum[i][Name], (TF2_IsPlayerInCondition(client, TFCond:iID) ? "x" : ""));
		
		new String:sID[12];
		IntToString(iID, sID, sizeof(sID));
		
		if (strlen(ConditionsEnum[i][Flags]) != 0)
		{
			new gAdminFlagBits = ReadFlagString(ConditionsEnum[i][Flags]);
			new bool:bFlags = bool:(GetUserFlagBits(client) & gAdminFlagBits);
			AddMenuItem(hMenu, sID, sName, (bFlags ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED));
		}
		else
		{
			AddMenuItem(hMenu, sID, sName);
		}
	}
	
	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public Menu_Conditions(Handle:hMenu, MenuAction:action, client, choice)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			new String:inform[50];
			GetMenuItem(hMenu, choice, inform, sizeof(inform));
			new TFCond:iCondition = TFCond:StringToInt(inform);
			
			if (!GetConVarBool(cv_bStatus)) return;
			
			if (!IsPlayerAlive(client))
			{
				ReplyToCommand(client, "[SM] You must be alive to manage conditions.");
				return;
			}
			
			switch (TF2_IsPlayerInCondition(client, iCondition))
			{
				case true:
					{
						TF2_RemoveCondition(client, iCondition);
						PrintToChat(client, "\x01[SM]%s Condition removed.", COLOR_RED);
					}
				case false:
					{
						TF2_AddCondition(client, iCondition);
						PrintToChat(client, "\x01[SM]\x04 Condition added.");
					}
			}
			
			Cmd_CondMenu(client, 0);
		}
	case MenuAction_End: CloseHandle(hMenu);
	}
}

public Action:Cmd_Reload(client, args)
{
	if (!GetConVarBool(cv_bStatus)) return Plugin_Handled;
	
	switch (ParseConditionsConfig())
	{
		case true: ReplyToCommand(client, "[SM] Conditions have been successfully reloaded.");
		case false: ReplyToCommand(client, "[SM] Error reloading configuration file, please check error logs.");
	}
	return Plugin_Handled;
}