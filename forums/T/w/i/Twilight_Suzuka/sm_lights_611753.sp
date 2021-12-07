#include <sourcemod>
#include <sdktools>

#define ADMFLAG_LIGHTS ADMFLAG_BAN

#define SETLIGHT_VERSION "Alpha:1"

public Plugin:myinfo = 
{
	name = "Set Lights",
	author = "Twilight Suzuka",
	description = "Provides a method to set lighting in server",
	version = SETLIGHT_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("setlights_version",SETLIGHT_VERSION,"Dynamic Light Setting",FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_lighting", Command_Lights, ADMFLAG_LIGHTS, "sm_lights <#pattern|level> [style]");
}

new String:StyleArray[][] = {
	"m",
	"mmnmmommommnonmmonqnmmo",
	"abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba",
	"mmmmmaaaaammmmmaaaaaabcdefgabcdefg",
	"mamamamamama",
	"jklmnopqrstuvwxyzyxwvutsrqponmlkj",
	"nmonqnmomnmomomno",
	"mmmaaaabcdefgmmmmaaaammmaamm",
	"mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa",
	"aaaaaaaazzzzzzzz",
	"mmamammmmammamamaaamammma",
	"abcdefghijklmnopqrrqponmlkjihgfedcba",
	"mmnnmmnnnmmnn"
};

public Action:Command_Lights(client, args)
{
	decl String:Pattern[192];
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_lighting <#pattern|level> [style]");
		return Plugin_Handled;
	}
	
	new Style = 0;
	if(args > 1)
	{
		GetCmdArg(2, Pattern, sizeof(Pattern));
		Style = StringToInt(Pattern);
		if(Style < 0 || Style >= MAX_LIGHTSTYLES)
		{
			ReplyToCommand(client, "[SM] Style must be no less than 0, and no more than 63!");
			return Plugin_Handled;
		}
	}
	
	GetCmdArg(1, Pattern, sizeof(Pattern));
	if(Pattern[0] == '#')
	{
		new PatternStyle = StringToInt(Pattern[1]);
		if(PatternStyle < 0 || PatternStyle > 12) return DisplayValidStyles(client);
		
		SetLightStyle(Style,StyleArray[PatternStyle]);
	}
	else SetLightStyle(Style, Pattern);
	
	decl String:Name[32];
	GetClientName(client,Name,sizeof(Name));
	
	LogAction(client, -1, "\"%s\" changed lights (pattern \"%s\") (style \"%d\") ", Name, Pattern, Style);
	ReplyToCommand(client, "[SM] Lighting Style Changed.");
	
	return Plugin_Handled;
}

stock Action:DisplayValidStyles(client)
{
	ReplyToCommand(client,"[SM] Valid Styles: 0 - 12:");
	ReplyToCommand(client, "[SM] 1 FLICKER (first variety)");
	ReplyToCommand(client, "[SM] 2 SLOW STRONG PULSE");
	ReplyToCommand(client, "[SM] 3 CANDLE (first variety)");
	ReplyToCommand(client, "[SM] 4 FAST STROBE");
	ReplyToCommand(client, "[SM] 5 GENTLE PULSE 1");
	ReplyToCommand(client, "[SM] 6 FLICKER (second variety)");
	ReplyToCommand(client, "[SM] 7 CANDLE (second variety)");
	ReplyToCommand(client, "[SM] 8 CANDLE (third variety)");
	ReplyToCommand(client, "[SM] 9 SLOW STROBE (fourth variety)");
	ReplyToCommand(client, "[SM] 10 FLUORESCENT FLICKER");
	ReplyToCommand(client, "[SM] 11 SLOW PULSE NOT FADE TO BLACK");
	ReplyToCommand(client, "[SM] 12 UNDERWATER LIGHT MUTATION");
	
	return Plugin_Handled;
}
	