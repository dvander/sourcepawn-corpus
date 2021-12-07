//////////////////////////////////////////////////////////////////
// SM COLOUR By MoggieX
//////////////////////////////////////////////////////////////////

#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define PLUGIN_VERSION "1.3"

//////////////////////////////////////////////////////////////////
// Plugin Info
//////////////////////////////////////////////////////////////////

public Plugin:myinfo = 
{
	name = "sm_colour",
	author = "MoggieX",
	description = "Set a Players Colour & Rendering",
	version = PLUGIN_VERSION,
	url = "http://www.afterbuy.co.uk"
};

//////////////////////////////////////////////////////////////////
// Start Plugin
//////////////////////////////////////////////////////////////////

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("smcolour.phrases");

	CreateConVar("sm_colour_version", PLUGIN_VERSION, "SM Colour Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_color", Command_SmColour, ADMFLAG_CUSTOM1, "sm_color <name or #userid or all/t/ct> <RED> <GREEN> <BLUE> <OPACITY> - Set target's colour.");
	RegAdminCmd("sm_colour", Command_SmColour, ADMFLAG_CUSTOM1, "sm_colour <name or #userid or all/t/ct> <RED> <GREEN> <BLUE> <OPACITY> - Set target's colour.");
	RegAdminCmd("sm_render", Command_SmRender, ADMFLAG_CUSTOM1, "sm_render <name or #userid or all/t/ct> <value> - Set target's render.");
}

////////////////////////////////////////////////////////////////////////
// sm_colour
////////////////////////////////////////////////////////////////////////
public Action:Command_SmColour(client, args)
{
	if (args < 4)
	{
		ReplyToCommand(client, "[SM Colour] Usage: sm_colour <#userid|name|team|all> <RED 0-255> <GREEN 0-255> <BLUE 0-255> <OPACITY 0-255>");
		return Plugin_Handled;	
	}

// Error trapping for R G B O

// #2 Red
	new red = 0;
	decl String:arg2[20];
	GetCmdArg(2, arg2, sizeof(arg2));
	if (StringToIntEx(arg2, red) == 0)
	{
		ReplyToCommand(client, "\x04[SM Colour]\x01 %t", "Invalid Amount For Red");
		return Plugin_Handled;
	}
	if (red < 0)
	{
		red = 0;
	}
	if (red > 255)
	{
		red = 255;
	}

// #3 Green
	new green = 0;
	decl String:arg3[20];
	GetCmdArg(3, arg3, sizeof(arg3));
	if (StringToIntEx(arg3, green) == 0)
	{
		ReplyToCommand(client, "\x04[SM Colour]\x01 %t", "Invalid Amount For Green");
		return Plugin_Handled;
	}
	if (green < 0)
	{
		green = 0;
	}
	if (green > 255)
	{
		green = 255;
	}

// #4 Blue
	new blue = 0;
	decl String:arg4[20];
	GetCmdArg(4, arg4, sizeof(arg4));
	if (StringToIntEx(arg4, blue) == 0)
	{
		ReplyToCommand(client, "\x04[SM Colour]\x01 %t", "Invalid Amount For Blue");
		return Plugin_Handled;
	}
	if (blue < 0)
	{
		blue = 0;
	}
	if (blue > 255)
	{
		blue = 255;
	}

// #5 Opacity
	new opacity = 0;
	decl String:arg5[20];
	GetCmdArg(5, arg5, sizeof(arg5));
	if (StringToIntEx(arg5, opacity) == 0)
	{
		ReplyToCommand(client, "\x04[SM Colour]\x01 %t", "Invalid Amount For Opacity");
		return Plugin_Handled;
	}
	if (opacity < 0)
	{
		opacity = 0;
	}
	if (opacity > 255)
	{
		opacity = 255;
	}

//////// Find player and SET Colours

// get their name
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		SetEntityRenderColor(target_list[i], red, green, blue, opacity);
	}

	if (tn_is_ml)
	{
		ShowActivity2(client, "x04[SM Colour]\x03 ", "%t", "Set colour on target", client, target_name, red, green, blue, opacity);
	}
	else
	{
		ShowActivity2(client, "\x04[SM Colour]\x03 ", "%t", "Set colour on target", "_s", client, target_name, red, green, blue, opacity);
	}

	return Plugin_Handled;
}

////////////////////////////////////////////////////////////////////////
// sm_render
////////////////////////////////////////////////////////////////////////

public Action:Command_SmRender(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM Render] Usage: sm_render <#userid|name|team|all> <RENDER 0-26>");
		return Plugin_Handled;	
	}

// get their name
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

		new amount = 0;
		decl String:arg2[20];
		GetCmdArg(2, arg2, sizeof(arg2));
		if (StringToIntEx(arg2, amount) == 0)
		{
			ReplyToCommand(client, "[SM] %t", "Invalid Amount");
			return Plugin_Handled;
		}
		
		if (amount < 0)
		{
			amount = 0;
		}
		
		if (amount > 26)
		{
			amount = 26;
		}

//////// Find and Set

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		SetEntityRenderFx(target_list[i], amount);
	}

	if (tn_is_ml)
	{
		ShowActivity2(client, "\x04[SM Colour]\x03 ", "%t", "Set render on target", client, target_name, amount);
	}
	else
	{
		ShowActivity2(client, "\x04[SM Colour]\x03 ", "%t", "Set render on target", "_s", client, target_name, amount);
	}

	return Plugin_Handled;

}