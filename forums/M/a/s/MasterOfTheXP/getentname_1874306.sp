#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
	RegAdminCmd("sm_getentname", Command_getentname, ADMFLAG_ROOT);
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
}

public Action:Command_getentname(client, args)
{
	if (args < 1)
	{
		new String:arg0[20];
		GetCmdArg(0, arg0, sizeof(arg0));
		ReplyToCommand(client, "[SM] Usage: %s <classname> [co-ords?] - Returns the names of all entities with this classname.", arg0);
		return Plugin_Handled;
	}
	new String:arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	new i = -1, count, String:output[512];
	while ((i = FindEntityByClassname(i, arg1)) != -1)
	{
		if (count) Format(output, sizeof(output), "%s\n", output);
		new String:name[64];
		GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
		if (StrEqual(name, "")) continue;
		Format(output, sizeof(output), "%s%i - %s", output, i, name);
		if (args > 1)
		{
			new Float:Pos[3];
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", Pos);
			Format(output, sizeof(output), "%s (%.2f %.2f %.2f)", output, Pos[0], Pos[1], Pos[2]);
		}
		count++;
	}
	if (!count)
	{
		ReplyToCommand(client, "[SM] No matching entities were found.");
		return Plugin_Handled;
	}
	PrintToConsole(client, output);
	if (SM_REPLY_TO_CHAT == GetCmdReplySource())
		ReplyToCommand(client, "[SM] %t", "See console for output");
	return Plugin_Handled;
}