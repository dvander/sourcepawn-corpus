/*  SM FPVMI - Custom Weapons Menu
 *
 *  Copyright (C) 2017 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <fpvm_interface>
#include <multicolors>

#pragma newdecls required

#define DATA "3.2.1"
#define MAXENTITIES 2048 

char sConfig[PLATFORM_MAX_PATH];
Handle kv, db, array_weapons;

//Spawn Message Cvar
Handle cvarcwmspawnmsg = INVALID_HANDLE;

char client_w[MAXPLAYERS+1];
int client_id[MAXPLAYERS+1];

Handle menu_cw;

char sql_buffer[3096];

bool ismysql;

// Sound
char sWeaponModel[64][MAXPLAYERS+1];
char sWeaponSoundStar[MAXENTITIES+1][PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name = "SM FPVMI - Custom Weapons Menu",
	author = "Franc1sco franug & Romeo",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
}

public void OnPluginStart()
{
	CreateConVar("sm_customweaponsmenu_version", DATA, "plugin info", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	//Spawn Messege
	cvarcwmspawnmsg = CreateConVar("sm_customweaponsmenu_spawnmsg", "0", "Enable or Disable Spawnmessages");
	
	RegConsoleCmd("sm_cw", Command_cw);
	RegAdminCmd("sm_reloadcw", ReloadSkins, ADMFLAG_ROOT);
	
	LoadTranslations("franug_cwm.phrases");
	LoadTranslations("common.phrases");
	
	HookEvent("player_spawn", PlayerSpawn);
	
	RefreshKV();
	ComprobarDB(true);
	
	// HSound
	AddTempEntHook("Shotgun Shot", EventPlayerShoot);
	AddNormalSoundHook(OnNormalSoundHook);
}

public Action ReloadSkins(int client, int args)
{	
	RefreshKV();
	ComprobarDB(true);
	CReplyToCommand(client, "\x04[CW]\x01 %T","Custom Weapons Menu configuration reloaded", client);
	
	return Plugin_Handled;
}

void ComprobarDB(bool reconnect = false, char basedatos[64] = "customweapons")
{
	if(reconnect)
	{
		if(db != INVALID_HANDLE)
		{
			//LogMessage("Reconnecting DB connection");
			CloseHandle(db);
			db = INVALID_HANDLE;
		}
	}
	else if(db != INVALID_HANDLE)
	{
		return;
	}

	if(!SQL_CheckConfig( basedatos ))
	{
		if(StrEqual(basedatos, "storage-local")) SetFailState("Databases not found");
		else 
		{
			//base = "clientprefs";
			ComprobarDB(true,"storage-local");
		}
		
		return;
	}
	SQL_TConnect(OnSqlConnect, basedatos);
}

public void OnSqlConnect(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Database failure: %s", error);
		
		SetFailState("Databases dont work");
	}
	else
	{
		db = hndl;
		
		SQL_GetDriverIdent(SQL_ReadDriver(db), sql_buffer, sizeof(sql_buffer));
		ismysql = StrEqual(sql_buffer,"mysql", false) ? true : false;
	
		if(ismysql)
		{
			Format(sql_buffer, sizeof(sql_buffer), "CREATE TABLE IF NOT EXISTS `customweapons` (`playername` varchar(128) NOT NULL, `steamid` varchar(32) NOT NULL,`last_accountuse` int(64) NOT NULL, `id` INT( 11 ) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY)");

			SQL_TQuery(db, tbasicoC, sql_buffer);

		}
		else
		{
			Format(sql_buffer, sizeof(sql_buffer), "CREATE TABLE IF NOT EXISTS customweapons (playername varchar(128) NOT NULL, steamid varchar(32) NOT NULL,last_accountuse int(64) NOT NULL, id INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL)");
		
			SQL_TQuery(db, tbasicoC, sql_buffer);
		}
	}
}

public void OnMapStart()
{
	Downloads();
}

// Show Spawn Message
public Action PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	// Get Client
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(GetClientTeam(client) == 1 && !IsPlayerAlive(client))
	{
		return;
	}
	
	// Check Convar & Spawnmsg
	if(GetConVarInt(cvarcwmspawnmsg) == 1)
	{	
		CPrintToChat(client," \x04[CW]\x01 %T","spawnmsg", client);
	}
}

public void RefreshKV()
{
	BuildPath(Path_SM, sConfig, PLATFORM_MAX_PATH, "configs/franug_cwm/configuration.txt");
	
	if(kv != INVALID_HANDLE) CloseHandle(kv);
	
	kv = CreateKeyValues("CustomModels");
	FileToKeyValues(kv, sConfig);
}

void Downloads()
{
	char imFile[PLATFORM_MAX_PATH];
	char line[192];
	
	BuildPath(Path_SM, imFile, sizeof(imFile), "configs/franug_cwm/downloads.txt");
	
	Handle file = OpenFile(imFile, "r");
	
	if(file != INVALID_HANDLE)
	{
		while (!IsEndOfFile(file))
		{
			if(!ReadFileLine(file, line, sizeof(line)))
			{
				break;
			}
			
			TrimString(line);
			if(strlen(line) > 0 && FileExists(line))
			{
				AddFileToDownloadsTable(line);
			}
		}

		CloseHandle(file);
	}
	else
	{
		LogError("[SM] no file found for downloads (configs/franug_cwm/downloads.txt)");
	}
}

public Action Command_cw(int client, int args)
{	
	SetMenuTitle(menu_cw, "Custom Weapons Menu v%s\n%T", DATA,"Select a weapon", client);
	DisplayMenu(menu_cw, client, 0);
	return Plugin_Handled;
}

public int Menu_Handler(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{

			char item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			Format(client_w[client], 64, "weapon_%s", item);
			
			KvJumpToKey(kv, client_w[client]);
			
			char temp[64];
			Menu menu_weapons = new Menu(Menu_Handler2);
			SetMenuTitle(menu_weapons, "%T", "Select a custom view model", client);
			AddMenuItem(menu_weapons, "default", "Default model");
			if(KvGotoFirstSubKey(kv))
			{
				do
				{
					KvGetSectionName(kv, temp, 64);
					AddMenuItem(menu_weapons, temp, temp);
			
				} while (KvGotoNextKey(kv));
			}
			KvRewind(kv);
			SetMenuExitBackButton(menu_weapons, true);
			DisplayMenu(menu_weapons, client, 0);
		}
	}
}

public int Menu_Handler2(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			if(StrEqual(item, "default"))
			{
				FPVMI_SetClientModel(client, client_w[client], -1, -1);
				CPrintToChat(client, " \x04[CW]\x01 %T","Now you have the default weapon model", client);
				Format(sql_buffer, sizeof(sql_buffer), "UPDATE %s SET saved = 'default' WHERE id = '%i';", client_w[client],client_id[client]);
				SQL_TQuery(db, tbasico, sql_buffer);
				Command_cw(client, 0);
				
				// Remove attack sound
				CreateTimer(0.11, TimerRemoveSound, client);
				
				return;
			}
			KvJumpToKey(kv, client_w[client]);
			KvJumpToKey(kv, item);
			
			char cwmodel[PLATFORM_MAX_PATH], cwmodel2[PLATFORM_MAX_PATH], cwmodel3[PLATFORM_MAX_PATH];
			KvGetString(kv, "model", cwmodel, PLATFORM_MAX_PATH, "none");
			KvGetString(kv, "worldmodel", cwmodel2, PLATFORM_MAX_PATH, "none");
			KvGetString(kv, "dropmodel", cwmodel3, PLATFORM_MAX_PATH, "none");
			if(StrEqual(cwmodel, "none") && StrEqual(cwmodel2, "none") && StrEqual(cwmodel3, "none"))
			{
				CPrintToChat(client, " \x04[CW]\x01 %T","Invalid configuration for this model", client);
			}
			else
			{
				char flag[8];
				KvGetString(kv, "flag", flag, 8, "");
				if(HasPermission(client, flag))
				{
					FPVMI_SetClientModel(client, client_w[client], !StrEqual(cwmodel, "none")?PrecacheModel(cwmodel):-1, !StrEqual(cwmodel2, "none")?PrecacheModel(cwmodel2):-1, cwmodel3);
					CPrintToChat(client, " \x04[CW]\x01 %T","Now you have a custom weapon model in",client, client_w[client]);
					
					
					Format(sql_buffer, sizeof(sql_buffer), "UPDATE %s SET saved = '%s' WHERE id = '%i';", client_w[client],item,client_id[client]);
					SQL_TQuery(db, tbasico, sql_buffer);
					
					// Get sound
					int weaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
					if(weaponIndex == -1) return;
					char sWeaponClass[32];
					GetEdictClassname(weaponIndex, sWeaponClass, sizeof(sWeaponClass));
	
					Format(sql_buffer, sizeof(sql_buffer), "SELECT saved FROM %s WHERE id = '%i'", sWeaponClass, client_id[client]);
					SQL_TQuery(db, FetchWeaponModel, sql_buffer, (GetClientUserId(client)*10000));
					
					DataPack pack;
					CreateDataTimer(0.1, TimerGetSound, pack);
					WritePackCell(pack, client);
					WritePackCell(pack, weaponIndex);
				}
				else
				{
					CPrintToChat(client, " \x04[CW]\x01 %T","You dont have access to use this weapon model", client);
				}
				Command_cw(client, 0);
			}
			KvRewind(kv);
		}
		case MenuAction_Cancel:
		{
			if(param2==MenuCancel_ExitBack)
			{
				Command_cw(client, 0);
			}
		}
		case MenuAction_End:
		{
			//param1 is MenuEnd reason, if canceled param2 is MenuCancel reason
			CloseHandle(menu);
		}
	}
}

stock bool HasPermission(int iClient, char[] flagString) 
{
	if(StrEqual(flagString, "")) 
	{
		return true;
	}
	
	AdminId admin = GetUserAdmin(iClient);
	
	if(admin != INVALID_ADMIN_ID)
	{
		int count, found, flags = ReadFlagString(flagString);
		for (int i = 0; i <= 20; i++) 
		{
			if(flags & (1<<i)) 
			{
				count++;
				
				if(GetAdminFlag(admin, view_as<AdminFlag>(i))) 
				{
					found++;
				}
			}
		}

		if(count == found)
		{
			return true;
		}
	}

	return false;
} 

public void OnClientPostAdminCheck(int client)
{
	client_id[client] = 0;
	
	if(!IsFakeClient(client)) CheckSteamID(client);
	
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponEquip);
}

public void OnClientDisconnect(int client)
{
	if(!IsFakeClient(client)) SaveCookies(client);
	
	client_id[client] = 0;
}

void CheckSteamID(int client)
{
	char query[255], steamid[32];
	GetClientAuthId(client, AuthId_Steam2,  steamid, sizeof(steamid) );
	
	Format(query, sizeof(query), "SELECT id FROM customweapons WHERE steamid = '%s'", steamid);
	SQL_TQuery(db, T_CheckSteamID, query, GetClientUserId(client));
}

public void T_CheckSteamID(Handle owner, Handle hndl, const char[] error, any data)
{
	int client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
	if(hndl == INVALID_HANDLE)
	{
		LogError("Query failure: %s", error);
		return;
	}

	if(!SQL_GetRowCount(hndl) || !SQL_FetchRow(hndl)) 
	{
		Nuevo(client);
		return;
	}
	
	client_id[client] = SQL_FetchInt(hndl, 0);
	
	char items[64];
	for(int i=0;i<GetArraySize(array_weapons);++i)
	{
		GetArrayString(array_weapons, i, items, 64);
		Format(sql_buffer, sizeof(sql_buffer), "SELECT saved FROM %s WHERE id = '%i'", items, client_id[client]);
		SQL_TQuery(db, tbasico6, sql_buffer, (GetClientUserId(client)*10000)+i);
	}
	
	//PrintToServer("pasado con id %i", client_id[client]);
}

void Nuevo(int client)
{
	char query[255], steamid[32];
	GetClientAuthId(client, AuthId_Steam2,  steamid, sizeof(steamid) );
	int userid = GetClientUserId(client);
	
	char Name[MAX_NAME_LENGTH+1];
	char SafeName[(sizeof(Name)*2)+1];
	if(!GetClientName(client, Name, sizeof(Name)))
	{
		Format(SafeName, sizeof(SafeName), "<noname>");
	}
	else
	{
		TrimString(Name);
		SQL_EscapeString(db, Name, SafeName, sizeof(SafeName));
	}
		
	Format(query, sizeof(query), "INSERT INTO customweapons(playername, steamid, last_accountuse) VALUES('%s', '%s', '%d');", SafeName, steamid, GetTime());
	SQL_TQuery(db, tbasico3, query, userid);
}

public void tbasico3(Handle owner, Handle hndl, const char [] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Query failure: %s", error);
		return;
	}
	int client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2,  steamid, sizeof(steamid) );
	
	Format(sql_buffer, sizeof(sql_buffer), "SELECT id FROM customweapons WHERE steamid = '%s';", steamid);
	SQL_TQuery(db, tbasico4, sql_buffer, GetClientUserId(client));
}

public void tbasicoC(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Query failure: %s", error);
		return;
	}
	//LogMessage("Database connection successful");
	
	if(array_weapons != INVALID_HANDLE) CloseHandle(array_weapons);
	array_weapons = CreateArray(64);
	
	char temp[64];
	menu_cw = new Menu(Menu_Handler);
	
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			KvGetSectionName(kv, temp, 64);
			
			if (ismysql) Format(sql_buffer, sizeof(sql_buffer), "CREATE TABLE IF NOT EXISTS `%s` (`id` int(11),`saved` varchar(128),PRIMARY KEY  (`id`))", temp);
			else Format(sql_buffer, sizeof(sql_buffer), "CREATE TABLE IF NOT EXISTS %s (id int(11),saved varchar(128),PRIMARY KEY  (id))", temp);
			SQL_TQuery(db, tbasico, sql_buffer);
			PushArrayString(array_weapons, temp);
			ReplaceString(temp, 64, "weapon_", "");
			AddMenuItem(menu_cw, temp, temp);
			
		} while (KvGotoNextKey(kv));
	}
	KvRewind(kv);
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			OnClientPostAdminCheck(client);
		}
	}
}

public void tbasico(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Query failure: %s", error);
	}
}

public void tbasico4(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Query failure: %s", error);
		return;
	}
	int client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
	
	if(!SQL_GetRowCount(hndl) || !SQL_FetchRow(hndl)) 
	{
		return;
	}
	char items[64];
	client_id[client] = SQL_FetchInt(hndl, 0);
	//PrintToServer("guardando");
	for(int i=0;i<GetArraySize(array_weapons);++i)
	{
		GetArrayString(array_weapons, i, items, 64);
		Format(sql_buffer, sizeof(sql_buffer), "INSERT INTO %s(id, saved) VALUES('%i', 'default');", items,client_id[client]);
		SQL_TQuery(db, tbasico, sql_buffer);
	}
}

public void tbasico6(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Query failure: %s", error);
		return;
	}
	
	int userid = data/10000;
	int weapon = (data-(userid*10000));
	int client = GetClientOfUserId(userid);
	//PrintToServer("valor %i y %i del total de %i",weapon, client, data);
	
	/* Make sure the client didn't disconnect while the thread was running */
	if(client == 0)
	{
		return;
	}
	
	char items[64], item[64];
	GetArrayString(array_weapons, weapon, items, 64);
	if(!SQL_GetRowCount(hndl) || !SQL_FetchRow(hndl)) 
	{
		
		Format(sql_buffer, sizeof(sql_buffer), "INSERT INTO %s(id, saved) VALUES('%i', 'default');", items,client_id[client]);
		SQL_TQuery(db, tbasico, sql_buffer);
		return;
	}
	
	SQL_FetchString(hndl, 0, item, 64);
	//PrintToServer("salto a %s y despues a %s", items, item);
	KvJumpToKey(kv, items);
	KvJumpToKey(kv, item);
	char cwmodel[PLATFORM_MAX_PATH], cwmodel2[PLATFORM_MAX_PATH], cwmodel3[PLATFORM_MAX_PATH];
	KvGetString(kv, "model", cwmodel, PLATFORM_MAX_PATH, "none");
	KvGetString(kv, "worldmodel", cwmodel2, PLATFORM_MAX_PATH, "none");
	KvGetString(kv, "dropmodel", cwmodel3, PLATFORM_MAX_PATH, "none");
	
	char flag[8];
	KvGetString(kv, "flag", flag, 8, "");
	
	if(HasPermission(client, flag)) FPVMI_SetClientModel(client, items, !StrEqual(cwmodel, "none")?PrecacheModel(cwmodel):-1, !StrEqual(cwmodel2, "none")?PrecacheModel(cwmodel2):-1, cwmodel3);
	
	KvRewind(kv);
}

void SaveCookies(int client)
{
	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2,  steamid, sizeof(steamid) );
	char Name[MAX_NAME_LENGTH+1];
	char SafeName[(sizeof(Name)*2)+1];
	if(!GetClientName(client, Name, sizeof(Name)))
	{
		Format(SafeName, sizeof(SafeName), "<noname>");
	}
	else
	{
		TrimString(Name);
		SQL_EscapeString(db, Name, SafeName, sizeof(SafeName));
	}	

	char buffer[3096];
	Format(buffer, sizeof(buffer), "UPDATE customweapons SET last_accountuse = %d, playername = '%s' WHERE steamid = '%s';",GetTime(), SafeName,steamid);
	SQL_TQuery(db, tbasico, buffer);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////// Attack Sound Codes ////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////

public Action EventPlayerShoot(const char[] sTEName, const int[] iPlayers, int numClients, float flDelay) 
{ 
	int client = TE_ReadNum("m_iPlayer") + 1;
	
	if(client <= 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	
	int weaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if(!IsValidEdict(weaponIndex))
	{
		return Plugin_Continue;
	}
	
	if(!StrEqual(sWeaponSoundStar[weaponIndex], "none"))
	{
		EmitSoundToAll(sWeaponSoundStar[weaponIndex], weaponIndex, SNDCHAN_WEAPON, SNDLEVEL_NORMAL);
	}
	
	return Plugin_Continue;
}

public Action OnWeaponEquip(int client, int weaponIndex)
{
	char sWeaponClass[32];
	GetEdictClassname(weaponIndex, sWeaponClass, sizeof(sWeaponClass));
	
	Format(sql_buffer, sizeof(sql_buffer), "SELECT saved FROM %s WHERE id = '%i'", sWeaponClass, client_id[client]);
	SQL_TQuery(db, FetchWeaponModel, sql_buffer, (GetClientUserId(client)*10000));
	
	DataPack pack;
	CreateDataTimer(0.1, TimerGetSound, pack);
	WritePackCell(pack, client);
	WritePackCell(pack, weaponIndex);
}

public Action TimerGetSound(Handle timer, Handle pack)
{
	ResetPack(pack);
	
	int client = ReadPackCell(pack);
	int weaponIndex = ReadPackCell(pack);
	
	if(!IsValidEdict(weaponIndex))
	{
		return;
	}
	
	char flag[8];
	char sWeaponSound[PLATFORM_MAX_PATH];
	char sWeaponClass[32];
	GetEdictClassname(weaponIndex, sWeaponClass, sizeof(sWeaponClass));
	
	KvJumpToKey(kv, sWeaponClass);
	KvJumpToKey(kv, sWeaponModel[client]);
	KvGetString(kv, "sound", sWeaponSound, PLATFORM_MAX_PATH, "none");
	KvGetString(kv, "flag", flag, 8, "");
	
	if(HasPermission(client, flag) && !StrEqual(sWeaponModel[client], "default") && !StrEqual(sWeaponSound, "none"))
	{
		ReplaceStringEx(sWeaponSound, PLATFORM_MAX_PATH, "sound/", "", -1, -1, false);
		Format(sWeaponSoundStar[weaponIndex], sizeof(sWeaponSoundStar), "*%s", sWeaponSound);
		AddToStringTable(FindStringTable("soundprecache"), sWeaponSoundStar[weaponIndex]);
	}
	
	KvRewind(kv);
}

public void FetchWeaponModel(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		return;
	}
	
	int userid = data/10000;
	int client = GetClientOfUserId(userid);
	
	if(client == 0)
	{
		return;
	}
	
	if(!SQL_GetRowCount(hndl) || !SQL_FetchRow(hndl))
	{
		return;
	}
	
	SQL_FetchString(hndl, 0, sWeaponModel[client], 64);
}

public Action TimerRemoveSound(Handle timer, int client)
{
	int weaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(weaponIndex == -1) return;
	Format(sWeaponSoundStar[weaponIndex], sizeof(sWeaponSoundStar), "none");
}

public Action OnNormalSoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	if(IsValidEdict(entity))
	{
		if(!StrEqual(sWeaponSoundStar[entity], "none") && StrContains(sample, "knife") != -1)
		{
			EmitSoundToAll(sWeaponSoundStar[entity], entity, SNDCHAN_WEAPON, SNDLEVEL_NORMAL);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void OnEntityDestroyed(int entity)
{
	if(IsValidEdict(entity))
	{
		Format(sWeaponSoundStar[entity], sizeof(sWeaponSoundStar), "none");
	}
}