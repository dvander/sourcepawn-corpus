public void OnPluginStart() {
	RegAdminCmd("AddCommandOverride", cmd_AddCommandOverride, ADMFLAG_ROOT);
	RegAdminCmd("GetCommandOverride", cmd_GetCommandOverride, ADMFLAG_ROOT);
	RegAdminCmd("UnsetCommandOverride", cmd_UnsetCommandOverride, ADMFLAG_ROOT);
}

public Action cmd_AddCommandOverride(int client, int args) {
	if (GetCmdArgs() < 3) {
		ReplyToCommand(client, "Usage: AddCommandOverride command_string [type] [flags]");
		return Plugin_Handled;
	}
	char sCommand[65];
	GetCmdArg(1, sCommand, sizeof(sCommand));
	char sType[22];
	OverrideType type = Override_Command;
	GetCmdArg(2, sType, sizeof(sType));
	if (StrContains(sType, "g", false) >= 0) type = Override_CommandGroup;
	char sFlags[22];
	GetCmdArg(3, sFlags, sizeof(sFlags));
	int flags = ReadFlagString(sFlags);
	AddCommandOverride(sCommand, type, flags);
	return Plugin_Handled;
}

public Action cmd_GetCommandOverride(int client, int args) {
	if (GetCmdArgs() < 2) {
		ReplyToCommand(client, "Usage: GetCommandOverride command_string [type]");
		return Plugin_Handled;
	}
	char sCommand[65];
	GetCmdArg(1, sCommand, sizeof(sCommand));
	char sType[22];
	OverrideType type = Override_Command;
	GetCmdArg(2, sType, sizeof(sType));
	if (StrContains(sType, "g", false) >= 0) type = Override_CommandGroup;
	int iFlags;
	bool bOverrideExists = GetCommandOverride(sCommand, type, iFlags);
	if (bOverrideExists) ReplyToCommand(client, "GetCommandOverride(%s, %s) gave back: %i", sCommand, sType, iFlags);
	else ReplyToCommand(client, "GetCommandOverride(%s, %s) returned FALSE", sCommand, sType);
	return Plugin_Handled;
}

public Action cmd_UnsetCommandOverride(int client, int args) {
	if (GetCmdArgs() < 2) {
		ReplyToCommand(client, "Usage: UnsetCommandOverride command_string [type]");
		return Plugin_Handled;
	}
	char sCommand[65];
	GetCmdArg(1, sCommand, sizeof(sCommand));
	char sType[22];
	OverrideType type = Override_Command;
	GetCmdArg(2, sType, sizeof(sType));
	if (StrContains(sType, "g", false) >= 0) type = Override_CommandGroup;
	UnsetCommandOverride(sCommand, type);
	return Plugin_Handled;
}
