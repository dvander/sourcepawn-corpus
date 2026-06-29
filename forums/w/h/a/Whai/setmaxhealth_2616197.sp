#pragma semicolon 1

#define MAX_HEALTH_ATTRIB 26
#define MAX_HEALTH_PENALITY_ATTRIB 125

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2attributes>
#define PLUGIN_VERSION "1.0.1c"

#pragma newdecls required

bool newMaxhealth[MAXPLAYERS+1];
bool bIsDebugMod[MAXPLAYERS+1];
bool bIsDebugModGlobal;
bool bDebugMenu;

int BaseMaxhealth[MAXPLAYERS+1];
int iHealthValue;

ConVar HealthBase;
ConVar hDebugMenu;

public Plugin myinfo =
{
	name = "[TF2] Set Max Health",
	author = "Whai",
	description = "Set max health to a player",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=310817"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_sethealth", Command_Health, ADMFLAG_KICK, "Set max health to someone");
	RegAdminCmd("sm_sethealthme", Command_HealthMe, ADMFLAG_SLAY, "Set max health to you");
	RegAdminCmd("sm_resethealth", Command_ResetHealth, ADMFLAG_SLAY, "Set default max health");
	RegAdminCmd("sm_debughealth", Command_DebugPLZ, ADMFLAG_ROOT, "Toggle Debug Mod");
	
	CreateConVar("sm_sethealth_version", PLUGIN_VERSION, "The version of \"Set Health\"", FCVAR_SPONLY|FCVAR_NOTIFY);
	HealthBase = CreateConVar("sm_sethealth_default", "1", "Set target heatlh when \"sm_sethealth <target> <no value set>\"", 0, true, 0.0, false);
	HookConVarChange(HealthBase, ConVarChanged);
	hDebugMenu = CreateConVar("sm_debughealth_menu", "0", "When debug mod (not global) is activated display value in chat and menu when it has more than 1 information", 0, true, 0.0, true, 1.0);
	HookConVarChange(hDebugMenu, ConVarChanged);
	
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	
	HookEvent("player_death", Player_ChangeClass_Death);
	HookEvent("player_changeclass", Player_ChangeClass_Death);
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	OnConfigsExecuted();
}

public void OnConfigsExecuted()
{
	iHealthValue = GetConVarInt(HealthBase);
	bDebugMenu = GetConVarBool(hDebugMenu);
}

public Action Player_ChangeClass_Death(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));

	if(newMaxhealth[iClient])	//if someone doesn't have default MaxHealth then set him to default when he changes class or die
	{
		TF2Attrib_RemoveByDefIndex(iClient, MAX_HEALTH_ATTRIB);		//Setting the default MaxHP
		TF2Attrib_RemoveByDefIndex(iClient, MAX_HEALTH_PENALITY_ATTRIB);		//Setting the default MaxHP
		SetEntityHealth(iClient, 1);	
		CreateTimer(0.1, Register, iClient); //Why create a timer ? it's because if there is no timer, it will not register the the default MaxHealth but the current MaxHealth that player had before dying
	}
}

public Action Register(Handle timer, int client)
{
	int MaxHeath = TF2_GetPlayerMaxHealth(client);
	BaseMaxhealth[client] = MaxHeath;
	SetEntityHealth(client, BaseMaxhealth[client]);
	newMaxhealth[client] = false;
	
	if(bIsDebugMod[client])
		PrintToChat(client, "[Debug Mod] [SM] Base Health : %i", BaseMaxhealth[client]);
		
	if(bIsDebugModGlobal)
		PrintToChatAll("[Debug Global Mod] [SM] Base Health : %i", BaseMaxhealth[client]);
}

public void OnClientPutInServer(int client)
{
	newMaxhealth[client] = false;
	bIsDebugMod[client] = false;
}

public void OnMapStart()
{
	bIsDebugModGlobal = false;
}

public void OnClientDisconnect(int client)
{
	newMaxhealth[client] = false;
	bIsDebugMod[client] = false;
}

public void OnMapEnd()
{
	bIsDebugModGlobal = false;
}

public Action Command_Health(int client, int args)
{
	char arg1[MAX_NAME_LENGTH], arg2[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;	//Don't know how it works
	
	if (args == 1)
	{
		if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		for (int i = 0; i < target_count; i++)
		{
			int target = target_list[i];
			SetEntityHealth(target, 1);
			PerformAddHeatlh(target, iHealthValue);
		}
	}
	if (args == 2)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
		int iarg2 = StringToInt(arg2);
	
		if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		for (int i = 0; i < target_count; i++)
		{
			int target = target_list[i];

			if(iarg2 > 0 && iarg2 <= 2147483520)	//I know the integrer value limit is higher than this value but after this value, it becoming very weird
			{
				SetEntityHealth(target, 1);	//If someone is doing /sethealth @me 100 then /sethealth @me 50, he will not have the overheal
				PerformAddHeatlh(target, iarg2);
			}
			if(iarg2 <= 0)
			{
				SetEntityHealth(target, 1);
				PerformAddHeatlh(target, iHealthValue);
			}
			if(iarg2 > 2147483520)
			{
				SetEntityHealth(target, 1);
				PerformAddHeatlh(target, 2147483520);
			}
		}
		ShowActivity2(client, "[SM] ", "Set MaxHealth to %s", target_name);
	}
	if (args > 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_sethealth <target> <HP Amount>");
		return Plugin_Handled;
	}
	if(args == 0)
	{
		ReplyToCommand(client, "[SM] Usage: sm_sethealth <target>\n[SM] Usage: sm_sethealth <target> <health value>");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_HealthMe(int client, int args)
{
	if(client == 0)
	{
		ReplyToCommand(client, "[SM] Cannot be used via console server");
		return Plugin_Handled;
	}
	
	if(args != 1)
		ReplyToCommand(client, "[SM] Usage: sm_sethealthme <hp value>");
		
	if(args == 1)
	{
		char value[64];
		GetCmdArg(1, value, sizeof(value));
		int iValue = StringToInt(value);
		
		if(iValue > 2147483520)
		{
			SetEntityHealth(client, 1);
			PerformAddHeatlh(client, 2147483520);
			ReplyToCommand(client, "\x04[SM] Your value is higher than \"2147483520\", set to the max value : \"2147483520\"");
		}
		if(iValue <= 0)
		{
			SetEntityHealth(client, 1);
			PerformAddHeatlh(client, iHealthValue);
			ReplyToCommand(client, "\x04[SM] Your value is a negative value or is too high that changed into a negative value, set to the default convar value");
		}
		if(iValue > 0 && iValue <= 2147483520)
		{
			SetEntityHealth(client, 1);
			PerformAddHeatlh(client, iValue);
		}
	}
	return Plugin_Handled;
}

public Action Command_ResetHealth(int client, int args)
{
	if(client == 0 && args == 0)
	{
		ReplyToCommand(client, "[SM] Usage in console server : sm_resethealth <target>");
		return Plugin_Handled;
	}
		
	if(args == 0)
	{
		TF2Attrib_RemoveByDefIndex(client, MAX_HEALTH_ATTRIB);
		TF2Attrib_RemoveByDefIndex(client, MAX_HEALTH_PENALITY_ATTRIB);
		SetEntityHealth(client, 1);	
		CreateTimer(0.1, Register, client);
	}
	if(args == 1)
	{
		if(CheckCommandAccess(client, "resethealth_target", ADMFLAG_KICK, true))
		{
			char arg1[64], target_name[MAX_TARGET_LENGTH];
			int target_list[MAXPLAYERS], target_count;
			bool tn_is_ml;
			GetCmdArg(1, arg1, sizeof(arg1));
			
			if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			
			for(int i = 0; i < target_count; i++)
			{
				int target = target_list[i];
				TF2Attrib_RemoveByDefIndex(target, MAX_HEALTH_ATTRIB);
				TF2Attrib_RemoveByDefIndex(target, MAX_HEALTH_PENALITY_ATTRIB);
				SetEntityHealth(target, 1);	
				CreateTimer(0.1, Register, target);
			}
			ShowActivity2(client, "[SM] ", "%s max health has been reset", target_name);
		}
		else
			ReplyToCommand(client, "%t", "No Access");
		
	}
	if(args > 1)
		ReplyToCommand(client, "[SM] Usage: sm_resethealth\n[SM] Usage: sm_resethealth <target>");
		
	return Plugin_Handled;
}

public Action Command_DebugPLZ(int client, int args)
{
	if(client == 0 && args == 0)
	{
		ReplyToCommand(client, "[SM] Can't use on server console");
		return Plugin_Handled;
	}
	
	if(args > 1)
		ReplyToCommand(client, "[SM] Usage: sm_debughealth\n[SM] Usage: sm_debughealth <target>\n[SM] Usage: sm_debughealth global");

	if(args == 0)
	{
		if(bIsDebugMod[client])
		{
			bIsDebugMod[client] = false;
			ReplyToCommand(client, "\x04[SM] Debug mod disabled");
		}	
		else
		{
			bIsDebugMod[client] = true;
			ReplyToCommand(client, "\x04[SM] Debug mod enabled");
			
			if(bIsDebugModGlobal)
			{
				bIsDebugModGlobal = false;
				ReplyToCommand(client, "\x04[SM] Debug global mod disabled");
			}
		}	
	}
	if(args == 1)
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));

		if(StrEqual(arg1, "global", false))
		{
			if(bIsDebugModGlobal)
				bIsDebugModGlobal = false;
				
			else
			{
				bIsDebugModGlobal = true;
				for(int i = 0; i < MaxClients; i++)
				{
					if(bIsDebugMod[i])
					{
						PrintToChat(i, "\x04[SM] Debug mod disabled\n\x03[SM] Debug global mod enabled");
						bIsDebugMod[i] = false;
					}
				}
			}
			if(!bIsDebugMod[client])
				ReplyToCommand(client, "\x04[SM] Debug global mod %s sucess", (bIsDebugModGlobal ? "enabled" : "disabled"));
				
		}
		else
		{
			int target = FindTarget(client, arg1, true);
			
			if(target == -1)
				return Plugin_Handled;
				
			else
			{
				if(bIsDebugMod[target])
				{
					bIsDebugMod[target] = false;
					PrintToChat(target, "\x04[SM] Debug mod disabled by an admin");
				}	
				else
				{
					bIsDebugMod[target] = true;
					PrintToChat(target, "\x04[SM] Debug mod enabled by an admin");
					
					if(bIsDebugModGlobal)
					{
						bIsDebugModGlobal = false;
						PrintToChat(target, "\x04[SM] Debug global mod disabled");
					}
				}	
			}
		}
	}
	
	return Plugin_Handled;
}

void PerformAddHeatlh(int client, int health)	
{
	if(!newMaxhealth[client])
	{
		int PlayerMaxHealth = TF2_GetPlayerMaxHealth(client);
		BaseMaxhealth[client] = PlayerMaxHealth;	//When he will enter sm_sethealth for first time, or after changing class or dying, it will saves the default MaxHealth that he had for being prepared to the second/third... enter of the command
		
		int FinalHealth = (health - PlayerMaxHealth);
		
		if(FinalHealth == 0)
		{
			TF2Attrib_RemoveByDefIndex(client, MAX_HEALTH_PENALITY_ATTRIB);
			TF2Attrib_RemoveByDefIndex(client, MAX_HEALTH_ATTRIB);
		}
		else if(FinalHealth < 0)
		{
			TF2Attrib_SetByDefIndex(client, MAX_HEALTH_PENALITY_ATTRIB, float(FinalHealth));
			TF2Attrib_RemoveByDefIndex(client, MAX_HEALTH_ATTRIB);
		}
		else if(FinalHealth > 0)
		{
			TF2Attrib_SetByDefIndex(client, MAX_HEALTH_ATTRIB, float(FinalHealth));
			TF2Attrib_RemoveByDefIndex(client, MAX_HEALTH_PENALITY_ATTRIB);
		}
		
		if(bIsDebugMod[client])
		{
			PrintToChat(client, "[Debug Mod] [1]\nDefault max health value : %i \nYour max health chosed : %i\nAttribute value : %i", PlayerMaxHealth, health, FinalHealth);
			
			if(bDebugMenu)
			{
				char buffer1[32], buffer2[32], buffer3[32];
				Format(buffer1, sizeof(buffer1), "Default max health value : %i", PlayerMaxHealth);
				Format(buffer2, sizeof(buffer2), "Your max health chosed : %i", health);
				Format(buffer3, sizeof(buffer3), "Attribute value : %i", FinalHealth);
				Menu menu = new Menu(Menu_Handle);
				menu.SetTitle("Debug Mod [1]");
				menu.AddItem("DefaultHealth", buffer1);
				menu.AddItem("HealthChosed", buffer2);
				menu.AddItem("AttributeValue", buffer3);
				menu.ExitButton = true;
				menu.Display(client, MENU_TIME_FOREVER);
			}
		}
		
		if(bIsDebugModGlobal)
			PrintToChatAll("[Debug Global Mod] [1]\nDefault max health value : %i \nHis max health chosed : %i\nAttribute value : %i", PlayerMaxHealth, health, FinalHealth);

	}
	else
	{
		int iHealth = (health - BaseMaxhealth[client]);
		
		if(iHealth == 0)
		{
			TF2Attrib_RemoveByDefIndex(client, MAX_HEALTH_PENALITY_ATTRIB);
			TF2Attrib_RemoveByDefIndex(client, MAX_HEALTH_ATTRIB);
		}
		else if(iHealth < 0)
		{
			TF2Attrib_SetByDefIndex(client, MAX_HEALTH_PENALITY_ATTRIB, float(iHealth));
			TF2Attrib_RemoveByDefIndex(client, MAX_HEALTH_ATTRIB);
		}
		else if(iHealth > 0 )	
		{
			TF2Attrib_SetByDefIndex(client, MAX_HEALTH_ATTRIB, float(iHealth));
			TF2Attrib_RemoveByDefIndex(client, MAX_HEALTH_PENALITY_ATTRIB);
		}
		
		if(bIsDebugMod[client])
		{
			PrintToChat(client, "[Debug Mod] [2]\nDefault max health value : %i \nYour max health chosed : %i\nAttribute value : %i", BaseMaxhealth[client], health, iHealth);
			
			if(bDebugMenu)
			{
				char buffer1[32], buffer2[32], buffer3[32];
				Format(buffer1, sizeof(buffer1), "Default max health value : %i", BaseMaxhealth[client]);
				Format(buffer2, sizeof(buffer2), "Your max health chosed : %i", health);
				Format(buffer3, sizeof(buffer3), "Attribute value : %i", iHealth);
				Menu menu = new Menu(Menu_Handle);
				menu.SetTitle("Debug Mod [2]");
				menu.AddItem("DefaultHealth", buffer1);
				menu.AddItem("HealthChosed", buffer2);
				menu.AddItem("AttributeValue", buffer3);
				menu.ExitButton = true;
				menu.Display(client, MENU_TIME_FOREVER);
			}
		}
			
		if(bIsDebugModGlobal)
			PrintToChatAll("[Debug Global Mod] [2]\nDefault max health value : %i \nHis max health chosed : %i\nAttribute value : %i", BaseMaxhealth[client], health, iHealth);
			
	}
	SetEntityHealth(client, GetEntProp(client, Prop_Data, "m_iHealth") +(health - 1));		//Because previously, I added SetEntityHealth(target, "1") so that's why there is a "+" here. It means it will do 1 + health - 1
	newMaxhealth[client] = true;
	
	//TF2_RegeneratePlayer(client);		Useless now
}

public int Menu_Handle(Menu hMenu, MenuAction action, int param1, int param2)
{
	//When you select an item, do nothing. the menu will just disappears
}

stock int TF2_GetPlayerMaxHealth(int client)
{
	return GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
}