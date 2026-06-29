#include <sourcemod>

new Handle: cvarEnabled = INVALID_HANDLE;

public OnPluginStart()
{
	RegConsoleCmd("sm_gravme", Cmd_GravMe);
	RegConsoleCmd("sm_gravoff", Cmd_GravOff);
	
	cvarEnabled = CreateConVar ("gravme_enabled", "1", "Enable / Disable GravME") 
}

public Action:Cmd_GravMe(client, args)
{
	if(!(cvarEnabled))
	{
		PrintToChat(client, "\x05[GravME]\x01 This plugin is \x05disabled!\x01");
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		ReplyToCommand(client, "[GravME] Usage: sm_gravme <amount of gravity>");
		return Plugin_Handled;
	}
	
	decl String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	new Float:amount = StringToFloat(arg);
	
	SetEntityGravity(client, amount * 0.01);
	
	PrintToChat(client, "\x05[GravME]\x01 Your gravity has been set to: \x05%s!\x01", arg);
	
	
	return Plugin_Continue;
}

public Action:Cmd_GravOff(client, arg)
{
	if(!(cvarEnabled))
	{
		PrintToChat(client, "\x05[GravME]\x01 This plugin is \x05disabled!\x01");
		return Plugin_Handled;
	}
	
	SetEntityGravity(client, 1.0);
	
	PrintToChat(client, "\x05[GravME]\x01 Your gravity has been set back to \x05default\x01.");
	
	return Plugin_Continue;
}