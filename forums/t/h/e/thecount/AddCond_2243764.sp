#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

public Plugin:myinfo = {
	name = "Add Condition Menu",
	author = "The Count",
	description = "Add any TF2 condition to yourself.",
	version = "1",
	url = "http://steamcommunity.com/profiles/76561197983205071"
}

#define COLOR_RED		"\x07B01313"

new Handle:admins = INVALID_HANDLE, String:KvPath[100];

//The compiled version of this code has a lot of TAG MISMATCH warnings because
//it expects a silly TFCond enum rather to actual numbers. That's the only reason why.

public OnPluginStart(){
	BuildPath(Path_SM, KvPath, sizeof(KvPath), "configs/tf2_addcond.cfg");
	RegConsoleCmd("sm_cond", Cmd_CondMenu, "Add and remove conditions.");
	admins = CreateConVar("sm_cond_admin", "0");
}

public Menu_Conditions(Handle:menu, MenuAction:action, client, choice){
	if(action == MenuAction_Select && IsPlayerAlive(client)){
		new String:inform[50];
		GetMenuItem(menu, choice, inform, sizeof(inform));
		new cond = StringToInt(inform);
		if(TF2_IsPlayerInCondition(client, cond)){
			TF2_RemoveCondition(client, cond);
			PrintToChat(client, "\x01[SM]%s Condition removed.", COLOR_RED);
		}else{
			TF2_AddCondition(client, cond);
			PrintToChat(client, "\x01[SM]\x04 Condition added.");
		}
		Cmd_CondMenu(client, 0);
	}
	CloseHandle(menu);
	return;
}

public Action:Cmd_CondMenu(client, args){
	args = 0;
	if(GetConVarInt(admins) == 1 && !GetAdminFlag(GetUserAdmin(client), Admin_Generic)){
		PrintToChat(client, "\x01[SM]%s Whoops!\x01 Looks like you're not allowed to do that!", COLOR_RED);
		return Plugin_Handled;
	}
	if(!IsPlayerAlive(client)){
		ReplyToCommand(client, "[SM] Must be alive to add a condition.");
		return Plugin_Handled;
	}
	new Handle:menu = CreateMenu(Menu_Conditions), String:temp[100], String:name[100];
	SetMenuTitle(menu, "Conditions");
	new Handle:DB = CreateKeyValues("Conditions");
	FileToKeyValues(DB, KvPath);
	if(KvGotoFirstSubKey(DB)){
		KvGetString(DB, "condID", temp, sizeof(temp));
		KvGetString(DB, "name", name, sizeof(name), "NULL_NAME");
		Format(name, sizeof(name), "%s[%s]", name, (TF2_IsPlayerInCondition(client, StringToInt(temp)) ? "x" : ""));
		AddMenuItem(menu, temp, name);
		while(KvGotoNextKey(DB)){
			KvGetString(DB, "condID", temp, sizeof(temp));
			KvGetString(DB, "name", name, sizeof(name), "NULL_NAME");
			Format(name, sizeof(name), "%s[%s]", name, (TF2_IsPlayerInCondition(client, StringToInt(temp)) ? "x" : ""));
			AddMenuItem(menu, temp, name);
		}
	}
	KvRewind(DB);
	CloseHandle(DB);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 40);
	return Plugin_Handled;
}