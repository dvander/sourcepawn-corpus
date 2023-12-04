#include <sourcemod>
#include <multicolors>
#include <morecolors>

#define CHAT_TAG "{yellow}[{darkred}kurumi{orange}test{yellow}] ►"
#define CHAT_TEXT_COLOR "{green}"
#define CHAT_NUMBER_COLOR "{yellow}"
#define HUD_TEXT_COLOR "#00CCFF"
#define HUD_NUMBER_COLOR "#FFFFFF"

#define HUD_MAX_STRING_LEN 42
#define HUD_NUMBER_MAX_COUNT 4

#define HUD_PREFIX "▻"
#define HUD_PREFIX_COLOR "#00FF00"

#define HUD_POSTFIX "◅"
#define HUD_POSTFIX_COLOR "#00FF00"

public Plugin myinfo =
{
	name			= "CountdownHUD",
	author		= "kurumi",
	description = "A simple HTML Countdown HUD for ZE.",
	version		= "2.0",
	url			= "https://github.com/tokKurumi"
};

char g_BlackListWords[][] = 
{
	"recharge",
	"cd",
	"tips",
	"recast",
	"cooldown",
	"cool"
};

char g_FilterSymbolsList[][] = 
{
	".",
	",",
	"!",
	":",
	";",
	"<",
	">",
	"(",
	")",
	"[",
	"]",
	"{",
	"}",
	"_",
	"/",
	"\\",
	"'"
};

Handle g_CurrentCountdownTimer;
int g_CurrentTimerSeconds;
char g_TimerPartsBuffer[2][MAX_MESSAGE_LENGTH]; // need to PrintMapCDMessageToAll function

//Check if input string contains word from blacklist.
public bool StrContainBlackListWord(const char[] string)
{
	for(int i = 0; i < sizeof(g_BlackListWords); ++i)
	{
		if(StrContains(string, g_BlackListWords[i], false) != -1)
		{
			return true;
		}
	}
	
	return false;
}

//Check if input string contains number.
public bool StrContainNumber(const char[] string)
{
	for(int i = 0; i < strlen(string); ++i)
	{
		if(IsCharNumeric(string[i]))
		{
			return true;
		}
	}
	
	return false;
}

//Find int number in string, if did not find - returns 0
public int StrSearchInt(const char[] string)
{
	int currentItPosition;
	char result[HUD_NUMBER_MAX_COUNT]; // the maximum search number contains 4 symbols

	for(int i = 0; i < strlen(string); ++i)
	{
		if(IsCharNumeric(string[i]))
		{
			result[currentItPosition++] = string[i];
		}
		else if(currentItPosition != 0) // if we already found number and current symbol is not numeric, break searching
		{
			break;
		}
	}

	return StringToInt(result);
}

//Check if symbol is not on g_FilterSymbolsList
public bool IsValidSymbol(const char[] symbol)
{
	for(int i = 0; i < sizeof(g_FilterSymbolsList); ++i)
	{
		if(StrEqual(symbol, g_FilterSymbolsList[i]))
		{
			return false;
		}
	}

	return true;
}

//Removes all g_FilterSymbolsList symbols from input string
public void FilterText(char string[MAX_MESSAGE_LENGTH])
{
	for(int i = 0; i < sizeof(g_FilterSymbolsList); ++i)
	{
		ReplaceString(string, sizeof(string), g_FilterSymbolsList[i], "");
	}
}

//Prints map message to chat with formating according to CHAT_TAG and CHAT_TEXT_COLOR
public void PrintMapMessageToAll(const char[] message)
{
	char formatMessage[MAX_MESSAGE_LENGTH];

	Format(formatMessage, sizeof(formatMessage), "%s %s%s", CHAT_TAG, CHAT_TEXT_COLOR, message);
	TrimString(formatMessage);

	CPrintToChatAll(formatMessage);
}

//Prints map message and countdown to chat with formating according to CHAT_TAG, CHAT_TEXT_COLOR and CHAT_NUMBER_COLOR
public void PrintMapCDMessageToAll(const char[] part1, const int seconds, const char[] part2)
{
	char formatCDMessage[MAX_MESSAGE_LENGTH];

	Format(formatCDMessage, sizeof(formatCDMessage), "%s %s%s%s%d%s%s", CHAT_TAG, CHAT_TEXT_COLOR, part1, CHAT_NUMBER_COLOR, seconds, CHAT_TEXT_COLOR, part2);
	TrimString(formatCDMessage);

	CPrintToChatAll(formatCDMessage);
}

//Formating HUD message according to HUD_TEXT_COLOR, HUD_NUMBER_COLOR, HUD_PREFIX, HUD_PREFIX_COLOR, HUD_POSTFIX and HUD_POSTFIX_COLOR
public void FormatCountdownMessage(const char[] part1, const int seconds, const char[] part2, char output[MAX_MESSAGE_LENGTH])
{
	Format(output, sizeof(output), "<font color='%s'>%s</font> <font color='%s'>%s</font><font color='%s'>%d</font><font color='%s'>%s</font> <font color='%s'>%s</font>", HUD_PREFIX_COLOR, HUD_PREFIX, HUD_TEXT_COLOR, part1, HUD_NUMBER_COLOR, seconds, HUD_TEXT_COLOR, part2, HUD_POSTFIX_COLOR, HUD_POSTFIX);
}

//Shows HTML message in player's HUD
public void HTMLHUDMessageShow(const char[] message, int hold)
{
	Event HTMLHUDMessage = CreateEvent("show_survival_respawn_status", true);

	if(HTMLHUDMessage != null)
	{
		HTMLHUDMessage.SetString("loc_token", message);
		HTMLHUDMessage.SetInt("duration", hold);
		HTMLHUDMessage.SetInt("userid", -1);

		HTMLHUDMessage.Fire();
	}
}

//Display Countdown HTML HUD to everyone
public void StartCountdown(const char[] message, int seconds)
{
	if (g_CurrentCountdownTimer != INVALID_HANDLE)
	{
		KillTimer(g_CurrentCountdownTimer);
		g_CurrentCountdownTimer = INVALID_HANDLE;
	}

	g_CurrentCountdownTimer = CreateTimer(1.0, Timer_Countdown, _, TIMER_REPEAT);
	g_CurrentTimerSeconds = seconds;
}

//Timer
public Action Timer_Countdown(Handle timer)
{
	char message[MAX_MESSAGE_LENGTH];

	g_CurrentTimerSeconds--;
	if(g_CurrentTimerSeconds < 0)
	{
		return Plugin_Handled;
	}

	FormatCountdownMessage(g_TimerPartsBuffer[0], g_CurrentTimerSeconds, g_TimerPartsBuffer[1], message);

	HTMLHUDMessageShow(message, 2); // hold = 2 because with 1 it is blinking

	return Plugin_Continue;
}

public void OnPluginStart()
{
	AddCommandListener(Listener_OnSay, "say");
}

public Action Listener_OnSay(int client, char[] command, int args)
{
	if(client) // skip message if message typed by not console
	{
		return Plugin_Continue;
	}

	char mapMessage[MAX_MESSAGE_LENGTH];
	GetCmdArgString(mapMessage, sizeof(mapMessage));

	FilterText(mapMessage);

	if(!StrContainBlackListWord(mapMessage) && StrContainNumber(mapMessage))
	{
		int seconds = StrSearchInt(mapMessage);

		char seconds_string[HUD_NUMBER_MAX_COUNT];
		IntToString(seconds, seconds_string, HUD_NUMBER_MAX_COUNT);

		ExplodeString(mapMessage, seconds_string, g_TimerPartsBuffer, 2, sizeof(g_TimerPartsBuffer[]));

		PrintMapCDMessageToAll(g_TimerPartsBuffer[0], seconds, g_TimerPartsBuffer[1]);

		StartCountdown(mapMessage, seconds);
	}
	else
	{
		PrintMapMessageToAll(mapMessage);
	}

	return Plugin_Handled;
}