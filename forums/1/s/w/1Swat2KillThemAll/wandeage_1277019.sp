/**
 * @file	wandeage.sp
 * @author	1Swat2KillThemAll
 *
 * @brief	WanDeage CS:S(OB) ServerSide Plugin - CORE
 * @version	1.000.000
 *
 * @todo	Test dynamically loading/unloading plugins, retest plugin, did some code refactoring =) (code readability ftw? ^^)
 *
 * WanDeage CS:S(OB) ServerSide Plugin - CORE
 * Copyright (C)/© 2010 B.D.A.K. Koch
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define WANDEAGE_INC_CORE_SHARED_ONLY
#include "wandeage.inc"

new ShotsFired[MAXPLAYERS+1][MAXPLAYERS+1],
	Handle:h_CvFile, String:CvFile[80],
    Handle:h_CvEnabled, CvEnabled,
    Handle:h_CvDebug = INVALID_HANDLE, CvDebug,
    Handle:h_CPrefSoundLevel, PrSoundLevel[MAXPLAYERS+1],
    Handle:h_WanDeageFwd, Handle:h_WanDeageCommandFwd, Handle:h_WanDeagePauseChangeFwd,
    Handle:h_ModNames, Handle:h_ModNamesPluginI,
    Handle:h_PrefNames, Handle:h_PrefNamesPluginI;

#define PLUGIN_NAME "WanDeage"
#define PLUGIN_AUTHOR "1Swat2KillThemAll"
#define PLUGIN_DESCRIPTION "WanDeage Core (Sound + Interface)"
#define PLUGIN_VERSION "1.000.000"
#define PLUGIN_URL "http://web.ccc-clan.com/wandeage/"
public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};
public __pl_wandeage_SetNTVOptional()
{
	MarkNativeAsOptional("HookWanDeage");
	MarkNativeAsOptional("HookWanDeageCommand");
	MarkNativeAsOptional("HookWanDeagePauseChange");
	MarkNativeAsOptional("AddWanDeageModules");
	MarkNativeAsOptional("AddWanDeagePref");
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("HookWanDeage", Native_HookWanDeage);
	CreateNative("HookWanDeageCommand", Native_HookWanDeageCommand);
	CreateNative("HookWanDeagePauseChange", Native_HookWanDeagePauseChange);
	CreateNative("AddWanDeageModules", Native_AddWanDeageModules);
	CreateNative("AddWanDeagePref", Native_AddWanDeagePref);

	return APLRes_Success;
}

public Native_HookWanDeage(Handle:plugin, numParams)
{
	AddToForward(h_WanDeageFwd, plugin, Function:GetNativeCell(1));
}
public Native_HookWanDeageCommand(Handle:plugin, numParams)
{
	AddToForward(h_WanDeageCommandFwd, plugin, Function:GetNativeCell(1));
}
public Native_HookWanDeagePauseChange(Handle:plugin, numParams)
{
	AddToForward(h_WanDeagePauseChangeFwd, plugin, Function:GetNativeCell(1));
}
public Native_AddWanDeageModules(Handle:plugin, numParams)
{
	decl length;
	GetNativeStringLength(1, length);

	if (length > 64)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "The Module's name is too long! Max size = 64");
	}

	decl String:buff[64];
	GetNativeString(1, buff, sizeof(buff));
	new index = FindStringInArray(h_ModNames, buff);

	if (GetNativeCell(2))
	{
		if (index == -1)
		{
			ThrowNativeError(SP_ERROR_NATIVE, "Can't find Module (%s)", buff);
		}

		RemoveFromArray(h_ModNames, index);
		RemoveFromArray(h_ModNamesPluginI, index);
	}
	else if (index == -1)
	{
		PushArrayString(h_ModNames, buff);
		PushArrayCell(h_ModNamesPluginI, plugin);
	}
}
public Native_AddWanDeagePref(Handle:plugin, numParams)
{
	decl length;
	GetNativeStringLength(1, length);

	if (length > 64)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "The Pref's Translation String is too long! Max size = 64");
	}

	decl String:buff[64];
	GetNativeString(1, buff, sizeof(buff));
	new index = FindStringInArray(h_PrefNames, buff);

	if (GetNativeCell(2))
	{
		if (index == -1)
		{
			ThrowNativeError(SP_ERROR_NATIVE, "Can't find Pref (%s)", buff);
		}

		RemoveFromArray(h_PrefNames, index);
		RemoveFromArray(h_PrefNamesPluginI, index);
	}
	else if (index == -1)
	{
		PushArrayString(h_PrefNames, buff);
		PushArrayCell(h_PrefNamesPluginI, plugin);
	}
}

public OnPluginStart()
{
	h_WanDeageFwd = CreateForward(ET_Event, Param_Cell, Param_Cell);
	h_WanDeageCommandFwd = CreateForward(ET_Hook, Param_Cell, Param_Cell, Param_String);
	h_WanDeagePauseChangeFwd = CreateForward(ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell); //ET_Single?
	RegPluginLibrary("wandeage");

	HookEvents();

	CreateConVar("sm_wandeage_version", PLUGIN_VERSION, "WanDeage Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	h_CvFile = CreateConVar("sm_wandeage_file", "misc/wandeage.wav", "Sets what sound file to play when somebody is WanDeage'd.", FCVAR_DONTRECORD);
	h_CvEnabled = CreateConVar("sm_wandeage_enabled", "1", "Sets whether WanDeage should be enabled.", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	CvEnabled = true;
	HookConVarChange(h_CvEnabled, OnConVarChanged);
	h_CvDebug = CreateConVar("sm_wandeage_debug", "0", "Debug Mode.", FCVAR_DONTRECORD, true, 0.0, true, 5.0);
	CvDebug = 0;
	HookConVarChange(h_CvDebug, OnConVarChanged);
	AutoExecConfig(true, PLUGIN_NAME);

	RegConsoleCmd("sm_wandeage", Sm_WanDeage, "¡WanDeage Message!");

	h_CPrefSoundLevel = RegClientCookie("sm_wandeage_disabled", "Determines the sound level of the WanDeage sound (-1 = muted).", CookieAccess_Protected);

	LoadTranslations("wandeage.phrases");
	LoadTranslations("common.phrases");

	h_ModNames = CreateArray(64);
	PushArrayString(h_ModNames, "Core");
	h_ModNamesPluginI = CreateArray();
	PushArrayCell(h_ModNamesPluginI, INVALID_HANDLE);
	h_PrefNames = CreateArray(64);
	PushArrayString(h_PrefNames, "ChangeSoundLevel");
	h_PrefNamesPluginI = CreateArray();
	PushArrayCell(h_PrefNamesPluginI, INVALID_HANDLE);
}
public OnPluginEnd()
{
	//UnhookEvents();
	CloseHandle(h_CPrefSoundLevel);
}
public OnPluginPauseChange(bool:pause)
{
	Call_StartForward(h_WanDeagePauseChangeFwd);
	Call_PushCell(pause);
	Call_Finish();
}
public OnMapStart()
{
	GetConVarString(h_CvFile, CvFile, 80);

	if (!PrecacheSound(CvFile, false))
	{
		LogError("Couldn't cache the soundfile!");
	}

	decl String:Buffer[80];
	Format(Buffer, sizeof(Buffer), "sound/%s", CvFile);
	AddFileToDownloadsTable(Buffer);
}
public OnClientPostAdminCheck(client)
{
	for (new i = 0; i <= MaxClients; i++)
	{
		ShotsFired[client][i] = 0;
	}
}
public OnClientCookiesCached(client)
{
	decl String:buffer[3];
	GetClientCookie(client, h_CPrefSoundLevel, buffer, sizeof(buffer));
	PrSoundLevel[client] = StringToInt(buffer);

	if (!PrSoundLevel[client])
	{
		PrSoundLevel[client] = SNDLEVEL_NORMAL;
	}
}

public OnConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (cvar == h_CvEnabled)
	{
		CvEnabled = StringToInt(newVal);

		if (CvEnabled)
		{
			HookEvents();
		}
		else
		{
			UnhookEvents();
		}
	}
	else if (cvar == h_CvDebug)
	{
#if defined DEBUG
		if (StringToInt(newVal) != 5)
		{
			SetConVarInt(h_CvDebug, 5);
		}
#else
		new newVali;

		if ((newVali = StringToInt(newVal)) < 5 && newVali >= 0)
		{
			CvDebug = newVali;
		}
		else
		{
			SetConVarInt(h_CvDebug, StringToInt(oldVal));
		}
#endif //DEBUG
	}
}

HookEvents()
{
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}
UnhookEvents()
{
	UnhookEvent("player_death", Event_PlayerDeath);
	UnhookEvent("player_hurt", Event_PlayerHurt);
	UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CvEnabled && GetEventBool(event, "headshot"))
	{
		decl String:weapon[64];
		GetEventString(event, "weapon", weapon, sizeof(weapon));

		if (StrEqual(weapon, "deagle"))
		{
			new uid_client = GetEventInt(event, "attacker"),
				uid_victim = GetEventInt(event, "userid"),
				client = GetClientOfUserId(uid_client),
				victim = GetClientOfUserId(uid_victim);

			if (ShotsFired[client][victim] <= 2)
			{
				Call_StartForward(h_WanDeageFwd);
				Call_PushCell(uid_client);
				Call_PushCell(uid_victim);
				Call_Finish();

				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i))
					{
						decl String:attacker_name[MAX_NAME_LENGTH],
							String:victim_name[MAX_NAME_LENGTH],
							String:buffer[((MAX_NAME_LENGTH) * 2) + 12];
						GetClientName(client, attacker_name, sizeof(attacker_name));
						GetClientName(victim, victim_name, sizeof(victim_name));
						Format(buffer, sizeof(buffer), "%s WanDeage'd %s", attacker_name, victim_name);

						if (PrSoundLevel[i] != -1)
						{
							EmitSoundToClient(i, CvFile, _, _, PrSoundLevel[i]);

							if (i != victim)
							{
								PrintCenterText(i, buffer);
							}
							else
							{
								PrintCenterText(i, "^^ ¡WanDeage! MoFo =D ^^");
							}
						}
					}
				}
			}
		}
	}
}
public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CvEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "attacker"));
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		ShotsFired[client][victim]++;
	}
}
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CvEnabled)
	{
		for (new i = 0; i <= MaxClients; i++)
		{
			for (new j = 0; j <= MaxClients; j++)
			{
				ShotsFired[i][j] = 0;
			}
		}
	}
}

public Action:Sm_WanDeage(client, args)
{
	if (CvEnabled)
	{
		decl String:buff[32];

		if (args == 0)
		{
			new Handle:panel = CreatePanel();
			Format(buff, sizeof(buff), "%t", "WanDeage", client);
			SetPanelTitle(panel, buff);
			Format(buff, sizeof(buff), "%t", "Preferences", client);
			DrawPanelItem(panel, buff);
			Format(buff, sizeof(buff), "%t", "Information", client);
			DrawPanelItem(panel, buff);
			DrawPanelText(panel, " ");
			Format(buff, sizeof(buff), "%t", "Exit", client);
			DrawPanelItem(panel, buff);
			SendPanelToClient(panel, client, SmWandeageHandler, 20);
			CloseHandle(panel);
		}

		if (args >= 1)
		{
			decl String:buffer[64];
			GetCmdArgString(buffer, sizeof(buffer));
			Call_StartForward(h_WanDeageCommandFwd);
			Call_PushCell(client);
			Call_PushCell(args);
			Call_PushString(buffer);
			Call_Finish();
		}
	}

	return Plugin_Handled;
}
public SmWandeageHandler(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction_Select)
	{
		switch (param)
		{
			case 1:
			{
				PreferenceMenu(client);
			}
			case 2:
			{
				InformationMenu(client);
			}
		}
	}
}
PreferenceMenu(client)
{
	new Handle:menu = CreateMenu(PreferenceMenuHandler);
	SetMenuTitle(menu, "%T", "Preferences", client);

	new count = GetArraySize(h_PrefNames);
	decl String:buff[64],
		String:buff2[64],
		String:buffer[3];

	for (new i = 0; i < count; i++)
	{
		GetArrayString(h_PrefNames, i, buff, sizeof(buff));
		IntToString(i, buffer, sizeof(buffer));
		Format(buff2, sizeof(buff2), "%T", buff, client);
		AddMenuItem(menu, buffer, buff2);
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public PreferenceMenuHandler(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction_Select)
	{
		new pref = -1;
		decl String:buff[4];
		GetMenuItem(menu, param, buff, sizeof(buff));

		for (new i = 0; i < 4; i++)
		{
			if (buff[i] == '\0')
			{
				break;
			}

			if (!IsCharNumeric(buff[i]))
			{
				return;
			}
		}

		pref = StringToInt(buff);

		if (pref == 0)
		{
			SndLvlPrefPanel(client);
		}
		else
		{
			new Handle:plugin = GetArrayCell(h_PrefNamesPluginI, pref);
			decl String:buffer[64];
			GetArrayString(h_PrefNames, pref, buffer, sizeof(buffer));
			Call_StartFunction(plugin, GetFunctionByName(plugin, "WdPrefMenuHandler"));
			Call_PushString(buff);
			Call_PushCell(client);
			Call_Finish();
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
SndLvlPrefPanel(client)
{
	new Handle:panel = CreatePanel();
	decl String:buff[128];

	Format(buff, sizeof(buff), "%T", "SoundLevelTitle", client, PrSoundLevel[client]);
	SetPanelTitle(panel, buff);
#if defined PRECISE_SOUND_LEVELS
	Format(buff, sizeof(buff), "%T", "SoundLevelPlus1", client);
	DrawPanelItem(panel, buff);
	Format(buff, sizeof(buff), "%T", "SoundLevelMin1", client);
	DrawPanelItem(panel, buff);
	DrawPanelText(panel, " ");
	Format(buff, sizeof(buff), "%T", "SoundLevelPlus10", client);
	DrawPanelItem(panel, buff);
	Format(buff, sizeof(buff), "%T", "SoundLevelMin10", client);
	DrawPanelItem(panel, buff);
	DrawPanelText(panel, " ");
	Format(buff, sizeof(buff), "%T", "SoundLevelMute", client);
	DrawPanelItem(panel, buff);
#else
	Format(buff, sizeof(buff), "%T", "SoundLevelQuiet", client);
	DrawPanelItem(panel, buff);
	Format(buff, sizeof(buff), "%T", "SoundLevelNormal", client);
	DrawPanelItem(panel, buff);
	Format(buff, sizeof(buff), "%T", "SoundLevelLoud", client);
	DrawPanelItem(panel, buff);
	DrawPanelText(panel, " ");
	Format(buff, sizeof(buff), "%T", "SoundLevelMute", client);
	DrawPanelItem(panel, buff);
#endif //PRECISE_SOUND_LEVELS
	DrawPanelText(panel, " ");
	Format(buff, sizeof(buff), "%t", "Exit", client);
	DrawPanelItem(panel, buff);

	SendPanelToClient(panel, client, SndLvlPrefPHandler, MENU_TIME_FOREVER);
	CloseHandle(panel);
}
public SndLvlPrefPHandler(Handle:panel, MenuAction:action, client, param)
{
	if (action == MenuAction_Select)
	{
		switch (param)
		{
#if defined PRECISE_SOUND_LEVELS
			case 1:
			{
				if (PrSoundLevel[client] < 180)
				{
					PrSoundLevel[client]++;
				}
			}
			case 2:
			{
				if (PrSoundLevel[client] > 1)
				{
					PrSoundLevel[client]--;
				}
			}
			case 3:
			{
				if (PrSoundLevel[client] <= 170)
				{
					PrSoundLevel[client] += 10;
				}
			}
			case 4:
			{
				if (PrSoundLevel[client] >= 11)
				{
					PrSoundLevel[client] -= 10;
				}
			}
			case 5:
			{
				SoundLevel[client] = -1;
			}
#else
			case 1:
			{
				PrSoundLevel[client] = SNDLEVEL_LIBRARY;
			}
			case 2:
			{
				PrSoundLevel[client] = SNDLEVEL_NORMAL;
			}
			case 3:
			{
				PrSoundLevel[client] = 100;
			}
			case 4:
			{
				PrSoundLevel[client] = -1;
			}
#endif //PRECISE_SOUND_LEVELS
		}

#if defined PRECISE_SOUND_LEVELS
		if (param != 6)
		{
			SndLvlPrefPanel(client);
		}
#else
		if (param != 5)
		{
			SndLvlPrefPanel(client);
		}
#endif //PRECISE_SOUND_LEVELS
		else
		{
			decl String:buff[8];
			IntToString(PrSoundLevel[client], buff, sizeof(buff));
			SetClientCookie(client, h_CPrefSoundLevel, buff);
		}
	}
}
InformationMenu(client)
{
	new Handle:menu = CreateMenu(InformationMenuHandler);
	SetMenuTitle(menu, "Loaded Modules:");

	new count = GetArraySize(h_ModNames);
	decl String:buff[64],
		String:buffer[3];

	for (new i = 0; i < count; i++)
	{
		GetArrayString(h_ModNames, i, buff, sizeof(buff));
		IntToString(i, buffer, sizeof(buffer));
		AddMenuItem(menu, buffer, buff);
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public InformationMenuHandler(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction_Select)
	{
		new module = -1;
		decl String:buff[4];
		GetMenuItem(menu, param, buff, sizeof(buff));

		for (new i = 0; i < 4; i++)
		{
			if (buff[i] == '\0')
			{
				break;
			}

			if (!IsCharNumeric(buff[i]))
			{
				return;
			}
		}

		module = StringToInt(buff);

		if (module == 0)
		{
			CoreMenu(client);
		}
		else
		{
			new Handle:plugin = GetArrayCell(h_ModNamesPluginI, module);
			Call_StartFunction(plugin, GetFunctionByName(plugin, "WdInfoMenuHandler"));
			Call_PushCell(client);
			Call_Finish();
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
CoreMenu(client)
{
	new Handle:menu = CreateMenu(CoreMenuHandler);
	SetMenuTitle(menu, "%T", "CodedBy", client, "1Swat2KillThemAll");
	AddMenuItem(menu, "0", "!wandeage [<command>]");
	AddMenuItem(menu, "1", "license");

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public CoreMenuHandler(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction_Select)
	{
		if (param != 1)
		{
			return;
		}

		PrintToChat(client, "%t", "CheckConsole", YELLOW, LIGHTGREEN, YELLOW);

		for (new i = 0; i < GNUGPLV3_MAX; i++)
		{
			PrintToConsole(client, GnuGplV3[i]);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
