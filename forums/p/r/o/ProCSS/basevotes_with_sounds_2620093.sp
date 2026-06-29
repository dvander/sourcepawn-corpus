/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod Basic Votes Plugin
 * Implements basic vote commands.
 *
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
 * =============================================================================
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
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#pragma semicolon 1

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <sdktools>
#include <colors>
#include <clientprefs>
#include <cstrike>

//SoundLib Optional
#undef REQUIRE_EXTENSIONS
#include <soundlib>
bool soundLib;
#pragma newdecls required
#define PLUGIN_VERSION ""


#define VOTE_NO "###no###"
#define VOTE_YES "###yes###"

Menu g_hVoteMenu = null;

ConVar g_Cvar_Limits[3] = {null, ...};
//ConVar g_Cvar_VoteSay = null;

enum voteType
{
	map,
	kick,
	ban,
	question
}

voteType g_voteType = question;

// Menu API does not provide us with a way to pass multiple peices of data with a single
// choice, so some globals are used to hold stuff.
//
int g_voteTarget;		/* Holds the target's user id */

#define VOTE_NAME	0
#define VOTE_AUTHID	1
#define	VOTE_IP		2
char g_voteInfo[3][65];	/* Holds the target's name, authid, and IP */

char g_voteArg[256];	/* Used to hold ban/kick reasons or vote questions */


TopMenu hTopMenu;

#include "basevotes/votekick.sp"
#include "basevotes/voteban.sp"
#include "basevotes/votemap.sp"

//MapSounds Stuff
int g_iSoundEnts[2048];
int g_iNumSounds;

//Cvars
Handle g_hCTPath;
Handle g_hTRPath;
Handle g_hPlayType;
Handle g_AbNeRCookie;
Handle g_hStop;
Handle g_playToTheEnd;
Handle g_roundDrawPlay;

bool SoundsTRSucess = false;
bool SoundsCTSucess = false;
bool SamePath = false;
bool CSGO;
ArrayList ctSound;
ArrayList trSound;


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("GetSoundLengthFloat");
	MarkNativeAsOptional("OpenSoundFile");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("basevotes.phrases");
	LoadTranslations("plugin.basecommands");
	LoadTranslations("basebans.phrases");
	
	RegAdminCmd("sm_votemap", Command_Votemap, ADMFLAG_KICK, "sm_votemap <mapname> [mapname2] ... [mapname5] ");
	
	
	RegAdminCmd("sm_vote", Command_Vote, ADMFLAG_KICK, "sm_vote <question> [Answer1] [Answer2] ... [Answer5]");

	/*
	g_Cvar_Show = FindConVar("sm_vote_show");
	if (g_Cvar_Show == null)
	{
		g_Cvar_Show = CreateConVar("sm_vote_show", "0", "Show player's votes? Default on.", 0, true, 0.0, true, 1.0);
	}
	*/

	g_Cvar_Limits[0] = CreateConVar("sm_vote_map", "0.60", "percent required for successful map vote.", 0, true, 0.05, true, 1.0);
	g_Cvar_Limits[1] = CreateConVar("sm_vote_kick", "0.60", "percent required for successful kick vote.", 0, true, 0.05, true, 1.0);	
	g_Cvar_Limits[2] = CreateConVar("sm_vote_ban", "0.60", "percent required for successful ban vote.", 0, true, 0.05, true, 1.0);		
soundLib = (GetFeatureStatus(FeatureType_Native, "GetSoundLengthFloat") == FeatureStatus_Available);
	
	//Cvars
	CreateConVar("abner_res_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY|FCVAR_REPLICATED);
	g_hTRPath = CreateConVar("res_tr_path", "basevotes", "Path off tr sounds in /cstrike/sound");
	g_hCTPath = CreateConVar("res_ct_path", "basevotes", "Path off ct sounds in /cstrike/sound");
	g_hPlayType = CreateConVar("res_play_type", "1", "1 - Random, 2- Play in queue");
	g_hStop = CreateConVar("res_stop_map_music", "0", "Stop map musics");	
	g_playToTheEnd = CreateConVar("res_play_to_the_end", "1", "Play sounds to the end.");
	g_roundDrawPlay = CreateConVar("res_rounddraw_play", "0", "0 - Don´t play sounds, 1 - Play TR sounds, 2 - Play CT sounds.");
		
	//ClientPrefs
	g_AbNeRCookie = RegClientCookie("AbNeR Round End Sounds", "", CookieAccess_Private);
	SetCookieMenuItem(SoundCookieHandler, 0, "AbNeR Round End Sounds");
	
	
	LoadTranslations("abner_res.phrases");
		
	AutoExecConfig(true, "abner_res");

	RegAdminCmd("res_refresh", CommandLoad, ADMFLAG_SLAY);
	RegConsoleCmd("res", abnermenu);
	
	HookConVarChange(g_hTRPath, PathChange);
	HookConVarChange(g_hCTPath, PathChange);
	HookConVarChange(g_hPlayType, PathChange);
	
	char theFolder[40];
	GetGameFolderName(theFolder, sizeof(theFolder));
	CSGO = StrEqual(theFolder, "csgo");
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	ctSound = new ArrayList(128);
	trSound = new ArrayList(128);
	
	
	/* Account for late loading */
	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(topmenu);
	}
	
	g_SelectedMaps = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
	
	g_MapList = new Menu(MenuHandler_Map, MenuAction_DrawItem|MenuAction_Display);
	g_MapList.SetTitle("%T", "Please select a map", LANG_SERVER);
	g_MapList.ExitBackButton = true;
	
	char mapListPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, mapListPath, sizeof(mapListPath), "configs/adminmenu_maplist.ini");
	SetMapListCompatBind("sm_votemap menu", mapListPath);
}

public void OnConfigsExecuted()
{
	g_mapCount = LoadMapList(g_MapList);
}

public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	/* Save the Handle */
	hTopMenu = topmenu;
	
	/* Build the "Voting Commands" category */
	TopMenuObject voting_commands = hTopMenu.FindCategory(ADMINMENU_VOTINGCOMMANDS);

	if (voting_commands != INVALID_TOPMENUOBJECT)
	{
		
		
		hTopMenu.AddItem("sm_votemap", AdminMenu_VoteMap, voting_commands, "sm_votemap", ADMFLAG_KICK);
	}
}

public Action Command_Vote(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_vote <question> [Answer1] [Answer2] ... [Answer5]");
		return Plugin_Handled;	
	}
	
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[SM] %t", "Vote in Progress");
		return Plugin_Handled;
	}
		
	if (!TestVoteDelay(client))
	{
		return Plugin_Handled;
	}
	
	char text[256];
	GetCmdArgString(text, sizeof(text));

	char answers[5][64];
	int answerCount;	
	int len = BreakString(text, g_voteArg, sizeof(g_voteArg));
	int pos = len;
	
	while (args > 1 && pos != -1 && answerCount < 5)
	{	
		pos = BreakString(text[len], answers[answerCount], sizeof(answers[]));
		answerCount++;
		
		if (pos != -1)
		{
			len += pos;
		}	
	}

	LogAction(client, -1, "\"%L\" initiated a generic vote.", client);
	ShowActivity2(client, "[SM] ", "%t", "Initiate Vote", g_voteArg);
	
	g_voteType = question;
	
	g_hVoteMenu = new Menu(Handler_VoteCallback, MENU_ACTIONS_ALL);
	g_hVoteMenu.SetTitle("%s?", g_voteArg);
	
	if (answerCount < 2)
	{
		g_hVoteMenu.AddItem(VOTE_YES, "da");
		g_hVoteMenu.AddItem(VOTE_NO, "nu");
	}
	else
	{
		for (int i = 0; i < answerCount; i++)
		{
			g_hVoteMenu.AddItem(answers[i], answers[i]);
		}	
	}
	
	g_hVoteMenu.ExitButton = false;
	g_hVoteMenu.DisplayVoteToAll(30);		
	
	return Plugin_Handled;	
}

public int Handler_VoteCallback(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		VoteMenuClose();
	}
	else if (action == MenuAction_Display)
	{
PlaySoundTR();
	 	if (g_voteType != question)
	 	{
			char title[64];
			menu.GetTitle(title, sizeof(title));
			
	 		char buffer[255];
			Format(buffer, sizeof(buffer), "%T", title, param1, g_voteInfo[VOTE_NAME]);

			Panel panel = view_as<Panel>(param2);
			panel.SetTitle(buffer);
		}
	}
	else if (action == MenuAction_DisplayItem)
	{
		char display[64];
		menu.GetItem(param2, "", 0, _, display, sizeof(display));
	 
	 	if (strcmp(display, "No") == 0 || strcmp(display, "Yes") == 0)
	 	{
			char buffer[255];
			Format(buffer, sizeof(buffer), "%T", display, param1);

			return RedrawMenuItem(buffer);
		}
	}
	/* else if (action == MenuAction_Select)
	{
		VoteSelect(menu, param1, param2);
	}*/
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		PrintToChatAll("[SM] %t", "No Votes Cast");
	}	
	else if (action == MenuAction_VoteEnd)
	{
		char item[64], display[64];
		float percent, limit;
		int votes, totalVotes;

		GetMenuVoteInfo(param2, votes, totalVotes);
		menu.GetItem(param1, item, sizeof(item), _, display, sizeof(display));
		
		if (strcmp(item, VOTE_NO) == 0 && param1 == 1)
		{
			votes = totalVotes - votes; // Reverse the votes to be in relation to the Yes option.
		}
		
		percent = GetVotePercent(votes, totalVotes);
		
		if (g_voteType != question)
		{
			limit = g_Cvar_Limits[g_voteType].FloatValue;
		}
		
		// A multi-argument vote is "always successful", but have to check if its a Yes/No vote.
		if ((strcmp(item, VOTE_YES) == 0 && FloatCompare(percent,limit) < 0 && param1 == 0) || (strcmp(item, VOTE_NO) == 0 && param1 == 1))
		{
			/* :TODO: g_voteTarget should be used here and set to -1 if not applicable.
			 */
			LogAction(-1, -1, "Vote failed.");
			PrintToChatAll("[SM] %t", "Vote Failed", RoundToNearest(100.0*limit), RoundToNearest(100.0*percent), totalVotes);
		}
		else
		{
			PrintToChatAll("[SM] %t", "Vote Successful", RoundToNearest(100.0*percent), totalVotes);
			
			switch (g_voteType)
			{
				case (question):
				{
					if (strcmp(item, VOTE_NO) == 0 || strcmp(item, VOTE_YES) == 0)
					{
						strcopy(item, sizeof(item), display);
					}
					
					PrintToChatAll("[SM] %t", "Vote End", g_voteArg, item);
				}
				
				case (map):
				{
					// single-vote items don't use the display item
					char displayName[PLATFORM_MAX_PATH];
					GetMapDisplayName(item, displayName, sizeof(displayName));
					LogAction(-1, -1, "Changing map to %s due to vote.", item);
					PrintToChatAll("[SM] %t", "Changing map", displayName);
					DataPack dp;
					CreateDataTimer(0.0, Timer_ChangeMap, dp);
					dp.WriteString(item);		
				}
					
				case (kick):
				{
					int voteTarget;
					if((voteTarget = GetClientOfUserId(g_voteTarget)) == 0)
					{
						LogAction(-1, -1, "Vote kick failed, unable to kick \"%s\" (reason \"%s\")", g_voteInfo[VOTE_NAME], "Player no longer available");
					}
					else
					{
						if (g_voteArg[0] == '\0')
						{
							strcopy(g_voteArg, sizeof(g_voteArg), "Votekicked");
						}
						
						PrintToChatAll("[SM] %t", "Kicked target", "_s", g_voteInfo[VOTE_NAME]);					
						LogAction(-1, voteTarget, "Vote kick successful, kicked \"%L\" (reason \"%s\")", voteTarget, g_voteArg);
						
						ServerCommand("kickid %d \"%s\"", g_voteTarget, g_voteArg);					
					}
				}
					
				case (ban):
				{
					int voteTarget;
					if((voteTarget = GetClientOfUserId(g_voteTarget)) == 0)
					{
						LogAction(-1, -1, "Vote ban failed, unable to ban \"%s\" (reason \"%s\")", g_voteInfo[VOTE_NAME], "Player no longer available");
					}
					else
					{
						if (g_voteArg[0] == '\0')
						{
							strcopy(g_voteArg, sizeof(g_voteArg), "Votebanned");
						}
						
						PrintToChatAll("[SM] %t", "Banned player", g_voteInfo[VOTE_NAME], 30);
						LogAction(-1, voteTarget, "Vote ban successful, banned \"%L\" (minutes \"30\") (reason \"%s\")", voteTarget, g_voteArg);
	
						BanClient(voteTarget,
								  30,
								  BANFLAG_AUTO,
								  g_voteArg,
								  "Banned by vote",
								  "sm_voteban");
					}
				}
			}
		}
	}
	
	return 0;
}

/*
void VoteSelect(Menu menu, int param1, int param2 = 0)
{
	if (g_Cvar_VoteShow.IntValue == 1)
	{
		char voter[64], junk[64], choice[64];
		GetClientName(param1, voter, sizeof(voter));
		menu.GetItem(param2, junk, sizeof(junk), _, choice, sizeof(choice));
		PrintToChatAll("[SM] %T", "Vote Select", LANG_SERVER, voter, choice);
	}
}
*/

void VoteMenuClose()
{
	delete g_hVoteMenu;
}

float GetVotePercent(int votes, int totalVotes)
{
	return FloatDiv(float(votes),float(totalVotes));
}

bool TestVoteDelay(int client)
{
 	int delay = CheckVoteDelay();
 	
 	if (delay > 0)
 	{
 		if (delay > 60)
 		{
 			ReplyToCommand(client, "[SM] %t", "Vote Delay Minutes", delay % 60);
 		}
 		else
 		{
 			ReplyToCommand(client, "[SM] %t", "Vote Delay Seconds", delay);
 		}
 		
 		return false;
 	}
 	
	return true;
}

public Action Timer_ChangeMap(Handle timer, DataPack dp)
{
	char mapname[65];
	
	dp.Reset();
	dp.ReadString(mapname, sizeof(mapname));
	
	ServerCommand("sm_setnextmap %s", mapname);
	
	return Plugin_Stop;
}

stock bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

public void StopMapMusic()
{
	char sSound[PLATFORM_MAX_PATH];
	int entity = INVALID_ENT_REFERENCE;
	for(int i=1;i<=MaxClients;i++){
		if(!IsClientInGame(i)){ continue; }
		for (int u=0; u<g_iNumSounds; u++){
			entity = EntRefToEntIndex(g_iSoundEnts[u]);
			if (entity != INVALID_ENT_REFERENCE){
				GetEntPropString(entity, Prop_Data, "m_iszSound", sSound, sizeof(sSound));
				Client_StopSound(i, entity, SNDCHAN_STATIC, sSound);
			}
		}
	}
}

stock void Client_StopSound(int client, int entity, int channel, const char[] name)
{
	EmitSoundToClient(client, name, entity, channel, SNDLEVEL_NONE, SND_STOP, 0.0, SNDPITCH_NORMAL, _, _, _, true);
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(GetConVarInt(g_hStop) == 1)
	{
		// Ents are recreated every round.
		g_iNumSounds = 0;
		
		// Find all ambient sounds played by the map.
		char sSound[PLATFORM_MAX_PATH];
		int entity = INVALID_ENT_REFERENCE;
		
		while ((entity = FindEntityByClassname(entity, "ambient_generic")) != INVALID_ENT_REFERENCE)
		{
			GetEntPropString(entity, Prop_Data, "m_iszSound", sSound, sizeof(sSound));
			
			int len = strlen(sSound);
			if (len > 4 && (StrEqual(sSound[len-3], "mp3") || StrEqual(sSound[len-3], "wav")))
			{
				g_iSoundEnts[g_iNumSounds++] = EntIndexToEntRef(entity);
			}
		}
	}
}

public void SoundCookieHandler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	abnermenu(client, 0);
} 

public void OnClientPutInServer(int client)
{
	CreateTimer(3.0, msg, client);
}

public Action msg(Handle timer, any client)
{
	if(IsValidClient(client))
	{
		CPrintToChat(client, "{default}{green}[AbNeR RES] {default}%t", "JoinMsg");
	}
}

public Action abnermenu(int client, int args)
{
	int cookievalue = GetIntCookie(client, g_AbNeRCookie);
	Handle g_AbNeRMenu = CreateMenu(AbNeRMenuHandler);
	SetMenuTitle(g_AbNeRMenu, "Round End Sounds by AbNeR_CSS");
	char Item[128];
	if(cookievalue == 0)
	{
		Format(Item, sizeof(Item), "%t %t", "RES_ON", "Selected"); 
		AddMenuItem(g_AbNeRMenu, "ON", Item);
		Format(Item, sizeof(Item), "%t", "RES_OFF"); 
		AddMenuItem(g_AbNeRMenu, "OFF", Item);
	}
	else
	{
		Format(Item, sizeof(Item), "%t", "RES_ON");
		AddMenuItem(g_AbNeRMenu, "ON", Item);
		Format(Item, sizeof(Item), "%t %t", "RES_OFF", "Selected"); 
		AddMenuItem(g_AbNeRMenu, "OFF", Item);
	}
	SetMenuExitBackButton(g_AbNeRMenu, true);
	SetMenuExitButton(g_AbNeRMenu, true);
	DisplayMenu(g_AbNeRMenu, client, 30);
}

public int AbNeRMenuHandler(Handle menu, MenuAction action, int param1, int param2)
{
	Handle g_AbNeRMenu = CreateMenu(AbNeRMenuHandler);
	if (action == MenuAction_DrawItem)
	{
		return ITEMDRAW_DEFAULT;
	}
	else if(param2 == MenuCancel_ExitBack)
	{
		ShowCookieMenu(param1);
	}
	else if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 0:
			{
				SetClientCookie(param1, g_AbNeRCookie, "0");
				abnermenu(param1, 0);
			}
			case 1:
			{
				SetClientCookie(param1, g_AbNeRCookie, "1");
				abnermenu(param1, 0);
			}
		}
		CloseHandle(g_AbNeRMenu);
	}
	return 0;
}

public void PathChange(Handle cvar, const char[] oldVal, const char[] newVal)
{       
	RefreshSounds(0);
}

public void OnMapStart()
{
	RefreshSounds(0);
}

void RefreshSounds(int client)
{
	char soundpath[PLATFORM_MAX_PATH];
	char soundpath2[PLATFORM_MAX_PATH];
	GetConVarString(g_hTRPath, soundpath, sizeof(soundpath));
	GetConVarString(g_hCTPath, soundpath2, sizeof(soundpath2));
	SamePath = StrEqual(soundpath, soundpath2);
	int size;
	if(SamePath)
	{
		size = LoadSoundsTR();
		SoundsTRSucess = (size > 0);
		if(SoundsTRSucess)
			ReplyToCommand(client, "[AbNeR RES] SOUNDS: %d sounds loaded.", size);
		else
			ReplyToCommand(client, "[AbNeR RES] INVALID TR SOUND PATH.");
	}
	else
	{
		size = LoadSoundsTR();
		SoundsTRSucess = (size > 0);
		if(SoundsTRSucess)
			ReplyToCommand(client, "[AbNeR RES] TR_SOUNDS: %d sounds loaded.", size);
		else
			ReplyToCommand(client, "[AbNeR RES] INVALID TR SOUND PATH.");
		
		size = LoadSoundsCT();
		SoundsCTSucess = (size > 0);
		if(SoundsCTSucess)
			ReplyToCommand(client, "[AbNeR RES] CT_SOUNDS: %d sounds loaded.", size);
		else
			ReplyToCommand(client, "[AbNeR RES] INVALID CT SOUND PATH.");
	}
}
 
int LoadSoundsCT()
{
	ctSound.Clear();
	char name[64];
	char soundname[64];
	char soundpath[PLATFORM_MAX_PATH];
	char soundpath2[PLATFORM_MAX_PATH];
	GetConVarString(g_hCTPath, soundpath, sizeof(soundpath));
	Format(soundpath2, sizeof(soundpath2), "sound/%s/", soundpath);
	Handle pluginsdir = OpenDirectory(soundpath2);
	SoundsCTSucess = (pluginsdir != INVALID_HANDLE);
	if(SoundsCTSucess)
	{
		while(ReadDirEntry(pluginsdir,name,sizeof(name)))
		{
			int namelen = strlen(name) - 4;
			if(StrContains(name,".mp3",false) == namelen)
			{
				Format(soundname, sizeof(soundname), "sound/%s/%s", soundpath, name);
				AddFileToDownloadsTable(soundname);
				Format(soundname, sizeof(soundname), "%s/%s", soundpath, name);
				ctSound.PushString(soundname);
			}
		}
	}
	return ctSound.Length;
}

int LoadSoundsTR()
{
	trSound.Clear();
	char name[64];
	char soundname[64];
	char soundpath[PLATFORM_MAX_PATH];
	char soundpath2[PLATFORM_MAX_PATH];
	GetConVarString(g_hTRPath, soundpath, sizeof(soundpath));
	Format(soundpath2, sizeof(soundpath2), "sound/%s/", soundpath);
	Handle pluginsdir = OpenDirectory(soundpath2);
	SoundsCTSucess = (pluginsdir != INVALID_HANDLE);
	if(SoundsCTSucess)
	{
		while(ReadDirEntry(pluginsdir,name,sizeof(name)))
		{
			int namelen = strlen(name) - 4;
			if(StrContains(name,".mp3",false) == namelen)
			{
				Format(soundname, sizeof(soundname), "sound/%s/%s", soundpath, name);
				AddFileToDownloadsTable(soundname);
				Format(soundname, sizeof(soundname), "%s/%s", soundpath, name);
				trSound.PushString(soundname);
			}
		}
	}
	return trSound.Length;
}

float PlaySoundCT()
{
	int soundToPlay;
	if(GetConVarInt(g_hPlayType) == 1)
	{
		soundToPlay = GetRandomInt(0, ctSound.Length-1);
	}
	else
	{
		soundToPlay = 0;
	}
	
	char szSound[128];
	ctSound.GetString(soundToPlay, szSound, sizeof(szSound));
	ctSound.Erase(soundToPlay);
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && GetIntCookie(i, g_AbNeRCookie) == 0)
		{
			if(CSGO)
			{
				ClientCommand(i, "playgamesound Music.StopAllMusic");
				ClientCommand(i, "play *%s", szSound);
			}
			else
				ClientCommand(i, "play %s", szSound);
		}
	}
	if(ctSound.Length == 0)
		LoadSoundsCT();
	return soundLenght(szSound);
}

float PlaySoundTR()
{
	int soundToPlay;
	if(GetConVarInt(g_hPlayType) == 1)
	{
		soundToPlay = GetRandomInt(0, trSound.Length-1);
	}
	else
	{
		soundToPlay = 0;
	}
	
	char szSound[128];
	trSound.GetString(soundToPlay, szSound, sizeof(szSound));
	trSound.Erase(soundToPlay);
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && GetIntCookie(i, g_AbNeRCookie) == 0)
		{
			if(CSGO)
			{
				ClientCommand(i, "playgamesound Music.StopAllMusic");
				ClientCommand(i, "play *%s", szSound);
			}
			else
				ClientCommand(i, "play %s", szSound);
		}
	}
	if(trSound.Length == 0)
		LoadSoundsTR();
	return soundLenght(szSound);
}


float soundLenght(char[] sound)
{
	float CurrentSoundLenght = 0.0;
	if(soundLib)
	{
		Handle Sound = OpenSoundFile(sound);
		if(Sound != INVALID_HANDLE)
			CurrentSoundLenght = GetSoundLengthFloat(Sound);
	}
	return CurrentSoundLenght;
}

//Round End Reasons
//TRWIN 0 2 3 8 12 14 17 19
//CTWIN 4 5 6 7 10 11 13 16
//DRAW 9 15

int TRWIN[] = {0, 2, 3, 8, 12, 14, 17, 19};
int CTWIN[] = {4, 5, 6, 7, 10, 11, 13, 16};

bool IsCTReason(int reason)
{
	for(int i = 0;i<sizeof(CTWIN);i++)
	{
		if(CTWIN[i] == reason) return true;
	}
	return false;
}

bool IsTRReason(int reason)
{
	for(int i = 0;i<sizeof(TRWIN);i++)
	{
		if(TRWIN[i] == reason) return true;
	}
	return false;
}

int GetWinner(int reason)
{
	if(IsTRReason(reason))
	{
		//PrintToChatAll("TR WIN");
		return 2;
	}
	if(IsCTReason(reason))
	{
		//PrintToChatAll("CT WIN");
		return 3;
	}
	//PrintToChatAll("DRAW");
	return 0;
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	char szReason[5];
	Format(szReason, sizeof(szReason), "%d", reason);
	int reason2 = StringToInt(szReason);
	int winner = (reason2);
	float CurrentSoundLenght;
	
	if(winner == 0)
	{
		if(GetConVarInt(g_roundDrawPlay) == 1) winner = 2;
		else if(GetConVarInt(g_roundDrawPlay) == 2) winner = 3;
	}
	else if(winner == 3 && SamePath)
	{
		winner = 2;
	}
	
	switch(winner)
	{
		case 0:
		{
			return Plugin_Continue;
		}
		case 2:
		{
			if(SoundsTRSucess)
			{
				CurrentSoundLenght = PlaySoundTR();
			}
			else
			{
				if(!SamePath) PrintToServer("[AbNeR RES] TR_SOUNDS ERROR: Sounds not loaded.");
				else PrintToServer("[AbNeR RES] SOUNDS ERROR: Sounds not loaded.");
				return Plugin_Continue;
			}
		}	
		case 3:
		{
			if(SoundsCTSucess)
			{
				CurrentSoundLenght = PlaySoundCT();
			}
			else
			{
				PrintToServer("[AbNeR RES] CT_SOUNDS ERROR: Sounds not loaded.");
				return Plugin_Continue;
			}
		}
	}
	
	if(GetConVarInt(g_hStop) == 1)
		StopMapMusic();
	
	if(GetConVarInt(g_playToTheEnd) == 1 && soundLib && CurrentSoundLenght > 0.0)
	{
		CS_TerminateRound(CurrentSoundLenght, reason, true);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}


public Action CommandLoad(int client, int args)
{   
	RefreshSounds(client);
	return Plugin_Handled;
}


int GetIntCookie(int client, Handle handle)
{
	char sCookieValue[11];
	GetClientCookie(client, handle, sCookieValue, sizeof(sCookieValue));
	return StringToInt(sCookieValue);
}
