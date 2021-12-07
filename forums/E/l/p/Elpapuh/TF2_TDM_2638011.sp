#define PL_AUTHOR "ElPapuh"
#define PL_VERSION "1.4.3"
/*
	Version 1.4 logs:
		Version number: 2 (1.4.2):
		#1 - Fixed the cdamage command not working
		
		Version number: 3 (1.4.3):
		#1 - Added an hp regen module
		#2 - Some code imrpovement
*/
#define PL_DESC "This plugin will modify the damage made by guns, sentry guns... to the team specified in the command"
#define PL_URL "https://jlovers.ml"
#define UPDATE_URL "https://jlovers.ml/plugins/tdm.txt"

#include <updater>
#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <colors>
#include <tf2>

new Handle:g_hpRegenTime[MAXPLAYERS + 1];
new Handle:g_hpInterval;
new Handle:g_hpAmmount;
new Handle:g_HPEnabled;

/*
ConVar g_teamdamageB;
ConVar g_teamdamageR;
*/

public Plugin myinfo =
{
	name = "TF2 Team damage multiplier",
	author = PL_AUTHOR,
	description = PL_DESC,
	version = PL_VERSION,
	url = PL_URL
};

public OnPluginStart()
{
	RegAdminCmd("sm_cdamage", CustomDamageCommand, ADMFLAG_GENERIC, "The main command to modify the damage");
	RegAdminCmd("sm_resetdmg", CustomDamageReset, ADMFLAG_GENERIC, "The command to reset the damage values");
	RegConsoleCmd("sm_votedmg", CustomDamageVote, "The command to start a vote to enable the custom damage");
	RegAdminCmd("sm_interval", CustomDamagehpInterval, ADMFLAG_GENERIC, "The command to choose the interval in seconds of hp regen");
	RegAdminCmd("sm_ammount", CustomDamagehpAmmount, ADMFLAG_GENERIC, "The command to choose the ammoun of hp that will be regenerated");
	
	new red = GetConVarFlags(FindConVar("tf_damage_multiplier_red"));
	new blue = GetConVarFlags(FindConVar("tf_damage_multiplier_red"));
	
	g_HPEnabled = CreateConVar("sm_regenturn", "0", "Enable/Disables the hp regen");
	
	SetConVarFlags(FindConVar("tf_damage_multiplier_red"), red & ~FCVAR_CHEAT);
	SetConVarFlags(FindConVar("tf_damage_multiplier_blue"), blue & ~FCVAR_CHEAT);
	
	/*
	g_teamdamageR = FindConVar("tf_damage_multiplier_red");
	g_teamdamageB = FindConVar("tf_damage_multiplier_blue");
	*/
	
	g_hpInterval = CreateConVar("hp_interval", "5.0", "Interval (in seconds) of hp regen");
	g_hpAmmount = CreateConVar("hp_ammount", "5.0", "Ammount of hp that will be regenerated");
	
	HookEvent("player_hurt", OnPlayerDamage);
}

public OnPlayerDamage(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iUserId = GetEventInt(event, "userid");
	new clientn = GetClientOfUserId(iUserId);

	if(g_hpRegenTime[clientn] == INVALID_HANDLE)
	{
		g_hpRegenTime[clientn] = CreateTimer(GetConVarFloat(g_hpInterval), hpRegen, clientn, TIMER_REPEAT);
	}
}

public Action:hpRegen(Handle:timer, any:client)
{	
	if(IsClientInGame(client) && !IsFakeClient(client))
	{
		
		new ClientHealth = GetClientHealth(client);
		
		if(GetConVarInt(g_HPEnabled) == 0)
		{
			if(ClientHealth < GetEntProp(client, Prop_Data, "m_iMaxHealth"))
			{
				return Plugin_Continue;
			}
			else
			{
				return Plugin_Continue;
			}
		}
		
		if(GetConVarInt(g_HPEnabled) == 1)
		{
			if(ClientHealth < GetEntProp(client, Prop_Data, "m_iMaxHealth"))
			{
				SetClientHP(client, ClientHealth + GetConVarInt(g_hpAmmount));
			}
			else
			{
				SetClientHP(client, ClientHealth + 0);
				g_hpRegenTime[client] = INVALID_HANDLE;
			}
		}
	}
	
	if(!IsClientInGame(client))
	{
		return Plugin_Continue;
	}
	
	if(!IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

SetClientHP(client, amount)
{
	new HealthOffs = FindDataMapInfo(client, "m_iHealth");
	SetEntData(client, HealthOffs, amount, true);
}

public OnMapStart()
{
	PluginListenner()
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public Action:CustomDamageCommand(client, args)
{
	if(client != 0)
	{
		if(args < 2)
		{
			CPrintToChat(client, "{red}[{blue}TDM{red}] {orange}Usage: {haunted}sm_cdamage <team> <value>");
			CPrintToChat(client, "{red}[{blue}TDM{red}] {orange}Check the console for more details.")
			PrintToConsole(client, "[TDM] Usage example: sm_cdamage blue 1000")
			PrintToConsole(client, "This will make the damage who a blue player receive will be increased by 1000")
			return Plugin_Handled;
		}
		if(args > 2)
		{
			CPrintToChat(client, "{red}[{blue}TDM{red}] {orange}Usage: {haunted}sm_cdamage <team> <value>");
			CPrintToChat(client, "{red}[{blue}TDM{red}] {orange}Check the console for more details.")
			PrintToConsole(client, "[TDM] Usage example: sm_cdamage blue 1000")
			PrintToConsole(client, "This will make the damage who a blue player receive will be increased by 1000")
			return Plugin_Handled;
		}
		if(args == 2)
		{
		
			new String:TeamLenght[6]; new String:damage[100];
				
			GetCmdArg(1, TeamLenght, sizeof(TeamLenght));
			GetCmdArg(2, damage, sizeof(damage));
			
			if(client == 0)
			{
				PrintToServer("[TDM] That command is for players only");
			}
			
			if(client != 0)
			{
				ServerCommand("tf_damage_multiplier_%s %s", TeamLenght, damage);
				if(!IsFakeClient(client))
				{
					CPrintToChatAll("{red}[{blue}TDM{red}] {orange}Now the {haunted}%s {orange}team will receive x{haunted}%s {orange}damage from the enemy team", TeamLenght, damage);
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action:CustomDamageReset(client, args)
{
	ServerCommand("tf_damage_multiplier_red 1.0");
	ServerCommand("tf_damage_multiplier_blue 1.0");
	CPrintToChatAll("{red}[{blue}TDM{red}] {orange}The team damage multiplier has been {haunted}disabled{orange}, now the guns'll do the default damage")
}

public Action:CustomDamageVote(client, args)
{
	if(client != 0)
	{
		DoVoteMenu()
	}
	if(client == 0)
	{
		PrintToServer("[TDM] That command is for players only");
	}
}

public MenuVoteOpenAction(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
		{
			delete menu;
		}	
		else if (action == MenuAction_VoteEnd)
		{
		if (param1 == 0)
		{
			ServerCommand("tf_damage_multiplier_blue 5");
			ServerCommand("tf_damage_multiplier_red 5");
			CPrintToChatAll("{red}[{blue}TDM{red}] {orange}Vote passed: Now the {red}RED {orange}and the {blue}BLU {orange}team will receive {haunted}+5% damage");
		}
		if (param1 == 1)
		{
			ServerCommand("tf_damage_multiplier_blue 10");
			ServerCommand("tf_damage_multiplier_red 10");
			CPrintToChatAll("{red}[{blue}TDM{red}] {orange}Vote passed: Now the {red}RED {orange}and the {blue}BLU {orange}team will receive {haunted}+10% damage");
		}
		if (param1 == 2)
		{
			ServerCommand("tf_damage_multiplier_blue 20");
			ServerCommand("tf_damage_multiplier_red 20");
			CPrintToChatAll("{red}[{blue}TDM{red}] {orange}Vote passed: Now the {red}RED {orange}and the {blue}BLU {orange}team will receive {haunted}+20% damage");
		}
		if (param1 == 3)
		{
			ServerCommand("tf_damage_multiplier_blue 40");
			ServerCommand("tf_damage_multiplier_red 40");
			CPrintToChatAll("{red}[{blue}TDM{red}] {orange}Vote passed: Now the {red}RED {orange}and the {blue}BLU {orange}team will receive {haunted}+40% damage");
		}
		if (param1 == 4)
		{
			ServerCommand("tf_damage_multiplier_blue 80");
			ServerCommand("tf_damage_multiplier_red 80");
			CPrintToChatAll("{red}[{blue}TDM{red}] {orange}Vote passed: Now the {red}RED {orange}and the {blue}BLU {orange}team will receive {haunted}+80% damage");
		}
		if (param1 == 5)
		{
			CPrintToChatAll("{red}[{blue}TDM{red}] {orange}No damage multiplier will be aplyed {haunted}(vote failled)");
		}
		if (param1 == 6)
		{
			ServerCommand("sm_resetdmg");
		}
	}
}

void DoVoteMenu()
{
	if (IsVoteInProgress())
	{
		return;
	}
 
	Menu menu = new Menu(MenuVoteOpenAction);
	menu.SetTitle("Damage multiplier?");
	menu.AddItem("yes", "5%");
	menu.AddItem("yes", "10%");
	menu.AddItem("yes", "20%");
	menu.AddItem("yes", "40%");
	menu.AddItem("yes", "80%");
	menu.AddItem("no", "No");
	
	menu.AddItem("no", "Disable");
	menu.ExitButton = false;
	menu.DisplayVoteToAll(20);
}

void PluginListenner()
{
	CreateTimer(60.0, Timer_DoMessage, _, TIMER_REPEAT);
}

public Action:Timer_DoMessage(Handle:timer, any:client)
{
	if(client != 0)
	{
		CPrintToChatAll("{red}[{blue}TDM{red}] {orange}You can use {haunted}/votedmg {orange}to start a vote and turn the team damage multiplier");
	}
	if(client == 0)
	{
	}
}

public Action CustomDamagehpInterval(client, args)
{
	if(GetConVarInt(g_HPEnabled) == 1)
	{
		if(client != 0)
		{
			if(args < 1)
			{
				CPrintToChat(client, "{red}[{blue}TDM{red}] {orange}Correct usage: {haunted}sm_interval <value>");
			} 
			if(args < 1)
			{
				CPrintToChat(client, "{red}[{blue}TDM{red}] {orange}Correct usage: {haunted}sm_interval <value>");
			} 
			if(args == 1)
			{
				new String:HpInterval[124];
						
				GetCmdArg(1, HpInterval, sizeof(HpInterval))
						
				ServerCommand("hp_interval %s", HpInterval);
						
				CPrintToChatAll("{red}[{blue}TDM{red}] {orange}Now you'll regenerate HP every {haunted}%s {orange}seconds", HpInterval);
			}
			if(client == 0)
			{
				PrintToServer("[TDM] That command is for players only");
			}
		}
	}
	if(GetConVarInt(g_HPEnabled) == 0 && client != 0)
	{
		CPrintToChat(client, "{red}[{blue}TDM{red}] {orange}HP regen is disabled");
	}
	if(GetConVarInt(g_HPEnabled) == 0 && client == 0)
	{
		PrintToServer("HP regen is disabled and that command is for players only");
	}
}

public Action CustomDamagehpAmmount(client, args)
{
	if(GetConVarInt(g_HPEnabled) == 1)
	{
		if(client != 0)
		{
			if(args < 1)
			{
				CPrintToChat(client, "{red}[{blue}TDM{red}] {orange}Correct usage: {haunted}sm_ammount <value>");
			} 
			if(args > 1)
			{
				CPrintToChat(client, "{red}[{blue}TDM{red}] {orange}Correct usage: {haunted}sm_ammount <value>");
			} 
			if(args == 1)
			{
				new String:HpAmmountCommand[124];
						
				GetCmdArg(1, HpAmmountCommand, sizeof(HpAmmountCommand))
						
				ServerCommand("hp_ammount %s", HpAmmountCommand);
						
				CPrintToChatAll("{red}[{blue}TDM{red}] {orange}Now you'll regenerate {haunted}%s {orange}of HP", HpAmmountCommand);
			}
		}
		if(client == 0)
		{
			PrintToServer("[TDM] That command is for players only");
		}
	}
	if(GetConVarInt(g_HPEnabled) == 0 && client != 0)
	{
		CPrintToChat(client, "{red}[{blue}TDM{red}] {orange}HP regen is disabled");
	}
	if(GetConVarInt(g_HPEnabled) == 0 && client == 0)
	{
		PrintToServer("HP regen is disabled and that command is for players only");
	}
}