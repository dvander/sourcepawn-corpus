#include <sourcemod>
#include <shavit>
#include <discord>

#define PLUGIN_VERSION "1.0"

#define WEBHOOK "" // webhook url

#define MIN_RECORDS 5 // minimum no. of records before discord bots posts wr

#define THUMBNAIL_URL "http://www.stickpng.com/assets/images/580b585b2edbce24c47b2af7.png" // url for thumbnail image
#define FOOTER_ICON_URL "http://simpleicon.com/wp-content/uploads/foot.png" // url for footer icon
#define MAIN_MSG_COLOUR "#00ffff" // colour of embed for when main wr is beaten
#define BONUS_MSG_COLOUR "#ff0000"  // colour of embed for when bonus wr is beaten

char g_cCurrentMap[PLATFORM_MAX_PATH];

ConVar g_cvHostname;
char g_cHostname[128];

public Plugin myinfo =
{
	name = "[shavit] Discord WR Bot",
	author = "SlidyBat",
	description = "Makes discord bot post message when server WR is beaten",
	version = PLUGIN_VERSION,
	url = "steamcommunity.com/id/SlidyBat2"
}

public void OnPluginStart()
{
	g_cvHostname = FindConVar("hostname");
	g_cvHostname.GetString( g_cHostname, sizeof( g_cHostname ) );
	g_cvHostname.AddChangeHook( OnConVarChanged );
}

public void OnConVarChanged( ConVar convar, const char[] oldValue, const char[] newValue )
{
	g_cvHostname.GetString( g_cHostname, sizeof( g_cHostname ) );
}

public void OnMapStart()
{
	GetCurrentMap( g_cCurrentMap, sizeof( g_cCurrentMap ) );
}

public void Shavit_OnWorldRecord( int client, int style, float time, int jumps, int strafes, float sync, int track )
{
	if( MIN_RECORDS > 0 && Shavit_GetRecordAmount( style, track ) < MIN_RECORDS ) // dont print if its a new record to avoid spam for new maps
	{
		return;
	}
	
	DiscordWebHook hook = new DiscordWebHook( WEBHOOK );
	hook.SlackMode = true;
	hook.SetUsername( "Shavit WR Bot" );
	
	MessageEmbed embed = new MessageEmbed();
	
	embed.SetColor( ( track == Track_Main ) ? MAIN_MSG_COLOUR : BONUS_MSG_COLOUR );
	
	char styleName[128];
	Shavit_GetStyleStrings( style, sStyleName, styleName, sizeof( styleName ));
	
	char buffer[512];
	Format( buffer, sizeof( buffer ), "__**New %s World Record**__ | **%s** - **%s**", ( track == Track_Main ) ? "" : "Bonus", g_cCurrentMap, styleName );
	embed.SetTitle( buffer );
	
	char steamid[65];
	GetClientAuthId( client, AuthId_SteamID64, steamid, sizeof( steamid ) );
	Format( buffer, sizeof( buffer ), "[%N](http://www.steamcommunity.com/profiles/%s)", client, steamid );
	embed.AddField( "Player:", buffer, true	);
	
	FormatSeconds( time, buffer, sizeof( buffer ) );
	Format( buffer, sizeof( buffer ), "%ss", buffer );
	embed.AddField( "Time:", buffer, true );
	
	Format( buffer, sizeof( buffer ), "**Strafes**: %i\t\t\t\t\t\t**Sync**: %.2f%%\t\t\t\t\t\t**Jumps**: %i", strafes, sync, jumps );
	embed.AddField( "Stats:", buffer, true );
	
	embed.SetThumb( THUMBNAIL_URL );
	
	embed.SetFooterIcon( FOOTER_ICON_URL );
	Format( buffer, sizeof( buffer ), "Server: %s", g_cHostname );
	embed.SetFooter( buffer );
	
	hook.Embed( embed );
	hook.Send();
}