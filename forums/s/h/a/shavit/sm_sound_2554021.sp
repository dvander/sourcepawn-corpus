/*
 * sm_sound
 * by: shavit
 *
 * This file is part of sm_sound.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
*/

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#tryinclude <soundscapehook>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

bool gB_MusicDisabled[MAXPLAYERS+1];
Handle gH_SoundCookie_Music = null;

bool gB_Nightcore = false;

public Plugin myinfo =
{
	name = "[CS:GO] sm_sound",
	author = "shavit",
	description = "Sound menu",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/member.php?u=163134"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(late)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				OnClientCookiesCached(i);
			}
		}
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	gH_SoundCookie_Music = RegClientCookie("sm_sound_stopmusic", "Stop all map music", CookieAccess_Protected);

	RegConsoleCmd("sm_sound", Command_Sound, "Opens the sound menu");
	RegAdminCmd("sm_nightcore", Command_Nightcore, ADMFLAG_RCON, "NIGHTCORE.");

	AddAmbientSoundHook(AmbientSoundHook);
}

public void OnMapStart()
{
	gB_Nightcore = false;
}

public void OnClientCookiesCached(int client)
{
	char[] sMusicCookie = new char[4];
	GetClientCookie(client, gH_SoundCookie_Music, sMusicCookie, 4);

	if(strlen(sMusicCookie) == 0)
	{
		SetClientCookie(client, gH_SoundCookie_Music, "0");
		gB_MusicDisabled[client] = false;
	}

	else
	{
		gB_MusicDisabled[client] = view_as<bool>(StringToInt(sMusicCookie));
	}
}

public Action Command_Sound(int client, int args)
{
	if(client == 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}

	return OpenSoundMenu(client);
}

public Action Command_Nightcore(int client, int args)
{
	gB_Nightcore = !gB_Nightcore;

	ShowActivity(client, "Nightcore %s", gB_Nightcore? "on":"off");

	return Plugin_Handled;
}

public Action OpenSoundMenu(int client)
{
	if(!AreClientCookiesCached(client))
	{
		PrintToChat(client, "[SM] Something is wrong, try again later.");

		return Plugin_Handled;
	}

	Menu m = new Menu(MenuHandler_SoundMenu);
	m.SetTitle("Sound menu:");

	char[] sFormat = new char[32];
	FormatEx(sFormat, 32, "[%s] Disable map music", gB_MusicDisabled[client]? "x":" ");
	m.AddItem("mapmusic", sFormat);

	m.ExitButton = true;

	m.Display(client, 20);

	return Plugin_Handled;
}

public int MenuHandler_SoundMenu(Menu m, MenuAction a, int p1, int p2)
{
	if(a == MenuAction_Select)
	{
		char[] sInfo = new char[16];
		m.GetItem(p2, sInfo, 16);

		if(StrEqual(sInfo, "mapmusic"))
		{
			gB_MusicDisabled[p1] = !gB_MusicDisabled[p1];
			SetClientCookie(p1, gH_SoundCookie_Music, gB_MusicDisabled[p1]? "1":"0");

			PrintToChat(p1, " \x04[SM]\x01 Map music %s\x01.", gB_MusicDisabled[p1]? "\x02disabled":"\x05enabled");

			if(gB_MusicDisabled[p1])
			{
				ClientCommand(p1, "snd_playsounds Music.StopAllExceptMusic");
			}
		}

		OpenSoundMenu(p1);
	}

	else if(a == MenuAction_End)
	{
		delete m;
	}

	return 0;
}

public Action AmbientSoundHook(char sample[PLATFORM_MAX_PATH], int &entity, float &volume, int &level, int &pitch, float pos[3], int &flags, float &delay)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(gB_MusicDisabled[i] && IsClientConnected(i) && IsClientInGame(i))
		{
			ClientCommand(i, "snd_playsounds Music.StopAllExceptMusic");
		}
	}

	if(gB_Nightcore)
	{
		pitch = 255;

		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public Action SoundscapeUpdateForPlayer(int entity, int client)
{
	if(gB_MusicDisabled[client] && entity != INVALID_ENT_REFERENCE && IsValidEntity(entity))
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
