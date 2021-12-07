//////////////////////////////////////////////////////////////////
// color changer By Benni
//////////////////////////////////////////////////////////////////

#include <sourcemod>
#include <sdktools>


//Terminate:
#pragma semicolon 1


public OnPluginStart()
{
	
	
	RegAdminCmd("sm_color", Command_color, ADMFLAG_SLAY,"Set a color :)");
	RegAdminCmd("sm_fx", Command_fx, ADMFLAG_SLAY,"Set Render FX :)");
	CreateConVar("Color_version", "2.1", "Color Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}



public Action:Command_color(Client,args)
{
	//Arguments:
	if(args < 1)
	{
		
		//Print:
		PrintToConsole(Client, "[RP] Usage: sm_color <Red> <Green> <Blue>");
		
		//Return:
		return Plugin_Handled;
	}
	
	PrintToChat(Client, "\x04[Color Changed]\x04");
	decl Ent;
	Ent = GetClientAimTarget(Client, false);
	
	decl String:arg1[255];	
	decl String:arg2[255];	
	decl String:arg3[255];	
	decl String:arg4[255];	
	
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	GetCmdArg(4, arg4, sizeof(arg4));
	
	SetEntityRenderColor(Ent, StringToInt(arg1), StringToInt(arg2), StringToInt(arg3), StringToInt(arg4));
	return Plugin_Handled;
}




public Action:Command_fx(Client,args)
{
	//Arguments:
	if(args < 1)
	{
		
		//Print:
		PrintToConsole(Client, "[RP] Usage: sm_fx <Alpha>");
		
		//Return:
		return Plugin_Handled;
	}
	
	PrintToChat(Client, "\x04[RenderFx Changed]\x04");
	decl Ent;
	Ent = GetClientAimTarget(Client, false);
	
	decl String:arg1[255];	


	
	GetCmdArg(1, arg1, sizeof(arg1));

	
	SetEntityRenderFx(Ent, StringToInt(arg1));
	
	return Plugin_Handled;
}



//Information:
public Plugin:myinfo =
{
	
	//Initation:
	name = "Color changer",
	author = "Benni",
	description = "Color changer for Roleplay",
	version = "1.0",
	url = "http://www.bfs-server.de"
}






