//Xp System +level +display

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
// #include <colors>

#define SOUND_LEVELUP "ui/item_acquired.wav"

new String:ServerInformation[512];
new String:hud[MAXPLAYERS +1];
new Handle:HudHintTimer[MAXPLAYERS+1];
new playerLevel[MAXPLAYERS+1];
new playerExp[MAXPLAYERS+1];
new playerExpMax[MAXPLAYERS+1];
new playerGold[MAXPLAYERS+1];

new Handle:cvar_enable;
new Handle:cvar_level_max;
new Handle:cvar_exp_levelup;
new Handle:cvar_exp_onkill;
new Handle:cvar_exp_hurt;
new Handle:cvar_gold_onkill_max;
new Handle:cvar_gold_onkill_min;


public Plugin:myinfo =
{
	name = "Gold System v0.1",
	author = "",
	description = "",
	version = "1.0",
	url = ""
};
public OnPluginStart()
{
	HookEvent("player_death",Death,EventHookMode_Pre);
	HookEvent("player_hurt",Hurt,EventHookMode_Pre);
	RegConsoleCmd("sm_info", info);
	RegConsoleCmd("sm_setting", setting);
	BuildPath(Path_SM, hud, 64, "data/hud_db.txt");
	RegConsoleCmd("sm_level", Command_display, "melong2");
	cvar_enable = CreateConVar("gs_enabled", "1", "Enables the plugin");
	cvar_level_max = CreateConVar("gs_level_max", "500", "Maxmimum level players can reach");
	cvar_exp_levelup = CreateConVar("gs_exp_levelup", "50", "Experience increase on level up");
	cvar_exp_onkill = CreateConVar("gs_exp_onkill", "5", "Experience to gain on kill");
	cvar_exp_hurt = CreateConVar("gs_exp_hurt", "1", "Experience to gain on Hurt");
	cvar_gold_onkill_min = CreateConVar("gs_gold_onkill_min", "1");
	cvar_gold_onkill_max = CreateConVar("gs_gold_onkill_max", "1");

	PrecacheSound(SOUND_LEVELUP, true);
	PrecacheSound(SOUND_LEVELUP);
	decl String:file3[64];
	Format(file3, 63, "sound/%s", SOUND_LEVELUP);
	AddFileToDownloadsTable(file3);

}
public Action:Command_display(Client, Arguments)
{
	if(IsPlayerAlive(Client) == true)
	{
		DisplaytoMenu(Client);
	}
}
public OnClientPostAdminCheck(client)
{
	if(GetConVarInt(cvar_enable))
	{
		CreateTimer(2.0, hud_Load, client);
		DisplaytoMenu(client);
	}
}

public DisplaytoMenu(client)
{

	new Handle:Panel = CreatePanel();
	SetPanelTitle(Panel, "Gold System");
	DrawPanelText(Panel, "================");
	DrawPanelItem(Panel, "On Display");
	DrawPanelItem(Panel, "Off Display");

	SendPanelToClient(Panel, client, Common_level, 20);
}
public Common_level(Handle:Menu, MenuAction:Click, Parameter1, Parameter2){
	
	new Handle:Panel = CreatePanel();
	new Client = Parameter1;

	if(Click == MenuAction_Select)
	{
		if(Parameter2 == 1)
		{
			HudHintTimer[Client] = CreateTimer(1.0, Timer_UpdateHudHint, Client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		if(Parameter2 == 2)
		{
			KillTimer(HudHintTimer[Client]);
			HudHintTimer[Client] = INVALID_HANDLE;
		}
	}
	CloseHandle(Panel);
}

public OnClientDisconnect(client)
{
	if (HudHintTimer[client] != INVALID_HANDLE)
	{
		KillTimer(HudHintTimer[client]);
		HudHintTimer[client] = INVALID_HANDLE;
	}
	Save(client);
}

public Action:Timer_UpdateHudHint(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		if(playerExp[client] >= playerExpMax[client] && playerLevel[client] < GetConVarInt(cvar_level_max))
		{
			LevelUp(client, playerLevel[client] + 1);
		}

		if(playerLevel[client] >= GetConVarInt(cvar_level_max))
		{
			FormatEx(ServerInformation, sizeof(ServerInformation), "Gold System\n\n\nLevel: %i\nExp: The maximum level", playerLevel[client]);
		}
		else
		{
			FormatEx(ServerInformation, sizeof(ServerInformation), "Gold System\n\n\nLevel : %i + Level Up!!\nExp : %i/%i\nGold : %i", playerLevel[client], playerExp[client], playerExpMax[client], playerGold[client]);
		}
	}

	new Handle:hBuffer = StartMessageOne("KeyHintText", client); 
	BfWriteByte(hBuffer, 1); 
	BfWriteString(hBuffer, ServerInformation); 
	EndMessage();
	return Plugin_Handled;
}
public Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(cvar_enable))
	{
		new client = GetClientOfUserId(GetEventInt(event, "attacker"));
		new killed = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client != killed && GetConVarInt(cvar_exp_onkill) >= 1 && playerLevel[client] < GetConVarInt(cvar_level_max) && IsClientInGame(client))
		{
			new expBoost1 = GetConVarInt(cvar_exp_onkill);	
			playerExp[client] = playerExp[client] + expBoost1;
			FormatEx(ServerInformation, sizeof(ServerInformation), "Gold System\n\n\nLevel : %i + Level Up!!\nExp : %i/%i\nGold : %i", playerLevel[client], playerExp[client], playerExpMax[client], playerGold[client]);
		}

		new tempgold = GetRandomInt(GetConVarInt(cvar_gold_onkill_min), GetConVarInt(cvar_gold_onkill_max));
		playerGold[client] = playerGold[client] + tempgold;
	}
}

public Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(cvar_enable))
	{
		new calhurt = GetConVarInt(cvar_exp_hurt);
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new dmg_health = GetEventInt(event, "dmg_health");
		new String:weapon[64];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		new String:temp[3][2];
		ExplodeString(weapon, "_", temp, sizeof(temp), 2);
		// temp[0] = weapon, temp[1] = weaponname


		if(client != attacker && GetConVarInt(cvar_exp_onkill) >= 1 && playerLevel[attacker] < GetConVarInt(cvar_level_max) && IsClientInGame(attacker))
		{
			if(!StrEqual(weapon, "weapon_knife", false) && StrEqual(temp[0], "weapon", false))
			{
				if (dmg_health < 250)
				{
					new total = calhurt / dmg_health;
					playerExp[client] += total;
				}
			}
		}
	}
}

public Action:hud_Load(Handle:Timer, any:Client)
{
	new String:SteamID[32];
	GetClientAuthString(Client, SteamID, 32);

	decl Handle:Vault;

	Vault = CreateKeyValues("Vault");

	FileToKeyValues(Vault, hud);

	KvJumpToKey(Vault, "playerLevel", false);
	playerLevel[Client] = KvGetNum(Vault, SteamID);
	KvRewind(Vault);
	if(playerLevel[Client] < 1) playerLevel[Client] = 1;
	
	KvJumpToKey(Vault, "playerExp", false);
	playerExp[Client] = KvGetNum(Vault, SteamID);
	KvRewind(Vault);
	if(playerExp[Client] < 1) playerExp[Client] = 0;
	
	KvJumpToKey(Vault, "playerExpMax", false);
	playerExpMax[Client] = KvGetNum(Vault, SteamID);
	KvRewind(Vault);
	if(playerExpMax[Client] < 1) playerExpMax[Client] = 40;

	KvJumpToKey(Vault, "playerGold", false);
	playerGold[Client] = KvGetNum(Vault, SteamID);
	KvRewind(Vault);
	if(playerGold[Client] < 1) playerGold[Client] = 100;

	KvRewind(Vault);

	CloseHandle(Vault);
}
public Save(Client)
{
	if(Client > 0 && IsClientInGame(Client))
	{
		new String:SteamID[32];
		GetClientAuthString(Client, SteamID, 32);

		decl Handle:Vault;

		Vault = CreateKeyValues("Vault");

		if(FileExists(hud))
			
			FileToKeyValues(Vault, hud);
		KvJumpToKey(Vault, "playerLevel", true);
		KvSetNum(Vault, SteamID, playerLevel[Client]);
		KvRewind(Vault);
		
		KvJumpToKey(Vault, "playerExp", true);
		KvSetNum(Vault, SteamID, playerExp[Client]);
		KvRewind(Vault);
		
		KvJumpToKey(Vault, "playerExpMax", true);
		KvSetNum(Vault, SteamID, playerExpMax[Client]);
		KvRewind(Vault);

		KvJumpToKey(Vault, "playerGold", true);
		KvSetNum(Vault, SteamID, playerGold[Client]);
		KvRewind(Vault);

		KvRewind(Vault);
		KeyValuesToFile(Vault, hud);
		CloseHandle(Vault);
	}
}

public Action:info(Client, Arguments)
{
	new String:clientsteamid[32];
	GetClientAuthString(Client, clientsteamid, 32);

	if(Arguments < 2) return Plugin_Handled;
	new String:Player_Name[32], String:Msg[256], Max, Target = -1;
	GetCmdArg(1, Player_Name, sizeof(Player_Name));
	GetCmdArg(2, Msg, sizeof(Msg));
	Max = GetMaxClients();
	for(new i=1; i <= Max; i++)
	{
		if(!IsClientConnected(i))
			continue;
		new String:Other[32];
		GetClientName(i, Other, sizeof(Other));
		if(StrContains(Other, Player_Name, false) != -1)
			Target = i;
	}
	if(Target == -1)
	{
		PrintToChat(Client, "Can not find the appropriate player");
		return Plugin_Handled;
	}

	new gold, level, String:steamid[32];
	GetClientAuthString(Target, steamid, 32);

	gold = playerGold[Target];
	level = playerLevel[Target];

	new String:temp[64];
	new Handle:Panel = CreatePanel();

	Format(temp, sizeof(temp), "Name : %N", Target);
	SetPanelTitle(Panel, temp);

	DrawPanelText(Panel, "================");

	Format(temp, sizeof(temp), "Level : %d", level);
	DrawPanelText(Panel, temp);

	Format(temp, sizeof(temp), "Gold : %d", gold);
	DrawPanelText(Panel, temp);

	DrawPanelText(Panel, "1. Exit");

	SendPanelToClient(Panel, Client, publicinfo, 20);

	return Plugin_Handled;
}

public Action:setting(Client, Arguments)
{
	DisplaytoMenu(Client);
}

public publicinfo(Handle:Menu, MenuAction:Click, Parameter1, Parameter2){}

stock LevelUp(client, level)
{
	playerLevel[client] = level;
	playerExp[client] = playerExp[client] - playerExpMax[client];
	playerExpMax[client] = playerExpMax[client] + GetConVarInt(cvar_exp_levelup);
	if(level == GetConVarInt(cvar_level_max))
	{
		playerExpMax[client] = 0;
	}
	//CPrintToChatAllEx(client, "{teamcolor}%N{default} Level Up - {green}Level %i", client, playerLevel[client]);
	PrintToChatAll("\x03x01%N \x01: \x03Level Up! \x01- \x05Level \x01: \x03%i \x01/ \x05Gold \x01: \x03%i", client, playerLevel[client], playerGold[client]);
	FormatEx(ServerInformation, sizeof(ServerInformation), "Gold System\n\n\nLevel : %i + Level Up!!\nExp : %i/%i\nGold : %i", playerLevel[client], playerExp[client], playerExpMax[client], playerGold[client]);
	EmitSoundToClient(client, SOUND_LEVELUP);
}