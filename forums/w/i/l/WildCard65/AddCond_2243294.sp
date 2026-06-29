#include <sourcemod>
#include <tf2_stocks>

new TFCond:conds[MAXPLAYERS+1];
new Handle:timeCvar = INVALID_HANDLE;
new Float:duration = 0.0;

public Plugin:myinfo = {
	name = "AddCond",
	author = "The Count",
	description = "Add any TF2 condition to yourself.",
	version = "1",
	url = "http://steamcommunity.com/profiles/76561197983205071"
}

public OnPluginStart(){
	RegConsoleCmd("sm_addcond", Cmd_AddCond, "Add a condition to yourself.");
	RegConsoleCmd("sm_remcond", Cmd_RemCond, "Removes a condition from yourself.");
	timeCvar = CreateConVar("sm_addcond_duration", "0.0", "Set to 0.0 or below(negative) for infinite time, anything greater is duration.");
	HookConVarChange(timeCvar, DurationChanged);
	AutoExecConfig();
}

public DurationChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	duration = StringToFloat(newValue);
}

public OnClientPutInServer(client)
{
	conds[client] = TFCond:-1;
}

public OnConfigsExecuted()
{
	duration = GetConVarFloat(timeCvar);
}

public Action:Cmd_RemCond(client, args)
{
	if (conds[client] == TFCond:-1)
		ReplyToCommand(client, "[SM] You don't have a condition applied.");
	else if (!TF2_IsPlayerInCondition(client, conds[client]))
		ReplyToCommand(client, "[SM] You already have this condition removed.");
	else
	{
		TF2_RemoveCondition(client, conds[client]);
		conds[client] = TFCond:-1;
		ReplyToCommand(client, "[SM] Successfully removed condition.");
	}
	return Plugin_Handled;
}

public Action:Cmd_AddCond(client, args){
	if (!IsPlayerAlive(client))
		ReplyToCommand(client, "[SM] Must be alive to add a condition.");
	else if (args != 1)
		ReplyToCommand(client, "[SM] Usage: !addcond [NUMBER]");
	else
	{
		if (conds[client] != TFCond:-1 && TF2_IsPlayerInCondition(client, conds[client]))
			TF2_RemoveCondition(client, conds[client]);
		new String:arg1[6]; //I believe TF2 conditions aren't into the thousands yet.
		GetCmdArg(1, arg1, sizeof(arg1));
		if (StringToInt(arg1) <= 0)
			ReplyToCommand(client, "[SM] Invalid integer.");
		else
		{
			new TFCond:cond = TFCond:StringToInt(arg1);
			TF2_AddCondition(client, cond, (duration <= 0.0 ? TFCondDuration_Infinite : duration));
			conds[client] = cond;
			ReplyToCommand(client, "Successfully added condition.");
		}
	}
	return Plugin_Handled;
}