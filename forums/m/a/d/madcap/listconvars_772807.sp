#include <sourcemod>
 
public Plugin:myinfo =
{
	name = "List all Commands and Convars",
	author = "Madcap and Lep",
	description = "List all convars and commands in L4D",
	version = "1.0.0.0",
	url = "http://maats.org"
};


public OnPluginStart()
{
	RegConsoleCmd("sm_cvarlist", CmdMakeCvarList);
}	

public Action:CmdMakeCvarList(client, args)
{
	new String:name[64]="NAME";
	new String:desc[256]="DESC";
	new String:value[128]="VALUE";
	new String:flag[32]="FLAGS";
	new bool:iscmd, cmdflags;
	new Handle:cvar;

	LogToFileEx("cvars.txt", "%s,TYPE,%s,%s,%s", name, flag, desc, value);
	
	new Handle:cmds = FindFirstConCommand(name,sizeof(name),iscmd,cmdflags,desc,sizeof(desc));
	do
	{
		if (cmds!=INVALID_HANDLE)
		{

			if (!iscmd)
			{
				cvar = FindConVar(name);
				if (cvar==INVALID_HANDLE)
					value="invalid";
				else
					GetConVarString(cvar, value, sizeof(value));
			}
		
			// valid csv requires fields with , to be surrounded in ""
			if (StrContains(name,","))
				Format(name, sizeof(name), "\"%s\"", name);
		
			// clean up description
			ReplaceString(desc, sizeof(desc), "\n", " ");
			ReplaceString(desc, sizeof(desc), "\t", " ");
			ReplaceString(desc, sizeof(desc), "  ", " ");
			if (StrContains(desc,","))
				Format(desc, sizeof(desc), "\"%s\"", desc);
		
			// set flags
			flag="";
			if(cmdflags&FCVAR_CHEAT){flag="cheat ";}
			if(cmdflags&FCVAR_NOTIFY){StrCat(flag, sizeof(flag), "notify ");}
			if(cmdflags&FCVAR_PLUGIN){StrCat(flag, sizeof(flag), "plugin ");}	
			TrimString(flag);
		
			if (iscmd)
				LogToFileEx("cvars.txt", "%s,Command,%s,%s, ", name, flag, desc);
			else
				LogToFileEx("cvars.txt", "%s,ConVar,%s,%s,%s", name, flag, desc, value);	
		}

	} while (FindNextConCommand(cmds,name,sizeof(name),iscmd,cmdflags,desc,sizeof(desc)));

	PrintToChat(client, "cvars written");
	
}