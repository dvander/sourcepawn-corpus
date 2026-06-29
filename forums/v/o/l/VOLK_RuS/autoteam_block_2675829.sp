public Plugin myinfo =
{
	name = "Block 'autoteam' command",
	author = "VOLK_RuS",
	description = "Just a little fix for prevent disbalancing.",
	version = "1.0",
	url = "awpcountry.ru"
};

public OnPluginStart()
{
	RegConsoleCmd("autoteam", autoteam);
}

public Action autoteam(client, args)
{
	return Plugin_Handled;
}