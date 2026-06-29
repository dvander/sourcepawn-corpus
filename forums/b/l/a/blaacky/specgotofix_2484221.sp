public Plugin myinfo = 
{
	name = "spec_goto crash fix",
	author = "blacky",
	description = "Fixes crash with spec_goto command",
	version = "1.0",
	url = "http://steamcommunity.com/id/blaackyy/"
}

public void OnPluginStart()
{
	CreateConVar("specgotofix_version", "1.0", "Unreal physics version", FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	AddCommandListener(Command_GoTo, "spec_goto");
}

public Action Command_GoTo(int client, const char[] command, int argc)
{
	if(argc == 5)
	{
		for(int i = 1; i <= 3; i++)
		{
			char sArg[64];
			GetCmdArg(i, sArg, 64);
			float fArg = StringToFloat(sArg);
			
			if(FloatAbs(fArg) > 5000000000)
			{
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

