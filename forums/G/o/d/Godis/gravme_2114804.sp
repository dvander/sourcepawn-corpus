#include <sourcemod>

public OnPluginStart()
{
	RegConsoleCmd("sm_gravme", Cmd_GravMe);
}

public Action:Cmd_GravMe(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_gravme <amount of gravity>");
		return Plugin_Handled;
	}
	decl String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	new Float:amount = StringToFloat(arg);
	SetEntPropFloat(client, Prop_Data, "m_flGravity", amount);
	ReplyToCommand(client, "[SM] Your gravity has been set to: %s!", arg);
	return Plugin_Handled;
}