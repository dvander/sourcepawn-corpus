#include <sourcemod>
#include <clientprefs>
#include <store>
#include <csgo_colors>

#define PLUGIN_AUTHOR "Simon -edit by Nachtfrische"
#define PLUGIN_VERSION "2.1"

ConVar g_hDailyEnable;
ConVar g_hDailyCredits;
ConVar g_hDailyBonus;
ConVar g_hDailyMax;
ConVar g_hDailyReset;
Handle g_hDailyCookie;
Handle g_hDailyBonusCookie;
char CurrentDate[20];
char SavedDate[MAXPLAYERS + 1][50];
char SavedBonus[MAXPLAYERS + 1][4];


public Plugin myinfo = 
{
	name = "[Store] Daily Credits", 
	author = PLUGIN_AUTHOR, 
	description = "Daily credits for regular players.", 
	version = PLUGIN_VERSION, 
	url = "yash1441@yahoo.com"
};

public void OnPluginStart()
{
	LoadTranslations("dailycredits.phrases");
	CreateConVar("sm_daily_credits_version", PLUGIN_VERSION, "Daily Credits Version", FCVAR_DONTRECORD | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_SPONLY);
	g_hDailyEnable = CreateConVar("sm_daily_credits_enable", "1", "Daily Credits enable? 0 = disable, 1 = enable", 0, true, 0.0, true, 1.0);
	g_hDailyCredits = CreateConVar("sm_daily_credits_amount", "10", "Amount of Credits.", 0, true, 0.0);
	g_hDailyBonus = CreateConVar("sm_daily_credits_bonus", "2", "Increase in Daily Credits on consecutive days.", 0, true, 0.0);
	g_hDailyMax = CreateConVar("sm_daily_credits_max", "50", "Max credits that you can get daily.", 0, true, 0.0);
	g_hDailyCookie = RegClientCookie("DailyCreditsDate", "Cookie for daily credits last used date.", CookieAccess_Protected);
	g_hDailyBonusCookie = RegClientCookie("DailyCreditsBonus", "Cookie for daily credits bonus.", CookieAccess_Protected);
	g_hDailyReset = CreateConVar("sm_daily_credits_resetperiod", "7", "Amount of days after which the streak should reset itself. Set to 0 to disable.", 0, true, 0.0);
	
	AutoExecConfig(true, "dailycredits");
	for (new i = MaxClients; i > 0; --i)
	{
		if (!AreClientCookiesCached(i))
			continue;
		OnClientCookiesCached(i);
	}
	RegConsoleCmd("sm_daily", Cmd_Daily);
	RegConsoleCmd("sm_dailies", Cmd_Daily);
}

public void OnClientCookiesCached(int client)
{
	GetClientCookie(client, g_hDailyCookie, SavedDate[client], sizeof(SavedDate[])); // Get saved date on client connecting
	GetClientCookie(client, g_hDailyBonusCookie, SavedBonus[client], sizeof(SavedBonus[])); // Get saved bonus on client connecting
}

public Action Cmd_Daily(int client, int args)
{
	FormatTime(CurrentDate, sizeof(CurrentDate), "%Y%m%d"); // Save current date in variable
	if (!GetConVarBool(g_hDailyEnable))return Plugin_Handled;
	else if (!IsValidClient(client))return Plugin_Handled;
	else if (StrEqual(SavedDate[client], ""))
	{
		GiveCredits(client, true);
		return Plugin_Handled;
	}
	else if (IsDailyAvailable(client) == 0)
	{
		return Plugin_Handled;
	}
	else if (IsDailyAvailable(client) == 1) // Check if daily is available
	{
		GiveCredits(client, false); // Give credits
		return Plugin_Handled;
	}
	else if (IsDailyAvailable(client) == 2) // Check if daily is available
	{
		GiveCredits(client, true); // Give credits
		return Plugin_Handled;
	}
	else if (IsDailyAvailable(client) == -1) // Check if daily is available
	{
		CPrintToChatEx(client, client, "%t", "CookieError");
		return Plugin_Handled;
	}
	else return Plugin_Handled;
}

stock void GiveCredits(int client, bool FirstDay)
{
	if (FirstDay)
	{
		Store_SetClientCredits(client, Store_GetClientCredits(client) + GetConVarInt(g_hDailyCredits)); // Giving credits
		CPrintToChatEx(client, client, "%t", "CreditsRecieved", GetConVarInt(g_hDailyCredits));
		SetClientCookie(client, g_hDailyBonusCookie, "1");
		strcopy(SavedBonus[client], sizeof(SavedBonus[]), "1");
		SetClientCookie(client, g_hDailyCookie, CurrentDate);
		Format(SavedDate[client], sizeof(SavedDate[]), CurrentDate);
	}
	else
	{
		int resetDaysSetting = GetConVarInt(g_hDailyReset);
		int TotalCredits = GetConVarInt(g_hDailyCredits) + ReturnDailyBonus(client);
		if (TotalCredits > GetConVarInt(g_hDailyMax))TotalCredits = GetConVarInt(g_hDailyMax);
		int streakDays = ReturnStreakDays(client);
		if (streakDays > 0)
		{
			streakDays--;
		}
		
		Store_SetClientCredits(client, Store_GetClientCredits(client) + TotalCredits); // Giving credits
		
		if (streakDays != 0)
		{
			if (streakDays >= resetDaysSetting) //if the current streak of days is the same as the value for resetting the "streak cycle"
			{
				CPrintToChatEx(client, client, "%t", "LastCreditsRecieved", TotalCredits);
				CPrintToChatEx(client, client, "%t", "ResetDays", resetDaysSetting); //tell the user that the reset cycle has been reached
				SetClientCookie(client, g_hDailyCookie, CurrentDate); // Set saved date to today
				Format(SavedDate[client], sizeof(SavedDate[]), CurrentDate);
				int cookievalue = 0;
				IntToString(cookievalue, SavedBonus[client], sizeof(SavedBonus[])); // Reset the bonus
				SetClientCookie(client, g_hDailyBonusCookie, SavedBonus[client]); // Save bonus
			}
			else //streak is smaller then reset period
			{
				CPrintToChatEx(client, client, "%t", "CreditsRecieved", TotalCredits); // Chat 
				SetClientCookie(client, g_hDailyCookie, CurrentDate); // Set saved date to today
				Format(SavedDate[client], sizeof(SavedDate[]), CurrentDate);
				int cookievalue = StringToInt(SavedBonus[client]);
				CPrintToChatEx(client, client, "%t", "CurrentDay", cookievalue + 1); //tell the user which day they are currently on
				cookievalue++;
				IntToString(cookievalue, SavedBonus[client], sizeof(SavedBonus[])); // Add 1 to bonus
				SetClientCookie(client, g_hDailyBonusCookie, SavedBonus[client]); // Save bonus
			}
		}
		else
		{
			CPrintToChatEx(client, client, "%t", "CreditsRecieved", TotalCredits); // Chat 
			SetClientCookie(client, g_hDailyCookie, CurrentDate); // Set saved date to today
			Format(SavedDate[client], sizeof(SavedDate[]), CurrentDate);
			int cookievalue = StringToInt(SavedBonus[client]);
			CPrintToChatEx(client, client, "%t", "CurrentDay", cookievalue + 1); //tell the user which day they are currently on
			cookievalue++;
			IntToString(cookievalue, SavedBonus[client], sizeof(SavedBonus[])); // Add 1 to bonus
			SetClientCookie(client, g_hDailyBonusCookie, SavedBonus[client]); // Save bonus
		}
	}
}

stock int IsDailyAvailable(int client)
{
	if (StringToInt(CurrentDate) - StringToInt(SavedDate[client]) == 1)
	{
		return 1; // If saved date - current date = 1 return true
	}
	
	else if (StringToInt(CurrentDate) - StringToInt(SavedDate[client]) == 0)
	{
		CPrintToChatEx(client, client, "%t", "BackTomorrow"); // if = 0 then tomorrow msg
		return 0;
	}
	
	else if (StringToInt(CurrentDate) - StringToInt(SavedDate[client]) > 1)
	{
		CPrintToChatEx(client, client, "%t", "StreakEnded", StringToInt(SavedBonus[client]));
		strcopy(SavedBonus[client], sizeof(SavedBonus[]), "0");
		SetClientCookie(client, g_hDailyBonusCookie, "0");
		return 2;
	}
	
	else return -1;
}

public int ReturnDailyBonus(int client)
{
	int cookievalue = StringToInt(SavedBonus[client]);
	return (cookievalue * GetConVarInt(g_hDailyBonus)); // Return saved bonus x daily bonus value
}

public int ReturnStreakDays(int client)
{
	int bonusDays = StringToInt(SavedBonus[client]);
	return bonusDays;
}

stock bool IsValidClient(client)
{
	if (client <= 0)return false;
	if (client > MaxClients)return false;
	if (!IsClientConnected(client))return false;
	return IsClientInGame(client);
} 