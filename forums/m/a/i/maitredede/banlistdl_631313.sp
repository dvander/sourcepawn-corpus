#include <sourcemod>
#include <downloader>

#define PLUGIN_VERSION "0.0.2"
#define DEFAULT_FILE "banlist.cfg"
#define DEFAULT_URL "http://ccss.clancalendar.net/download/banlist_clancalendar_CSS.cfg"

/* Changelog
 * v0.0.2
 *   - Change default ClanCalendar url
 * v0.0.1
 *   - Initial release
 */

public Plugin:myinfo =
{
	name = "Banlist downloader",
	author = "MaitreDede",
	description = "Download and execute a banlist file",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

new bool:g_updating = false;
new Handle:g_down = INVALID_HANDLE;
new String:g_file[] = "bancc.cfg";
new Handle:sm_banlist_file = INVALID_HANDLE;
new Handle:sm_banlist_url = INVALID_HANDLE;

public OnPluginStart()
{
	RegAdminCmd("sm_banlist_update", sm_banlist_update, ADMFLAG_GENERIC | ADMFLAG_BAN | ADMFLAG_CONFIG, "Download the banlist file, and execute it (need flags generic admin [b], ban [d], and config [i])", "", FCVAR_PLUGIN);
	sm_banlist_file = CreateConVar("sm_banlist_file", DEFAULT_FILE, "Ban file name (ex: 'banlist.cfg')", FCVAR_PLUGIN | FCVAR_PRINTABLEONLY);
	sm_banlist_url = CreateConVar("sm_banlist_url", DEFAULT_URL, "Banlist file url to download", FCVAR_PLUGIN | FCVAR_PRINTABLEONLY);

	CreateConVar("sm_banlist_version", PLUGIN_VERSION, "Banlist Version",  FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	AutoExecConfig();
}

public Action:sm_banlist_update(client, args)
{
	if(g_updating)
	{
		ReplyToCommand(client, "Update already running, please wait...");
	}
	else
	{
		g_updating = true;
		g_down = CreateDownloader();

		//Get convar values
		GetConVarString(sm_banlist_file, g_file, sizeof(g_file));
		new String:url[PLATFORM_MAX_PATH];
		GetConVarString(sm_banlist_url, url, sizeof(url));

		//Start downloading
		SetURL(g_down, url);
		SetCallback(g_down, update_Complete);
		SetProgressCallback(g_down, update_Progress);

		//Download to "<moddir>/file"
		SetOutputFile(g_down, g_file);

		Download(g_down);
	}
	return Plugin_Continue;
}

public update_Progress(const recvSize, const totalSize, Handle:arg)
{
}

public update_Complete(const sucess, const status, Handle:arg)
{
	PrintToServer("Banlist DownloadComplete: %i %i",sucess, status);
	CloseHandle(g_down);

	//Move file to config : I have not found a "MoveFile" function...
	new String:target[PLATFORM_MAX_PATH];
	Format(target, sizeof(target), "/cfg/%s", g_file);

	new Handle:OldFile = OpenFile(g_file, "r");
	new Handle:NewFile = OpenFile(target, "w");

	new items[100];
	new read;
	while(!IsEndOfFile(OldFile))
	{
		read = ReadFile(OldFile, items, sizeof(items), 4);
		WriteFile(NewFile, items, read, 4);
	}
	FlushFile(NewFile);
	CloseHandle(OldFile);
	CloseHandle(NewFile);

	//Delete downloaded file
	DeleteFile(g_file);

	//Execute banlist
	ServerCommand("exec %s", g_file);

	g_updating = false;
}
