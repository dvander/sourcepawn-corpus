#define PL_VERSION    "0.3"

new bool:cvar_bBannersRandom, Handle:listBannersFile, Handle:g_hGraphicCvar, Handle:g_hRandomCvar;

public Plugin:myinfo = 
{
    name = "Rotate server graphic banners",
    author = "HiTmAnY",
    description = "Rotates sv_server_graphic1 banners",
    version = PL_VERSION,
	url = "http://hitmany.net"
}

public OnPluginStart()
{
	listBannersFile = CreateConVar("sm_graphics_file",     "graphics.txt",	"File to read the banners from.");
	HookConVarChange(g_hRandomCvar = CreateConVar("sm_graphics_random", "0", "Banners are changing in turns or randomly?\n0 - by rotation."), hookRandomCvarChange);
	cvar_bBannersRandom = GetConVarBool(g_hRandomCvar);
	g_hGraphicCvar = FindConVar("sv_server_graphic1")
	
	CreateConVar("graphicrotator_version", PL_VERSION, "Plugin version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);	
}

public OnMapEnd()
{
	decl String:sPath[PLATFORM_MAX_PATH], String:sFile[PLATFORM_MAX_PATH];
	
	GetConVarString(listBannersFile, sFile, sizeof(sFile));
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/%s", sFile);
	
	if(FileExists(sPath))
	{
		decl Handle:h;
		if(FileToKeyValues((h=CreateKeyValues("Graphics")), sPath))
		{
			new amount_of_banners = KvGotoFirstSubKey(h);
			while(KvGotoNextKey(h)) amount_of_banners++;
			
			if(amount_of_banners != 1)
			{
				CloseHandle(h);
				static current_banner;
				if(cvar_bBannersRandom) current_banner = GetRandomInt(1, amount_of_banners);
				else if(++current_banner > amount_of_banners) current_banner = 1;
				FileToKeyValues(h=CreateKeyValues("Graphics"), sPath);
				IntToString(current_banner, sPath, 3);
				KvJumpToKey(h, sPath);
			}
			
			KvGetString(h, "file", sPath, PLATFORM_MAX_PATH);
			SetConVarString(g_hGraphicCvar, sPath);
			
		}
		else
		{
			LogError("Failed load %s!", sPath);
		}
		
		CloseHandle(h);
		
	}
	else
	{
		LogError("File not found: %s!", sPath);
	}
}

public hookRandomCvarChange(Handle:convar, String:oldValue[], String:newValue[])
{
	cvar_bBannersRandom = GetConVarBool(convar);
}