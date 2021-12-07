#include <downloader>
#include <sourcemod>

#define PLUGIN_VERSION "0.0.2"

/*the code from the funtion that reads out the maplist.txt is from webshortcuts*/

new Handle:g_Shortcuts;
new Handle:g_Titles;
new Handle:g_Links;
new String:mod[32]
new Handle:MapListUrl = INVALID_HANDLE;
public Plugin:myinfo = 
{
	name = "MAP-Downloader",
	author = "R-Hehl",
	description = "Map Downloader",
	version = PLUGIN_VERSION,
	url = "http://CompactAim.de"
};

new Handle:down;

public DownloadComplete(const sucess, const status, Handle:arg)
{
    PrintToChatAll("Download Complete");
    CloseHandle(down);
}
public Progress(const recvSize, const totalSize, Handle:arg)
{
    PrintToServer("Download Progress: %i/%i ",recvSize,totalSize);  
}
public OnPluginStart()
{
CreateConVar("sm_map_dl_version", PLUGIN_VERSION, "MapDownloader", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
MapListUrl = CreateConVar("sm_maplisturl","http://fsrlp.de/","The Url Where The MapList is Located");
RegAdminCmd("sm_mapdlmenu", Map_DL_Menu, ADMFLAG_CHANGEMAP, "Map Download Menu"); 
g_Shortcuts = CreateArray( 32 );
g_Titles = CreateArray( 64 );
g_Links = CreateArray( 512 );
GetGameFolderName(mod, sizeof(mod))
DownloadMaplist()
LoadMaplist()
}
public DownloadMaplist()
{
down = CreateDownloader();

new String:Link[128];
new String:L_MapListUrl[256]
GetConVarString(MapListUrl,L_MapListUrl,sizeof(L_MapListUrl))
Format(Link, sizeof(Link), "%smaplist-%s.txt",L_MapListUrl ,mod);
SetURL(down,Link);
SetCallback(down,DownloadComplete);
SetProgressCallback(down,Progress);
SetOutputFile(down,"mapdl_maplist.txt");
Download(down);
}
LoadMaplist()
{
	decl String:buffer [1024];
	Format(buffer, sizeof(buffer), "mapdl_maplist.txt");
	
	if ( !FileExists( buffer ) )
	{
		return;
	}
 
	new Handle:f = OpenFile( buffer, "r" );
	if ( f == INVALID_HANDLE )
	{
		LogError( "[SM] Could not open file: %s", buffer );
		return;
	}
	
	ClearArray( g_Shortcuts );
	ClearArray( g_Titles );
	ClearArray( g_Links );
	
	decl String:shortcut [32];
	decl String:title [64];
	decl String:link [512];
	while ( !IsEndOfFile( f ) && ReadFileLine( f, buffer, sizeof(buffer) ) )
	{
		TrimString( buffer );
		if ( buffer[0] == '\0' || buffer[0] == ';' || ( buffer[0] == '/' && buffer[1] == '/' ) )
		{
			continue;
		}
		
		new pos = BreakString( buffer, shortcut, sizeof(shortcut) );
		if ( pos == -1 )
		{
			continue;
		}
		
		new linkPos = BreakString( buffer[pos], title, sizeof(title) );
		if ( linkPos == -1 )
		{
			continue;
		}
		
		strcopy( link, sizeof(link), buffer[linkPos+pos] );
		TrimString( link );
		
		PushArrayString( g_Shortcuts, shortcut );
		PushArrayString( g_Titles, title );
		PushArrayString( g_Links, link );
	}
	
	CloseHandle( f );
}
public Action:Map_DL_Menu(client, args)
{
	new Handle:menu = CreateMenu(MapMenuHandler)
	SetMenuTitle(menu, "Select a Map to Download")
	new size = GetArraySize( g_Shortcuts );
	for (new i; i != size; ++i)
	{
	decl String:Shortcut [64];
	
	GetArrayString( g_Shortcuts, i, Shortcut, sizeof(Shortcut) );
	AddMenuItem(menu, Shortcut, Shortcut)
	}
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)
 
	return Plugin_Handled
}
public MapMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
	new String:map[64]
	decl String:link [512];
	GetMenuItem(menu, param2, map, sizeof(map))
	down = CreateDownloader();
	new size = GetArraySize( g_Shortcuts );
	
	for (new i; i != size; ++i)
	{
	decl String:Shortcut [64];
	GetArrayString( g_Shortcuts, i, Shortcut, sizeof(Shortcut) );
	if (strcmp(Shortcut, map, true) == 0)
	{
	GetArrayString( g_Links, i, link, sizeof(link) );
	}
	}
	SetURL(down,link);
	SetCallback(down,DownloadComplete);
	SetProgressCallback(down,Progress);
	new String:Locstor[128];
	Format(Locstor, sizeof(Locstor), "/maps/%s.bsp",map);
	SetOutputFile(down, Locstor);
	Download(down);
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
	PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2)
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
	CloseHandle(menu)
	}
}