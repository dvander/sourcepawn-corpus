public Action:OnClientCommand(client, args)
{
	new String:arg0[64], String:cmd[64], flags, String:desc[3];
	GetCmdArg(0, arg0, sizeof(arg0));
	
	if (!CommandExists(arg0)) return;
	
	new Handle:iter = GetCommandIterator(), bool:found;
	while (ReadCommandIterator(iter, cmd, sizeof(cmd), flags, desc, sizeof(desc)))
	{
		if (StrEqual(cmd, arg0, false) && (flags || !StrContains(cmd, "sm_", false)))
		{
			found = true;
			break;
		}
	}
	CloseHandle(iter);
	
	if (!found) return;
	
	new String:team[16];
	switch (GetClientTeam(client))
	{
		case 1: FormatEx(team, sizeof(team), "<Spectator>");
		case 2: FormatEx(team, sizeof(team), "<Red>");
		case 3: FormatEx(team, sizeof(team), "<Blue>");
	}
	
	new String:argstr[512];
	GetCmdArgString(argstr, sizeof(argstr));
	Format(argstr, sizeof(argstr), "\"%L\" used command \"%s %s\"", client, arg0, argstr);
	ReplaceString(argstr, sizeof(argstr), "<>", team);
}