#include sourcemod
#include sdktools
#pragma semicolon 1
#define PLUGIN_VERSION "1.0b"

new Handle:l4d2_hiar;
new Handle:l4d2_hiarsnd;
new Handle:l4d2_hiarnfo;
new Handle:l4d2_hiarnfows;
new Handle:l4d2_hiarnfopub;
new Handle:l4d2_hiarnfoc;
new Handle:l4d2_hiarcount;
new Handle:Sound_File10 = INVALID_HANDLE;
new Handle:Sound_File20 = INVALID_HANDLE;
new Handle:Sound_File30 = INVALID_HANDLE;
new Handle:Sound_File40 = INVALID_HANDLE;
new Handle:Sound_File50 = INVALID_HANDLE;
new Handle:Sound_File60 = INVALID_HANDLE;
new Handle:l4d2_hiarow1;
new Handle:l4d2_hiarow2;
new Handle:l4d2_hiarow3;
new Handle:l4d2_hiarow4;
new Handle:l4d2_hiarow5;
new Handle:l4d2_hiarow6;
new killcount[MAXPLAYERS+1];
new headcount[MAXPLAYERS+1];
new headcountrow[MAXPLAYERS+1];
new sheadcount[MAXPLAYERS+1];
new sheadcountrow[MAXPLAYERS+1];
new skillcount[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "[L4D2] Headshots in a row",
	author = "dYZER",
	description = "Plays Sound/Count at a headshots in a row",
	version = "1.0",
	url = "http://forums.alliedmods.net/"
}
//thnx TeddyRuxpin 
//http://forums.alliedmods.net/showthread.php?t=84607 i modded a little with

public OnPluginStart()
{
	CreateConVar("l4d2_hiar_version", PLUGIN_VERSION, "Headshots in a Row Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	l4d2_hiar = CreateConVar("l4d2_hiar", "1", "Heads in a row (0=Disable,1=Enable)", FCVAR_PLUGIN|FCVAR_NOTIFY);
	l4d2_hiarnfo = CreateConVar("l4d2_hiarnfo", "1", "Auto announce at given rows (0=Disable,1=Enable)", FCVAR_PLUGIN|FCVAR_NOTIFY);
	l4d2_hiarnfows = CreateConVar("l4d2_hiarnfows", "1", "Auto announce at given rows with Stats (0=Disable,1=Enable)", FCVAR_PLUGIN|FCVAR_NOTIFY);
	l4d2_hiarnfopub = CreateConVar("l4d2_hiarnfopub", "1", "announce Stats public by trigger !hiar (0=Private,1=All)", FCVAR_PLUGIN|FCVAR_NOTIFY);
	l4d2_hiarnfoc = CreateConVar("l4d2_hiarnfoc", "1", "announce Center current Headshots kills(0=Disable,1=Enable)", FCVAR_PLUGIN|FCVAR_NOTIFY);
	l4d2_hiarcount = CreateConVar("l4d2_hiarcount", "5", "Start Counter for the Centerinfo", FCVAR_PLUGIN|FCVAR_NOTIFY);
	l4d2_hiarsnd = CreateConVar("l4d2_hiarsnd", "1", "play sound at the given row (0=Disable,1=Enable)", FCVAR_PLUGIN|FCVAR_NOTIFY);

	Sound_File10 = CreateConVar("l4d2_hiarsound10", "npc/moustachio/strengthlvl1_littlepeanut.wav", "Plays that sound file at the 1 row", FCVAR_PLUGIN);
	Sound_File20 = CreateConVar("l4d2_hiarsound20", "npc/moustachio/strengthlvl2_babypeanut.wav", "Plays that sound file at the 2 row", FCVAR_PLUGIN);
	Sound_File30 = CreateConVar("l4d2_hiarsound30", "npc/moustachio/strengthlvl3_oldpeanut.wav", "Plays that sound file at the 3 row", FCVAR_PLUGIN);
	Sound_File40 = CreateConVar("l4d2_hiarsound40", "npc/moustachio/strengthlvl4_notbad.wav", "Plays that sound file at the 4 row", FCVAR_PLUGIN);
	Sound_File50 = CreateConVar("l4d2_hiarsound50", "npc/moustachio/strengthlvl5_sostrong.wav", "Plays that sound file at the 5 row", FCVAR_PLUGIN);
	Sound_File60 = CreateConVar("l4d2_hiarsound60", "npc/moustachio/strengthbreakmachine.wav", "Plays that sound file at the 6 row", FCVAR_PLUGIN);
	
	l4d2_hiarow1 = CreateConVar("l4d2_hiarow1", "10", "1 row", FCVAR_PLUGIN);
	l4d2_hiarow2 = CreateConVar("l4d2_hiarow2", "20", "2 row", FCVAR_PLUGIN);
	l4d2_hiarow3 = CreateConVar("l4d2_hiarow3", "30", "3 row", FCVAR_PLUGIN);
	l4d2_hiarow4 = CreateConVar("l4d2_hiarow4", "40", "4 row", FCVAR_PLUGIN);
	l4d2_hiarow5 = CreateConVar("l4d2_hiarow5", "50", "5 row", FCVAR_PLUGIN);
	l4d2_hiarow6 = CreateConVar("l4d2_hiarow6", "60", "6 row", FCVAR_PLUGIN);
	
	HookEvent("infected_death", Event_Infected_Death, EventHookMode_Pre);
	HookEvent("infected_hurt", Event_Infected_Hurt, EventHookMode_Pre);
	HookEvent("player_spawn", evtPlayerSpawn);
	HookEvent("player_first_spawn", EvtPlayerFirstSpawn);
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	RegConsoleCmd("sm_hiar",hiar);
	
	AutoExecConfig(true, "l4d2_hiar");
}
public OnConfigsExecuted()
{
	if ((GetConVarInt(l4d2_hiarsnd) == 1) && (GetConVarInt(l4d2_hiar) == 1))
	{
		decl String: sound_10[128];
		GetConVarString(Sound_File10, sound_10, sizeof(sound_10));
		if (!IsSoundPrecached(sound_10)) PrecacheSound(sound_10, false);
		AddFileToDownloadsTable(sound_10);

		decl String: sound_20[128];
		GetConVarString(Sound_File20, sound_20, sizeof(sound_20));
		if (!IsSoundPrecached(sound_20)) PrecacheSound(sound_20, false);
		AddFileToDownloadsTable(sound_20);

		decl String: sound_30[128];
		GetConVarString(Sound_File30, sound_30, sizeof(sound_30));
		if (!IsSoundPrecached(sound_30)) PrecacheSound(sound_30, false);
		AddFileToDownloadsTable(sound_30);

		decl String: sound_40[128];
		GetConVarString(Sound_File40, sound_40, sizeof(sound_40));
		if (!IsSoundPrecached(sound_40)) PrecacheSound(sound_40, false);
		AddFileToDownloadsTable(sound_40);

		decl String: sound_50[128];
		GetConVarString(Sound_File50, sound_50, sizeof(sound_50));
		if (!IsSoundPrecached(sound_50)) PrecacheSound(sound_50, false);
		AddFileToDownloadsTable(sound_50);

		decl String: sound_60[128];
		GetConVarString(Sound_File60, sound_60, sizeof(sound_60));
		if (!IsSoundPrecached(sound_60)) PrecacheSound(sound_60, false);
		AddFileToDownloadsTable(sound_60);
	}
}

public Action:EvtPlayerFirstSpawn(Handle:event, const String:strName[], bool:bDontBroadcast)
{
	if (GetConVarInt(l4d2_hiar) == 1) 
	{
		new attacker_userid = GetEventInt(event, "userid");
		new attacker = GetClientOfUserId(attacker_userid);
		killcount[attacker] = 0;
		headcount[attacker] = 0;
		headcountrow[attacker] = 0;
		skillcount[attacker] = 0;
		sheadcount[attacker] = 0;
		sheadcountrow[attacker] = 0;
	}
}
public Action:evtPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(l4d2_hiar) == 1) 
	{
		new attacker_userid = GetEventInt(event, "userid");
		new attacker = GetClientOfUserId(attacker_userid);
		headcountrow[attacker] = 0;
		sheadcountrow[attacker] = 0;
	}
}

public Action:Command_Say(client, args)
{
	if(!client) return Plugin_Continue;
	decl String:text[192];
	if(!GetCmdArgString(text, sizeof(text))) return Plugin_Continue;
	new startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
		}
	if(strcmp(text[startidx], "!hiar", false) == 0) saystats2(client);
	return Plugin_Continue;
}
public Action:hiar(client,args)
{
	saystats2(client);
	return Plugin_Continue;
}

public OnMapStart() 
{
	if ((GetConVarInt(l4d2_hiarsnd) == 1) && (GetConVarInt(l4d2_hiar) == 1))
	{
		decl String: sound_10[128];
		GetConVarString(Sound_File10, sound_10, sizeof(sound_10));
		PrecacheSound(sound_10, false);
		
		decl String: sound_20[128];
		GetConVarString(Sound_File20, sound_20, sizeof(sound_20));
		PrecacheSound(sound_20, false);

		decl String: sound_30[128];
		GetConVarString(Sound_File30, sound_30, sizeof(sound_30));
		PrecacheSound(sound_30, false);

		decl String: sound_40[128];
		GetConVarString(Sound_File40, sound_40, sizeof(sound_40));
		PrecacheSound(sound_40, false);

		decl String: sound_50[128];
		GetConVarString(Sound_File50, sound_50, sizeof(sound_50));
		PrecacheSound(sound_50, false);

		decl String: sound_60[128];
		GetConVarString(Sound_File60, sound_60, sizeof(sound_60));
		PrecacheSound(sound_60, false);

	}
}

public Action:playrow10(attacker)
{
	if (GetConVarInt(l4d2_hiarsnd) == 1) 
	{
		decl String: l4d2_hiarows[128];
		GetConVarString(Sound_File10, l4d2_hiarows, sizeof(l4d2_hiarows));
		new i;
		for (i = 1; i <= GetMaxClients(); i++)
		{
			if (!IsClientConnected(i)) continue;
			if (IsFakeClient(i)) continue;
			if (GetConVarInt(l4d2_hiarsnd) == 1)  EmitSoundToClient(i, l4d2_hiarows, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
		}
	}
	if (GetConVarInt(l4d2_hiarnfo) == 1) saystats(attacker);
}
public Action:playrow20(attacker)
{
	if (GetConVarInt(l4d2_hiarsnd) == 1) 
	{
		decl String: l4d2_hiarows[128];
		GetConVarString(Sound_File20, l4d2_hiarows, sizeof(l4d2_hiarows));
		new i;
		for (i = 1; i <= GetMaxClients(); i++)
		{
			if (!IsClientConnected(i)) continue;
			if (IsFakeClient(i)) continue;
			EmitSoundToClient(i, l4d2_hiarows, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
		}
	}
	if (GetConVarInt(l4d2_hiarnfo) == 1) saystats(attacker);
}
public Action:playrow30(attacker)
{
	if (GetConVarInt(l4d2_hiarsnd) == 1)
	{
		decl String: l4d2_hiarows[128];
		GetConVarString(Sound_File30, l4d2_hiarows, sizeof(l4d2_hiarows));
		new i;
		for (i = 1; i <= GetMaxClients(); i++)
		{
			if (!IsClientConnected(i)) continue;
			if (IsFakeClient(i)) continue;
			EmitSoundToClient(i, l4d2_hiarows, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
		}
	}
	if (GetConVarInt(l4d2_hiarnfo) == 1) saystats(attacker);
}
public Action:playrow40(attacker)
{
	if (GetConVarInt(l4d2_hiarsnd) == 1)
	{
		decl String: l4d2_hiarows[128];
		GetConVarString(Sound_File40, l4d2_hiarows, sizeof(l4d2_hiarows));
		new i;
		for (i = 1; i <= GetMaxClients(); i++)
		{
			if (!IsClientConnected(i)) continue;
			if (IsFakeClient(i)) continue;
			EmitSoundToClient(i, l4d2_hiarows, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
		}
	}
	if (GetConVarInt(l4d2_hiarnfo) == 1) saystats(attacker);
}
public Action:playrow50(attacker)
{
	if (GetConVarInt(l4d2_hiarsnd) == 1) 
	{
		decl String: l4d2_hiarows[128];
		GetConVarString(Sound_File50, l4d2_hiarows, sizeof(l4d2_hiarows));
		new i;
		for (i = 1; i <= GetMaxClients(); i++)
		{
			if (!IsClientConnected(i)) continue;
			if (IsFakeClient(i)) continue;
			EmitSoundToClient(i, l4d2_hiarows, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
		}
	}
	if (GetConVarInt(l4d2_hiarnfo) == 1) saystats(attacker);
}
public Action:playrow60(attacker)
{
	if (GetConVarInt(l4d2_hiarsnd) == 1) 
	{
		decl String: l4d2_hiarows[128];
		GetConVarString(Sound_File60, l4d2_hiarows, sizeof(l4d2_hiarows));
		new i;
		for (i = 1; i <= GetMaxClients(); i++)
		{
			if (!IsClientConnected(i)) continue;
			if (IsFakeClient(i)) continue;
			if (GetConVarInt(l4d2_hiarsnd) == 1) EmitSoundToClient(i, l4d2_hiarows, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
		}
	}
	if (GetConVarInt(l4d2_hiarnfo) == 1) saystats(attacker);
}

saystats(attacker)
{
	if (GetConVarInt(l4d2_hiar) == 1) 
	{
		if (GetConVarInt(l4d2_hiarnfows) == 0) 
		{ 
			PrintToChatAll("\x04[!hiar]\x01 \x05%N\x01, makes \x04%i\x01 Headshots in a row", attacker, headcountrow[attacker]);
			//[!hiar] dYZER makes 10 Headshots in a row
		}
		if (GetConVarInt(l4d2_hiarnfows) == 1)
		{
			new hdShot_check = headcount[attacker];
			new kill_check = killcount[attacker];
			new hdShotAcheck = RoundFloat((float(hdShot_check) / kill_check) * 100);
			new shdShot_check = sheadcount[attacker];
			new skill_check = skillcount[attacker];
			new shdShotAcheck = RoundFloat((float(shdShot_check) / skill_check) * 100);
		
			PrintToChatAll("\x04[!hiar] \x05%N\x01 at \x04%i\x01 Headhots: \x05%i\x01/%i \x05hits\x01 %d%% \x04| \x03%i\x01/%i \x03kills\x01 %d%", attacker, headcountrow[attacker], shdShot_check, skill_check, shdShotAcheck, hdShot_check, kill_check, hdShotAcheck);
			//[!hiar] dYZER at 10 Headhots: 67/177 hits 38% | 33/39 kills 85%
		}
	}
}
saystats2(attacker)
{
	if (GetConVarInt(l4d2_hiar) == 1) 
	{
		new hdShot_check = headcount[attacker];
		new kill_check = killcount[attacker];
		new hdShotAcheck = RoundFloat((float(hdShot_check) / kill_check) * 100);
		new shdShot_check = sheadcount[attacker];
		new skill_check = skillcount[attacker];
		new shdShotAcheck = RoundFloat((float(shdShot_check) / skill_check) * 100);
		
		if (GetConVarInt(l4d2_hiarnfopub) == 1)
		{
			PrintToChatAll("\x04[!hiar] \x05%N\x01 at \x04%i\x01 Headhots: \x05%i\x01/%i \x05hits\x01 %d%% \x04| \x03%i\x01/%i \x03kills\x01 %d%", attacker, headcountrow[attacker], shdShot_check, skill_check, shdShotAcheck, hdShot_check, kill_check, hdShotAcheck);
			//[!hiar] dYZER at 10 Headhots: 67/177 hits 38% | 33/39 kills 85%
		}
		if (GetConVarInt(l4d2_hiarnfopub) == 0)
		{
			//[!hiar] You´re at 10 Headhots: 67/177 hits 38% | 33/39 kills 85%
			PrintToChat(attacker,"\x04[!hiar]\x01 You are at \x04%i\x01 Headhots: \x05%i\x01/%i \x05hits\x01 %d%% \x04| \x03%i\x01/%i \x03kills\x01 %d%", headcountrow[attacker],shdShot_check, skill_check, shdShotAcheck, hdShot_check, kill_check, hdShotAcheck);
		}
	}
}

public Action:Event_Infected_Hurt(Handle:event, const String:name[], bool:dontBroadcast) {
	if (GetConVarInt(l4d2_hiar) == 1) 
	{
		new attacker_userid = GetEventInt(event, "attacker");
		new attacker =  GetClientOfUserId(attacker_userid);
		
		skillcount[attacker] += 1;
		
		if (GetEventInt(event, "hitgroup") == 1)
		{
			sheadcount[attacker] += 1;
			sheadcountrow[attacker] += 1;
		}
		//else sheadcountrow[attacker] = 0; //if hit nonhead reset
	}
	return Plugin_Continue;
}
public Action:Event_Infected_Death(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if (GetConVarInt(l4d2_hiar) == 1)
	{
		new attacker_userid = GetEventInt(event, "attacker");
		new attacker =  GetClientOfUserId(attacker_userid);
		new headshot = GetEventInt(event, "headshot");
		new bool:minigun = GetEventBool(event, "minigun");
		new bool:blast = GetEventBool(event, "blast");
		new bool:submerged = GetEventBool(event, "submerged");

		if(attacker)
		{
			killcount[attacker] += 1;
			if(!minigun && !blast && !submerged)
			{
				if(headshot == 1) 
				{
					headcount[attacker] += 1;
					headcountrow[attacker] += 1;
					if (GetConVarInt(l4d2_hiarnfoc) == 1) {
						if(headcountrow[attacker] >= GetConVarInt(l4d2_hiarcount)) 
						{ 
							PrintCenterText(attacker, "%d", headcountrow[attacker]);	
						}
					}
				}
				else headcountrow[attacker] = 0;
			}

			if(headcountrow[attacker] == GetConVarInt(l4d2_hiarow1)) { playrow10(attacker); }
			if(headcountrow[attacker] == GetConVarFloat(l4d2_hiarow2)) { playrow20(attacker); }
			if(headcountrow[attacker] == GetConVarFloat(l4d2_hiarow3)) { playrow30(attacker); }
			if(headcountrow[attacker] == GetConVarFloat(l4d2_hiarow4)) { playrow40(attacker); }
			if(headcountrow[attacker] == GetConVarFloat(l4d2_hiarow5)) { playrow50(attacker); }
			if(headcountrow[attacker] == GetConVarFloat(l4d2_hiarow6)) { playrow60(attacker); }
			//else
			//{
			//	return Plugin_Continue;
			//}
		}
	}
	return Plugin_Continue;
}