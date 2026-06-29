/*
*	TempEnt Hooks - DevTools
*	Copyright (C) 2022 Silvers
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
*/



#define PLUGIN_VERSION 		"1.3"

/*=======================================================================================
	Plugin Info:

*	Name	:	[ANY] TempEnt Hooks - DevTools
*	Author	:	SilverShot
*	Descrp	:	Prints TempEnt data, with class filtering.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=319684
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.3 (11-Dec-2022)
	- Changes to fix compile warnings on SourceMod 1.11.

1.2 (30-Sep-2020)
	- Fixed compile errors on SM 1.11.

1.1 (10-May-2020)
	- Various changes to tidy up code.
	- Various optimizations and fixes.

1.0 (15-Nov-2019)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define CONFIG_TE_LIST		"data/tempent_hooks.cfg"
#define CONFIG_DUMP			"logs/tempent_hooks.log"

#define LEN_CLASS			32 // Max TempEnt name string length


ConVar g_hCvarFilter, g_hCvarListen, g_hCvarLogging;
ArrayList g_aTempArray, g_aHookedTempEnt, g_aFilter, g_aListen, g_aWatch;
StringMapSnapshot g_aTempEnts_Snap;
StringMap g_aTempEnts_List;
File g_hLogFile;
bool g_bWatch[MAXPLAYERS+1];
int g_iCvarLogging, g_iListening, g_iSection;

enum
{
	TYPE_array,
	TYPE_float,
	TYPE_int,
	TYPE_vector
}



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[ANY] TempEnt Hooks - DevTools",
	author = "SilverShot",
	description = "Prints TempEnt data, with classname filtering.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=319684"
}

public void OnPluginStart()
{
	// Arrays
	g_aFilter = new ArrayList(ByteCountToCells(LEN_CLASS));
	g_aListen = new ArrayList(ByteCountToCells(LEN_CLASS));
	g_aWatch = new ArrayList(ByteCountToCells(LEN_CLASS));
	g_aTempEnts_List = CreateTrie();
	g_aHookedTempEnt = CreateArray();

	// Cvars
	g_hCvarFilter = CreateConVar(	"sm_tempent_filter",		"Footprint Decal,Blood Stream",		"Do not hook and these TempEnts, separate by commas (no spaces). Only works for sm_te_listen command.", CVAR_FLAGS );
	g_hCvarListen = CreateConVar(	"sm_tempent_listen",		"",					"Only hook and display these TempEnts, separate by commas (no spaces). Only works for sm_te_listen command.", CVAR_FLAGS );
	g_hCvarLogging = CreateConVar(	"sm_tempent_logging",		"0",				"0=Off. 1=Log TempEnts data when listening.", CVAR_FLAGS );
	CreateConVar(					"sm_tempent_version",		PLUGIN_VERSION,		"TempEnt Hooks plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,			"tempent_hooks");

	g_hCvarFilter.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarListen.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarLogging.AddChangeHook(ConVarChanged_Cvars);

	GetCvars();

	// Commands
	RegAdminCmd("sm_te_listen",		CmdListen,					ADMFLAG_ROOT,	 	"Starts listening to all TempEnts. Filters or listens for TempEnts using the filter and listen cvars.");
	RegAdminCmd("sm_te_stop",		CmdStop,					ADMFLAG_ROOT,	 	"Stop printing TempEnts.");
	RegAdminCmd("sm_te_watch",		CmdWatch,					ADMFLAG_ROOT,	 	"Start printing TempEnts. Usage: sm_tempent_watch <TempEnt names to watch, separate by commas>");

	// TE config
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_TE_LIST);
	if( FileExists(sPath) == false )
	{
		ServerCommand("sm_dump_teprops %s", sPath);
	}

	// Hook
	CreateTimer(0.5, TimerHook); // Wait for list to be generated.
}

Action TimerHook(Handle timer)
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_TE_LIST);
	if( FileExists(sPath) )
	{
		ParseConfigFile(sPath);
	}

	if( g_aTempEnts_List.Size == 0 )
	{
		LogError("TempEnt list size 0.");
		return Plugin_Continue;
	}

	g_aTempEnts_Snap = g_aTempEnts_List.Snapshot();

	return Plugin_Continue;
}



// ====================================================================================================
// CVARS
// ====================================================================================================
void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	// Cvars
	g_iCvarLogging = g_hCvarLogging.IntValue;

	// Filters
	int pos, last;
	char sCvar[2048];
	g_aFilter.Clear();
	g_aListen.Clear();

	// Filter list
	g_hCvarFilter.GetString(sCvar, sizeof(sCvar));
	if( sCvar[0] != 0 )
	{
		StrCat(sCvar, sizeof(sCvar), ",");

		while( (pos = FindCharInString(sCvar[last], ',')) != -1 )
		{
			sCvar[pos + last] = 0;
			g_aFilter.PushString(sCvar[last]);
			last += pos + 1;
		}
	}

	// Listen list
	g_hCvarListen.GetString(sCvar, sizeof(sCvar));
	if( sCvar[0] != 0 )
	{
		StrCat(sCvar, sizeof(sCvar), ",");

		pos = 0;
		last = 0;
		while( (pos = FindCharInString(sCvar[last], ',')) != -1 )
		{
			sCvar[pos + last] = 0;
			g_aListen.PushString(sCvar[last]);
			last += pos + 1;
		}
	}
}



// ====================================================================================================
// COMMANDS
// ====================================================================================================
Action CmdListen(int client, int args)
{
	if( g_aTempEnts_List.Size == 0 )
	{
		ReplyToCommand(client, "TempEntHooks: 0 hooks detected. TE unsupported or server hibernating from start.");
		return Plugin_Handled;
	}

	g_bWatch[client] = true;

	if( g_iListening == 0 )
	{
		g_iListening = 1;
		ListenAll();
	}
	return Plugin_Handled;
}

Action CmdStop(int client, int args)
{
	if( g_aTempEnts_List.Size == 0 )
	{
		ReplyToCommand(client, "TempEntHooks: 0 hooks detected. TE unsupported or server hibernating from start.");
		return Plugin_Handled;
	}

	g_aWatch.Clear();
	g_bWatch[client] = false;
	g_iListening = 0;
	delete g_hLogFile;

	UnhookAll();
	return Plugin_Handled;
}

Action CmdWatch(int client, int args)
{
	if( g_aTempEnts_List.Size == 0 )
	{
		ReplyToCommand(client, "TempEntHooks: 0 hooks detected. TE unsupported or server hibernating from start.");
		return Plugin_Handled;
	}

	if( args != 1 )
	{
		ReplyToCommand(client, "Usage: sm_tempent_watch <TempEnt names to watch, separate by commas>");
		return Plugin_Handled;
	}

	// Watch list
	int pos, last;
	char sCvar[2048];
	GetCmdArg(1, sCvar, sizeof(sCvar));
	g_aWatch.Clear();

	if( sCvar[0] != 0 )
	{
		StrCat(sCvar, sizeof(sCvar), ",");

		while( (pos = FindCharInString(sCvar[last], ',')) != -1 )
		{
			sCvar[pos + last] = 0;
			g_aWatch.PushString(sCvar[last]);
			last += pos + 1;
		}
	}

	// Find
	g_bWatch[client] = true;
	g_iListening = 2;
	UnhookAll();
	ListenAll();
	return Plugin_Handled;
}

void ListenAll()
{
	char sTemp[LEN_CLASS];

	for( int i = 0; i < g_aTempEnts_Snap.Length; i++ )
	{
		if( g_aHookedTempEnt.FindValue(i) == -1 )
		{
			g_aTempEnts_Snap.GetKey(i, sTemp, sizeof(sTemp));

			if( g_iListening == 1 )
			{
				if( g_aFilter.Length != 0 && g_aFilter.FindString(sTemp) != -1 )		continue;
				if( g_aListen.Length != 0 && g_aListen.FindString(sTemp) == -1 )		continue;
			} else {
				if( g_aWatch.FindString(sTemp) == -1 )									continue;
			}

			AddTempEntHook(sTemp, Hooked_TempEnts);
			g_aHookedTempEnt.Push(i);
		}
	}
}

void UnhookAll()
{
	char sTemp[LEN_CLASS];

	for( int i = 0; i < g_aTempEnts_Snap.Length; i++ )
	{
		if( g_aHookedTempEnt.FindValue(i) != -1 )
		{
			g_aTempEnts_Snap.GetKey(i, sTemp, sizeof(sTemp));
			RemoveTempEntHook(sTemp, Hooked_TempEnts);
		}
	}

	g_aHookedTempEnt.Clear();
}

Action Hooked_TempEnts(const char[] te_name, const int[] Players, int numClients, float delay)
{
	ArrayList aHand;

	g_aTempEnts_List.GetValue(te_name, aHand);

	if( aHand != null )
	{
		int type;
		static float vVec[3];
		static char temp[LEN_CLASS];
		static char msg[512];
		msg[0] = 0;

		for( int i = 0; i < aHand.Length; i += 2 )
		{
			aHand.GetString(i, temp, sizeof(temp));
			type = aHand.Get(i + 1);

			switch( type )
			{
				case TYPE_array:
				{
					Format(msg, sizeof(msg), "%sUnsupported type: %d (%s) (%s)", msg, type, te_name, temp);
				}
				case TYPE_float:
				{
					Format(msg, sizeof(msg), "%s%s %f. ", msg, temp, TE_ReadFloat(temp));
				}
				case TYPE_int:
				{
					Format(msg, sizeof(msg), "%s%s %d. ", msg, temp, TE_ReadNum(temp));
				}
				case TYPE_vector:
				{
					TE_ReadVector(temp, vVec);
					Format(msg, sizeof(msg), "%s%s (%f, %f, %f). ", msg, temp, vVec[0], vVec[1], vVec[2]);
				}
			}
		}

		if( msg[0] == 0 ) return Plugin_Continue;
		msg[strlen(msg) - 1] = 0; // Remove last space



		// Logging - Dump
		if( g_iCvarLogging )
		{
			if( g_hLogFile == null )
			{
				char sPath[PLATFORM_MAX_PATH];
				BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_DUMP);
				g_hLogFile = OpenFile(sPath, "a", false);
			}

			WriteFileLine(g_hLogFile, "%s: %s", te_name, msg);
		}



		// Print
		for( int i = 0; i <= MaxClients; i++ )
		{
			if( g_bWatch[i] )
			{
				if( i )
				{
					if( IsClientInGame(i) && !IsFakeClient(i) )
					{
						// Format to 250 bytes due to TextMsg size limit:
						// "DLL_MessageEnd:  Refusing to send user message TextMsg of 256 bytes to client, user message size limit is 255 bytes"
						Format(msg, 250, "\x04TE: \x05%s\x01: %s", te_name, msg);
						PrintToChat(i, msg);
					}
					else
						g_bWatch[i] = false;
				}
				else
					PrintToServer("TE: %s: %s", te_name, msg);
			}
		}
	}

	return Plugin_Continue;
}

bool ParseConfigFile(const char[] file)
{
	SMCParser parser = new SMCParser();
	SMC_SetReaders(parser, Config_NewSection, Config_KeyValue, Config_EndSection);
	parser.OnEnd = Config_End;

	char error[128];
	int line = 0, col = 0;
	SMCError result = parser.ParseFile(file, line, col);

	if( result != SMCError_Okay )
	{
		parser.GetErrorString(result, error, sizeof(error));
		SetFailState("%s on line %d, col %d of %s [%d]", error, line, col, file, result);
	}

	delete parser;
	return (result == SMCError_Okay);
}

SMCResult Config_NewSection(Handle parser, const char[] section, bool quotes)
{
	g_iSection++;
	return SMCParse_Continue;
}

SMCResult Config_KeyValue(Handle parser, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	if( g_iSection == 2 && strcmp(key, "name") == 0 )
	{
		g_aTempArray = new ArrayList(LEN_CLASS);
		if( g_aTempEnts_List.SetValue(value, g_aTempArray) == false )
		{
			delete g_aTempArray;
		}
	}
	else if( g_iSection == 3 )
	{
		if( g_aTempArray != null )
		{
			g_aTempArray.PushString(key);
			if(			strcmp(value, "array") == 0 )	g_aTempArray.Push(TYPE_array);
			else if(	strcmp(value, "float") == 0 )	g_aTempArray.Push(TYPE_float);
			else if(	strcmp(value, "int") == 0 )		g_aTempArray.Push(TYPE_int);
			else if(	strcmp(value, "vector") == 0 )	g_aTempArray.Push(TYPE_vector);
		}
	}

	return SMCParse_Continue;
}

SMCResult Config_EndSection(Handle parser)
{
	g_iSection--;
	return SMCParse_Continue;
}

void Config_End(Handle parser, bool halted, bool failed)
{
	if( failed )
		SetFailState("Error: Cannot load the \"%s\" config.", CONFIG_TE_LIST);
}