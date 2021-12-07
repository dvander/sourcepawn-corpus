/*
*	Left 4 Dead Slots
*	Copyright (C) 2021 Accelerator
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*
*	Thanks:
*
*	Original L4DToolZ extension by ivailosp:	https://forums.alliedmods.net/showthread.php?t=93600
*	Code Patcher:					https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/code_patcher.sp
*
*/

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION		"1.1.0"

#define MAX_PATCH_SIZE 255
#define MAX_PATCH_NAME_LENGTH 63
#define MAX_VALUE_LENGTH (MAX_PATCH_SIZE*4)

#include <sourcemod>

ArrayList hPatchNames;
ArrayList hPatchAddresses;
ArrayList hPatchBytes;

GameData g_hGameConf;

bool bIsWindows;

static Address max_players_friend_lobby;
static Address human_limit;

static Address max_players_connect;
static Address max_players_server_browser;
static Address lobby_sux_ptr;
static Address unreserved_ptr;
static Address lobby_match_ptr;

ConVar l4dslots_version;
ConVar sv_maxplayers;
ConVar sv_removehumanlimit;
ConVar sv_force_unreserved;

public Plugin myinfo =
{
	name = "[L4D & L4D2] Left 4 Dead Slots",
	author = "Accelerator",
	description = "Unlock the max player limit on L4D and L4D2",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=333092"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_hGameConf = new GameData("l4dslots");
	if (g_hGameConf == null)
	{
		strcopy(error, err_max, "Failed to load gamedata/l4dslots.");
		return APLRes_SilentFailure;
	}

	bIsWindows = g_hGameConf.GetOffset("Platform") != 0;

	if (GetEngineVersion() == Engine_Left4Dead)
	{
		max_players_friend_lobby = g_hGameConf.GetAddress("friends_lobby");
		human_limit = g_hGameConf.GetAddress("human_limit");
	}

	max_players_connect = g_hGameConf.GetAddress("max_players");
	max_players_server_browser = g_hGameConf.GetAddress("server_bplayers");
	lobby_sux_ptr = g_hGameConf.GetAddress("lobby_sux");
	unreserved_ptr = g_hGameConf.GetAddress("unreserved");
	lobby_match_ptr = g_hGameConf.GetAddress("lobby_match");

	hPatchNames = new ArrayList(ByteCountToCells(MAX_PATCH_NAME_LENGTH+1));
	hPatchAddresses = new ArrayList();
	hPatchBytes = new ArrayList(ByteCountToCells(MAX_PATCH_SIZE+1));

	return APLRes_Success;
}

public void OnPluginStart()
{
	l4dslots_version = CreateConVar("l4dslots_version", PLUGIN_VERSION, "L4DSlots Version", FCVAR_REPLICATED|FCVAR_NOTIFY);

	sv_maxplayers = CreateConVar("sv_maxplayers", "-1", "Max Human Players", 0, true, -1.0, true, 18.0);
	sv_removehumanlimit = CreateConVar("sv_removehumanlimit", "0", "Remove Human limit reached kick", 0, true, 0.0, true, 1.0);
	sv_force_unreserved = CreateConVar("sv_force_unreserved", "0", "Disallow lobby reservation cookie", 0, true, 0.0, true, 1.0);

	sv_maxplayers.AddChangeHook(OnChangeMaxplayers);
	sv_removehumanlimit.AddChangeHook(OnChangeRemovehumanlimit);
	sv_force_unreserved.AddChangeHook(OnChangeUnreserved);

	if (sv_maxplayers.IntValue >= 0)
	{
		char sTemp[3];
		IntToString(sv_maxplayers.IntValue, sTemp, sizeof(sTemp));
		OnChangeMaxplayers(sv_maxplayers, "-1", sTemp);
	}
	if (sv_removehumanlimit.IntValue == 1) OnChangeRemovehumanlimit(sv_removehumanlimit, "0", "1");
	if (sv_force_unreserved.IntValue == 1) OnChangeUnreserved(sv_force_unreserved, "0", "1");
}

public void OnPluginEnd()
{
	int size = hPatchNames.Length;

	char name[MAX_PATCH_NAME_LENGTH+1];

	for (int i = size-1; i != -1; --i)
	{
		hPatchNames.GetString(i, name, sizeof(name));
		RevertPatch(name);
	}
}

public void OnChangeMaxplayers(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	if (max_players_connect == Address_Null || max_players_server_browser == Address_Null || lobby_sux_ptr == Address_Null)
	{
		LogError("sv_maxplayers init error");
		return;
	}

	int new_value = StringToInt(newVal);

	if (StringToInt(oldVal) == new_value) return;

	if (new_value >= 0)
	{
		if (GetEngineVersion() == Engine_Left4Dead)
		{
			if (max_players_friend_lobby == Address_Null)
			{
				LogError("sv_maxplayers init error");
				return;
			}

			ApplyPatchAddr(max_players_friend_lobby, "friends_lobby", new_value, 1);
		}

		if (lobby_match_ptr != Address_Null)
		{
			ApplyPatchAddr(lobby_match_ptr, "lobby_match", new_value, 0);
		}
		else
		{
			LogError("sv_maxplayers MS init error");
		}

		ApplyPatchAddr(max_players_connect, "max_players", new_value, 2);
		ApplyPatchAddr(lobby_sux_ptr, "lobby_sux");
		ApplyPatchAddr(max_players_server_browser, "server_bplayers", new_value, 1);
	}
	else
	{
		RevertPatch("friends_lobby");
		RevertPatch("lobby_match");
		RevertPatch("max_players");
		RevertPatch("lobby_sux");
		RevertPatch("server_bplayers");
	}
}

public void OnChangeRemovehumanlimit(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	if (GetEngineVersion() != Engine_Left4Dead) return;

	if (human_limit == Address_Null)
	{
		LogError("sv_removehumanlimit init error");
		return;
	}

	int new_value = StringToInt(newVal);

	if (StringToInt(oldVal) == new_value) return;

	if (new_value == 1)
	{
		ApplyPatchAddr(human_limit, "human_limit");
	}
	else
	{
		RevertPatch("human_limit");
	}
}

public void OnChangeUnreserved(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	if (unreserved_ptr == Address_Null)
	{
		LogError("unreserved_ptr init error");
		return;
	}

	int new_value = StringToInt(newVal);

	if (StringToInt(oldVal) == new_value) return;

	if (new_value == 1)
	{
		ApplyPatchAddr(unreserved_ptr, "unreserved");
		InsertServerCommand("sv_allow_lobby_connect_only 0");
	}
	else
	{
		RevertPatch("unreserved");
	}
}

stock void ApplyPatchAddr(Address addr, const char[] name, int data = 0xC3, int offs = -1)
{
	char key[MAX_PATCH_NAME_LENGTH+32];
	char value[MAX_VALUE_LENGTH+1];

	int offset = g_hGameConf.GetOffset(name);
	if (offset == -1)
	{
		LogError("Could not load offset '%s'", name);
		return;
	}

	Format(key, sizeof(key), "%s_len", name);
	if (!g_hGameConf.GetKeyValue(key, value, sizeof(value)))
	{
		Format(key, sizeof(key), "%s_len_%s", name, bIsWindows ? "w" : "l");
		if (!g_hGameConf.GetKeyValue(key, value, sizeof(value)))
		{
			LogError("Could not find key '%s'", key);
			return;
		}
	}

	int length = StringToInt(value);

	if (length < 1 || length > MAX_PATCH_SIZE)
	{
		PrintToServer("Too %s patch bytes for '%s'", length < 1 ? "few" : "many", name);
		return;
	}

	Format(key, sizeof(key), "%s_new", name);
	if (!g_hGameConf.GetKeyValue(key, value, sizeof(value)))
	{
		Format(key, sizeof(key), "%s_new_%s", name, bIsWindows ? "w" : "l");
		if (!g_hGameConf.GetKeyValue(key, value, sizeof(value)))
		{
			LogError("Could not find key '%s'", key);
			return;
		}
	}

	char[] bytes = new char[length];

	if (!ParseBytes(value, bytes, length, data, offs))
	{
		LogError("Failed to parse patch bytes for '%s'", name);
		return;
	}

	ApplyPatch(name, addr + view_as<Address>(offset), bytes, length);
}

// code_patcher
// https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/code_patcher.sp

static int GetPackedByte(int cell, int i)
{
	return (cell >> ((3-i)*8)) & 0xff;
}

static int SetPackedByte(int cell, int i, int byte)
{
	int mask = 0xff << ((3-i)*8);
	return (cell & ~mask) | (byte << ((3-i)*8));
}

static int GetBytes(ArrayList array, char[] bytes, int idx)
{
	int cell = array.Get(idx, 0);
	int count = GetPackedByte(cell, 0);
	int j = 0;

	for (int i = 1; i <= count; ++i)
	{
		if (i % 4 == 0)
			cell = array.Get(idx, i/4);

		bytes[j++] = GetPackedByte(cell, i % 4);
	}

	return count;
}

static void PushBytes(ArrayList array, char[] bytes, int count)
{
	int nCells = ByteCountToCells(count + 1);
	int[] cells = new int[nCells];

	cells[0] = SetPackedByte(cells[0], 0, count);

	int j = 0;

	for (int i = 1; i <= count; ++i)
	{
		if (i % 4 == 0)
			++j;

		cells[j] = SetPackedByte(cells[j], i % 4, bytes[i-1]);
	}

	array.PushArray(cells, nCells);
}

static bool ParseBytes(const char[] value, char[] bytes, int count, int data, int offs)
{
	int length = strlen(value);

	if (length != count * 4)
		return false;

	char hex[3];
	int j = 0;

	for (int i = 0; i < length; i += 4)
	{
		if (value[i] != '\\')
			return false;

		if (value[i+1] != 'x')
			return false;

		if (j == offs)
		{
			bytes[j++] = data & 0xff;
			continue;
		}

		hex[0] = value[i+2];
		hex[1] = value[i+3];
		hex[2] = 0;

		bytes[j++] = StringToInt(hex, 16);
	}

	return true;
}

static void WriteBytesToMemory(Address addr, const char[] bytes, int count)
{
	for (int i = 0; i < count; ++i)
		StoreToAddress(addr + view_as<Address>(i), bytes[i] & 0xff, NumberType_Int8);
}

static void ReadBytesFromMemory(Address addr, char[] bytes, int count)
{
	for (int i = 0; i < count; ++i)
		bytes[i] = view_as<char>(LoadFromAddress(addr + view_as<Address>(i), NumberType_Int8)) & 0xff;
}

static void ApplyPatch(const char[] name, Address addr, const char[] bytes, int length)
{
	char[] oldBytes = new char[length];

	ReadBytesFromMemory(addr, oldBytes, length);
	WriteBytesToMemory(addr, bytes, length);

	hPatchNames.PushString(name);
	hPatchAddresses.Push(addr);
	PushBytes(hPatchBytes, oldBytes, length);
}

static bool RevertPatch(const char[] name)
{
	int patchId = hPatchNames.FindString(name);

	if (patchId == -1)
		return false;

	char bytes[MAX_PATCH_SIZE];
	int count = GetBytes(hPatchBytes, bytes, patchId);

	Address addr = hPatchAddresses.Get(patchId);

	WriteBytesToMemory(addr, bytes, count);

	hPatchNames.Erase(patchId);
	hPatchAddresses.Erase(patchId);
	hPatchBytes.Erase(patchId);

	return true;
}
