#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <morecolors>
#include <timer>
#include <timer-stocks>
#include <timer-config_loader.sp>

#undef REQUIRE_PLUGIN
#include <timer-physics>
#include <timer-worldrecord>

new bool:g_timerPhysics = false;
new bool:g_timerWorldRecord = false;

public Plugin:myinfo = 
{
	name = "[Timer] Finish Message",
	author = "Zipcore",
	description = "[Timer] Finish message for CS:S",
	version = "1.0",
	url = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
	LoadPhysics();
	LoadTimerSettings();
	
	g_timerPhysics = LibraryExists("timer-physics");
	g_timerWorldRecord = LibraryExists("timer-worldrecord");
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "timer-physics"))
	{
		g_timerPhysics = true;
	}	
	else if (StrEqual(name, "timer-worldrecord"))
	{
		g_timerWorldRecord = true;
	}
}

public OnLibraryRemoved(const String:name[])
{	
	if (StrEqual(name, "timer-physics"))
	{
		g_timerPhysics = false;
	}	
	else if (StrEqual(name, "timer-worldrecord"))
	{
		g_timerWorldRecord = false;
	}
}


public OnMapStart()
{
	LoadPhysics();
	LoadTimerSettings();
}

public OnTimerRecord(client, bonus, mode, Float:time, Float:lasttime, currentrank, newrank)
{
	decl String:name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	
	//Record Info
	new RecordId;
	new Float:RecordTime;
	new RankTotal;
	new Float:LastTime;
	new Float:LastTimeStatic;
	new LastJumps;
	decl String:TimeDiff[32];
	decl String:buffer[32];
	
	new bool:NewPersonalRecord = false;
	new bool:NewWorldRecord = false;
	new bool:FirstRecord = false;
	
	new bool:ranked, Float:jumpacc;
	if(g_timerPhysics) 
	{
		ranked = bool:Timer_IsModeRanked(mode);
		Timer_GetJumpAccuracy(client, jumpacc);
	}
	
	new bool:enabled = false;
	new jumps = 0;
	new fpsmax;

	Timer_GetClientTimer(client, enabled, time, jumps, fpsmax);
	
	if(g_timerWorldRecord) 
	{
		/* Get Personal Record */
		if(Timer_GetBestRound(client, mode, bonus, LastTime, LastJumps))
		{
			LastTimeStatic = LastTime;
			LastTime -= time;			
			if(LastTime < 0.0)
			{
				LastTime *= -1.0;
				Timer_SecondsToTime(LastTime, buffer, sizeof(buffer), 3);
				FormatEx(TimeDiff, sizeof(TimeDiff), "+%s", buffer);
			}
			else if(LastTime > 0.0)
			{
				Timer_SecondsToTime(LastTime, buffer, sizeof(buffer), 3);
				FormatEx(TimeDiff, sizeof(TimeDiff), "-%s", buffer);
			}
			else if(LastTime == 0.0)
			{
				Timer_SecondsToTime(LastTime, buffer, sizeof(buffer), 3);
				FormatEx(TimeDiff, sizeof(TimeDiff), "%s", buffer);
			}
		}
		else
		{
			//No personal record, this is his first record
			FirstRecord = true;
			LastTime = 0.0;
			Timer_SecondsToTime(LastTime, buffer, sizeof(buffer), 3);
			FormatEx(TimeDiff, sizeof(TimeDiff), "%s", buffer);
			RankTotal++;
		}
	}
	
	decl String:TimeString[32];
	Timer_SecondsToTime(time, TimeString, sizeof(TimeString), 2);
	
	new String:WrName[32], String:WrTime[32];
	new Float:wrtime;
	
	if(g_timerWorldRecord)
	{
		Timer_GetRecordTimeInfo(mode, bonus, newrank, wrtime, WrTime, 32);
		Timer_GetRecordHolderName(mode, bonus, newrank, WrName, 32);
	
		/* Get World Record */
		Timer_GetDifficultyRecordTime(mode, bonus, RecordId, RecordTime, RankTotal);
	}
	
	/* Detect Record Type */
	if(RecordTime == 0.0 || time < RecordTime)
	{
		NewWorldRecord = true;
	}
	
	if(LastTimeStatic == 0.0 || time < LastTimeStatic)
	{
		NewPersonalRecord = true;
	}
	
	new bool:self = false;
	
	if(currentrank == newrank)
	{
		self = true;
	}
	
	if(FirstRecord) RankTotal++;
	
	new Float:wrdiff = time-wrtime;
	
	new String:BonusString[32];
	
	if(bonus == 1)
	{
		FormatEx(BonusString, sizeof(BonusString), " {green}bonus");
	}
	else if(bonus == 2)
	{
		FormatEx(BonusString, sizeof(BonusString), " {green}short");
	}	
	
	new String:RankString[128], String:RankPwndString[128];

	new String:JumpString[128];
	new bool:bAll = false;
	
	decl String:StyleString[128];
	
	if(g_ModeCount > 0 && !g_Settings[MultimodeEnable])
		FormatEx(StyleString, sizeof(StyleString), " on {green}%s", g_Physics[mode][ModeName]);
	
	if(g_Settings[MultimodeEnable]) 
		FormatEx(StyleString, sizeof(StyleString), " on {green}%s", g_Physics[mode][ModeName]);
	
	if(NewWorldRecord)
	{
		bAll = true;
		FormatEx(RankString, sizeof(RankString), "{magenta} New WR!");
		
		if(wrtime > 0.0)
		{
			if(self)
				FormatEx(RankPwndString, sizeof(RankPwndString), "{blue}Improved %s! {yellow}[%s]{blue} by {yellow}[%.2fs]", "himself", WrTime, wrdiff);
			else
				FormatEx(RankPwndString, sizeof(RankPwndString), "{blue}Beaten %s{blue}! {yellow}[%s]{blue} by {yellow}[%.2fs]", WrName, WrTime, wrdiff);
		}
	}
	else if(newrank > 5000)
	{
		FormatEx(RankString, sizeof(RankString), "{yellow}#%d+ / %d", newrank, RankTotal);
	}
	else if(NewPersonalRecord || FirstRecord)
	{
		bAll = true;
		FormatEx(RankString, sizeof(RankString), "{yellow}#%d / %d", newrank, RankTotal);
		
		if(newrank < currentrank) Format(RankPwndString, sizeof(RankPwndString), "{blue}Beaten %s{blue}! {yellow}[%s]{blue} by {yellow}[%.2fs]", WrName, WrTime, wrdiff);
	}	
	else if(NewPersonalRecord)
	{
		FormatEx(RankString, sizeof(RankString), "{orange}#%d / %d", newrank, RankTotal);
		
		FormatEx(RankPwndString, sizeof(RankPwndString), "You have improved yourself! {yellow}[%s]{blue} by {yellow}[%.2fs]", WrTime, wrdiff);
	}
	
	if(g_Settings[JumpsEnable])
	{
		Format(JumpString, sizeof(JumpString), "{blue} and {yellow}%d jumps", jumps);
	}
	
	if(ranked)
	{
		if(FirstRecord)
		{
			if(bAll)
			{
				CPrintToChatAll("%s {blue}Player %s{blue} has finished%s{blue}%s{blue}.", PLUGIN_PREFIX2, name, BonusString, StyleString);
				CPrintToChatAll("{blue}Time: {yellow}[%ss]%s %s", TimeString, JumpString, RankString);
				CPrintToChatAll("%s", RankPwndString);
			}
			else
			{
				CPrintToChat(client, "%s {blue}You have finished%s{blue}%s{blue}.", PLUGIN_PREFIX2, BonusString, StyleString);
				CPrintToChat(client, "{blue}Time: {yellow}[%ss]%s %s", TimeString, JumpString, RankString);
				CPrintToChat(client, "%s", RankPwndString);
			}
		}
		else if(NewPersonalRecord)
		{
			if(bAll)
			{
				CPrintToChatAll("%s {blue}Player %s{blue} has finished%s{blue}%s{blue}.", PLUGIN_PREFIX2, name, BonusString, StyleString);
				CPrintToChatAll("{blue}Time: {yellow}[%ss] improved by [%.2fs]%s %s", TimeString, time-lasttime, JumpString, RankString);
				CPrintToChatAll("%s", RankPwndString);
			}
			else
			{
				CPrintToChat(client, "%s {blue}You have finished%s{blue}%s{blue}.", PLUGIN_PREFIX2, BonusString, StyleString);
				CPrintToChat(client, "{blue}Time: {yellow}[%ss] improved by [%.2fs]%s %s", TimeString, time-lasttime, JumpString, RankString);
				CPrintToChat(client, "%s", RankPwndString);
			}
		}
		else
		{
			CPrintToChat(client, "%s {blue}You have finished%s{blue}%s{blue}. Time: {yellow}[%ss]%s %s", PLUGIN_PREFIX2, BonusString, StyleString, TimeString, JumpString, RankString);
		}
	}
	else
	{
		CPrintToChat(client, "%s {blue}You have finished%s{blue}%s{blue}.", PLUGIN_PREFIX2, BonusString, StyleString);
		CPrintToChat(client, "{blue}Time: {yellow}[%ss] %s", TimeString, JumpString);
	}
}