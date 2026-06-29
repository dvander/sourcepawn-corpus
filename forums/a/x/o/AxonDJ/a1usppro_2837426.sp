#pragma semicolon 1
#pragma newdecls required

#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

#define TAG "[SM]"

Database db = null;

bool	 BuyA1[MAXPLAYERS + 1], BuyUsp[MAXPLAYERS + 1], BuyR8[MAXPLAYERS + 1], BuyCz[MAXPLAYERS + 1], BuyMp5[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name		= "Change Buy Gun",
	author		= "Neko Channel,useduudm,ALTOVICIO",
	description 	= "custom buy option",
	version		= "V3.0 PRO",
	url		= "https://himeneko.cn/,https://github.com/useduudm/"
};

public void OnPluginStart()
{
	HookEventEx("player_spawn", OnPlayerSpawn);

	RegConsoleCmd("sm_inventary", Command_ChangeBuyMenu);

	CreateDatabase();
}

stock void CreateDatabase()
{
	char err[255];
	db = SQL_Connect("BuyWeapon", true, err, sizeof(err));
	if (db == null)
	{
		PrintToServer("[SM] Cannot connect to the database, error: %s", err);
	}
	else
	{
		if (!SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS buyweaponset (id VARCHAR(128) NOT NULL UNIQUE KEY, weapon_a1 VARCHAR(512) NOT NULL, weapon_r8 VARCHAR(512) NOT NULL, weapon_cz VARCHAR(512) NOT NULL, weapon_mp5 VARCHAR(512) NOT NULL, weapon_usp VARCHAR(512) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8;"))
		{
			SQL_GetError(db, err, sizeof(err));
			PrintToServer("[SM] Failed to create the table, error: %s", err);
		}
		else
		{
			PrintToServer("[SM] Table has created if not existed.");
		}
	}
}

stock void GetClientWeaponBool(int client)
{
	DBResultSet hQuery = null;
	char		Query[128], SteamAuth[32], tmp_geta1bool[1024], tmp_getuspbool[1024];
	GetClientAuthId(client, AuthId_Steam2, SteamAuth, sizeof(SteamAuth));

	Format(Query, sizeof(Query), "SELECT `weapon_a1`, `weapon_usp`, `weapon_r8`, `weapon_cz`, `weapon_mp5` FROM buyweaponset WHERE id LIKE '%s'", SteamAuth);
	hQuery = SQL_Query(db, Query);

	if (hQuery == null || !SQL_FetchRow(hQuery))
	{
		PrintToServer("[SM] Could not execute the query.");
		BuyUsp[client] = true;
		BuyA1[client]  = false;
		UpdateClientWeaponBool(client);
	}
	else
	{
		SQL_FetchString(hQuery, 0, tmp_geta1bool, sizeof tmp_geta1bool);
		SQL_FetchString(hQuery, 1, tmp_getuspbool, sizeof tmp_getuspbool);

		BuyA1[client]  = view_as<bool>(StringToInt(tmp_geta1bool));
		BuyUsp[client] = view_as<bool>(StringToInt(tmp_getuspbool));
	}

	delete hQuery;
}

stock bool UpdateClientWeaponBool(int client)
{
	char err[255], SteamAuth[32];
	GetClientAuthId(client, AuthId_Steam2, SteamAuth, sizeof(SteamAuth));
	if (db == null)
	{
		PrintToServer("[SM] Cannot connect to the database, error: %s", err);
		return false;
	}
	else
	{
		char Query[2048];
		Format(Query, sizeof(Query), "REPLACE INTO `buyweaponset` (id, weapon_a1, weapon_usp, weapon_r8, weapon_cz, weapon_mp5) VALUES ('%s', '%i', '%i', '%i', '%i', '%i')", SteamAuth, view_as<int>(BuyA1[client]), view_as<int>(BuyUsp[client]), view_as<int>(BuyR8[client]), view_as<int>(BuyCz[client]), view_as<int>(BuyMp5[client]));
		if (SQL_FastQuery(db, Query))
			return true;
		else
			return false;
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		GetClientWeaponBool(client);
	}
}

public Action Command_ChangeBuyMenu(int client, int args)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		ChangeBuyWeaponMenu(client);
	}
	return Plugin_Continue;
}

public Action Command_ChangeA1(int client, int args)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		BuyA1[client] = !BuyA1[client];
		UpdateClientWeaponBool(client);
		PrintToChat(client, "%s %s.", TAG, BuyA1[client] ? "a1" : "a4");
	}
	return Plugin_Continue;
}

public Action Command_ChangeR8(int client, int args)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		BuyR8[client] = !BuyR8[client];
		UpdateClientWeaponBool(client);
		PrintToChat(client, "%s %s.", TAG, BuyR8[client] ? "r8" : "deagle");
	}
	return Plugin_Continue;
}

public Action Command_ChangeCz(int client, int args)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		BuyCz[client] = !BuyCz[client];
		UpdateClientWeaponBool(client);
		PrintToChat(client, "%s %s.", TAG, BuyCz[client] ? "cz" : "cz75");
	}
	return Plugin_Continue;
}

public Action Command_ChangeMp5(int client, int args)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		BuyMp5[client] = !BuyMp5[client];
		UpdateClientWeaponBool(client);
		PrintToChat(client, "%s %s.", TAG, BuyMp5[client] ? "mp5" : "mp7");
	}
	return Plugin_Continue;
}

public Action Command_ChangeUsp(int client, int args)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		BuyUsp[client] = !BuyUsp[client];
		UpdateClientWeaponBool(client);
		PrintToChat(client, "%s %s.", TAG, BuyUsp[client] ? "usp" : "p2000");
	}
	return Plugin_Continue;
}

public void OnPlayerSpawn(Event eEvent, const char[] szName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(eEvent.GetInt("userid"));

	if (IsValidClient(client) && !IsFakeClient(client))
	{
		if (GetClientTeam(client) == CS_TEAM_CT && BuyUsp[client])
		{
			char szUSP[32];

			GetClientWeapon(client, szUSP, sizeof(szUSP));

			if (strcmp(szUSP, "weapon_hkp2000") == 0)
				CSGO_ReplaceWeapon(client, CS_SLOT_SECONDARY, "weapon_usp_silencer");
		}
	}
}

public Action CS_OnBuyCommand(int client, const char[] szWeapon)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && !IsFakeClient(client))
	{
		int iAccount = GetEntProp(client, Prop_Send, "m_iAccount");

		if (strcmp(szWeapon, "m4a1") == 0 && BuyA1[client])
		{
			if (iAccount >= CS_GetWeaponPrice(client, CSWeapon_M4A1_SILENCER))
			{
				CSGO_SetMoney(client, iAccount - CS_GetWeaponPrice(client, CSWeapon_M4A1_SILENCER));
				CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, "weapon_m4a1_silencer");
				return Plugin_Changed;
			}
			else
			{
				PrintHintText(client, "¿Qué estás comprando?");
			}
		}

		if (strcmp(szWeapon, "m4a1_silencer") == 0 && !BuyA1[client])
		{
			if (iAccount >= CS_GetWeaponPrice(client, CSWeapon_M4A1))
			{
				CSGO_SetMoney(client, iAccount - CS_GetWeaponPrice(client, CSWeapon_M4A1));
				CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, "weapon_m4a1");
				return Plugin_Changed;
			}
			else
			{
				PrintHintText(client, "¿Qué estás comprando?");
			}
		}

		if (strcmp(szWeapon, "hkp2000") == 0 && BuyUsp[client])
		{
			if (iAccount >= CS_GetWeaponPrice(client, CSWeapon_USP_SILENCER))
			{
				CSGO_SetMoney(client, iAccount - CS_GetWeaponPrice(client, CSWeapon_USP_SILENCER));
				CSGO_ReplaceWeapon(client, CS_SLOT_SECONDARY, "weapon_usp_silencer");
				return Plugin_Changed;
			}
			else
			{
				PrintHintText(client, "¿Qué estás comprando?");
			}
		}

		if (strcmp(szWeapon, "usp_silencer") == 0 && !BuyUsp[client])
		{
			if (iAccount >= CS_GetWeaponPrice(client, CSWeapon_HKP2000))
			{
				CSGO_SetMoney(client, iAccount - CS_GetWeaponPrice(client, CSWeapon_HKP2000));
				CSGO_ReplaceWeapon(client, CS_SLOT_SECONDARY, "weapon_hkp2000");
				return Plugin_Changed;
			}
			else
			{
				PrintHintText(client, "¿Qué estás comprando?");
			}
		}

		if (strcmp(szWeapon, "fiveseven") == 0 && BuyCz[client])
		{
			if (iAccount >= CS_GetWeaponPrice(client, CSWeapon_CZ75A))
			{
				CSGO_SetMoney(client, iAccount - CS_GetWeaponPrice(client, CSWeapon_CZ75A));
				CSGO_ReplaceWeapon(client, CS_SLOT_SECONDARY, "weapon_cz75a");
				return Plugin_Changed;
			}
			else
			{
				PrintHintText(client, "¿Qué estás comprando?");
			}
		}

		if (strcmp(szWeapon, "cz75a") == 0 && !BuyCz[client])
		{
			if (iAccount >= CS_GetWeaponPrice(client, CSWeapon_FIVESEVEN))
			{
				CSGO_SetMoney(client, iAccount - CS_GetWeaponPrice(client, CSWeapon_FIVESEVEN));
				CSGO_ReplaceWeapon(client, CS_SLOT_SECONDARY, "weapon_fiveseven");
				return Plugin_Changed;
			}
			else
			{
				PrintHintText(client, "¿Qué estás comprando?");
			}
		}

		if (strcmp(szWeapon, "tec9") == 0 && BuyCz[client])
		{
			if (iAccount >= CS_GetWeaponPrice(client, CSWeapon_CZ75A))
			{
				CSGO_SetMoney(client, iAccount - CS_GetWeaponPrice(client, CSWeapon_CZ75A));
				CSGO_ReplaceWeapon(client, CS_SLOT_SECONDARY, "weapon_cz75a");
				return Plugin_Changed;
			}
			else
			{
				PrintHintText(client, "¿Qué estás comprando?");
			}
		}

		if (strcmp(szWeapon, "cz75a") == 0 && !BuyCz[client])
		{
			if (iAccount >= CS_GetWeaponPrice(client, CSWeapon_TEC9))
			{
				CSGO_SetMoney(client, iAccount - CS_GetWeaponPrice(client, CSWeapon_TEC9));
				CSGO_ReplaceWeapon(client, CS_SLOT_SECONDARY, "weapon_tec9");
				return Plugin_Changed;
			}
			else
			{
				PrintHintText(client, "¿Qué estás comprando?");
			}
		}

		if (strcmp(szWeapon, "deagle") == 0 && BuyR8[client])
		{
			if (iAccount >= CS_GetWeaponPrice(client, CSWeapon_REVOLVER))
			{
				CSGO_SetMoney(client, iAccount - CS_GetWeaponPrice(client, CSWeapon_REVOLVER));
				CSGO_ReplaceWeapon(client, CS_SLOT_SECONDARY, "weapon_revolver");
				return Plugin_Changed;
			}
			else
			{
				PrintHintText(client, "¿Qué estás comprando?");
			}
		}

		if (strcmp(szWeapon, "revolver") == 0 && !BuyR8[client])
		{
			if (iAccount >= CS_GetWeaponPrice(client, CSWeapon_DEAGLE))
			{
				CSGO_SetMoney(client, iAccount - CS_GetWeaponPrice(client, CSWeapon_DEAGLE));
				CSGO_ReplaceWeapon(client, CS_SLOT_SECONDARY, "weapon_deagle");
				return Plugin_Changed;
			}
			else
			{
				PrintHintText(client, "¿Qué estás comprando?");
			}
		}

		if (strcmp(szWeapon, "mp7") == 0 && BuyMp5[client])
		{
			if (iAccount >= CS_GetWeaponPrice(client, CSWeapon_MP5NAVY))
			{
				CSGO_SetMoney(client, iAccount - CS_GetWeaponPrice(client, CSWeapon_MP5NAVY));
				CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, "weapon_mp5sd");
				return Plugin_Changed;
			}
			else
			{
				PrintHintText(client, "¿Qué estás comprando?");
			}
		}

		if (strcmp(szWeapon, "mp5sd") == 0 && !BuyMp5[client])
		{
			if (iAccount >= CS_GetWeaponPrice(client, CSWeapon_MP7))
			{
				CSGO_SetMoney(client, iAccount - CS_GetWeaponPrice(client, CSWeapon_MP7));
				CSGO_ReplaceWeapon(client, CS_SLOT_PRIMARY, "weapon_mp7");
				return Plugin_Changed;
			}
			else
			{
				PrintHintText(client, "¿Qué estás comprando?");
			}
		}
	}
	return Plugin_Continue;
}

public Action ChangeBuyWeaponMenu(int client)
{
	if (!IsValidClient(client))
		return Plugin_Continue;

	Menu WeaponMenu = new Menu(MenuHandler_ChangeBuyWeaponMenu);
	WeaponMenu.SetTitle("Inventory Menu");

	char line[1024];

	Format(line, sizeof(line), "%s", BuyUsp[client] ? "usp" : "p2000");
	WeaponMenu.AddItem("usp", line);
	Format(line, sizeof(line), "%s", BuyA1[client] ? "a1" : "a4");
	WeaponMenu.AddItem("a1", line);
	Format(line, sizeof(line), "%s", BuyCz[client] ? "cz75 " : "cz");
	WeaponMenu.AddItem("cz", line);
	Format(line, sizeof(line), "%s", BuyR8[client] ? "r8" : "deagle");
	WeaponMenu.AddItem("r8", line);
	Format(line, sizeof(line), "%s", BuyMp5[client] ? "mp5" : "mp7");
	WeaponMenu.AddItem("mp5", line);

	WeaponMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Continue;
}

public int MenuHandler_ChangeBuyWeaponMenu(Menu WeaponMenu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (IsValidClient(client))
			{
				char items[50];
				WeaponMenu.GetItem(itemNum, items, sizeof(items));
				if (StrEqual(items, "usp"))
				{
					BuyUsp[client] = !BuyUsp[client];
					PrintToChat(client, "%s %s.", TAG, BuyUsp[client] ? "usp" : "p2000");
				}
				if (StrEqual(items, "a1"))
				{
					BuyA1[client] = !BuyA1[client];
					PrintToChat(client, "%s %s.", TAG, BuyA1[client] ? "a1" : "a4");
				}
				if (StrEqual(items, "cz"))
				{
					BuyCz[client] = !BuyCz[client];
					PrintToChat(client, "%s %s.", TAG, BuyCz[client] ? "cz75" : "cz");
				}
				if (StrEqual(items, "r8"))
				{
					BuyR8[client] = !BuyR8[client];
					PrintToChat(client, "%s %s.", TAG, BuyR8[client] ? "r8" : "deagle");
				}
				if (StrEqual(items, "mp5"))
				{
					BuyMp5[client] = !BuyMp5[client];
					PrintToChat(client, "%s %s.", TAG, BuyMp5[client] ? "mp5" : "mp7");
				}
				UpdateClientWeaponBool(client);
			}
			ChangeBuyWeaponMenu(client);
		}
		case MenuAction_End:
		{
			delete WeaponMenu;
		}
	}
	return 0;
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

stock void CSGO_SetMoney(int client, int iAmount)
{
	if (iAmount < 0)
		iAmount = 0;

	int iMax = FindConVar("mp_maxmoney").IntValue;

	if (iAmount > iMax)
		iAmount = iMax;

	SetEntProp(client, Prop_Send, "m_iAccount", iAmount);
}

stock int CSGO_ReplaceWeapon(int client, int iSlot, const char[] szClass)
{
	int iWeapon = GetPlayerWeaponSlot(client, iSlot);

	if (IsValidEntity(iWeapon))
	{
		if (GetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity") != client)
			SetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity", client);

		CS_DropWeapon(client, iWeapon, false, true);
		RemoveEntity(iWeapon);
	}

	iWeapon = GivePlayerItem(client, szClass);

	if (IsValidEntity(iWeapon))
		EquipPlayerWeapon(client, iWeapon);

	return iWeapon;
}