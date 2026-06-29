/*
 *  V.I.P
 *    by
 * PriceLess              
 * version 1.1
*/

#include <sourcemod>
#include <cstrike>
#include <sdktools>

#define VERSION	"1.1"
#define SPEC		1
#define TEAM1		2
#define TEAM2		3

new Float:extendDuration;

new g_VipStatus[MAXPLAYERS+1] = 0;
new g_VipEnd[MAXPLAYERS+1] = 0;
new tag;

new bool:g_bTracersEnabled[MAXPLAYERS+1] = { false, ... } ;

new Handle:hDatabase = INVALID_HANDLE;
new Handle:g_Health;
new Handle:g_Money;
new Handle:g_Armor;
new Handle:g_chat;
new Handle:g_time;

new String:Log[PLATFORM_MAX_PATH];

public Plugin:myinfo =
{
 name = "vip",
 author = "priceless",
 description = "Gives featurs to vip",
 version = VERSION,
 url = "http://sourcemod.net/"
}

public OnPluginStart()
{
	BuildPath(Path_SM, Log, sizeof(Log), "logs/vip.log");
	
	PrintToChatAll("\x07FFFFFF[VIP]\x01 version \x01(\x07FFFFFF%s\x01) has been injected, enjoy!", VERSION);
	if(!SQL_CheckConfig("vip"))
	LogToFile(Log, "[VIP] Could not establish connection in database.cfg");
	SQL_TConnect(GotDatabase, "vip");
	
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("bullet_impact", OnBulletImpact);
	
	CreateConVar("sm_vip_version", VERSION, "VIP Verion", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Health = CreateConVar("sm_vip_health", "120", "Amount of hp on spawn");
	g_Money = CreateConVar("sm_vip_money", "1200", "amount of money on spawn");
	g_Armor = CreateConVar("sm_vip_armor", "120", "amount of armor on spawn");
	g_chat = CreateConVar("sm_vip_chat", "yourtag", "the chat tag where it says 'yourtag'");
	g_time = CreateConVar("sm_vip_duration", "31", "the time you want your 'vip's' to be vip");
	
	RegConsoleCmd("sm_vip", VIP);
	RegAdminCmd("sm_givevip", AddVip, ADMFLAG_ROOT);
	AddCommandListener(Chat, "say");
	
	AddServerTag("vip");
	
	AutoExecConfig(true, "sm_vip");
}

public OnPluginEnd()
{
	CloseHandle(hDatabase);
}

public GotDatabase(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogToFile(Log, "[VIP] Database failure (%s)", error);
	}
	else
	{
		LogToFile(Log, "[VIP] Connection found");
		PrintToServer(Log, "[VIP] Connection found");
		hDatabase = hndl;
		SQL_TQuery(hndl, GotDatabase2, "CREATE TABLE IF NOT EXISTS vip (id INTEGER PRIMARY KEY AUTO_INCREMENT, steamid VARCHAR(32) UNIQUE, status INTEGER, expiredate INTEGER)");
	}
}

public GotDatabase2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogToFile(Log, "[VIP] Failed to query (%s)", error);
		return;
	}
}

public OnClientPutInServer(client)
{
	new String:Query[250];
	new String:steamid[32];
	g_VipStatus[client] = 0;
	GetClientAuthString(client, steamid, sizeof(steamid));
	Format(Query, sizeof(Query), "SELECT status,expiredate FROM vip WHERE steamid='%s'", steamid);
	SQL_TQuery(hDatabase, clientConnect, Query, client);	
}

public clientConnect(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(hndl == INVALID_HANDLE)
	{
		LogToFile(Log, "[VIP] Failed to query (%s)", error);
		return;
	}
	else
	{
		if(!IsClientConnected(client) || !IsClientInGame(client)) return;
		if(SQL_GetRowCount(hndl) == 0)
		{
			PrintToChat(client, "\x07FFFFFF[VIP]\x01 Your vip status is \x07FFFFFFoff \x01");
		}
		else
		{
			SQL_FetchRow(hndl);
			EnableVIP(client, SQL_FetchInt(hndl, 0), SQL_FetchInt(hndl, 1));
			PrintToChat(client, "\x07FFFFFF[VIP]\x01 Your vip status is \x07FFFFFFon \x01");
		}
	}
}

public EnableVIP(client, status, endtime)
{
	g_VipStatus[client] = status;
	g_VipEnd[client] = endtime;
	/*if (status >= 1)
	{
		AddUserFlags(client, Admin_Custom1);
	}*/
}

public OnClientDisconnect(client)
{
	g_VipStatus[client] = 0;
}

public Action:VIP(client, args)
{
	if(g_VipStatus[client] == 1)
	{
		new Handle:VMenu = CreateMenu(VipMenu);
		SetMenuTitle(VMenu, "_-'VIP'-_");
		AddMenuItem(VMenu, "TT", "Toggle tracers");
		AddMenuItem(VMenu, "SPEC", "Move to spectator");
		SetMenuExitButton(VMenu, true);
		DisplayMenu(VMenu, client, 0);
			
		return Plugin_Handled;
	}
	else
	{
		PrintToChat(client, "\x07FFFFFF[VIP]\x01 You are not a VIP member");
		return Plugin_Handled;
	}
}

public VipMenu(Handle:VMenu, MenuAction:action, client, position)
{
	if(action == MenuAction_Select)
	{
		decl String:item[20];
		GetMenuItem(VMenu, position, item, sizeof(item));
		
		if(StrEqual(item, "TT"))
		{
			if (g_VipStatus[client] == 0) return;
			g_bTracersEnabled[client] = !g_bTracersEnabled[client];
			PrintToChat(client, "\x07FFFFFF[VIP]\x01 Your tracers are now \x07FFFFFF%s\x01", g_bTracersEnabled[client] ? "on" : "off");
		}
		if(StrEqual(item, "SPEC"))
		{
			ChangeClientTeam(client, SPEC)
			PrintToChat(client, "\x07FFFFFF [VIP] \x01 You were moved to spectator");
			return;
		}
		if(GetClientTeam(client)==CS_TEAM_SPECTATOR)
		{
			PrintToChat(client, "You are already a spectator.");
			return;
		}			
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(VMenu)
	}
}

public Action:OnBulletImpact(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_bTracersEnabled[client])
	{
		decl Float:_fOrigin[3], Float:_fImpact[3], colors[4];
		_fImpact[0] = GetEventFloat(event, "x");
		_fImpact[1] = GetEventFloat(event, "y");
		_fImpact[2] = GetEventFloat(event, "z");
		GetClientEyePosition(client, _fOrigin);
		if (GetClientTeam(client) == CS_TEAM_CT)
		{
			colors = {0,0,255,255};
			TE_SetupBeamPoints(_fOrigin, _fImpact, PrecacheModel("materials/sprites/laser.vmt"), 0, 0, 0, 2.0, 1.0, 1.0, 1, 0.0, colors, 0);
			TE_SendToAll();
		}
		else
		{
			colors = {255,0,0,255};
			TE_SetupBeamPoints(_fOrigin, _fImpact, PrecacheModel("materials/sprites/laser.vmt"), 0, 0, 0, 2.0, 1.0, 1.0, 1, 0.0, colors, 0);
			TE_SendToAll();
		}
	}
}

public Action:Chat(client, const String:command[], args)
{
	if(g_VipStatus[client] == 1)
	{
		decl String:chat2[15];
		GetConVarString(g_chat, chat2, sizeof(chat2));
		tag = client;
		if(tag == client)
		{
			decl String:Text[250];
			GetCmdArg(1, Text, sizeof(Text));
			
			if(Text[0] == '/')
			{
				return Plugin_Handled;
			}
			
			{
				PrintToChatAll("\x07FFFFFF[%s] \x03%N:\x01 %s", chat2, client, Text);
				return Plugin_Handled;
			}
		}
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:AddVip(client, args)
{
	if(GetCmdArgs() != 2)
	{
		PrintToChat(client, "\x07FFFFFF[VIP]\x01 Usage: sm_givevip <steamid|#name> <1|#0>");
		return Plugin_Handled;
	}
	new String:steamid[32], String:status[2], intStatus, String:Query[200];
	GetCmdArg(1, steamid, sizeof(steamid));

	if(StrContains(steamid, "steamid_", false) == -1)
	{
		new target;
		target = matchPlayerName(steamid);
		
		if(target == 0)
		{
			PrintToChat(client, "\x07FFFFFF[VIP]\x01 Can't find %s in the server", steamid);
			return Plugin_Handled;
		}
		GetClientAuthString(target, steamid, sizeof(steamid));
	}
	GetCmdArg(2, status, sizeof(status));
	intStatus = StringToInt(status);
	
	if(intStatus == 0)
	{
		Format(Query, sizeof(Query), "DELETE FROM vip WHERE steamid='%s'", steamid);
		SQL_TQuery(hDatabase, GotDatabase2, Query);
		PrintToChat(client, "\x07FFFFFF[VIP]\x01 Removed %s from database", steamid);
	}
	else
	{
		new String:days[2], Float:fldays;
		GetCmdArg(3, days, sizeof(days));
		extendDuration = GetConVarFloat(g_time);
		
		fldays = StringToFloat(days);
		if (fldays == 0.0)
		{
			fldays = extendDuration;
		}
		
		new time = GetTime();
		Format(Query, sizeof(Query), "REPLACE INTO vip (status, steamid, expiredate) VALUES ('%i', '%s', '%.0f')", intStatus, steamid, time + fldays * 24*60*60);
		SQL_TQuery(hDatabase, GotDatabase2, Query);
		PrintToChat(client, "\x07FFFFFF[VIP]\x01 Added %s  to \x07FFFFFF[VIP]\x01 ending in %.2f days", steamid, fldays);
		
		new playerindex = getClientFromAuth(steamid);
		if (playerindex != 0)
		{
			EnableVIP(playerindex, intStatus, time + _:fldays *24*60*60);
			PrintToChat(playerindex, "\x07FFFFFF[VIP]\x01 Your VIP has been enabled, you have %.2f days remaining", fldays);
		}
	}
	return Plugin_Handled;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_VipStatus[client] == 1)
	{
		SetEntProp(client, Prop_Data, "m_iHealth", GetConVarInt(g_Health));
		SetEntProp(client, Prop_Send, "m_iAccount", GetConVarInt(g_Money));
		SetEntProp(client, Prop_Send, "m_ArmorValue", GetConVarInt(g_Armor));
	}
	else
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

/* helper functions */
public getClientFromAuth(String:auth[])
{
	decl String:compsteamid[64];
	for (new x=1; x<= MaxClients; x++)
	{
		if (IsClientConnected(x) && IsClientInGame(x))
		{
			GetClientAuthString(x, compsteamid, sizeof(compsteamid));
			if (StrEqual(compsteamid, auth))
			{
				return x;
			}
		}
	}
	return 0;
}

public matchPlayerName(String:partialstring[])
{
	decl String:playername[64];
	for (new x=1; x<= MaxClients; x++)
	{
		if (IsClientConnected(x) && IsClientInGame(x))
		{
			GetClientName(x, playername, sizeof(playername));
			if (StrContains(playername, partialstring, false) != -1)
			{
				return x;
			}
		}
	}
	return 0;
}