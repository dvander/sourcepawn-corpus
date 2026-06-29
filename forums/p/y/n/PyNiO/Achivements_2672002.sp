
#define PLUGIN_AUTHOR "PyNiO ™"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#include <clientprefs>
#include <scp>

ConVar g_iPlayerOn;
ConVar g_iPlayerKills;
ConVar g_iPlayerAssists;
ConVar g_iPlayerHeadshots;
ConVar g_iPlayerWin;
ConVar g_iPlayerLose;
ConVar g_iPlayerPlant;
ConVar g_iPlayerDefuse;

int g_iKills[MAXPLAYERS];
int g_iAssists[MAXPLAYERS];
int g_iHeadshots[MAXPLAYERS];
int g_iWin[MAXPLAYERS];
int g_iLose[MAXPLAYERS];
int g_iPlant[MAXPLAYERS];
int g_iDefuse[MAXPLAYERS];

int g_iKillsA[MAXPLAYERS];
int g_iAssistsA[MAXPLAYERS];
int g_iHeadshotsA[MAXPLAYERS];
int g_iWinA[MAXPLAYERS];
int g_iLoseA[MAXPLAYERS];
int g_iPlantA[MAXPLAYERS];
int g_iDefuseA[MAXPLAYERS];

int g_iPlayerTag[MAXPLAYERS];

Handle g_hSQL = INVALID_HANDLE;
bool	g_bPlayerWczytane		[MAXPLAYERS+1];
int		g_iPolaczenia;

new String:Error[100];

char g_sNames[][128] =
{
	"-"
    "Killer",
    "Helpful guy",
    "Headhunter",
    "Winner",
    "Loser",
    "Planter",
    "Sapper",
};

public Plugin myinfo = 
{
	name = "Achievements",
	author = PLUGIN_AUTHOR,
	description = "Custom achievements for cs:go server",
	version = PLUGIN_VERSION,
	url = "asd"
};
public void OnMapStart()
{
	g_iPolaczenia=0;
	ConnectSQL();
	
	AddFolderToDownloadsTable("materials/overlays/achievements");
	AddFileToDownloadsTable("sound/achievements/achievement.mp3");
	PrecacheSound("achievements/achievement.mp3", true);
}

void sound(int client)
{
	ClientCommand(client, "play *achievements/achievement.mp3");
}

public OnClientConnected(client)
{
	ClientCommand(client,"r_drawscreenoverlay 1");
}

public void OnClientPutInServer(int client)
{
	g_bPlayerWczytane[client]=false;
	Load(client);
	givetags(client);
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_achievements", cmd_achivements);
	RegConsoleCmd("sm_tag", cmd_tag);
	RegConsoleCmd("sm_stats", cmd_stats);
	
	HookEvent("player_death", Player_Death);
	HookEvent("round_end", Round_End);
	HookEvent("bomb_planted", BombPlanted);
	HookEvent("bomb_defused", BombDefused);
	
	g_iPlayerOn = CreateConVar("achievements_players", "2", "How many players for getting achievement?", _, true, 1.0, true, 64.0);
	g_iPlayerKills = CreateConVar("achievements_kills", "20", "How many kills for achievement?", _, true, 1.0, true, 1000.0);
	g_iPlayerAssists = CreateConVar("achievements_assists", "5", "How many assists for achievement?", _, true, 1.0, true, 1000.0);
	g_iPlayerHeadshots = CreateConVar("achivements_headshots", "5", "How many headshots for achievement?", _, true, 1.0, true, 1000.0);
	g_iPlayerWin = CreateConVar("achievements_win", "10", "How many rounds wins for achievement?", _, true, 1.0, true, 1000.0);
	g_iPlayerLose = CreateConVar("achievements_lose", "10", "How many rounds lost for achievement?", _, true, 1.0, true, 1000.0);
	g_iPlayerPlant = CreateConVar("achievements_plant", "5", "How many bomb plants for achievement?", _, true, 1.0, true, 1000.0);
	g_iPlayerDefuse = CreateConVar("achievements_defuse", "5", "How many bomb defuses for achievement?", _, true, 1.0, true, 1000.0);
	
	AutoExecConfig(true, "Achievements_Config");
}

public Action cmd_tag(int client, int args)
{
	if(IsValidPlayer(client))
	{
		playertag(client);
	}	
}

public Action cmd_stats(int client, int args)
{
	if(IsValidPlayer(client))
	{
		stats(client);
	}
}

public Action cmd_achivements(int client, int args)
{
	Handle menu = CreateMenu(MenuAchivementsHand);
	
	SetMenuTitle(menu, "Achievements: Menu");
	
	AddMenuItem(menu, "op1","My Achievements");
	AddMenuItem(menu, "op2","My Stats");
	AddMenuItem(menu, "op3","All Achievements");
	AddMenuItem(menu, "op4","Achievements Tags");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 30);
}

public MenuAchivementsHand(Handle menu, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select && IsValidPlayer(client)) 
	{
		char info[255];
		GetMenuItem(menu, itemNum, info, sizeof(info));
	
		if(StrEqual(info, "op1"))
		{
			PrintToChat(client, " \x02---------------- \x01My Achievements \x02----------------");
			
			if(g_iKillsA[client]==1)
			{
				PrintToChat(client, " \x04Killer [Owned]");
			}
			if(g_iAssistsA[client]==1)
			{
				PrintToChat(client, " \x04Helpful guy [Owned]");
			}
			if(g_iHeadshotsA[client]==1)
			{
				PrintToChat(client, " \x04Headhunter [Owned]");
			}
			if(g_iWinA[client]==1)
			{
				PrintToChat(client, " \x04Winner [Owned]");
			}
			if(g_iLoseA[client]==1)
			{
				PrintToChat(client, " \x04Loser [Owned]");
			}
			if(g_iPlantA[client]==1)
			{
				PrintToChat(client, " \x04Planter [Owned]");
			}
			if(g_iDefuseA[client]==1)
			{
				PrintToChat(client, " \x04Sapper [Owned]");
			}
			
			PrintToChat(client, " \x02---------------------------------------------");
		}
		if(StrEqual(info, "op2"))
		{
			PrintToChat(client, " \x02---------------- \x01My Statistics \x02----------------");
			PrintToChat(client, " \x04Kills: %i",g_iKills[client]);
			PrintToChat(client, " \x04Assists: %i",g_iAssists[client]);
			PrintToChat(client, " \x04Headshots %i",g_iHeadshots[client]);
			PrintToChat(client, " \x04Win: %i",g_iWin[client]);
			PrintToChat(client, " \x04Lose: %i",g_iLose[client]);
			PrintToChat(client, " \x04Bomb planted: %i",g_iPlant[client]);
			PrintToChat(client, " \x04Bomb defused: %i",g_iDefuse[client]);
			PrintToChat(client, " \x02---------------------------------------------");
		}
		if(StrEqual(info, "op3"))
		{
			stats(client);
		}
		if(StrEqual(info, "op4"))
		{
			playertag(client);
		}
	}
}

public stats(int client)
{
	if(IsValidPlayer(client))
	{
		PrintToChat(client, " \x02---------------- \x01All Achievements \x02----------------");
			
			PrintToChat(client, " \x04Killer: [%i / %i]",g_iKills[client],g_iPlayerKills.IntValue);
			PrintToChat(client, " \x04Helpful guy: [%i / %i]",g_iAssists[client],g_iPlayerAssists.IntValue);
			PrintToChat(client, " \x04Headhunter: [%i / %i]",g_iHeadshots[client],g_iPlayerHeadshots.IntValue);
			PrintToChat(client, " \x04Winner: [%i / %i]",g_iWin[client],g_iPlayerWin.IntValue);
			PrintToChat(client, " \x04Loser: [%i / %i]",g_iLose[client],g_iPlayerLose.IntValue);
			PrintToChat(client, " \x04Planter: [%i / %i]",g_iPlant[client],g_iPlayerPlant.IntValue);
			PrintToChat(client, " \x04Sapper: [%i / %i]",g_iDefuse[client],g_iPlayerDefuse.IntValue);
			
			PrintToChat(client, " \x02---------------------------------------------");
	}	
}

public givetags(int client)
{
	if(g_iPlayerTag[client]==1)
	{
		CS_SetClientClanTag(client, "[Killer]");
	}
	if(g_iPlayerTag[client]==2)
	{
		CS_SetClientClanTag(client, "[HelpfulGuy]");
	}
	if(g_iPlayerTag[client]==3)
	{
		CS_SetClientClanTag(client, "[Headhunter]");
	}
	if(g_iPlayerTag[client]==4)
	{
		CS_SetClientClanTag(client, "[Winner]");
	}
	if(g_iPlayerTag[client]==5)
	{
		CS_SetClientClanTag(client, "[Loser]");
	}
	if(g_iPlayerTag[client]==6)
	{
		CS_SetClientClanTag(client, "[Planter]");
	}
	if(g_iPlayerTag[client]==7)
	{
		CS_SetClientClanTag(client, "[Sapper]");
	}
	else
	{
		return Plugin_Continue;
	}
}

public playertag(int client)
{
	Handle menutag = CreateMenu(MenuTagHand);
	
	SetMenuTitle(menutag, "Achievements: Tags");
	
	if(g_iKillsA[client]==1)
	{
		AddMenuItem(menutag, "op1","Killer");
	}
	else
	{
		AddMenuItem(menutag, "op1","Killer",ITEMDRAW_DISABLED);
	}
	
	if(g_iAssistsA[client]==1)
	{
		AddMenuItem(menutag, "op2","HelpfulGuy");
	}
	else
	{
		AddMenuItem(menutag, "op2","HelpfulGuy",ITEMDRAW_DISABLED);
	}
	
	if(g_iHeadshotsA[client]==1)
	{
		AddMenuItem(menutag, "op3","Headhunter");
	}
	else
	{
		AddMenuItem(menutag, "op3","Headhunter",ITEMDRAW_DISABLED);
	}
	
	if(g_iWinA[client]==1)
	{
		AddMenuItem(menutag, "op4","Winnner");
	}
	else
	{
		AddMenuItem(menutag, "op4","Winnner",ITEMDRAW_DISABLED);
	}
	
	if(g_iLoseA[client]==1)
	{
		AddMenuItem(menutag, "op5","Loser");
	}
	else
	{
		AddMenuItem(menutag, "op5","Loser",ITEMDRAW_DISABLED);
	}
	
	if(g_iPlantA[client]==1)
	{
		AddMenuItem(menutag, "op6","Planter");
	}
	else
	{
		AddMenuItem(menutag, "op6","Planter",ITEMDRAW_DISABLED);
	}
	
	if(g_iDefuseA[client]==1)
	{
		AddMenuItem(menutag, "op7","Sapper");
	}
	else
	{
		AddMenuItem(menutag, "op7","Sapper",ITEMDRAW_DISABLED);
	}
	
	SetMenuExitButton(menutag, true);
	DisplayMenu(menutag, client, 30);
}

public MenuTagHand(Handle menu, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select && IsValidPlayer(client)) 
	{
		char info[255];
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		if(StrEqual(info, "op1"))
		{
			CS_SetClientClanTag(client, "[Killer]");
			g_iPlayerTag[client] = 1;
			Save(client);
		}
		if(StrEqual(info, "op2"))
		{
			CS_SetClientClanTag(client, "[HelpfulGuy]");
			g_iPlayerTag[client] = 2;
			Save(client);
		}
		if(StrEqual(info, "op3"))
		{
			CS_SetClientClanTag(client, "[Headhunter]");
			g_iPlayerTag[client] = 3;
			Save(client);
		}
		if(StrEqual(info, "op4"))
		{
			CS_SetClientClanTag(client, "[Winner]");
			g_iPlayerTag[client] = 4;
			Save(client);
		}
		if(StrEqual(info, "op5"))
		{
			CS_SetClientClanTag(client, "[Loser]");
			g_iPlayerTag[client] = 5;
			Save(client);
		}
		if(StrEqual(info, "op6"))
		{
			CS_SetClientClanTag(client, "[Planter]");
			g_iPlayerTag[client] = 6;
			Save(client);
		}
		if(StrEqual(info, "op7"))
		{
			CS_SetClientClanTag(client, "[Sapper]");
			g_iPlayerTag[client] = 7;
			Save(client);
		}
	}
}

public Action:OnChatMessage(&author, Handle:recipients, String:name[], String:message[]) 
{
	if(IsValidPlayer(author))
	{
		if(g_iPlayerTag[author]==1)
		{
			Format(name, MAXLENGTH_NAME, "%s", name);
			new MaxMessageLength = MAXLENGTH_MESSAGE - strlen(name) - 5; 
			Format(name, MaxMessageLength, " \x02[Killer] %s",name); 
			return Plugin_Changed;
		}
		else if(g_iPlayerTag[author]==2)
		{
			Format(name, MAXLENGTH_NAME, "%s", name);
			new MaxMessageLength = MAXLENGTH_MESSAGE - strlen(name) - 5; 
			Format(name, MaxMessageLength, " \x02[HelpfulGuy] %s",name); 
			return Plugin_Changed;
		}
		else if(g_iPlayerTag[author]==3)
		{
			Format(name, MAXLENGTH_NAME, "%s", name);
			new MaxMessageLength = MAXLENGTH_MESSAGE - strlen(name) - 5; 
			Format(name, MaxMessageLength, " \x02[Headhunter] %s",name); 
			return Plugin_Changed;
		}
		else if(g_iPlayerTag[author]==4)
		{
			Format(name, MAXLENGTH_NAME, "%s", name);
			new MaxMessageLength = MAXLENGTH_MESSAGE - strlen(name) - 5; 
			Format(name, MaxMessageLength, " \x02[Winner] %s",name); 
			return Plugin_Changed;
		}
		else if(g_iPlayerTag[author]==5)
		{
			Format(name, MAXLENGTH_NAME, "%s", name);
			new MaxMessageLength = MAXLENGTH_MESSAGE - strlen(name) - 5; 
			Format(name, MaxMessageLength, " \x02[Loser] %s",name); 
			return Plugin_Changed;
		}
		else if(g_iPlayerTag[author]==6)
		{
			Format(name, MAXLENGTH_NAME, "%s", name);
			new MaxMessageLength = MAXLENGTH_MESSAGE - strlen(name) - 5; 
			Format(name, MaxMessageLength, " \x02[Planter] %s",name); 
			return Plugin_Changed;
		}
		else if(g_iPlayerTag[author]==7)
		{
			Format(name, MAXLENGTH_NAME, "%s", name);
			new MaxMessageLength = MAXLENGTH_MESSAGE - strlen(name) - 5; 
			Format(name, MaxMessageLength, " \x02[Sapper] %s",name); 
			return Plugin_Changed;
		}
		else
		{
			Format(name, MAXLENGTH_NAME, "%s", name);
			new MaxMessageLength = MAXLENGTH_MESSAGE - strlen(name) - 5; 
			Format(name, MaxMessageLength, " %s",name); 
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action Player_Death(Handle event, char[] name2, bool dontBroadcast)
{
	
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int assister = GetClientOfUserId(GetEventInt(event, "assister"));
	bool headshot = GetEventBool(event, "headshot");
	
	if(IsValidPlayers() >= g_iPlayerOn.IntValue)
	{
		if(IsValidPlayer(attacker))
			{
				g_iKills[attacker] = g_iKills[attacker] + 1;
			Save(attacker);
		
			if(g_iKillsA[attacker]==0)
			{
				if(g_iKills[attacker]==g_iPlayerKills.IntValue)
				{
					g_iKillsA[attacker] = 1;
					sound(attacker);
					ClientCommand(attacker, "r_screenoverlay overlays/achievements/killer");
					CreateTimer(3.0, offover, attacker);
					Save(attacker);
					PrintToChatAll(" \x04Player \x02%N \x04gets achievement: \x02Killer \x04!", attacker);
				}
			}
		}
	
		if(IsValidPlayer(assister))
		{
			g_iAssists[assister] = g_iAssists[assister] + 1;
			Save(assister);
			
			if(g_iAssistsA[assister]==0)
			{
				if(g_iAssists[assister]==g_iPlayerAssists.IntValue)
				{
					g_iAssistsA[assister] = 1;
					sound(assister);
					ClientCommand(assister, "r_screenoverlay overlays/achievements/help");
					CreateTimer(3.0, offover, assister);
					Save(assister);
					PrintToChatAll(" \x04Player \x02%N \x04gets achievement: \x02Helpful guy \x04!", assister);
				}
			}
		}
		
		if(headshot)
		{
			if(IsValidPlayer(attacker))
			{
				g_iHeadshots[attacker] = g_iHeadshots[attacker] + 1;
				Save(attacker);
			
				if(g_iHeadshotsA[attacker]==0)
				{
					if(g_iHeadshots[attacker]==g_iPlayerHeadshots.IntValue)
					{
						g_iHeadshotsA[attacker] = 1;
						sound(attacker);
						ClientCommand(attacker, "r_screenoverlay overlays/achievements/head");
						CreateTimer(3.0, offover, attacker);
						Save(attacker);
						PrintToChatAll(" \x04Player \x02%N \x04gets achievement: \x02Headhunter \x04!", attacker);
					}
				}
			}
		}	
	}
	
}

public BombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsValidPlayers() >= g_iPlayerOn.IntValue)
	{
		if(IsValidPlayer(userid))
		{
			g_iPlant[userid] = g_iPlant[userid] + 1;
			Save(userid);
			
			if(g_iPlantA[userid]==0)
			{
				if(g_iPlant[userid]==g_iPlayerPlant.IntValue)
				{
					g_iPlantA[userid] = 1;
					sound(userid);
					ClientCommand(userid, "r_screenoverlay overlays/achievements/planter");
					CreateTimer(3.0, offover, userid);
					Save(userid);
					PrintToChatAll(" \x04Player \x02%N \x04gets achievement: \x02Planter \x04!", userid);
				}
			}
		}
	}
}

public BombDefused(Handle:event, const String:name[], bool:dontBroadcast)
{
    new userid = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if(IsValidPlayers() >= g_iPlayerOn.IntValue)
    {
		if(IsValidPlayer(userid))
		{
			g_iDefuse[userid] = g_iDefuse[userid] + 1;
				Save(userid);
			
			if(g_iDefuseA[userid]==0)
			{
				if(g_iDefuse[userid]==g_iPlayerDefuse.IntValue)
				{
					g_iDefuseA[userid] = 1;
					sound(userid);
					ClientCommand(userid, "r_screenoverlay overlays/achievements/sapper");
					CreateTimer(3.0, offover, userid);
					Save(userid);
					PrintToChatAll(" \x04Player \x02%N \x04gets achievement: \x02Sapper \x04!", userid);
				}
			}
		}
	}
}

public Round_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(IsValidPlayers() >= g_iPlayerOn.IntValue)
	{
		new wygrana_druzyna = GetEventInt(event, "winner");
		for(new i = 1; i <= MaxClients; i ++)
		{
				if(!IsClientInGame(i))
			continue;
	
			if(GetClientTeam(i) != ((wygrana_druzyna == 2)? CS_TEAM_T: CS_TEAM_CT))
			{
				
				if(IsValidPlayer(i))
				{
					g_iLose[i] = g_iLose[i] + 1;
					Save(i);
			
					if(g_iLoseA[i]==0)
					{
						if(g_iLose[i]==g_iPlayerLose.IntValue)
						{
							g_iLoseA[i] = 1;
							sound(i);
							ClientCommand(i, "r_screenoverlay overlays/achievements/loser");
							CreateTimer(3.0, offover, i);
							Save(i);
								PrintToChatAll(" \x04Player \x02%N \x04gets achievement: \x02Loser \x04!", i);
						}
					}
				}
			}
			else
				{
				if(IsValidPlayer(i))
				{
					g_iWin[i] = g_iWin[i] + 1;
					Save(i);
			
					if(g_iWinA[i]==0)
					{
						if(g_iWin[i]==g_iPlayerWin.IntValue)
						{
							g_iWinA[i] = 1;
							sound(i);
							ClientCommand(i, "r_screenoverlay overlays/achievements/winner");
							CreateTimer(3.0, offover, i);
							Save(i);
							PrintToChatAll(" \x04Player \x02%N \x04gets achievement: \x02Winner \x04!", i);
						}
					}
				}
			}
		}
	}
}

public Action:offover(Handle:timer, any:client)
{
    if(IsValidPlayer(client))
    {
   		ClientCommand(client, "r_screenoverlay \"\"");
   	}
}

public void ConnectSQL()
{
	if(g_hSQL != null)
	{
		CloseHandle(g_hSQL);
	}

	if(SQL_CheckConfig("achievements"))
	{
		char _cError[255];

		if(!(g_hSQL = SQL_Connect("achievements", true, _cError, 255)))
		{
			if(g_iPolaczenia < 5)
			{
				g_iPolaczenia++;
				LogError("ERROR: %s", _cError);
				ConnectSQL();
				
				return;
			}
			g_iPolaczenia=0;
		}
	}
	
	new Handle:queryH = SQL_Query(g_hSQL, "CREATE TABLE IF NOT EXISTS `Players` ( `STEAMID64` VARCHAR(128) NOT NULL , `name` VARCHAR(128) NOT NULL , `killq` INT(11) NOT NULL , `assist` INT(11) NOT NULL , `head` INT(11) NOT NULL , `win` INT(11) NOT NULL , `lose` INT(11) NOT NULL , `plant` INT(11) NOT NULL , `defuse` INT(11) NOT NULL , `killa` INT(11) NOT NULL , `assista` INT(11) NOT NULL , `heada` INT(11) NOT NULL , `wina` INT(11) NOT NULL , `losea` INT(11) NOT NULL , `planta` INT(11) NOT NULL , `defusea` INT(11) NOT NULL , `tag` INT(11) NOT NULL)");
    if(queryH != INVALID_HANDLE)
    {
        PrintToServer("Succesfully create database.");
    }
    else
    {
        SQL_GetError(g_hSQL, Error, sizeof(Error));
        PrintToServer("Database wasn't created. Error: %s",Error); 
    }
}

public void Load(int client)
{
	
	if(!IsValidPlayer(client))
	return;
	
	if(!g_hSQL)
	{
		ConnectSQL();
		Load(client);
		return;
	}
	

	char _cBuffer[1024];
	char _cSteamID64[64];
	char s_name[64];
	
	GetClientAuthId(client, AuthId_SteamID64, _cSteamID64, sizeof(_cSteamID64));
	Format(_cBuffer,sizeof(_cBuffer),"SELECT * FROM Players WHERE STEAMID64 = '%s'",_cSteamID64);
	GetClientName(client, s_name, sizeof(s_name));

	Handle _HQuery = SQL_Query(g_hSQL, _cBuffer);	
	
	if (_HQuery != INVALID_HANDLE)
	{
	
		bool _bFetch=SQL_FetchRow(_HQuery);
		if(_bFetch)
		{
			Format(_cSteamID64,sizeof(_cSteamID64),"");	
			SQL_FetchString(_HQuery, 0, _cSteamID64, 63);
			
			Format(s_name,sizeof(s_name),"");	
			SQL_FetchString(_HQuery, 1, s_name, 64);
			
			g_iKills[client]=SQL_FetchInt(_HQuery,2);
			g_iAssists[client]=SQL_FetchInt(_HQuery,3);
			g_iHeadshots[client]=SQL_FetchInt(_HQuery,4);
			g_iWin[client]=SQL_FetchInt(_HQuery,5);
			g_iLose[client]=SQL_FetchInt(_HQuery,6);
			g_iPlant[client]=SQL_FetchInt(_HQuery,7);
			g_iDefuse[client]=SQL_FetchInt(_HQuery,8);
			g_iKillsA[client]=SQL_FetchInt(_HQuery,9);
			g_iAssistsA[client]=SQL_FetchInt(_HQuery,10);
			g_iHeadshotsA[client]=SQL_FetchInt(_HQuery,11);
			g_iWinA[client]=SQL_FetchInt(_HQuery,12);
			g_iLoseA[client]=SQL_FetchInt(_HQuery,13);
			g_iPlantA[client]=SQL_FetchInt(_HQuery,14);
			g_iDefuseA[client]=SQL_FetchInt(_HQuery,15);
			g_iPlayerTag[client]=SQL_FetchInt(_HQuery,16);
			
			if(_cSteamID64[0])
			{
				g_bPlayerWczytane[client]=true;
			}
			
			CloseHandle(_HQuery);
			return;
		}
	}
	
	CloseHandle(_HQuery);
	Format(_cBuffer,sizeof(_cBuffer),"INSERT IGNORE INTO Players VALUES ('%s', '%s','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0')",_cSteamID64,s_name);
	
	SQL_Query(g_hSQL, _cBuffer);
	Load(client);
}

public void Save(int client)
{
	if(!IsValidPlayer(client))
	return;
	
	if(!g_hSQL)
	{
		ConnectSQL();
		return;
	}
	
	char _cBuffer[1024];
	char _cSteamID64[64];
	
	GetClientAuthId(client, AuthId_SteamID64, _cSteamID64, sizeof(_cSteamID64));
	
		
	Format(_cBuffer,sizeof(_cBuffer),"UPDATE Players SET  killq=%i, assist=%i, head=%i, win=%i, lose=%i, plant=%i, defuse=%i, killa=%i, assista=%i, heada=%i, wina=%i, losea=%i, planta=%i, defusea=%i, tag=%i  WHERE STEAMID64 = '%s'",g_iKills[client],g_iAssists[client],g_iHeadshots[client],g_iWin[client],g_iLose[client],g_iPlant[client],g_iDefuse[client],g_iKillsA[client],g_iAssistsA[client],g_iHeadshotsA[client],g_iWinA[client],g_iLoseA[client],g_iPlantA[client],g_iDefuseA[client],g_iPlayerTag[client],_cSteamID64);

	SQL_Query(g_hSQL, _cBuffer);	

}

stock AddFolderToDownloadsTable(const String:sDirectory[])
{
	decl String:sFile[64], String:sPath[512];
	new FileType:iType, Handle:hDir = OpenDirectory(sDirectory);
	while(ReadDirEntry(hDir, sFile, sizeof(sFile), iType))     
	{
		if(iType == FileType_File)
		{
			Format(sPath, sizeof(sPath), "%s/%s", sDirectory, sFile);
			AddFileToDownloadsTable(sPath);
		}
	}
}

public IsValidPlayers()
{
    new players;
    for(new i = 1; i <= MaxClients; i ++)
    {
        if(!IsClientInGame(i) || IsFakeClient(i))
            continue;

        players ++;
    }

    return players;
}

stock bool IsValidPlayer(int client)
{
    if(client >= 1 && client <= MaxClients && IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client) )
    return true;

    return false;
}